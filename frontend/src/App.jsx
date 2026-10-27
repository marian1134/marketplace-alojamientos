import { useEffect, useState } from 'react'
import RegistroUsuario from './components/RegistroUsuario'
import InicioSesion from './components/InicioSesion'
import NuevaClave from './components/NuevaClave'
import { enviarDatos } from './api'
import './App.css'

function App() {
  const [pantalla, setPantalla] = useState('login')
  const [usuario, setUsuario] = useState(null)
  const [cargando, setCargando] = useState(true)
  const [cerrando, setCerrando] = useState(false)
  const [mensajeSesion, setMensajeSesion] = useState('')

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

  function recibirSesion(datos) {
    setUsuario(datos)
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
        throw new Error('No se pudo cerrar la sesión')
      }

      setUsuario(null)
      setPantalla('login')
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

    // Consultar nuevamente la sesión después de cambiar la clave.
    window.location.reload()
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
        <span className="registro-marca">StayHub</span>

        <div className="registro-bienvenida">
          <h2>{titulo}</h2>

          <p>
            Encuentra tu próximo destino o comparte tu alojamiento.
          </p>
        </div>
      </aside>

      <section>
        {esRecuperacion ? (
          <NuevaClave
            token={token}
            onVolver={volverAlInicio}
          />
        ) : cargando ? (
          <p role="status">Comprobando sesión...</p>
        ) : usuario ? (
          <section>
            <h1>Hola, {usuario.nombre}</h1>
            <p>Tu sesión está iniciada en StayHub.</p>

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

            <button
              type="button"
              className="boton-salir"
              onClick={cerrarSesion}
              disabled={cerrando}
            >
              {cerrando ? 'Cerrando sesión...' : 'Cerrar sesión'}
            </button>
          </section>
        ) : (
          <>
            {esLogin ? (
              <InicioSesion onSesion={recibirSesion} />
            ) : (
              <RegistroUsuario />
            )}

            <p className="cambio-pantalla">
              {esLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? '}

              <button
                type="button"
                className="boton-enlace"
                onClick={() => {
                  setPantalla(esLogin ? 'registro' : 'login')
                  setMensajeSesion('')
                }}
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