import { idiomaActual, t } from './index'

// Solo cambia las plantillas generadas por StayHub. Las capturas conservan
// nombres, títulos de alojamientos, importes y el contenido del mensaje.
const reglas = [
  [/^Tu reserva (.+) está confirmada$/, (codigo) => `Your booking ${codigo} is confirmed`],
  [/^Tu reserva en (.+) está confirmada\. Pagaste (.+)\.$/, (casa, total) => `Your booking at ${casa} is confirmed. You paid ${total}.`],
  [/^Tu reserva en (.+) quedó confirmada automáticamente\. No tienes que volver a pagar\.$/, (casa) => `Your booking at ${casa} was confirmed automatically. You do not need to pay again.`],
  [/^Nueva reserva (.+) en (.+)$/, (codigo, casa) => `New booking ${codigo} at ${casa}`],
  [/^Reserva confirmada: (.+)$/, (codigo) => `Booking confirmed: ${codigo}`],
  [/^(.+) reservó y pagó (.+) \((.+)\)\.$/, (nombre, casa, fechas) => `${nombre} booked and paid for ${casa} (${fechas}).`],
  [/^La reserva de (.+) en (.+) quedó confirmada automáticamente con el pago ya registrado\.$/, (nombre, casa) => `${nombre}'s booking at ${casa} was confirmed automatically using the payment already recorded.`],
  [/^Comprobante de pago - reserva (.+)$/, (codigo) => `Payment receipt - booking ${codigo}`],
  [/^Pagaste (.+) por tu reserva en (.+)\.$/, (total, casa) => `You paid ${total} for your booking at ${casa}.`],
  [/^Mañana llegas a (.+): recuerda tu check-in$/, (casa) => `You arrive at ${casa} tomorrow: remember to check in`],
  [/^Mañana es tu llegada a (.+)\. Haz tu check-in desde las (.+)\.$/, (casa, hora) => `You arrive at ${casa} tomorrow. Check in from ${hora}.`],
  [/^Check-in confirmado: (.+)$/, (casa) => `Check-in confirmed: ${casa}`],
  [/^Hiciste check-in en (.+) a las (.+)\.$/, (casa, hora) => `You checked in at ${casa} at ${hora}.`],
  [/^(.+) hizo check-in en (.+)$/, (nombre, casa) => `${nombre} checked in at ${casa}`],
  [/^(.+) hizo check-in a las (.+)\.$/, (nombre, hora) => `${nombre} checked in at ${hora}.`],
  [/^Tu reserva (.+) fue cancelada por no hacer check-in$/, (codigo) => `Your booking ${codigo} was canceled because you did not check in`],
  [/^El anfitrión canceló tu reserva en (.+) porque no hiciste check-in\.$/, (casa) => `The host canceled your booking at ${casa} because you did not check in.`],
  [/^Cancelaste la reserva (.+) por no presentarse$/, (codigo) => `You canceled booking ${codigo} as a no-show`],
  [/^Cancelaste la reserva de (.+)\. Las fechas quedaron libres\.$/, (nombre) => `You canceled ${nombre}'s booking. The dates are now available.`],
  [/^Cancelaste tu reserva (.+)$/, (codigo) => `You canceled your booking ${codigo}`],
  [/^Cancelaste tu reserva en (.+)\. Devolución: (.+)\.$/, (casa, total) => `You canceled your booking at ${casa}. Refund: ${total}.`],
  [/^El huésped canceló la reserva (.+)$/, (codigo) => `The guest canceled booking ${codigo}`],
  [/^(.+) canceló su reserva en (.+) \((.+)\)\.$/, (nombre, casa, fechas) => `${nombre} canceled their booking at ${casa} (${fechas}).`],
]
export function textoNotificacion(aviso, campo) {
  const texto = aviso?.[campo] || ''
  if (idiomaActual() === 'es') return texto
  if (aviso.tipo === 'MENSAJE_CHAT') {
    if (campo === 'titulo') return texto.replace(/^Nuevo mensaje de /, 'New message from ')
    return texto.replace(/^Reserva /, 'Booking ')
  }
  for (const [patron, traducir] of reglas) {
    const partes = patron.exec(texto)
    if (partes) return traducir(...partes.slice(1))
  }
  return t(texto)
}
