import { useState } from 'react'
import { enviarDatos } from '../api'

function NuevaClave({ token, onVolver }) {
  const [mensaje, setMensaje] = useState('')
  const [enviando, setEnviando] = useState(false)
  const [actualizada, setActualizada] = useState(false)

  const codigoValido = /^[A-Za-z0-9_-]{43}$/.test(token)

  async function guardarClave(evento) {
    evento.preventDefault()

    const formulario = evento.currentTarget
    const datos = Object.fromEntries(new FormData(formulario))

    setMensaje('')

    if (datos.contrasena !== datos.confirmacion) {
      setMensaje('Las contraseñas no coinciden.')
      return
    }

    if (new TextEncoder().encode(datos.contrasena).length > 72) {
      setMensaje('La contraseña no puede superar 72 bytes.')
      return
    }

    setEnviando(true)

    try {
      const respuesta = await enviarDatos(
        '/api/usuarios/nueva-clave',
        {
          token,
          contrasena: datos.contrasena,
        }
      )

      if (respuesta.status === 400) {
        setMensaje(
          'No se pudo cambiar la contraseña. El enlace puede haber vencido o ya haberse utilizado. Solicita uno nuevo.'
        )
        return
      }

      if (respuesta.status === 403) {
        setMensaje(
          'No se pudo autorizar la solicitud. Recarga la página e intenta nuevamente.'
        )
        return
      }

      if (!respuesta.ok) {
        setMensaje(
          'No se pudo guardar la contraseña. Intenta nuevamente.'
        )
        return
      }

      formulario.reset()
      setActualizada(true)
      setMensaje(
        'Contraseña actualizada. Ya puedes iniciar sesión.'
      )
    } catch {
      setMensaje(
        'No se pudo completar la solicitud. Comprueba que el servidor esté funcionando.'
      )
    } finally {
      setEnviando(false)
    }
  }

  return (
    <section>
      <h1>Nueva contraseña</h1>

      <p>
        Crea una contraseña para volver a entrar a tu cuenta.
      </p>

      {!codigoValido ? (
        <p role="alert">
          El enlace no es válido. Solicita uno nuevo desde
          “¿Olvidaste tu contraseña?”.
        </p>
      ) : actualizada ? (
        <p role="status">{mensaje}</p>
      ) : (
        <form onSubmit={guardarClave}>
          <div>
            <label htmlFor="nueva-contrasena">
              Nueva contraseña
            </label>

            <input
              id="nueva-contrasena"
              name="contrasena"
              type="password"
              autoComplete="new-password"
              minLength={8}
              maxLength={72}
              required
            />
          </div>

          <div>
            <label htmlFor="confirmar-contrasena">
              Confirmar contraseña
            </label>

            <input
              id="confirmar-contrasena"
              name="confirmacion"
              type="password"
              autoComplete="new-password"
              minLength={8}
              maxLength={72}
              required
            />
          </div>

          <button type="submit" disabled={enviando}>
            {enviando ? 'Guardando...' : 'Guardar contraseña'}
          </button>

          <p role="status">{mensaje}</p>
        </form>
      )}

      <p className="cambio-pantalla">
        <button
          type="button"
          className="boton-enlace"
          onClick={onVolver}
          disabled={enviando}
        >
          Volver al inicio de sesión
        </button>
      </p>
    </section>
  )
}

export default NuevaClave