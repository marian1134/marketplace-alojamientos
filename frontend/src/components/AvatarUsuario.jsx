function AvatarUsuario({
  usuario,
  className = '',
  mostrarNombre = false,
}) {
  const nombre = usuario?.nombre?.trim() || 'Usuario'

  const iniciales = nombre
    .split(/\s+/)
    .slice(0, 2)
    .map((parte) => parte.charAt(0).toUpperCase())
    .join('')

  return (
    <span className={`avatar-usuario ${className}`.trim()}>
      <span className="avatar-usuario-imagen">
        {usuario?.fotoUrl ? (
          <img
            src={usuario.fotoUrl}
            alt={`Foto de perfil de ${nombre}`}
          />
        ) : (
          <span aria-hidden="true">{iniciales}</span>
        )}
      </span>

      {mostrarNombre && (
        <span className="avatar-usuario-nombre">
          {nombre.split(/\s+/)[0]}
        </span>
      )}
    </span>
  )
}

export default AvatarUsuario
