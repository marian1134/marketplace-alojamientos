import { useEffect, useState } from 'react'
import { consultar, leerError } from '../api'
import TarjetaResultado from './TarjetaResultado'

function MisFavoritos({ favoritos, onFavorito, onExplorar, onVerAlojamiento }) {
  const [lista, setLista] = useState([])
  const [cargando, setCargando] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let activo = true

    async function cargar() {
      try {
        const respuesta = await consultar('/api/v1/favoritos')

        if (!respuesta.ok) {
          throw new Error(
            await leerError(respuesta, 'No se pudieron cargar tus favoritos.')
          )
        }

        const datos = await respuesta.json()

        if (activo) {
          setLista(datos)
        }
      } catch (excepcion) {
        if (activo) {
          setError(excepcion.message)
        }
      } finally {
        if (activo) {
          setCargando(false)
        }
      }
    }

    cargar()

    return () => {
      activo = false
    }
  }, [])

  // Al quitar un corazón, la tarjeta desaparece de la lista
  const visibles = lista.filter((resultado) =>
    favoritos.has(resultado.alojamiento.idAlojamiento)
  )

  return (
    <section className="contenedor">
      <h1 className="titulo-serif">Favoritos</h1>
      <p className="texto-suave">
        Los alojamientos que guardaste con el corazón.
      </p>

      {cargando ? (
        <p className="cargando" role="status">
          Cargando tus favoritos...
        </p>
      ) : error ? (
        <p className="aviso aviso-error" role="alert">
          {error}
        </p>
      ) : visibles.length === 0 ? (
        <div className="tarjeta vacio">
          <span aria-hidden="true">♡</span>
          <h2>Aún no tienes favoritos</h2>
          <p className="texto-suave">
            Toca el corazón de un alojamiento para guardarlo aquí.
          </p>
          <button
            type="button"
            className="boton-principal"
            onClick={onExplorar}
          >
            Explorar alojamientos
          </button>
        </div>
      ) : (
        <ul className="grilla-resultados">
          {visibles.map((resultado) => (
            <TarjetaResultado
              key={resultado.alojamiento.idAlojamiento}
              resultado={resultado}
              esFavorito
              onFavorito={onFavorito}
              onAbrir={onVerAlojamiento}
            />
          ))}
        </ul>
      )}
    </section>
  )
}

export default MisFavoritos
