// Permite instalar StayHub como app en el celular.
// No guarda nada en caché: siempre se usan los datos más recientes.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (evento) => evento.waitUntil(self.clients.claim()));
