import { t, useIdioma, localeActual } from '../idiomas'
import { useEffect, useId, useRef, useState } from 'react';
import { enviarDatos, leerError } from '../api';
import CrearAdministrador from './CrearAdministrador';
import './panel-administrador.css';
const SECCIONES = [
    ['resumen', 'Resumen'], ['usuarios', 'Usuarios'], ['alojamientos', 'Alojamientos'],
    ['reportes', 'Reportes de reseñas'], ['auditoria', 'Auditoría'],
];
const FILTROS = {
    usuarios: ['ACTIVA', 'INACTIVA', 'RESTRINGIDA'],
    alojamientos: ['BORRADOR', 'PENDIENTE_REVISION', 'ACTIVA', 'PAUSADA', 'BLOQUEADA'],
    reportes: ['PENDIENTES', 'ATENDIDOS'],
};
function etiqueta(texto) {
    return String(texto || '').replaceAll('_', ' ').toLowerCase();
}
function fecha(valor) {
    if (!valor)
        return t("Sin registro");
    const d = new Date(valor);
    return Number.isNaN(d.getTime()) ? String(valor) : d.toLocaleString(localeActual());
}
function moneda(valor) {
    return new Intl.NumberFormat(localeActual(), { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(Number(valor));
}
export default function PanelAdministrador({ usuario, onVerAlojamiento, reporteSolicitado }) {
    useIdioma();
    const [seccion, setSeccion] = useState(reporteSolicitado ? 'reportes' : 'resumen');
    const [idReporteAviso, setIdReporteAviso] = useState(reporteSolicitado?.id || null);
    const [busqueda, setBusqueda] = useState('');
    const [q, setQ] = useState('');
    const [estado, setEstado] = useState('');
    const [pagina, setPagina] = useState(0);
    const [resumen, setResumen] = useState(null);
    const [datos, setDatos] = useState({ contenido: [], total: 0, pagina: 0, tamano: 20 });
    const [cargando, setCargando] = useState(true);
    const [error, setError] = useState('');
    const [mensaje, setMensaje] = useState('');
    const [revision, setRevision] = useState(0);
    const [accion, setAccion] = useState(null);
    const [creandoAdmin, setCreandoAdmin] = useState(false);
    useEffect(() => {
        if (usuario?.rol !== 'ADMINISTRADOR')
            return;
        const controlador = new AbortController();
        let vigente = true;
        async function cargar() {
            setCargando(true);
            setError('');
            try {
                const opciones = { credentials: 'same-origin', cache: 'no-store', signal: controlador.signal };
                const consulta = new URLSearchParams({ q, estado, pagina: String(pagina) });
                const rutas = ['/api/v1/admin/resumen'];
                if (seccion !== 'resumen')
                    rutas.push(seccion === 'reportes' && idReporteAviso
                        ? `/api/v1/admin/avisos/reportes/${idReporteAviso}`
                        : `/api/v1/admin/${seccion}?${consulta}`);
                const respuestas = await Promise.all(rutas.map((ruta) => fetch(ruta, opciones)));
                const fallida = respuestas.find((respuesta) => !respuesta.ok);
                if (fallida)
                    throw new Error(await leerError(fallida, t("No se pudo cargar el panel de administraci\u00F3n.")));
                const recibidos = await Promise.all(respuestas.map((respuesta) => respuesta.json()));
                if (!vigente)
                    return;
                setResumen(recibidos[0]);
                if (recibidos[1])
                    setDatos(recibidos[1]);
            }
            catch (excepcion) {
                if (vigente && excepcion.name !== 'AbortError')
                    setError(excepcion.message || t("No se pudo conectar con el servidor."));
            }
            finally {
                if (vigente)
                    setCargando(false);
            }
        }
        cargar();
        return () => { vigente = false; controlador.abort(); };
    }, [usuario?.rol, seccion, q, estado, pagina, revision, idReporteAviso]);
    if (usuario?.rol !== 'ADMINISTRADOR') {
        return <section className="contenedor"><p role="alert">{t("No tienes acceso al panel de administrador.")}</p></section>;
    }
    function abrirSeccion(id) {
        setIdReporteAviso(null);
        setSeccion(id);
        setPagina(0);
        setBusqueda('');
        setQ('');
        setEstado('');
        setMensaje('');
    }
    function proponer(tipo, registro, destino, titulo) {
        setMensaje('');
        setAccion({ tipo, registro, destino, titulo });
    }
    function guardada() {
        setAccion(null);
        setMensaje(t("Cambio guardado. La acci\u00F3n qued\u00F3 registrada en auditor\u00EDa."));
        setRevision((n) => n + 1);
    }
    return (<section className="contenedor admin-panel">
      <div className="admin-panel-cabecera">
        <div>
          <p className="admin-panel-etiqueta">{t("Administraci\u00F3n de StayHub")}</p>
          <h1 className="titulo-serif">{t("Panel de administrador")}</h1>
          <p className="texto-suave">{t("Gestiona las cuentas, revisa los alojamientos y atiende los reportes.")}</p>
        </div>
        <button type="button" className="boton-secundario" disabled={cargando} onClick={() => setRevision((n) => n + 1)}>{t("Actualizar")}</button>
      </div>
      <nav className="admin-panel-pestanas" aria-label={t("Secciones de administraci\u00F3n")}>
        {SECCIONES.map(([id, texto]) => (<button key={id} type="button" aria-current={seccion === id ? 'page' : undefined} className={seccion === id ? 'activa' : ''} onClick={() => abrirSeccion(id)}>{t(texto)}</button>))}
      </nav>
      {mensaje && <p className="aviso" role="status">{t(mensaje)}</p>}
      {error && <div className="aviso aviso-error" role="alert">
        {t(error)}{' '}<button type="button" className="boton-enlace" onClick={() => setRevision((n) => n + 1)}>{t("Reintentar")}</button>
      </div>}

      {seccion === 'reportes' && idReporteAviso && (<div className="aviso" role="status">{t("Mostrando el reporte #")}{idReporteAviso}{t(" de tu notificaci\u00F3n.")}{' '}
          <button type="button" className="boton-enlace" onClick={() => abrirSeccion('reportes')}>{t("Ver todos los reportes")}</button>
        </div>)}

      {seccion === 'usuarios' && (<div className="admin-panel-acciones">
          <button type="button" className="boton-principal" onClick={() => setCreandoAdmin(true)}>{t("Crear administrador")}</button>
        </div>)}

      {seccion !== 'resumen' && (<form className="admin-panel-filtros" onSubmit={(evento) => {
                evento.preventDefault();
                setIdReporteAviso(null);
                setPagina(0);
                setQ(busqueda.trim());
            }}>
          <label>{t("Buscar")}<input value={busqueda} maxLength={100} onChange={(evento) => setBusqueda(evento.target.value)} placeholder={t(seccion === 'usuarios' ? t("Nombre o correo") : seccion === 'alojamientos' ? t("T\u00EDtulo, ciudad o correo del anfitri\u00F3n") : t("Texto del reporte o acci\u00F3n"))}/>
          </label>
          {FILTROS[seccion] && <label>{t("Estado")}<select value={estado} onChange={(evento) => { setIdReporteAviso(null); setEstado(evento.target.value); setPagina(0); }}>
              <option value="">{t("Todos")}</option>
              {FILTROS[seccion].map((valor) => <option key={valor} value={valor}>{t(etiqueta(valor))}</option>)}
            </select>
          </label>}
          <button type="submit" className="boton-principal">{t("Buscar")}</button>
        </form>)}

      {cargando ? <p className="cargando" role="status">{t("Cargando administraci\u00F3n...")}</p> : !error && (seccion === 'resumen' ? (<>
            <div className="admin-panel-resumen">
              {[
                [t("Usuarios"), resumen?.usuarios],
                [t("Cuentas no activas"), resumen?.usuariosNoActivos],
                [t("Alojamientos"), resumen?.alojamientos],
                [t("Publicados"), resumen?.alojamientosActivos],
                [t("Bloqueados"), resumen?.alojamientosBloqueados],
                [t("Pendientes de revisi\u00F3n"), resumen?.pendientesRevision],
                [t("Reportes pendientes"), resumen?.reportesPendientes],
            ].map(([nombre, total]) => <article className="tarjeta" key={nombre}>
                <span>{t(nombre)}</span><strong>{total ?? 0}</strong>
              </article>)}
            </div>
            <article className="tarjeta admin-panel-ayuda">
              <h2>{t("Acciones de administraci\u00F3n")}</h2>
              <p>{t("Restringe o reactiva cuentas, bloquea alojamientos y revisa las rese\u00F1as reportadas. Cada cambio requiere un motivo y queda registrado.")}</p>
              <p>{t("Cuando se restringe o inactiva un anfitri\u00F3n, sus alojamientos publicados pasan a pausa. Reactivar la cuenta no vuelve a publicar sus alojamientos autom\u00E1ticamente.")}</p>
            </article>
          </>) : (<>
            <p className="texto-suave">{datos.total}{t(" registros encontrados.")}</p>
            {!datos.contenido.length ? <div className="tarjeta"><p>{t("No hay registros con estos filtros.")}</p></div> : (<ul className="admin-panel-lista">
                {datos.contenido.map((registro) => (<li className="tarjeta admin-panel-registro" key={registro.id}>
                    {seccion === 'usuarios' && <>
                      <div className="admin-panel-titulo">
                        <h2>{registro.nombre}</h2><span>{t(etiqueta(registro.estado))}</span>
                      </div>
                      <p>{registro.email}</p>
                      <p className="texto-suave">ID {registro.id} · {t(etiqueta(registro.rol))}{t(" \u00B7 Registro: ")}{fecha(registro.creadoEn)}</p>
                      {registro.motivo && <p>{t("Motivo: ")}{registro.motivo}</p>}
                      {registro.rol === 'ADMINISTRADOR' ? <p className="texto-suave">{t("Cuenta administrativa protegida.")}</p> : (<div className="admin-panel-acciones">
                          {registro.estado !== 'ACTIVA' && <button type="button" className="boton-secundario" onClick={() => proponer('usuarios', registro, 'ACTIVA', 'Reactivar cuenta')}>{t("Reactivar")}</button>}
                          {registro.estado !== 'RESTRINGIDA' && <button type="button" className="boton-peligro" onClick={() => proponer('usuarios', registro, 'RESTRINGIDA', 'Restringir cuenta')}>{t("Restringir")}</button>}
                          {registro.estado !== 'INACTIVA' && <button type="button" className="boton-secundario" onClick={() => proponer('usuarios', registro, 'INACTIVA', 'Inactivar cuenta')}>{t("Inactivar")}</button>}
                        </div>)}
                    </>}
                    {seccion === 'alojamientos' && <>
                      <div className="admin-panel-titulo">
                        <h2>{registro.titulo}</h2><span>{t(etiqueta(registro.estado))}</span>
                      </div>
                      <p>{registro.ciudad} · {moneda(registro.precioNoche)}{t(" por noche")}</p>
                      <p className="texto-suave">ID {registro.id} · {registro.anfitrion} · {registro.emailAnfitrion}</p>
                      {registro.motivo && <p>{t("Motivo: ")}{registro.motivo}</p>}
                      <div className="admin-panel-acciones">
                        <button type="button" className="boton-secundario" onClick={() => onVerAlojamiento(registro.id)}>{t("Ver alojamiento")}</button>
                        {registro.estado === 'PENDIENTE_REVISION' && <button type="button" className="boton-principal" onClick={() => proponer('alojamientos', registro, 'ACTIVA', 'Aprobar publicación')}>{t("Aprobar publicaci\u00F3n")}</button>}
                        {registro.estado === 'BLOQUEADA' ? <button type="button" className="boton-secundario" onClick={() => proponer('alojamientos', registro, 'PAUSADA', 'Desbloquear alojamiento')}>{t("Desbloquear y dejar en pausa")}</button> :
                            <button type="button" className="boton-peligro" onClick={() => proponer('alojamientos', registro, 'BLOQUEADA', 'Bloquear alojamiento')}>{t("Bloquear")}</button>}
                      </div>
                    </>}
                    {seccion === 'reportes' && <>
                      <div className="admin-panel-titulo">
                        <h2>{t("Reporte #")}{registro.id} · {registro.alojamiento}</h2>
                        <span>{registro.atendido ? t("Atendido") : t("Pendiente")}</span>
                      </div>
                      <p>{t("Reportado por ")}{registro.reportante} · {fecha(registro.fecha)}</p>
                      <p><strong>{t("Motivo del reporte:")}</strong> {registro.motivo}</p>
                      <blockquote>{registro.comentario}</blockquote>
                      <p className="texto-suave">{t("Autor: ")}{registro.autor} · {registro.calificacion}{t("/5 \u00B7 Rese\u00F1a ")}{registro.visible ? 'visible' : 'oculta'}</p>
                      {registro.motivoOcultamiento && <p>{t("Motivo de ocultamiento: ")}{registro.motivoOcultamiento}</p>}
                      {!registro.atendido && <div className="admin-panel-acciones">
                        <button type="button" className="boton-peligro" onClick={() => proponer('reportes', registro, 'OCULTAR', 'Ocultar reseña y atender reporte')}>{t("Ocultar rese\u00F1a")}</button>
                        <button type="button" className="boton-secundario" onClick={() => proponer('reportes', registro, 'DESCARTAR', 'Descartar reporte')}>{t("Descartar reporte")}</button>
                      </div>}
                    </>}
                    {seccion === 'auditoria' && <>
                      <div className="admin-panel-titulo"><h2>{t(etiqueta(registro.accion))}</h2><span>{registro.resultado}</span></div>
                      <p>{registro.administrador || t("Sin usuario")} · {fecha(registro.fecha)}</p>
                      <p className="texto-suave">{registro.entidad} #{registro.entidadId}</p>
                      <p>{registro.detalle}</p>
                    </>}
                  </li>))}
              </ul>)}
            <div className="admin-panel-paginacion">
              <button type="button" className="boton-secundario" disabled={pagina === 0} onClick={() => setPagina((n) => n - 1)}>{t("Anterior")}</button>
              <span>{t("P\u00E1gina ")}{pagina + 1}{t(" de ")}{Math.max(1, Math.ceil(datos.total / datos.tamano))}</span>
              <button type="button" className="boton-secundario" disabled={(pagina + 1) * datos.tamano >= datos.total} onClick={() => setPagina((n) => n + 1)}>{t("Siguiente")}</button>
            </div>
          </>))}
      {creandoAdmin && <CrearAdministrador onCerrar={() => setCreandoAdmin(false)} onCreado={(cuenta) => {
                setCreandoAdmin(false);
                setPagina(0);
                setQ('');
                setBusqueda('');
                setEstado('');
                setMensaje(`Administrador ${cuenta.nombre} creado. Puede iniciar sesión con su correo y contraseña.`);
                setRevision((n) => n + 1);
            }}/>}
      {accion && <ConfirmarAccionAdmin key={`${accion.tipo}-${accion.registro.id}-${accion.destino}`} accion={accion} onCerrar={() => setAccion(null)} onGuardada={guardada}/>}
    </section>);
}
function ConfirmarAccionAdmin({ accion, onCerrar, onGuardada }) {
    useIdioma();
    const tituloId = useId();
    const ventana = useRef(null);
    const envioEnCurso = useRef(false);
    const vigente = useRef(false);
    const [motivo, setMotivo] = useState('');
    const [guardando, setGuardando] = useState(false);
    const [error, setError] = useState('');
    useEffect(() => {
        vigente.current = true;
        const dialogo = ventana.current;
        dialogo?.showModal();
        return () => { vigente.current = false; dialogo?.close(); };
    }, []);
    async function confirmar(evento) {
        evento.preventDefault();
        if (envioEnCurso.current)
            return;
        const texto = motivo.trim();
        if (texto.length < 10) {
            setError(t("Escribe un motivo de al menos 10 caracteres."));
            return;
        }
        envioEnCurso.current = true;
        setGuardando(true);
        setError('');
        try {
            const reporte = accion.tipo === 'reportes';
            const datos = reporte ? {
                decision: accion.destino, motivo: texto, visibleActual: Boolean(accion.registro.visible),
            } : { estado: accion.destino, motivo: texto, estadoActual: accion.registro.estado };
            const ruta = `/api/v1/admin/${accion.tipo}/${accion.registro.id}/${reporte ? 'resolver' : 'estado'}`;
            const respuesta = await enviarDatos(ruta, datos, 'PATCH');
            if (!respuesta.ok)
                throw new Error(await leerError(respuesta, t("No se pudo guardar el cambio.")));
            if (vigente.current)
                onGuardada();
        }
        catch (excepcion) {
            if (vigente.current)
                setError(excepcion.message || t("No se pudo conectar con el servidor."));
        }
        finally {
            envioEnCurso.current = false;
            if (vigente.current)
                setGuardando(false);
        }
    }
    return (<dialog className="admin-panel-modal" ref={ventana} aria-labelledby={tituloId} onCancel={(evento) => { if (envioEnCurso.current)
        evento.preventDefault();
    else {
        evento.preventDefault();
        onCerrar();
    } }}>
      <form onSubmit={confirmar}>
        <h2 id={tituloId}>{t(accion.titulo)}</h2>
        <p>{accion.registro.nombre || accion.registro.titulo || accion.registro.alojamiento}{t(" \u00B7 ID ")}{accion.registro.id}</p>
        {accion.tipo === 'usuarios' && accion.destino !== 'ACTIVA' && <p className="admin-panel-nota">{t("Se cerrar\u00E1 el acceso de la cuenta en su pr\u00F3xima petici\u00F3n. Si es anfitri\u00F3n, sus publicaciones activas o pendientes pasar\u00E1n a pausa. Las reservas existentes se conservan.")}</p>}
        {accion.destino === 'PAUSADA' && <p>{t("El alojamiento quedar\u00E1 en pausa. El anfitri\u00F3n podr\u00E1 revisar sus datos antes de publicarlo.")}</p>}
        {accion.destino === 'DESCARTAR' && <p>{t("Se atender\u00E1 el reporte y se conservar\u00E1 la visibilidad actual de la rese\u00F1a.")}</p>}
        <label>{t("Motivo de la decisi\u00F3n")}<textarea value={motivo} maxLength={500} minLength={10} required rows={4} disabled={guardando} onChange={(evento) => { setMotivo(evento.target.value); setError(''); }}/>
        </label>
        {error && <p className="aviso aviso-error" role="alert">{t(error)}</p>}
        <div className="admin-panel-acciones">
          <button type="submit" className="boton-principal" disabled={guardando || motivo.trim().length < 10}>
            {guardando ? t("Guardando...") : t("Confirmar cambio")}
          </button>
          <button type="button" className="boton-secundario" disabled={guardando} onClick={onCerrar}>{t("Cancelar")}</button>
        </div>
      </form>
    </dialog>);
}
