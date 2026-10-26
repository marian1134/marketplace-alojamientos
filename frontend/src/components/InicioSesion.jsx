import { useRef, useState } from 'react'

function InicioSesion() {
  const [mensaje, setMensaje] = useState('')
  const [enviando, setEnviando] = useState(false)
  const [mensajeRecuperacion, setMensajeRecuperacion] = useState('')
  const ventanaRecuperacion = useRef(null)
  const [enviandoCorreo, setEnviandoCorreo] = useState(false)

  async function iniciarSesion(evento) {
    evento.preventDefault()

    const formulario = evento.currentTarget
    const datos = Object.fromEntries(new FormData(formulario))

    setEnviando(true)
    setMensaje('')

    try {
      const respuesta = await fetch('/api/usuarios/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(datos),
      })

      if (respuesta.status === 401) {
        setMensaje('Correo o contraseña incorrectos')
        return
      }

      if (respuesta.status === 403) {
        setMensaje('Tu cuenta no se encuentra activa')
        return
      }

      if (respuesta.status === 400) {
        setMensaje('Revisa el correo y la contraseña')
        return
      }

      if (!respuesta.ok) {
        setMensaje('No se pudo iniciar sesión. Intenta nuevamente.')
        return
      }

      const usuario = await respuesta.json()

      setMensaje(`¡Bienvenido/a, ${usuario.nombre}!`)
      formulario.reset()
    } catch {
      setMensaje('No se pudo conectar con el servidor.')
    } finally {
      setEnviando(false)
    }
  }

  function abrirRecuperacion() {
    setMensajeRecuperacion('')
    ventanaRecuperacion.current.showModal()
  }

  function cerrarRecuperacion() {
    ventanaRecuperacion.current.close()
  }

 async function solicitarRecuperacion(evento) {
  evento.preventDefault()

  const datos = Object.fromEntries(
    new FormData(evento.currentTarget)
  )

  setEnviandoCorreo(true)
  setMensajeRecuperacion('')

  try {
    const respuesta = await fetch('/api/usuarios/recuperar', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(datos),
    })

    if (respuesta.status === 400) {
      setMensajeRecuperacion('Escribe un correo electrónico válido.')
      return
    }

    if (!respuesta.ok) {
      setMensajeRecuperacion(
        'No se pudo solicitar el enlace. Intenta nuevamente.'
      )
      return
    }

    const resultado = await respuesta.json()
    setMensajeRecuperacion(resultado.mensaje)
  } catch {
    setMensajeRecuperacion(
      'No se pudo conectar con el servidor.'
    )
  } finally {
    setEnviandoCorreo(false)
  }
}

  return (
    <section>
      <h1>Iniciar sesión</h1>
      <p>Ingresa a tu cuenta de StayHub</p>

      <form onSubmit={iniciarSesion}>
        <div>
          <label htmlFor="login-correo">Correo electrónico</label>
          <input
            id="login-correo"
            name="correo"
            type="email"
            autoComplete="username"
            maxLength={150}
            required
          />
        </div>

        <div>
          <label htmlFor="login-contrasena">Contraseña</label>
          <input
            id="login-contrasena"
            name="contrasena"
            type="password"
            autoComplete="current-password"
            required
          />
        </div>

        <button
          type="button"
          className="boton-enlace recuperar-contrasena"
          onClick={abrirRecuperacion}
          disabled={enviando}
        >
          ¿Olvidaste tu contraseña?
        </button>

        <button type="submit" disabled={enviando}>
          {enviando ? 'Verificando...' : 'Iniciar sesión'}
        </button>

        <p role="status">{mensaje}</p>
      </form>

      <dialog
        ref={ventanaRecuperacion}
        className="modal-recuperacion"
        aria-labelledby="recuperacion-titulo"
        aria-describedby="recuperacion-descripcion"
        onClose={() => setMensajeRecuperacion('')}
      >
        <button
          type="button"
          className="modal-cerrar"
          aria-label="Cerrar ventana de recuperación"
          onClick={cerrarRecuperacion}
        >
          ×
        </button>

        <h2 id="recuperacion-titulo">Recuperar contraseña</h2>

        <p id="recuperacion-descripcion">
          Escribe el correo electrónico asociado a tu cuenta.
        </p>

        <form onSubmit={solicitarRecuperacion}>
          <div>
            <label htmlFor="recuperacion-correo">
              Correo electrónico
            </label>

            <input
              id="recuperacion-correo"
              name="correo"
              type="email"
              autoComplete="email"
              maxLength={150}
              autoFocus
              required
            />
          </div>

          <button type="submit" disabled={enviandoCorreo}>
  {enviandoCorreo
    ? 'Enviando...'
    : 'Enviar enlace de recuperación'}
</button>

          <p role="status">{mensajeRecuperacion}</p>

          <button
            type="button"
            className="boton-enlace"
            onClick={cerrarRecuperacion}
          >
            Volver al inicio de sesión
          </button>
        </form>
      </dialog>
    </section>
  )
}

export default InicioSesion