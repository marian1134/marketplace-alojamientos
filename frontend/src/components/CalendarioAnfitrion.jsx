import { useEffect, useMemo, useState } from 'react'
import { consultar, enviarDatos, leerError } from '../api'
import { aTexto, fechaCorta, hoyTexto } from '../formato'

const DIAS = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do']

// Días de un mes para pintar la cuadrícula (empieza en lunes)
function diasDelMes(anio, mes) {
  const primero = new Date(anio, mes, 1)
  const huecos = (primero.getDay() + 6) % 7
  const total = new Date(anio, mes + 1, 0).getDate()

  return [
    ...Array.from({ length: huecos }, () => null),
    ...Array.from({ length: total }, (_, indice) => new Date(anio, mes, indice + 1)),
  ]
}

function Mes({ anio, mes, estadoDelDia }) {
  const nombre = new Date(anio, mes, 1).toLocaleDateString('es-CO', {
    month: 'long',
    year: 'numeric',
  })

  return (
    <div className="mes">
      <h3>{nombre}</h3>
      <div className="mes-grilla">
        {DIAS.map((dia) => (
          <span key={dia} className="mes-dia-nombre">
            {dia}
          </span>
        ))}

        {diasDelMes(anio, mes).map((fecha, indice) => {
          if (!fecha) {
            return <span key={`hueco-${indice}`} />
          }

          const { clase, detalle } = estadoDelDia(aTexto(fecha))

          return (
            <span
              key={aTexto(fecha)}
              className={`mes-dia ${clase}`}
              title={detalle}
            >
              {fecha.getDate()}
            </span>
          )
        })}
      </div>
    </div>
  )
}

function CalendarioAnfitrion({ onGestionarAlojamientos }) {
  const [alojamientos, setAlojamientos] = useState([])
  const [idElegido, setIdElegido] = useState('')
  const [calendario, setCalendario] = useState(null)
  const [cargando, setCargando] = useState(true)
  const [mensaje, setMensaje] = useState('')
  const [error, setError] = useState('')
  const [inicio, setInicio] = useState('')
  const [fin, setFin] = useState('')

  const hoy = new Date()
  const [mesVisible, setMesVisible] = useState({
    anio: hoy.getFullYear(),
    mes: hoy.getMonth(),
  })

  // Lista de alojamientos del anfitrión
  useEffect(() => {
    let activo = true

    consultar('/api/v1/alojamientos/mis-alojamientos')
      .then((respuesta) => (respuesta.ok ? respuesta.json() : []))
      .then((datos) => {
        if (activo) {
          setAlojamientos(datos)
          setIdElegido(datos[0]?.idAlojamiento ?? '')
          setCargando(false)
        }
      })
      .catch(() => {
        if (activo) {
          setError('No se pudieron cargar tus alojamientos.')
          setCargando(false)
        }
      })

    return () => {
      activo = false
    }
  }, [])

  // Calendario del alojamiento elegido
  useEffect(() => {
    if (!idElegido) {
      return
    }

    let activo = true

    consultar(`/api/v1/alojamientos/${idElegido}/calendario`)
      .then(async (respuesta) => {
        if (!respuesta.ok) {
          throw new Error(
            await leerError(respuesta, 'No se pudo cargar el calendario.')
          )
        }
        return respuesta.json()
      })
      .then((datos) => {
        if (activo) {
          setCalendario(datos)
          setError('')
        }
      })
      .catch((excepcion) => {
        if (activo) {
          setError(excepcion.message)
        }
      })

    return () => {
      activo = false
    }
  }, [idElegido])

  const reservadas = useMemo(
    () =>
      new Map(
        (calendario?.nochesReservadas ?? []).map((noche) => [noche.fecha, noche])
      ),
    [calendario]
  )

  function estadoDelDia(fecha) {
    const reserva = reservadas.get(fecha)

    if (reserva) {
      return {
        clase: 'reservado',
        detalle: `Reservado: ${reserva.codigoReserva} · ${reserva.nombreHuesped}`,
      }
    }

    if (fecha < hoyTexto()) {
      return { clase: 'pasado', detalle: '' }
    }

    const periodos = calendario?.periodos ?? []

    // La noche de la fecha fin no cuenta: es el día de salida
    const disponible =
      periodos.length === 0 ||
      periodos.some(
        (periodo) => fecha >= periodo.fechaInicio && fecha < periodo.fechaFin
      )

    return disponible
      ? { clase: 'disponible', detalle: 'Disponible' }
      : { clase: 'cerrado', detalle: 'No recibes huéspedes' }
  }

  async function agregarPeriodo(evento) {
    evento.preventDefault()
    setMensaje('')

    const respuesta = await enviarDatos(
      `/api/v1/alojamientos/${idElegido}/periodos`,
      { fechaInicio: inicio, fechaFin: fin }
    )

    if (!respuesta.ok) {
      setMensaje(await leerError(respuesta, 'No se pudo guardar el periodo.'))
      return
    }

    setCalendario(await respuesta.json())
    setInicio('')
    setFin('')
  }

  async function eliminarPeriodo(idPeriodo) {
    setMensaje('')

    const respuesta = await enviarDatos(
      `/api/v1/periodos/${idPeriodo}`,
      {},
      'DELETE'
    )

    if (!respuesta.ok) {
      setMensaje(await leerError(respuesta, 'No se pudo borrar el periodo.'))
      return
    }

    setCalendario(await respuesta.json())
  }

  function moverMes(cantidad) {
    const fecha = new Date(mesVisible.anio, mesVisible.mes + cantidad, 1)
    setMesVisible({ anio: fecha.getFullYear(), mes: fecha.getMonth() })
  }

  const siguiente = new Date(mesVisible.anio, mesVisible.mes + 1, 1)

  return (
    <section className="contenedor">
      <h1 className="titulo-serif">Calendario y disponibilidad</h1>
      <p className="texto-suave">
        Elige en qué fechas recibes huéspedes y mira tus noches reservadas.
      </p>

      {cargando ? (
        <p className="cargando" role="status">
          Cargando...
        </p>
      ) : alojamientos.length === 0 ? (
        <div className="tarjeta vacio">
          <span aria-hidden="true">🏡</span>
          <h2>Primero publica un alojamiento</h2>
          <button
            type="button"
            className="boton-principal"
            onClick={onGestionarAlojamientos}
          >
            + Publicar un alojamiento
          </button>
        </div>
      ) : (
        <>
          <label className="campo-alojamiento">
            Alojamiento
            <select
              value={idElegido}
              onChange={(evento) => {
                setCalendario(null)
                setIdElegido(Number(evento.target.value))
              }}
            >
              {alojamientos.map((alojamiento) => (
                <option
                  key={alojamiento.idAlojamiento}
                  value={alojamiento.idAlojamiento}
                >
                  {alojamiento.titulo} · {alojamiento.ciudad}
                </option>
              ))}
            </select>
          </label>

          {error && (
            <p className="aviso aviso-error" role="alert">
              {error}
            </p>
          )}

          {calendario && (
            <div className="calendario-columnas">
              <article className="tarjeta">
                <div className="tarjeta-titulo">
                  <button
                    type="button"
                    className="boton-secundario"
                    onClick={() => moverMes(-1)}
                    aria-label="Mes anterior"
                  >
                    ‹
                  </button>
                  <div className="leyenda">
                    <span><i className="disponible" /> Disponible</span>
                    <span><i className="reservado" /> Reservado</span>
                    <span><i className="cerrado" /> No recibes</span>
                  </div>
                  <button
                    type="button"
                    className="boton-secundario"
                    onClick={() => moverMes(1)}
                    aria-label="Mes siguiente"
                  >
                    ›
                  </button>
                </div>

                <div className="meses">
                  <Mes
                    anio={mesVisible.anio}
                    mes={mesVisible.mes}
                    estadoDelDia={estadoDelDia}
                  />
                  <Mes
                    anio={siguiente.getFullYear()}
                    mes={siguiente.getMonth()}
                    estadoDelDia={estadoDelDia}
                  />
                </div>

                <p className="texto-suave">
                  Pasa el mouse sobre un día reservado para ver el código y el
                  huésped.
                </p>
              </article>

              <aside className="tarjeta">
                <h2>Fechas en que recibes huéspedes</h2>

                {calendario.periodos.length === 0 ? (
                  <p className="aviso">
                    No has definido periodos, así que tu alojamiento está
                    disponible todos los días. Agrega uno si solo quieres
                    recibir huéspedes en ciertas fechas.
                  </p>
                ) : (
                  <ul className="lista-periodos">
                    {calendario.periodos.map((periodo) => (
                      <li key={periodo.idPeriodo}>
                        <span>
                          {fechaCorta(periodo.fechaInicio)} –{' '}
                          {fechaCorta(periodo.fechaFin)}
                        </span>
                        <button
                          type="button"
                          className="boton-enlace"
                          onClick={() => eliminarPeriodo(periodo.idPeriodo)}
                        >
                          Quitar
                        </button>
                      </li>
                    ))}
                  </ul>
                )}

                <form onSubmit={agregarPeriodo}>
                  <h3>Agregar periodo</h3>
                  <div className="dos-columnas">
                    <label>
                      Desde
                      <input
                        type="date"
                        value={inicio}
                        min={hoyTexto()}
                        onChange={(evento) => setInicio(evento.target.value)}
                        required
                      />
                    </label>
                    <label>
                      Hasta
                      <input
                        type="date"
                        value={fin}
                        min={inicio || hoyTexto()}
                        onChange={(evento) => setFin(evento.target.value)}
                        required
                      />
                    </label>
                  </div>

                  {mensaje && (
                    <p className="aviso aviso-error" role="alert">
                      {mensaje}
                    </p>
                  )}

                  <button type="submit" className="boton-principal boton-ancho">
                    Guardar periodo
                  </button>
                </form>
              </aside>
            </div>
          )}
        </>
      )}
    </section>
  )
}

export default CalendarioAnfitrion
