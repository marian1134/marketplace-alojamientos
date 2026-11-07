import { t, useIdioma } from '../idiomas'
import { useEffect, useState } from 'react';
import { consultar, enviarDatos, leerError } from '../api';
import ChatReserva from './ChatReserva';
import CalificarHuesped from './CalificarHuesped';
import './reservas-anfitrion.css';
import { aFecha, fechaCorta, horaBonita, hoyTexto, NOMBRES_ESTADO_RESERVA, pesos, } from '../formato';
function PanelAnfitrion({ usuario, onGestionarAlojamientos, onCalendario, }) {
    useIdioma();
    const [alojamientos, setAlojamientos] = useState([]);
    const [reservas, setReservas] = useState([]);
    const [chatAbierto, setChatAbierto] = useState(null);
    const [calificaciones, setCalificaciones] = useState([]);
    const [cargando, setCargando] = useState(true);
    const [error, setError] = useState('');
    const [mensaje, setMensaje] = useState('');
    useEffect(() => {
        let activo = true;
        async function cargar() {
            try {
                const [respuestaAlojamientos, respuestaReservas, respuestaCalificaciones] = await Promise.all([
                    consultar('/api/v1/alojamientos/mis-alojamientos'),
                    consultar('/api/v1/reservas/recibidas'),
                    consultar('/api/v1/resenas-huesped/mis-calificaciones'),
                ]);
                if (!respuestaAlojamientos.ok || !respuestaReservas.ok || !respuestaCalificaciones.ok) {
                    throw new Error(t("No se pudo cargar tu panel."));
                }
                const datosAlojamientos = await respuestaAlojamientos.json();
                const datosReservas = await respuestaReservas.json();
                const datosCalificaciones = await respuestaCalificaciones.json();
                if (activo) {
                    setAlojamientos(datosAlojamientos);
                    setReservas(datosReservas);
                    setCalificaciones(datosCalificaciones);
                }
            }
            catch (excepcion) {
                if (activo) {
                    setError(excepcion.message);
                }
            }
            finally {
                if (activo) {
                    setCargando(false);
                }
            }
        }
        cargar();
        return () => {
            activo = false;
        };
    }, []);
    function reemplazar(actualizada) {
        setReservas((actuales) => actuales.map((reserva) => reserva.idReserva === actualizada.idReserva
            ? actualizada
            : reserva));
    }
    // El huésped no hizo check-in el día de llegada
    async function cancelarNoShow(reserva) {
        const seguro = window.confirm(t("\u00BFCancelar la reserva {0} porque {1} no se present\u00F3? ", reserva.codigo, reserva.nombreHuesped) + t("La devoluci\u00F3n sigue tu pol\u00EDtica de cancelaci\u00F3n y las fechas quedan libres."));
        if (!seguro) {
            return;
        }
        setMensaje('');
        const respuesta = await enviarDatos(`/api/v1/reservas/${reserva.idReserva}/no-se-presento`, {}, 'PATCH');
        if (!respuesta.ok) {
            setMensaje(await leerError(respuesta, t("No se pudo cancelar la reserva.")));
            return;
        }
        reemplazar(await respuesta.json());
        setMensaje(t("Reserva {0} cancelada por no presentarse. Le avisamos al hu\u00E9sped por correo.", reserva.codigo));
    }
    const hoy = hoyTexto();
    const enUnMes = new Date();
    enUnMes.setDate(enUnMes.getDate() + 30);
    const activas = reservas.filter((reserva) => reserva.estado === 'CONFIRMADA' && reserva.fechaSalida > hoy);
    const proximasLlegadas = activas.filter((reserva) => reserva.fechaLlegada >= hoy &&
        aFecha(reserva.fechaLlegada) <= enUnMes);
    const ingresos = reservas
        .filter((reserva) => ['CONFIRMADA', 'COMPLETADA'].includes(reserva.estado))
        .reduce((suma, reserva) => suma + Number(reserva.subtotal) + Number(reserva.tarifaLimpieza), 0);
    const pendientes = reservas.filter((reserva) => reserva.estado === 'PENDIENTE_APROBACION');
    const nombre = usuario?.nombre?.split(' ')[0];
    return (<section className="contenedor">
      <div className="panel-cabecera">
        <div>
          <h1 className="titulo-serif">{t("\u00A1Hola, ")}{nombre}!</h1>
          <p className="texto-suave">{t("Comparte tus alojamientos y conecta con viajeros de todo el pa\u00EDs.")}</p>
        </div>
        <div className="viaje-acciones">
          <button type="button" className="boton-secundario" onClick={onCalendario}>{t("\u25A6 Calendario y disponibilidad")}</button>
          <button type="button" className="boton-principal" onClick={onGestionarAlojamientos}>{t("+ Publicar un alojamiento")}</button>
        </div>
      </div>

      {cargando ? (<p className="cargando" role="status">{t("Cargando tu panel...")}</p>) : error ? (<p className="aviso aviso-error" role="alert">
          {t(error)}
        </p>) : (<>
          <div className="estadisticas">
            <article className="tarjeta">
              <span aria-hidden="true">⌂</span>
              <strong>{alojamientos.length}</strong>{t("Mis alojamientos")}</article>
            <article className="tarjeta">
              <span aria-hidden="true">▦</span>
              <strong>{activas.length}</strong>{t("Reservas activas")}</article>
            <article className="tarjeta">
              <span aria-hidden="true">♙</span>
              <strong>{proximasLlegadas.length}</strong>{t("Pr\u00F3ximas llegadas (30 d\u00EDas)")}</article>
            <article className="tarjeta">
              <span aria-hidden="true">▮</span>
              <strong>{pesos(ingresos)}</strong>{t("Ingresos estimados")}</article>
          </div>

          {mensaje && (<p className="aviso" role="status">
              {t(mensaje)}
            </p>)}

          {alojamientos.length === 0 && (<div className="tarjeta vacio">
              <span aria-hidden="true">🏡</span>
              <h2>{t("A\u00FAn no tienes alojamientos publicados")}</h2>
              <p className="texto-suave">{t("Publica tu primer alojamiento y empieza a recibir reservas. Es r\u00E1pido y sencillo.")}</p>
              <button type="button" className="boton-principal" onClick={onGestionarAlojamientos}>{t("+ Publicar un alojamiento")}</button>
              <p className="aviso">{t("Agrega al menos una foto y cambia el estado a \"Activa\" para que los hu\u00E9spedes lo vean.")}</p>
            </div>)}

          {pendientes.length > 0 && (<p className="aviso" role="status">{t("Hay reservas anteriores cuyo pago o disponibilidad necesitan revisi\u00F3n. No requieren que aceptes al hu\u00E9sped. El hu\u00E9sped puede consultar su estado o cancelarlas desde Mis viajes.")}</p>)}

          <article className="tarjeta">
            <div className="tarjeta-titulo">
              <h2>{t("Reservas recibidas")}</h2>
              <button type="button" className="boton-enlace" onClick={onGestionarAlojamientos}>{t("Gestionar mis alojamientos")}</button>
            </div>

            {reservas.length === 0 ? (<p className="texto-suave">{t("Todav\u00EDa no has recibido reservas.")}</p>) : (<ul className="anfitrion-reservas-lista">
                {reservas.map((reserva) => (<li key={reserva.idReserva} className="anfitrion-reserva-tarjeta">
                    <div className="anfitrion-reserva-cabecera">
                      <div>
                        <p className="anfitrion-reserva-codigo">{reserva.codigo}</p>
                        <h3>{reserva.tituloAlojamiento}</h3>
                      </div>
                      <span className={`estado-reserva estado-${reserva.estado.toLowerCase()}`}>
                        {t(NOMBRES_ESTADO_RESERVA[reserva.estado])}
                      </span>
                    </div>
                    <dl className="anfitrion-reserva-datos">
                      <div><dt>{t("Hu\u00E9sped")}</dt><dd>{reserva.nombreHuesped}</dd></div>
                      <div><dt>{t("Fechas")}</dt><dd>
                        {fechaCorta(reserva.fechaLlegada)} – {fechaCorta(reserva.fechaSalida)}
                      </dd></div>
                      <div><dt>{t("Hu\u00E9spedes")}</dt><dd>{reserva.cantidadHuespedes}</dd></div>
                      <div><dt>{t("Total de la reserva")}</dt><dd>{pesos(reserva.total)}</dd></div>
                    </dl>
                    <div className="anfitrion-reserva-checkin">
                      <strong>{t("Check-in: ")}</strong>
                      {reserva.checkInEn ? (<span className="etiqueta-verde">{t("\u2713 Realizado a las")}{' '}{horaBonita(reserva.checkInEn.slice(11, 16))}
                        </span>) : reserva.puedeCancelarNoShow ? (<button type="button" className="boton-peligro" onClick={() => cancelarNoShow(reserva)}>{t("No se present\u00F3")}</button>) : reserva.estado === 'CONFIRMADA' && reserva.horaCheckIn ? (<span>{t("Desde ")}{horaBonita(reserva.horaCheckIn)}</span>) : <span className="texto-suave">{t("Sin registro")}</span>}
                    </div>
                    <div className="viaje-acciones">
                      <button type="button" className="boton-secundario" onClick={() => setChatAbierto(reserva)}>{t("Chat con el hu\u00E9sped")}</button>
                    </div>
                    <div className="anfitrion-reserva-calificacion">
                      <h4>{t("Tu calificaci\u00F3n del hu\u00E9sped")}</h4>
                      <CalificarHuesped reserva={reserva} resena={calificaciones.find((resena) => resena.idReserva === reserva.idReserva)} onGuardada={(resena) => {
                        setCalificaciones((actuales) => [
                            resena,
                            ...actuales.filter((actual) => actual.idReserva !== resena.idReserva),
                        ]);
                        setMensaje(`Calificación del huésped guardada para ${reserva.codigo}.`);
                    }}/>
                    </div>
                  </li>))}
              </ul>)}
          </article>
        </>)}

      {chatAbierto && (<ChatReserva key={chatAbierto.idReserva} reserva={chatAbierto} onCerrar={() => setChatAbierto(null)}/>)}
    </section>);
}
export default PanelAnfitrion;
