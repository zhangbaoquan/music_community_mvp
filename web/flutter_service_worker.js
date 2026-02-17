// KILLER SERVICE WORKER V2
// Forcefully unregisters itself and reloads the page to clear the cache.

const VERSION = 'killer-v2-' + new Date().getTime(); // Unique version

self.addEventListener('install', (event) => {
    console.log('[Killer SW] Installing ' + VERSION);
    // Skipp waiting to activate immediately
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    console.log('[Killer SW] Activated. Unregistering...');

    event.waitUntil(
        self.registration.unregister()
            .then((success) => {
                console.log('[Killer SW] Unregister success:', success);
                // Find all open windows/tabs
                return self.clients.matchAll({
                    type: 'window',
                    includeUncontrolled: true
                });
            })
            .then((clients) => {
                console.log('[Killer SW] Reloading ' + clients.length + ' clients');
                clients.forEach((client) => {
                    // Navigate client to its current URL to force a reload from network
                    if (client.url && 'navigate' in client) {
                        client.navigate(client.url);
                    }
                });
            })
    );
});

// Intercept fetch to ensure we never return cached assets during the death throes
self.addEventListener('fetch', (event) => {
    // Pass through to network
    event.respondWith(fetch(event.request));
});
