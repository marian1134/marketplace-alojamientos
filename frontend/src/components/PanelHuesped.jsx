import { t, useIdioma } from '../idiomas'
import { useRef, useState } from 'react';
import { enviarArchivo, enviarDatos } from '../api';
import EditarDatosPerfil from './EditarDatosPerfil';
const MAXIMO_BYTES = 5 * 1024 * 1024;
const TIPOS_PERMITIDOS = [
    'image/jpeg',
    'image/png',
    'image/webp',
];
function PanelHuesped({ usuario, cantidadFavoritos, onExplorar, onViajes, onFavoritos, onPanelAnfitrion, onPanelAdministrador, onConvertirse, onCerrarSesion, onUsuarioActualizado, cerrando, }) {
    useIdioma();
    const entradaFoto = useRef(null);
    const [editandoDatos, setEditandoDatos] = useState(false);
    const [subiendoFoto, setSubiendoFoto] = useState(false);
    const [eliminandoFoto, setEliminandoFoto] = useState(false);
    const [mensajeFoto, setMensajeFoto] = useState('');
    const [ayudaAbierta, setAyudaAbierta] = useState(false);
    const [temaAyuda, setTemaAyuda] = useState(usuario.rol === 'ADMINISTRADOR' ? 'cuenta' : 'busqueda');
    const nombreCompleto = usuario.nombre?.trim() || t("Usuario");
    const primerNombre = nombreCompleto.split(/\s+/)[0];
    const iniciales = nombreCompleto
        .split(/\s+/)
        .slice(0, 2)
        .map((palabra) => palabra.charAt(0).toUpperCase())
        .join('');
    const esAnfitrion = usuario.rol === 'ANFITRION';
    const esAdministrador = usuario.rol === 'ADMINISTRADOR';
    const esHuesped = usuario.rol === 'HUESPED';
    const etiquetaRol = {
        HUESPED: t("Hu\u00E9sped"),
        ANFITRION: t("Anfitri\u00F3n"),
        ADMINISTRADOR: t("Administrador"),
    }[usuario.rol] || t("Usuario");
    async function seleccionarFoto(evento) {
        const entrada = evento.currentTarget;
        const archivo = entrada.files?.[0];
        if (!archivo) {
            return;
        }
        if (!TIPOS_PERMITIDOS.includes(archivo.type)) {
            setMensajeFoto(t("La foto debe ser JPG, PNG o WebP."));
            entrada.value = '';
            return;
        }
        if (archivo.size > MAXIMO_BYTES) {
            setMensajeFoto(t("La foto debe pesar m\u00E1ximo 5 MB."));
            entrada.value = '';
            return;
        }
        setSubiendoFoto(true);
        setMensajeFoto('');
        try {
            const respuesta = await enviarArchivo('/api/usuarios/perfil/foto', archivo);
            if (!respuesta.ok) {
                const error = await respuesta.json().catch(() => null);
                throw new Error(error?.message || t("No se pudo guardar la foto"));
            }
            const usuarioActualizado = await respuesta.json();
            onUsuarioActualizado(usuarioActualizado);
            setMensajeFoto(t("Foto de perfil actualizada."));
        }
        catch (error) {
            setMensajeFoto(error.message || t("No se pudo actualizar la foto."));
        }
        finally {
            setSubiendoFoto(false);
            entrada.value = '';
        }
    }
    async function eliminarFoto() {
        setEliminandoFoto(true);
        setMensajeFoto('');
        try {
            const respuesta = await enviarDatos('/api/usuarios/perfil/foto', {}, 'DELETE');
            if (!respuesta.ok) {
                throw new Error(t("No se pudo eliminar la foto"));
            }
            const usuarioActualizado = await respuesta.json();
            onUsuarioActualizado(usuarioActualizado);
            setMensajeFoto(t("Foto de perfil eliminada."));
        }
        catch {
            setMensajeFoto(t("No se pudo eliminar la foto de perfil."));
        }
        finally {
            setEliminandoFoto(false);
        }
    }
    return (<section className="perfil-huesped">
      <div className="perfil-huesped-bienvenida">
        <div>
          <span className="perfil-huesped-etiqueta">{t("MI CUENTA")}</span>

          <h1>{t("\u00A1Hola, ")}{primerNombre}!</h1>

          <p>
            {esAdministrador
            ? t("Consulta tus datos personales y accede a la administraci\u00F3n de StayHub.") : t("Administra tus viajes, alojamientos favoritos y datos personales desde un solo lugar.")}
          </p>
        </div>

       {!esAdministrador && (<button type="button" className="perfil-boton-principal" onClick={onExplorar}>{t("Buscar alojamiento")}</button>)}
      </div>

      <div className="perfil-huesped-contenido">
        <div className="perfil-huesped-principal">
          <section className="perfil-accesos">
            {esAdministrador ? (<button type="button" className="perfil-acceso" onClick={onPanelAdministrador}>
                <span className="perfil-acceso-icono" aria-hidden="true">⚙</span>
                <span>
                  <strong>{t("Panel de administrador")}</strong>
                  <small>{t("Gestiona usuarios, alojamientos, reportes y auditor\u00EDa.")}</small>
                </span>
                <span className="perfil-acceso-flecha" aria-hidden="true">→</span>
              </button>) : (<>
            <button type="button" className="perfil-acceso" onClick={onViajes}>
              <span className="perfil-acceso-icono" aria-hidden="true">
                ♧
              </span>
              <span>
                <strong>{t("Mis viajes")}</strong>
                <small>{t("Consulta tus reservas y pr\u00F3ximos viajes.")}</small>
              </span>
              <span className="perfil-acceso-flecha" aria-hidden="true">
                →
              </span>
            </button>

            <button type="button" className="perfil-acceso" onClick={onFavoritos}>
              <span className="perfil-acceso-icono" aria-hidden="true">
                ♡
              </span>
              <span>
                <strong>{t("Mis favoritos")}</strong>
                <small>
                  {cantidadFavoritos === 1
                ? t("Tienes 1 alojamiento guardado.") : t("Tienes {0} alojamientos guardados.", cantidadFavoritos)}
                </small>
              </span>
              <span className="perfil-acceso-flecha" aria-hidden="true">
                →
              </span>
            </button>

              </>)}

            {esAnfitrion && (<button type="button" className="perfil-acceso" onClick={onPanelAnfitrion}>
                <span className="perfil-acceso-icono" aria-hidden="true">
                  ⌂
                </span>
                <span>
                  <strong>{t("Panel de anfitri\u00F3n")}</strong>
                  <small>{t("Administra tus alojamientos y reservas.")}</small>
                </span>
                <span className="perfil-acceso-flecha" aria-hidden="true">
                  →
                </span>
              </button>)}
          </section>

          <section className="perfil-informacion">
            <div className="perfil-seccion-encabezado">
              <div>
                <span className="perfil-seccion-etiqueta">{t("INFORMACI\u00D3N PERSONAL")}</span>
                <h2>{t("Datos de tu cuenta")}</h2>
              </div>
              <span className="perfil-estado-cuenta">{t("Cuenta activa")}</span>
            </div>

            <EditarDatosPerfil usuario={usuario} etiquetaRol={etiquetaRol} onUsuarioActualizado={onUsuarioActualizado} bloqueado={subiendoFoto || eliminandoFoto || cerrando} onEdicionCambiada={setEditandoDatos}/>
          </section>
        </div>

        <aside className="perfil-huesped-lateral">
          <section className="perfil-resumen">
            <div className="perfil-avatar-contenedor">
              <div className="perfil-avatar">
                {usuario.fotoUrl ? (<img src={usuario.fotoUrl} alt={t(t("Foto de perfil de {0}", nombreCompleto))}/>) : (<span aria-hidden="true">{iniciales}</span>)}
              </div>

              <button type="button" className="perfil-cambiar-foto" onClick={() => entradaFoto.current?.click()} disabled={subiendoFoto || eliminandoFoto || editandoDatos} aria-label={t("Cambiar foto de perfil")} title={t("Cambiar foto de perfil")}>
                {subiendoFoto ? t("agrega imagen") : '📷'}
              </button>

              <input ref={entradaFoto} className="perfil-entrada-foto" type="file" accept="image/jpeg,image/png,image/webp" onChange={seleccionarFoto}/>
            </div>

            <h2>{nombreCompleto}</h2>
            <p>{usuario.correo}</p>
            <span className="perfil-rol">
              {t(etiquetaRol)}
            </span>

            {usuario.fotoUrl && (<button type="button" className="perfil-eliminar-foto" onClick={eliminarFoto} disabled={eliminandoFoto || subiendoFoto || editandoDatos}>
                {eliminandoFoto ? t("Eliminando...") : t("Eliminar foto")}
              </button>)}

            {mensajeFoto && (<p className="perfil-mensaje-foto" role="status">
                {t(mensajeFoto)}
              </p>)}
          </section>

          {esHuesped && (<section className="perfil-anfitrion-invitacion">
              <span aria-hidden="true">⌂</span>
              <h2>{t("Comparte tu alojamiento")}</h2>
              <p>{t("Convi\u00E9rtete en anfitri\u00F3n con esta misma cuenta y comienza a publicar tus espacios.")}</p>
              <button type="button" onClick={onConvertirse}>{t("Quiero ser anfitri\u00F3n")}</button>
            </section>)}

          <section className="perfil-ayuda">
            <div className="perfil-ayuda-titulo">
              <span className="perfil-ayuda-icono" aria-hidden="true">
                ?
              </span>
              <div>
                <h2>{t("\u00BFNecesitas ayuda?")}</h2>
                <p>
                  {esAdministrador
            ? t("Consulta la ayuda de tu cuenta y de las herramientas de administraci\u00F3n.") : t("Te ayudamos con tu b\u00FAsqueda, tus reservas o cualquier problema con tu cuenta.")}
                </p>
              </div>
            </div>

            <div className="perfil-ayuda-opciones">
              {esAdministrador ? (<button type="button" onClick={onPanelAdministrador}>
                  <span>{t("Ir al panel de administrador")}</span>
                  <span aria-hidden="true">→</span>
                </button>) : (<>
              <button type="button" onClick={() => {
                setTemaAyuda('busqueda');
                setAyudaAbierta(true);
            }}>
                <span>{t("Ayuda con mi b\u00FAsqueda")}</span>
                <span aria-hidden="true">→</span>
              </button>

              <button type="button" onClick={() => {
                setTemaAyuda('reserva');
                setAyudaAbierta(true);
            }}>
                <span>{t("Problemas con una reserva")}</span>
                <span aria-hidden="true">→</span>
              </button>

                </>)}

              <button type="button" onClick={() => {
            setTemaAyuda('cuenta');
            setAyudaAbierta(true);
        }}>
                <span>{t("Problemas con mi cuenta")}</span>
                <span aria-hidden="true">→</span>
              </button>
            </div>

            <button type="button" className="perfil-ayuda-boton" onClick={() => setAyudaAbierta((abierta) => !abierta)} aria-expanded={ayudaAbierta} aria-controls="perfil-centro-ayuda">
              {ayudaAbierta ? t("Cerrar ayuda") : t("Ir al centro de ayuda")}
            </button>

            {ayudaAbierta && (<div id="perfil-centro-ayuda" className="perfil-ayuda-detalle">
                {temaAyuda === 'busqueda' && (<>
                    <h3>{t("Ayuda con tu b\u00FAsqueda")}</h3>
                    <p>{t("Revisa que la ciudad est\u00E9 escrita correctamente, que la fecha de salida sea posterior a la entrada y que el alojamiento acepte la cantidad de hu\u00E9spedes.")}</p>
                    <button type="button" onClick={onExplorar}>{t("Volver a buscar")}</button>
                  </>)}

                {temaAyuda === 'reserva' && (<>
                    <h3>{t("Ayuda con una reserva")}</h3>
                    <p>{t("En Mis viajes puedes consultar el estado, las fechas y la informaci\u00F3n de cada reserva realizada.")}</p>
                    <button type="button" onClick={onViajes}>{t("Ver mis viajes")}</button>
                  </>)}

                {temaAyuda === 'cuenta' && (<>
                    <h3>{t("Ayuda con tu cuenta")}</h3>
                    <p>{t("Si tus datos no aparecen correctamente o no puedes usar una funci\u00F3n, cierra la sesi\u00F3n, vuelve a ingresar y revisa de nuevo.")}</p>
                  </>)}
              </div>)}
          </section>

          <button type="button" className="perfil-cerrar-sesion" onClick={onCerrarSesion} disabled={cerrando}>
            {cerrando ? t("Cerrando sesi\u00F3n...") : t("Cerrar sesi\u00F3n")}
          </button>
        </aside>
      </div>
    </section>);
}
export default PanelHuesped;
