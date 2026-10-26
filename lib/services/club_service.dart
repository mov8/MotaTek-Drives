import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import 'dart:developer' as developer;

/// A club the user is in, and their role in it - member or admin
class Club {
  final String id;
  final String name;
  final String role;
  const Club({required this.id, required this.name, required this.role});

  bool get isAdmin => role == 'admin';

  factory Club.fromMap(Map map) => Club(
      id: map['id'] ?? '', name: map['name'] ?? '', role: map['role'] ?? '');
}

/// The user's clubs (api.clubs on the server): which they're in and as
/// what, whose Home and Shop pages they're looking at, and whether they may
/// edit those pages (a club's admin, or Drives staff). People in no club,
/// and people not logged in, see Drives' own pages.
///
/// The server keeps which club's pages the user sees, so Home and Shop are
/// right before this has loaded; this is for the club picker (ClubPicker)
/// and for offering the Markdown editor.
class ClubService extends ChangeNotifier {
  static final ClubService _instance = ClubService._internal();
  factory ClubService() => _instance;
  ClubService._internal();

  List<Club> clubs = [];
  String showing = ''; // the club whose pages the user sees
  String drives = ''; // Drives' own pages
  bool canEditPages = false;

  /// Done once the clubs are known - read, or cleared for nobody logged in
  final Completer<void> _known = Completer<void>();
  Future<void> get known => _known.future;

  bool get inAnyClub => clubs.isNotEmpty;

  /// The name of the pages being shown - a club's, or Drives'
  String get showingName => clubs
      .firstWhere((club) => club.id == showing,
          orElse: () => const Club(id: '', name: 'Drives', role: ''))
      .name;

  /// From the server's summary - in the login reply, the user's details,
  /// /v1/club/mine and /v1/club/showing
  void read(Map data) {
    clubs = [for (Map club in data['clubs'] ?? []) Club.fromMap(club)];
    showing = data['showing'] ?? '';
    drives = data['drives'] ?? '';
    canEditPages = data['can_edit_pages'] == true;
    _isKnown();
    notifyListeners();
  }

  void _isKnown() {
    if (!_known.isCompleted) _known.complete();
  }

  void clear() {
    clubs = [];
    showing = drives;
    canEditPages = false;
    _isKnown();
    notifyListeners();
  }

  /// Fetches the user's clubs - at start-up, when they're already logged in
  Future<void> refresh() async {
    if (Setup().jwt.isEmpty) return clear();
    try {
      http.Response response =
          await getWebData(uri: Uri.parse('$urlClub/mine'), secure: true);
      if (response.statusCode == 200) {
        read(jsonDecode(response.body));
      } else if ([401, 403, 408, 422].contains(response.statusCode)) {
        clear(); // not logged in after all
      }
    } catch (e) {
      developer.log('ClubService.refresh(): ${e.toString()}', name: 'error');
    }
    _isKnown(); // offline - as they were
  }

  /// Shows the user one of their clubs' pages, or Drives' own - and
  /// reloads Home and Shop. Null, or why it couldn't.
  Future<String?> show(String clubId) async {
    try {
      http.Response response = await postWebData(
          uri: Uri.parse('$urlClub/showing'),
          body: jsonEncode({'club_id': clubId}));
      Map body = response.body.isEmpty ? {} : jsonDecode(response.body);
      if (response.statusCode != 200) {
        return body['msg'] ?? "Couldn't change the club";
      }
      read(body);
      MapService().homeController?.reload();
      MapService().shopController?.reload();
      return null;
    } catch (e) {
      developer.log('ClubService.show(): ${e.toString()}', name: 'error');
      return "Couldn't reach Drives - check your connection";
    }
  }

  // ---- finding, joining and running clubs (/v1/club/...) ------------------
  // Each returns (what came back, null) or (null, why not).

  static const String _offline =
      "Couldn't reach Drives - check your connection";

  Future<(dynamic, String?)> _call(String path,
      {Map<String, dynamic>? body,
      bool post = false,
      String base = urlClub}) async {
    try {
      Uri uri = Uri.parse('$base/$path');
      http.Response response = post || body != null
          ? await postWebData(uri: uri, body: jsonEncode(body ?? {}))
          : await getWebData(uri: uri, secure: Setup().jwt.isNotEmpty);
      dynamic data = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode == 200) return (data, null);
      if ([401, 407, 408].contains(response.statusCode)) {
        return (null, 'Log in first, please');
      }
      return (
        null,
        (data is Map ? data['msg'] : null)?.toString() ?? 'That didn\'t work'
      );
    } catch (e) {
      developer.log('ClubService $path: ${e.toString()}', name: 'error');
      return (null, _offline);
    }
  }

  /// Anything that changes the user's clubs comes back as their summary
  Future<String?> _changed(String path, Map<String, dynamic> body) async {
    var (data, problem) = await _call(path, body: body);
    if (data is Map && data.containsKey('clubs')) read(data);
    return problem;
  }

  Future<(dynamic, String?)> search(String name) =>
      _call('search?name=${Uri.encodeQueryComponent(name)}');

  Future<(dynamic, String?)> profile(String clubId) => _call(clubId);

  Future<(dynamic, String?)> askToJoin(String clubId, String message) =>
      _call('$clubId/join', body: {'message': message});

  Future<String?> leave(String clubId) => _changed('$clubId/leave', {});

  Future<(dynamic, String?)> invitations() => _call('invitations');

  Future<String?> answer(String invitationId, bool accept) =>
      _changed('invitations/$invitationId', {'accept': accept});

  // the club's admin

  Future<(dynamic, String?)> updateProfile(
          String clubId, Map<String, dynamic> changes) =>
      _call(clubId, body: changes);

  Future<(dynamic, String?)> members(String clubId) => _call('$clubId/members');

  Future<(dynamic, String?)> setRole(
          String clubId, String userId, String role) =>
      _call('$clubId/members/$userId', body: {'role': role});

  Future<(dynamic, String?)> remove(String clubId, String userId) =>
      _call('$clubId/members/$userId', body: {'remove': true});

  Future<(dynamic, String?)> requests(String clubId) =>
      _call('$clubId/requests');

  Future<(dynamic, String?)> decide(
          String clubId, String requestId, bool approve) =>
      _call('$clubId/requests/$requestId', body: {'approve': approve});

  /// emails as pasted - any number, any separators
  Future<(dynamic, String?)> invite(
          String clubId, String emails, String message) =>
      _call('$clubId/invite', body: {'emails': emails, 'message': message});

  Future<(dynamic, String?)> outstanding(String clubId) =>
      _call('$clubId/invitations');

  Future<(dynamic, String?)> withdraw(String clubId, String invitationId) =>
      _call('$clubId/invitations/$invitationId/withdraw', post: true);

  /// To every member - comes back as {sent}
  Future<(dynamic, String?)> emailMembers(
          String clubId, String subject, String message) =>
      _call('$clubId/email', body: {'subject': subject, 'message': message});

  // Drives staff: every club (/v1/console/...) - each comes back as the list

  Future<(dynamic, String?)> consoleClubs() => _call('clubs', base: urlConsole);

  Future<(dynamic, String?)> newClub(String name) =>
      _call('clubs', body: {'name': name}, base: urlConsole);

  /// contact_name, contact_email, contact_phone, payment_note and
  /// paid_until (YYYY-MM-DD, or null for not paid)
  Future<(dynamic, String?)> updateClub(
          String clubId, Map<String, dynamic> changes) =>
      _call('clubs/$clubId', body: changes, base: urlConsole);

  Future<(dynamic, String?)> appointAdmin(String clubId, String email) =>
      _call('clubs/$clubId/admins', body: {'email': email}, base: urlConsole);

  Future<(dynamic, String?)> uploadLogo(
      String clubId, List<int> bytes, String filename) async {
    try {
      http.MultipartRequest request =
          http.MultipartRequest('POST', Uri.parse('$urlClub/$clubId/logo'));
      request.headers['Authorization'] = 'Bearer ${Setup().jwt}';
      request.files
          .add(http.MultipartFile.fromBytes('logo', bytes, filename: filename));
      http.Response response =
          await http.Response.fromStream(await request.send());
      dynamic data = response.body.isEmpty ? null : jsonDecode(response.body);
      return response.statusCode == 200
          ? (data, null)
          : (
              null,
              (data is Map ? data['msg'] : null)?.toString() ??
                  'That didn\'t work'
            );
    } catch (e) {
      developer.log('ClubService logo: ${e.toString()}', name: 'error');
      return (null, _offline);
    }
  }
}
