import { useEffect, useRef, useState } from 'react'
import { consultar, enviarDatos, leerError } from '../api'
import CalificarHuesped from './CalificarHuesped'
import './reservas-anfitrion.css'
import {
  aFecha,
  fechaCorta,
  horaBonita,
  hoyTexto,
  NOMBRES_ESTADO_RESERVA,
  pesos,
} from '../formato'

function PanelAnfitrion({
  usuario,
  onGestionarAlojamientos,
  onCalendario,
}) {
  const [alojamientos, setAlojamientos] = useState([])
  const [reservas, setReservas] = useState([])
  const [calificaciones, setCalificaciones] = useState([])
  const [cargando, setCargando] = useState(true)
  const [error, setError] = useState('')
  const [mensaje, setMensaje] = useState('')
  const [aRechazar, setARechazar] = useState(null)
  const [motivo, setMotivo] = useState('')
  const ventana = useRef(null)

  useEffect(() => {
    let activo = true

    async function cargar() {
      try {
        const [respuestaAlojamientos, respuestaReservas, respuestaCalificaciones] =
          await Promise.all([
            consultar('/api/v1/alojamientos/mis-alojamientos'),
            consultar('/api/v1/reservas/recibidas'),
            consultar('/api/v1/resenas-huesped/mis-calificaciones'),
          ])

        if (!respuestaAlojamientos.ok || !respuestaReservas.ok || !respuestaCalificaciones.ok) {
          throw new Error('No se pudo cargar tu panel.')
        }

        const datosAlojamientos = await respuestaAlojamientos.json()
        const datosReservas = await respuestaReservas.json()
        const datosCalificaciones = await respuestaCalificaciones.json()

        if (activo) {
          setAlojamientos(datosAlojamientos)
          setReservas(datosReservas)
          setCalificaciones(datosCalificaciones)
        }
      } catch (excepcion) {
        if (activo) {
          setError(excepcion.message)
        }
      } finally {
        if (activo) {
          setCargando(false)
        }
      }
    }

    cargar()

    return () => {
      activo = false
    }
  }, [])

  function reemplazar(actualizada) {
    setReservas((actuales) =>
      actuales.map((reserva) =>
        reserva.idReserva === actualizada.idReserva
          ? actualizada
          : reserva
      )
    )
  }

  async function aprobar(reserva) {
    setMensaje('')

    const respuesta = await enviarDatos(
      `/api/v1/reservas/${reserva.idReserva}/aprobar`,
      {},
      'PATCH'
    )

    if (!respuesta.ok) {
      setMensaje(
        await leerError(respuesta, 'No se pudo aprobar la reserva.')
      )
      return
    }

    reemplazar(await respuesta.json())
    setMensaje(`Reserva ${reserva.codigo} aprobada.`)
  }

  // El huésped no hizo check-in el día de llegada
  async function cancelarNoShow(reserva) {
    const seguro = window.confirm(
      `¿Cancelar la reserva ${reserva.codigo} porque ${reserva.nombreHuesped} no se presentó? ` +
        'La devolución sigue tu política de cancelación y las fechas quedan libres.'
    )

    if (!seguro) {
      return
    }

    setMensaje('')

    const respuesta = await enviarDatos(
      `/api/v1/reservas/${reserva.idReserva}/no-se-presento`,
      {},
      'PATCH'
    )

    if (!respuesta.ok) {
      setMensaje(
        await leerError(respuesta, 'No se pudo cancelar la reserva.')
      )
      return
    }

    reemplazar(await respuesta.json())
    setMensaje(
      `Reserva ${reserva.codigo} cancelada por no presentarse. Le avisamos al huésped por correo.`
    )
  }

  function abrirRechazo(reserva) {
    setARechazar(reserva)
    setMotivo('')
    ventana.current?.showModal()
  }

  async function rechazar(evento) {
    evento.preventDefault()

    const respuesta = await enviarDatos(
      `/api/v1/reservas/${aRechazar.idReserva}/rechazar`,
      { motivo },
      'PATCH'
    )

    ventana.current?.close()

    if (!respuesta.ok) {
      setMensaje(
        await leerError(respuesta, 'No se pudo rechazar la reserva.')
      )
      return
    }

    reemplazar(await respuesta.json())
    setMensaje(
      `Reserva ${aRechazar.codigo} rechazada. Se devolvió el pago al huésped.`
    )
  }

  const hoy = hoyTexto()
  const enUnMes = new Date()
  enUnMes.setDate(enUnMes.getDate() + 30)

  const activas = reservas.filter(
    (reserva) =>
      reserva.estado === 'CONFIRMADA' && reserva.fechaSalida > hoy
  )

  const proximasLlegadas = activas.filter(
    (reserva) =>
      reserva.fechaLlegada >= hoy &&
      aFecha(reserva.fechaLlegada) <= enUnMes
  )

  const ingresos = reservas
    .filter((reserva) =>
      ['CONFIRMADA', 'COMPLETADA'].includes(reserva.estado)
    )
    .reduce(
      (suma, reserva) =>
        suma + Number(reserva.subtotal) + Number(reserva.tarifaLimpieza),
      0
    )

  const pendientes = reservas.filter(
    (reserva) => reserva.estado === 'PENDIENTE_APROBACION'
  )

  const nombre = usuario?.nombre?.split(' ')[0]

  return (
    <section className="contenedor">
      <div className="panel-cabecera">
        <div>
          <h1 className="titulo-serif">¡Hola, {nombre}!</h1>
          <p className="texto-suave">
            Comparte tus alojamientos y conecta con viajeros de todo el
            país.
          </p>
        </div>
        <div className="viaje-acciones">
          <button
            type="button"
            className="boton-secundario"
            onClick={onCalendario}
          >
            ▦ Calendario y disponibilidad
          </button>
          <button
            type="button"
            className="boton-principal"
            onClick={onGestionarAlojamientos}
          >
            + Publicar un alojamiento
          </button>
        </div>
      </div>

      {cargando ? (
        <p className="cargando" role="status">
          Cargando tu panel...
        </p>
      ) : error ? (
        <p className="aviso aviso-error" role="alert">
          {error}
        </p>
      ) : (
        <>
          <div className="estadisticas">
            <article className="tarjeta">
              <span aria-hidden="true">⌂</span>
              <strong>{alojamientos.length}</strong>
              Mis alojamientos
            </article>
            <article className="tarjeta">
              <span aria-hidden="true">▦</span>
              <strong>{activas.length}</strong>
              Reservas activas
            </article>
            <article className="tarjeta">
              <span aria-hidden="true">♙</span>
              <strong>{proximasLlegadas.length}</strong>
              Próximas llegadas (30 días)
            </article>
            <article className="tarjeta">
              <span aria-hidden="true">▮</span>
              <strong>{pesos(ingresos)}</strong>
              Ingresos estimados
            </article>
          </div>

          {mensaje && (
            <p className="aviso" role="status">
              {mensaje}
            </p>
          )}

          {alojamientos.length === 0 && (
            <div className="tarjeta vacio">
              <span aria-hidden="true">🏡</span>
              <h2>Aún no tienes alojamientos publicados</h2>
              <p className="texto-suave">
                Publica tu primer alojamiento y empieza a recibir
                reservas. Es rápido y sencillo.
              </p>
              <button
                type="button"
                className="boton-principal"
                onClick={onGestionarAlojamientos}
              >
                + Publicar un alojamiento
              </button>
              <p className="aviso">
                Agrega al menos una foto y cambia el estado a
                &quot;Activa&quot; para que los huéspedes lo vean.
              </p>
            </div>
          )}

          {pendientes.length > 0 && (
            <article className="tarjeta">
              <h2>Solicitudes por aprobar</h2>
              <ul className="lista-recibidas">
                {pendientes.map((reserva) => (
                  <li key={reserva.idReserva}>
                    <div>
                      <strong>{reserva.nombreHuesped}</strong> ·{' '}
                      {reserva.tituloAlojamiento}
                      <p className="texto-suave">
                        {fechaCorta(reserva.fechaLlegada)} –{' '}
                        {fechaCorta(reserva.fechaSalida)} ·{' '}
                        {reserva.cantidadHuespedes} huéspedes ·{' '}
                        {reserva.codigo}
                      </p>
                    </div>
                    <div className="viaje-acciones">
                      <button
                        type="button"
                        className="boton-principal"
                        onClick={() => aprobar(reserva)}
                      >
                        Aprobar
                      </button>
                      <button
                        type="button"
                        className="boton-peligro"
                        onClick={() => abrirRechazo(reserva)}
                      >
                        Rechazar
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
            </article>
          )}

          <article className="tarjeta">
            <div className="tarjeta-titulo">
              <h2>Reservas recibidas</h2>
              <button
                type="button"
                className="boton-enlace"
                onClick={onGestionarAlojamientos}
              >
                Gestionar mis alojamientos
              </button>
            </div>

            {reservas.length === 0 ? (
              <p className="texto-suave">
                Todavía no has recibido reservas.
              </p>
            ) : (
              <ul className="anfitrion-reservas-lista">
                {reservas.map((reserva) => (
                  <li key={reserva.idReserva} className="anfitrion-reserva-tarjeta">
                    <div className="anfitrion-reserva-cabecera">
                      <div>
                        <p className="anfitrion-reserva-codigo">{reserva.codigo}</p>
                        <h3>{reserva.tituloAlojamiento}</h3>
                      </div>
                      <span className={`estado-reserva estado-${reserva.estado.toLowerCase()}`}>
                        {NOMBRES_ESTADO_RESERVA[reserva.estado]}
                      </span>
                    </div>
                    <dl className="anfitrion-reserva-datos">
                      <div><dt>Huésped</dt><dd>{reserva.nombreHuesped}</dd></div>
                      <div><dt>Fechas</dt><dd>
                        {fechaCorta(reserva.fechaLlegada)} – {fechaCorta(reserva.fechaSalida)}
                      </dd></div>
                      <div><dt>Huéspedes</dt><dd>{reserva.cantidadHuespedes}</dd></div>
                      <div><dt>Total de la reserva</dt><dd>{pesos(reserva.total)}</dd></div>
                    </dl>
                    <div className="anfitrion-reserva-checkin">
                      <strong>Check-in: </strong>
                      {reserva.checkInEn ? (
                        <span className="etiqueta-verde">
                          ✓ Realizado a las {horaBonita(reserva.checkInEn.slice(11, 16))}
                        </span>
                      ) : reserva.puedeCancelarNoShow ? (
                        <button type="button" className="boton-peligro" onClick={() => cancelarNoShow(reserva)}>
                          No se presentó
                        </button>
                      ) : reserva.estado === 'CONFIRMADA' && reserva.horaCheckIn ? (
                        <span>Desde {horaBonita(reserva.horaCheckIn)}</span>
                      ) : <span className="texto-suave">Sin registro</span>}
                    </div>
                    <div className="anfitrion-reserva-calificacion">
                      <h4>Tu calificación del huésped</h4>
                      <CalificarHuesped
                        reserva={reserva}
                        resena={calificaciones.find((resena) => resena.idReserva === reserva.idReserva)}
                        onGuardada={(resena) => {
                          setCalificaciones((actuales) => [
                            resena,
                            ...actuales.filter((actual) => actual.idReserva !== resena.idReserva),
                          ])
                          setMensaje(`Calificación del huésped guardada para ${reserva.codigo}.`)
                        }}
                      />
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </article>
        </>
      )}

      <dialog
        ref={ventana}
        className="modal-sesion modal-izquierda"
        aria-labelledby="rechazar-titulo"
      >
        <button
          type="button"
          className="modal-cerrar"
          onClick={() => ventana.current?.close()}
          aria-label="Cerrar"
        >
          ×
        </button>

        {aRechazar && (
          <form onSubmit={rechazar}>
            <h2 id="rechazar-titulo">Rechazar solicitud</h2>
            <p>
              {aRechazar.nombreHuesped} · {aRechazar.tituloAlojamiento}
            </p>
            <label className="campo-bloque">
              Motivo (lo verá el huésped)
              <textarea
                value={motivo}
                maxLength={500}
                rows={3}
                onChange={(evento) => setMotivo(evento.target.value)}
                required
              />
            </label>
            <button type="submit" className="boton-peligro boton-ancho">
              Rechazar y devolver el pago
            </button>
          </form>
        )}
      </dialog>
    </section>
  )
}

export default PanelAnfitrion
