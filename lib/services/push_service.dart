import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '/constants.dart';
import '/models/models.dart';
import 'web_helper.dart';
import 'push_android.dart' if (dart.library.js_interop) 'push_web.dart'
    as platform;

/// Push notifications on this device - a new message or a group drive
/// invitation, even when Drives isn't open. In a browser that's Web Push
/// (push_web.dart); on an Android phone, Firebase Cloud Messaging
/// (push_android.dart).
/// The server keeps each device's subscription and pushes to it.
class PushService {
  static final PushService _instance = PushService._();
  factory PushService() => _instance;
  PushService._();

  /// Whether this device can have notifications at all
  Future<bool> get supported => platform.supported();

  /// Whether notifications are on for this device
  Future<bool> get enabled async => (await platform.current()) != null;

  /// Turns notifications on - the browser or phone asks the user first.
  /// Returns '' when they're on, otherwise why not, to show the user
  Future<String> enable() async {
    if (!await supported) {
      return kIsWeb
          ? "This browser can't show notifications."
          : "This phone can't show notifications.";
    }
    if (Setup().jwt.isEmpty) return 'Log in to get notifications.';
    String key = kIsWeb ? await _serverKey() : ''; // only a browser needs it
    if (kIsWeb && key.isEmpty) {
      return "The Drives server can't send notifications yet.";
    }
    String? subscription;
    try {
      subscription = await platform.subscribe(key);
    } catch (e) {
      developer.log('Push subscribe failed: ${e.toString()}', name: 'error');
    }
    if (subscription == null) {
      return kIsWeb
          ? "Notifications are blocked for Drives - they can be allowed in the browser's settings for this site."
          : "Notifications are blocked for Drives - they can be allowed in the phone's Settings, under Apps, Drives.";
    }
    return await _send(subscription, 'subscribe')
        ? ''
        : "Couldn't reach the Drives server - please try again.";
  }

  /// Turns notifications off for this device
  Future<void> disable() async {
    String? subscription = await platform.unsubscribe();
    if (subscription != null && Setup().jwt.isNotEmpty) {
      await _send(subscription, 'unsubscribe');
    }
  }

  /// After logging in, or starting: this device's notifications go to the
  /// user logged in now (and the server has the subscription as it is now)
  Future<void> refresh() async {
    if (Setup().jwt.isEmpty) return;
    String? subscription = await platform.current();
    if (subscription != null) await _send(subscription, 'subscribe');
  }

  Future<String> _serverKey() async {
    try {
      http.Response response =
          await getWebData(uri: Uri.parse('$urlPush/key'), secure: false);
      if (response.statusCode == 200) return jsonDecode(response.body)['key'];
    } catch (e) {
      developer.log('Push key: ${e.toString()}', name: 'error');
    }
    return '';
  }

  Future<bool> _send(String subscription, String action) async {
    try {
      http.Response response = await postWebData(
          uri: Uri.parse('$urlPush/$action'),
          body: jsonEncode({'subscription': jsonDecode(subscription)}));
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Push $action: ${e.toString()}', name: 'error');
      return false;
    }
  }
}
