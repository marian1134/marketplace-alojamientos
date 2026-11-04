import { t, useIdioma } from '../idiomas'
import { useState } from 'react';
// Tarjeta con foto de un destino. Si la foto de internet no carga,
// prueba la foto local y al final muestra un fondo de color.
function TarjetaDestino({ destino, cantidad, onElegir }) {
    useIdioma();
    const fuentes = [
        destino.foto,
        `/imagenes/destinos/${destino.id}.jpg`,
    ];
    const [intento, setIntento] = useState(0);
    const fuente = fuentes[intento];
    return (<button type="button" className="destino-tarjeta" style={{ '--color-destino': destino.color }} onClick={() => onElegir(destino)}>
      {fuente && (<img src={fuente} alt="" loading="lazy" onError={() => setIntento(intento + 1)}/>)}

      <span className="destino-texto">
        <strong>{destino.nombre}</strong>
        <span>{t(destino.lema)}</span>
        <small>
          {cantidad === 0
            ? t("Pr\u00F3ximamente") : t("{0} {1}", cantidad, cantidad === 1 ? t("alojamiento") : t("alojamientos"))}
        </small>
      </span>
    </button>);
}
export default TarjetaDestino;
