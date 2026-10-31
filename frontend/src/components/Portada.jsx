import { useEffect, useState } from 'react'

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

function Portada({
  usuario,
  onIniciarSesion,
  onRegistrarse,
  onPerfil,
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
            <a href="#alojamientos-destacados">
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
              <button
                type="button"
                className="portada-boton-claro"
                onClick={onPerfil}
              >
                Mi perfil
              </button>
            ) : (
              <>
                <button
                  type="button"
                  className="portada-boton-claro"
                  onClick={onIniciarSesion}
                >
                  Iniciar sesión
                </button>

                <button
                  type="button"
                  className="portada-boton-principal"
                  onClick={onRegistrarse}
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
          id="como-funciona"
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
          <p className="portada-estado">
            No encontramos alojamientos disponibles
            con esos criterios.
          </p>
        ) : (
          <div className="portada-tarjetas">
            {alojamientosFiltrados.map(
              (alojamiento) => (
                <article
                  className="portada-tarjeta"
                  key={
                    alojamiento.idAlojamiento
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
                      {
                        alojamiento.tipoAlojamiento
                      }
                    </span>

                    <button
                      type="button"
                      className="portada-favorito"
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
                  </div>
                </article>
              )
            )}
          </div>
        )}
      </section>

      <section
        className="portada-nosotros"
        id="sobre-nosotros"
      >
        <h2>Descubre Colombia con StayHub</h2>

        <p>
          Conectamos viajeros con alojamientos cómodos,
          confiables y llenos de experiencias.
        </p>
      </section>
    </main>
  )
}

export default Portada