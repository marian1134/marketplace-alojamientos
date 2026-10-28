import { useState } from 'react'
import { enviarDatos } from '../api'

function RegistroUsuario() {
  const [mensaje, setMensaje] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function registrar(evento) {
    evento.preventDefault()

    const formulario = evento.currentTarget
    const datos = Object.fromEntries(new FormData(formulario))

    setMensaje('')

    if (new TextEncoder().encode(datos.contrasena).length > 72) {
      setMensaje('La contraseña no puede superar 72 bytes.')
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
          'Revisa los datos. Completa todos los campos y usa una contraseña de entre 8 y 72 caracteres.'
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
        `¡Registro exitoso! Bienvenido/a, ${usuario.nombre}`
      )

      formulario.reset()
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
              value="USUARIO"
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
          <label htmlFor="nombre">Nombre</label>

          <input
            id="nombre"
            name="nombre"
            autoComplete="given-name"
            maxLength={80}
            required
          />
        </div>

        <div>
          <label htmlFor="apellido">Apellido</label>

          <input
            id="apellido"
            name="apellido"
            autoComplete="family-name"
            maxLength={80}
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

          <input
            id="contrasena"
            name="contrasena"
            type="password"
            autoComplete="new-password"
            minLength={8}
            maxLength={72}
            required
          />
        </div>

        <div>
          <label htmlFor="telefono">Teléfono</label>

          <input
            id="telefono"
            name="telefono"
            type="tel"
            autoComplete="tel"
            maxLength={16}
            pattern="[+]?[0-9]{7,15}"
            title="Entre 7 y 15 dígitos. Puede empezar con +."
            required
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