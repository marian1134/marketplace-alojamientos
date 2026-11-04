import { useRef, useState } from 'react'
import { enviarDatos } from '../api'
import './editar-datos-perfil.css'

function EditarDatosPerfil({ usuario, etiquetaRol, onUsuarioActualizado, bloqueado, onEdicionCambiada }) {
  const [editando, setEditando] = useState(false)
  const [nombre, setNombre] = useState('')
  const [telefono, setTelefono] = useState('')
  const [guardando, setGuardando] = useState(false)
  const [mensaje, setMensaje] = useState('')
  const [error, setError] = useState('')
  const envioEnCurso = useRef(false)

  function editar() {
    setNombre(usuario.nombre || '')
    setTelefono(usuario.telefono || '')
    setMensaje('')
    setError('')
    setEditando(true)
    onEdicionCambiada(true)
  }

  function cancelar() {
    if (envioEnCurso.current) return
    setEditando(false)
    setError('')
    onEdicionCambiada(false)
  }

  async function guardar(evento) {
    evento.preventDefault()
    if (envioEnCurso.current || bloqueado) return
    const nombreLimpio = nombre.trim()
    const telefonoLimpio = telefono.trim()
    setError('')
    setMensaje('')
    if (nombreLimpio.length < 2 || nombreLimpio.length > 100) {
      setError('El nombre debe tener entre 2 y 100 caracteres.')
      return
    }
    if (telefonoLimpio && (telefonoLimpio.length > 20 ||
        !/^[+0-9() .-]+$/.test(telefonoLimpio) ||
        telefonoLimpio.replace(/[^0-9]/g, '').length < 7)) {
      setError('El teléfono debe tener al menos 7 dígitos y máximo 20 caracteres.')
      return
    }
    envioEnCurso.current = true
    setGuardando(true)
    try {
      const respuesta = await enviarDatos('/api/usuarios/perfil', {
        nombre: nombreLimpio,
        telefono: telefonoLimpio,
      }, 'PATCH')
      if (!respuesta.ok) {
        const detalle = await respuesta.json().catch(() => null)
        const mensajeError = respuesta.status === 401
          ? 'Tu sesión terminó. Vuelve a iniciar sesión para guardar.'
          : respuesta.status === 403
            ? 'No se pudo autorizar el cambio. Actualiza la página e inténtalo de nuevo.'
            : detalle?.detail || detalle?.message || 'No se pudieron guardar tus datos. Inténtalo de nuevo.'
        throw new Error(mensajeError)
      }
      const actualizado = await respuesta.json()
      onUsuarioActualizado(actualizado)
      setEditando(false)
      onEdicionCambiada(false)
      setMensaje('Tus datos se guardaron correctamente.')
    } catch (fallo) {
      setError(fallo.message || 'No se pudo conectar con el servidor. Inténtalo de nuevo.')
    } finally {
      envioEnCurso.current = false
      setGuardando(false)
    }
  }

  return (
    <div className="editar-datos-perfil">
      {editando ? (
        <form onSubmit={guardar} aria-label="Editar información personal">
          <fieldset disabled={guardando || bloqueado}>
            <legend>Editar datos personales</legend>
            <label htmlFor="perfil-nombre">Nombre completo</label>
            <input id="perfil-nombre" name="nombre" autoComplete="name"
              value={nombre} onChange={(evento) => setNombre(evento.target.value)}
              required minLength={2} maxLength={100} autoFocus />
            <label htmlFor="perfil-telefono">Teléfono (opcional)</label>
            <input id="perfil-telefono" name="telefono" type="tel" autoComplete="tel"
              value={telefono} onChange={(evento) => setTelefono(evento.target.value)}
              maxLength={20} aria-describedby="perfil-telefono-ayuda" />
            <small id="perfil-telefono-ayuda">Puedes dejarlo vacío para quitar el teléfono registrado.</small>
            <p>Correo electrónico: {usuario.correo}</p>
            <p>Tipo de cuenta: {etiquetaRol}</p>
            <div className="editar-datos-acciones">
              <button type="submit" className="perfil-boton-principal">
                {guardando ? 'Guardando...' : 'Guardar cambios'}
              </button>
              <button type="button" onClick={cancelar}>Cancelar</button>
            </div>
          </fieldset>
        </form>
      ) : (
        <>
          <dl className="perfil-informacion-lista">
            <div><dt>Nombre completo</dt><dd>{usuario.nombre}</dd></div>
            <div><dt>Correo electrónico</dt><dd>{usuario.correo}</dd></div>
            <div><dt>Teléfono</dt><dd>{usuario.telefono || 'Sin registrar'}</dd></div>
            <div><dt>Tipo de cuenta</dt><dd>{etiquetaRol}</dd></div>
          </dl>
          <button type="button" className="editar-datos-boton" onClick={editar} disabled={bloqueado}>
            Editar datos
          </button>
        </>
      )}
      {error && <p className="editar-datos-error" role="alert">{error}</p>}
      {mensaje && <p className="editar-datos-exito" role="status">{mensaje}</p>}
    </div>
  )
}

export default EditarDatosPerfil
