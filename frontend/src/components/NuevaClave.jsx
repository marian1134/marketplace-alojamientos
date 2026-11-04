import { t, useIdioma } from '../idiomas'
import { useState } from 'react';
import { enviarDatos } from '../api';
import CampoContrasena from './CampoContrasena';
function NuevaClave({ token, onVolver }) {
    useIdioma();
    const [mensaje, setMensaje] = useState('');
    const [enviando, setEnviando] = useState(false);
    const [actualizada, setActualizada] = useState(false);
    const codigoValido = /^[A-Za-z0-9_-]{43}$/.test(token);
    async function guardarClave(evento) {
        evento.preventDefault();
        const formulario = evento.currentTarget;
        const datos = Object.fromEntries(new FormData(formulario));
        setMensaje('');
        if (datos.contrasena !== datos.confirmacion) {
            setMensaje(t("Las contrase\u00F1as no coinciden."));
            return;
        }
        if (new TextEncoder().encode(datos.contrasena).length > 72) {
            setMensaje(t("La contrase\u00F1a no puede superar 72 bytes."));
            return;
        }
        setEnviando(true);
        try {
            const respuesta = await enviarDatos('/api/usuarios/nueva-clave', {
                token,
                contrasena: datos.contrasena,
            });
            if (respuesta.status === 400) {
                setMensaje(t("No se pudo cambiar la contrase\u00F1a. El enlace puede haber vencido o ya haberse utilizado. Solicita uno nuevo."));
                return;
            }
            if (respuesta.status === 403) {
                setMensaje(t("No se pudo autorizar la solicitud. Recarga la p\u00E1gina e intenta nuevamente."));
                return;
            }
            if (!respuesta.ok) {
                setMensaje(t("No se pudo guardar la contrase\u00F1a. Intenta nuevamente."));
                return;
            }
            formulario.reset();
            setActualizada(true);
            setMensaje(t("Contrase\u00F1a actualizada. Ya puedes iniciar sesi\u00F3n."));
        }
        catch {
            setMensaje(t("No se pudo completar la solicitud. Comprueba que el servidor est\u00E9 funcionando."));
        }
        finally {
            setEnviando(false);
        }
    }
    return (<section>
      <h1>{t("Nueva contrase\u00F1a")}</h1>

      <p>{t("Crea una contrase\u00F1a para volver a entrar a tu cuenta.")}</p>

      {!codigoValido ? (<p role="alert">{t("El enlace no es v\u00E1lido. Solicita uno nuevo desde \u201C\u00BFOlvidaste tu contrase\u00F1a?\u201D.")}</p>) : actualizada ? (<p role="status">{t(mensaje)}</p>) : (<form onSubmit={guardarClave}>
          <div>
            <label htmlFor="nueva-contrasena">{t("Nueva contrase\u00F1a")}</label>

            <CampoContrasena id="nueva-contrasena" name="contrasena" autoComplete="new-password" minLength={8} maxLength={72} required/>
          </div>

          <div>
            <label htmlFor="confirmar-contrasena">{t("Confirmar contrase\u00F1a")}</label>

            <CampoContrasena id="confirmar-contrasena" name="confirmacion" autoComplete="new-password" minLength={8} maxLength={72} required/>
          </div>

          <button type="submit" disabled={enviando}>
            {enviando ? t("Guardando...") : t("Guardar contrase\u00F1a")}
          </button>

          <p role="status">{t(mensaje)}</p>
        </form>)}

      <p className="cambio-pantalla">
        <button type="button" className="boton-enlace" onClick={onVolver} disabled={enviando}>{t("Volver al inicio de sesi\u00F3n")}</button>
      </p>
    </section>);
}
export default NuevaClave;
