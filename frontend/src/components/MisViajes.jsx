import { useEffect, useRef, useState } from 'react'
import { consultar, enviarDatos, leerError } from '../api'
import { Estrellas, IconoEstrella } from './Iconos'
import {
  fechaCorta,
  fotoRespaldo,
  NOMBRES_ESTADO_RESERVA,
  NOMBRES_POLITICA,
  pesos,
} from '../formato'

const PESTANAS = [
  {
    id: 'proximos',
    texto: 'Próximos',
    estados: ['CONFIRMADA', 'PENDIENTE_APROBACION'],
  },
  {
    id: 'pasados',
    texto: 'Pasados',
    estados: ['COMPLETADA'],
  },
  {
    id: 'cancelados',
    texto: 'Cancelados',
    estados: ['CANCELADA', 'RECHAZADA', 'ANULADA'],
  },
]

function MisViajes({ onExplorar, onVerAlojamiento }) {
  const [reservas, setReservas] = useState([])
  const [cargando, setCargando] = useState(true)
  const [error, setError] = useState('')
  const [pestana, setPestana] = useState('proximos')
  const [aCancelar, setACancelar] = useState(null)
  const [motivo, setMotivo] = useState('')
  const [cancelando, setCancelando] = useState(false)
  const [mensaje, setMensaje] = useState('')
  const ventana = useRef(null)

  // Ventana para dejar reseña
  const ventanaResena = useRef(null)
  const [aResenar, setAResenar] = useState(null)
  const [estrellas, setEstrellas] = useState(5)
  const [comentario, setComentario] = useState('')
  const [enviandoResena, setEnviandoResena] = useState(false)
  const [mensajeResena, setMensajeResena] = useState('')

  async function cargar() {
    try {
      const respuesta = await consultar('/api/v1/reservas/mis-reservas')

      if (!respuesta.ok) {
        throw new Error(
          await leerError(respuesta, 'No se pudieron cargar tus viajes.')
        )
      }

      setReservas(await respuesta.json())
      setError('')
    } catch (excepcion) {
      setError(excepcion.message)
    } finally {
      setCargando(false)
    }
  }

  useEffect(() => {
    cargar()
  }, [])

  function abrirCancelacion(reserva) {
    setACancelar(reserva)
    setMotivo('')
    setMensaje('')
    ventana.current?.showModal()
  }

  async function confirmarCancelacion(evento) {
    evento.preventDefault()

    if (!motivo.trim()) {
      setMensaje('Cuéntanos el motivo de la cancelación.')
      return
    }

    setCancelando(true)

    try {
      const respuesta = await enviarDatos(
        `/api/v1/reservas/${aCancelar.idReserva}/cancelar`,
        { motivo }
      )

      if (!respuesta.ok) {
        setMensaje(
          await leerError(respuesta, 'No se pudo cancelar la reserva.')
        )
        return
      }

      const cancelada = await respuesta.json()

      ventana.current?.close()
      setReservas((actuales) =>
        actuales.map((reserva) =>
          reserva.idReserva === cancelada.idReserva ? cancelada : reserva
        )
      )
      setPestana('cancelados')
    } catch {
      setMensaje('No se pudo conectar con el servidor.')
    } finally {
      setCancelando(false)
    }
  }

  function abrirResena(reserva) {
    setAResenar(reserva)
    setEstrellas(5)
    setComentario('')
    setMensajeResena('')
    ventanaResena.current?.showModal()
  }

  async function enviarResena(evento) {
    evento.preventDefault()

    if (comentario.trim().length < 10) {
      setMensajeResena('Cuéntanos un poco más (mínimo 10 caracteres).')
      return
    }

    setEnviandoResena(true)

    try {
      const respuesta = await enviarDatos(
        `/api/v1/reservas/${aResenar.idReserva}/resena`,
        { calificacion: estrellas, comentario }
      )

      if (!respuesta.ok) {
        setMensajeResena(
          await leerError(respuesta, 'No se pudo guardar tu reseña.')
        )
        return
      }

      ventanaResena.current?.close()
      setReservas((actuales) =>
        actuales.map((reserva) =>
          reserva.idReserva === aResenar.idReserva
            ? {
                ...reserva,
                puedeResenar: false,
                calificacionResena: estrellas,
              }
            : reserva
        )
      )
    } catch {
      setMensajeResena('No se pudo conectar con el servidor.')
    } finally {
      setEnviandoResena(false)
    }
  }

  const estadosVisibles = PESTANAS.find(
    (item) => item.id === pestana
  ).estados

  const visibles = reservas.filter((reserva) =>
    estadosVisibles.includes(reserva.estado)
  )

  return (
    <section className="contenedor">
      <h1 className="titulo-serif">Mis viajes</h1>
      <p className="texto-suave">
        Aquí ves tus reservas, su estado y puedes cancelarlas según la
        política del alojamiento.
      </p>

      <div className="pestanas" role="tablist">
        {PESTANAS.map((item) => {
          const cantidad = reservas.filter((reserva) =>
            item.estados.includes(reserva.estado)
          ).length

          return (
            <button
              key={item.id}
              type="button"
              role="tab"
              aria-selected={pestana === item.id}
              className={pestana === item.id ? 'activa' : ''}
              onClick={() => setPestana(item.id)}
            >
              {item.texto} <span>{cantidad}</span>
            </button>
          )
        })}
      </div>

      {cargando ? (
        <p className="cargando" role="status">
          Cargando tus viajes...
        </p>
      ) : error ? (
        <p className="aviso aviso-error" role="alert">
          {error}
        </p>
      ) : visibles.length === 0 ? (
        <div className="tarjeta vacio">
          <span aria-hidden="true">🧳</span>
          <h2>
            {pestana === 'proximos'
              ? 'Aún no tienes viajes próximos'
              : 'No hay reservas en esta sección'}
          </h2>
          <p className="texto-suave">
            Explora alojamientos y reserva tu próxima aventura.
          </p>
          <button
            type="button"
            className="boton-principal"
            onClick={onExplorar}
          >
            Explorar alojamientos
          </button>
        </div>
      ) : (
        <ul className="lista-viajes">
          {visibles.map((reserva) => (
            <li key={reserva.idReserva} className="tarjeta viaje">
              {reserva.imagenPortada ? (
                <img
                  src={reserva.imagenPortada}
                  alt=""
                  onError={fotoRespaldo}
                />
              ) : (
                <div className="sin-foto sin-foto-baja">⌂</div>
              )}

              <div className="viaje-info">
                <div className="tarjeta-titulo">
                  <h2>{reserva.tituloAlojamiento}</h2>
                  <span
                    className={`estado-reserva estado-${reserva.estado.toLowerCase()}`}
                  >
                    {NOMBRES_ESTADO_RESERVA[reserva.estado]}
                  </span>
                </div>

                <p className="texto-suave">
                  ⌖ {reserva.ciudad} · Código{' '}
                  <strong>{reserva.codigo}</strong>
                </p>

                <p>
                  {fechaCorta(reserva.fechaLlegada)} –{' '}
                  {fechaCorta(reserva.fechaSalida)} · {reserva.noches}{' '}
                  {reserva.noches === 1 ? 'noche' : 'noches'} ·{' '}
                  {reserva.cantidadHuespedes}{' '}
                  {reserva.cantidadHuespedes === 1
                    ? 'huésped'
                    : 'huéspedes'}
                </p>

                <p>
                  Total pagado: <strong>{pesos(reserva.total)}</strong>
                  {reserva.ultimos4 &&
                    ` · Tarjeta terminada en ${reserva.ultimos4}`}
                </p>

                {reserva.valorDevolucion && (
                  <p className="etiqueta-verde">
                    Devolución: {pesos(reserva.valorDevolucion)}
                  </p>
                )}

                {reserva.motivo && (
                  <p className="texto-suave">
                    Motivo: {reserva.motivo}
                  </p>
                )}

                {reserva.calificacionResena && (
                  <p className="tu-resena">
                    Tu reseña:{' '}
                    <Estrellas valor={reserva.calificacionResena} />
                  </p>
                )}

                <div className="viaje-acciones">
                  {reserva.puedeResenar && (
                    <button
                      type="button"
                      className="boton-principal"
                      onClick={() => abrirResena(reserva)}
                    >
                      ★ Dejar reseña
                    </button>
                  )}

                  <button
                    type="button"
                    className="boton-secundario"
                    onClick={() =>
                      onVerAlojamiento(reserva.idAlojamiento)
                    }
                  >
                    Ver alojamiento
                  </button>

                  {reserva.puedeCancelar && (
                    <button
                      type="button"
                      className="boton-peligro"
                      onClick={() => abrirCancelacion(reserva)}
                    >
                      Cancelar reserva
                    </button>
                  )}
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}

      <dialog
        ref={ventanaResena}
        className="modal-sesion modal-izquierda"
        aria-labelledby="resena-titulo"
      >
        <button
          type="button"
          className="modal-cerrar"
          onClick={() => ventanaResena.current?.close()}
          aria-label="Cerrar"
        >
          ×
        </button>

        {aResenar && (
          <form onSubmit={enviarResena}>
            <h2 id="resena-titulo">¿Cómo te fue?</h2>
            <p>
              {aResenar.tituloAlojamiento} · {aResenar.ciudad}
            </p>

            <div
              className="elegir-estrellas"
              role="radiogroup"
              aria-label="Calificación"
            >
              {[1, 2, 3, 4, 5].map((numero) => (
                <button
                  key={numero}
                  type="button"
                  role="radio"
                  aria-checked={estrellas === numero}
                  aria-label={`${numero} ${numero === 1 ? 'estrella' : 'estrellas'}`}
                  className={numero <= estrellas ? 'llena' : ''}
                  onClick={() => setEstrellas(numero)}
                >
                  <IconoEstrella tamano={34} activo={numero <= estrellas} />
                </button>
              ))}
            </div>

            <label className="campo-bloque">
              Cuéntales a otros viajeros tu experiencia
              <textarea
                value={comentario}
                maxLength={1000}
                rows={4}
                placeholder="¿Qué fue lo que más te gustó?"
                onChange={(evento) => {
                  setComentario(evento.target.value)
                  setMensajeResena('')
                }}
                required
              />
            </label>

            {mensajeResena && (
              <p className="aviso aviso-error" role="alert">
                {mensajeResena}
              </p>
            )}

            <button
              type="submit"
              className="boton-principal boton-ancho"
              disabled={enviandoResena}
            >
              {enviandoResena ? 'Enviando...' : 'Publicar reseña'}
            </button>
          </form>
        )}
      </dialog>

      <dialog
        ref={ventana}
        className="modal-sesion modal-izquierda"
        aria-labelledby="cancelar-titulo"
      >
        <button
          type="button"
          className="modal-cerrar"
          onClick={() => ventana.current?.close()}
          aria-label="Cerrar"
        >
          ×
        </button>

        {aCancelar && (
          <form onSubmit={confirmarCancelacion}>
            <h2 id="cancelar-titulo">Cancelar reserva</h2>
            <p>
              {aCancelar.tituloAlojamiento} ·{' '}
              {fechaCorta(aCancelar.fechaLlegada)} –{' '}
              {fechaCorta(aCancelar.fechaSalida)}
            </p>
            <p className="aviso">
              Esta reserva tiene{' '}
              <strong>
                {NOMBRES_POLITICA[aCancelar.tipoPolitica]?.toLowerCase()}
              </strong>
              . La devolución se calcula según los días que faltan para
              la llegada.
            </p>

            <label className="campo-bloque">
              Motivo de la cancelación
              <textarea
                value={motivo}
                maxLength={500}
                rows={3}
                onChange={(evento) => {
                  setMotivo(evento.target.value)
                  setMensaje('')
                }}
                required
              />
            </label>

            {mensaje && (
              <p className="aviso aviso-error" role="alert">
                {mensaje}
              </p>
            )}

            <button
              type="submit"
              className="boton-peligro boton-ancho"
              disabled={cancelando}
            >
              {cancelando ? 'Cancelando...' : 'Sí, cancelar reserva'}
            </button>
            <button
              type="button"
              className="boton-secundario boton-ancho"
              onClick={() => ventana.current?.close()}
            >
              No, mantener reserva
            </button>
          </form>
        )}
      </dialog>
    </section>
  )
}

export default MisViajes
