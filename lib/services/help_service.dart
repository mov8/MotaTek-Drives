import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '/constants.dart';

/// The app's help, from the documentation on the website - one source for
/// both. Each docs page's summary is what the ? shows (HelpButton), and each
/// control's hint is its HelpTip, by key:
///   `chip.<TripChip name>`  fab.search, fab.preferences, fab.location,
///   fab.zoom, fab.pointOfInterest, fab.greatRoad  bar.undo, bar.redo,
///   bar.help, bar.account, bar.menu, bar.addContact, bar.writeMessage
///   `menu.<drawerOptions key>`  trip.load, trip.publish, trip.synchronise,
///   trip.delete
/// The website writes them with its help shortcode (the Hugo site's
/// layouts/shortcodes/help.html) into motatek.com/docs/app-help.json. The app
/// ships a copy - assets/help/app-help.json, copied from the website's build
/// (public/docs/app-help.json) before building the app - and fetches the
/// latest when it can. A control documented first, then built, gets its
/// hint without a word of it in the code.
class HelpService extends ChangeNotifier {
  static final HelpService _instance = HelpService._internal();
  factory HelpService() => _instance;
  HelpService._internal() {
    _load();
  }

  /// The main pages' docs, in NavigationService().page order - Published
  /// and Explore are great_drives and my_trip
  static const List<String> mainPages = [
    'home',
    'great_drives',
    'my_trip',
    'my_drives',
    'shop',
    'messages',
  ];

  Map<String, dynamic> _pages = {};
  Map<String, dynamic> _help = {};

  Future<void> _load() async {
    try {
      _read(await rootBundle.loadString('assets/help/app-help.json'));
    } catch (e) {
      developer.log('HelpService: no copy of the help: $e', name: 'error');
    }
    try {
      http.Response reply = await http
          .get(Uri.parse('${urlDocs}app-help.json'))
          .timeout(const Duration(seconds: 10));
      if (reply.statusCode == 200) _read(utf8.decode(reply.bodyBytes));
    } catch (_) {
      // Offline - or on the web, the website not letting the app read it.
      // The copy will do.
    }
  }

  void _read(String json) {
    Map<String, dynamic> help = jsonDecode(json);
    _pages = Map<String, dynamic>.from(help['pages'] ?? {});
    _help = Map<String, dynamic>.from(help['help'] ?? {});
    notifyListeners();
  }

  /// A control's hint, or null if it isn't documented. page.home and so on
  /// are the page's summary's first sentence - for the buttons that go there.
  String? hint(String key) {
    if (key.startsWith('page.')) {
      String summary = page(key.substring(5))?.summary ?? '';
      return summary.isEmpty
          ? null
          : RegExp(r'^[^.!?]*[.!?]').stringMatch(summary) ?? summary;
    }
    return _help[key]?['hint'];
  }

  /// A docs page - home, great_drives, my_trip... - its title, summary and
  /// address, or null
  ({String title, String summary, Uri url})? page(String name) {
    Map? found = _pages[name];
    if (found == null) return null;
    return (
      title: found['title'] ?? '',
      summary: found['summary'] ?? '',
      url: Uri.parse(urlDocs).resolve(found['url'] ?? '/docs/$name/'),
    );
  }
}

/// A control's hint from the help (HelpService): shown on hovering over it,
/// or a long press on a phone. Until the help has it, just the control.
class HelpTip extends StatelessWidget {
  final String helpKey;
  final Widget child;
  const HelpTip({super.key, required this.helpKey, required this.child});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: HelpService(),
        builder: (context, child) {
          String? hint = HelpService().hint(helpKey);
          return hint == null
              ? child!
              : Tooltip(
                  message: hint,
                  waitDuration: const Duration(milliseconds: 500),
                  // long enough to read on a phone, after a long press
                  showDuration: const Duration(seconds: 6),
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: child,
                );
        },
        child: child,
      );
}
