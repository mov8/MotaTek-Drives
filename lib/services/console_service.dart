import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '/constants.dart';
import '/models/models.dart';
import '/services/services.dart';

/// The control panel's calls (/v1/console/... - api/v1/console.py), for
/// Drives staff: the summaries and months (api/reports.py), the clubs'
/// contacts, schemes and payments, private users' counts and exceptions,
/// the schemes, and
/// emailing everyone or the clubs' admins. Each returns (what came back,
/// null) or (null, why not).
class ConsoleService {
  static final ConsoleService _instance = ConsoleService._internal();
  factory ConsoleService() => _instance;
  ConsoleService._internal();

  Future<(dynamic, String?)> _call(String path,
      {Map<String, dynamic>? body}) async {
    try {
      Uri uri = Uri.parse('$urlConsole/$path');
      http.Response response = body != null
          ? await postWebData(uri: uri, body: jsonEncode(body))
          : await getWebData(uri: uri, secure: Setup().jwt.isNotEmpty);
      dynamic data = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode == 200) return (data, null);
      return (
        null,
        (data is Map ? data['msg'] : null)?.toString() ?? "That didn't work"
      );
    } catch (e) {
      developer.log('ConsoleService $path: ${e.toString()}', name: 'error');
      return (null, "Couldn't reach Drives - check your connection");
    }
  }

  /// All of Drives, private users, then each club
  Future<(dynamic, String?)> overview() => _call('overview');

  /// The last year by month - scope is all, private or a club's id
  Future<(dynamic, String?)> months(String scope) => _call('months/$scope');

  /// {id, summaries}
  Future<(dynamic, String?)> newClub(String name) =>
      _call('clubs', body: {'name': name});

  /// contact_name, contact_email, contact_phone, payment_note, scheme_id,
  /// paid_until (YYYY-MM-DD, or null) - back come the summaries
  Future<(dynamic, String?)> updateClub(
          String clubId, Map<String, dynamic> changes) =>
      _call('clubs/$clubId', body: changes);

  Future<(dynamic, String?)> appointAdmin(String clubId, String email) =>
      _call('clubs/$clubId/admins', body: {'email': email});

  /// A club's payments (payer is 'clubs')
  Future<(dynamic, String?)> payments(String payer, String id) =>
      _call('$payer/$id/payments');

  /// {amount (pounds), paid, reference, note, paid_until (or a period on)}
  Future<(dynamic, String?)> recordPayment(
          String payer, String id, Map<String, dynamic> payment) =>
      _call('$payer/$id/payments', body: payment);

  /// Private users: counts, and the exceptions to look into
  Future<(dynamic, String?)> privateUsers() => _call('private');

  Future<(dynamic, String?)> schemes() => _call('schemes');

  /// A new scheme (no id), or a change to one - back come them all
  Future<(dynamic, String?)> saveScheme(
          String? id, Map<String, dynamic> scheme) =>
      _call(id == null ? 'schemes' : 'schemes/$id', body: scheme);

  /// {done: deleted or retired, schemes}
  Future<(dynamic, String?)> deleteScheme(String id) =>
      _call('schemes/$id/delete', body: {});

  /// to is all (who haven't unsubscribed) or club_admins - {sent}
  Future<(dynamic, String?)> email(String to, String subject, String message) =>
      _call('email', body: {'to': to, 'subject': subject, 'message': message});
}
