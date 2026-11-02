// Formatos de dinero y fechas que usan las pantallas de reservas

export function pesos(valor) {
  if (valor === null || valor === undefined) {
    return '—'
  }

  return (
    '$' +
    Number(valor).toLocaleString('es-CO', {
      maximumFractionDigits: 0,
    }) +
    ' COP'
  )
}

// '2026-12-15' -> Date local (sin problemas de zona horaria)
export function aFecha(texto) {
  const [anio, mes, dia] = texto.split('-').map(Number)
  return new Date(anio, mes - 1, dia)
}

// Date -> '2026-12-15'
export function aTexto(fecha) {
  return [
    fecha.getFullYear(),
    String(fecha.getMonth() + 1).padStart(2, '0'),
    String(fecha.getDate()).padStart(2, '0'),
  ].join('-')
}

export function hoyTexto() {
  return aTexto(new Date())
}

export function fechaCorta(texto) {
  if (!texto) {
    return ''
  }

  return aFecha(texto).toLocaleDateString('es-CO', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

export function contarNoches(entrada, salida) {
  if (!entrada || !salida) {
    return 0
  }

  return Math.round(
    (aFecha(salida) - aFecha(entrada)) / 86400000
  )
}

export const NOMBRES_ESTADO_RESERVA = {
  PENDIENTE_PAGO: 'Pendiente de pago',
  PENDIENTE_APROBACION: 'Esperando aprobación',
  CONFIRMADA: 'Confirmada',
  RECHAZADA: 'Rechazada',
  ANULADA: 'Anulada',
  CANCELADA: 'Cancelada',
  COMPLETADA: 'Completada',
}

export const NOMBRES_POLITICA = {
  FLEXIBLE: 'Cancelación flexible',
  MODERADA: 'Cancelación moderada',
  ESTRICTA: 'Cancelación estricta',
}

// Explica la política con palabras sencillas. Si se conoce la fecha de
// llegada, dice hasta qué día exacto se puede cancelar.
export function explicarPolitica(politica, fechaLlegada) {
  if (!politica) {
    return ''
  }

  const antes = Number(politica.porcentajeAntes)
  const despues = Number(politica.porcentajeDespues)
  const dias = politica.diasAnticipacion

  let plazo = `hasta ${dias} ${dias === 1 ? 'día' : 'días'} antes de la llegada`

  if (fechaLlegada) {
    const limite = aFecha(fechaLlegada)
    limite.setDate(limite.getDate() - dias)
    plazo = `hasta el ${fechaCorta(aTexto(limite))}`
  }

  const primera =
    antes === 100
      ? `Cancelación gratis ${plazo}: te devolvemos el 100 % del pago.`
      : `Si cancelas ${plazo}, te devolvemos el ${antes} % del pago.`

  const segunda =
    despues > 0
      ? `Si cancelas después, te devolvemos el ${despues} %.`
      : 'Si cancelas después, no hay devolución.'

  return `${primera} ${segunda}`
}

// Nombre corto con mayúscula: 'Flexible', 'Moderada', 'Estricta'
export function nombreCortoPolitica(tipo) {
  const texto = (tipo ?? '').toLowerCase()
  return texto.charAt(0).toUpperCase() + texto.slice(1)
}

export function sumarDias(texto, dias) {
  const fecha = aFecha(texto)
  fecha.setDate(fecha.getDate() + dias)
  return aTexto(fecha)
}

// Límites de las fechas de la reserva
export const MAXIMO_NOCHES = 90

export function fechaMaximaLlegada() {
  return sumarDias(hoyTexto(), 365)
}

export function plural(cantidad, uno, varios) {
  return `${cantidad} ${cantidad === 1 ? uno : varios}`
}

// Si una foto de internet no carga, se muestra la foto de la cabaña
export function fotoRespaldo(evento) {
  const imagen = evento.currentTarget

  if (!imagen.dataset.respaldo) {
    imagen.dataset.respaldo = 'si'
    imagen.src = '/imagenes/registro-fondo.png'
  }
}
