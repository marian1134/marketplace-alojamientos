import { t, useIdioma } from './idiomas'
import { useEffect, useRef, useState } from 'react';
import RegistroUsuario from './components/RegistroUsuario';
import InicioSesion from './components/InicioSesion';
import NuevaClave from './components/NuevaClave';
import Alojamientos from './components/Alojamientos';
import Portada from './components/Portada';
import Encabezado from './components/Encabezado';
import DetalleAlojamiento from './components/DetalleAlojamiento';
import Reservar from './components/Reservar';
import MisViajes from './components/MisViajes';
import PanelAnfitrion from './components/PanelAnfitrion';
import PanelAdministrador from './components/PanelAdministrador';
import PanelHuesped from './components/PanelHuesped';
import ResultadosBusqueda from './components/ResultadosBusqueda';
import MisFavoritos from './components/MisFavoritos';
import CalendarioAnfitrion from './components/CalendarioAnfitrion';
import RedDeSeguridad from './components/RedDeSeguridad';
import { consultar, enviarDatos } from './api';
import './App.css';
import './reservas.css';
// Pantallas que solo ve un usuario con sesión, con la barra superior
const PANTALLAS_INTERNAS = [
    'perfil',
    'resultados',
    'detalle',
    'reservar',
    'viajes',
    'panel',
    'alojamientos',
    'favoritos',
    'calendario',
    'administracion',
];
function App() {
    useIdioma();
    const [pantalla, setPantalla] = useState('portada');
    const [reporteSolicitado, setReporteSolicitado] = useState(null);
    const [usuario, setUsuario] = useState(null);
    // El soporte se monta en main.jsx; solo le avisamos que debe revisar su sesion.
    useEffect(() => {
        window.dispatchEvent(new CustomEvent('stayhub:sesion', { detail: usuario?.idUsuario ?? null }));
    }, [usuario?.idUsuario]);
    const [cargando, setCargando] = useState(true);
    const [cerrando, setCerrando] = useState(false);
    const [mensajeSesion, setMensajeSesion] = useState('');
    const historialPantallas = useRef([]);
    // Alojamiento elegido, búsqueda de la portada y reserva en curso
    const [idAlojamiento, setIdAlojamiento] = useState(null);
    const [busqueda, setBusqueda] = useState(null);
    const [solicitudReserva, setSolicitudReserva] = useState(null);
    // Ids de los alojamientos guardados con el corazón
    const [favoritos, setFavoritos] = useState(() => new Set());
    // Alojamiento que quiso ver antes de iniciar sesión
    const [pendiente, setPendiente] = useState(null);
    const [token, setToken] = useState(() => new URLSearchParams(window.location.search).get('token'));
    // Pantalla pedida desde el botón de un correo (?ir=viajes o ?ir=panel)
    const [irA, setIrA] = useState(() => {
        const destino = new URLSearchParams(window.location.search).get('ir');
        return ['viajes', 'panel'].includes(destino) ? destino : null;
    });
    const esRecuperacion = token !== null;
    const esLogin = pantalla === 'login';
    useEffect(() => {
        let activo = true;
        async function consultarSesion() {
            try {
                const respuesta = await fetch('/api/usuarios/perfil', {
                    credentials: 'same-origin',
                    cache: 'no-store',
                });
                if (respuesta.status === 401) {
                    if (activo) {
                        setUsuario(null);
                    }
                    return;
                }
                if (!respuesta.ok) {
                    throw new Error(t("No se pudo consultar la sesi\u00F3n"));
                }
                const datos = await respuesta.json();
                if (activo) {
                    setUsuario(datos);
                }
            }
            catch {
                if (activo) {
                    setMensajeSesion(t("No se pudo comprobar la sesi\u00F3n. Revisa la conexi\u00F3n con el servidor y recarga la p\u00E1gina."));
                }
            }
            finally {
                if (activo) {
                    setCargando(false);
                }
            }
        }
        consultarSesion();
        return () => {
            activo = false;
        };
    }, []);
    // Si llegó desde un correo: con sesión va directo a la pantalla;
    // sin sesión, primero inicia sesión y después se lleva allá.
    useEffect(() => {
        if (cargando || !irA) {
            return;
        }
        const direccion = new URL(window.location.href);
        if (direccion.searchParams.has('ir')) {
            direccion.searchParams.delete('ir');
            window.history.replaceState(null, '', direccion.pathname + direccion.search + direccion.hash);
        }
        if (usuario) {
            setPantalla(irA);
            setIrA(null);
        }
        else {
            setPantalla('login');
        }
    }, [cargando, usuario, irA]);
    // Cuando hay sesión se cargan los favoritos del usuario
    useEffect(() => {
        if (!usuario) {
            return;
        }
        let activo = true;
        consultar('/api/v1/favoritos/ids')
            .then((respuesta) => (respuesta.ok ? respuesta.json() : []))
            .then((ids) => {
            if (activo) {
                setFavoritos(new Set(ids));
            }
        })
            .catch(() => { });
        return () => {
            activo = false;
        };
    }, [usuario]);
    // Agrega o quita un favorito (se pinta de una vez y luego se guarda)
    async function cambiarFavorito(idAlojamiento) {
        const yaEsta = favoritos.has(idAlojamiento);
        const nuevos = new Set(favoritos);
        if (yaEsta) {
            nuevos.delete(idAlojamiento);
        }
        else {
            nuevos.add(idAlojamiento);
        }
        setFavoritos(nuevos);
        try {
            const respuesta = await enviarDatos(`/api/v1/favoritos/${idAlojamiento}`, {}, yaEsta ? 'DELETE' : 'POST');
            if (!respuesta.ok) {
                throw new Error(t("No se pudo guardar el favorito"));
            }
        }
        catch {
            setFavoritos(favoritos);
        }
    }
    function navegar(destino) {
        setReporteSolicitado(null);
        setMensajeSesion('');
        if (destino !== pantalla) {
            historialPantallas.current.push(pantalla);
        }
        setPantalla(destino);
        window.scrollTo({ top: 0 });
    }
    useEffect(() => {
        function abrirReporteDesdeAviso(evento) {
            const id = Number(evento.detail?.idReporte);
            if (usuario?.rol !== 'ADMINISTRADOR' || !Number.isSafeInteger(id) || id <= 0)
                return;
            setReporteSolicitado((anterior) => ({ id, revision: (anterior?.revision || 0) + 1 }));
            setMensajeSesion('');
            if (pantalla !== 'administracion')
                historialPantallas.current.push(pantalla);
            setPantalla('administracion');
            window.scrollTo({ top: 0 });
        }
        window.addEventListener('stayhub:abrir-reporte', abrirReporteDesdeAviso);
        return () => window.removeEventListener('stayhub:abrir-reporte', abrirReporteDesdeAviso);
    }, [usuario?.rol, pantalla]);
    function volverPantallaAnterior() {
        const anterior = historialPantallas.current.pop() || 'portada';
        setMensajeSesion('');
        setPantalla(anterior);
        window.scrollTo({ top: 0 });
    }
    // Después de iniciar sesión o registrarse: a buscar destino
    function recibirSesion(datos) {
        setUsuario(datos);
        setMensajeSesion('');
        if (pendiente) {
            setIdAlojamiento(pendiente);
            setPendiente(null);
            navegar('detalle');
            return;
        }
        navegar(datos.rol === 'ADMINISTRADOR' ? 'administracion' : datos.rol === 'ANFITRION' ? 'panel' : 'portada');
    }
    async function cerrarSesion() {
        setCerrando(true);
        setMensajeSesion('');
        try {
            const respuesta = await enviarDatos('/api/usuarios/logout', {});
            if (!respuesta.ok) {
                throw new Error(t("No se pudo cerrar la sesi\u00F3n"));
            }
            setUsuario(null);
            setFavoritos(new Set());
            setSolicitudReserva(null);
            navegar('portada');
        }
        catch {
            setMensajeSesion(t("No se pudo cerrar la sesi\u00F3n. Intenta nuevamente."));
        }
        finally {
            setCerrando(false);
        }
    }
    function volverAlInicio() {
        const direccion = new URL(window.location.href);
        direccion.searchParams.delete('token');
        window.history.replaceState(null, '', direccion.pathname + direccion.search + direccion.hash);
        setToken(null);
        setPantalla('login');
    }
    // "Buscar" abre la pantalla de resultados
    function buscar(datosBusqueda) {
        setBusqueda(datosBusqueda);
        navegar('resultados');
    }
    function verAlojamiento(id, datosBusqueda) {
        setIdAlojamiento(id);
        if (datosBusqueda !== undefined) {
            setBusqueda(datosBusqueda);
        }
        navegar('detalle');
    }
    function pedirCuenta(destino, idDeseado) {
        setPendiente(idDeseado ?? null);
        navegar(destino);
    }
    if (!esRecuperacion && cargando) {
        return (<p className="cargando" role="status">{t("Comprobando sesi\u00F3n...")}</p>);
    }
    if (!esRecuperacion && pantalla === 'portada') {
        return (<Portada usuario={usuario} onIniciarSesion={(id) => pedirCuenta('login', id)} onRegistrarse={(id) => pedirCuenta('registro', id)} onNavegar={navegar} onCerrarSesion={cerrarSesion} onVerAlojamiento={verAlojamiento} onBuscar={buscar} favoritos={favoritos} onFavorito={cambiarFavorito}/>);
    }
    if (!esRecuperacion && PANTALLAS_INTERNAS.includes(pantalla)) {
        if (!usuario) {
            return (<Portada usuario={null} onIniciarSesion={(id) => pedirCuenta('login', id)} onRegistrarse={(id) => pedirCuenta('registro', id)} onNavegar={navegar} onCerrarSesion={cerrarSesion} onVerAlojamiento={verAlojamiento} onBuscar={buscar} favoritos={favoritos} onFavorito={cambiarFavorito}/>);
        }
        return (<div className="pagina-interna">
        <Encabezado usuario={usuario} pantalla={pantalla} onNavegar={navegar} onCerrarSesion={cerrarSesion}/>

        <main>
          {/* La reserva tiene su propio "Volver" (regresa paso por paso) */}
          {pantalla !== 'reservar' && (<div className="navegacion-interna">
            <button type="button" className="boton-volver-pantalla" onClick={volverPantallaAnterior} aria-label={t("Volver a la pantalla anterior")}>
              <span aria-hidden="true">←</span>{t("Volver")}</button>
          </div>)}

          <RedDeSeguridad key={pantalla} onVolver={() => navegar('portada')}>
          {pantalla === 'administracion' && (<PanelAdministrador key={reporteSolicitado?.revision || 0} reporteSolicitado={reporteSolicitado} usuario={usuario} onVerAlojamiento={(id) => verAlojamiento(id, null)}/>)}

          {pantalla === 'perfil' && (<PanelHuesped usuario={usuario} cantidadFavoritos={favoritos.size} onExplorar={() => navegar('portada')} onViajes={() => navegar('viajes')} onFavoritos={() => navegar('favoritos')} onPanelAnfitrion={() => navegar('panel')} onPanelAdministrador={() => navegar('administracion')} onConvertirse={() => window.alert(t('En el siguiente paso conectaremos esta opción para activar el perfil de anfitrión con la misma cuenta.'))} onCerrarSesion={cerrarSesion} onUsuarioActualizado={setUsuario} cerrando={cerrando}/>)}

          {pantalla === 'resultados' && busqueda && (<ResultadosBusqueda key={JSON.stringify(busqueda)} busqueda={busqueda} onBuscar={buscar} onVerAlojamiento={(id) => verAlojamiento(id)} favoritos={favoritos} onFavorito={cambiarFavorito}/>)}

          {pantalla === 'detalle' && (<DetalleAlojamiento key={idAlojamiento} idAlojamiento={idAlojamiento} busqueda={busqueda} favoritos={favoritos} onFavorito={cambiarFavorito} onReservar={(datos) => {
                    setSolicitudReserva(datos);
                    setBusqueda({
                        entrada: datos.entrada,
                        salida: datos.salida,
                        huespedes: datos.huespedes,
                    });
                    navegar('reservar');
                }}/>)}

          {pantalla === 'reservar' && solicitudReserva && (<Reservar reserva={solicitudReserva} onVolver={() => navegar('detalle')} onVerViajes={() => {
                    setSolicitudReserva(null);
                    navegar('viajes');
                }} onExplorar={() => {
                    setSolicitudReserva(null);
                    setBusqueda(null);
                    navegar('portada');
                }}/>)}

          {pantalla === 'viajes' && (<MisViajes onExplorar={() => navegar('portada')} onVerAlojamiento={(id) => verAlojamiento(id, null)}/>)}

          {pantalla === 'panel' && (<PanelAnfitrion usuario={usuario} onGestionarAlojamientos={() => navegar('alojamientos')} onCalendario={() => navegar('calendario')}/>)}

          {pantalla === 'favoritos' && (<MisFavoritos favoritos={favoritos} onFavorito={cambiarFavorito} onExplorar={() => navegar('portada')} onVerAlojamiento={(id) => verAlojamiento(id, null)}/>)}

          {pantalla === 'calendario' && (<CalendarioAnfitrion onGestionarAlojamientos={() => navegar('alojamientos')}/>)}

          {pantalla === 'alojamientos' && (<section className="contenedor">
              <Alojamientos onVolver={() => navegar('panel')}/>
            </section>)}
          </RedDeSeguridad>
        </main>
      </div>);
    }
    let titulo = t("Crea tu cuenta");
    if (esRecuperacion) {
        titulo = t("Recupera tu cuenta");
    }
    else if (usuario) {
        titulo = t("Bienvenido a StayHub");
    }
    else if (esLogin) {
        titulo = t("Bienvenido de nuevo");
    }
    return (<main className="registro-pagina">
      <aside className="registro-imagen">
        <button type="button" className="registro-marca boton-marca" onClick={() => navegar('portada')} aria-label={t("StayHub, ir a la portada")}>{t("\u2190 StayHub")}</button>

        <div className="registro-bienvenida">
          <h2>{titulo}</h2>

          <p>{t("Encuentra tu pr\u00F3ximo destino o comparte tu alojamiento.")}</p>
        </div>
      </aside>

      <section>
        {esRecuperacion ? (<NuevaClave token={token} onVolver={volverAlInicio}/>) : usuario ? (<section>
            <h1>{t("Hola, ")}{usuario.nombre}</h1>

            <p>{t("Tu sesi\u00F3n est\u00E1 iniciada en StayHub.")}</p>

            <dl className="perfil-datos">
              <dt>{t("Nombre")}</dt>
              <dd>{usuario.nombre}</dd>

              <dt>{t("Correo electr\u00F3nico")}</dt>
              <dd>{usuario.correo}</dd>

              <dt>{t("Tipo de cuenta")}</dt>
              <dd>
                {usuario.rol === 'ADMINISTRADOR' ? t("Administrador") : usuario.rol === 'ANFITRION' ? t("Anfitri\u00F3n") : t("Hu\u00E9sped")}
              </dd>

              <dt>{t("Tel\u00E9fono")}</dt>
              <dd>{usuario.telefono || t("Sin registrar")}</dd>
            </dl>

            <div className="acciones-perfil">
              <button type="button" className="boton-gestionar" onClick={() => navegar('portada')}>{t("Buscar mi destino")}</button>

              <button type="button" className="boton-gestionar" onClick={() => navegar('viajes')}>{t("Mis viajes")}</button>

              {usuario.rol === 'ANFITRION' && (<button type="button" className="boton-gestionar" onClick={() => navegar('panel')}>{t("Panel anfitri\u00F3n")}</button>)}

              <button type="button" className="boton-salir" onClick={cerrarSesion} disabled={cerrando}>
                {cerrando ? t("Cerrando sesi\u00F3n...") : t("Cerrar sesi\u00F3n")}
              </button>
            </div>
          </section>) : (<>
            {esLogin ? (<InicioSesion onSesion={recibirSesion}/>) : (<RegistroUsuario onSesion={recibirSesion}/>)}

            <p className="cambio-pantalla">
              {esLogin ? t("\u00BFNo tienes cuenta? ") : t("\u00BFYa tienes cuenta? ")}

              <button type="button" className="boton-enlace" onClick={() => navegar(esLogin ? 'registro' : 'login')}>
                {esLogin ? t("Reg\u00EDstrate") : t("Inicia sesi\u00F3n")}
              </button>
            </p>
          </>)}

        {mensajeSesion && (<p className="mensaje-sesion" role="status">
            {t(mensajeSesion)}
          </p>)}
      </section>
    </main>);
}
export default App;
