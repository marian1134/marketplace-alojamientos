import { useEffect, useId, useRef, useState } from 'react'
import { filtrarCiudades } from '../ciudades'

// Campo "¿A dónde vas?" con lista desplegable de ciudades que se filtra
// mientras se escribe. También acepta escribir un departamento.
function CampoCiudad({
  id,
  value,
  onChange,
  placeholder = 'Ciudad o destino',
  bloqueado = false,
  className = '',
}) {
  const [abierto, setAbierto] = useState(false)
  const [resaltado, setResaltado] = useState(0)
  const contenedor = useRef(null)
  const idLista = useId()

  const opciones = filtrarCiudades(value)

  useEffect(() => {
    function cerrarAfuera(evento) {
      if (!contenedor.current?.contains(evento.target)) {
        setAbierto(false)
      }
    }

    document.addEventListener('mousedown', cerrarAfuera)
    return () => document.removeEventListener('mousedown', cerrarAfuera)
  }, [])

  function elegir(ciudad) {
    onChange(ciudad)
    setAbierto(false)
  }

  function teclado(evento) {
    if (bloqueado) {
      return
    }

    if (evento.key === 'ArrowDown') {
      evento.preventDefault()
      setAbierto(true)
      setResaltado((actual) => Math.min(actual + 1, opciones.length - 1))
    } else if (evento.key === 'ArrowUp') {
      evento.preventDefault()
      setResaltado((actual) => Math.max(actual - 1, 0))
    } else if (evento.key === 'Enter' && abierto && opciones[resaltado]) {
      evento.preventDefault()
      elegir(opciones[resaltado].ciudad)
    } else if (evento.key === 'Escape') {
      setAbierto(false)
    }
  }

  return (
    <div className={`campo-ciudad ${className}`} ref={contenedor}>
      <input
        id={id}
        type="text"
        value={value}
        placeholder={placeholder}
        autoComplete="off"
        readOnly={bloqueado}
        role="combobox"
        aria-expanded={abierto}
        aria-controls={idLista}
        aria-autocomplete="list"
        onFocus={() => !bloqueado && setAbierto(true)}
        onClick={() => !bloqueado && setAbierto(true)}
        onChange={(evento) => {
          onChange(evento.target.value)
          setResaltado(0)
          setAbierto(true)
        }}
        onKeyDown={teclado}
      />

      {abierto && opciones.length > 0 && (
        <ul className="lista-ciudades" id={idLista} role="listbox">
          {opciones.map((item, indice) => (
            <li
              key={item.ciudad}
              role="option"
              aria-selected={indice === resaltado}
              className={indice === resaltado ? 'resaltada' : ''}
              onMouseDown={(evento) => {
                evento.preventDefault()
                elegir(item.ciudad)
              }}
              onMouseEnter={() => setResaltado(indice)}
            >
              <strong>{item.ciudad}</strong>
              <span>{item.departamento}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

export default CampoCiudad
