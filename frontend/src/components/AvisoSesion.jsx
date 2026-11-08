import { t, useIdioma } from '../idiomas'
import { useEffect, useRef } from 'react';
// Casa con candado del mockup "Inicia sesión para continuar"
function IlustracionCandado() {
    useIdioma();
    return (<svg viewBox="0 0 220 120" aria-hidden="true" className="modal-sesion-ilustracion">
      <ellipse cx="110" cy="70" rx="100" ry="48" fill="#f6ede4"/>
      <path d="M20 108h180" stroke="#7a9a6a" strokeWidth="4" strokeLinecap="round"/>
      <circle cx="42" cy="84" r="14" fill="#8fb48a"/>
      <rect x="40" y="94" width="4" height="14" fill="#6b5a45"/>
      <circle cx="180" cy="80" r="16" fill="#7fa77c"/>
      <rect x="178" y="92" width="4" height="16" fill="#6b5a45"/>
      <path d="M62 66 110 34l48 32" fill="#6d4c3d"/>
      <rect x="70" y="64" width="80" height="44" rx="2" fill="#d9a77c"/>
      <rect x="102" y="82" width="16" height="26" rx="2" fill="#7b5236"/>
      <rect x="80" y="74" width="12" height="10" rx="1" fill="#557a6a"/>
      <rect x="128" y="74" width="12" height="10" rx="1" fill="#557a6a"/>
      <path d="M98 30v-8a12 12 0 0 1 24 0v8" fill="none" stroke="#b07d55" strokeWidth="5"/>
      <rect x="94" y="28" width="32" height="24" rx="4" fill="#c99366"/>
      <circle cx="110" cy="40" r="3" fill="#6d4c3d"/>
    </svg>);
}
// Letrero "Inicia sesión para continuar": solo sale al reservar o guardar favoritos
function AvisoSesion({ abierto, onCerrar, onIniciarSesion, onRegistrarse }) {
    useIdioma();
    const ventana = useRef(null);
    useEffect(() => {
        const dialogo = ventana.current;
        if (!dialogo) {
            return;
        }
        if (abierto && !dialogo.open) {
            if (typeof dialogo.showModal === 'function') {
                dialogo.showModal();
            }
            else {
                dialogo.setAttribute('open', '');
            }
        }
        if (!abierto && dialogo.open) {
            dialogo.close();
        }
    }, [abierto]);
    return (<dialog ref={ventana} className="modal-sesion" aria-labelledby="modal-sesion-titulo" onClose={onCerrar}>
        <button type="button" className="modal-cerrar" onClick={onCerrar} aria-label={t("Cerrar")}>
          ×
        </button>

        <IlustracionCandado />

        <h2 id="modal-sesion-titulo">{t("Inicia sesi\u00F3n para continuar")}</h2>

        <p>{t("Para reservar o guardar favoritos necesitas una cuenta en StayHub.")}</p>

        <button type="button" className="modal-sesion-principal" onClick={onIniciarSesion}>{t("Iniciar sesi\u00F3n")}</button>

        <button type="button" className="modal-sesion-secundario" onClick={onRegistrarse}>{t("Crear cuenta")}</button>
      </dialog>);
}
export default AvisoSesion;
