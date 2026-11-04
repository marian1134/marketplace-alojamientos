import { useEffect, useRef, useState } from 'react'
import { consultar, enviarDatos, leerError } from '../api'
import './reportar-resena.css'

function ReportarResena({ idResena }) {
  const [estado, setEstado] = useState(null)
  const [abierto, setAbierto] = useState(false)
  const [motivo, setMotivo] = useState('')
  const [error, setError] = useState('')
  const [mensaje, setMensaje] = useState('')
  const [enviando, setEnviando] = useState(false)
  const [cargando, setCargando] = useState(true)
  const [intento, setIntento] = useState(0)
  const envioEnCurso = useRef(false)
  const campoId = `motivo-reporte-${idResena}`
  const ayudaId = `ayuda-reporte-${idResena}`

  useEffect(() => {
    let activo = true
    setCargando(true)
    setError('')
    async function cargar() {
      try {
        const respuesta = await consultar(`/api/v1/resenas/${idResena}/reporte`)
        if (!respuesta.ok) {
          throw new Error(respuesta.status === 401
            ? 'Inicia sesión para reportar esta reseña.'
            : await leerError(respuesta, 'No se pudo consultar el estado del reporte.'))
        }
        const datos = await respuesta.json()
        if (activo) setEstado(datos)
      } catch (fallo) {
        if (activo) setError(fallo.message || 'No se pudo conectar con el servidor.')
      } finally {
        if (activo) setCargando(false)
      }
    }
    cargar()
    return () => { activo = false }
  }, [idResena, intento])

  function cancelar() {
    if (envioEnCurso.current) return
    setAbierto(false)
    setMotivo('')
    setError('')
  }

  async function enviar(evento) {
    evento.preventDefault()
    if (envioEnCurso.current) return
    const texto = motivo.trim()
    setError('')
    if (texto.length < 10 || texto.length > 500) {
      setError('Escribe un motivo de 10 a 500 caracteres.')
      return
    }
    envioEnCurso.current = true
    setEnviando(true)
    try {
      const respuesta = await enviarDatos(`/api/v1/resenas/${idResena}/reporte`, { motivo: texto })
      if (respuesta.status === 409) {
        setEstado({ reportada: true, puedeReportar: false })
        setMensaje('Ya reportaste esta reseña.')
        setAbierto(false)
        setMotivo('')
        return
      }
      if (!respuesta.ok) {
        throw new Error(respuesta.status === 401
          ? 'Tu sesión terminó. Inicia sesión de nuevo para enviar el reporte.'
          : await leerError(respuesta, 'No se pudo enviar el reporte. Inténtalo de nuevo.'))
      }
      const datos = await respuesta.json()
      setEstado(datos)
      setMensaje(datos.mensaje || 'Reporte enviado. El administrador lo revisará.')
      setAbierto(false)
      setMotivo('')
    } catch (fallo) {
      setError(fallo.message || 'No se pudo conectar con el servidor. Inténtalo de nuevo.')
    } finally {
      envioEnCurso.current = false
      setEnviando(false)
    }
  }

  if (cargando) return <span className="reporte-resena-cargando" role="status">Consultando reporte…</span>
  if (estado && !estado.puedeReportar && !estado.reportada) return null

  return (
    <div className="reporte-resena">
      {estado?.reportada ? (
        <p className="reporte-resena-confirmacion" role="status">{mensaje || 'Ya reportaste esta reseña.'}</p>
      ) : !estado ? (
        <>
          <p className="reporte-resena-error" role="alert">{error}</p>
          <button type="button" className="reporte-resena-enlace" onClick={() => setIntento((valor) => valor + 1)}>
            Reintentar consulta del reporte
          </button>
        </>
      ) : (
        <>
          {!abierto ? (
            <button type="button" className="reporte-resena-enlace"
              onClick={() => { setAbierto(true); setError('') }} aria-expanded={false}>
              Reportar reseña
            </button>
          ) : (
            <form onSubmit={enviar} className="reporte-resena-formulario" aria-label="Reportar reseña">
              <label htmlFor={campoId}>¿Por qué reportas esta reseña?</label>
              <p id={ayudaId}>Describe si contiene insultos, spam, datos personales u otro contenido inapropiado. El administrador revisará tu motivo.</p>
              <textarea id={campoId} value={motivo} onChange={(evento) => setMotivo(evento.target.value)}
                required minLength={10} maxLength={500} rows={4} autoFocus disabled={enviando}
                aria-describedby={ayudaId} />
              <small>{motivo.length}/500 caracteres</small>
              {error && <p className="reporte-resena-error" role="alert">{error}</p>}
              <div className="reporte-resena-acciones">
                <button type="submit" disabled={enviando}>{enviando ? 'Enviando…' : 'Enviar reporte'}</button>
                <button type="button" onClick={cancelar} disabled={enviando}>Cancelar</button>
              </div>
            </form>
          )}
        </>
      )}
    </div>
  )
}

export default ReportarResena
