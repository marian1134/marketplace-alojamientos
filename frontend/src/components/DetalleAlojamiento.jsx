import { useEffect, useMemo, useState } from 'react'
import { consultar, enviarDatos, leerError } from '../api'
import { NOMBRES_TIPO } from '../tipos'
import { Estrellas, IconoCorazon, IconoEstrella, IconoUbicacion } from './Iconos'
import {
  aFecha,
  aTexto,
  explicarPolitica,
  fechaCorta,
  fotoRespaldo,
  hoyTexto,
  NOMBRES_POLITICA,
  pesos,
} from '../formato'

// Agrupa noches seguidas: ['2026-11-11','2026-11-12'] -> [{desde, hasta}]
function agruparNoches(noches) {
  const grupos = []

  for (const noche of noches) {
    const ultimo = grupos[grupos.length - 1]

    if (ultimo) {
      const siguiente = aFecha(ultimo.hasta)
      siguiente.setDate(siguiente.getDate() + 1)

      if (aTexto(siguiente) === noche) {
        ultimo.hasta = noche
        continue
      }
    }

    grupos.push({ desde: noche, hasta: noche })
  }

  return grupos
}

function DetalleAlojamiento({
  idAlojamiento,
  busqueda,
  favoritos,
  onFavorito,
  onVolver,
  onReservar,
}) {
  const [detalle, setDetalle] = useState(null)
  const [error, setError] = useState('')
  const [entrada, setEntrada] = useState(busqueda?.entrada ?? '')
  const [salida, setSalida] = useState(busqueda?.salida ?? '')
  const [huespedes, setHuespedes] = useState(
    Number(busqueda?.huespedes) || 1
  )
  const [cotizacion, setCotizacion] = useState(null)
  const [mensajePrecio, setMensajePrecio] = useState('')
  const [imagenActual, setImagenActual] = useState(0)

  useEffect(() => {
    let activo = true

    async function cargar() {
      try {
        const respuesta = await consultar(
          `/api/v1/alojamientos/${idAlojamiento}/detalle`
        )

        if (!respuesta.ok) {
          throw new Error(
            await leerError(
              respuesta,
              'No se pudo cargar el alojamiento.'
            )
          )
        }

        const datos = await respuesta.json()

        if (activo) {
          setDetalle(datos)
          setHuespedes((actual) =>
            Math.min(actual, datos.alojamiento.capacidad)
          )
        }
      } catch (excepcion) {
        if (activo) {
          setError(excepcion.message)
        }
      }
    }

    cargar()

    return () => {
      activo = false
    }
  }, [idAlojamiento])

  const ocupadas = useMemo(
    () => new Set(detalle?.nochesOcupadas ?? []),
    [detalle]
  )

  // Revisa en el navegador si alguna noche elegida ya está ocupada
  const choca = useMemo(() => {
    if (!entrada || !salida || salida <= entrada) {
      return false
    }

    const fecha = aFecha(entrada)

    while (aTexto(fecha) < salida) {
      if (ocupadas.has(aTexto(fecha))) {
        return true
      }
      fecha.setDate(fecha.getDate() + 1)
    }

    return false
  }, [entrada, salida, ocupadas])

  // Si el anfitrión definió periodos, la estadía debe caber en uno
  const fueraDePeriodo = useMemo(() => {
    const periodos = detalle?.periodosDisponibles ?? []

    if (!entrada || !salida || periodos.length === 0) {
      return false
    }

    return !periodos.some(
      (periodo) =>
        entrada >= periodo.fechaInicio && salida <= periodo.fechaFin
    )
  }, [detalle, entrada, salida])

  const fechasValidas =
    entrada && salida && entrada >= hoyTexto() && salida > entrada

  // Pide el precio al backend cada vez que cambian fechas o huéspedes
  useEffect(() => {
    if (!detalle || !fechasValidas || choca || fueraDePeriodo) {
      return
    }

    let activo = true

    const espera = setTimeout(async () => {
      try {
        const respuesta = await enviarDatos(
          '/api/v1/reservas/cotizacion',
          {
            idAlojamiento,
            fechaLlegada: entrada,
            fechaSalida: salida,
            cantidadHuespedes: huespedes,
          }
        )

        if (!activo) {
          return
        }

        if (!respuesta.ok) {
          setCotizacion(null)
          setMensajePrecio(
            await leerError(
              respuesta,
              'No se pudo calcular el precio.'
            )
          )
          return
        }

        setMensajePrecio('')
        setCotizacion(await respuesta.json())
      } catch {
        if (activo) {
          setMensajePrecio(
            'No se pudo calcular el precio. Revisa la conexión.'
          )
        }
      }
    }, 300)

    return () => {
      activo = false
      clearTimeout(espera)
    }
  }, [
    detalle,
    idAlojamiento,
    entrada,
    salida,
    huespedes,
    fechasValidas,
    choca,
    fueraDePeriodo,
  ])

  if (error) {
    return (
      <section className="contenedor">
        <button
          type="button"
          className="boton-volver"
          onClick={onVolver}
        >
          ← Volver
        </button>
        <p className="aviso aviso-error" role="alert">
          {error}
        </p>
      </section>
    )
  }

  if (!detalle) {
    return (
      <section className="contenedor">
        <p className="cargando" role="status">
          Cargando alojamiento...
        </p>
      </section>
    )
  }

  const { alojamiento, imagenes, politica } = detalle
  const tipo =
    NOMBRES_TIPO[alojamiento.tipoAlojamiento] ??
    alojamiento.tipoAlojamiento
  const portada = imagenes[imagenActual] ?? imagenes[0]
  const miniaturas = imagenes.slice(0, 5)
  const gruposOcupados = agruparNoches(detalle.nochesOcupadas)

  let aviso = mensajePrecio

  if (entrada && entrada < hoyTexto()) {
    aviso = 'La fecha de entrada no puede estar en el pasado.'
  } else if (entrada && salida && salida <= entrada) {
    aviso = 'La salida debe ser después de la entrada.'
  } else if (choca) {
    aviso =
      'Alguna de esas noches ya está reservada. Elige otras fechas.'
  } else if (fueraDePeriodo) {
    aviso =
      'El anfitrión no recibe huéspedes en esas fechas. Mira las fechas disponibles.'
  }

  const puedeReservar =
    fechasValidas && !choca && !fueraDePeriodo && cotizacion && !aviso

  function reservar() {
    onReservar({
      detalle,
      entrada,
      salida,
      huespedes,
      cotizacion,
    })
  }

  return (
    <section className="contenedor detalle">
      <button
        type="button"
        className="boton-volver"
        onClick={onVolver}
      >
        ← Volver
      </button>

      <div className="detalle-galeria">
        <div className="detalle-imagen-principal">
          {portada ? (
            <img
              src={portada.urlImagen}
              alt={`Foto de ${alojamiento.titulo}`}
              onError={fotoRespaldo}
            />
          ) : (
            <div className="sin-foto">
              <span aria-hidden="true">⌂</span>
              Sin fotografías
            </div>
          )}

          {imagenes.length > 0 && (
            <span className="contador-fotos">
              {imagenActual + 1} / {imagenes.length}
            </span>
          )}
        </div>

        {miniaturas.length > 1 && (
          <div className="detalle-miniaturas">
            {miniaturas.map((imagen, indice) => (
              <button
                key={imagen.idImagen}
                type="button"
                className={
                  indice === imagenActual ? 'activa' : ''
                }
                onClick={() => setImagenActual(indice)}
                aria-label={`Ver foto ${indice + 1}`}
              >
                <img
                  src={imagen.urlImagen}
                  alt=""
                  onError={fotoRespaldo}
                />
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="detalle-cuerpo">
        <div className="detalle-info">
          <p className="migas">
            Alojamientos › {tipo} › {alojamiento.ciudad}
          </p>

          <div className="detalle-titulo">
            <h1>{alojamiento.titulo}</h1>

            <button
              type="button"
              className={
                favoritos.has(alojamiento.idAlojamiento)
                  ? 'boton-corazon en-linea activo'
                  : 'boton-corazon en-linea'
              }
              onClick={() => onFavorito(alojamiento.idAlojamiento)}
              aria-pressed={favoritos.has(alojamiento.idAlojamiento)}
              aria-label="Guardar en favoritos"
            >
              <IconoCorazon
                tamano={20}
                activo={favoritos.has(alojamiento.idAlojamiento)}
              />
              {favoritos.has(alojamiento.idAlojamiento)
                ? 'Guardado'
                : 'Guardar'}
            </button>
          </div>

          <p className="detalle-ubicacion con-icono">
            {detalle.promedioCalificacion && (
              <span className="calificacion">
                <IconoEstrella tamano={16} />
                {detalle.promedioCalificacion.toFixed(1)}
                <a href="#resenas">
                  ({detalle.cantidadResenas}{' '}
                  {detalle.cantidadResenas === 1 ? 'reseña' : 'reseñas'})
                </a>
                ·
              </span>
            )}
            <IconoUbicacion tamano={16} />
            {alojamiento.ciudad} · {alojamiento.direccion}
          </p>

          <ul className="detalle-datos">
            <li>
              <strong>{alojamiento.capacidad}</strong>
              huéspedes máx.
            </li>
            <li>
              <strong>{tipo}</strong>
              tipo
            </li>
            <li>
              <strong>
                {alojamiento.modoReserva === 'CON_APROBACION'
                  ? 'Con aprobación'
                  : 'Inmediata'}
              </strong>
              reserva
            </li>
            <li>
              <strong>
                {NOMBRES_POLITICA[politica.tipo]?.replace(
                  'Cancelación ',
                  ''
                )}
              </strong>
              cancelación
            </li>
          </ul>

          <article className="tarjeta detalle-anfitrion">
            <span className="avatar avatar-grande" aria-hidden="true">
              {detalle.nombreAnfitrion.charAt(0)}
            </span>
            <div>
              <strong>{detalle.nombreAnfitrion}</strong>
              <span className="etiqueta-verde">Anfitrión</span>
              {detalle.anfitrionDesde && (
                <p>Anfitrión desde {detalle.anfitrionDesde}</p>
              )}
            </div>
          </article>

          <div className="detalle-columnas">
            <article className="tarjeta">
              <h2>Descripción</h2>
              <p className="texto-largo">
                {alojamiento.descripcion}
              </p>
            </article>

            <article className="tarjeta">
              <h2>Reglas y cancelación</h2>
              <ul className="lista-reglas">
                <li>Check-in: 3:00 p. m.</li>
                <li>Check-out: 11:00 a. m.</li>
                <li>
                  Máximo {alojamiento.capacidad} huéspedes
                </li>
              </ul>
              <p>
                <strong>{NOMBRES_POLITICA[politica.tipo]}.</strong>{' '}
                {explicarPolitica(politica)}
              </p>
            </article>
          </div>

          {detalle.periodosDisponibles.length > 0 && (
            <article className="tarjeta">
              <h2>Fechas en que recibe huéspedes</h2>
              <ul className="fechas-ocupadas">
                {detalle.periodosDisponibles.map((periodo) => (
                  <li key={periodo.idPeriodo}>
                    Del {fechaCorta(periodo.fechaInicio)} al{' '}
                    {fechaCorta(periodo.fechaFin)}
                  </li>
                ))}
              </ul>
            </article>
          )}

          <article className="tarjeta resenas" id="resenas">
            <h2>Reseñas</h2>

            {detalle.cantidadResenas === 0 ? (
              <p className="texto-suave">
                Este alojamiento aún no tiene reseñas. ¡Sé el primero en
                hospedarte y contar tu experiencia!
              </p>
            ) : (
              <>
                <div className="resenas-resumen">
                  <div className="resenas-promedio">
                    <strong>
                      {detalle.promedioCalificacion.toFixed(1)}
                    </strong>
                    <Estrellas
                      valor={detalle.promedioCalificacion}
                      tamano={18}
                    />
                    <span className="texto-suave">
                      {detalle.cantidadResenas}{' '}
                      {detalle.cantidadResenas === 1 ? 'reseña' : 'reseñas'}
                    </span>
                  </div>

                  <ul className="resenas-barras">
                    {[5, 4, 3, 2, 1].map((estrella) => {
                      const cantidad =
                        detalle.distribucionEstrellas[estrella - 1]
                      const porcentaje =
                        (cantidad / detalle.cantidadResenas) * 100

                      return (
                        <li key={estrella}>
                          <span>
                            {estrella}{' '}
                            {estrella === 1 ? 'estrella' : 'estrellas'}
                          </span>
                          <span className="barra">
                            <span style={{ width: `${porcentaje}%` }} />
                          </span>
                          <span>{cantidad}</span>
                        </li>
                      )
                    })}
                  </ul>
                </div>

                <ul className="lista-resenas">
                  {detalle.resenas.map((resena) => (
                    <li key={resena.idResena}>
                      <div className="resena-cabecera">
                        <span className="avatar" aria-hidden="true">
                          {resena.nombreHuesped.charAt(0)}
                        </span>
                        <div>
                          <strong>{resena.nombreHuesped}</strong>
                          <span className="texto-suave">
                            {new Date(resena.fecha).toLocaleDateString(
                              'es-CO',
                              { day: 'numeric', month: 'long', year: 'numeric' }
                            )}
                          </span>
                        </div>
                        <Estrellas valor={resena.calificacion} />
                      </div>
                      <p>{resena.comentario}</p>
                    </li>
                  ))}
                </ul>
              </>
            )}
          </article>

          <article className="tarjeta">
            <h2>Ubicación</h2>
            <p>
              ⌖ {alojamiento.ciudad} — {alojamiento.direccion}
            </p>
          </article>

          {gruposOcupados.length > 0 && (
            <article className="tarjeta">
              <h2>Fechas no disponibles</h2>
              <ul className="fechas-ocupadas">
                {gruposOcupados.map((grupo) => (
                  <li key={grupo.desde}>
                    {grupo.desde === grupo.hasta
                      ? `Noche del ${fechaCorta(grupo.desde)}`
                      : `Noches del ${fechaCorta(grupo.desde)} al ${fechaCorta(grupo.hasta)}`}
                  </li>
                ))}
              </ul>
            </article>
          )}
        </div>

        <aside className="tarjeta detalle-reserva">
          <p className="precio-grande">
            <strong>{pesos(alojamiento.precioNoche)}</strong>{' '}
            <span>noche</span>
          </p>

          <div className="campos-fecha">
            <label>
              Entrada
              <input
                type="date"
                value={entrada}
                min={hoyTexto()}
                onChange={(evento) => {
                  setEntrada(evento.target.value)
                  setCotizacion(null)
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
                onChange={(evento) => {
                  setSalida(evento.target.value)
                  setCotizacion(null)
                }}
              />
            </label>
          </div>

          <label className="campo-huespedes">
            Huéspedes
            <select
              value={huespedes}
              onChange={(evento) => {
                setHuespedes(Number(evento.target.value))
                setCotizacion(null)
              }}
            >
              {Array.from(
                { length: alojamiento.capacidad },
                (_, indice) => indice + 1
              ).map((cantidad) => (
                <option key={cantidad} value={cantidad}>
                  {cantidad}{' '}
                  {cantidad === 1 ? 'huésped' : 'huéspedes'}
                </option>
              ))}
            </select>
          </label>

          <button
            type="button"
            className="boton-principal boton-ancho"
            disabled={!puedeReservar}
            onClick={reservar}
          >
            Reservar ahora
          </button>

          <p className="nota-centro">No se te cobrará todavía</p>

          {aviso && (
            <p className="aviso aviso-error" role="alert">
              {aviso}
            </p>
          )}

          {!aviso && !fechasValidas && (
            <p className="aviso">
              Elige las fechas de entrada y salida para ver el
              precio total.
            </p>
          )}

          {cotizacion && !aviso && (
            <dl className="desglose">
              <div>
                <dt>
                  {pesos(cotizacion.precioNoche)} x{' '}
                  {cotizacion.noches}{' '}
                  {cotizacion.noches === 1 ? 'noche' : 'noches'}
                </dt>
                <dd>{pesos(cotizacion.subtotal)}</dd>
              </div>
              <div>
                <dt>Tarifa de limpieza</dt>
                <dd>{pesos(cotizacion.tarifaLimpieza)}</dd>
              </div>
              <div>
                <dt>
                  Tarifa de servicio StayHub (
                  {Number(cotizacion.porcentajeServicio)} %)
                </dt>
                <dd>{pesos(cotizacion.tarifaServicio)}</dd>
              </div>
              {Number(cotizacion.descuentos) > 0 && (
                <div className="descuento">
                  <dt>Descuento por estadía larga</dt>
                  <dd>-{pesos(cotizacion.descuentos)}</dd>
                </div>
              )}
              <div className="total">
                <dt>Total</dt>
                <dd>{pesos(cotizacion.total)}</dd>
              </div>
            </dl>
          )}

          <div className="reserva-segura">
            <strong>Reserva segura</strong>
            <p>
              Tu pago está protegido
              {alojamiento.modoReserva === 'CON_APROBACION'
                ? ' y la reserva se confirma cuando el anfitrión la acepte.'
                : ' y la reserva se confirma al instante.'}
            </p>
          </div>
        </aside>
      </div>
    </section>
  )
}

export default DetalleAlojamiento
