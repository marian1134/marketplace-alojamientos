// Barra superior de las pantallas internas (usuario con sesión)
function Encabezado({
  usuario,
  pantalla,
  onNavegar,
  onCerrarSesion,
}) {
  const enlaces = [
    { id: 'portada', texto: 'Explorar' },
    { id: 'viajes', texto: 'Mis viajes' },
  ]

  if (usuario?.rol === 'ANFITRION') {
    enlaces.push({ id: 'panel', texto: 'Panel anfitrión' })
  }

  return (
    <header className="encabezado">
      <button
        type="button"
        className="encabezado-logo"
        onClick={() => onNavegar('portada')}
      >
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path
            d="M3 10.5 12 3l9 7.5M5.5 9.5V21h13V9.5M9 21v-7h6v7"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
        StayHub
      </button>

      <nav aria-label="Menú principal">
        {enlaces.map((enlace) => (
          <button
            key={enlace.id}
            type="button"
            className={
              pantalla === enlace.id ? 'activo' : ''
            }
            aria-current={
              pantalla === enlace.id ? 'page' : undefined
            }
            onClick={() => onNavegar(enlace.id)}
          >
            {enlace.texto}
          </button>
        ))}
      </nav>

      <div className="encabezado-usuario">
        <button
          type="button"
          className="encabezado-perfil"
          onClick={() => onNavegar('perfil')}
          title="Mi perfil"
        >
          <span className="avatar" aria-hidden="true">
            {usuario?.nombre?.charAt(0).toUpperCase()}
          </span>
          <span className="encabezado-nombre">
            {usuario?.nombre?.split(' ')[0]}
          </span>
        </button>

        <button
          type="button"
          className="encabezado-salir"
          onClick={onCerrarSesion}
        >
          Salir
        </button>
      </div>
    </header>
  )
}

export default Encabezado
