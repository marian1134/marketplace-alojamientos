import { useEffect, useRef, useState } from 'react'
import { consultar, enviarDatos, leerError } from '../api'
import {
  aFecha,
  fechaCorta,
  hoyTexto,
  NOMBRES_ESTADO_RESERVA,
  pesos,
} from '../formato'

function PanelAnfitrion({ usuario, onGestionarAlojamientos }) {
  const [alojamientos, setAlojamientos] = useState([])
  const [reservas, setReservas] = useState([])
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
        const [respuestaAlojamientos, respuestaReservas] =
          await Promise.all([
            consultar('/api/v1/alojamientos/mis-alojamientos'),
            consultar('/api/v1/reservas/recibidas'),
          ])

        if (!respuestaAlojamientos.ok || !respuestaReservas.ok) {
          throw new Error('No se pudo cargar tu panel.')
        }

        const datosAlojamientos = await respuestaAlojamientos.json()
        const datosReservas = await respuestaReservas.json()

        if (activo) {
          setAlojamientos(datosAlojamientos)
          setReservas(datosReservas)
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
        <button
          type="button"
          className="boton-principal"
          onClick={onGestionarAlojamientos}
        >
          + Publicar un alojamiento
        </button>
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
              <div className="tabla-scroll">
                <table className="tabla">
                  <thead>
                    <tr>
                      <th>Código</th>
                      <th>Huésped</th>
                      <th>Alojamiento</th>
                      <th>Fechas</th>
                      <th>Estado</th>
                      <th>Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reservas.map((reserva) => (
                      <tr key={reserva.idReserva}>
                        <td>{reserva.codigo}</td>
                        <td>{reserva.nombreHuesped}</td>
                        <td>{reserva.tituloAlojamiento}</td>
                        <td>
                          {fechaCorta(reserva.fechaLlegada)} –{' '}
                          {fechaCorta(reserva.fechaSalida)}
                        </td>
                        <td>
                          <span
                            className={`estado-reserva estado-${reserva.estado.toLowerCase()}`}
                          >
                            {NOMBRES_ESTADO_RESERVA[reserva.estado]}
                          </span>
                        </td>
                        <td>{pesos(reserva.total)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
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
