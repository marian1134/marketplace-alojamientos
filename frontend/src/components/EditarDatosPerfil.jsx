import { t, useIdioma } from '../idiomas'
import { useRef, useState } from 'react';
import { enviarDatos } from '../api';
import './editar-datos-perfil.css';
function EditarDatosPerfil({ usuario, etiquetaRol, onUsuarioActualizado, bloqueado, onEdicionCambiada }) {
    useIdioma();
    const [editando, setEditando] = useState(false);
    const [nombre, setNombre] = useState('');
    const [telefono, setTelefono] = useState('');
    const [guardando, setGuardando] = useState(false);
    const [mensaje, setMensaje] = useState('');
    const [error, setError] = useState('');
    const envioEnCurso = useRef(false);
    function editar() {
        setNombre(usuario.nombre || '');
        setTelefono((usuario.telefono || '').replace(/^\+57/, '').replace(/\D/g, '').slice(-10));
        setMensaje('');
        setError('');
        setEditando(true);
        onEdicionCambiada(true);
    }
    function cancelar() {
        if (envioEnCurso.current)
            return;
        setEditando(false);
        setError('');
        onEdicionCambiada(false);
    }
    async function guardar(evento) {
        evento.preventDefault();
        if (envioEnCurso.current || bloqueado)
            return;
        const nombreLimpio = nombre.trim();
        const telefonoLimpio = telefono.trim();
        setError('');
        setMensaje('');
        if (nombreLimpio.length < 2 || nombreLimpio.length > 100) {
            setError(t("El nombre debe tener entre 2 y 100 caracteres."));
            return;
        }
        if (!/^3\d{9}$/.test(telefonoLimpio)) {
            setError(t("El celular debe tener 10 d\u00EDgitos y empezar por 3."));
            return;
        }
        envioEnCurso.current = true;
        setGuardando(true);
        try {
            const respuesta = await enviarDatos('/api/usuarios/perfil', {
                nombre: nombreLimpio,
                telefono: `+57${telefonoLimpio}`,
            }, 'PATCH');
            if (!respuesta.ok) {
                const detalle = await respuesta.json().catch(() => null);
                const mensajeError = respuesta.status === 401
                    ? t("Tu sesi\u00F3n termin\u00F3. Vuelve a iniciar sesi\u00F3n para guardar.") : respuesta.status === 403
                    ? t("No se pudo autorizar el cambio. Actualiza la p\u00E1gina e int\u00E9ntalo de nuevo.") : detalle?.detail || detalle?.message || t("No se pudieron guardar tus datos. Int\u00E9ntalo de nuevo.");
                throw new Error(mensajeError);
            }
            const actualizado = await respuesta.json();
            onUsuarioActualizado(actualizado);
            setEditando(false);
            onEdicionCambiada(false);
            setMensaje(t("Tus datos se guardaron correctamente."));
        }
        catch (fallo) {
            setError(fallo.message || t("No se pudo conectar con el servidor. Int\u00E9ntalo de nuevo."));
        }
        finally {
            envioEnCurso.current = false;
            setGuardando(false);
        }
    }
    return (<div className="editar-datos-perfil">
      {editando ? (<form onSubmit={guardar} aria-label={t("Editar informaci\u00F3n personal")}>
          <fieldset disabled={guardando || bloqueado}>
            <legend>{t("Editar datos personales")}</legend>
            <label htmlFor="perfil-nombre">{t("Nombre completo")}</label>
            <input id="perfil-nombre" name="nombre" autoComplete="name" value={nombre} onChange={(evento) => setNombre(evento.target.value)} required minLength={2} maxLength={100} autoFocus/>
            <label htmlFor="perfil-telefono">{t("Celular")}</label>
            <div className="campo-celular">
              <span className="prefijo-celular" aria-hidden="true">🇨🇴 +57</span>
              <input id="perfil-telefono" name="telefono" type="tel" inputMode="numeric" autoComplete="tel-national" placeholder="3001234567" value={telefono} onChange={(evento) => setTelefono(evento.target.value.replace(/\D/g, '').slice(0, 10))} maxLength={10} pattern="3[0-9]{9}" title={t("El celular debe tener 10 d\u00EDgitos y empezar por 3.")} required/>
            </div>
            <p>{t("Correo electr\u00F3nico: ")}{usuario.correo}</p>
            <p>{t("Tipo de cuenta: ")}{t(etiquetaRol)}</p>
            <div className="editar-datos-acciones">
              <button type="submit" className="perfil-boton-principal">
                {guardando ? t("Guardando...") : t("Guardar cambios")}
              </button>
              <button type="button" onClick={cancelar}>{t("Cancelar")}</button>
            </div>
          </fieldset>
        </form>) : (<>
          <dl className="perfil-informacion-lista">
            <div><dt>{t("Nombre completo")}</dt><dd>{usuario.nombre}</dd></div>
            <div><dt>{t("Correo electr\u00F3nico")}</dt><dd>{usuario.correo}</dd></div>
            <div><dt>{t("Celular")}</dt><dd>{usuario.telefono || t("Sin registrar")}</dd></div>
            <div><dt>{t("Tipo de cuenta")}</dt><dd>{t(etiquetaRol)}</dd></div>
          </dl>
          <button type="button" className="editar-datos-boton" onClick={editar} disabled={bloqueado}>{t("Editar datos")}</button>
        </>)}
      {error && <p className="editar-datos-error" role="alert">{t(error)}</p>}
      {mensaje && <p className="editar-datos-exito" role="status">{t(mensaje)}</p>}
    </div>);
}
export default EditarDatosPerfil;
