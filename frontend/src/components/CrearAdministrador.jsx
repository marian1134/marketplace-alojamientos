import { useEffect, useId, useRef, useState } from 'react'
import { enviarDatos, leerError } from '../api'

export default function CrearAdministrador({ onCerrar, onCreado }) {
  const tituloId = useId()
  const ventana = useRef(null)
  const vigente = useRef(false)
  const enviando = useRef(false)
  const [nombre, setNombre] = useState('')
  const [correo, setCorreo] = useState('')
  const [contrasena, setContrasena] = useState('')
  const [guardando, setGuardando] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    vigente.current = true
    const dialogo = ventana.current
    dialogo?.showModal()
    return () => { vigente.current = false; dialogo?.close() }
  }, [])

  async function crear(evento) {
    evento.preventDefault()
    if (enviando.current) return
    if (nombre.trim().length < 2) { setError('Escribe el nombre del administrador.'); return }
    if (new TextEncoder().encode(contrasena).length > 72) {
      setError('La contraseña no puede superar 72 bytes.'); return
    }
    enviando.current = true; setGuardando(true); setError('')
    try {
      const respuesta = await enviarDatos('/api/v1/admin/administradores', {
        nombre: nombre.trim(), correo: correo.trim(), contrasena,
      })
      if (!respuesta.ok) throw new Error(await leerError(respuesta, 'No se pudo crear el administrador.'))
      const cuenta = await respuesta.json()
      if (vigente.current) {
        setContrasena('')
        onCreado(cuenta)
      }
    } catch (excepcion) {
      if (vigente.current) setError(excepcion.message || 'No se pudo conectar. Revisa la lista antes de reintentar si la respuesta se perdió.')
    } finally {
      enviando.current = false
      if (vigente.current) setGuardando(false)
    }
  }

  return (
    <dialog ref={ventana} className="admin-panel-modal" aria-labelledby={tituloId}
      onCancel={(evento) => { evento.preventDefault(); if (!enviando.current) onCerrar() }}>
      <form onSubmit={crear}>
        <h2 id={tituloId}>Crear administrador</h2>
        <p>Esta cuenta tendrá acceso a la gestión de usuarios, alojamientos y reportes.</p>
        <div style={{ display: 'grid', gap: 16 }}>
          <label>Nombre completo
            <input value={nombre} minLength={2} maxLength={100} required autoComplete="off"
              disabled={guardando} onChange={(evento) => setNombre(evento.target.value)} />
          </label>
          <label>Correo electrónico
            <input type="email" value={correo} maxLength={150} required autoComplete="off"
              disabled={guardando} onChange={(evento) => setCorreo(evento.target.value)} />
          </label>
          <label>Contraseña
            <input type="password" value={contrasena} minLength={8} maxLength={72} required
              autoComplete="new-password" disabled={guardando}
              onChange={(evento) => setContrasena(evento.target.value)} />
          </label>
        </div>
        <p className="texto-suave">Usa al menos 8 caracteres, con una letra, un número y un símbolo.
          Para entrar, la cuenta también verificará el código enviado a su correo.</p>
        {error && <p className="aviso aviso-error" role="alert">{error}</p>}
        <div className="admin-panel-acciones">
          <button type="submit" className="boton-principal" disabled={guardando}>
            {guardando ? 'Creando...' : 'Crear administrador'}
          </button>
          <button type="button" className="boton-secundario" disabled={guardando} onClick={onCerrar}>Cancelar</button>
        </div>
      </form>
    </dialog>
  )
}
