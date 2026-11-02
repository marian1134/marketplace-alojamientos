// Ciudades y destinos de StayHub, con su departamento
export const CIUDADES = [
  ['Arauca', 'Arauca'],
  ['Barichara', 'Santander'],
  ['Barranquilla', 'Atlántico'],
  ['Bogotá', 'Bogotá D.C.'],
  ['Cabo de la Vela', 'La Guajira'],
  ['Cali', 'Valle del Cauca'],
  ['Cartagena', 'Bolívar'],
  ['Cúcuta', 'Norte de Santander'],
  ['Florencia', 'Caquetá'],
  ['Guatapé', 'Antioquia'],
  ['Guatavita', 'Cundinamarca'],
  ['Honda', 'Tolima'],
  ['Inírida', 'Guainía'],
  ['Leticia', 'Amazonas'],
  ['Manizales', 'Caldas'],
  ['Medellín', 'Antioquia'],
  ['Mitú', 'Vaupés'],
  ['Mocoa', 'Putumayo'],
  ['Mompox', 'Bolívar'],
  ['Montería', 'Córdoba'],
  ['Nuquí', 'Chocó'],
  ['Pasto', 'Nariño'],
  ['Pereira', 'Risaralda'],
  ['Popayán', 'Cauca'],
  ['Puerto Carreño', 'Vichada'],
  ['Riohacha', 'La Guajira'],
  ['Salento', 'Quindío'],
  ['San Agustín', 'Huila'],
  ['San Andrés', 'San Andrés y Providencia'],
  ['San José del Guaviare', 'Guaviare'],
  ['Santa Marta', 'Magdalena'],
  ['Tolú', 'Sucre'],
  ['Valledupar', 'Cesar'],
  ['Villa de Leyva', 'Boyacá'],
  ['Villavicencio', 'Meta'],
  ['Yopal', 'Casanare'],
].map(([ciudad, departamento]) => ({ ciudad, departamento }))

export function normalizar(texto) {
  return (texto ?? '')
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .trim()
}

// Ciudades cuyo nombre o departamento contiene el texto escrito
export function filtrarCiudades(texto) {
  const buscado = normalizar(texto)

  if (!buscado) {
    return CIUDADES
  }

  return CIUDADES.filter(
    (item) =>
      normalizar(item.ciudad).includes(buscado) ||
      normalizar(item.departamento).includes(buscado)
  )
}
