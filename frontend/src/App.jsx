import { useEffect, useState } from 'react'
import RegistroUsuario from './components/RegistroUsuario'
import InicioSesion from './components/InicioSesion'
import NuevaClave from './components/NuevaClave'
import Alojamientos from './components/Alojamientos'
import Portada from './components/Portada'
import Encabezado from './components/Encabezado'
import DetalleAlojamiento from './components/DetalleAlojamiento'
import Reservar from './components/Reservar'
import MisViajes from './components/MisViajes'
import PanelAnfitrion from './components/PanelAnfitrion'
import ResultadosBusqueda from './components/ResultadosBusqueda'
import MisFavoritos from './components/MisFavoritos'
import CalendarioAnfitrion from './components/CalendarioAnfitrion'
import { consultar, enviarDatos } from './api'
import './App.css'
import './reservas.css'

// Pantallas que solo ve un usuario con sesión, con la barra superior
const PANTALLAS_INTERNAS = [
  'resultados',
  'detalle',
  'reservar',
  'viajes',
  'panel',
  'alojamientos',
  'favoritos',
  'calendario',
]

function App() {
  const [pantalla, setPantalla] = useState('portada')
  const [usuario, setUsuario] = useState(null)
  const [cargando, setCargando] = useState(true)
  const [cerrando, setCerrando] = useState(false)
  const [mensajeSesion, setMensajeSesion] = useState('')

  // Alojamiento elegido, búsqueda de la portada y reserva en curso
  const [idAlojamiento, setIdAlojamiento] = useState(null)
  const [busqueda, setBusqueda] = useState(null)
  const [solicitudReserva, setSolicitudReserva] = useState(null)

  // Pantalla a la que vuelve el botón "Volver" del detalle
  const [origenDetalle, setOrigenDetalle] = useState('portada')

  // Ids de los alojamientos guardados con el corazón
  const [favoritos, setFavoritos] = useState(() => new Set())

  // Alojamiento que quiso ver antes de iniciar sesión
  const [pendiente, setPendiente] = useState(null)

  const [token, setToken] = useState(() =>
    new URLSearchParams(window.location.search).get('token')
  )

  const esRecuperacion = token !== null
  const esLogin = pantalla === 'login'

  useEffect(() => {
    let activo = true

    async function consultarSesion() {
      try {
        const respuesta = await fetch('/api/usuarios/perfil', {
          credentials: 'same-origin',
          cache: 'no-store',
        })

        if (respuesta.status === 401) {
          if (activo) {
            setUsuario(null)
          }
          return
        }

        if (!respuesta.ok) {
          throw new Error('No se pudo consultar la sesión')
        }

        const datos = await respuesta.json()

        if (activo) {
          setUsuario(datos)
        }
      } catch {
        if (activo) {
          setMensajeSesion(
            'No se pudo comprobar la sesión. Revisa la conexión con el servidor y recarga la página.'
          )
        }
      } finally {
        if (activo) {
          setCargando(false)
        }
      }
    }

    consultarSesion()

    return () => {
      activo = false
    }
  }, [])

  // Cuando hay sesión se cargan los favoritos del usuario
  useEffect(() => {
    if (!usuario) {
      return
    }

    let activo = true

    consultar('/api/v1/favoritos/ids')
      .then((respuesta) => (respuesta.ok ? respuesta.json() : []))
      .then((ids) => {
        if (activo) {
          setFavoritos(new Set(ids))
        }
      })
      .catch(() => {})

    return () => {
      activo = false
    }
  }, [usuario])

  // Agrega o quita un favorito (se pinta de una vez y luego se guarda)
  async function cambiarFavorito(idAlojamiento) {
    const yaEsta = favoritos.has(idAlojamiento)
    const nuevos = new Set(favoritos)

    if (yaEsta) {
      nuevos.delete(idAlojamiento)
    } else {
      nuevos.add(idAlojamiento)
    }

    setFavoritos(nuevos)

    try {
      const respuesta = await enviarDatos(
        `/api/v1/favoritos/${idAlojamiento}`,
        {},
        yaEsta ? 'DELETE' : 'POST'
      )

      if (!respuesta.ok) {
        throw new Error('No se pudo guardar el favorito')
      }
    } catch {
      setFavoritos(favoritos)
    }
  }

  function navegar(destino) {
    setMensajeSesion('')
    setPantalla(destino)
    window.scrollTo({ top: 0 })
  }

  // Después de iniciar sesión o registrarse: a buscar destino
  function recibirSesion(datos) {
    setUsuario(datos)
    setMensajeSesion('')

    if (pendiente) {
      setIdAlojamiento(pendiente)
      setPendiente(null)
      navegar('detalle')
      return
    }

    navegar(datos.rol === 'ANFITRION' ? 'panel' : 'portada')
  }

  async function cerrarSesion() {
    setCerrando(true)
    setMensajeSesion('')

    try {
      const respuesta = await enviarDatos('/api/usuarios/logout', {})

      if (!respuesta.ok) {
        throw new Error('No se pudo cerrar la sesión')
      }

      setUsuario(null)
      setFavoritos(new Set())
      setSolicitudReserva(null)
      navegar('portada')
    } catch {
      setMensajeSesion(
        'No se pudo cerrar la sesión. Intenta nuevamente.'
      )
    } finally {
      setCerrando(false)
    }
  }

  function volverAlInicio() {
    const direccion = new URL(window.location.href)
    direccion.searchParams.delete('token')

    window.history.replaceState(
      null,
      '',
      direccion.pathname + direccion.search + direccion.hash
    )

    setToken(null)
    setPantalla('login')
  }

  // "Buscar" abre la pantalla de resultados
  function buscar(datosBusqueda) {
    setBusqueda(datosBusqueda)
    navegar('resultados')
  }

  function verAlojamiento(id, datosBusqueda) {
    setIdAlojamiento(id)
    setOrigenDetalle(
      ['resultados', 'viajes', 'favoritos'].includes(pantalla)
        ? pantalla
        : 'portada'
    )

    if (datosBusqueda !== undefined) {
      setBusqueda(datosBusqueda)
    }

    navegar('detalle')
  }

  function pedirCuenta(destino, idDeseado) {
    setPendiente(idDeseado ?? null)
    navegar(destino)
  }

  if (!esRecuperacion && cargando) {
    return (
      <p className="cargando" role="status">
        Comprobando sesión...
      </p>
    )
  }

  if (!esRecuperacion && pantalla === 'portada') {
    return (
      <Portada
        usuario={usuario}
        onIniciarSesion={(id) => pedirCuenta('login', id)}
        onRegistrarse={(id) => pedirCuenta('registro', id)}
        onNavegar={navegar}
        onCerrarSesion={cerrarSesion}
        onVerAlojamiento={verAlojamiento}
        onBuscar={buscar}
        favoritos={favoritos}
        onFavorito={cambiarFavorito}
      />
    )
  }

  if (!esRecuperacion && PANTALLAS_INTERNAS.includes(pantalla)) {
    if (!usuario) {
      return (
        <Portada
          usuario={null}
          onIniciarSesion={(id) => pedirCuenta('login', id)}
          onRegistrarse={(id) => pedirCuenta('registro', id)}
          onNavegar={navegar}
          onCerrarSesion={cerrarSesion}
          onVerAlojamiento={verAlojamiento}
          onBuscar={buscar}
          favoritos={favoritos}
          onFavorito={cambiarFavorito}
        />
      )
    }

    return (
      <div className="pagina-interna">
        <Encabezado
          usuario={usuario}
          pantalla={pantalla}
          onNavegar={navegar}
          onCerrarSesion={cerrarSesion}
        />

        <main>
          {pantalla === 'resultados' && busqueda && (
            <ResultadosBusqueda
              key={JSON.stringify(busqueda)}
              busqueda={busqueda}
              onBuscar={buscar}
              onVerAlojamiento={(id) => verAlojamiento(id)}
              favoritos={favoritos}
              onFavorito={cambiarFavorito}
            />
          )}

          {pantalla === 'detalle' && (
            <DetalleAlojamiento
              key={idAlojamiento}
              idAlojamiento={idAlojamiento}
              busqueda={busqueda}
              favoritos={favoritos}
              onFavorito={cambiarFavorito}
              onVolver={() => navegar(origenDetalle)}
              onReservar={(datos) => {
                setSolicitudReserva(datos)
                setBusqueda({
                  entrada: datos.entrada,
                  salida: datos.salida,
                  huespedes: datos.huespedes,
                })
                navegar('reservar')
              }}
            />
          )}

          {pantalla === 'reservar' && solicitudReserva && (
            <Reservar
              reserva={solicitudReserva}
              onVolver={() => navegar('detalle')}
              onVerViajes={() => {
                setSolicitudReserva(null)
                navegar('viajes')
              }}
              onExplorar={() => {
                setSolicitudReserva(null)
                setBusqueda(null)
                navegar('portada')
              }}
            />
          )}

          {pantalla === 'viajes' && (
            <MisViajes
              onExplorar={() => navegar('portada')}
              onVerAlojamiento={(id) => verAlojamiento(id, null)}
            />
          )}

          {pantalla === 'panel' && (
            <PanelAnfitrion
              usuario={usuario}
              onGestionarAlojamientos={() => navegar('alojamientos')}
              onCalendario={() => navegar('calendario')}
            />
          )}

          {pantalla === 'favoritos' && (
            <MisFavoritos
              favoritos={favoritos}
              onFavorito={cambiarFavorito}
              onExplorar={() => navegar('portada')}
              onVerAlojamiento={(id) => verAlojamiento(id, null)}
            />
          )}

          {pantalla === 'calendario' && (
            <CalendarioAnfitrion
              onGestionarAlojamientos={() => navegar('alojamientos')}
            />
          )}

          {pantalla === 'alojamientos' && (
            <section className="contenedor contenedor-estrecho">
              <Alojamientos onVolver={() => navegar('panel')} />
            </section>
          )}
        </main>
      </div>
    )
  }

  let titulo = 'Crea tu cuenta'

  if (esRecuperacion) {
    titulo = 'Recupera tu cuenta'
  } else if (usuario) {
    titulo = 'Bienvenido a StayHub'
  } else if (esLogin) {
    titulo = 'Bienvenido de nuevo'
  }

  return (
    <main className="registro-pagina">
      <aside className="registro-imagen">
        <button
          type="button"
          className="registro-marca boton-marca"
          onClick={() => navegar('portada')}
          aria-label="StayHub, ir a la portada"
        >
          ← StayHub
        </button>

        <div className="registro-bienvenida">
          <h2>{titulo}</h2>

          <p>
            Encuentra tu próximo destino o comparte tu alojamiento.
          </p>
        </div>
      </aside>

      <section>
        {esRecuperacion ? (
          <NuevaClave token={token} onVolver={volverAlInicio} />
        ) : usuario ? (
          <section>
            <h1>Hola, {usuario.nombre}</h1>

            <p>Tu sesión está iniciada en StayHub.</p>

            <dl className="perfil-datos">
              <dt>Nombre</dt>
              <dd>{usuario.nombre}</dd>

              <dt>Correo electrónico</dt>
              <dd>{usuario.correo}</dd>

              <dt>Tipo de cuenta</dt>
              <dd>
                {usuario.rol === 'ANFITRION' ? 'Anfitrión' : 'Huésped'}
              </dd>

              <dt>Teléfono</dt>
              <dd>{usuario.telefono || 'Sin registrar'}</dd>
            </dl>

            <div className="acciones-perfil">
              <button
                type="button"
                className="boton-gestionar"
                onClick={() => navegar('portada')}
              >
                Buscar mi destino
              </button>

              <button
                type="button"
                className="boton-gestionar"
                onClick={() => navegar('viajes')}
              >
                Mis viajes
              </button>

              {usuario.rol === 'ANFITRION' && (
                <button
                  type="button"
                  className="boton-gestionar"
                  onClick={() => navegar('panel')}
                >
                  Panel anfitrión
                </button>
              )}

              <button
                type="button"
                className="boton-salir"
                onClick={cerrarSesion}
                disabled={cerrando}
              >
                {cerrando ? 'Cerrando sesión...' : 'Cerrar sesión'}
              </button>
            </div>
          </section>
        ) : (
          <>
            {esLogin ? (
              <InicioSesion onSesion={recibirSesion} />
            ) : (
              <RegistroUsuario onSesion={recibirSesion} />
            )}

            <p className="cambio-pantalla">
              {esLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? '}

              <button
                type="button"
                className="boton-enlace"
                onClick={() => navegar(esLogin ? 'registro' : 'login')}
              >
                {esLogin ? 'Regístrate' : 'Inicia sesión'}
              </button>
            </p>
          </>
        )}

        {mensajeSesion && (
          <p className="mensaje-sesion" role="status">
            {mensajeSesion}
          </p>
        )}
      </section>
    </main>
  )
}

export default App
