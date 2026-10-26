import { useState } from 'react'

function RegistroUsuario() {
  const [mensaje, setMensaje] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function registrar(evento) {
    evento.preventDefault()

    const formulario = evento.currentTarget
    const datos = Object.fromEntries(new FormData(formulario))

    setEnviando(true)
    setMensaje('')

    try {
      const respuesta = await fetch('/api/usuarios/registro', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(datos),
      })

      if (respuesta.status === 409) {
        setMensaje('Ese correo ya está registrado')
        return
      }

      if (respuesta.status === 400) {
        setMensaje(
          'Revisa los datos. La contraseña debe tener entre 8 y 72 caracteres y no superar 72 bytes.'
        )
        return
      }

      if (!respuesta.ok) {
        throw new Error('Error al registrar')
      }

      const usuario = await respuesta.json()

      setMensaje(`¡Registro exitoso! Bienvenido/a, ${usuario.nombre}`)
      formulario.reset()
    } catch {
      setMensaje('No se pudo completar el registro. Intenta nuevamente.')
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
    pattern="\+?[0-9]{7,15}"
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