import { t, useIdioma } from '../idiomas'
import { useEffect, useState } from 'react';
import { DESTINOS } from '../destinos';
import TarjetaDestino from './TarjetaDestino';
// Pantalla "Alojamientos": los destinos populares para elegir a dónde ir
function DestinosPopulares({ onBuscar }) {
    useIdioma();
    const [alojamientos, setAlojamientos] = useState([]);
    useEffect(() => {
        let activo = true;
        fetch('/api/v1/alojamientos', { credentials: 'same-origin' })
            .then((respuesta) => (respuesta.ok ? respuesta.json() : []))
            .then((datos) => {
            if (activo && Array.isArray(datos)) {
                setAlojamientos(datos);
            }
        })
            .catch(() => { });
        return () => {
            activo = false;
        };
    }, []);
    function contar(destino) {
        return alojamientos.filter((alojamiento) => destino.ciudades.includes(alojamiento.ciudad?.toLocaleLowerCase('es'))).length;
    }
    return (<section className="portada-destinos pantalla-destinos">
      <p className="portada-etiqueta">{t("Lo mejor de Colombia")}</p>

      <h1>{t("Destinos populares")}</h1>

      <p className="portada-descripcion-seccion">{t("Elige un destino y descubre dónde quedarte.")}</p>

      <div className="destinos-grilla">
        {DESTINOS.map((destino) => (<TarjetaDestino key={destino.id} destino={destino} cantidad={contar(destino)} onElegir={() => onBuscar({
                destino: destino.nombre,
                ciudades: destino.ciudades,
                entrada: '',
                salida: '',
                huespedes: '',
            })}/>))}
      </div>
    </section>);
}
export default DestinosPopulares;
