import { textoNotificacion } from '../idiomas/notificaciones'
import { t, useIdioma, localeActual, idiomaActual } from '../idiomas'
import { useCallback, useEffect, useId, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { enviarDatos, leerError } from '../api';
import ChatReserva from './ChatReserva';
import DetalleReservaAviso, { buscarReservaNotificacion } from './DetalleReservaAviso';
import './campana-notificaciones.css';
const RUTA = '/api/v1/notificaciones';
function fechaAviso(valor) {
    const fecha = new Date(valor);
    return Number.isNaN(fecha.getTime()) ? '' : fecha.toLocaleString(localeActual(), {
        day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
    });
}
export default function CampanaNotificaciones({ usuario }) {
    useIdioma();
    if (!usuario)
        return null;
    return <BandejaNotificaciones key={usuario.correo || usuario.id} usuario={usuario}/>;
}
function BandejaNotificaciones({ usuario } = {}) {
    useIdioma();
    const id = useId();
    const boton = useRef(null);
    const panel = useRef(null);
    const vigente = useRef(false);
    const consulta = useRef(null);
    const version = useRef(0);
    const escribiendo = useRef(false);
    const sesionTerminada = useRef(false);
    const aperturaEnCurso = useRef(false);
    const consultaChat = useRef(null);
    const [abierta, setAbierta] = useState(false);
    const [chatAbierto, setChatAbierto] = useState(null);
    const [reservaAbierta, setReservaAbierta] = useState(null);
    const [abriendoAviso, setAbriendoAviso] = useState(null);
    const [avisos, setAvisos] = useState([]);
    const [sinLeer, setSinLeer] = useState(0);
    const [cargando, setCargando] = useState(true);
    const [guardando, setGuardando] = useState(false);
    const [error, setError] = useState('');
    const [posicion, setPosicion] = useState({ top: 80, right: 16 });
    const cargar = useCallback(async () => {
        if (escribiendo.current || sesionTerminada.current)
            return;
        consulta.current?.abort();
        const controlador = new AbortController();
        consulta.current = controlador;
        const turno = ++version.current;
        const actual = () => vigente.current && turno === version.current;
        try {
            const respuesta = await fetch(RUTA, {
                credentials: 'same-origin', cache: 'no-store', signal: controlador.signal,
            });
            if (!respuesta.ok) {
                if (respuesta.status === 401) {
                    sesionTerminada.current = true;
                    if (actual()) {
                        setAvisos([]);
                        setSinLeer(0);
                    }
                }
                throw new Error(await leerError(respuesta, t("No pudimos cargar tus notificaciones.")));
            }
            const datos = await respuesta.json();
            if (!Array.isArray(datos.notificaciones) || !Number.isFinite(datos.sinLeer)) {
                throw new Error(t("La respuesta de notificaciones no es v\u00E1lida."));
            }
            if (actual()) {
                setAvisos(datos.notificaciones);
                setSinLeer(datos.sinLeer);
                setError('');
            }
        }
        catch (excepcion) {
            if (excepcion.name !== 'AbortError' && actual())
                setError(excepcion.message);
        }
        finally {
            if (actual())
                setCargando(false);
        }
    }, []);
    useEffect(() => {
        vigente.current = true;
        const actualizar = () => { if (!document.hidden)
            cargar(); };
        actualizar();
        const intervalo = window.setInterval(actualizar, 30000);
        window.addEventListener('focus', actualizar);
        document.addEventListener('visibilitychange', actualizar);
        return () => {
            vigente.current = false;
            version.current++;
            consulta.current?.abort();
            consultaChat.current?.abort();
            window.clearInterval(intervalo);
            window.removeEventListener('focus', actualizar);
            document.removeEventListener('visibilitychange', actualizar);
        };
    }, [cargar]);
    useEffect(() => {
        if (!abierta)
            return;
        const ubicar = () => {
            const rect = boton.current?.getBoundingClientRect();
            if (rect)
                setPosicion({
                    top: Math.max(8, Math.min(rect.bottom + 12, window.innerHeight - 220)),
                    right: Math.max(16, window.innerWidth - rect.right),
                });
        };
        const cerrarFuera = (evento) => {
            if (!panel.current?.contains(evento.target) && !boton.current?.contains(evento.target)) {
                setAbierta(false);
            }
        };
        const teclado = (evento) => {
            if (evento.key === 'Escape') {
                setAbierta(false);
                boton.current?.focus();
            }
        };
        ubicar();
        panel.current?.focus();
        window.addEventListener('resize', ubicar);
        window.addEventListener('scroll', ubicar, true);
        document.addEventListener('pointerdown', cerrarFuera);
        document.addEventListener('keydown', teclado);
        return () => {
            window.removeEventListener('resize', ubicar);
            window.removeEventListener('scroll', ubicar, true);
            document.removeEventListener('pointerdown', cerrarFuera);
            document.removeEventListener('keydown', teclado);
        };
    }, [abierta]);
    async function marcar(idAviso) {
        if (escribiendo.current || sesionTerminada.current)
            return false;
        escribiendo.current = true;
        version.current++;
        consulta.current?.abort();
        setGuardando(true);
        setError('');
        setCargando(false);
        try {
            const ruta = idAviso == null ? `${RUTA}/leidas` : `${RUTA}/${idAviso}/leida`;
            const respuesta = await enviarDatos(ruta, {}, 'PATCH');
            if (!respuesta.ok) {
                if (respuesta.status === 401) {
                    sesionTerminada.current = true;
                    if (vigente.current) {
                        setAvisos([]);
                        setSinLeer(0);
                    }
                }
                throw new Error(await leerError(respuesta, t("No pudimos marcar las notificaciones.")));
            }
            if (vigente.current) {
                setAvisos((anteriores) => anteriores.map((aviso) => idAviso == null || aviso.id === idAviso ? { ...aviso, leida: true } : aviso));
                setSinLeer((total) => idAviso == null ? 0 : Math.max(0, total - 1));
            }
            escribiendo.current = false;
            if (vigente.current)
                await cargar();
            return true;
        }
        catch (excepcion) {
            if (vigente.current)
                setError(excepcion.message);
            return false;
        }
        finally {
            escribiendo.current = false;
            if (vigente.current)
                setGuardando(false);
        }
    }
    async function abrirAviso(aviso) {
        if (aperturaEnCurso.current || escribiendo.current || sesionTerminada.current)
            return;
        if (aviso.entidad === 'REPORTE_RESENA' && aviso.tipo === 'REPORTE_RESENA_NUEVO') {
            await abrirReporte(aviso);
            return;
        }
        const idReserva = Number(aviso.entidadId);
        if (!Number.isSafeInteger(idReserva) || idReserva <= 0) {
            setError(t("La notificaci\u00F3n no tiene una reserva v\u00E1lida."));
            return;
        }
        aperturaEnCurso.current = true;
        setAbriendoAviso(aviso.id);
        setError('');
        const controlador = new AbortController();
        consultaChat.current = controlador;
        try {
            const esChat = aviso.tipo === 'MENSAJE_CHAT';
            let datos;
            if (esChat) {
                const respuesta = await fetch(`/api/v1/reservas/${idReserva}/mensajes`, {
                    credentials: 'same-origin', cache: 'no-store', signal: controlador.signal,
                });
                if (!respuesta.ok) {
                    if (respuesta.status === 401)
                        sesionTerminada.current = true;
                    throw new Error(await leerError(respuesta, t("No pudimos abrir el chat de esta reserva.")));
                }
                datos = await respuesta.json();
                if (Number(datos.idReserva) !== idReserva) {
                    throw new Error(t("La conversaci\u00F3n recibida no corresponde a esta reserva."));
                }
            }
            else {
                datos = await buscarReservaNotificacion(idReserva, usuario?.rol, controlador.signal);
            }
            if (!vigente.current)
                return;
            // Si falla la marca de lectura, conserva la bandeja y permite reintentar.
            if (!aviso.leida && !(await marcar(aviso.id)))
                return;
            if (!vigente.current)
                return;
            if (esChat) {
                setChatAbierto({
                    idReserva,
                    codigo: datos.codigoReserva,
                    tituloAlojamiento: datos.tituloAlojamiento,
                });
            }
            else {
                setReservaAbierta(datos);
            }
            setAbierta(false);
        }
        catch (excepcion) {
            if (excepcion.name !== 'AbortError' && vigente.current)
                setError(excepcion.message);
        }
        finally {
            aperturaEnCurso.current = false;
            if (vigente.current)
                setAbriendoAviso(null);
        }
    }
    async function abrirReporte(aviso) {
        const idReporte = Number(aviso.entidadId);
        if (usuario?.rol !== 'ADMINISTRADOR' || !Number.isSafeInteger(idReporte) || idReporte <= 0) {
            setError(t("No puedes abrir este reporte."));
            return;
        }
        aperturaEnCurso.current = true;
        setAbriendoAviso(aviso.id);
        setError('');
        const controlador = new AbortController();
        consultaChat.current = controlador;
        try {
            const respuesta = await fetch(`/api/v1/admin/avisos/reportes/${idReporte}`, {
                credentials: 'same-origin', cache: 'no-store', signal: controlador.signal,
            });
            if (!respuesta.ok) {
                if (respuesta.status === 401)
                    sesionTerminada.current = true;
                throw new Error(await leerError(respuesta, t("No pudimos abrir el reporte.")));
            }
            const datos = await respuesta.json();
            if (!Array.isArray(datos.contenido) || Number(datos.contenido[0]?.id) !== idReporte) {
                throw new Error(t("El reporte recibido no corresponde a esta notificaci\u00F3n."));
            }
            if (!vigente.current)
                return;
            if (!aviso.leida && !(await marcar(aviso.id)))
                return;
            if (!vigente.current)
                return;
            setAbierta(false);
            window.dispatchEvent(new CustomEvent('stayhub:abrir-reporte', { detail: { idReporte } }));
        }
        catch (excepcion) {
            if (excepcion.name !== 'AbortError' && vigente.current)
                setError(excepcion.message);
        }
        finally {
            aperturaEnCurso.current = false;
            if (vigente.current)
                setAbriendoAviso(null);
        }
    }
    function alternar() {
        if (!abierta)
            cargar();
        setAbierta(!abierta);
    }
    return (<div className="stayhub-avisos">
      <button ref={boton} type="button" className="stayhub-avisos-boton" aria-label={t(t("Notificaciones{0}", sinLeer ? t(": {0} sin leer", sinLeer) : ''))} title={t("Notificaciones")} aria-expanded={abierta} aria-controls={abierta ? id : undefined} onClick={alternar}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4M12 2V1"/>
        </svg>
        {sinLeer > 0 && <span className="stayhub-avisos-contador" aria-hidden="true">
          {sinLeer > 99 ? '99+' : sinLeer}
        </span>}
      </button>
      {abierta && createPortal(<section ref={panel} id={id} className="stayhub-avisos-panel" tabIndex={-1} aria-labelledby={`${id}-titulo`} style={{ ...posicion, maxHeight: `calc(100dvh - ${posicion.top + 16}px)` }}>
          <div className="stayhub-avisos-cabecera">
            <div>
              <h2 id={`${id}-titulo`}>{t("Notificaciones")}</h2>
              <p>{sinLeer === 0 ? t("Est\u00E1s al d\u00EDa") : t("{0} sin leer", sinLeer)}</p>
            </div>
            <button type="button" className="stayhub-avisos-cerrar" aria-label={t("Cerrar notificaciones")} onClick={() => { setAbierta(false); boton.current?.focus(); }}>×</button>
          </div>
          {sinLeer > 0 && <div className="stayhub-avisos-herramientas">
            <button type="button" disabled={guardando || abriendoAviso !== null || cargando || sesionTerminada.current} onClick={() => marcar(null)}>{t("Marcar todas como le\u00EDdas")}</button>
          </div>}
          <div className="stayhub-avisos-lista" aria-busy={cargando || guardando}>
            {error && <div className="stayhub-avisos-error" role="alert">
              <p>{t(error)}</p>
              <button type="button" disabled={guardando} onClick={() => {
                    sesionTerminada.current = false;
                    setCargando(true);
                    cargar();
                }}>{t("Reintentar")}</button>
            </div>}
            {cargando && <p className="stayhub-avisos-vacio" role="status">{t("Cargando notificaciones\u2026")}</p>}
            {!cargando && !error && avisos.length === 0 && <p className="stayhub-avisos-vacio">{t("Todav\u00EDa no tienes notificaciones. Aqu\u00ED aparecer\u00E1n los avisos de tus reservas, mensajes y reportes.")}</p>}
            {avisos.length > 0 && <ul>
              {avisos.map((aviso) => <li key={aviso.id} className={aviso.leida ? '' : 'stayhub-aviso-pendiente'}>
                <div className="stayhub-aviso-titulo">
                  <h3>{textoNotificacion(aviso, 'titulo')}</h3>
                  {!aviso.leida && <span className="stayhub-aviso-nuevo">{t("Sin leer")}</span>}
                </div>
                <p>{textoNotificacion(aviso, 'mensaje')}</p>
                <time dateTime={aviso.creadaEn}>{fechaAviso(aviso.creadaEn)}</time>
                <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
                  {aviso.entidad === 'RESERVA' && aviso.entidadId != null && (<button type="button" disabled={guardando || abriendoAviso !== null || sesionTerminada.current} onClick={() => abrirAviso(aviso)}>
                      {abriendoAviso === aviso.id ? t("Abriendo\u2026") : aviso.tipo === 'MENSAJE_CHAT' ? t("Abrir chat") : t("Ver reserva")}
                    </button>)}
                  {aviso.entidad === 'REPORTE_RESENA' && aviso.tipo === 'REPORTE_RESENA_NUEVO'
                        && usuario?.rol === 'ADMINISTRADOR' && aviso.entidadId != null && (<button type="button" disabled={guardando || abriendoAviso !== null || sesionTerminada.current} onClick={() => abrirAviso(aviso)}>
                        {abriendoAviso === aviso.id ? t("Abriendo\u2026") : t("Revisar reporte")}
                      </button>)}
                  {!aviso.leida && <button type="button" disabled={guardando || abriendoAviso !== null || sesionTerminada.current} onClick={() => marcar(aviso.id)}>{t("Marcar como le\u00EDda")}</button>}
                </div>
              </li>)}
            </ul>}
          </div>
          <p className="stayhub-avisos-pie">{t("Se muestran los 50 avisos m\u00E1s recientes.")}</p>
        </section>, document.body)}
      {reservaAbierta && createPortal(<DetalleReservaAviso key={reservaAbierta.idReserva} reserva={reservaAbierta} onCerrar={() => {
                setReservaAbierta(null);
                boton.current?.focus();
            }}/>, document.body)}
      {chatAbierto && createPortal(<ChatReserva key={chatAbierto.idReserva} reserva={chatAbierto} onCerrar={() => {
                setChatAbierto(null);
                boton.current?.focus();
            }}/>, document.body)}
    </div>);
}
