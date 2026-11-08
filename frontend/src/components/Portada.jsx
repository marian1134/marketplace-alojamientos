import { t, useIdioma, localeActual } from '../idiomas'
import SelectorIdioma from './SelectorIdioma';
import { useEffect, useRef, useState } from 'react';
import { NOMBRES_TIPO } from '../tipos';
import AvatarUsuario from './AvatarUsuario';
import CampanaNotificaciones from './CampanaNotificaciones';
import { fechaMaximaLlegada, fotoRespaldo, MAXIMO_NOCHES, plural, sumarDias, } from '../formato';
// El alojamiento más grande recibe 16 personas
const MAXIMO_HUESPEDES = 16;
import { DESTINOS } from '../destinos';
import TarjetaDestino from './TarjetaDestino';
import CampoCiudad from './CampoCiudad';
import AvisoSesion from './AvisoSesion';
import CampoFecha from './CampoFecha';
import { IconoBuscar, IconoCalendario, IconoCorazon, IconoPersonas, IconoSalida, IconoUbicacion, } from './Iconos';
function IconoCasa() {
    useIdioma();
    return (<svg viewBox="0 0 24 24" aria-hidden="true" className="portada-icono-logo">
      <path d="M3 10.5 12 3l9 7.5M5.5 9.5V21h13V9.5M9 21v-7h6v7" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>);
}
function Portada({ usuario, onIniciarSesion, onRegistrarse, onNavegar, onCerrarSesion, onVerAlojamiento, onBuscar, favoritos, onFavorito, }) {
    useIdioma();
    const [menuMovilAbierto, setMenuMovilAbierto] = useState(false);
    const [destino, setDestino] = useState('');
    const [entrada, setEntrada] = useState('');
    const [salida, setSalida] = useState('');
    const [huespedes, setHuespedes] = useState('2');
    const [mensajeBusqueda, setMensajeBusqueda] = useState('');
    const [alojamientos, setAlojamientos] = useState([]);
    const [destacados, setDestacados] = useState([]);
    const [cargandoAlojamientos, setCargandoAlojamientos] = useState(true);
    const [mensajeAlojamientos, setMensajeAlojamientos] = useState('');
    // Letrero de inicio de sesión: solo para guardar favoritos
    const [avisoSesion, setAvisoSesion] = useState(false);
    // Alojamiento que quiso guardar sin sesión (se abre después del login)
    const alojamientoDeseado = useRef(null);
    function pedirSesion(idAlojamiento) {
        alojamientoDeseado.current = idAlojamiento ?? null;
        ventanaSeccion.current?.close();
        setAvisoSesion(true);
    }
    // Ventana con "Alojamientos", "Cómo funciona" o "Sobre nosotros"
    const ventanaSeccion = useRef(null);
    const [seccionAbierta, setSeccionAbierta] = useState(null);
    function abrirSeccion(seccion) {
        setSeccionAbierta(seccion);
        const ventana = ventanaSeccion.current;
        if (ventana && !ventana.open) {
            ventana.showModal();
        }
    }
    function cerrarSeccion() {
        ventanaSeccion.current?.close();
    }
    function abrirAlojamiento(idAlojamiento) {
        ventanaSeccion.current?.close();
        onVerAlojamiento(idAlojamiento, {
            entrada,
            salida,
            huespedes,
        });
    }
    const fechaActual = new Date();
    const fechaMinima = [
        fechaActual.getFullYear(),
        String(fechaActual.getMonth() + 1).padStart(2, '0'),
        String(fechaActual.getDate()).padStart(2, '0'),
    ].join('-');
    useEffect(() => {
        let activo = true;
        async function cargarAlojamientos() {
            try {
                const respuesta = await fetch('/api/v1/alojamientos', {
                    credentials: 'same-origin',
                    cache: 'no-store',
                });
                if (!respuesta.ok) {
                    throw new Error(t("No se pudieron consultar los alojamientos"));
                }
                const datos = await respuesta.json();
                // 9 destacados, cada uno de un destino distinto
                const ciudadesVistas = new Set();
                const elegidos = [];
                for (const alojamiento of datos) {
                    if (elegidos.length === 9) {
                        break;
                    }
                    if (!ciudadesVistas.has(alojamiento.ciudad)) {
                        ciudadesVistas.add(alojamiento.ciudad);
                        elegidos.push(alojamiento);
                    }
                }
                // Solo se piden las fotos de los destacados
                const destacadosConPortada = await Promise.all(elegidos.map(async (alojamiento) => {
                    try {
                        const respuestaImagenes = await fetch(`/api/v1/alojamientos/${alojamiento.idAlojamiento}/imagenes`, {
                            credentials: 'same-origin',
                            cache: 'no-store',
                        });
                        if (!respuestaImagenes.ok) {
                            return { ...alojamiento, imagenPortada: null };
                        }
                        const imagenes = await respuestaImagenes.json();
                        const portada = imagenes.find((imagen) => imagen.principal) ??
                            imagenes[0];
                        return {
                            ...alojamiento,
                            imagenPortada: portada?.urlImagen ?? null,
                        };
                    }
                    catch {
                        return { ...alojamiento, imagenPortada: null };
                    }
                }));
                if (activo) {
                    setAlojamientos(datos);
                    setDestacados(destacadosConPortada);
                }
            }
            catch {
                if (activo) {
                    setMensajeAlojamientos(t("No se pudieron cargar los alojamientos disponibles."));
                }
            }
            finally {
                if (activo) {
                    setCargandoAlojamientos(false);
                }
            }
        }
        cargarAlojamientos();
        return () => {
            activo = false;
        };
    }, []);
    function contarEnDestino(destino) {
        return alojamientos.filter((alojamiento) => destino.ciudades.includes(alojamiento.ciudad?.toLocaleLowerCase('es'))).length;
    }
    // Al tocar un destino se muestran sus alojamientos
    function elegirDestino(destino) {
        onBuscar({
            destino: destino.nombre,
            ciudades: destino.ciudades,
            entrada,
            salida,
            huespedes: '',
        });
    }
    // Si no hay alojamientos publicados, la sección no se muestra
    const hayAlojamientos = cargandoAlojamientos ||
        mensajeAlojamientos !== '' ||
        alojamientos.length > 0;
    function buscarAlojamientos(evento) {
        evento.preventDefault();
        setMensajeBusqueda('');
        const cantidadHuespedes = Number(huespedes);
        if (!destino.trim()) {
            setMensajeBusqueda(t("Escribe la ciudad o el destino que deseas buscar."));
            return;
        }
        if (!entrada || !salida) {
            setMensajeBusqueda(t("Selecciona las fechas de entrada y salida."));
            return;
        }
        if (entrada < fechaMinima) {
            setMensajeBusqueda(t("La fecha de entrada no puede estar en el pasado."));
            return;
        }
        if (salida <= entrada) {
            setMensajeBusqueda(t("La fecha de salida debe ser posterior a la fecha de entrada."));
            return;
        }
        if (!Number.isInteger(cantidadHuespedes) ||
            cantidadHuespedes < 1) {
            setMensajeBusqueda(t("La cantidad de hu\u00E9spedes debe ser un n\u00FAmero entero mayor que cero."));
            return;
        }
        // Abre la pantalla de resultados
        onBuscar({
            destino: destino.trim(),
            entrada,
            salida,
            huespedes: cantidadHuespedes,
        });
    }
    const seccionAlojamientos = (hayAlojamientos && (<section className="portada-alojamientos" id="alojamientos-destacados">
        <p className="portada-etiqueta">{t("Encuentra tu lugar ideal")}</p>

        <h2>{t("Alojamientos populares")}</h2>

        <p className="portada-descripcion-seccion">{t("Explora espacios \u00FAnicos para tu pr\u00F3xima aventura.")}</p>

        {cargandoAlojamientos ? (<p className="portada-estado">{t("Cargando alojamientos...")}</p>) : mensajeAlojamientos ? (<p className="portada-estado portada-error" role="status">
            {t(mensajeAlojamientos)}
          </p>) : (<div className="portada-tarjetas">
            {destacados.map((alojamiento) => (<article className="portada-tarjeta tarjeta-clic" key={alojamiento.idAlojamiento} onClick={() => abrirAlojamiento(alojamiento.idAlojamiento)}>
                  <div className="portada-tarjeta-imagen">
                    {alojamiento.imagenPortada ? (<img src={alojamiento.imagenPortada} alt={t(t("Portada de ") +
                            alojamiento.titulo)} onError={fotoRespaldo}/>) : (<div className="portada-sin-foto">
                        <span aria-hidden="true">
                          ⌂
                        </span>

                        <p>{t("Sin fotograf\u00EDa")}</p>
                      </div>)}

                    <span className="portada-tipo">
                      {t(NOMBRES_TIPO[alojamiento.tipoAlojamiento] ?? alojamiento.tipoAlojamiento)}
                    </span>

                    <button type="button" className={favoritos?.has(alojamiento.idAlojamiento)
                        ? 'portada-favorito activo'
                        : 'portada-favorito'} onClick={(evento) => {
                        evento.stopPropagation();
                        if (!usuario) {
                            pedirSesion(alojamiento.idAlojamiento);
                            return;
                        }
                        onFavorito(alojamiento.idAlojamiento);
                    }} aria-pressed={favoritos?.has(alojamiento.idAlojamiento)} aria-label={t(t("Guardar {0} en favoritos", alojamiento.titulo))}>
                      <IconoCorazon tamano={20} activo={favoritos?.has(alojamiento.idAlojamiento)}/>
                    </button>
                  </div>

                  <div className="portada-tarjeta-contenido">
                    <div className="portada-tarjeta-titulo">
                      <div>
                        <h3>
                          {alojamiento.titulo}
                        </h3>

                        <p>
                          ⌖ {alojamiento.ciudad}
                        </p>
                      </div>

                      <p className="portada-precio">
                        <strong>
                          $
                          {Number(alojamiento.precioNoche).toLocaleString(localeActual())}
                        </strong>

                        <span>{t("/ noche")}</span>
                      </p>
                    </div>

                    <p className="portada-tarjeta-descripcion">
                      {alojamiento.descripcion}
                    </p>

                    <div className="portada-tarjeta-datos">
                      <span>
                        ♙ {alojamiento.capacidad}{' '}{t("personas")}</span>

                      <span>
                        {alojamiento.direccion}
                      </span>
                    </div>

                    <button type="button" className="boton-ver-alojamiento" onClick={(evento) => {
                        evento.stopPropagation();
                        abrirAlojamiento(alojamiento.idAlojamiento);
                    }}>{t("Ver disponibilidad y reservar")}</button>
                  </div>
                </article>))}
          </div>)}

        {alojamientos.length > destacados.length && (<button type="button" className="boton-ver-todos boton-ver-todos-grande" onClick={() => {
                    ventanaSeccion.current?.close();
                    onBuscar({
                        destino: '',
                        entrada: '',
                        salida: '',
                        huespedes: '',
                    });
                }}>{t("Ver m\u00E1s")}</button>)}
      </section>));
    const seccionComo = (<>
      <section className="portada-como-funciona" id="como-funciona">
        <p className="portada-etiqueta">{t("C\u00F3mo funciona")}</p>

        <h2>{t("Tu viaje en 3 pasos")}</h2>

        <ol className="pasos-viaje">
          <li>
            <span aria-hidden="true">1</span>
            <h3>{t("Busca tu destino")}</h3>
            <p>{t("Elige a d\u00F3nde quieres ir, tus fechas y cu\u00E1ntas personas viajan contigo.")}</p>
          </li>

          <li>
            <span aria-hidden="true">2</span>
            <h3>{t("Reserva y paga seguro")}</h3>
            <p>{t("Ves el precio total antes de pagar, sin sorpresas. Tus fechas quedan bloqueadas al instante.")}</p>
          </li>

          <li>
            <span aria-hidden="true">3</span>
            <h3>{t("Vive la experiencia")}</h3>
            <p>{t("Llega, disfruta y gestiona tu reserva desde Mis viajes cuando lo necesites.")}</p>
          </li>
        </ol>

        <div className="invitacion-anfitrion">
          <div>
            <strong>{t("\u00BFTienes un alojamiento?")}</strong>
            <p>{t("Publ\u00EDcalo en StayHub y empieza a recibir viajeros de todo el pa\u00EDs.")}</p>
          </div>

          <button type="button" className="portada-boton-principal" onClick={() => usuario?.rol === 'ANFITRION'
            ? onNavegar('panel')
            : onRegistrarse()}>{t("Quiero ser anfitri\u00F3n")}</button>
        </div>
      </section>
      </>);
    const seccionNosotros = (<>
      <section className="portada-nosotros" id="sobre-nosotros">
        <p className="portada-etiqueta">{t("Sobre nosotros")}</p>

        <h2>{t("Somos StayHub, expertos en tus viajes")}</h2>

        <p>{t("Somos una empresa colombiana de Inversiones LR enfocada en que tu viaje empiece mucho antes de llegar: te ayudamos a encontrar el lugar ideal, reservarlo con tranquilidad y disfrutarlo sin preocupaciones.")}</p>

        <div className="nosotros-valores">
          <article>
            <span aria-hidden="true">◆</span>
            <h3>{t("Confianza")}</h3>
            <p>{t("Revisamos cada alojamiento antes de publicarlo y protegemos cada pago.")}</p>
          </article>

          <article>
            <span aria-hidden="true">✦</span>
            <h3>{t("Experiencias locales")}</h3>
            <p>{t("Del Caribe a los Andes: caba\u00F1as, fincas, glampings y casas con alma colombiana.")}</p>
          </article>

          <article>
            <span aria-hidden="true">♥</span>
            <h3>{t("Te acompa\u00F1amos")}</h3>
            <p>{t("Antes, durante y despu\u00E9s de tu viaje, con reglas claras y cancelaciones justas.")}</p>
          </article>
        </div>

        <p className="nosotros-firma">{t("Viajar es coleccionar momentos. Nosotros nos encargamos del lugar; t\u00FA, de los recuerdos.")}</p>
      </section>
      </>);
    return (<main className="portada-publica">
      <section className="portada-hero">
        <header className="portada-navegacion">
          <button type="button" className="portada-logo" onClick={() => window.scrollTo({
            top: 0,
            behavior: 'smooth',
        })}>
            <IconoCasa />
            <span>StayHub</span>
          </button>

          <button type="button" className="portada-menu-movil" aria-expanded={menuMovilAbierto} aria-controls="portada-menu-principal" aria-label={t(menuMovilAbierto ? "Cerrar menú" : "Abrir menú")} onClick={() => setMenuMovilAbierto((abierto) => !abierto)}>
            <span aria-hidden="true">{menuMovilAbierto ? '×' : '☰'}</span>
          </button>

          <nav id="portada-menu-principal" className={menuMovilAbierto ? 'menu-movil-abierto' : ''} aria-label={t("Navegaci\u00F3n principal")}>
            {!usuario && (<>
                <button type="button" className="portada-enlace" onClick={() => { setMenuMovilAbierto(false); abrirSeccion('alojamientos'); }}>{t("Alojamientos")}</button>

                <button type="button" className="portada-enlace" onClick={() => { setMenuMovilAbierto(false); abrirSeccion('como'); }}>{t("C\u00F3mo funciona")}</button>

                <button type="button" className="portada-enlace" onClick={() => { setMenuMovilAbierto(false); abrirSeccion('nosotros'); }}>{t("Sobre nosotros")}</button>
              </>)}
          </nav>

          {/* La campana queda fuera del menú para que en el celular siempre se vea */}
          <div className="portada-derecha">
          {/* El idioma también queda fuera del menú, siempre a la vista */}
          {!usuario && <SelectorIdioma portada/>}
          <CampanaNotificaciones usuario={usuario}/>
          <div className={menuMovilAbierto ? 'portada-acciones menu-movil-abierto' : 'portada-acciones'}>

            {usuario ? (<>
                <button type="button" className="portada-boton-claro" onClick={() => { setMenuMovilAbierto(false); onNavegar('viajes'); }}>{t("Mis viajes")}</button>

                {usuario.rol === 'ADMINISTRADOR' && (<button type="button" className="portada-boton-claro" onClick={() => { setMenuMovilAbierto(false); onNavegar('administracion'); }}>{t("Administraci\u00F3n")}</button>)}

                {usuario.rol === 'ANFITRION' && (<button type="button" className="portada-boton-claro" onClick={() => { setMenuMovilAbierto(false); onNavegar('panel'); }}>{t("Panel anfitri\u00F3n")}</button>)}

                <button type="button" className="portada-boton-principal portada-boton-perfil" onClick={() => { setMenuMovilAbierto(false); onNavegar('perfil'); }} title={t("Mi perfil")}>
  <AvatarUsuario usuario={usuario} className="avatar-portada" mostrarNombre/>
        </button>

                <button type="button" className="portada-boton-claro" onClick={() => { setMenuMovilAbierto(false); onCerrarSesion(); }}>{t("Salir")}</button>
              </>) : (<>
                <button type="button" className="portada-boton-claro" onClick={() => { setMenuMovilAbierto(false); onIniciarSesion(); }}>{t("Iniciar sesi\u00F3n")}</button>

                <button type="button" className="portada-boton-principal" onClick={() => { setMenuMovilAbierto(false); onRegistrarse(); }}>{t("Registrarse")}</button>
              </>)}
          </div>
          </div>
        </header>

        <div className="portada-contenido">
          <h1>{t("Tu pr\u00F3xima aventura")}<br />{t("empieza aqu\u00ED")}</h1>

          <p>{t("Descubre alojamientos \u00FAnicos en los mejores destinos de Colombia.")}</p>

          <form className="portada-buscador" onSubmit={buscarAlojamientos} noValidate>
            <div className="buscador-item">
              <span className="buscador-icono"><IconoUbicacion tamano={24}/></span>

              <span className="buscador-campo">
                <label htmlFor="buscar-destino">
                  <strong>{t("\u00BFA d\u00F3nde vas?")}</strong>
                </label>

                <CampoCiudad id="buscar-destino" value={destino} onChange={(valor) => {
            setDestino(valor);
            setMensajeBusqueda('');
        }}/>
              </span>
            </div>

            <div className="buscador-item">
              <span className="buscador-icono"><IconoCalendario tamano={24}/></span>

              <span className="buscador-campo">
                <strong>{t("Entrada")}</strong>

                <CampoFecha etiqueta={t("Fecha de entrada")} value={entrada} min={fechaMinima} max={fechaMaximaLlegada()} onChange={(valor) => {
            setEntrada(valor);
            setMensajeBusqueda('');
            if (salida &&
                (salida <= valor ||
                    salida > sumarDias(valor, MAXIMO_NOCHES))) {
                setSalida('');
            }
        }}/>
              </span>
            </div>

            <div className="buscador-item">
              <span className="buscador-icono"><IconoSalida tamano={24}/></span>

              <span className="buscador-campo">
                <strong>{t("Salida")}</strong>

                <CampoFecha etiqueta={t("Fecha de salida")} value={salida} min={entrada
            ? sumarDias(entrada, 1)
            : sumarDias(fechaMinima, 1)} max={entrada
            ? sumarDias(entrada, MAXIMO_NOCHES)
            : sumarDias(fechaMaximaLlegada(), MAXIMO_NOCHES)} onChange={(valor) => {
            setSalida(valor);
            setMensajeBusqueda('');
        }}/>
              </span>
            </div>

            <div className="buscador-item">
              <span className="buscador-icono"><IconoPersonas tamano={24}/></span>

              <span className="buscador-campo">
                <label htmlFor="buscar-huespedes">
                  <strong>{t("Hu\u00E9spedes")}</strong>
                </label>

                <select id="buscar-huespedes" value={huespedes} onChange={(evento) => {
            setHuespedes(evento.target.value);
            setMensajeBusqueda('');
        }}>
                  {Array.from({ length: MAXIMO_HUESPEDES }, (_, indice) => indice + 1).map((cantidad) => (<option key={cantidad} value={cantidad}>
                        {plural(cantidad, t("hu\u00E9sped"), t("hu\u00E9spedes"))}
                      </option>))}
                </select>
              </span>
            </div>

            <button type="submit" className="portada-boton-buscar">
              <IconoBuscar tamano={20}/>{t("Buscar")}</button>
          </form>

          {mensajeBusqueda && (<p className="portada-mensaje-busqueda" role="alert">
              {t(mensajeBusqueda)}
            </p>)}
        </div>

        <div className="portada-beneficios">
          <article>
            <span aria-hidden="true">⌂</span>

            <div>
              <strong>{t("Alojamientos verificados")}</strong>

              <p>{t("Estancias seguras y confiables")}</p>
            </div>
          </article>

          <article>
            <span aria-hidden="true">◆</span>

            <div>
              <strong>{t("Reserva f\u00E1cil y segura")}</strong>

              <p>{t("Tu tranquilidad es lo primero")}</p>
            </div>
          </article>

          <article>
            <span aria-hidden="true">★</span>

            <div>
              <strong>{t("Experiencias \u00FAnicas")}</strong>

              <p>{t("Destinos incre\u00EDbles en un solo lugar")}</p>
            </div>
          </article>
        </div>
      </section>

      <section className="portada-destinos" id="destinos-populares">
        <p className="portada-etiqueta">{t("Lo mejor de Colombia")}</p>

        <h2>{t("Destinos populares")}</h2>

        <p className="portada-descripcion-seccion">{t("Elige un destino y descubre d\u00F3nde quedarte.")}</p>

        <div className="destinos-grilla">
          {DESTINOS.slice(0, 3).map((destino) => (<TarjetaDestino key={destino.id} destino={destino} cantidad={contarEnDestino(destino)} onElegir={elegirDestino}/>))}
        </div>

        {/* "Ver más" abre la pantalla con todos los destinos */}
        {(<button type="button" className="boton-ver-todos boton-ver-todos-grande" onClick={() => onNavegar('destinos')}>{t("Ver m\u00E1s")}</button>)}

      </section>

      {/* Con sesión los alojamientos se ven aquí; sin sesión se abren con el botón de arriba */}
      {usuario && seccionAlojamientos}

      <AvisoSesion abierto={avisoSesion} onCerrar={() => setAvisoSesion(false)} onIniciarSesion={() => {
            setAvisoSesion(false);
            onIniciarSesion(alojamientoDeseado.current);
        }} onRegistrarse={() => {
            setAvisoSesion(false);
            onRegistrarse(alojamientoDeseado.current);
        }}/>

      {/* Ventana de "Alojamientos", "Cómo funciona" y "Sobre nosotros" (sin sesión) */}
      <dialog ref={ventanaSeccion} className="portada-ventana" aria-label={t("Informaci\u00F3n de StayHub")} onClose={() => setSeccionAbierta(null)}>
        <button type="button" className="modal-cerrar portada-ventana-cerrar" onClick={cerrarSeccion} aria-label={t("Cerrar")}>
          ×
        </button>
        {seccionAbierta === 'alojamientos' && (seccionAlojamientos || (<p className="portada-estado">{t("Pronto tendremos alojamientos publicados.")}</p>))}
        {seccionAbierta === 'como' && seccionComo}
        {seccionAbierta === 'nosotros' && seccionNosotros}
      </dialog>

    </main>);
}
export default Portada;
