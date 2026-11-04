import { t, useIdioma } from '../idiomas'
import { useEffect, useRef, useState } from 'react';
import { consultar, enviarDatos, leerError } from '../api';
import './reportar-resena.css';
function ReportarResena({ idResena }) {
    useIdioma();
    const [estado, setEstado] = useState(null);
    const [abierto, setAbierto] = useState(false);
    const [motivo, setMotivo] = useState('');
    const [error, setError] = useState('');
    const [mensaje, setMensaje] = useState('');
    const [enviando, setEnviando] = useState(false);
    const [cargando, setCargando] = useState(true);
    const [intento, setIntento] = useState(0);
    const envioEnCurso = useRef(false);
    const campoId = `motivo-reporte-${idResena}`;
    const ayudaId = `ayuda-reporte-${idResena}`;
    useEffect(() => {
        let activo = true;
        setCargando(true);
        setError('');
        async function cargar() {
            try {
                const respuesta = await consultar(`/api/v1/resenas/${idResena}/reporte`);
                if (!respuesta.ok) {
                    throw new Error(respuesta.status === 401
                        ? t("Inicia sesi\u00F3n para reportar esta rese\u00F1a.") : await leerError(respuesta, t("No se pudo consultar el estado del reporte.")));
                }
                const datos = await respuesta.json();
                if (activo)
                    setEstado(datos);
            }
            catch (fallo) {
                if (activo)
                    setError(fallo.message || t("No se pudo conectar con el servidor."));
            }
            finally {
                if (activo)
                    setCargando(false);
            }
        }
        cargar();
        return () => { activo = false; };
    }, [idResena, intento]);
    function cancelar() {
        if (envioEnCurso.current)
            return;
        setAbierto(false);
        setMotivo('');
        setError('');
    }
    async function enviar(evento) {
        evento.preventDefault();
        if (envioEnCurso.current)
            return;
        const texto = motivo.trim();
        setError('');
        if (texto.length < 10 || texto.length > 500) {
            setError(t("Escribe un motivo de 10 a 500 caracteres."));
            return;
        }
        envioEnCurso.current = true;
        setEnviando(true);
        try {
            const respuesta = await enviarDatos(`/api/v1/resenas/${idResena}/reporte`, { motivo: texto });
            if (respuesta.status === 409) {
                setEstado({ reportada: true, puedeReportar: false });
                setMensaje(t("Ya reportaste esta rese\u00F1a."));
                setAbierto(false);
                setMotivo('');
                return;
            }
            if (!respuesta.ok) {
                throw new Error(respuesta.status === 401
                    ? t("Tu sesi\u00F3n termin\u00F3. Inicia sesi\u00F3n de nuevo para enviar el reporte.") : await leerError(respuesta, t("No se pudo enviar el reporte. Int\u00E9ntalo de nuevo.")));
            }
            const datos = await respuesta.json();
            setEstado(datos);
            setMensaje(datos.mensaje || t("Reporte enviado. El administrador lo revisar\u00E1."));
            setAbierto(false);
            setMotivo('');
        }
        catch (fallo) {
            setError(fallo.message || t("No se pudo conectar con el servidor. Int\u00E9ntalo de nuevo."));
        }
        finally {
            envioEnCurso.current = false;
            setEnviando(false);
        }
    }
    if (cargando)
        return <span className="reporte-resena-cargando" role="status">{t("Consultando reporte\u2026")}</span>;
    if (estado && !estado.puedeReportar && !estado.reportada)
        return null;
    return (<div className="reporte-resena">
      {estado?.reportada ? (<p className="reporte-resena-confirmacion" role="status">{mensaje || t("Ya reportaste esta rese\u00F1a.")}</p>) : !estado ? (<>
          <p className="reporte-resena-error" role="alert">{t(error)}</p>
          <button type="button" className="reporte-resena-enlace" onClick={() => setIntento((valor) => valor + 1)}>{t("Reintentar consulta del reporte")}</button>
        </>) : (<>
          {!abierto ? (<button type="button" className="reporte-resena-enlace" onClick={() => { setAbierto(true); setError(''); }} aria-expanded={false}>{t("Reportar rese\u00F1a")}</button>) : (<form onSubmit={enviar} className="reporte-resena-formulario" aria-label={t("Reportar rese\u00F1a")}>
              <label htmlFor={campoId}>{t("\u00BFPor qu\u00E9 reportas esta rese\u00F1a?")}</label>
              <p id={ayudaId}>{t("Describe si contiene insultos, spam, datos personales u otro contenido inapropiado. El administrador revisar\u00E1 tu motivo.")}</p>
              <textarea id={campoId} value={motivo} onChange={(evento) => setMotivo(evento.target.value)} required minLength={10} maxLength={500} rows={4} autoFocus disabled={enviando} aria-describedby={ayudaId}/>
              <small>{motivo.length}{t("/500 caracteres")}</small>
              {error && <p className="reporte-resena-error" role="alert">{t(error)}</p>}
              <div className="reporte-resena-acciones">
                <button type="submit" disabled={enviando}>{enviando ? t("Enviando\u2026") : t("Enviar reporte")}</button>
                <button type="button" onClick={cancelar} disabled={enviando}>{t("Cancelar")}</button>
              </div>
            </form>)}
        </>)}
    </div>);
}
export default ReportarResena;
