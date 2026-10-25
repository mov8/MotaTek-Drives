// Web Push in the browser - through web/push.js (window.drivesPush). A
// subscription is its JSON text: the endpoint and keys the server needs.
import 'dart:js_interop';

@JS('drivesPush.supported')
external JSBoolean _supported();

@JS('drivesPush.current')
external JSPromise<JSString?> _current();

@JS('drivesPush.subscribe')
external JSPromise<JSString?> _subscribe(JSString publicKey);

@JS('drivesPush.unsubscribe')
external JSPromise<JSString?> _unsubscribe();

Future<bool> supported() async {
  try {
    return _supported().toDart;
  } catch (e) {
    return false; // push.js not loaded
  }
}

Future<String?> current() async {
  if (!await supported()) return null;
  return (await _current().toDart)?.toDart;
}

Future<String?> subscribe(String publicKey) async =>
    (await _subscribe(publicKey.toJS).toDart)?.toDart;

Future<String?> unsubscribe() async {
  if (!await supported()) return null;
  return (await _unsubscribe().toDart)?.toDart;
}
