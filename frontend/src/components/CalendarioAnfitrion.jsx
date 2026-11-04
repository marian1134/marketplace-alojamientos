import { t, useIdioma, localeActual } from '../idiomas'
import { useEffect, useMemo, useState } from 'react';
import { consultar, enviarDatos, leerError } from '../api';
import { aTexto, fechaCorta, hoyTexto, sumarDias } from '../formato';
import CampoFecha from './CampoFecha';
const DIAS = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];
// Días de un mes para pintar la cuadrícula (empieza en lunes)
function diasDelMes(anio, mes) {
    const primero = new Date(anio, mes, 1);
    const huecos = (primero.getDay() + 6) % 7;
    const total = new Date(anio, mes + 1, 0).getDate();
    return [
        ...Array.from({ length: huecos }, () => null),
        ...Array.from({ length: total }, (_, indice) => new Date(anio, mes, indice + 1)),
    ];
}
function Mes({ anio, mes, estadoDelDia }) {
    useIdioma();
    const nombre = new Date(anio, mes, 1).toLocaleDateString(localeActual(), {
        month: 'long',
        year: 'numeric',
    });
    return (<div className="mes">
      <h3>{nombre}</h3>
      <div className="mes-grilla">
        {DIAS.map((dia) => (<span key={dia} className="mes-dia-nombre">
            {t(dia)}
          </span>))}

        {diasDelMes(anio, mes).map((fecha, indice) => {
            if (!fecha) {
                return <span key={`hueco-${indice}`}/>;
            }
            const { clase, detalle } = estadoDelDia(aTexto(fecha));
            return (<span key={aTexto(fecha)} className={`mes-dia ${clase}`} title={t(detalle)}>
              {fecha.getDate()}
            </span>);
        })}
      </div>
    </div>);
}
function CalendarioAnfitrion({ onGestionarAlojamientos }) {
    useIdioma();
    const [alojamientos, setAlojamientos] = useState([]);
    const [idElegido, setIdElegido] = useState('');
    const [calendario, setCalendario] = useState(null);
    const [cargando, setCargando] = useState(true);
    const [mensaje, setMensaje] = useState('');
    const [error, setError] = useState('');
    const [inicio, setInicio] = useState('');
    const [fin, setFin] = useState('');
    const hoy = new Date();
    const [mesVisible, setMesVisible] = useState({
        anio: hoy.getFullYear(),
        mes: hoy.getMonth(),
    });
    // Lista de alojamientos del anfitrión
    useEffect(() => {
        let activo = true;
        consultar('/api/v1/alojamientos/mis-alojamientos')
            .then((respuesta) => (respuesta.ok ? respuesta.json() : []))
            .then((datos) => {
            if (activo) {
                setAlojamientos(datos);
                setIdElegido(datos[0]?.idAlojamiento ?? '');
                setCargando(false);
            }
        })
            .catch(() => {
            if (activo) {
                setError(t("No se pudieron cargar tus alojamientos."));
                setCargando(false);
            }
        });
        return () => {
            activo = false;
        };
    }, []);
    // Calendario del alojamiento elegido
    useEffect(() => {
        if (!idElegido) {
            return;
        }
        let activo = true;
        consultar(`/api/v1/alojamientos/${idElegido}/calendario`)
            .then(async (respuesta) => {
            if (!respuesta.ok) {
                throw new Error(await leerError(respuesta, t("No se pudo cargar el calendario.")));
            }
            return respuesta.json();
        })
            .then((datos) => {
            if (activo) {
                setCalendario(datos);
                setError('');
            }
        })
            .catch((excepcion) => {
            if (activo) {
                setError(excepcion.message);
            }
        });
        return () => {
            activo = false;
        };
    }, [idElegido]);
    const reservadas = useMemo(() => new Map((calendario?.nochesReservadas ?? []).map((noche) => [noche.fecha, noche])), [calendario]);
    function estadoDelDia(fecha) {
        const reserva = reservadas.get(fecha);
        if (reserva) {
            return {
                clase: 'reservado',
                detalle: t("Reservado: {0} \u00B7 {1}", reserva.codigoReserva, reserva.nombreHuesped),
            };
        }
        if (fecha < hoyTexto()) {
            return { clase: 'pasado', detalle: '' };
        }
        const periodos = calendario?.periodos ?? [];
        // La noche de la fecha fin no cuenta: es el día de salida
        const disponible = periodos.length === 0 ||
            periodos.some((periodo) => fecha >= periodo.fechaInicio && fecha < periodo.fechaFin);
        return disponible
            ? { clase: 'disponible', detalle: t("Disponible") }
            : { clase: 'cerrado', detalle: t("No recibes hu\u00E9spedes") };
    }
    async function agregarPeriodo(evento) {
        evento.preventDefault();
        setMensaje('');
        if (!inicio || !fin) {
            setMensaje(t("Elige las fechas de inicio y fin del periodo."));
            return;
        }
        const respuesta = await enviarDatos(`/api/v1/alojamientos/${idElegido}/periodos`, { fechaInicio: inicio, fechaFin: fin });
        if (!respuesta.ok) {
            setMensaje(await leerError(respuesta, t("No se pudo guardar el periodo.")));
            return;
        }
        setCalendario(await respuesta.json());
        setInicio('');
        setFin('');
    }
    async function eliminarPeriodo(idPeriodo) {
        setMensaje('');
        const respuesta = await enviarDatos(`/api/v1/periodos/${idPeriodo}`, {}, 'DELETE');
        if (!respuesta.ok) {
            setMensaje(await leerError(respuesta, t("No se pudo borrar el periodo.")));
            return;
        }
        setCalendario(await respuesta.json());
    }
    function moverMes(cantidad) {
        const fecha = new Date(mesVisible.anio, mesVisible.mes + cantidad, 1);
        setMesVisible({ anio: fecha.getFullYear(), mes: fecha.getMonth() });
    }
    const siguiente = new Date(mesVisible.anio, mesVisible.mes + 1, 1);
    return (<section className="contenedor">
      <h1 className="titulo-serif">{t("Calendario y disponibilidad")}</h1>
      <p className="texto-suave">{t("Elige en qu\u00E9 fechas recibes hu\u00E9spedes y mira tus noches reservadas.")}</p>

      {cargando ? (<p className="cargando" role="status">{t("Cargando...")}</p>) : alojamientos.length === 0 ? (<div className="tarjeta vacio">
          <span aria-hidden="true">🏡</span>
          <h2>{t("Primero publica un alojamiento")}</h2>
          <button type="button" className="boton-principal" onClick={onGestionarAlojamientos}>{t("+ Publicar un alojamiento")}</button>
        </div>) : (<>
          <label className="campo-alojamiento">{t("Alojamiento")}<select value={idElegido} onChange={(evento) => {
                setCalendario(null);
                setIdElegido(Number(evento.target.value));
            }}>
              {alojamientos.map((alojamiento) => (<option key={alojamiento.idAlojamiento} value={alojamiento.idAlojamiento}>
                  {alojamiento.titulo} · {alojamiento.ciudad}
                </option>))}
            </select>
          </label>

          {error && (<p className="aviso aviso-error" role="alert">
              {t(error)}
            </p>)}

          {calendario && (<div className="calendario-columnas">
              <article className="tarjeta">
                <div className="tarjeta-titulo">
                  <button type="button" className="boton-secundario" onClick={() => moverMes(-1)} aria-label={t("Mes anterior")}>
                    ‹
                  </button>
                  <div className="leyenda">
                    <span><i className="disponible"/>{t(" Disponible")}</span>
                    <span><i className="reservado"/>{t(" Reservado")}</span>
                    <span><i className="cerrado"/>{t(" No recibes")}</span>
                  </div>
                  <button type="button" className="boton-secundario" onClick={() => moverMes(1)} aria-label={t("Mes siguiente")}>
                    ›
                  </button>
                </div>

                <div className="meses">
                  <Mes anio={mesVisible.anio} mes={mesVisible.mes} estadoDelDia={estadoDelDia}/>
                  <Mes anio={siguiente.getFullYear()} mes={siguiente.getMonth()} estadoDelDia={estadoDelDia}/>
                </div>

                <p className="texto-suave">{t("Pasa el mouse sobre un d\u00EDa reservado para ver el c\u00F3digo y el hu\u00E9sped.")}</p>
              </article>

              <aside className="tarjeta">
                <h2>{t("Fechas en que recibes hu\u00E9spedes")}</h2>

                {calendario.periodos.length === 0 ? (<p className="aviso">{t("No has definido periodos, as\u00ED que tu alojamiento est\u00E1 disponible todos los d\u00EDas. Agrega uno si solo quieres recibir hu\u00E9spedes en ciertas fechas.")}</p>) : (<ul className="lista-periodos">
                    {calendario.periodos.map((periodo) => (<li key={periodo.idPeriodo}>
                        <span>
                          {fechaCorta(periodo.fechaInicio)} –{' '}
                          {fechaCorta(periodo.fechaFin)}
                        </span>
                        <button type="button" className="boton-enlace" onClick={() => eliminarPeriodo(periodo.idPeriodo)}>{t("Quitar")}</button>
                      </li>))}
                  </ul>)}

                <form onSubmit={agregarPeriodo}>
                  <h3>{t("Agregar periodo")}</h3>
                  <div className="campo-barra">
                    <span>{t("Desde")}</span>
                    <CampoFecha etiqueta={t("Inicio del periodo")} value={inicio} min={hoyTexto()} max={sumarDias(hoyTexto(), 730)} onChange={(valor) => {
                    setInicio(valor);
                    if (fin && fin <= valor) {
                        setFin('');
                    }
                }}/>
                  </div>

                  <div className="campo-barra">
                    <span>{t("Hasta")}</span>
                    <CampoFecha etiqueta={t("Fin del periodo")} value={fin} min={sumarDias(inicio || hoyTexto(), 1)} max={sumarDias(inicio || hoyTexto(), 730)} onChange={setFin}/>
                  </div>

                  {mensaje && (<p className="aviso aviso-error" role="alert">
                      {t(mensaje)}
                    </p>)}

                  <button type="submit" className="boton-principal boton-ancho">{t("Guardar periodo")}</button>
                </form>
              </aside>
            </div>)}
        </>)}
    </section>);
}
export default CalendarioAnfitrion;
