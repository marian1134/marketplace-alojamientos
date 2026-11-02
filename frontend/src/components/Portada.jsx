import { useEffect, useRef, useState } from 'react'
import { NOMBRES_TIPO } from '../tipos'
import { DESTINOS } from '../destinos'
import TarjetaDestino from './TarjetaDestino'

function IconoCasa() {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      className="portada-icono-logo"
    >
      <path
        d="M3 10.5 12 3l9 7.5M5.5 9.5V21h13V9.5M9 21v-7h6v7"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

// Casa con candado del mockup "Inicia sesión para continuar"
function IlustracionCandado() {
  return (
    <svg
      viewBox="0 0 220 120"
      aria-hidden="true"
      className="modal-sesion-ilustracion"
    >
      <ellipse cx="110" cy="70" rx="100" ry="48" fill="#f6ede4" />
      <path
        d="M20 108h180"
        stroke="#7a9a6a"
        strokeWidth="4"
        strokeLinecap="round"
      />
      <circle cx="42" cy="84" r="14" fill="#8fb48a" />
      <rect x="40" y="94" width="4" height="14" fill="#6b5a45" />
      <circle cx="180" cy="80" r="16" fill="#7fa77c" />
      <rect x="178" y="92" width="4" height="16" fill="#6b5a45" />
      <path d="M62 66 110 34l48 32" fill="#6d4c3d" />
      <rect x="70" y="64" width="80" height="44" rx="2" fill="#d9a77c" />
      <rect x="102" y="82" width="16" height="26" rx="2" fill="#7b5236" />
      <rect x="80" y="74" width="12" height="10" rx="1" fill="#557a6a" />
      <rect x="128" y="74" width="12" height="10" rx="1" fill="#557a6a" />
      <path
        d="M98 30v-8a12 12 0 0 1 24 0v8"
        fill="none"
        stroke="#b07d55"
        strokeWidth="5"
      />
      <rect x="94" y="28" width="32" height="24" rx="4" fill="#c99366" />
      <circle cx="110" cy="40" r="3" fill="#6d4c3d" />
    </svg>
  )
}

function Portada({
  usuario,
  onIniciarSesion,
  onRegistrarse,
  onNavegar,
  onCerrarSesion,
  onVerAlojamiento,
}) {
  const [destino, setDestino] = useState('')
  const [entrada, setEntrada] = useState('')
  const [salida, setSalida] = useState('')
  const [huespedes, setHuespedes] = useState('2')
  const [mensajeBusqueda, setMensajeBusqueda] =
    useState('')

  const [alojamientos, setAlojamientos] = useState([])
  const [cargandoAlojamientos, setCargandoAlojamientos] =
    useState(true)

  const [mensajeAlojamientos, setMensajeAlojamientos] =
    useState('')

  // Ventana que pide iniciar sesión antes de buscar
  const ventanaSesion = useRef(null)

  // Alojamiento que quiso abrir sin sesión (se abre después del login)
  const alojamientoDeseado = useRef(null)

  function pedirSesion(idAlojamiento) {
    alojamientoDeseado.current = idAlojamiento ?? null

    const ventana = ventanaSesion.current

    if (ventana && !ventana.open) {
      ventana.showModal()
    }
  }

  function cerrarVentanaSesion() {
    ventanaSesion.current?.close()
  }

  function abrirAlojamiento(idAlojamiento) {
    if (!usuario) {
      pedirSesion(idAlojamiento)
      return
    }

    onVerAlojamiento(idAlojamiento, {
      entrada,
      salida,
      huespedes,
    })
  }

  // Sin sesión, cualquier clic en el buscador abre la ventana
  function revisarSesion(evento) {
    if (!usuario) {
      evento.preventDefault()
      pedirSesion()
    }
  }

  const [filtros, setFiltros] = useState({
    destino: '',
    huespedes: 0,
  })

  const fechaActual = new Date()

  const fechaMinima = [
    fechaActual.getFullYear(),
    String(fechaActual.getMonth() + 1).padStart(
      2,
      '0'
    ),
    String(fechaActual.getDate()).padStart(2, '0'),
  ].join('-')

  useEffect(() => {
    let activo = true

    async function cargarAlojamientos() {
      try {
        const respuesta = await fetch(
          '/api/v1/alojamientos',
          {
            credentials: 'same-origin',
            cache: 'no-store',
          }
        )

        if (!respuesta.ok) {
          throw new Error(
            'No se pudieron consultar los alojamientos'
          )
        }

        const datos = await respuesta.json()

        const alojamientosConPortada =
          await Promise.all(
            datos.map(async (alojamiento) => {
              try {
                const respuestaImagenes = await fetch(
                  `/api/v1/alojamientos/${alojamiento.idAlojamiento}/imagenes`,
                  {
                    credentials: 'same-origin',
                    cache: 'no-store',
                  }
                )

                if (!respuestaImagenes.ok) {
                  return {
                    ...alojamiento,
                    imagenPortada: null,
                  }
                }

                const imagenes =
                  await respuestaImagenes.json()

                const portada =
                  imagenes.find(
                    (imagen) => imagen.principal
                  ) ?? imagenes[0]

                return {
                  ...alojamiento,
                  imagenPortada:
                    portada?.urlImagen ?? null,
                }
              } catch {
                return {
                  ...alojamiento,
                  imagenPortada: null,
                }
              }
            })
          )

        if (activo) {
          setAlojamientos(
            alojamientosConPortada
          )
        }
      } catch {
        if (activo) {
          setMensajeAlojamientos(
            'No se pudieron cargar los alojamientos disponibles.'
          )
        }
      } finally {
        if (activo) {
          setCargandoAlojamientos(false)
        }
      }
    }

    cargarAlojamientos()

    return () => {
      activo = false
    }
  }, [])

  function contarEnDestino(destino) {
    return alojamientos.filter((alojamiento) =>
      destino.ciudades.includes(
        alojamiento.ciudad?.toLocaleLowerCase('es')
      )
    ).length
  }

  // Al tocar un destino se muestran sus alojamientos
  function elegirDestino(destino) {
    if (!usuario) {
      pedirSesion()
      return
    }

    setDestino(destino.nombre)
    setFiltros({
      destino: destino.nombre,
      ciudades: destino.ciudades,
      huespedes: 0,
    })

    document
      .querySelector('#alojamientos-destacados')
      ?.scrollIntoView({ behavior: 'smooth' })
  }

  // Si no hay alojamientos publicados, la sección no se muestra
  const hayAlojamientos =
    cargandoAlojamientos ||
    mensajeAlojamientos !== '' ||
    alojamientos.length > 0

  const alojamientosFiltrados =
    alojamientos.filter((alojamiento) => {
      const ciudad =
        alojamiento.ciudad?.toLocaleLowerCase(
          'es'
        ) ?? ''

      const titulo =
        alojamiento.titulo?.toLocaleLowerCase(
          'es'
        ) ?? ''

      const destinoBuscado =
        filtros.destino
          .trim()
          .toLocaleLowerCase('es')

      const coincideDestino =
        destinoBuscado === '' ||
        filtros.ciudades?.includes(ciudad) ||
        ciudad.includes(destinoBuscado) ||
        titulo.includes(destinoBuscado)

      const coincideCapacidad =
        Number(filtros.huespedes) === 0 ||
        Number(alojamiento.capacidad) >=
          Number(filtros.huespedes)

      return coincideDestino && coincideCapacidad
    })

  function buscarAlojamientos(evento) {
    evento.preventDefault()
    setMensajeBusqueda('')

    if (!usuario) {
      pedirSesion()
      return
    }

    const cantidadHuespedes = Number(huespedes)

    if (!destino.trim()) {
      setMensajeBusqueda(
        'Escribe la ciudad o el destino que deseas buscar.'
      )
      return
    }

    if (!entrada || !salida) {
      setMensajeBusqueda(
        'Selecciona las fechas de entrada y salida.'
      )
      return
    }

    if (entrada < fechaMinima) {
      setMensajeBusqueda(
        'La fecha de entrada no puede estar en el pasado.'
      )
      return
    }

    if (salida <= entrada) {
      setMensajeBusqueda(
        'La fecha de salida debe ser posterior a la fecha de entrada.'
      )
      return
    }

    if (
      !Number.isInteger(cantidadHuespedes) ||
      cantidadHuespedes < 1
    ) {
      setMensajeBusqueda(
        'La cantidad de huéspedes debe ser un número entero mayor que cero.'
      )
      return
    }

    setFiltros({
      destino: destino.trim(),
      huespedes: cantidadHuespedes,
    })

    document
      .querySelector('#alojamientos-destacados')
      ?.scrollIntoView({
        behavior: 'smooth',
      })
  }

  return (
    <main className="portada-publica">
      <section className="portada-hero">
        <header className="portada-navegacion">
          <button
            type="button"
            className="portada-logo"
            onClick={() =>
              window.scrollTo({
                top: 0,
                behavior: 'smooth',
              })
            }
          >
            <IconoCasa />
            <span>StayHub</span>
          </button>

          <nav aria-label="Navegación principal">
            <a
              href={
                alojamientos.length > 0
                  ? '#alojamientos-destacados'
                  : '#destinos-populares'
              }
            >
              Alojamientos
            </a>

            <a href="#como-funciona">
              Cómo funciona
            </a>

            <a href="#sobre-nosotros">
              Sobre nosotros
            </a>
          </nav>

          <div className="portada-acciones">
            <span className="portada-idioma">
              ◉ ES⌄
            </span>

            {usuario ? (
              <>
                <button
                  type="button"
                  className="portada-boton-claro"
                  onClick={() => onNavegar('viajes')}
                >
                  Mis viajes
                </button>

                {usuario.rol === 'ANFITRION' && (
                  <button
                    type="button"
                    className="portada-boton-claro"
                    onClick={() => onNavegar('panel')}
                  >
                    Panel anfitrión
                  </button>
                )}

                <button
                  type="button"
                  className="portada-boton-principal"
                  onClick={() => onNavegar('perfil')}
                  title="Mi perfil"
                >
                  {usuario.nombre.split(' ')[0]}
                </button>

                <button
                  type="button"
                  className="portada-boton-claro"
                  onClick={onCerrarSesion}
                >
                  Salir
                </button>
              </>
            ) : (
              <>
                <button
                  type="button"
                  className="portada-boton-claro"
                  onClick={() => onIniciarSesion()}
                >
                  Iniciar sesión
                </button>

                <button
                  type="button"
                  className="portada-boton-principal"
                  onClick={() => onRegistrarse()}
                >
                  Registrarse
                </button>
              </>
            )}
          </div>
        </header>

        <div className="portada-contenido">
          <h1>
            Tu próxima aventura
            <br />
            empieza aquí
          </h1>

          <p>
            Descubre alojamientos únicos en los mejores
            destinos de Colombia.
          </p>

          <form
            className="portada-buscador"
            onSubmit={buscarAlojamientos}
            onClick={revisarSesion}
            noValidate
          >
            <label>
              <span className="buscador-icono">⌖</span>

              <span className="buscador-campo">
                <strong>¿A dónde vas?</strong>

                <input
                  type="text"
                  value={destino}
                  onChange={(evento) => {
                    setDestino(evento.target.value)
                    setMensajeBusqueda('')
                  }}
                  placeholder="Ciudad o destino"
                  readOnly={!usuario}
                  required
                />
              </span>
            </label>

            <label>
              <span className="buscador-icono">□</span>

              <span className="buscador-campo">
                <strong>Entrada</strong>

                <input
                  type="date"
                  value={entrada}
                  min={fechaMinima}
                  onChange={(evento) => {
                    setEntrada(evento.target.value)
                    setMensajeBusqueda('')

                    if (
                      salida &&
                      salida <= evento.target.value
                    ) {
                      setSalida('')
                    }
                  }}
                  readOnly={!usuario}
                  required
                />
              </span>
            </label>

            <label>
              <span className="buscador-icono">□</span>

              <span className="buscador-campo">
                <strong>Salida</strong>

                <input
                  type="date"
                  value={salida}
                  min={entrada || fechaMinima}
                  onChange={(evento) => {
                    setSalida(evento.target.value)
                    setMensajeBusqueda('')
                  }}
                  readOnly={!usuario}
                  required
                />
              </span>
            </label>

            <label>
              <span className="buscador-icono">♙</span>

              <span className="buscador-campo">
                <strong>Huéspedes</strong>

                <input
                  type="number"
                  value={huespedes}
                  min="1"
                  step="1"
                  onChange={(evento) => {
                    setHuespedes(
                      evento.target.value
                    )
                    setMensajeBusqueda('')
                  }}
                  placeholder="Cantidad"
                  readOnly={!usuario}
                  required
                />
              </span>
            </label>

            <button
              type="submit"
              className="portada-boton-buscar"
            >
              <span aria-hidden="true">⌕</span>
              Buscar
            </button>
          </form>

          {mensajeBusqueda && (
            <p
              className="portada-mensaje-busqueda"
              role="alert"
            >
              {mensajeBusqueda}
            </p>
          )}
        </div>

        <div
          className="portada-beneficios"
        >
          <article>
            <span aria-hidden="true">⌂</span>

            <div>
              <strong>
                Alojamientos verificados
              </strong>

              <p>Estancias seguras y confiables</p>
            </div>
          </article>

          <article>
            <span aria-hidden="true">◆</span>

            <div>
              <strong>
                Reserva fácil y segura
              </strong>

              <p>Tu tranquilidad es lo primero</p>
            </div>
          </article>

          <article>
            <span aria-hidden="true">★</span>

            <div>
              <strong>Experiencias únicas</strong>

              <p>
                Destinos increíbles en un solo lugar
              </p>
            </div>
          </article>
        </div>
      </section>

      <section
        className="portada-destinos"
        id="destinos-populares"
      >
        <p className="portada-etiqueta">
          Lo mejor de Colombia
        </p>

        <h2>Destinos populares</h2>

        <p className="portada-descripcion-seccion">
          Elige un destino y descubre dónde quedarte.
        </p>

        <div className="destinos-grilla">
          {DESTINOS.map((destino) => (
            <TarjetaDestino
              key={destino.id}
              destino={destino}
              cantidad={contarEnDestino(destino)}
              onElegir={elegirDestino}
            />
          ))}
        </div>

      </section>

      {hayAlojamientos && (
      <section
        className="portada-alojamientos"
        id="alojamientos-destacados"
      >
        <p className="portada-etiqueta">
          Encuentra tu lugar ideal
        </p>

        <h2>Alojamientos populares</h2>

        <p className="portada-descripcion-seccion">
          Explora espacios únicos para tu próxima
          aventura.
        </p>

        {cargandoAlojamientos ? (
          <p className="portada-estado">
            Cargando alojamientos...
          </p>
        ) : mensajeAlojamientos ? (
          <p
            className="portada-estado portada-error"
            role="status"
          >
            {mensajeAlojamientos}
          </p>
        ) : alojamientosFiltrados.length === 0 ? (
          <div className="portada-estado">
            <p>
              No encontramos alojamientos disponibles
              con esos criterios.
            </p>

            <button
              type="button"
              className="boton-ver-todos"
              onClick={() => {
                setDestino('')
                setFiltros({ destino: '', huespedes: 0 })
              }}
            >
              Ver todos los alojamientos
            </button>
          </div>
        ) : (
          <div className="portada-tarjetas">
            {alojamientosFiltrados.map(
              (alojamiento) => (
                <article
                  className="portada-tarjeta tarjeta-clic"
                  key={
                    alojamiento.idAlojamiento
                  }
                  onClick={() =>
                    abrirAlojamiento(
                      alojamiento.idAlojamiento
                    )
                  }
                >
                  <div className="portada-tarjeta-imagen">
                    {alojamiento.imagenPortada ? (
                      <img
                        src={
                          alojamiento.imagenPortada
                        }
                        alt={
                          `Portada de ` +
                          alojamiento.titulo
                        }
                      />
                    ) : (
                      <div className="portada-sin-foto">
                        <span aria-hidden="true">
                          ⌂
                        </span>

                        <p>Sin fotografía</p>
                      </div>
                    )}

                    <span className="portada-tipo">
                      {NOMBRES_TIPO[
                        alojamiento.tipoAlojamiento
                      ] ?? alojamiento.tipoAlojamiento}
                    </span>

                    <button
                      type="button"
                      className="portada-favorito"
                      onClick={(evento) =>
                        evento.stopPropagation()
                      }
                      aria-label={
                        `Agregar ${alojamiento.titulo} a favoritos`
                      }
                    >
                      ♡
                    </button>
                  </div>

                  <div className="portada-tarjeta-contenido">
                    <div className="portada-tarjeta-titulo">
                      <div>
                        <h3>
                          {alojamiento.titulo}
                        </h3>

                        <p>
                          ⌖ {alojamiento.ciudad}
                        </p>
                      </div>

                      <p className="portada-precio">
                        <strong>
                          $
                          {Number(
                            alojamiento.precioNoche
                          ).toLocaleString(
                            'es-CO'
                          )}
                        </strong>

                        <span>/ noche</span>
                      </p>
                    </div>

                    <p className="portada-tarjeta-descripcion">
                      {alojamiento.descripcion}
                    </p>

                    <div className="portada-tarjeta-datos">
                      <span>
                        ♙ {alojamiento.capacidad}{' '}
                        personas
                      </span>

                      <span>
                        {alojamiento.direccion}
                      </span>
                    </div>

                    <button
                      type="button"
                      className="boton-ver-alojamiento"
                      onClick={(evento) => {
                        evento.stopPropagation()
                        abrirAlojamiento(
                          alojamiento.idAlojamiento
                        )
                      }}
                    >
                      Ver disponibilidad y reservar
                    </button>
                  </div>
                </article>
              )
            )}
          </div>
        )}
      </section>
      )}

      <dialog
        ref={ventanaSesion}
        className="modal-sesion"
        aria-labelledby="modal-sesion-titulo"
      >
        <button
          type="button"
          className="modal-cerrar"
          onClick={cerrarVentanaSesion}
          aria-label="Cerrar"
        >
          ×
        </button>

        <IlustracionCandado />

        <h2 id="modal-sesion-titulo">
          Inicia sesión para continuar
        </h2>

        <p>
          Para buscar alojamientos, ver disponibilidad y
          reservar, necesitas una cuenta en StayHub.
        </p>

        <button
          type="button"
          className="modal-sesion-principal"
          onClick={() => {
            cerrarVentanaSesion()
            onIniciarSesion(alojamientoDeseado.current)
          }}
        >
          Iniciar sesión
        </button>

        <button
          type="button"
          className="modal-sesion-secundario"
          onClick={() => {
            cerrarVentanaSesion()
            onRegistrarse(alojamientoDeseado.current)
          }}
        >
          Crear cuenta
        </button>
      </dialog>

      <section
        className="portada-como-funciona"
        id="como-funciona"
      >
        <p className="portada-etiqueta">Cómo funciona</p>

        <h2>Tu viaje en 3 pasos</h2>

        <ol className="pasos-viaje">
          <li>
            <span aria-hidden="true">1</span>
            <h3>Busca tu destino</h3>
            <p>
              Elige a dónde quieres ir, tus fechas y cuántas
              personas viajan contigo.
            </p>
          </li>

          <li>
            <span aria-hidden="true">2</span>
            <h3>Reserva y paga seguro</h3>
            <p>
              Ves el precio total antes de pagar, sin
              sorpresas. Tus fechas quedan bloqueadas al
              instante.
            </p>
          </li>

          <li>
            <span aria-hidden="true">3</span>
            <h3>Vive la experiencia</h3>
            <p>
              Llega, disfruta y gestiona tu reserva desde
              Mis viajes cuando lo necesites.
            </p>
          </li>
        </ol>

        <div className="invitacion-anfitrion">
          <div>
            <strong>¿Tienes un alojamiento?</strong>
            <p>
              Publícalo en StayHub y empieza a recibir
              viajeros de todo el país.
            </p>
          </div>

          <button
            type="button"
            className="portada-boton-principal"
            onClick={() =>
              usuario?.rol === 'ANFITRION'
                ? onNavegar('panel')
                : onRegistrarse()
            }
          >
            Quiero ser anfitrión
          </button>
        </div>
      </section>

      <section
        className="portada-nosotros"
        id="sobre-nosotros"
      >
        <p className="portada-etiqueta">Sobre nosotros</p>

        <h2>Somos StayHub, expertos en tus viajes</h2>

        <p>
          Somos una empresa colombiana de Inversiones LR
          enfocada en que tu viaje empiece mucho antes de
          llegar: te ayudamos a encontrar el lugar ideal,
          reservarlo con tranquilidad y disfrutarlo sin
          preocupaciones.
        </p>

        <div className="nosotros-valores">
          <article>
            <span aria-hidden="true">◆</span>
            <h3>Confianza</h3>
            <p>
              Revisamos cada alojamiento antes de
              publicarlo y protegemos cada pago.
            </p>
          </article>

          <article>
            <span aria-hidden="true">✦</span>
            <h3>Experiencias locales</h3>
            <p>
              Del Caribe a los Andes: cabañas, fincas,
              glampings y casas con alma colombiana.
            </p>
          </article>

          <article>
            <span aria-hidden="true">♥</span>
            <h3>Te acompañamos</h3>
            <p>
              Antes, durante y después de tu viaje, con
              reglas claras y cancelaciones justas.
            </p>
          </article>
        </div>

        <p className="nosotros-firma">
          Viajar es coleccionar momentos. Nosotros nos
          encargamos del lugar; tú, de los recuerdos.
        </p>
      </section>

      <footer className="portada-pie">
        © {new Date().getFullYear()} StayHub · Inversiones
        LR · Hecho en Colombia
      </footer>
    </main>
  )
}

export default Portada