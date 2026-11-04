import { t, useIdioma } from '../idiomas'
import { useId, useRef, useState } from 'react';
import { enviarDatos, leerError } from '../api';
import './calificar-huesped.css';
export default function CalificarHuesped({ reserva, resena, onGuardada }) {
    useIdioma();
    const id = useId();
    const dialogo = useRef(null);
    const enviando = useRef(false);
    const [calificacion, setCalificacion] = useState(0);
    const [comentario, setComentario] = useState('');
    const [guardando, setGuardando] = useState(false);
    const [error, setError] = useState('');
    if (resena) {
        return <div className="huesped-calificacion-guardada">
      <span aria-label={t(t("{0} de 5 estrellas", resena.calificacion))}>
        {'★'.repeat(resena.calificacion)}{'☆'.repeat(5 - resena.calificacion)}
      </span>
      <p>{resena.comentario}</p>
      <small>{t("Calificaci\u00F3n enviada")}</small>
    </div>;
    }
    if (reserva.estado !== 'COMPLETADA') {
        return <span className="texto-suave">{t("Disponible al completar la reserva")}</span>;
    }
    function abrir() {
        setCalificacion(0);
        setComentario('');
        setError('');
        dialogo.current?.showModal();
    }
    async function guardar(evento) {
        evento.preventDefault();
        if (enviando.current)
            return;
        const texto = comentario.trim();
        if (!calificacion || texto.length < 10 || texto.length > 1000) {
            setError(t("Selecciona las estrellas y escribe un comentario de 10 a 1000 caracteres."));
            return;
        }
        enviando.current = true;
        setGuardando(true);
        setError('');
        try {
            const respuesta = await enviarDatos(`/api/v1/reservas/${reserva.idReserva}/resena-huesped`, { calificacion, comentario: texto });
            if (!respuesta.ok) {
                throw new Error(await leerError(respuesta, t("No se pudo guardar la calificaci\u00F3n.")));
            }
            const guardada = await respuesta.json();
            dialogo.current?.close();
            onGuardada(guardada);
        }
        catch (excepcion) {
            setError(excepcion.message);
        }
        finally {
            enviando.current = false;
            setGuardando(false);
        }
    }
    return <>
    <button type="button" className="boton-principal" onClick={abrir}>{t("Calificar hu\u00E9sped")}</button>
    <dialog ref={dialogo} className="huesped-calificacion-modal" aria-labelledby={`${id}-titulo`} onCancel={(evento) => { if (enviando.current)
        evento.preventDefault(); }}>
      <form onSubmit={guardar}>
        <div className="huesped-calificacion-cabecera">
          <h2 id={`${id}-titulo`}>{t("Calificar a ")}{reserva.nombreHuesped}</h2>
          <button type="button" aria-label={t("Cerrar calificaci\u00F3n")} disabled={guardando} onClick={() => dialogo.current?.close()}>×</button>
        </div>
        <p>{reserva.tituloAlojamiento} · {reserva.codigo}</p>
        <fieldset disabled={guardando}>
          <legend>{t("\u00BFC\u00F3mo fue tu experiencia con el hu\u00E9sped?")}</legend>
          <div className="huesped-calificacion-estrellas">
            {[1, 2, 3, 4, 5].map((valor) => <label key={valor}>
              <input type="radio" name={`${id}-estrellas`} value={valor} checked={calificacion === valor} required onChange={() => setCalificacion(valor)} aria-label={t(t("{0} {1}", valor, valor === 1 ? t("estrella") : t("estrellas")))}/>
              <span aria-hidden="true" className={valor <= calificacion ? 'seleccionada' : ''}>★</span>
            </label>)}
          </div>
          <p className="huesped-calificacion-ayuda" aria-live="polite">
            {calificacion ? t("{0} de 5 estrellas", calificacion) : t("Selecciona una calificaci\u00F3n")}
          </p>
          <label htmlFor={`${id}-comentario`}>{t("Comentario")}</label>
          <textarea id={`${id}-comentario`} rows={4} minLength={10} maxLength={1000} required value={comentario} onChange={(evento) => setComentario(evento.target.value)} aria-describedby={`${id}-ayuda`}/>
          <small id={`${id}-ayuda`}>{t("De 10 a 1000 caracteres. ")}{comentario.trim().length}/1000</small>
        </fieldset>
        <p className="huesped-calificacion-ayuda">{t("Puedes enviar una sola calificaci\u00F3n por reserva.")}</p>
        {error && <p className="huesped-calificacion-error" role="alert">{t(error)}</p>}
        <div className="huesped-calificacion-acciones">
          <button type="button" className="boton-secundario" disabled={guardando} onClick={() => dialogo.current?.close()}>{t("Cancelar")}</button>
          <button type="submit" className="boton-principal" disabled={guardando}>
            {guardando ? t("Guardando\u2026") : t("Enviar calificaci\u00F3n")}
          </button>
        </div>
      </form>
    </dialog>
  </>;
}
