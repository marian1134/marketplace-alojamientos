// Destinos populares de la portada. Fotos gratuitas de Pexels (licencia Pexels).
// Si una foto no carga, la tarjeta muestra un fondo de color con el nombre.
// También puedes guardar tu propia foto en public/imagenes/destinos/<id>.jpg
function pexels(id) {
  return `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=800`
}

export const DESTINOS = [
  {
    id: 'cartagena',
    nombre: 'Cartagena',
    lema: 'Ciudad amurallada y mar Caribe',
    foto: pexels(17745834),
    ciudades: ['cartagena'],
    color: '#c2703d',
  },
  {
    id: 'medellin',
    nombre: 'Medellín',
    lema: 'La ciudad de la eterna primavera',
    foto: pexels(12127531),
    ciudades: ['medellín', 'medellin'],
    color: '#2f6f8f',
  },
  {
    id: 'eje-cafetero',
    nombre: 'Eje Cafetero',
    lema: 'Valle de Cocora y palmas de cera',
    foto: pexels(28405086),
    ciudades: ['salento', 'armenia', 'pereira', 'manizales', 'filandia'],
    color: '#3f7d4e',
  },
  {
    id: 'santa-marta',
    nombre: 'Santa Marta',
    lema: 'Playas, Tayrona y Sierra Nevada',
    foto: pexels(30314589),
    ciudades: ['santa marta'],
    color: '#1f7a8c',
  },
  {
    id: 'guatape',
    nombre: 'Guatapé',
    lema: 'La Piedra del Peñol y su embalse',
    foto: pexels(14773970),
    ciudades: ['guatapé', 'guatape'],
    color: '#5b6fa8',
  },
  {
    id: 'san-andres',
    nombre: 'San Andrés',
    lema: 'El mar de los siete colores',
    foto: pexels(13836268),
    ciudades: ['san andrés', 'san andres'],
    color: '#1b8aa6',
  },
  {
    id: 'la-guajira',
    nombre: 'La Guajira',
    lema: 'Desierto, mar y cultura wayuu',
    foto: pexels(13837047),
    ciudades: ['cabo de la vela', 'riohacha'],
    color: '#c58a3c',
  },
  {
    id: 'amazonas',
    nombre: 'Amazonas',
    lema: 'Selva, río y delfines rosados',
    foto: pexels(13818469),
    ciudades: ['leticia'],
    color: '#2f6b3a',
  },
  {
    id: 'bogota',
    nombre: 'Bogotá',
    lema: 'Capital de museos y montañas',
    foto: pexels(19675608),
    ciudades: ['bogotá', 'bogota'],
    color: '#4a5a7a',
  },
  {
    id: 'llanos',
    nombre: 'Llanos Orientales',
    lema: 'Sabanas, joropo y atardeceres',
    foto: pexels(28154875),
    ciudades: ['villavicencio', 'yopal', 'arauca', 'puerto carreño'],
    color: '#b5823b',
  },
  {
    id: 'pacifico',
    nombre: 'Pacífico',
    lema: 'Ballenas, selva y mar en Nuquí',
    foto: pexels(13708932),
    ciudades: ['nuquí', 'nuqui'],
    color: '#2c6e63',
  },
  {
    id: 'villa-de-leyva',
    nombre: 'Villa de Leyva',
    lema: 'Pueblo colonial de Boyacá',
    foto: pexels(17198171),
    ciudades: ['villa de leyva'],
    color: '#a5673f',
  },
]
