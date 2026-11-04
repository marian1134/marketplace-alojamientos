import { useEffect, useId, useRef } from 'react'
import { leerError } from '../api'
import {
  dinero, fechaCorta, horaBonita, NOMBRES_ESTADO_RESERVA,
} from '../formato'
import './detalle-reserva-aviso.css'

// Las listas ya son filtradas por el servidor para la sesión actual.
export async function buscarReservaNotificacion(id, rol, signal) {
  const rutas = ['/api/v1/reservas/mis-reservas']
  if (rol === 'ANFITRION') rutas.push('/api/v1/reservas/recibidas')
  const respuestas = await Promise.all(rutas.map((ruta) => fetch(ruta, {
    credentials: 'same-origin', cache: 'no-store', signal,
  })))
  const sinSesion = respuestas.find((respuesta) => respuesta.status === 401)
  if (sinSesion) {
    throw new Error(await leerError(sinSesion, 'Tu sesión terminó. Inicia sesión de nuevo.'))
  }
  for (const respuesta of respuestas) {
    if (!respuesta.ok) continue
    const reservas = await respuesta.json()
    if (!Array.isArray(reservas)) throw new Error('La respuesta de reservas no es válida.')
    const propia = reservas.find((reserva) => Number(reserva.idReserva) === id)
    if (propia) return propia
  }
  const fallida = respuestas.find((respuesta) => !respuesta.ok)
  if (fallida) {
    throw new Error(await leerError(fallida, 'No pudimos consultar la reserva. Intenta de nuevo.'))
  }
  throw new Error('Esta reserva ya no está disponible para tu cuenta.')
}

export default function DetalleReservaAviso({ reserva, onCerrar }) {
  const tituloId = useId()
  const ventana = useRef(null)

  useEffect(() => {
    const dialogo = ventana.current
    dialogo?.showModal()
    return () => dialogo?.close()
  }, [])

  const estado = NOMBRES_ESTADO_RESERVA[reserva.estado] || reserva.estado
  const moneda = reserva.monedaPago || reserva.moneda || 'COP'
  const tienePago = reserva.montoPagado != null || Boolean(reserva.ultimos4)
  const monto = reserva.montoPagado ?? reserva.total

  return (
    <dialog ref={ventana} className="detalle-reserva-aviso"
      aria-labelledby={tituloId}
      onCancel={(evento) => { evento.preventDefault(); onCerrar() }}>
      <header>
        <div>
          <p className="detalle-reserva-aviso-codigo">{reserva.codigo}</p>
          <h2 id={tituloId}>Detalle de la reserva</h2>
        </div>
        <button type="button" className="detalle-reserva-aviso-cerrar"
          aria-label="Cerrar detalle de la reserva" onClick={onCerrar}>×</button>
      </header>
      <div className="detalle-reserva-aviso-contenido">
        <h3>{reserva.tituloAlojamiento}</h3>
        <p className="detalle-reserva-aviso-ciudad">{reserva.ciudad}</p>
        <span className="detalle-reserva-aviso-estado">{estado}</span>
        <dl className="detalle-reserva-aviso-datos">
          <div><dt>Llegada</dt><dd>{fechaCorta(reserva.fechaLlegada)}</dd></div>
          <div><dt>Salida</dt><dd>{fechaCorta(reserva.fechaSalida)}</dd></div>
          <div><dt>Huésped</dt><dd>{reserva.nombreHuesped}</dd></div>
          <div><dt>Anfitrión</dt><dd>{reserva.nombreAnfitrion}</dd></div>
          <div><dt>Personas</dt><dd>{reserva.cantidadHuespedes}</dd></div>
          <div><dt>Noches</dt><dd>{reserva.noches}</dd></div>
        </dl>

        <section className="detalle-reserva-aviso-bloque" aria-label="Check-in">
          <h3>Check-in</h3>
          {reserva.checkInEn ? (
            <p>Realizado el {fechaCorta(reserva.checkInEn.slice(0, 10))},
              a las {horaBonita(reserva.checkInEn.slice(11, 16))}.</p>
          ) : (
            <p>Sin registro de check-in.
              {reserva.horaCheckIn && ` Hora de llegada: desde las ${horaBonita(reserva.horaCheckIn)}.`}
            </p>
          )}
        </section>

        <section className="detalle-reserva-aviso-bloque" aria-label="Datos del pago">
          <h3>Reserva y pago</h3>
          <dl className="detalle-reserva-aviso-datos">
            <div><dt>{tienePago ? 'Monto pagado' : 'Total de la reserva'}</dt>
              <dd>{dinero(monto, moneda)}</dd></div>
            <div><dt>Moneda</dt><dd>{moneda}</dd></div>
            {reserva.ultimos4 && <div><dt>Tarjeta</dt>
              <dd>Terminada en {reserva.ultimos4}</dd></div>}
            {Number(reserva.valorDevolucion) > 0 && <div><dt>Devolución</dt>
              <dd>{dinero(reserva.valorDevolucion, moneda)}</dd></div>}
          </dl>
          {reserva.motivo && <p>Motivo: {reserva.motivo}</p>}
        </section>

        {reserva.calificacionResena != null && (
          <p>Calificación del alojamiento: {reserva.calificacionResena}/5.</p>
        )}
        <p className="detalle-reserva-aviso-ayuda">
          Puedes gestionar la reserva desde Mis viajes o desde el Panel anfitrión,
          según tu participación.
        </p>
      </div>
      <footer>
        <button type="button" onClick={onCerrar}>Cerrar</button>
      </footer>
    </dialog>
  )
}
