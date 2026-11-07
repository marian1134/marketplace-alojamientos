import { t, useIdioma } from '../idiomas'
import { useEffect, useState } from 'react';
import { enviarDatos, leerError } from '../api';
const SEGUNDOS_PARA_REENVIAR = 30;
// Segundo paso del inicio de sesión: escribir el código de 6 números
// que llegó al correo.
function CodigoVerificacion({ correo, contrasena, correoOculto, minutos, onSesion, onVolver, }) {
    useIdioma();
    const [codigo, setCodigo] = useState('');
    const [mensaje, setMensaje] = useState('');
    const [enviando, setEnviando] = useState(false);
    const [espera, setEspera] = useState(SEGUNDOS_PARA_REENVIAR);
    // Cuenta regresiva para poder pedir otro código
    useEffect(() => {
        if (espera <= 0) {
            return;
        }
        const temporizador = setTimeout(() => setEspera(espera - 1), 1000);
        return () => clearTimeout(temporizador);
    }, [espera]);
    async function verificar(evento) {
        evento.preventDefault();
        if (!/^\d{6}$/.test(codigo)) {
            setMensaje(t("El c\u00F3digo tiene 6 n\u00FAmeros."));
            return;
        }
        setEnviando(true);
        setMensaje('');
        try {
            const respuesta = await enviarDatos('/api/usuarios/verificar-codigo', {
                correo,
                codigo,
            });
            if (!respuesta.ok) {
                setMensaje(await leerError(respuesta, t("No se pudo verificar el c\u00F3digo.")));
                setCodigo('');
                return;
            }
            onSesion?.(await respuesta.json());
        }
        catch {
            setMensaje(t("No se pudo completar la solicitud. Comprueba que el servidor est\u00E9 funcionando."));
        }
        finally {
            setEnviando(false);
        }
    }
    async function reenviar() {
        setEnviando(true);
        setMensaje('');
        try {
            const respuesta = await enviarDatos('/api/usuarios/login', {
                correo,
                contrasena,
            });
            if (respuesta.status !== 202) {
                setMensaje(await leerError(respuesta, t("No se pudo enviar otro c\u00F3digo.")));
                return;
            }
            setCodigo('');
            setEspera(SEGUNDOS_PARA_REENVIAR);
            setMensaje(t("Te enviamos un c\u00F3digo nuevo. El anterior ya no sirve."));
        }
        catch {
            setMensaje(t("No se pudo conectar con el servidor."));
        }
        finally {
            setEnviando(false);
        }
    }
    return (<section>
      <h1>{t("Verifica que eres t\u00FA")}</h1>
      <p>{t("Te enviamos un c\u00F3digo de 6 n\u00FAmeros a")}{' '}<strong>{correoOculto}</strong>{t(". Vence en")}{' '}{minutos}{' '}{t("minutos.")}</p>

      <form onSubmit={verificar}>
        <div>
          <label htmlFor="codigo-verificacion">{t("C\u00F3digo")}</label>

          <input id="codigo-verificacion" name="codigo" className="campo-codigo" inputMode="numeric" autoComplete="one-time-code" pattern="\d{6}" maxLength={6} placeholder="000000" value={codigo} onChange={(evento) => setCodigo(evento.target.value.replace(/\D/g, '').slice(0, 6))} autoFocus required/>

          <small>{t("\u00BFNo lo ves? Revisa la carpeta de spam o promociones.")}</small>
        </div>

        <button type="submit" disabled={enviando || codigo.length !== 6}>
          {enviando ? t("Verificando...") : t("Entrar")}
        </button>

        <p role="status">{t(mensaje)}</p>

        <button type="button" className="boton-enlace" onClick={reenviar} disabled={enviando || espera > 0}>
          {espera > 0
            ? t("Pedir otro c\u00F3digo (en {0} s)", espera) : t("Pedir otro c\u00F3digo")}
        </button>

        <button type="button" className="boton-enlace" onClick={onVolver}>{t("\u2190 Volver")}</button>
      </form>
    </section>);
}
export default CodigoVerificacion;
