// Poistaa vanhan offline-välimuistin (service worker) pelaajien laitteilta.
//
// Pelin ensimmäiset versiot tallensivat itsensä selaimen välimuistiin, jolloin
// iPhone saattoi näyttää vanhaa versiota vielä päivityksen jälkeenkin.
// Selain hakee tämän tiedoston vanhan tilalle, ottaa sen heti käyttöön,
// tyhjentää välimuistin, poistaa itsensä ja lataa pelin uudelleen verkosta.
// CI kopioi tämän nimellä index.service.worker.js.
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => caches.delete(key)));
    await self.registration.unregister();
    const windows = await self.clients.matchAll({ type: "window" });
    for (const client of windows) {
      client.navigate(client.url);
    }
  })());
});
