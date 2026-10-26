// Push on an Android phone - Firebase Cloud Messaging (push_web.dart is the
// browser's). Google delivers the push and can read it, so the server sends
// a phone only "New message" and the like, never who from.
//
// A subscription is its JSON text, {"fcm": the phone's Firebase token}.
// Notifications are off until the user turns them on: auto-init is off in
// AndroidManifest.xml, so there's no token till then. Turning them on turns
// auto-init on (Firebase remembers it), so auto-init is the on/off switch.
//
// It uses FCM tokens (getToken), which the server's HTTP v1 sends address.
// firebase_messaging 17 calls them deprecated in favour of its new
// installation ID registration (register/onRegistered) - a move for when
// sending to those is settled.
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:universal_io/io.dart';

/// Firebase's messaging, set up on first use - null where there's none (not
/// Android, or Firebase couldn't start)
Future<FirebaseMessaging?> _messaging() async {
  if (!Platform.isAndroid) return null;
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    return FirebaseMessaging.instance;
  } catch (e) {
    developer.log('Firebase: ${e.toString()}', name: 'error');
    return null;
  }
}

String _subscription(String token) => jsonEncode({'fcm': token});

Future<bool> _allowed(FirebaseMessaging messaging, {bool ask = false}) async {
  NotificationSettings settings = ask
      ? await messaging.requestPermission()
      : await messaging.getNotificationSettings();
  return settings.authorizationStatus == AuthorizationStatus.authorized;
}

Future<bool> supported() async => await _messaging() != null;

Future<String?> current() async {
  FirebaseMessaging? messaging = await _messaging();
  if (messaging == null ||
      !messaging.isAutoInitEnabled ||
      !await _allowed(messaging)) {
    return null;
  }
  // ignore: deprecated_member_use
  String? token = await messaging.getToken();
  return token == null ? null : _subscription(token);
}

/// (The server's public key is a browser's - a phone doesn't need it)
Future<String?> subscribe(String publicKey) async {
  FirebaseMessaging? messaging = await _messaging();
  if (messaging == null || !await _allowed(messaging, ask: true)) return null;
  await messaging.setAutoInitEnabled(true);
  // ignore: deprecated_member_use
  String? token = await messaging.getToken();
  return token == null ? null : _subscription(token);
}

Future<String?> unsubscribe() async {
  FirebaseMessaging? messaging = await _messaging();
  if (messaging == null) return null;
  String? was = await current();
  await messaging.setAutoInitEnabled(false);
  // ignore: deprecated_member_use
  await messaging.deleteToken();
  return was;
}
