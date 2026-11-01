import { useState } from 'react'
import { enviarDatos } from '../api'
import CampoContrasena from './CampoContrasena'

// Mínimo 8 caracteres, con una letra, un número y un símbolo
const CONTRASENA_SEGURA = /^(?=.*\p{L})(?=.*\d)(?=.*[^\p{L}\d\s]).{8,}$/u

function RegistroUsuario({ onSesion }) {
  const [mensaje, setMensaje] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function registrar(evento) {
    evento.preventDefault()

    const formulario = evento.currentTarget
    const { confirmarContrasena, ...datos } = Object.fromEntries(
      new FormData(formulario)
    )

    setMensaje('')

    if (new TextEncoder().encode(datos.contrasena).length > 72) {
      setMensaje('La contraseña no puede superar 72 bytes.')
      return
    }

    if (!CONTRASENA_SEGURA.test(datos.contrasena)) {
      setMensaje(
        'La contraseña debe tener mínimo 8 caracteres, con una letra, un número y un símbolo.'
      )
      return
    }

    if (datos.contrasena !== confirmarContrasena) {
      setMensaje('Las contraseñas no coinciden.')
      return
    }

    setEnviando(true)

    try {
      const respuesta = await enviarDatos(
        '/api/usuarios/registro',
        datos
      )

      if (respuesta.status === 409) {
        setMensaje('Ese correo ya está registrado.')
        return
      }

      if (respuesta.status === 400) {
        setMensaje(
          'Revisa los datos. Completa los campos obligatorios y usa una contraseña de mínimo 8 caracteres, con una letra, un número y un símbolo.'
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
          'No se pudo completar el registro. Intenta nuevamente.'
        )
        return
      }

      const usuario = await respuesta.json()

      setMensaje(
        `¡Registro exitoso! Bienvenido/a, ${usuario.nombre}. Entrando...`
      )

      // Inicia la sesión de una vez para que pueda buscar su destino
      const respuestaSesion = await enviarDatos(
        '/api/usuarios/login',
        {
          correo: datos.correo,
          contrasena: datos.contrasena,
        }
      )

      if (!respuestaSesion.ok) {
        setMensaje(
          `¡Registro exitoso, ${usuario.nombre}! Ahora inicia sesión con tu correo y contraseña.`
        )
        formulario.reset()
        return
      }

      formulario.reset()
      onSesion?.(await respuestaSesion.json())
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
      <h1>Crear cuenta</h1>
      <p>Regístrate en Inversiones LR</p>

      <form onSubmit={registrar}>
        <fieldset>
          <legend>¿Cómo quieres usar StayHub?</legend>

          <label>
            <input
              type="radio"
              name="rol"
              value="HUESPED"
              defaultChecked
              required
            />
            Huésped
          </label>

          <label>
            <input
              type="radio"
              name="rol"
              value="ANFITRION"
              required
            />
            Anfitrión
          </label>
        </fieldset>

        <div>
          <label htmlFor="nombre">Nombre completo</label>

          <input
            id="nombre"
            name="nombre"
            autoComplete="name"
            placeholder="Tu nombre completo"
            maxLength={100}
            required
          />
        </div>

        <div>
          <label htmlFor="correo">Correo electrónico</label>

          <input
            id="correo"
            name="correo"
            type="email"
            autoComplete="email"
            maxLength={150}
            required
          />
        </div>

        <div>
          <label htmlFor="contrasena">Contraseña</label>

          <CampoContrasena
            id="contrasena"
            name="contrasena"
            autoComplete="new-password"
            minLength={8}
            maxLength={72}
            aria-describedby="ayuda-contrasena"
            required
          />

          <small id="ayuda-contrasena">
            Mínimo 8 caracteres, con una letra, un número y un símbolo.
          </small>
        </div>

        <div>
          <label htmlFor="confirmarContrasena">
            Confirmar contraseña
          </label>

          <CampoContrasena
            id="confirmarContrasena"
            name="confirmarContrasena"
            autoComplete="new-password"
            minLength={8}
            maxLength={72}
            required
          />
        </div>

        <div>
          <label htmlFor="telefono">Teléfono (opcional)</label>

          <input
            id="telefono"
            name="telefono"
            type="tel"
            autoComplete="tel"
            maxLength={16}
            pattern="[+]?[0-9]{7,15}"
            title="Entre 7 y 15 dígitos. Puede empezar con +."
          />
        </div>

        <button type="submit" disabled={enviando}>
          {enviando ? 'Registrando...' : 'Crear cuenta'}
        </button>

        <p role="status">{mensaje}</p>
      </form>
    </section>
  )
}

export default RegistroUsuario