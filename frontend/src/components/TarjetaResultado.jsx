import { t, useIdioma } from '../idiomas'
import { NOMBRES_TIPO } from '../tipos';
import { fotoRespaldo, pesos, plural } from '../formato';
import { IconoCorazon, IconoEstrella, IconoUbicacion } from './Iconos';
// Tarjeta de un alojamiento en resultados y favoritos
function TarjetaResultado({ resultado, esFavorito, onFavorito, onAbrir }) {
    useIdioma();
    const { alojamiento, imagenPortada, noches, totalEstimado, promedioCalificacion, cantidadResenas, } = resultado;
    return (<li className="resultado-item">
      <button type="button" className="tarjeta resultado" onClick={() => onAbrir(alojamiento.idAlojamiento)}>
        <span className="resultado-foto">
          {imagenPortada ? (<img src={imagenPortada} alt="" loading="lazy" onError={fotoRespaldo}/>) : (<span className="sin-foto sin-foto-baja">⌂</span>)}
          <span className="resultado-tipo">
            {t(NOMBRES_TIPO[alojamiento.tipoAlojamiento])}
          </span>
        </span>

        <span className="resultado-info">
          <span className="resultado-titulo">
            <strong>{alojamiento.titulo}</strong>
            {promedioCalificacion && (<span className="calificacion">
                <IconoEstrella tamano={15}/>
                {promedioCalificacion.toFixed(1)}
                <span className="texto-suave">({cantidadResenas})</span>
              </span>)}
          </span>
          <span className="texto-suave con-icono">
            <IconoUbicacion tamano={15}/>
            {alojamiento.ciudad}{t(" \u00B7 hasta ")}{alojamiento.capacidad}{t("hu\u00E9spedes")}</span>
          <span className="texto-suave">
            {plural(alojamiento.habitaciones ?? 1, t("habitaci\u00F3n"), t("habitaciones"))} ·{' '}
            {plural(alojamiento.banos ?? 1, t("ba\u00F1o"), t("ba\u00F1os"))}
          </span>
          <span className="resultado-precio">
            <strong>{pesos(alojamiento.precioNoche)}</strong>{t("noche")}</span>
          {totalEstimado && (<span className="texto-suave">
              {pesos(totalEstimado)}{t(" por ")}{noches}{' '}
              {noches === 1 ? t("noche") : t("noches")}{t("(con limpieza)")}</span>)}
        </span>
      </button>

      <button type="button" className={esFavorito ? 'boton-corazon activo' : 'boton-corazon'} onClick={() => onFavorito(alojamiento.idAlojamiento)} aria-pressed={esFavorito} aria-label={t(esFavorito
            ? t("Quitar {0} de favoritos", alojamiento.titulo) : t("Guardar {0} en favoritos", alojamiento.titulo))}>
        <IconoCorazon tamano={20} activo={esFavorito}/>
      </button>
    </li>);
}
export default TarjetaResultado;
