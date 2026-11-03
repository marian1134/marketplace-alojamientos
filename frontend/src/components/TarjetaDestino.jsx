import { useState } from 'react'

// Tarjeta con foto de un destino. Si la foto de internet no carga,
// prueba la foto local y al final muestra un fondo de color.
function TarjetaDestino({ destino, cantidad, onElegir }) {
  const fuentes = [
    destino.foto,
    `/imagenes/destinos/${destino.id}.jpg`,
  ]
  const [intento, setIntento] = useState(0)
  const fuente = fuentes[intento]

  return (
    <button
      type="button"
      className="destino-tarjeta"
      style={{ '--color-destino': destino.color }}
      onClick={() => onElegir(destino)}
    >
      {fuente && (
        <img
          src={fuente}
          alt=""
          loading="lazy"
          onError={() => setIntento(intento + 1)}
        />
      )}

      <span className="destino-texto">
        <strong>{destino.nombre}</strong>
        <span>{destino.lema}</span>
        <small>
          {cantidad === 0
            ? 'Próximamente'
            : `${cantidad} ${cantidad === 1 ? 'alojamiento' : 'alojamientos'}`}
        </small>
      </span>
    </button>
  )
}

export default TarjetaDestino
