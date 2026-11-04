import { useId, useRef, useState } from 'react'
import { enviarDatos, leerError } from '../api'
import './calificar-huesped.css'

export default function CalificarHuesped({ reserva, resena, onGuardada }) {
  const id = useId()
  const dialogo = useRef(null)
  const enviando = useRef(false)
  const [calificacion, setCalificacion] = useState(0)
  const [comentario, setComentario] = useState('')
  const [guardando, setGuardando] = useState(false)
  const [error, setError] = useState('')

  if (resena) {
    return <div className="huesped-calificacion-guardada">
      <span aria-label={`${resena.calificacion} de 5 estrellas`}>
        {'★'.repeat(resena.calificacion)}{'☆'.repeat(5 - resena.calificacion)}
      </span>
      <p>{resena.comentario}</p>
      <small>Calificación enviada</small>
    </div>
  }
  if (reserva.estado !== 'COMPLETADA') {
    return <span className="texto-suave">Disponible al completar la reserva</span>
  }

  function abrir() {
    setCalificacion(0)
    setComentario('')
    setError('')
    dialogo.current?.showModal()
  }

  async function guardar(evento) {
    evento.preventDefault()
    if (enviando.current) return
    const texto = comentario.trim()
    if (!calificacion || texto.length < 10 || texto.length > 1000) {
      setError('Selecciona las estrellas y escribe un comentario de 10 a 1000 caracteres.')
      return
    }
    enviando.current = true
    setGuardando(true)
    setError('')
    try {
      const respuesta = await enviarDatos(
        `/api/v1/reservas/${reserva.idReserva}/resena-huesped`,
        { calificacion, comentario: texto }
      )
      if (!respuesta.ok) {
        throw new Error(await leerError(respuesta, 'No se pudo guardar la calificación.'))
      }
      const guardada = await respuesta.json()
      dialogo.current?.close()
      onGuardada(guardada)
    } catch (excepcion) {
      setError(excepcion.message)
    } finally {
      enviando.current = false
      setGuardando(false)
    }
  }

  return <>
    <button type="button" className="boton-principal" onClick={abrir}>Calificar huésped</button>
    <dialog ref={dialogo} className="huesped-calificacion-modal" aria-labelledby={`${id}-titulo`}
      onCancel={(evento) => { if (enviando.current) evento.preventDefault() }}>
      <form onSubmit={guardar}>
        <div className="huesped-calificacion-cabecera">
          <h2 id={`${id}-titulo`}>Calificar a {reserva.nombreHuesped}</h2>
          <button type="button" aria-label="Cerrar calificación" disabled={guardando}
            onClick={() => dialogo.current?.close()}>×</button>
        </div>
        <p>{reserva.tituloAlojamiento} · {reserva.codigo}</p>
        <fieldset disabled={guardando}>
          <legend>¿Cómo fue tu experiencia con el huésped?</legend>
          <div className="huesped-calificacion-estrellas">
            {[1, 2, 3, 4, 5].map((valor) => <label key={valor}>
              <input type="radio" name={`${id}-estrellas`} value={valor}
                checked={calificacion === valor} required
                onChange={() => setCalificacion(valor)}
                aria-label={`${valor} ${valor === 1 ? 'estrella' : 'estrellas'}`} />
              <span aria-hidden="true" className={valor <= calificacion ? 'seleccionada' : ''}>★</span>
            </label>)}
          </div>
          <p className="huesped-calificacion-ayuda" aria-live="polite">
            {calificacion ? `${calificacion} de 5 estrellas` : 'Selecciona una calificación'}
          </p>
          <label htmlFor={`${id}-comentario`}>Comentario</label>
          <textarea id={`${id}-comentario`} rows={4} minLength={10} maxLength={1000}
            required value={comentario} onChange={(evento) => setComentario(evento.target.value)}
            aria-describedby={`${id}-ayuda`} />
          <small id={`${id}-ayuda`}>De 10 a 1000 caracteres. {comentario.trim().length}/1000</small>
        </fieldset>
        <p className="huesped-calificacion-ayuda">Puedes enviar una sola calificación por reserva.</p>
        {error && <p className="huesped-calificacion-error" role="alert">{error}</p>}
        <div className="huesped-calificacion-acciones">
          <button type="button" className="boton-secundario" disabled={guardando}
            onClick={() => dialogo.current?.close()}>Cancelar</button>
          <button type="submit" className="boton-principal" disabled={guardando}>
            {guardando ? 'Guardando…' : 'Enviar calificación'}
          </button>
        </div>
      </form>
    </dialog>
  </>
}
