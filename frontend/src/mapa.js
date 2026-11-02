// Coordenadas (latitud, longitud) del centro de cada ciudad para el mapa
const COORDENADAS = {
  'cabo de la vela': [12.205, -72.148],
  riohacha: [11.544, -72.907],
  'santa marta': [11.24, -74.199],
  cartagena: [10.391, -75.479],
  mompox: [9.241, -74.427],
  barranquilla: [10.964, -74.796],
  'san andres': [12.584, -81.7],
  tolu: [9.524, -75.582],
  monteria: [8.748, -75.881],
  valledupar: [10.463, -73.253],
  barichara: [6.636, -73.223],
  cucuta: [7.893, -72.508],
  'villa de leyva': [5.633, -73.524],
  guatavita: [4.935, -73.833],
  bogota: [4.711, -74.072],
  medellin: [6.244, -75.581],
  guatape: [6.233, -75.158],
  manizales: [5.07, -75.513],
  pereira: [4.813, -75.696],
  armenia: [4.534, -75.681],
  salento: [4.637, -75.57],
  filandia: [4.674, -75.658],
  honda: [5.204, -74.736],
  'san agustin': [1.881, -76.268],
  cali: [3.451, -76.532],
  popayan: [2.444, -76.614],
  pasto: [1.214, -77.281],
  nuqui: [5.71, -77.271],
  villavicencio: [4.142, -73.627],
  yopal: [5.337, -72.395],
  arauca: [7.084, -70.759],
  'puerto carreno': [6.189, -67.486],
  inirida: [3.865, -67.924],
  'san jose del guaviare': [2.57, -72.642],
  mitu: [1.198, -70.173],
  florencia: [1.614, -75.606],
  mocoa: [1.149, -76.646],
  leticia: [-4.215, -69.94],
}

function normalizar(texto) {
  return (texto ?? '')
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .trim()
}

// "Granada, Cali, Valle del Cauca, Colombia" (sin repetir la ciudad)
function textoBusqueda(ciudad, direccion) {
  const incluyeCiudad = normalizar(direccion).includes(normalizar(ciudad))
  return incluyeCiudad
    ? `${direccion}, Colombia`
    : `${direccion}, ${ciudad}, Colombia`
}

// Dirección del mapa para incrustar en la página
export function urlMapa(ciudad, direccion) {
  const coordenadas = COORDENADAS[normalizar(ciudad)]

  if (coordenadas) {
    const [latitud, longitud] = coordenadas
    const margen = 0.03
    const caja = [
      longitud - margen,
      latitud - margen,
      longitud + margen,
      latitud + margen,
    ].join(',')

    return `https://www.openstreetmap.org/export/embed.html?bbox=${caja}&layer=mapnik&marker=${latitud},${longitud}`
  }

  // Ciudad que no está en la lista: se busca por la dirección
  return `https://maps.google.com/maps?q=${encodeURIComponent(
    textoBusqueda(ciudad, direccion)
  )}&z=13&output=embed`
}

// Enlace para abrir la ubicación en Google Maps
export function enlaceGoogleMaps(ciudad, direccion) {
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
    textoBusqueda(ciudad, direccion)
  )}`
}
