import { t, useIdioma } from '../idiomas'
import { useState } from 'react';
const CONTENIDO_AYUDA = {
    busqueda: {
        titulo: 'Ayuda con tu búsqueda',
        texto: 'Verifica la ciudad, las fechas y la cantidad de huéspedes. La fecha de salida debe ser posterior a la fecha de entrada.',
    },
    reserva: {
        titulo: 'Problemas con una reserva',
        texto: 'Entra a Mis viajes para revisar el estado, las fechas y los datos del alojamiento reservado.',
    },
    cuenta: {
        titulo: 'Problemas con tu cuenta',
        texto: 'Comprueba tus datos e intenta cerrar e iniciar sesión nuevamente. Si el problema continúa, guarda una captura del mensaje de error.',
    },
};
function SoporteFlotante() {
    useIdioma();
    const [abierto, setAbierto] = useState(false);
    const [tema, setTema] = useState(null);
    const ayudaSeleccionada = tema ? CONTENIDO_AYUDA[tema] : null;
    function cerrar() {
        setAbierto(false);
        setTema(null);
    }
    return (<div className="soporte-flotante">
      {abierto && (<section id="panel-soporte" className="soporte-panel" aria-label={t("Centro de ayuda")}>
          <div className="soporte-encabezado">
            <div>
              <span className="soporte-etiqueta">{t("CENTRO DE AYUDA")}</span>
              <h2>{t("\u00BFC\u00F3mo podemos ayudarte?")}</h2>
            </div>

            <button type="button" className="soporte-cerrar" onClick={cerrar} aria-label={t("Cerrar ayuda")}>
              ×
            </button>
          </div>

          <p className="soporte-introduccion">{t("Selecciona la opci\u00F3n que se relacione con tu problema.")}</p>

          <div className="soporte-opciones">
            <button type="button" onClick={() => setTema('busqueda')}>
              <span aria-hidden="true">⌕</span>
              <span>
                <strong>{t("Ayuda con mi b\u00FAsqueda")}</strong>
                <small>{t("Ciudad, fechas o hu\u00E9spedes")}</small>
              </span>
              <span aria-hidden="true">→</span>
            </button>

            <button type="button" onClick={() => setTema('reserva')}>
              <span aria-hidden="true">▣</span>
              <span>
                <strong>{t("Problemas con una reserva")}</strong>
                <small>{t("Estado o informaci\u00F3n del viaje")}</small>
              </span>
              <span aria-hidden="true">→</span>
            </button>

            <button type="button" onClick={() => setTema('cuenta')}>
              <span aria-hidden="true">♙</span>
              <span>
                <strong>{t("Problemas con mi cuenta")}</strong>
                <small>{t("Inicio de sesi\u00F3n o datos personales")}</small>
              </span>
              <span aria-hidden="true">→</span>
            </button>
          </div>

          {ayudaSeleccionada && (<div className="soporte-respuesta" role="status">
              <h3>{t(ayudaSeleccionada.titulo)}</h3>
              <p>{t(ayudaSeleccionada.texto)}</p>
            </div>)}
        </section>)}

      <button type="button" className="soporte-activador" onClick={() => {
            setAbierto((actual) => !actual);
            if (abierto)
                setTema(null);
        }} aria-expanded={abierto} aria-controls="panel-soporte">
        <span className="soporte-signo" aria-hidden="true">?</span>
        <span>{abierto ? t("Cerrar ayuda") : t("\u00BFNecesitas ayuda?")}</span>
      </button>
    </div>);
}
export default SoporteFlotante;
