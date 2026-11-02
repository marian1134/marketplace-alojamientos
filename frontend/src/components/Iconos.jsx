// Íconos dibujados en SVG (se ven nítidos y toman el color del texto)

function Icono({ children, tamano = 22, relleno = 'none', className = '' }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width={tamano}
      height={tamano}
      fill={relleno}
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      className={`icono ${className}`}
    >
      {children}
    </svg>
  )
}

export function IconoUbicacion(props) {
  return (
    <Icono {...props}>
      <path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21Z" />
      <circle cx="12" cy="9.5" r="2.5" />
    </Icono>
  )
}

export function IconoCalendario(props) {
  return (
    <Icono {...props}>
      <rect x="3.5" y="5" width="17" height="15.5" rx="2.5" />
      <path d="M3.5 10h17M8 3v4M16 3v4" />
      <path d="M8 14h2M14 14h2M8 17.5h2" />
    </Icono>
  )
}

export function IconoSalida(props) {
  return (
    <Icono {...props}>
      <rect x="3.5" y="5" width="17" height="15.5" rx="2.5" />
      <path d="M3.5 10h17M8 3v4M16 3v4" />
      <path d="m10 13.5 2.5 2.5 4-4" />
    </Icono>
  )
}

export function IconoPersonas(props) {
  return (
    <Icono {...props}>
      <circle cx="9" cy="8" r="3.2" />
      <path d="M3 19.5c.6-3.4 3-5.5 6-5.5s5.4 2.1 6 5.5" />
      <circle cx="17" cy="9" r="2.4" />
      <path d="M16.5 14.2c2.4.2 4 1.9 4.5 4.8" />
    </Icono>
  )
}

export function IconoBuscar(props) {
  return (
    <Icono {...props}>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m16 16 4.5 4.5" />
    </Icono>
  )
}

export function IconoCorazon({ activo, ...props }) {
  return (
    <Icono relleno={activo ? 'currentColor' : 'none'} {...props}>
      <path d="M12 20.5s-7.5-4.6-9.2-9.4C1.6 7.6 3.9 4.5 7.2 4.5c2 0 3.6 1.1 4.8 2.8 1.2-1.7 2.8-2.8 4.8-2.8 3.3 0 5.6 3.1 4.4 6.6-1.7 4.8-9.2 9.4-9.2 9.4Z" />
    </Icono>
  )
}

export function IconoEstrella({ activo = true, ...props }) {
  return (
    <Icono relleno={activo ? 'currentColor' : 'none'} {...props}>
      <path d="m12 3.5 2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8l-5.2 2.8 1-5.8-4.3-4.1 5.9-.8L12 3.5Z" />
    </Icono>
  )
}

// Fila de estrellas para mostrar una calificación (1 a 5)
export function Estrellas({ valor, tamano = 16 }) {
  return (
    <span
      className="estrellas"
      role="img"
      aria-label={`${valor} de 5 estrellas`}
    >
      {[1, 2, 3, 4, 5].map((numero) => (
        <IconoEstrella
          key={numero}
          tamano={tamano}
          activo={numero <= Math.round(valor)}
        />
      ))}
    </span>
  )
}
