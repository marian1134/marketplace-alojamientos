import { t, useIdioma, idiomaActual } from '../idiomas'
import { useCallback, useEffect, useRef, useState } from 'react';
import { loadStripe } from '@stripe/stripe-js';
import { Elements } from '@stripe/react-stripe-js';
import { consultar, enviarDatos, leerError } from '../api';
import TarjetaStripe from './TarjetaStripe';
import { NOMBRES_TIPO } from '../tipos';
import { convertirMoneda, dinero, explicarPolitica, fechaCorta, fotoRespaldo, NOMBRES_POLITICA, plural, pesos, } from '../formato';
const PASOS = [
    { id: 'confirmar', texto: 'Confirmación' },
    { id: 'pago', texto: 'Pago' },
    { id: 'procesando', texto: 'Procesando' },
    { id: 'listo', texto: 'Listo' },
];
const ETAPAS_PROCESO = [
    {
        titulo: 'Verificando disponibilidad',
        texto: 'Confirmando que el alojamiento esté libre en tus fechas.',
    },
    {
        titulo: 'Procesando el pago',
        texto: 'Validando tu tarjeta en el entorno de pruebas.',
    },
    {
        titulo: 'Creando la reserva',
        texto: 'Guardando la información y bloqueando las fechas.',
    },
    {
        titulo: 'Enviando notificación',
        texto: 'Te avisaremos cuando todo esté listo.',
    },
];
// Stripe se carga una sola vez con la clave pública
let promesaStripe = null;
function obtenerStripe(clavePublica) {
    if (!promesaStripe) {
        promesaStripe = loadStripe(clavePublica, { locale: idiomaActual() });
    }
    return promesaStripe;
}
function esperar(milisegundos) {
    return new Promise((resolver) => setTimeout(resolver, milisegundos));
}
// 4242424242424242 -> '4242 4242 4242 4242'
function formatearTarjeta(valor) {
    return valor
        .replace(/\D/g, '')
        .slice(0, 19)
        .replace(/(\d{4})(?=\d)/g, '$1 ');
}
// Fecha MM/AA: el mes solo puede ir de 01 a 12
function formatearExpiracion(valor) {
    let digitos = valor.replace(/\D/g, '').slice(0, 4);
    // "4" se vuelve "04": ningún mes empieza por 2 o más
    if (digitos.length > 0 && Number(digitos[0]) > 1) {
        digitos = `0${digitos}`.slice(0, 4);
    }
    if (digitos.length >= 2) {
        let mes = Number(digitos.slice(0, 2));
        if (mes > 12)
            mes = 12;
        if (mes === 0)
            mes = 1;
        digitos = String(mes).padStart(2, '0') + digitos.slice(2);
    }
    if (digitos.length <= 2) {
        return digitos;
    }
    return `${digitos.slice(0, 2)}/${digitos.slice(2)}`;
}
// ¿La tarjeta MM/AA ya venció?
function expiracionInvalida(texto) {
    if (!/^(0[1-9]|1[0-2])\/\d{2}$/.test(texto)) {
        return t("Escribe la fecha de expiraci\u00F3n como MM/AA.");
    }
    const mes = Number(texto.slice(0, 2));
    const anio = 2000 + Number(texto.slice(3));
    const hoy = new Date();
    const actual = hoy.getFullYear() * 12 + hoy.getMonth() + 1;
    const tarjeta = anio * 12 + mes;
    if (tarjeta < actual) {
        return t("La tarjeta est\u00E1 vencida.");
    }
    if (tarjeta > actual + 20 * 12) {
        return t("La fecha de expiraci\u00F3n no es v\u00E1lida.");
    }
    return '';
}
function Pasos({ actual }) {
    useIdioma();
    const indiceActual = PASOS.findIndex((paso) => paso.id === actual);
    return (<ol className="pasos">
      <li className="hecho">
        <span>✓</span>{t("Alojamiento")}</li>
      <li className="hecho">
        <span>✓</span>{t("Fechas y hu\u00E9spedes")}</li>
      {PASOS.map((paso, indice) => (<li key={paso.id} className={indice < indiceActual
                ? 'hecho'
                : indice === indiceActual
                    ? 'actual'
                    : ''} aria-current={indice === indiceActual ? 'step' : undefined}>
          <span>{indice < indiceActual ? '✓' : indice + 3}</span>
          {t(paso.texto)}
        </li>))}
    </ol>);
}
function Resumen({ alojamiento, imagen, entrada, salida, huespedes, precio, politica }) {
    useIdioma();
    return (<aside className="tarjeta resumen-lateral">
      {imagen ? (<img src={imagen} alt={t(t("Foto de {0}", alojamiento.titulo))} onError={fotoRespaldo}/>) : (<div className="sin-foto sin-foto-baja">⌂</div>)}

      <div className="resumen-contenido">
        <h3>{alojamiento.titulo}</h3>
        <p className="texto-suave">
          ⌖ {alojamiento.ciudad} ·{' '}
          {t(NOMBRES_TIPO[alojamiento.tipoAlojamiento])} ·{' '}
          {plural(alojamiento.habitaciones ?? 1, t("habitaci\u00F3n"), t("habitaciones"))} ·{' '}
          {plural(alojamiento.banos ?? 1, t("ba\u00F1o"), t("ba\u00F1os"))}
        </p>

        <h4>{t("Tu reserva")}</h4>
        <dl className="desglose desglose-compacto">
          <div>
            <dt>{t("Fechas")}</dt>
            <dd>
              {fechaCorta(entrada)} – {fechaCorta(salida)} (
              {precio.noches}{' '}
              {precio.noches === 1 ? t("noche") : t("noches")})
            </dd>
          </div>
          <div>
            <dt>{t("Hu\u00E9spedes")}</dt>
            <dd>{huespedes}</dd>
          </div>
          <div>
            <dt>{t("Cancelaci\u00F3n")}</dt>
            <dd>{t(NOMBRES_POLITICA[politica.tipo])}</dd>
          </div>
        </dl>

        <h4>{t("Resumen del precio")}</h4>
        <DesglosePrecio precio={precio}/>

        <div className="reserva-segura">
          <strong>{t("Estad\u00EDa segura y confiable")}</strong>
          <ul>
            <li>{t("\u2713 Alojamientos verificados")}</li>
            <li>{t("\u2713 Pagos seguros (modo de prueba)")}</li>
            <li>{t("\u2713 Soporte en todo momento")}</li>
          </ul>
        </div>
      </div>
    </aside>);
}
function DesglosePrecio({ precio }) {
    useIdioma();
    return (<dl className="desglose">
      <div>
        <dt>{t("Precio por noche")}{' '}
          <span className="texto-suave">
            {pesos(precio.precioNoche)} x {precio.noches}
          </span>
        </dt>
        <dd>{pesos(precio.subtotal)}</dd>
      </div>
      <div>
        <dt>{t("Tarifa de limpieza")}</dt>
        <dd>{pesos(precio.tarifaLimpieza)}</dd>
      </div>
      <div>
        <dt>{t("Tarifa de servicio")}</dt>
        <dd>{pesos(precio.tarifaServicio)}</dd>
      </div>
      <div className="descuento">
        <dt>{t("Descuento")}</dt>
        <dd>
          {Number(precio.descuentos) > 0 ? '-' : ''}
          {pesos(precio.descuentos)}
        </dd>
      </div>
      <div className="total">
        <dt>{t("Total")}</dt>
        <dd>{pesos(precio.total)}</dd>
      </div>
    </dl>);
}
function Reservar({ reserva: solicitud, onVolver, onVerViajes, onExplorar, }) {
    useIdioma();
    const { detalle, entrada, salida, huespedes, cotizacion } = solicitud;
    const { alojamiento, politica } = detalle;
    const imagen = detalle.imagenes[0]?.urlImagen;
    const [paso, setPaso] = useState('confirmar');
    const [tarjeta, setTarjeta] = useState({
        numero: '',
        titular: '',
        expiracion: '',
        cvc: '',
    });
    const [acepta, setAcepta] = useState(false);
    const [mensaje, setMensaje] = useState('');
    const [etapa, setEtapa] = useState(0);
    const [reserva, setReserva] = useState(null);
    const [copiado, setCopiado] = useState(false);
    // Una sola clave por intento: si hay doble clic no se crean dos reservas
    const [clave] = useState(() => crypto.randomUUID());
    // Configuración del pago: si Stripe está activo y la tasa del dólar
    const [configuracion, setConfiguracion] = useState({
        stripeActivo: false,
        tasaUsd: 4000,
    });
    const [moneda, setMoneda] = useState('COP');
    const [pagando, setPagando] = useState(false);
    const stripeListo = useRef(null);
    const usaStripe = Boolean(configuracion.stripeActivo && configuracion.clavePublica);
    const totalCobrar = convertirMoneda(cotizacion.total, moneda, configuracion.tasaUsd);
    const guardarStripe = useCallback((datos) => {
        stripeListo.current = datos;
    }, []);
    useEffect(() => {
        let activo = true;
        consultar('/api/v1/pagos/configuracion')
            .then((respuesta) => (respuesta.ok ? respuesta.json() : null))
            .then((datos) => {
            if (activo && datos) {
                setConfiguracion(datos);
            }
        })
            .catch(() => { });
        return () => {
            activo = false;
        };
    }, []);
    useEffect(() => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }, [paso]);
    function cambiarTarjeta(evento) {
        const { name, value } = evento.target;
        let valor = value;
        if (name === 'numero')
            valor = formatearTarjeta(value);
        if (name === 'expiracion')
            valor = formatearExpiracion(value);
        if (name === 'cvc')
            valor = value.replace(/\D/g, '').slice(0, 3);
        setTarjeta({ ...tarjeta, [name]: valor });
        setMensaje('');
    }
    async function pagar(evento) {
        evento.preventDefault();
        if (!tarjeta.titular.trim()) {
            setMensaje(t("Escribe el nombre del titular de la tarjeta."));
            return;
        }
        if (!usaStripe) {
            const numero = tarjeta.numero.replace(/\D/g, '');
            if (numero.length < 13) {
                setMensaje(t("El n\u00FAmero de tarjeta debe tener entre 13 y 19 d\u00EDgitos."));
                return;
            }
            const errorFecha = expiracionInvalida(tarjeta.expiracion);
            if (errorFecha) {
                setMensaje(errorFecha);
                return;
            }
            if (tarjeta.cvc.length !== 3) {
                setMensaje(t("El CVC debe tener 3 d\u00EDgitos."));
                return;
            }
        }
        if (!acepta) {
            setMensaje(t("Debes aceptar los t\u00E9rminos y condiciones."));
            return;
        }
        setMensaje('');
        const datosReserva = {
            idAlojamiento: alojamiento.idAlojamiento,
            fechaLlegada: entrada,
            fechaSalida: salida,
            cantidadHuespedes: huespedes,
            claveIdempotencia: clave,
            moneda,
        };
        // Con Stripe: primero se cobra la tarjeta en Stripe
        let idIntencionPago = null;
        if (usaStripe) {
            if (!stripeListo.current) {
                setMensaje(t("El formulario de pago a\u00FAn est\u00E1 cargando. Intenta de nuevo."));
                return;
            }
            setPagando(true);
            try {
                const respuestaIntencion = await enviarDatos('/api/v1/pagos/intencion', datosReserva);
                if (!respuestaIntencion.ok) {
                    setMensaje(await leerError(respuestaIntencion, t("No se pudo iniciar el pago.")));
                    return;
                }
                const intencion = await respuestaIntencion.json();
                const { stripe, elements, CardElement } = stripeListo.current;
                const resultado = await stripe.confirmCardPayment(intencion.clientSecret, {
                    payment_method: {
                        card: elements.getElement(CardElement),
                        billing_details: { name: tarjeta.titular },
                    },
                });
                if (resultado.error) {
                    setMensaje(resultado.error.message);
                    return;
                }
                idIntencionPago = resultado.paymentIntent.id;
            }
            catch {
                setMensaje(t("No se pudo conectar con Stripe. Intenta nuevamente."));
                return;
            }
            finally {
                setPagando(false);
            }
        }
        setEtapa(0);
        setPaso('procesando');
        // Las etapas se muestran mientras el backend responde
        const animacion = (async () => {
            for (let indice = 1; indice <= ETAPAS_PROCESO.length; indice++) {
                await esperar(700);
                setEtapa(indice);
            }
        })();
        try {
            const respuesta = await enviarDatos('/api/v1/reservas', usaStripe
                ? { ...datosReserva, idIntencionPago, titular: tarjeta.titular }
                : {
                    ...datosReserva,
                    numeroTarjeta: tarjeta.numero,
                    titular: tarjeta.titular,
                    expiracion: tarjeta.expiracion,
                    cvc: tarjeta.cvc,
                });
            if (!respuesta.ok) {
                const error = await leerError(respuesta, t("No se pudo completar la reserva. Intenta nuevamente."));
                await esperar(900);
                setMensaje(error);
                setPaso('pago');
                return;
            }
            const creada = await respuesta.json();
            await animacion;
            setReserva(creada);
            setPaso('listo');
        }
        catch {
            setMensaje(t("No se pudo conectar con el servidor. Revisa que el backend est\u00E9 funcionando."));
            setPaso('pago');
        }
    }
    async function copiarCodigo() {
        try {
            await navigator.clipboard.writeText(reserva.codigo);
            setCopiado(true);
            setTimeout(() => setCopiado(false), 2000);
        }
        catch {
            setCopiado(false);
        }
    }
    const resumen = (<Resumen alojamiento={alojamiento} imagen={imagen} entrada={entrada} salida={salida} huespedes={huespedes} precio={reserva ?? cotizacion} politica={politica}/>);
    return (<section className="contenedor flujo-reserva">
      <div className="flujo-cabecera">
        {paso !== 'procesando' && paso !== 'listo' && (<button type="button" className="boton-volver" onClick={() => paso === 'pago' ? setPaso('confirmar') : onVolver()}>{t("\u2190 Volver")}</button>)}
        <Pasos actual={paso}/>
      </div>

      {paso === 'confirmar' && (<div className="flujo-columnas">
          <div>
            <h1 className="titulo-serif">{t("Confirma tu reserva")}</h1>
            <p className="texto-suave">{t("Revisa el detalle de tu estancia y la cotizaci\u00F3n antes de continuar al pago.")}</p>

            <article className="tarjeta">
              <div className="tarjeta-titulo">
                <h2>{t("Detalle de la reserva")}</h2>
                <button type="button" className="boton-enlace" onClick={onVolver}>{t("Editar")}</button>
              </div>

              <div className="reserva-alojamiento">
                {imagen ? (<img src={imagen} alt="" onError={fotoRespaldo}/>) : (<div className="sin-foto sin-foto-baja">⌂</div>)}
                <div>
                  <h3>{alojamiento.titulo}</h3>
                  <p className="texto-suave">⌖ {alojamiento.ciudad}</p>
                  <p className="texto-suave">
                    {t(NOMBRES_TIPO[alojamiento.tipoAlojamiento])} ·{' '}
                    {plural(alojamiento.habitaciones ?? 1, t("habitaci\u00F3n"), t("habitaciones"))} ·{' '}
                    {plural(alojamiento.banos ?? 1, t("ba\u00F1o"), t("ba\u00F1os"))}{t(" \u00B7 Hasta")}{' '}
                    {alojamiento.capacidad}{t("hu\u00E9spedes")}</p>
                </div>
              </div>

              <div className="reserva-datos">
                <div>
                  <strong>{t("Fechas")}</strong>
                  <p>
                    {fechaCorta(entrada)} – {fechaCorta(salida)}
                  </p>
                  <p className="texto-suave">
                    {cotizacion.noches}{' '}
                    {cotizacion.noches === 1 ? t("noche") : t("noches")}
                  </p>
                </div>
                <div>
                  <strong>{t("Hu\u00E9spedes")}</strong>
                  <p>
                    {huespedes}{' '}
                    {huespedes === 1 ? t("hu\u00E9sped") : t("hu\u00E9spedes")}
                  </p>
                </div>
                <div>
                  <strong>{t("Pol\u00EDtica de cancelaci\u00F3n")}</strong>
                  <p>{t(NOMBRES_POLITICA[politica.tipo])}</p>
                  <p className="texto-suave">
                    {explicarPolitica(politica, entrada)}
                  </p>
                </div>
              </div>
            </article>

            <article className="tarjeta">
              <div className="tarjeta-titulo">
                <h2>{t("Resumen del precio")}</h2>
                <span className="etiqueta-verde">{t("\u2713 Las fechas siguen disponibles")}</span>
              </div>

              <DesglosePrecio precio={cotizacion}/>

              <p className="aviso">{t("El precio puede variar si cambias las fechas o la cantidad de hu\u00E9spedes. Las tarifas est\u00E1n incluidas en el total.")}</p>
            </article>

            <button type="button" className="boton-principal boton-ancho" onClick={() => setPaso('pago')}>{t("Continuar al pago \u2192")}</button>
          </div>

          {resumen}
        </div>)}

      {paso === 'pago' && (<div className="flujo-columnas">
          <form onSubmit={pagar} className="formulario-pago">
            <h1 className="titulo-serif">{t("M\u00E9todo de pago")}</h1>
            <p className="texto-suave">{t("Ingresa la informaci\u00F3n de tu tarjeta para completar la reserva.")}</p>

            <article className="tarjeta">
              <div className="tarjeta-titulo">
                <div>
                  <h2>{t("Tarjeta de cr\u00E9dito o d\u00E9bito")}</h2>
                  <p className="texto-suave">{t("Pago seguro con nuestro proveedor de pagos.")}</p>
                </div>
                <span className="marcas-tarjeta" aria-hidden="true">{t("VISA \u00B7 Mastercard \u00B7 AMEX")}</span>
              </div>

              <fieldset className="elegir-moneda">
                <legend>{t("\u00BFEn qu\u00E9 moneda quieres pagar?")}</legend>

                {[
                ['COP', t("Pesos colombianos")],
                ['USD', t("D\u00F3lares estadounidenses")],
            ].map(([codigo, nombre]) => (<label key={codigo} className={moneda === codigo ? 'activa' : ''}>
                    <input type="radio" name="moneda" value={codigo} checked={moneda === codigo} onChange={() => {
                    setMoneda(codigo);
                    setMensaje('');
                }}/>
                    <span>
                      <strong>{t(nombre)} ({codigo})</strong>
                      {dinero(convertirMoneda(cotizacion.total, codigo, configuracion.tasaUsd), codigo)}
                    </span>
                  </label>))}

                {moneda === 'USD' && (<p className="texto-suave">{t("Tasa usada: 1 USD =")}{pesos(configuracion.tasaUsd)}
                  </p>)}
              </fieldset>

              <label>{t("Nombre del titular")}<input name="titular" autoComplete="cc-name" placeholder={t("Tu nombre completo")} maxLength={100} value={tarjeta.titular} onChange={cambiarTarjeta} required/>
              </label>

              {usaStripe ? (<div className="campo-bloque-stripe">
                  <span>{t("Datos de la tarjeta")}</span>
                  <Elements stripe={obtenerStripe(configuracion.clavePublica)} options={{ locale: idiomaActual() }}>
                    <TarjetaStripe onListo={guardarStripe} onCambio={(error) => setMensaje(error)}/>
                  </Elements>
                </div>) : (<>
                  <label>{t("N\u00FAmero de tarjeta")}<input name="numero" inputMode="numeric" autoComplete="cc-number" placeholder="1234 5678 9012 3456" value={tarjeta.numero} onChange={cambiarTarjeta} required/>
                  </label>

                  <div className="dos-columnas">
                    <label>{t("Fecha de expiraci\u00F3n")}<input name="expiracion" inputMode="numeric" autoComplete="cc-exp" placeholder={t("MM/AA")} maxLength={5} value={tarjeta.expiracion} onChange={cambiarTarjeta} required/>
                    </label>

                    <label>
                      CVC
                      <input name="cvc" inputMode="numeric" autoComplete="cc-csc" placeholder="123" maxLength={3} value={tarjeta.cvc} onChange={cambiarTarjeta} required/>
                    </label>
                  </div>
                </>)}

              <label className="casilla">
                <input type="checkbox" checked={acepta} onChange={(evento) => {
                setAcepta(evento.target.checked);
                setMensaje('');
            }}/>{t("Acepto los t\u00E9rminos y condiciones de StayHub y la pol\u00EDtica de privacidad.")}</label>

              {mensaje && (<p className="aviso aviso-error" role="alert">
                  {t(mensaje)}
                </p>)}

              <button type="submit" className="boton-principal boton-ancho" disabled={pagando}>
                {pagando
                ? t("Procesando el pago...") : t("Confirmar y reservar \u2014 {0} \u2192", dinero(totalCobrar, moneda))}
              </button>

              <p className="nota-centro">
                {usaStripe
                ? t("\uD83D\uDD12 Pago procesado por Stripe. Los datos de tu tarjeta van directo a Stripe; solo guardamos los \u00FAltimos 4 d\u00EDgitos.") : t("\uD83D\uDD12 Tu informaci\u00F3n de pago est\u00E1 protegida. Solo guardamos los \u00FAltimos 4 d\u00EDgitos.")}
              </p>
            </article>
          </form>

          {resumen}
        </div>)}

      {paso === 'procesando' && (<div className="flujo-columnas">
          <div>
            <h1 className="titulo-serif">{t("Procesando tu reserva...")}</h1>
            <p className="texto-suave">{t("Estamos verificando la disponibilidad, procesando el pago y creando tu reserva.")}</p>

            <article className="tarjeta" aria-live="polite">
              <ul className="etapas">
                {ETAPAS_PROCESO.map((item, indice) => (<li key={item.titulo} className={indice < etapa
                    ? 'hecha'
                    : indice === etapa
                        ? 'en-curso'
                        : ''}>
                    <span className="etapa-icono" aria-hidden="true">
                      {indice < etapa ? '✓' : ''}
                    </span>
                    <div>
                      <strong>{t(item.titulo)}</strong>
                      <p className="texto-suave">{t(item.texto)}</p>
                    </div>
                  </li>))}
              </ul>

              <p className="aviso">{t("Este proceso puede tardar unos segundos. No cierres la ventana.")}</p>
            </article>
          </div>

          {resumen}
        </div>)}

      {paso === 'listo' && reserva && (<div className="flujo-columnas">
          <div>
            <div className="confirmada-cabecera">
              <span className="check-grande" aria-hidden="true">✓</span>
              <h1 className="titulo-serif">
                {reserva.estado === 'CONFIRMADA' ? t("\u00A1Reserva confirmada!") : t("Reserva registrada")}
              </h1>
              <p className="texto-suave">
                {reserva.estado === 'CONFIRMADA'
                ? t("Tu estad\u00EDa en {0} qued\u00F3 confirmada autom\u00E1ticamente al completar el pago.", reserva.tituloAlojamiento) : t("Consulta el estado actualizado de tu reserva en Mis viajes.")}
              </p>
            </div>

            <article className="tarjeta">
              <div className="confirmada-datos">
                <div>
                  <span className="texto-suave">{t("C\u00F3digo de reserva")}</span>
                  <button type="button" className="codigo-reserva" onClick={copiarCodigo} title={t("Copiar c\u00F3digo")}>
                    {reserva.codigo} {copiado ? t("\u2713 Copiado") : '⧉'}
                  </button>
                </div>
                <div>
                  <span className="texto-suave">{t("Estado")}</span>
                  <span className={`estado-reserva estado-${reserva.estado.toLowerCase()}`}>
                    {reserva.estado === 'CONFIRMADA' ? t("\u2713 Confirmada") : t("Consulta Mis viajes")}
                  </span>
                </div>
              </div>

              <div className="reserva-datos">
                <div>
                  <strong>{t("Fechas")}</strong>
                  <p>
                    {fechaCorta(reserva.fechaLlegada)} –{' '}
                    {fechaCorta(reserva.fechaSalida)}
                  </p>
                  <p className="texto-suave">
                    {reserva.noches}{' '}
                    {reserva.noches === 1 ? t("noche") : t("noches")}
                  </p>
                </div>
                <div>
                  <strong>{t("Hu\u00E9spedes")}</strong>
                  <p>{reserva.cantidadHuespedes}</p>
                </div>
                <div>
                  <strong>{t("M\u00E9todo de pago")}</strong>
                  <p>{t("Tarjeta terminada en ")}{reserva.ultimos4}</p>
                </div>
              </div>

              <p className="total-pagado">
                <span className="texto-suave">{t("Total pagado")}</span>
                <strong>
                  {dinero(reserva.montoPagado ?? reserva.total, reserva.monedaPago)}
                </strong>
              </p>
            </article>

            <div className="botones-final">
              <button type="button" className="boton-principal" onClick={onVerViajes}>{t("Ver mis viajes \u2192")}</button>
              <button type="button" className="boton-secundario" onClick={onExplorar}>{t("Volver a explorar alojamientos")}</button>
            </div>
          </div>

          <aside className="tarjeta que-sigue">
            <h3>{t("\u00BFQu\u00E9 sigue?")}</h3>
            <ol>
              <li>
                <strong>
                  {reserva.estado === 'CONFIRMADA' ? t("Reserva confirmada") : t("Revisa tu reserva")}
                </strong>
                <p className="texto-suave">
                  {reserva.estado === 'CONFIRMADA'
                ? t("Tu pago fue procesado y las fechas ya est\u00E1n bloqueadas. No necesitas esperar la aprobaci\u00F3n del anfitri\u00F3n.") : t("Abre Mis viajes para consultar la informaci\u00F3n de tu reserva.")}
                </p>
              </li>
              <li>
                <strong>{t("Gestiona tu reserva")}</strong>
                <p className="texto-suave">{t("Puedes verla o cancelarla desde")}<em>{t("Mis viajes")}</em>.
                </p>
              </li>
              <li>
                <strong>{t("Pol\u00EDtica de cancelaci\u00F3n")}</strong>
                <p className="texto-suave">
                  {t(NOMBRES_POLITICA[politica.tipo])}.{' '}
                  {explicarPolitica(politica, entrada)}
                </p>
              </li>
            </ol>
          </aside>
        </div>)}
    </section>);
}
export default Reservar;
