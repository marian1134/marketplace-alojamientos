import { t, useIdioma } from '../idiomas'
import { useEffect, useRef, useState } from 'react';
import { consultar, enviarDatos, leerError } from '../api';
import ChatReserva from './ChatReserva';
import { Estrellas, IconoEstrella } from './Iconos';
import { dinero, fechaCorta, fotoRespaldo, horaBonita, NOMBRES_ESTADO_RESERVA, NOMBRES_POLITICA, } from '../formato';
const PESTANAS = [
    {
        id: 'proximos',
        texto: 'Próximos',
        estados: ['CONFIRMADA', 'PENDIENTE_APROBACION'],
    },
    {
        id: 'pasados',
        texto: 'Pasados',
        estados: ['COMPLETADA'],
    },
    {
        id: 'cancelados',
        texto: 'Cancelados',
        estados: ['CANCELADA', 'RECHAZADA', 'ANULADA'],
    },
];
function MisViajes({ onExplorar, onVerAlojamiento }) {
    useIdioma();
    const [reservas, setReservas] = useState([]);
    const [chatAbierto, setChatAbierto] = useState(null);
    const [cargando, setCargando] = useState(true);
    const [error, setError] = useState('');
    const [pestana, setPestana] = useState('proximos');
    const [aCancelar, setACancelar] = useState(null);
    const [motivo, setMotivo] = useState('');
    const [cancelando, setCancelando] = useState(false);
    const [mensaje, setMensaje] = useState('');
    const ventana = useRef(null);
    // Check-in
    const [haciendoCheckIn, setHaciendoCheckIn] = useState(null);
    const [avisoCheckIn, setAvisoCheckIn] = useState(null);
    // Ventana para dejar reseña
    const ventanaResena = useRef(null);
    const [aResenar, setAResenar] = useState(null);
    const [estrellas, setEstrellas] = useState(5);
    const [comentario, setComentario] = useState('');
    const [enviandoResena, setEnviandoResena] = useState(false);
    const envioResenaEnCurso = useRef(false);
    const [mensajeResena, setMensajeResena] = useState('');
    async function cargar() {
        try {
            const respuesta = await consultar('/api/v1/reservas/mis-reservas');
            if (!respuesta.ok) {
                throw new Error(await leerError(respuesta, t("No se pudieron cargar tus viajes.")));
            }
            setReservas(await respuesta.json());
            setError('');
        }
        catch (excepcion) {
            setError(excepcion.message);
        }
        finally {
            setCargando(false);
        }
    }
    useEffect(() => {
        cargar();
    }, []);
    function abrirCancelacion(reserva) {
        setACancelar(reserva);
        setMotivo('');
        setMensaje('');
        ventana.current?.showModal();
    }
    async function confirmarCancelacion(evento) {
        evento.preventDefault();
        if (!motivo.trim()) {
            setMensaje(t("Cu\u00E9ntanos el motivo de la cancelaci\u00F3n."));
            return;
        }
        setCancelando(true);
        try {
            const respuesta = await enviarDatos(`/api/v1/reservas/${aCancelar.idReserva}/cancelar`, { motivo });
            if (!respuesta.ok) {
                setMensaje(await leerError(respuesta, t("No se pudo cancelar la reserva.")));
                return;
            }
            const cancelada = await respuesta.json();
            ventana.current?.close();
            setReservas((actuales) => actuales.map((reserva) => reserva.idReserva === cancelada.idReserva ? cancelada : reserva));
            setPestana('cancelados');
        }
        catch {
            setMensaje(t("No se pudo conectar con el servidor."));
        }
        finally {
            setCancelando(false);
        }
    }
    async function hacerCheckIn(reserva) {
        setHaciendoCheckIn(reserva.idReserva);
        setAvisoCheckIn(null);
        try {
            const respuesta = await enviarDatos(`/api/v1/reservas/${reserva.idReserva}/check-in`, {});
            if (!respuesta.ok) {
                setAvisoCheckIn({
                    error: true,
                    texto: await leerError(respuesta, t("No se pudo hacer el check-in.")),
                });
                return;
            }
            const actualizada = await respuesta.json();
            setReservas((actuales) => actuales.map((item) => item.idReserva === actualizada.idReserva ? actualizada : item));
            setAvisoCheckIn({
                error: false,
                texto: t("\u00A1Check-in listo en {0}! Le avisamos al anfitri\u00F3n. Disfruta tu estad\u00EDa.", actualizada.tituloAlojamiento),
            });
        }
        catch {
            setAvisoCheckIn({
                error: true,
                texto: t("No se pudo conectar con el servidor."),
            });
        }
        finally {
            setHaciendoCheckIn(null);
        }
    }
    function abrirResena(reserva) {
        setAResenar(reserva);
        setEstrellas(5);
        setComentario('');
        setMensajeResena('');
        ventanaResena.current?.showModal();
    }
    async function enviarResena(evento) {
        evento.preventDefault();
        if (envioResenaEnCurso.current)
            return;
        if (comentario.trim().length < 10) {
            setMensajeResena(t("Cu\u00E9ntanos un poco m\u00E1s (m\u00EDnimo 10 caracteres)."));
            return;
        }
        envioResenaEnCurso.current = true;
        setEnviandoResena(true);
        try {
            const respuesta = await enviarDatos(`/api/v1/reservas/${aResenar.idReserva}/resena`, { calificacion: estrellas, comentario: comentario.trim() });
            if (!respuesta.ok) {
                setMensajeResena(await leerError(respuesta, t("No se pudo guardar tu rese\u00F1a.")));
                return;
            }
            ventanaResena.current?.close();
            setReservas((actuales) => actuales.map((reserva) => reserva.idReserva === aResenar.idReserva
                ? {
                    ...reserva,
                    puedeResenar: false,
                    calificacionResena: estrellas,
                }
                : reserva));
        }
        catch {
            setMensajeResena(t("No se pudo conectar con el servidor."));
        }
        finally {
            envioResenaEnCurso.current = false;
            setEnviandoResena(false);
        }
    }
    const estadosVisibles = PESTANAS.find((item) => item.id === pestana).estados;
    const visibles = reservas.filter((reserva) => estadosVisibles.includes(reserva.estado));
    return (<section className="contenedor">
      <h1 className="titulo-serif">{t("Mis viajes")}</h1>
      <p className="texto-suave">{t("Consulta tus reservas, realiza el check-in y califica el alojamiento cuando termine tu estad\u00EDa, desde la pesta\u00F1a Pasados.")}</p>

      <div className="pestanas" role="tablist">
        {PESTANAS.map((item) => {
            const cantidad = reservas.filter((reserva) => item.estados.includes(reserva.estado)).length;
            return (<button key={item.id} type="button" role="tab" aria-selected={pestana === item.id} className={pestana === item.id ? 'activa' : ''} onClick={() => setPestana(item.id)}>
              {t(item.texto)} <span>{cantidad}</span>
            </button>);
        })}
      </div>

      {reservas.some((reserva) => reserva.puedeResenar) && (<div className="aviso" role="status">{t("Tienes alojamientos pendientes por calificar.")}{' '}
          <button type="button" className="boton-enlace" onClick={() => setPestana('pasados')}>{t("Ver viajes para rese\u00F1ar")}</button>
        </div>)}

      {avisoCheckIn && (<p className={avisoCheckIn.error ? 'aviso aviso-error' : 'aviso'} role={avisoCheckIn.error ? 'alert' : 'status'}>
          {avisoCheckIn.texto}
        </p>)}

      {cargando ? (<p className="cargando" role="status">{t("Cargando tus viajes...")}</p>) : error ? (<p className="aviso aviso-error" role="alert">
          {t(error)}
        </p>) : visibles.length === 0 ? (<div className="tarjeta vacio">
          <span aria-hidden="true">🧳</span>
          <h2>
            {pestana === 'proximos'
                ? t("A\u00FAn no tienes viajes pr\u00F3ximos") : t("No hay reservas en esta secci\u00F3n")}
          </h2>
          <p className="texto-suave">{t("Explora alojamientos y reserva tu pr\u00F3xima aventura.")}</p>
          <button type="button" className="boton-principal" onClick={onExplorar}>{t("Explorar alojamientos")}</button>
        </div>) : (<ul className="lista-viajes">
          {visibles.map((reserva) => (<li key={reserva.idReserva} className="tarjeta viaje">
              {reserva.imagenPortada ? (<img src={reserva.imagenPortada} alt="" onError={fotoRespaldo}/>) : (<div className="sin-foto sin-foto-baja">⌂</div>)}

              <div className="viaje-info">
                <div className="tarjeta-titulo">
                  <h2>{reserva.tituloAlojamiento}</h2>
                  <span className={`estado-reserva estado-${reserva.estado.toLowerCase()}`}>
                    {t(NOMBRES_ESTADO_RESERVA[reserva.estado])}
                  </span>
                </div>

                <p className="texto-suave">
                  ⌖ {reserva.ciudad}{t(" \u00B7 C\u00F3digo")}{' '}
                  <strong>{reserva.codigo}</strong>
                </p>

                <p>
                  {fechaCorta(reserva.fechaLlegada)} –{' '}
                  {fechaCorta(reserva.fechaSalida)} · {reserva.noches}{' '}
                  {reserva.noches === 1 ? t("noche") : t("noches")} ·{' '}
                  {reserva.cantidadHuespedes}{' '}
                  {reserva.cantidadHuespedes === 1
                    ? t("hu\u00E9sped") : t("hu\u00E9spedes")}
                </p>

                <p>{t("Total pagado:")}{' '}
                  <strong>
                    {dinero(reserva.montoPagado ?? reserva.total, reserva.monedaPago)}
                  </strong>
                  {reserva.ultimos4 && t(" \u00B7 Tarjeta terminada en {0}", reserva.ultimos4)}
                </p>

                {reserva.valorDevolucion && (<p className="etiqueta-verde">{t("Devoluci\u00F3n:")}{dinero(reserva.valorDevolucion, reserva.monedaPago)}
                  </p>)}

                {reserva.motivo && (<p className="texto-suave">{t("Motivo:")}{reserva.motivo}
                  </p>)}

                {reserva.checkInEn ? (<p className="etiqueta-verde">{t("\u2713 Check-in hecho a las")}{' '}
                    {horaBonita(reserva.checkInEn.slice(11, 16))}
                  </p>) : (reserva.estado === 'CONFIRMADA' &&
                    reserva.horaCheckIn && (<p className="texto-suave">{t("Check-in:")}{fechaCorta(reserva.fechaLlegada)}{t(", desde las")}{' '}
                      {horaBonita(reserva.horaCheckIn)}{t("hasta las 11:59 p. m. Si no lo haces ese d\u00EDa, el anfitri\u00F3n podr\u00E1 cancelar tu reserva.")}</p>))}

                {reserva.estado === 'CONFIRMADA' && !reserva.calificacionResena && (<p className="texto-suave">{t("Podr\u00E1s calificar este alojamiento cuando la reserva est\u00E9 completada.")}</p>)}

                {reserva.calificacionResena && (<p className="tu-resena">{t("Tu rese\u00F1a:")}{' '}
                    <Estrellas valor={reserva.calificacionResena}/>
                  </p>)}

                <div className="viaje-acciones">
                  <button type="button" className="boton-secundario" onClick={() => setChatAbierto(reserva)}>{t("Chat con el anfitri\u00F3n")}</button>

                  {reserva.puedeHacerCheckIn && (<button type="button" className="boton-principal" onClick={() => hacerCheckIn(reserva)} disabled={haciendoCheckIn === reserva.idReserva}>
                      {haciendoCheckIn === reserva.idReserva
                        ? t("Haciendo check-in...") : t("\u2713 Hacer check-in")}
                    </button>)}

                  {reserva.puedeResenar && (<button type="button" className="boton-principal" onClick={() => abrirResena(reserva)}>{t("\u2605 Calificar alojamiento")}</button>)}

                  <button type="button" className="boton-secundario" onClick={() => onVerAlojamiento(reserva.idAlojamiento)}>{t("Ver alojamiento")}</button>

                  {reserva.puedeCancelar && (<button type="button" className="boton-peligro" onClick={() => abrirCancelacion(reserva)}>{t("Cancelar reserva")}</button>)}
                </div>
              </div>
            </li>))}
        </ul>)}

      <dialog ref={ventanaResena} className="modal-sesion modal-izquierda" aria-labelledby="resena-titulo">
        <button type="button" className="modal-cerrar" onClick={() => ventanaResena.current?.close()} aria-label={t("Cerrar")}>
          ×
        </button>

        {aResenar && (<form onSubmit={enviarResena}>
            <h2 id="resena-titulo">{t("Calificar alojamiento")}</h2>
            <p>
              {aResenar.tituloAlojamiento} · {aResenar.ciudad}
            </p>

            <div className="elegir-estrellas" role="radiogroup" aria-label={t("Calificaci\u00F3n")}>
              {[1, 2, 3, 4, 5].map((numero) => (<button key={numero} type="button" role="radio" aria-checked={estrellas === numero} aria-label={t(t("{0} {1}", numero, numero === 1 ? t("estrella") : t("estrellas")))} className={numero <= estrellas ? 'llena' : ''} onClick={() => setEstrellas(numero)}>
                  <IconoEstrella tamano={34} activo={numero <= estrellas}/>
                </button>))}
            </div>

            <label className="campo-bloque">{t("Cu\u00E9ntales a otros viajeros tu experiencia")}<textarea value={comentario} maxLength={1000} rows={4} placeholder={t("\u00BFQu\u00E9 fue lo que m\u00E1s te gust\u00F3?")} onChange={(evento) => {
                setComentario(evento.target.value);
                setMensajeResena('');
            }} required/>
            </label>

            {mensajeResena && (<p className="aviso aviso-error" role="alert">
                {t(mensajeResena)}
              </p>)}

            <button type="submit" className="boton-principal boton-ancho" disabled={enviandoResena}>
              {enviandoResena ? t("Enviando...") : t("Publicar rese\u00F1a")}
            </button>
          </form>)}
      </dialog>

      <dialog ref={ventana} className="modal-sesion modal-izquierda" aria-labelledby="cancelar-titulo">
        <button type="button" className="modal-cerrar" onClick={() => ventana.current?.close()} aria-label={t("Cerrar")}>
          ×
        </button>

        {aCancelar && (<form onSubmit={confirmarCancelacion}>
            <h2 id="cancelar-titulo">{t("Cancelar reserva")}</h2>
            <p>
              {aCancelar.tituloAlojamiento} ·{' '}
              {fechaCorta(aCancelar.fechaLlegada)} –{' '}
              {fechaCorta(aCancelar.fechaSalida)}
            </p>
            <p className="aviso">{t("Esta reserva tiene")}{' '}
              <strong>
                {t(NOMBRES_POLITICA[aCancelar.tipoPolitica]?.toLowerCase())}
              </strong>{t(". La devoluci\u00F3n se calcula seg\u00FAn los d\u00EDas que faltan para la llegada.")}</p>

            <label className="campo-bloque">{t("Motivo de la cancelaci\u00F3n")}<textarea value={motivo} maxLength={500} rows={3} onChange={(evento) => {
                setMotivo(evento.target.value);
                setMensaje('');
            }} required/>
            </label>

            {mensaje && (<p className="aviso aviso-error" role="alert">
                {t(mensaje)}
              </p>)}

            <button type="submit" className="boton-peligro boton-ancho" disabled={cancelando}>
              {cancelando ? t("Cancelando...") : t("S\u00ED, cancelar reserva")}
            </button>
            <button type="button" className="boton-secundario boton-ancho" onClick={() => ventana.current?.close()}>{t("No, mantener reserva")}</button>
          </form>)}
      </dialog>
      {chatAbierto && (<ChatReserva key={chatAbierto.idReserva} reserva={chatAbierto} onCerrar={() => setChatAbierto(null)}/>)}
    </section>);
}
export default MisViajes;
