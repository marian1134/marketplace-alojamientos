import { useEffect, useState } from 'react'
import RegistroUsuario from './components/RegistroUsuario'
import InicioSesion from './components/InicioSesion'
import NuevaClave from './components/NuevaClave'
import Alojamientos from './components/Alojamientos'
import Portada from './components/Portada'
import { enviarDatos } from './api'
import './App.css'

function App() {
  const [pantalla, setPantalla] = useState('portada')
  const [vistaUsuario, setVistaUsuario] =
    useState('perfil')
  const [usuario, setUsuario] = useState(null)
  const [cargando, setCargando] = useState(true)
  const [cerrando, setCerrando] = useState(false)
  const [mensajeSesion, setMensajeSesion] =
    useState('')

  const [token, setToken] = useState(() =>
    new URLSearchParams(window.location.search).get(
      'token'
    )
  )

  const esRecuperacion = token !== null
  const esLogin = pantalla === 'login'

  const mostrandoAlojamientos =
    usuario &&
    pantalla === 'perfil' &&
    vistaUsuario === 'alojamientos'

  useEffect(() => {
    let activo = true

    async function consultarSesion() {
      try {
        const respuesta = await fetch(
          '/api/usuarios/perfil',
          {
            credentials: 'same-origin',
            cache: 'no-store',
          }
        )

        if (respuesta.status === 401) {
          if (activo) {
            setUsuario(null)
          }
          return
        }

        if (!respuesta.ok) {
          throw new Error(
            'No se pudo consultar la sesión'
          )
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

  function recibirSesion(datos) {
    setUsuario(datos)
    setVistaUsuario('perfil')
    setPantalla('perfil')
    setMensajeSesion('')
  }

  async function cerrarSesion() {
    setCerrando(true)
    setMensajeSesion('')

    try {
      const respuesta = await enviarDatos(
        '/api/usuarios/logout',
        {}
      )

      if (!respuesta.ok) {
        throw new Error(
          'No se pudo cerrar la sesión'
        )
      }

      setUsuario(null)
      setVistaUsuario('perfil')
      setPantalla('portada')
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
      direccion.pathname +
        direccion.search +
        direccion.hash
    )

    setToken(null)
    setPantalla('login')
  }

  function mostrarPortada() {
    setPantalla('portada')
    setVistaUsuario('perfil')
    setMensajeSesion('')
  }

  function mostrarLogin() {
    setPantalla('login')
    setVistaUsuario('perfil')
    setMensajeSesion('')
  }

  function mostrarRegistro() {
    setPantalla('registro')
    setVistaUsuario('perfil')
    setMensajeSesion('')
  }

  function mostrarPerfil() {
    setPantalla('perfil')
    setVistaUsuario('perfil')
    setMensajeSesion('')
  }

  if (
    !esRecuperacion &&
    !cargando &&
    pantalla === 'portada'
  ) {
    return (
      <Portada
        usuario={usuario}
        onIniciarSesion={mostrarLogin}
        onRegistrarse={mostrarRegistro}
        onPerfil={mostrarPerfil}
      />
    )
  }

  let titulo = 'Crea tu cuenta'

  if (esRecuperacion) {
    titulo = 'Recupera tu cuenta'
  } else if (mostrandoAlojamientos) {
    titulo = 'Comparte tu alojamiento'
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
          onClick={mostrarPortada}
        >
          StayHub
        </button>

        <div className="registro-bienvenida">
          <h2>{titulo}</h2>

          <p>
            Encuentra tu próximo destino o comparte tu
            alojamiento.
          </p>
        </div>
      </aside>

      <section>
        {!esRecuperacion &&
          !mostrandoAlojamientos && (
            <button
              type="button"
              className="boton-enlace volver-portada"
              onClick={mostrarPortada}
            >
              ← Volver a la portada
            </button>
          )}

        {esRecuperacion ? (
          <NuevaClave
            token={token}
            onVolver={volverAlInicio}
          />
        ) : cargando ? (
          <p role="status">
            Comprobando sesión...
          </p>
        ) : mostrandoAlojamientos ? (
          <Alojamientos
            onVolver={() =>
              setVistaUsuario('perfil')
            }
          />
        ) : usuario ? (
          <section>
            <h1>Hola, {usuario.nombre}</h1>

            <p>
              Tu sesión está iniciada en StayHub.
            </p>

            <dl className="perfil-datos">
              <dt>Nombre</dt>

              <dd>
                {usuario.nombre} {usuario.apellido}
              </dd>

              <dt>Correo electrónico</dt>
              <dd>{usuario.correo}</dd>

              <dt>Teléfono</dt>
              <dd>{usuario.telefono}</dd>
            </dl>

            <div className="acciones-perfil">
              <button
                type="button"
                className="boton-gestionar"
                onClick={() =>
                  setVistaUsuario('alojamientos')
                }
              >
                Gestionar alojamientos
              </button>

              <button
                type="button"
                className="boton-salir"
                onClick={cerrarSesion}
                disabled={cerrando}
              >
                {cerrando
                  ? 'Cerrando sesión...'
                  : 'Cerrar sesión'}
              </button>
            </div>
          </section>
        ) : (
          <>
            {esLogin ? (
              <InicioSesion
                onSesion={recibirSesion}
              />
            ) : (
              <RegistroUsuario />
            )}

            <p className="cambio-pantalla">
              {esLogin
                ? '¿No tienes cuenta? '
                : '¿Ya tienes cuenta? '}

              <button
                type="button"
                className="boton-enlace"
                onClick={() => {
                  if (esLogin) {
                    mostrarRegistro()
                  } else {
                    mostrarLogin()
                  }
                }}
              >
                {esLogin
                  ? 'Regístrate'
                  : 'Inicia sesión'}
              </button>
            </p>
          </>
        )}

        {mensajeSesion && (
          <p
            className="mensaje-sesion"
            role="status"
          >
            {mensajeSesion}
          </p>
        )}
      </section>
    </main>
  )
}

export default App