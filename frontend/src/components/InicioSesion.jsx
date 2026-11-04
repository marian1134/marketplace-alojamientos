import { t, useIdioma } from '../idiomas'
import { useRef, useState } from 'react';
import { enviarDatos, leerError } from '../api';
import CampoContrasena from './CampoContrasena';
import CodigoVerificacion from './CodigoVerificacion';
function InicioSesion({ onSesion }) {
    useIdioma();
    const [mensaje, setMensaje] = useState('');
    const [enviando, setEnviando] = useState(false);
    const [mensajeRecuperacion, setMensajeRecuperacion] = useState('');
    const [enviandoCorreo, setEnviandoCorreo] = useState(false);
    // Cuando la contraseña es correcta, se pide el código del correo
    const [verificacion, setVerificacion] = useState(null);
    const ventanaRecuperacion = useRef(null);
    async function iniciarSesion(evento) {
        evento.preventDefault();
        const formulario = evento.currentTarget;
        const datos = Object.fromEntries(new FormData(formulario));
        setEnviando(true);
        setMensaje('');
        try {
            const respuesta = await enviarDatos('/api/usuarios/login', datos);
            if (respuesta.status === 401) {
                setMensaje(t("Correo o contrase\u00F1a incorrectos"));
                return;
            }
            if (respuesta.status === 403) {
                setMensaje(t("No se pudo autorizar el acceso. Revisa que tu cuenta est\u00E9 activa o recarga la p\u00E1gina."));
                return;
            }
            if (respuesta.status === 400) {
                setMensaje(t("Revisa el correo y la contrase\u00F1a"));
                return;
            }
            if (respuesta.status === 429 || respuesta.status === 503) {
                setMensaje(await leerError(respuesta, t("No se pudo iniciar sesi\u00F3n. Intenta m\u00E1s tarde.")));
                return;
            }
            if (respuesta.status !== 202) {
                setMensaje(t("No se pudo iniciar sesi\u00F3n. Intenta nuevamente."));
                return;
            }
            const resultado = await respuesta.json();
            formulario.reset();
            setVerificacion({
                correo: datos.correo,
                contrasena: datos.contrasena,
                correoOculto: resultado.correoOculto,
                minutos: resultado.minutos,
            });
        }
        catch {
            setMensaje(t("No se pudo completar la solicitud. Comprueba que el servidor est\u00E9 funcionando."));
        }
        finally {
            setEnviando(false);
        }
    }
    function abrirRecuperacion() {
        setMensajeRecuperacion('');
        ventanaRecuperacion.current.showModal();
    }
    function cerrarRecuperacion() {
        ventanaRecuperacion.current.close();
    }
    async function solicitarRecuperacion(evento) {
        evento.preventDefault();
        const datos = Object.fromEntries(new FormData(evento.currentTarget));
        setEnviandoCorreo(true);
        setMensajeRecuperacion('');
        try {
            const respuesta = await enviarDatos('/api/usuarios/recuperar', datos);
            if (respuesta.status === 400) {
                setMensajeRecuperacion(t("Escribe un correo electr\u00F3nico v\u00E1lido."));
                return;
            }
            if (!respuesta.ok) {
                setMensajeRecuperacion(t("No se pudo solicitar el enlace. Intenta nuevamente."));
                return;
            }
            const resultado = await respuesta.json();
            setMensajeRecuperacion(resultado.mensaje);
        }
        catch {
            setMensajeRecuperacion(t("No se pudo completar la solicitud. Comprueba que el servidor est\u00E9 funcionando."));
        }
        finally {
            setEnviandoCorreo(false);
        }
    }
    if (verificacion) {
        return (<CodigoVerificacion {...verificacion} onSesion={onSesion} onVolver={() => setVerificacion(null)}/>);
    }
    return (<section>
      <h1>{t("Iniciar sesi\u00F3n")}</h1>
      <p>{t("Ingresa a tu cuenta de StayHub")}</p>

      <form onSubmit={iniciarSesion}>
        <div>
          <label htmlFor="login-correo">{t("Correo electr\u00F3nico")}</label>

          <input id="login-correo" name="correo" type="email" autoComplete="username" maxLength={150} required/>
        </div>

        <div>
          <label htmlFor="login-contrasena">{t("Contrase\u00F1a")}</label>

          <CampoContrasena id="login-contrasena" name="contrasena" autoComplete="current-password" required/>
        </div>

        <button type="button" className="boton-enlace recuperar-contrasena" onClick={abrirRecuperacion} disabled={enviando}>{t("\u00BFOlvidaste tu contrase\u00F1a?")}</button>

        <button type="submit" disabled={enviando}>
          {enviando ? t("Verificando...") : t("Iniciar sesi\u00F3n")}
        </button>

        <p role="status">{t(mensaje)}</p>
      </form>

      <dialog ref={ventanaRecuperacion} className="modal-recuperacion" aria-labelledby="recuperacion-titulo" aria-describedby="recuperacion-descripcion" onClose={() => setMensajeRecuperacion('')}>
        <button type="button" className="modal-cerrar" aria-label={t("Cerrar ventana de recuperaci\u00F3n")} onClick={cerrarRecuperacion}>
          ×
        </button>

        <h2 id="recuperacion-titulo">{t("Recuperar contrase\u00F1a")}</h2>

        <p id="recuperacion-descripcion">{t("Escribe el correo electr\u00F3nico asociado a tu cuenta.")}</p>

        <form onSubmit={solicitarRecuperacion}>
          <div>
            <label htmlFor="recuperacion-correo">{t("Correo electr\u00F3nico")}</label>

            <input id="recuperacion-correo" name="correo" type="email" autoComplete="email" maxLength={150} autoFocus required/>
          </div>

          <button type="submit" disabled={enviandoCorreo}>
            {enviandoCorreo
            ? t("Enviando...") : t("Enviar enlace de recuperaci\u00F3n")}
          </button>

          <p role="status">{t(mensajeRecuperacion)}</p>

          <button type="button" className="boton-enlace" onClick={cerrarRecuperacion}>{t("Volver al inicio de sesi\u00F3n")}</button>
        </form>
      </dialog>
    </section>);
}
export default InicioSesion;
