import { t, useIdioma } from '../idiomas'
import { useState } from 'react';
import { enviarDatos, leerError } from '../api';
import CampoContrasena from './CampoContrasena';
import CodigoVerificacion from './CodigoVerificacion';
// Mínimo 8 caracteres, con una letra, un número y un símbolo
const CONTRASENA_SEGURA = /^(?=.*\p{L})(?=.*\d)(?=.*[^\p{L}\d\s]).{8,30}$/u;
// Nombre de 3 a 60 caracteres, solo letras y espacios
const NOMBRE_VALIDO = /^\p{L}[\p{L} .'-]{2,59}$/u;
// Correo con formato real: usuario@dominio.ext
const CORREO_VALIDO = /^[A-Za-z0-9._%+-]{1,64}@([A-Za-z0-9-]+\.)+[A-Za-z]{2,24}$/;
function RegistroUsuario({ onSesion }) {
    useIdioma();
    const [mensaje, setMensaje] = useState('');
    const [enviando, setEnviando] = useState(false);
    // Después de registrarse se pide el código que llega al correo
    const [verificacion, setVerificacion] = useState(null);
    async function registrar(evento) {
        evento.preventDefault();
        const formulario = evento.currentTarget;
        const { confirmarContrasena, celular, ...datos } = Object.fromEntries(new FormData(formulario));
        // El celular es de Colombia y se guarda con el prefijo: +573001234567
        datos.telefono = `+57${celular}`;
        setMensaje('');
        datos.nombre = datos.nombre.trim().replace(/\s+/g, ' ');
        datos.correo = datos.correo.trim().toLowerCase();
        if (!NOMBRE_VALIDO.test(datos.nombre)) {
            setMensaje(t("El nombre debe tener entre 3 y 60 caracteres y solo letras."));
            return;
        }
        if (!CORREO_VALIDO.test(datos.correo) || datos.correo.includes('..')) {
            setMensaje(t("Escribe un correo válido, por ejemplo nombre@gmail.com"));
            return;
        }
        if (!CONTRASENA_SEGURA.test(datos.contrasena)) {
            setMensaje(t("La contrase\u00F1a debe tener m\u00EDnimo 8 caracteres, con una letra, un n\u00FAmero y un s\u00EDmbolo."));
            return;
        }
        if (datos.contrasena !== confirmarContrasena) {
            setMensaje(t("Las contrase\u00F1as no coinciden."));
            return;
        }
        if (!/^3\d{9}$/.test(celular)) {
            setMensaje(t("El celular debe tener 10 d\u00EDgitos y empezar por 3."));
            return;
        }
        setEnviando(true);
        try {
            const respuesta = await enviarDatos('/api/usuarios/registro', datos);
            if (respuesta.status === 409) {
                setMensaje(t("Ese correo ya est\u00E1 registrado."));
                return;
            }
            if (respuesta.status === 400) {
                setMensaje(await leerError(respuesta, t("Revisa los datos. Completa los campos obligatorios y usa una contrase\u00F1a de 8 a 30 caracteres, con una letra, un n\u00FAmero y un s\u00EDmbolo.")));
                return;
            }
            if (respuesta.status === 403) {
                setMensaje(t("No se pudo autorizar la solicitud. Recarga la p\u00E1gina e intenta nuevamente."));
                return;
            }
            if (!respuesta.ok) {
                setMensaje(t("No se pudo completar el registro. Intenta nuevamente."));
                return;
            }
            const usuario = await respuesta.json();
            setMensaje(t("\u00A1Registro exitoso! Bienvenido/a, {0}. Entrando...", usuario.nombre));
            // Inicia la sesión de una vez para que pueda buscar su destino
            const respuestaSesion = await enviarDatos('/api/usuarios/login', {
                correo: datos.correo,
                contrasena: datos.contrasena,
            });
            if (respuestaSesion.status !== 202) {
                setMensaje(t("\u00A1Registro exitoso, {0}! Ahora inicia sesi\u00F3n con tu correo y contrase\u00F1a.", usuario.nombre));
                formulario.reset();
                return;
            }
            const resultado = await respuestaSesion.json();
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
    if (verificacion) {
        return (<CodigoVerificacion {...verificacion} onSesion={onSesion} onVolver={() => setVerificacion(null)}/>);
    }
    return (<section>
      <h1>{t("Crear cuenta")}</h1>
      <p>{t("Reg\u00EDstrate en Inversiones LR")}</p>

      <form onSubmit={registrar}>
        <fieldset>
          <legend>{t("\u00BFC\u00F3mo quieres usar StayHub?")}</legend>

          <label>
            <input type="radio" name="rol" value="HUESPED" defaultChecked required/>{t("Hu\u00E9sped")}</label>

          <label>
            <input type="radio" name="rol" value="ANFITRION" required/>{t("Anfitri\u00F3n")}</label>
        </fieldset>

        <div>
          <label htmlFor="nombre">{t("Nombre completo")}</label>

          <input id="nombre" name="nombre" autoComplete="name" placeholder={t("Tu nombre completo")} minLength={3} maxLength={60} aria-describedby="ayuda-nombre" required/>

          <small id="ayuda-nombre">{t("De 3 a 60 caracteres, solo letras.")}</small>
        </div>

        <div>
          <label htmlFor="correo">{t("Correo electr\u00F3nico")}</label>

          <input id="correo" name="correo" type="email" autoComplete="email" placeholder="nombre@gmail.com" maxLength={100} aria-describedby="ayuda-correo" required/>

          <small id="ayuda-correo">{t("Usa un correo real: ahí te llega el código para entrar.")}</small>
        </div>

        <div>
          <label htmlFor="contrasena">{t("Contrase\u00F1a")}</label>

          <CampoContrasena id="contrasena" name="contrasena" autoComplete="new-password" minLength={8} maxLength={30} aria-describedby="ayuda-contrasena" required/>

          <small id="ayuda-contrasena">{t("De 8 a 30 caracteres, con una letra, un n\u00FAmero y un s\u00EDmbolo.")}</small>
        </div>

        <div>
          <label htmlFor="confirmarContrasena">{t("Confirmar contrase\u00F1a")}</label>

          <CampoContrasena id="confirmarContrasena" name="confirmarContrasena" autoComplete="new-password" minLength={8} maxLength={30} required/>
        </div>

        <div>
          <label htmlFor="celular">{t("Celular")}</label>

          <div className="campo-celular">
            <span className="prefijo-celular" aria-hidden="true">🇨🇴 +57</span>

            <input id="celular" name="celular" type="tel" inputMode="numeric" autoComplete="tel-national" placeholder="3001234567" maxLength={10} pattern="3[0-9]{9}" title={t("El celular debe tener 10 d\u00EDgitos y empezar por 3.")} aria-label={t("Celular (Colombia +57)")} required onInput={(evento) => {
            evento.currentTarget.value = evento.currentTarget.value
                .replace(/\D/g, '')
                .slice(0, 10);
        }}/>
          </div>
        </div>

        <button type="submit" disabled={enviando}>
          {enviando ? t("Registrando...") : t("Crear cuenta")}
        </button>

        <p role="status">{t(mensaje)}</p>
      </form>
    </section>);
}
export default RegistroUsuario;
