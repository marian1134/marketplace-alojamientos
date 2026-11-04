import { t, useIdioma, localeActual } from '../idiomas'
import { useEffect, useMemo, useState } from 'react';
import { consultar, enviarDatos, leerError } from '../api';
import { NOMBRES_TIPO } from '../tipos';
import { enlaceGoogleMaps, urlMapa } from '../mapa';
import CampoFecha from './CampoFecha';
import ReportarResena from './ReportarResena';
import { Estrellas, IconoCorazon, IconoEstrella, IconoUbicacion } from './Iconos';
import { aFecha, aTexto, explicarPolitica, fechaMaximaLlegada, MAXIMO_NOCHES, nombreCortoPolitica, sumarDias, fechaCorta, fotoRespaldo, hoyTexto, NOMBRES_POLITICA, pesos, } from '../formato';
// Agrupa noches seguidas: ['2026-11-11','2026-11-12'] -> [{desde, hasta}]
function agruparNoches(noches) {
    const grupos = [];
    for (const noche of noches) {
        const ultimo = grupos[grupos.length - 1];
        if (ultimo) {
            const siguiente = aFecha(ultimo.hasta);
            siguiente.setDate(siguiente.getDate() + 1);
            if (aTexto(siguiente) === noche) {
                ultimo.hasta = noche;
                continue;
            }
        }
        grupos.push({ desde: noche, hasta: noche });
    }
    return grupos;
}
function DetalleAlojamiento({ idAlojamiento, busqueda, favoritos, onFavorito, onVolver, onReservar, }) {
    useIdioma();
    const [detalle, setDetalle] = useState(null);
    const [error, setError] = useState('');
    const [entrada, setEntrada] = useState(busqueda?.entrada ?? '');
    const [salida, setSalida] = useState(busqueda?.salida ?? '');
    const [huespedes, setHuespedes] = useState(Number(busqueda?.huespedes) || 1);
    const [cotizacion, setCotizacion] = useState(null);
    const [mensajePrecio, setMensajePrecio] = useState('');
    const [imagenActual, setImagenActual] = useState(0);
    useEffect(() => {
        let activo = true;
        async function cargar() {
            try {
                const respuesta = await consultar(`/api/v1/alojamientos/${idAlojamiento}/detalle`);
                if (!respuesta.ok) {
                    throw new Error(await leerError(respuesta, t("No se pudo cargar el alojamiento.")));
                }
                const recibidos = await respuesta.json();
                // Valores por defecto: así la pantalla funciona aunque el
                // backend todavía no envíe reseñas, periodos o favoritos
                const datos = {
                    ...recibidos,
                    imagenes: recibidos.imagenes ?? [],
                    nochesOcupadas: recibidos.nochesOcupadas ?? [],
                    periodosDisponibles: recibidos.periodosDisponibles ?? [],
                    resenas: recibidos.resenas ?? [],
                    distribucionEstrellas: recibidos.distribucionEstrellas ?? [0, 0, 0, 0, 0],
                    cantidadResenas: recibidos.cantidadResenas ?? 0,
                    backendDesactualizado: recibidos.periodosDisponibles === undefined,
                };
                if (activo) {
                    setDetalle(datos);
                    setHuespedes((actual) => Math.min(actual, datos.alojamiento.capacidad));
                }
            }
            catch (excepcion) {
                if (activo) {
                    setError(excepcion.message);
                }
            }
        }
        cargar();
        return () => {
            activo = false;
        };
    }, [idAlojamiento]);
    const ocupadas = useMemo(() => new Set(detalle?.nochesOcupadas ?? []), [detalle]);
    // Revisa en el navegador si alguna noche elegida ya está ocupada
    const choca = useMemo(() => {
        if (!entrada || !salida || salida <= entrada) {
            return false;
        }
        const fecha = aFecha(entrada);
        while (aTexto(fecha) < salida) {
            if (ocupadas.has(aTexto(fecha))) {
                return true;
            }
            fecha.setDate(fecha.getDate() + 1);
        }
        return false;
    }, [entrada, salida, ocupadas]);
    // Si el anfitrión definió periodos, la estadía debe caber en uno
    const fueraDePeriodo = useMemo(() => {
        const periodos = detalle?.periodosDisponibles ?? [];
        if (!entrada || !salida || periodos.length === 0) {
            return false;
        }
        return !periodos.some((periodo) => entrada >= periodo.fechaInicio && salida <= periodo.fechaFin);
    }, [detalle, entrada, salida]);
    const fechasValidas = entrada && salida && entrada >= hoyTexto() && salida > entrada;
    // Pide el precio al backend cada vez que cambian fechas o huéspedes
    useEffect(() => {
        if (!detalle || !fechasValidas || choca || fueraDePeriodo) {
            return;
        }
        let activo = true;
        const espera = setTimeout(async () => {
            try {
                const respuesta = await enviarDatos('/api/v1/reservas/cotizacion', {
                    idAlojamiento,
                    fechaLlegada: entrada,
                    fechaSalida: salida,
                    cantidadHuespedes: huespedes,
                });
                if (!activo) {
                    return;
                }
                if (!respuesta.ok) {
                    setCotizacion(null);
                    setMensajePrecio(await leerError(respuesta, t("No se pudo calcular el precio.")));
                    return;
                }
                setMensajePrecio('');
                setCotizacion(await respuesta.json());
            }
            catch {
                if (activo) {
                    setMensajePrecio(t("No se pudo calcular el precio. Revisa la conexi\u00F3n."));
                }
            }
        }, 300);
        return () => {
            activo = false;
            clearTimeout(espera);
        };
    }, [
        detalle,
        idAlojamiento,
        entrada,
        salida,
        huespedes,
        fechasValidas,
        choca,
        fueraDePeriodo,
    ]);
    if (error) {
        return (<section className="contenedor">
        <button type="button" className="boton-volver" onClick={onVolver}>{t("\u2190 Volver")}</button>
        <p className="aviso aviso-error" role="alert">
          {t(error)}
        </p>
      </section>);
    }
    if (!detalle) {
        return (<section className="contenedor">
        <p className="cargando" role="status">{t("Cargando alojamiento...")}</p>
      </section>);
    }
    const { alojamiento, imagenes, politica } = detalle;
    const tipo = NOMBRES_TIPO[alojamiento.tipoAlojamiento] ??
        alojamiento.tipoAlojamiento;
    const portada = imagenes[imagenActual] ?? imagenes[0];
    const miniaturas = imagenes.slice(0, 5);
    const gruposOcupados = agruparNoches(detalle.nochesOcupadas);
    const periodos = detalle.periodosDisponibles;
    // Noche que no se puede reservar: ocupada o fuera de los periodos
    function nocheNoDisponible(fecha) {
        if (ocupadas.has(fecha)) {
            return true;
        }
        return (periodos.length > 0 &&
            !periodos.some((periodo) => fecha >= periodo.fechaInicio && fecha < periodo.fechaFin));
    }
    // Última salida posible: antes de la siguiente noche no disponible
    // y máximo 90 noches
    function maximaSalida(llegada) {
        let fecha = llegada;
        for (let noche = 1; noche <= MAXIMO_NOCHES; noche++) {
            fecha = sumarDias(llegada, noche);
            if (nocheNoDisponible(fecha)) {
                return fecha;
            }
        }
        return fecha;
    }
    let aviso = mensajePrecio;
    if (entrada && entrada < hoyTexto()) {
        aviso = t("La fecha de entrada no puede estar en el pasado.");
    }
    else if (entrada && salida && salida <= entrada) {
        aviso = t("La salida debe ser despu\u00E9s de la entrada.");
    }
    else if (choca) {
        aviso = t("Alguna de esas noches ya est\u00E1 reservada. Elige otras fechas.");
    }
    else if (fueraDePeriodo) {
        aviso = t("El anfitri\u00F3n no recibe hu\u00E9spedes en esas fechas. Mira las fechas disponibles.");
    }
    const puedeReservar = fechasValidas && !choca && !fueraDePeriodo && cotizacion && !aviso;
    function reservar() {
        onReservar({
            detalle,
            entrada,
            salida,
            huespedes,
            cotizacion,
        });
    }
    return (<section className="contenedor detalle">
      <button type="button" className="boton-volver" onClick={onVolver}>{t("\u2190 Volver")}</button>

      {detalle.backendDesactualizado && (<p className="aviso aviso-error" role="alert">{t("El backend est\u00E1 desactualizado: las rese\u00F1as y los periodos no se ven. Ejecuta 06_resenas_favoritos.sql y reinicia el backend (Ctrl + C y mvnw.cmd spring-boot:run).")}</p>)}

      <div className="detalle-galeria">
        <div className="detalle-imagen-principal">
          {portada ? (<img src={portada.urlImagen} alt={t(t("Foto de {0}", alojamiento.titulo))} onError={fotoRespaldo}/>) : (<div className="sin-foto">
              <span aria-hidden="true">⌂</span>{t("Sin fotograf\u00EDas")}</div>)}

          {imagenes.length > 0 && (<span className="contador-fotos">
              {imagenActual + 1} / {imagenes.length}
            </span>)}
        </div>

        {miniaturas.length > 1 && (<div className="detalle-miniaturas">
            {miniaturas.map((imagen, indice) => (<button key={imagen.idImagen} type="button" className={indice === imagenActual ? 'activa' : ''} onClick={() => setImagenActual(indice)} aria-label={t(t("Ver foto {0}", indice + 1))}>
                <img src={imagen.urlImagen} alt="" onError={fotoRespaldo}/>
              </button>))}
          </div>)}
      </div>

      <div className="detalle-cuerpo">
        <div className="detalle-info">
          <p className="migas">{t("Alojamientos \u203A")}{t(tipo)} › {alojamiento.ciudad}
          </p>

          <div className="detalle-titulo">
            <h1>{alojamiento.titulo}</h1>

            <button type="button" className={favoritos.has(alojamiento.idAlojamiento)
            ? 'boton-corazon en-linea activo'
            : 'boton-corazon en-linea'} onClick={() => onFavorito?.(alojamiento.idAlojamiento)} aria-pressed={favoritos.has(alojamiento.idAlojamiento)} aria-label={t("Guardar en favoritos")}>
              <IconoCorazon tamano={20} activo={favoritos.has(alojamiento.idAlojamiento)}/>
              {favoritos.has(alojamiento.idAlojamiento)
            ? t("Guardado") : t("Guardar")}
            </button>
          </div>

          <p className="detalle-ubicacion con-icono">
            {detalle.promedioCalificacion && (<span className="calificacion">
                <IconoEstrella tamano={16}/>
                {detalle.promedioCalificacion.toFixed(1)}
                <a href="#resenas">
                  ({detalle.cantidadResenas}{' '}
                  {detalle.cantidadResenas === 1 ? t("rese\u00F1a") : t("rese\u00F1as")})
                </a>
                ·
              </span>)}
            <IconoUbicacion tamano={16}/>
            {alojamiento.ciudad} · {alojamiento.direccion}
          </p>

          <ul className="detalle-datos">
            <li>
              <strong>{alojamiento.capacidad}</strong>
              {alojamiento.capacidad === 1 ? t("hu\u00E9sped m\u00E1x.") : t("hu\u00E9spedes m\u00E1x.")}
            </li>
            <li>
              <strong>{alojamiento.habitaciones ?? 1}</strong>
              {(alojamiento.habitaciones ?? 1) === 1 ? t("habitaci\u00F3n") : t("habitaciones")}
            </li>
            <li>
              <strong>{alojamiento.banos ?? 1}</strong>
              {(alojamiento.banos ?? 1) === 1 ? t("ba\u00F1o") : t("ba\u00F1os")}
            </li>
            <li>
              <strong>{t(tipo)}</strong>{t("tipo")}</li>
            <li>
              <strong>
                {alojamiento.modoReserva === 'CON_APROBACION'
            ? t("Con aprobaci\u00F3n") : t("Inmediata")}
              </strong>{t("reserva")}</li>
            <li>
              <strong>{t(nombreCortoPolitica(politica.tipo))}</strong>{t("cancelaci\u00F3n")}</li>
          </ul>

          <article className="tarjeta detalle-anfitrion">
            <span className="avatar avatar-grande" aria-hidden="true">
              {detalle.nombreAnfitrion.charAt(0)}
            </span>
            <div>
              <strong>{detalle.nombreAnfitrion}</strong>
              <span className="etiqueta-verde">{t("Anfitri\u00F3n")}</span>
              {detalle.anfitrionDesde && (<p>{t("Anfitri\u00F3n desde ")}{detalle.anfitrionDesde}</p>)}
            </div>
          </article>

          <div className="detalle-columnas">
            <article className="tarjeta">
              <h2>{t("Descripci\u00F3n")}</h2>
              <p className="texto-largo">
                {alojamiento.descripcion}
              </p>
            </article>

            <article className="tarjeta">
              <h2>{t("Reglas y cancelaci\u00F3n")}</h2>
              <ul className="lista-reglas">
                <li>{t("Check-in: 3:00 p. m.")}</li>
                <li>{t("Check-out: 11:00 a. m.")}</li>
                <li>{t("M\u00E1ximo")}{alojamiento.capacidad}{t("hu\u00E9spedes")}</li>
              </ul>
              <p>
                <strong>{t(NOMBRES_POLITICA[politica.tipo])}.</strong>{' '}
                {explicarPolitica(politica, fechasValidas ? entrada : null)}
              </p>
            </article>
          </div>

          {detalle.periodosDisponibles.length > 0 && (<article className="tarjeta">
              <h2>{t("Fechas en que recibe hu\u00E9spedes")}</h2>
              <ul className="fechas-ocupadas">
                {detalle.periodosDisponibles.map((periodo) => (<li key={periodo.idPeriodo}>{t("Del")}{fechaCorta(periodo.fechaInicio)}{t(" al")}{' '}
                    {fechaCorta(periodo.fechaFin)}
                  </li>))}
              </ul>
            </article>)}

          <article className="tarjeta resenas" id="resenas">
            <h2>{t("Rese\u00F1as")}</h2>

            {detalle.cantidadResenas === 0 ? (<p className="texto-suave">{t("Este alojamiento a\u00FAn no tiene rese\u00F1as. \u00A1S\u00E9 el primero en hospedarte y contar tu experiencia!")}</p>) : (<>
                <div className="resenas-resumen">
                  <div className="resenas-promedio">
                    <strong>
                      {detalle.promedioCalificacion.toFixed(1)}
                    </strong>
                    <Estrellas valor={detalle.promedioCalificacion} tamano={18}/>
                    <span className="texto-suave">
                      {detalle.cantidadResenas}{' '}
                      {detalle.cantidadResenas === 1 ? t("rese\u00F1a") : t("rese\u00F1as")}
                    </span>
                  </div>

                  <ul className="resenas-barras">
                    {[5, 4, 3, 2, 1].map((estrella) => {
                const cantidad = detalle.distribucionEstrellas[estrella - 1];
                const porcentaje = (cantidad / detalle.cantidadResenas) * 100;
                return (<li key={estrella}>
                          <span>
                            {estrella}{' '}
                            {estrella === 1 ? t("estrella") : t("estrellas")}
                          </span>
                          <span className="barra">
                            <span style={{ width: `${porcentaje}%` }}/>
                          </span>
                          <span>{cantidad}</span>
                        </li>);
            })}
                  </ul>
                </div>

                <ul className="lista-resenas">
                  {detalle.resenas.map((resena) => (<li key={resena.idResena}>
                      <div className="resena-cabecera">
                        <span className="avatar" aria-hidden="true">
                          {resena.nombreHuesped.charAt(0)}
                        </span>
                        <div>
                          <strong>{resena.nombreHuesped}</strong>
                          <span className="texto-suave">
                            {new Date(resena.fecha).toLocaleDateString(localeActual(), { day: 'numeric', month: 'long', year: 'numeric' })}
                          </span>
                        </div>
                        <Estrellas valor={resena.calificacion}/>
                      </div>
                      <p>{resena.comentario}</p>
                      <ReportarResena key={resena.idResena} idResena={resena.idResena}/>
                    </li>))}
                </ul>
              </>)}
          </article>

          <article className="tarjeta">
            <div className="tarjeta-titulo">
              <h2>{t("Ubicaci\u00F3n")}</h2>
              <a className="boton-enlace" href={enlaceGoogleMaps(alojamiento.ciudad, alojamiento.direccion)} target="_blank" rel="noreferrer">{t("Abrir en Google Maps \u2197")}</a>
            </div>

            <p className="con-icono">
              <IconoUbicacion tamano={16}/>
              {alojamiento.direccion}
            </p>

            <iframe className="mapa" title={t(t("Mapa de {0}", alojamiento.ciudad))} src={urlMapa(alojamiento.ciudad, alojamiento.direccion)} loading="lazy" referrerPolicy="no-referrer-when-downgrade"/>

            <p className="texto-suave nota-mapa">{t("El punto muestra la zona aproximada. El anfitri\u00F3n te enviar\u00E1 la direcci\u00F3n exacta cuando confirmes tu reserva.")}</p>
          </article>

          {gruposOcupados.length > 0 && (<article className="tarjeta">
              <h2>{t("Fechas no disponibles")}</h2>
              <ul className="fechas-ocupadas">
                {gruposOcupados.map((grupo) => (<li key={grupo.desde}>
                    {grupo.desde === grupo.hasta
                    ? t("Noche del {0}", fechaCorta(grupo.desde)) : t("Noches del {0} al {1}", fechaCorta(grupo.desde), fechaCorta(grupo.hasta))}
                  </li>))}
              </ul>
            </article>)}
        </div>

        <aside className="tarjeta detalle-reserva">
          <p className="precio-grande">
            <strong>{pesos(alojamiento.precioNoche)}</strong>{' '}
            <span>{t("noche")}</span>
          </p>

          <div className="campos-fecha">
            <div className="campo-barra">
              <span>{t("Entrada")}</span>
              <CampoFecha etiqueta={t("Fecha de entrada")} value={entrada} min={hoyTexto()} max={fechaMaximaLlegada()} deshabilitada={nocheNoDisponible} onChange={(valor) => {
            setEntrada(valor);
            setCotizacion(null);
            if (salida && (salida <= valor || salida > maximaSalida(valor))) {
                setSalida('');
            }
        }}/>
            </div>

            <div className="campo-barra">
              <span>{t("Salida")}</span>
              <CampoFecha etiqueta={t("Fecha de salida")} value={salida} min={sumarDias(entrada || hoyTexto(), 1)} max={entrada ? maximaSalida(entrada) : undefined} onChange={(valor) => {
            setSalida(valor);
            setCotizacion(null);
        }}/>
            </div>
          </div>

          <label className="campo-huespedes">{t("Hu\u00E9spedes")}<select value={huespedes} onChange={(evento) => {
            setHuespedes(Number(evento.target.value));
            setCotizacion(null);
        }}>
              {Array.from({ length: alojamiento.capacidad }, (_, indice) => indice + 1).map((cantidad) => (<option key={cantidad} value={cantidad}>
                  {cantidad}{' '}
                  {cantidad === 1 ? t("hu\u00E9sped") : t("hu\u00E9spedes")}
                </option>))}
            </select>
          </label>

          <button type="button" className="boton-principal boton-ancho" disabled={!puedeReservar} onClick={reservar}>{t("Reservar ahora")}</button>

          <p className="nota-centro">{t("No se te cobrar\u00E1 todav\u00EDa")}</p>

          {aviso && (<p className="aviso aviso-error" role="alert">
              {t(aviso)}
            </p>)}

          {!aviso && !fechasValidas && (<p className="aviso">{t("Elige las fechas de entrada y salida para ver el precio total.")}</p>)}

          {cotizacion && !aviso && (<dl className="desglose">
              <div>
                <dt>
                  {pesos(cotizacion.precioNoche)} x{' '}
                  {cotizacion.noches}{' '}
                  {cotizacion.noches === 1 ? t("noche") : t("noches")}
                </dt>
                <dd>{pesos(cotizacion.subtotal)}</dd>
              </div>
              <div>
                <dt>{t("Tarifa de limpieza")}</dt>
                <dd>{pesos(cotizacion.tarifaLimpieza)}</dd>
              </div>
              <div>
                <dt>{t("Tarifa de servicio StayHub (")}{Number(cotizacion.porcentajeServicio)} %)
                </dt>
                <dd>{pesos(cotizacion.tarifaServicio)}</dd>
              </div>
              {Number(cotizacion.descuentos) > 0 && (<div className="descuento">
                  <dt>{t("Descuento por estad\u00EDa larga")}</dt>
                  <dd>-{pesos(cotizacion.descuentos)}</dd>
                </div>)}
              <div className="total">
                <dt>{t("Total")}</dt>
                <dd>{pesos(cotizacion.total)}</dd>
              </div>
            </dl>)}

          <div className="reserva-segura">
            <strong>{t("Reserva segura")}</strong>
            <p>{t("Tu pago est\u00E1 protegido")}{alojamiento.modoReserva === 'CON_APROBACION'
            ? t(" y la reserva se confirma cuando el anfitri\u00F3n la acepte.") : t(" y la reserva se confirma al instante.")}
            </p>
          </div>
        </aside>
      </div>
    </section>);
}
export default DetalleAlojamiento;
