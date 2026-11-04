import { t, useIdioma } from '../idiomas'
function AvatarUsuario({ usuario, className = '', mostrarNombre = false, }) {
    useIdioma();
    const nombre = usuario?.nombre?.trim() || t("Usuario");
    const iniciales = nombre
        .split(/\s+/)
        .slice(0, 2)
        .map((parte) => parte.charAt(0).toUpperCase())
        .join('');
    return (<span className={`avatar-usuario ${className}`.trim()}>
      <span className="avatar-usuario-imagen">
        {usuario?.fotoUrl ? (<img src={usuario.fotoUrl} alt={t(t("Foto de perfil de {0}", nombre))}/>) : (<span aria-hidden="true">{iniciales}</span>)}
      </span>

      {mostrarNombre && (<span className="avatar-usuario-nombre">
          {nombre.split(/\s+/)[0]}
        </span>)}
    </span>);
}
export default AvatarUsuario;
