// Push on a phone - not yet: Android will use Firebase Cloud Messaging.
// Until then, no notifications (push_web.dart is the browser's).

Future<bool> supported() async => false;

Future<String?> current() async => null;

Future<String?> subscribe(String publicKey) async => null;

Future<String?> unsubscribe() async => null;
