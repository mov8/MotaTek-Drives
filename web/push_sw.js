// Drives push notifications: shows a push from the Drives server, and
// opens Drives when it's tapped. push.js registers it with the scope
// push/, so it doesn't replace Flutter's own service worker - a push
// reaches it whatever its scope.

self.addEventListener('push', (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {
    // not JSON - show the default
  }
  event.waitUntil(
    self.registration.showNotification(data.title || 'Drives', {
      body: data.body || 'Something new in Drives',
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
    })
  );
});

// Tapping it: back to Drives if it's open, otherwise open it
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const app = new URL('./', self.location).href;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windows) => {
      for (const w of windows) {
        if (w.url.startsWith(app) && 'focus' in w) return w.focus();
      }
      return clients.openWindow(app);
    })
  );
});
