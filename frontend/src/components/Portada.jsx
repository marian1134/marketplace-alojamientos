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
import CampoFecha from './CampoFecha';
import { IconoBuscar, IconoCalendario, IconoCorazon, IconoPersonas, IconoSalida, IconoUbicacion, } from './Iconos';
function IconoCasa() {
    useIdioma();
    return (<svg viewBox="0 0 24 24" aria-hidden="true" className="portada-icono-logo">
      <path d="M3 10.5 12 3l9 7.5M5.5 9.5V21h13V9.5M9 21v-7h6v7" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>);
}
// Casa con candado del mockup "Inicia sesión para continuar"
function IlustracionCandado() {
    useIdioma();
    return (<svg viewBox="0 0 220 120" aria-hidden="true" className="modal-sesion-ilustracion">
      <ellipse cx="110" cy="70" rx="100" ry="48" fill="#f6ede4"/>
      <path d="M20 108h180" stroke="#7a9a6a" strokeWidth="4" strokeLinecap="round"/>
      <circle cx="42" cy="84" r="14" fill="#8fb48a"/>
      <rect x="40" y="94" width="4" height="14" fill="#6b5a45"/>
      <circle cx="180" cy="80" r="16" fill="#7fa77c"/>
      <rect x="178" y="92" width="4" height="16" fill="#6b5a45"/>
      <path d="M62 66 110 34l48 32" fill="#6d4c3d"/>
      <rect x="70" y="64" width="80" height="44" rx="2" fill="#d9a77c"/>
      <rect x="102" y="82" width="16" height="26" rx="2" fill="#7b5236"/>
      <rect x="80" y="74" width="12" height="10" rx="1" fill="#557a6a"/>
      <rect x="128" y="74" width="12" height="10" rx="1" fill="#557a6a"/>
      <path d="M98 30v-8a12 12 0 0 1 24 0v8" fill="none" stroke="#b07d55" strokeWidth="5"/>
      <rect x="94" y="28" width="32" height="24" rx="4" fill="#c99366"/>
      <circle cx="110" cy="40" r="3" fill="#6d4c3d"/>
    </svg>);
}
function Portada({ usuario, onIniciarSesion, onRegistrarse, onNavegar, onCerrarSesion, onVerAlojamiento, onBuscar, favoritos, onFavorito, }) {
    useIdioma();
    const [destino, setDestino] = useState('');
    const [entrada, setEntrada] = useState('');
    const [salida, setSalida] = useState('');
    const [huespedes, setHuespedes] = useState('2');
    const [mensajeBusqueda, setMensajeBusqueda] = useState('');
    const [alojamientos, setAlojamientos] = useState([]);
    const [destacados, setDestacados] = useState([]);
    const [cargandoAlojamientos, setCargandoAlojamientos] = useState(true);
    const [mensajeAlojamientos, setMensajeAlojamientos] = useState('');
    // Ventana que pide iniciar sesión antes de buscar
    const ventanaSesion = useRef(null);
    // Alojamiento que quiso abrir sin sesión (se abre después del login)
    const alojamientoDeseado = useRef(null);
    function pedirSesion(idAlojamiento) {
        alojamientoDeseado.current = idAlojamiento ?? null;
        const ventana = ventanaSesion.current;
        if (ventana && !ventana.open) {
            ventana.showModal();
        }
    }
    function cerrarVentanaSesion() {
        ventanaSesion.current?.close();
    }
    function abrirAlojamiento(idAlojamiento) {
        if (!usuario) {
            pedirSesion(idAlojamiento);
            return;
        }
        onVerAlojamiento(idAlojamiento, {
            entrada,
            salida,
            huespedes,
        });
    }
    // Sin sesión, cualquier clic en el buscador abre la ventana
    function revisarSesion(evento) {
        if (!usuario) {
            evento.preventDefault();
            pedirSesion();
        }
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
        if (!usuario) {
            pedirSesion();
            return;
        }
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
        if (!usuario) {
            pedirSesion();
            return;
        }
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

          <nav aria-label={t("Navegaci\u00F3n principal")}>
            <a href={alojamientos.length > 0
            ? '#alojamientos-destacados'
            : '#destinos-populares'}>{t("Alojamientos")}</a>

            {!usuario && (<>
                <a href="#como-funciona">{t("C\u00F3mo funciona")}</a>

                <a href="#sobre-nosotros">{t("Sobre nosotros")}</a>
              </>)}
          </nav>

          <div className="portada-acciones">
            {!usuario && <SelectorIdioma portada/>}

            {usuario ? (<>
                <CampanaNotificaciones usuario={usuario}/>
                <button type="button" className="portada-boton-claro" onClick={() => onNavegar('viajes')}>{t("Mis viajes")}</button>

                {usuario.rol === 'ADMINISTRADOR' && (<button type="button" className="portada-boton-claro" onClick={() => onNavegar('administracion')}>{t("Administraci\u00F3n")}</button>)}

                {usuario.rol === 'ANFITRION' && (<button type="button" className="portada-boton-claro" onClick={() => onNavegar('panel')}>{t("Panel anfitri\u00F3n")}</button>)}

                <button type="button" className="portada-boton-principal portada-boton-perfil" onClick={() => onNavegar('perfil')} title={t("Mi perfil")}>
  <AvatarUsuario usuario={usuario} className="avatar-portada" mostrarNombre/>
        </button>

                <button type="button" className="portada-boton-claro" onClick={onCerrarSesion}>{t("Salir")}</button>
              </>) : (<>
                <button type="button" className="portada-boton-claro" onClick={() => onIniciarSesion()}>{t("Iniciar sesi\u00F3n")}</button>

                <button type="button" className="portada-boton-principal" onClick={() => onRegistrarse()}>{t("Registrarse")}</button>
              </>)}
          </div>
        </header>

        <div className="portada-contenido">
          <h1>{t("Tu pr\u00F3xima aventura")}<br />{t("empieza aqu\u00ED")}</h1>

          <p>{t("Descubre alojamientos \u00FAnicos en los mejores destinos de Colombia.")}</p>

          <form className="portada-buscador" onSubmit={buscarAlojamientos} onClick={revisarSesion} noValidate>
            <div className="buscador-item">
              <span className="buscador-icono"><IconoUbicacion tamano={24}/></span>

              <span className="buscador-campo">
                <label htmlFor="buscar-destino">
                  <strong>{t("\u00BFA d\u00F3nde vas?")}</strong>
                </label>

                <CampoCiudad id="buscar-destino" value={destino} onChange={(valor) => {
            setDestino(valor);
            setMensajeBusqueda('');
        }} bloqueado={!usuario}/>
              </span>
            </div>

            <div className="buscador-item">
              <span className="buscador-icono"><IconoCalendario tamano={24}/></span>

              <span className="buscador-campo">
                <strong>{t("Entrada")}</strong>

                <CampoFecha etiqueta={t("Fecha de entrada")} value={entrada} min={fechaMinima} max={fechaMaximaLlegada()} bloqueado={!usuario} onChange={(valor) => {
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
            : sumarDias(fechaMaximaLlegada(), MAXIMO_NOCHES)} bloqueado={!usuario} onChange={(valor) => {
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

                <select id="buscar-huespedes" value={huespedes} onMouseDown={(evento) => {
            // Sin sesión no se abre: el clic muestra el aviso
            if (!usuario) {
                evento.preventDefault();
            }
        }} onChange={(evento) => {
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
          {DESTINOS.map((destino) => (<TarjetaDestino key={destino.id} destino={destino} cantidad={contarEnDestino(destino)} onElegir={elegirDestino}/>))}
        </div>

      </section>

      {hayAlojamientos && (<section className="portada-alojamientos" id="alojamientos-destacados">
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
                            pedirSesion();
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
                    if (!usuario) {
                        pedirSesion();
                        return;
                    }
                    onBuscar({
                        destino: '',
                        entrada: '',
                        salida: '',
                        huespedes: '',
                    });
                }}>{t("Ver los")}{alojamientos.length.toLocaleString(localeActual())}{' '}{t("alojamientos")}</button>)}
      </section>)}

      <dialog ref={ventanaSesion} className="modal-sesion" aria-labelledby="modal-sesion-titulo">
        <button type="button" className="modal-cerrar" onClick={cerrarVentanaSesion} aria-label={t("Cerrar")}>
          ×
        </button>

        <IlustracionCandado />

        <h2 id="modal-sesion-titulo">{t("Inicia sesi\u00F3n para continuar")}</h2>

        <p>{t("Para buscar alojamientos, ver disponibilidad y reservar, necesitas una cuenta en StayHub.")}</p>

        <button type="button" className="modal-sesion-principal" onClick={() => {
            cerrarVentanaSesion();
            onIniciarSesion(alojamientoDeseado.current);
        }}>{t("Iniciar sesi\u00F3n")}</button>

        <button type="button" className="modal-sesion-secundario" onClick={() => {
            cerrarVentanaSesion();
            onRegistrarse(alojamientoDeseado.current);
        }}>{t("Crear cuenta")}</button>
      </dialog>

      {/* Solo se muestran en la portada pública, sin sesión */}
      {!usuario && (<>
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
      </>)}

      <footer className="portada-pie">
        © {new Date().getFullYear()}{t("StayHub \u00B7 Inversiones LR \u00B7 Hecho en Colombia")}</footer>
    </main>);
}
export default Portada;
