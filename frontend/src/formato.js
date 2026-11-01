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

export function explicarPolitica(politica) {
  if (!politica) {
    return ''
  }

  const antes = Number(politica.porcentajeAntes)
  const despues = Number(politica.porcentajeDespues)
  const dias = politica.diasAnticipacion

  return (
    `Si cancelas hasta ${dias} ${dias === 1 ? 'día' : 'días'} antes de la llegada, ` +
    `te devolvemos el ${antes} %. Después, ` +
    (despues > 0
      ? `te devolvemos el ${despues} %.`
      : 'no hay devolución.')
  )
}
