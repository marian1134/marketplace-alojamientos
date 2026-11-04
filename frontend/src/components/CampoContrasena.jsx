import { t, useIdioma } from '../idiomas'
import { useState } from 'react';
function IconoOjo({ tachado }) {
    useIdioma();
    return (<svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round"/>
      <circle cx="12" cy="12" r="3" fill="none" stroke="currentColor" strokeWidth="1.8"/>
      {tachado && (<path d="M4 4l16 16" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/>)}
    </svg>);
}
// Campo de contraseña con el botón del ojo para mostrarla u ocultarla
function CampoContrasena(props) {
    useIdioma();
    const [visible, setVisible] = useState(false);
    return (<div className="campo-contrasena">
      <input {...props} type={visible ? 'text' : 'password'}/>

      <button type="button" className="boton-ojo" onClick={() => setVisible(!visible)} aria-label={t(visible
            ? t("Ocultar contrase\u00F1a") : t("Mostrar contrase\u00F1a"))} aria-pressed={visible}>
        <IconoOjo tachado={visible}/>
      </button>
    </div>);
}
export default CampoContrasena;
