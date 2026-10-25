// Drives push notifications in the browser - lib/services/push_web.dart
// calls these. A subscription goes to Dart as its JSON text (endpoint and
// keys), for the Drives server to push to.
window.drivesPush = (() => {
  const SCOPE = 'push/';

  const supported = () =>
    'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;

  // The server's public key, as the browser wants it
  const keyBytes = (base64url) => {
    const base64 = (base64url + '='.repeat((4 - (base64url.length % 4)) % 4))
      .replace(/-/g, '+').replace(/_/g, '/');
    return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  };

  // The push service worker, once it's active. (Not serviceWorker.ready -
  // that waits for a worker controlling this page, which this one, scoped
  // to push/, never is.)
  const registration = async () => {
    const found = await navigator.serviceWorker.register('push_sw.js', { scope: SCOPE });
    const worker = found.installing || found.waiting || found.active;
    if (worker && worker.state !== 'activated') {
      await new Promise((resolve) => worker.addEventListener('statechange', () => {
        if (worker.state === 'activated') resolve();
      }));
    }
    return found;
  };

  const existing = async () => {
    if (!supported()) return null;
    const found = await navigator.serviceWorker.getRegistration(SCOPE);
    return found ? found.pushManager.getSubscription() : null;
  };

  return {
    supported,

    // This browser's subscription, if notifications are on - or null
    async current() {
      if (!supported() || Notification.permission !== 'granted') return null;
      const subscription = await existing();
      return subscription ? JSON.stringify(subscription) : null;
    },

    // Asks the user, then subscribes - null if they said no
    async subscribe(publicKey) {
      if (!supported()) return null;
      if ((await Notification.requestPermission()) !== 'granted') return null;
      const found = await registration();
      const subscription = await found.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: keyBytes(publicKey),
      });
      return JSON.stringify(subscription);
    },

    // Unsubscribes - the old subscription, for the server to forget, or null
    async unsubscribe() {
      const subscription = await existing();
      if (!subscription) return null;
      const json = JSON.stringify(subscription);
      await subscription.unsubscribe();
      return json;
    },
  };
})();
