import { useEffect, useState } from 'react'
import { consultar, leerError } from '../api'
import { NOMBRES_TIPO } from '../tipos'
import { DESTINOS } from '../destinos'
import { fechaCorta, fotoRespaldo, hoyTexto, pesos } from '../formato'

const ORDENES = {
  recomendados: 'Recomendados',
  menor: 'Menor precio',
  mayor: 'Mayor precio',
}

// Pantalla de resultados que se abre al darle "Buscar"
function ResultadosBusqueda({ busqueda, onBuscar, onVerAlojamiento }) {
  const [destino, setDestino] = useState(busqueda.destino ?? '')
  const [entrada, setEntrada] = useState(busqueda.entrada ?? '')
  const [salida, setSalida] = useState(busqueda.salida ?? '')
  const [huespedes, setHuespedes] = useState(
    busqueda.huespedes ? String(busqueda.huespedes) : ''
  )
  const [resultados, setResultados] = useState([])
  const [cargando, setCargando] = useState(true)
  const [error, setError] = useState('')
  const [tipo, setTipo] = useState('TODOS')
  const [orden, setOrden] = useState('recomendados')

  // Se muestran de a 24 para que la página cargue rápido
  const [cantidadVisible, setCantidadVisible] = useState(24)

  useEffect(() => {
    let activo = true

    async function cargar() {
      setCargando(true)
      setError('')

      const parametros = new URLSearchParams()

      if (busqueda.ciudades?.length) {
        busqueda.ciudades.forEach((ciudad) =>
          parametros.append('ciudades', ciudad)
        )
      } else if (busqueda.destino) {
        parametros.set('destino', busqueda.destino)
      }

      if (busqueda.entrada && busqueda.salida) {
        parametros.set('llegada', busqueda.entrada)
        parametros.set('salida', busqueda.salida)
      }

      if (busqueda.huespedes) {
        parametros.set('huespedes', busqueda.huespedes)
      }

      try {
        const respuesta = await consultar(
          `/api/v1/busqueda?${parametros}`
        )

        if (!respuesta.ok) {
          throw new Error(
            await leerError(
              respuesta,
              'No se pudo hacer la búsqueda.'
            )
          )
        }

        const datos = await respuesta.json()

        if (activo) {
          setResultados(datos)
        }
      } catch (excepcion) {
        if (activo) {
          setError(excepcion.message)
          setResultados([])
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
  }, [busqueda])

  function buscarDeNuevo(evento) {
    evento.preventDefault()

    if (entrada && salida && salida <= entrada) {
      setError('La salida debe ser después de la entrada.')
      return
    }

    onBuscar({
      destino: destino.trim(),
      entrada: entrada && salida ? entrada : '',
      salida: entrada && salida ? salida : '',
      huespedes: Number(huespedes) || '',
    })
  }

  const tiposPresentes = [
    ...new Set(
      resultados.map(
        (resultado) => resultado.alojamiento.tipoAlojamiento
      )
    ),
  ]

  const visibles = resultados
    .filter(
      (resultado) =>
        tipo === 'TODOS' ||
        resultado.alojamiento.tipoAlojamiento === tipo
    )
    .sort((a, b) => {
      const precioA = Number(a.alojamiento.precioNoche)
      const precioB = Number(b.alojamiento.precioNoche)

      if (orden === 'menor') return precioA - precioB
      if (orden === 'mayor') return precioB - precioA
      return 0
    })

  const lugar = busqueda.destino || 'todos los destinos'
  const conFechas = busqueda.entrada && busqueda.salida

  return (
    <section className="contenedor resultados">
      <form className="barra-busqueda tarjeta" onSubmit={buscarDeNuevo}>
        <label>
          ¿A dónde vas?
          <input
            value={destino}
            onChange={(evento) => setDestino(evento.target.value)}
            placeholder="Ciudad o destino"
          />
        </label>

        <label>
          Entrada
          <input
            type="date"
            value={entrada}
            min={hoyTexto()}
            onChange={(evento) => {
              setEntrada(evento.target.value)
              if (salida && salida <= evento.target.value) {
                setSalida('')
              }
            }}
          />
        </label>

        <label>
          Salida
          <input
            type="date"
            value={salida}
            min={entrada || hoyTexto()}
            onChange={(evento) => setSalida(evento.target.value)}
          />
        </label>

        <label>
          Huéspedes
          <input
            type="number"
            min="1"
            value={huespedes}
            placeholder="Cualquiera"
            onChange={(evento) => setHuespedes(evento.target.value)}
          />
        </label>

        <button type="submit" className="boton-principal">
          ⌕ Buscar
        </button>
      </form>

      <div className="resultados-cabecera">
        <div>
          <h1 className="titulo-serif">
            {busqueda.destino
              ? `Alojamientos en ${busqueda.destino}`
              : 'Todos los alojamientos'}
          </h1>
          <p className="texto-suave">
            {cargando
              ? 'Buscando...'
              : `${visibles.length} ${visibles.length === 1 ? 'alojamiento disponible' : 'alojamientos disponibles'}`}
            {conFechas &&
              ` · ${fechaCorta(busqueda.entrada)} – ${fechaCorta(busqueda.salida)}`}
            {busqueda.huespedes &&
              ` · ${busqueda.huespedes} ${Number(busqueda.huespedes) === 1 ? 'huésped' : 'huéspedes'}`}
          </p>
        </div>

        <label className="campo-orden">
          Ordenar por
          <select
            value={orden}
            onChange={(evento) => {
              setOrden(evento.target.value)
              setCantidadVisible(24)
            }}
          >
            {Object.entries(ORDENES).map(([valor, texto]) => (
              <option key={valor} value={valor}>
                {texto}
              </option>
            ))}
          </select>
        </label>
      </div>

      {tiposPresentes.length > 1 && (
        <div className="filtros-tipo" role="group" aria-label="Tipo de alojamiento">
          {['TODOS', ...tiposPresentes].map((valor) => (
            <button
              key={valor}
              type="button"
              className={tipo === valor ? 'activo' : ''}
              aria-pressed={tipo === valor}
              onClick={() => {
                setTipo(valor)
                setCantidadVisible(24)
              }}
            >
              {valor === 'TODOS' ? 'Todos' : NOMBRES_TIPO[valor]}
            </button>
          ))}
        </div>
      )}

      {error && (
        <p className="aviso aviso-error" role="alert">
          {error}
        </p>
      )}

      {cargando ? (
        <p className="cargando" role="status">
          Buscando alojamientos...
        </p>
      ) : visibles.length === 0 ? (
        <div className="tarjeta vacio">
          <span aria-hidden="true">🔎</span>
          <h2>No encontramos alojamientos en {lugar}</h2>
          <p className="texto-suave">
            {conFechas
              ? 'Puede que estén ocupados en esas fechas. Prueba otras fechas u otro destino.'
              : 'Prueba con otro destino o mira todos los alojamientos.'}
          </p>

          <button
            type="button"
            className="boton-principal"
            onClick={() =>
              onBuscar({ destino: '', entrada: '', salida: '', huespedes: '' })
            }
          >
            Ver todos los alojamientos
          </button>

          <p className="texto-suave sugerencia-titulo">
            O explora un destino popular:
          </p>
          <div className="filtros-tipo centrado">
            {DESTINOS.map((item) => (
              <button
                key={item.id}
                type="button"
                onClick={() =>
                  onBuscar({
                    destino: item.nombre,
                    ciudades: item.ciudades,
                    entrada: busqueda.entrada,
                    salida: busqueda.salida,
                    huespedes: busqueda.huespedes,
                  })
                }
              >
                {item.nombre}
              </button>
            ))}
          </div>
        </div>
      ) : (
        <ul className="grilla-resultados">
          {visibles
            .slice(0, cantidadVisible)
            .map(({ alojamiento, imagenPortada, noches, totalEstimado }) => (
            <li key={alojamiento.idAlojamiento}>
              <button
                type="button"
                className="tarjeta resultado"
                onClick={() => onVerAlojamiento(alojamiento.idAlojamiento)}
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
                  <strong>{alojamiento.titulo}</strong>
                  <span className="texto-suave">
                    ⌖ {alojamiento.ciudad} · hasta {alojamiento.capacidad}{' '}
                    huéspedes
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
            </li>
          ))}
        </ul>
      )}

      {!cargando && visibles.length > cantidadVisible && (
        <div className="ver-mas">
          <p className="texto-suave">
            Mostrando {cantidadVisible} de {visibles.length}
          </p>
          <button
            type="button"
            className="boton-secundario"
            onClick={() => setCantidadVisible(cantidadVisible + 24)}
          >
            Ver más alojamientos
          </button>
        </div>
      )}
    </section>
  )
}

export default ResultadosBusqueda
