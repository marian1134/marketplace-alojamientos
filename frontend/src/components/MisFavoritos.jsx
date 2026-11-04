import { t, useIdioma } from '../idiomas'
import { useEffect, useState } from 'react';
import { consultar, leerError } from '../api';
import TarjetaResultado from './TarjetaResultado';
function MisFavoritos({ favoritos, onFavorito, onExplorar, onVerAlojamiento }) {
    useIdioma();
    const [lista, setLista] = useState([]);
    const [cargando, setCargando] = useState(true);
    const [error, setError] = useState('');
    useEffect(() => {
        let activo = true;
        async function cargar() {
            try {
                const respuesta = await consultar('/api/v1/favoritos');
                if (!respuesta.ok) {
                    throw new Error(await leerError(respuesta, t("No se pudieron cargar tus favoritos.")));
                }
                const datos = await respuesta.json();
                if (activo) {
                    setLista(datos);
                }
            }
            catch (excepcion) {
                if (activo) {
                    setError(excepcion.message);
                }
            }
            finally {
                if (activo) {
                    setCargando(false);
                }
            }
        }
        cargar();
        return () => {
            activo = false;
        };
    }, []);
    // Al quitar un corazón, la tarjeta desaparece de la lista
    const visibles = lista.filter((resultado) => favoritos.has(resultado.alojamiento.idAlojamiento));
    return (<section className="contenedor">
      <h1 className="titulo-serif">{t("Favoritos")}</h1>
      <p className="texto-suave">{t("Los alojamientos que guardaste con el coraz\u00F3n.")}</p>

      {cargando ? (<p className="cargando" role="status">{t("Cargando tus favoritos...")}</p>) : error ? (<p className="aviso aviso-error" role="alert">
          {t(error)}
        </p>) : visibles.length === 0 ? (<div className="tarjeta vacio">
          <span aria-hidden="true">♡</span>
          <h2>{t("A\u00FAn no tienes favoritos")}</h2>
          <p className="texto-suave">{t("Toca el coraz\u00F3n de un alojamiento para guardarlo aqu\u00ED.")}</p>
          <button type="button" className="boton-principal" onClick={onExplorar}>{t("Explorar alojamientos")}</button>
        </div>) : (<ul className="grilla-resultados">
          {visibles.map((resultado) => (<TarjetaResultado key={resultado.alojamiento.idAlojamiento} resultado={resultado} esFavorito onFavorito={onFavorito} onAbrir={onVerAlojamiento}/>))}
        </ul>)}
    </section>);
}
export default MisFavoritos;
