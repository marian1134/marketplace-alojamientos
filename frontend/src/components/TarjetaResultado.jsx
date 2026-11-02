import { NOMBRES_TIPO } from '../tipos'
import { fotoRespaldo, pesos } from '../formato'
import { IconoCorazon, IconoEstrella, IconoUbicacion } from './Iconos'

// Tarjeta de un alojamiento en resultados y favoritos
function TarjetaResultado({ resultado, esFavorito, onFavorito, onAbrir }) {
  const {
    alojamiento,
    imagenPortada,
    noches,
    totalEstimado,
    promedioCalificacion,
    cantidadResenas,
  } = resultado

  return (
    <li className="resultado-item">
      <button
        type="button"
        className="tarjeta resultado"
        onClick={() => onAbrir(alojamiento.idAlojamiento)}
      >
        <span className="resultado-foto">
          {imagenPortada ? (
            <img
              src={imagenPortada}
              alt=""
              loading="lazy"
              onError={fotoRespaldo}
            />
          ) : (
            <span className="sin-foto sin-foto-baja">⌂</span>
          )}
          <span className="resultado-tipo">
            {NOMBRES_TIPO[alojamiento.tipoAlojamiento]}
          </span>
        </span>

        <span className="resultado-info">
          <span className="resultado-titulo">
            <strong>{alojamiento.titulo}</strong>
            {promedioCalificacion && (
              <span className="calificacion">
                <IconoEstrella tamano={15} />
                {promedioCalificacion.toFixed(1)}
                <span className="texto-suave">({cantidadResenas})</span>
              </span>
            )}
          </span>
          <span className="texto-suave con-icono">
            <IconoUbicacion tamano={15} />
            {alojamiento.ciudad} · hasta {alojamiento.capacidad} huéspedes
          </span>
          <span className="resultado-precio">
            <strong>{pesos(alojamiento.precioNoche)}</strong> noche
          </span>
          {totalEstimado && (
            <span className="texto-suave">
              {pesos(totalEstimado)} por {noches}{' '}
              {noches === 1 ? 'noche' : 'noches'} (con limpieza)
            </span>
          )}
        </span>
      </button>

      <button
        type="button"
        className={esFavorito ? 'boton-corazon activo' : 'boton-corazon'}
        onClick={() => onFavorito(alojamiento.idAlojamiento)}
        aria-pressed={esFavorito}
        aria-label={
          esFavorito
            ? `Quitar ${alojamiento.titulo} de favoritos`
            : `Guardar ${alojamiento.titulo} en favoritos`
        }
      >
        <IconoCorazon tamano={20} activo={esFavorito} />
      </button>
    </li>
  )
}

export default TarjetaResultado
