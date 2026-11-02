import { useEffect, useState } from 'react'
import { enviarDatos, leerError } from '../api'
import { NOMBRES_TIPO } from '../tipos'
import {
  explicarPolitica,
  fechaCorta,
  fotoRespaldo,
  NOMBRES_POLITICA,
  pesos,
} from '../formato'

const PASOS = [
  { id: 'confirmar', texto: 'Confirmación' },
  { id: 'pago', texto: 'Pago' },
  { id: 'procesando', texto: 'Procesando' },
  { id: 'listo', texto: 'Listo' },
]

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
]

function esperar(milisegundos) {
  return new Promise((resolver) =>
    setTimeout(resolver, milisegundos)
  )
}

// 4242424242424242 -> '4242 4242 4242 4242'
function formatearTarjeta(valor) {
  return valor
    .replace(/\D/g, '')
    .slice(0, 19)
    .replace(/(\d{4})(?=\d)/g, '$1 ')
}

function formatearExpiracion(valor) {
  const digitos = valor.replace(/\D/g, '').slice(0, 4)

  if (digitos.length <= 2) {
    return digitos
  }

  return `${digitos.slice(0, 2)}/${digitos.slice(2)}`
}

function Pasos({ actual }) {
  const indiceActual = PASOS.findIndex((paso) => paso.id === actual)

  return (
    <ol className="pasos">
      <li className="hecho">
        <span>✓</span> Alojamiento
      </li>
      <li className="hecho">
        <span>✓</span> Fechas y huéspedes
      </li>
      {PASOS.map((paso, indice) => (
        <li
          key={paso.id}
          className={
            indice < indiceActual
              ? 'hecho'
              : indice === indiceActual
                ? 'actual'
                : ''
          }
          aria-current={indice === indiceActual ? 'step' : undefined}
        >
          <span>{indice < indiceActual ? '✓' : indice + 3}</span>
          {paso.texto}
        </li>
      ))}
    </ol>
  )
}

function Resumen({ alojamiento, imagen, entrada, salida, huespedes, precio, politica }) {
  return (
    <aside className="tarjeta resumen-lateral">
      {imagen ? (
        <img
          src={imagen}
          alt={`Foto de ${alojamiento.titulo}`}
          onError={fotoRespaldo}
        />
      ) : (
        <div className="sin-foto sin-foto-baja">⌂</div>
      )}

      <div className="resumen-contenido">
        <h3>{alojamiento.titulo}</h3>
        <p className="texto-suave">
          ⌖ {alojamiento.ciudad} ·{' '}
          {NOMBRES_TIPO[alojamiento.tipoAlojamiento]}
        </p>

        <h4>Tu reserva</h4>
        <dl className="desglose desglose-compacto">
          <div>
            <dt>Fechas</dt>
            <dd>
              {fechaCorta(entrada)} – {fechaCorta(salida)} (
              {precio.noches}{' '}
              {precio.noches === 1 ? 'noche' : 'noches'})
            </dd>
          </div>
          <div>
            <dt>Huéspedes</dt>
            <dd>{huespedes}</dd>
          </div>
          <div>
            <dt>Cancelación</dt>
            <dd>{NOMBRES_POLITICA[politica.tipo]}</dd>
          </div>
        </dl>

        <h4>Resumen del precio</h4>
        <DesglosePrecio precio={precio} />

        <div className="reserva-segura">
          <strong>Estadía segura y confiable</strong>
          <ul>
            <li>✓ Alojamientos verificados</li>
            <li>✓ Pagos seguros (modo de prueba)</li>
            <li>✓ Soporte en todo momento</li>
          </ul>
        </div>
      </div>
    </aside>
  )
}

function DesglosePrecio({ precio }) {
  return (
    <dl className="desglose">
      <div>
        <dt>
          Precio por noche{' '}
          <span className="texto-suave">
            {pesos(precio.precioNoche)} x {precio.noches}
          </span>
        </dt>
        <dd>{pesos(precio.subtotal)}</dd>
      </div>
      <div>
        <dt>Tarifa de limpieza</dt>
        <dd>{pesos(precio.tarifaLimpieza)}</dd>
      </div>
      <div>
        <dt>Tarifa de servicio</dt>
        <dd>{pesos(precio.tarifaServicio)}</dd>
      </div>
      <div className="descuento">
        <dt>Descuento</dt>
        <dd>
          {Number(precio.descuentos) > 0 ? '-' : ''}
          {pesos(precio.descuentos)}
        </dd>
      </div>
      <div className="total">
        <dt>Total</dt>
        <dd>{pesos(precio.total)}</dd>
      </div>
    </dl>
  )
}

function Reservar({
  reserva: solicitud,
  onVolver,
  onVerViajes,
  onExplorar,
}) {
  const { detalle, entrada, salida, huespedes, cotizacion } = solicitud
  const { alojamiento, politica } = detalle
  const imagen = detalle.imagenes[0]?.urlImagen

  const [paso, setPaso] = useState('confirmar')
  const [tarjeta, setTarjeta] = useState({
    numero: '',
    titular: '',
    expiracion: '',
    cvc: '',
  })
  const [acepta, setAcepta] = useState(false)
  const [mensaje, setMensaje] = useState('')
  const [etapa, setEtapa] = useState(0)
  const [reserva, setReserva] = useState(null)
  const [copiado, setCopiado] = useState(false)

  // Una sola clave por intento: si hay doble clic no se crean dos reservas
  const [clave] = useState(() => crypto.randomUUID())

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }, [paso])

  function cambiarTarjeta(evento) {
    const { name, value } = evento.target
    let valor = value

    if (name === 'numero') valor = formatearTarjeta(value)
    if (name === 'expiracion') valor = formatearExpiracion(value)
    if (name === 'cvc') valor = value.replace(/\D/g, '').slice(0, 4)

    setTarjeta({ ...tarjeta, [name]: valor })
    setMensaje('')
  }

  async function pagar(evento) {
    evento.preventDefault()

    if (!acepta) {
      setMensaje('Debes aceptar los términos y condiciones.')
      return
    }

    setMensaje('')
    setEtapa(0)
    setPaso('procesando')

    // Las etapas se muestran mientras el backend responde
    const animacion = (async () => {
      for (let indice = 1; indice <= ETAPAS_PROCESO.length; indice++) {
        await esperar(700)
        setEtapa(indice)
      }
    })()

    try {
      const respuesta = await enviarDatos('/api/v1/reservas', {
        idAlojamiento: alojamiento.idAlojamiento,
        fechaLlegada: entrada,
        fechaSalida: salida,
        cantidadHuespedes: huespedes,
        claveIdempotencia: clave,
        numeroTarjeta: tarjeta.numero,
        titular: tarjeta.titular,
        expiracion: tarjeta.expiracion,
        cvc: tarjeta.cvc,
      })

      if (!respuesta.ok) {
        const error = await leerError(
          respuesta,
          'No se pudo completar la reserva. Intenta nuevamente.'
        )
        await esperar(900)
        setMensaje(error)
        setPaso('pago')
        return
      }

      const creada = await respuesta.json()
      await animacion
      setReserva(creada)
      setPaso('listo')
    } catch {
      setMensaje(
        'No se pudo conectar con el servidor. Revisa que el backend esté funcionando.'
      )
      setPaso('pago')
    }
  }

  async function copiarCodigo() {
    try {
      await navigator.clipboard.writeText(reserva.codigo)
      setCopiado(true)
      setTimeout(() => setCopiado(false), 2000)
    } catch {
      setCopiado(false)
    }
  }

  const resumen = (
    <Resumen
      alojamiento={alojamiento}
      imagen={imagen}
      entrada={entrada}
      salida={salida}
      huespedes={huespedes}
      precio={reserva ?? cotizacion}
      politica={politica}
    />
  )

  return (
    <section className="contenedor flujo-reserva">
      <div className="flujo-cabecera">
        {paso !== 'procesando' && paso !== 'listo' && (
          <button
            type="button"
            className="boton-volver"
            onClick={() =>
              paso === 'pago' ? setPaso('confirmar') : onVolver()
            }
          >
            ← Volver
          </button>
        )}
        <Pasos actual={paso} />
      </div>

      {paso === 'confirmar' && (
        <div className="flujo-columnas">
          <div>
            <h1 className="titulo-serif">Confirma tu reserva</h1>
            <p className="texto-suave">
              Revisa el detalle de tu estancia y la cotización antes de
              continuar al pago.
            </p>

            <article className="tarjeta">
              <div className="tarjeta-titulo">
                <h2>Detalle de la reserva</h2>
                <button
                  type="button"
                  className="boton-enlace"
                  onClick={onVolver}
                >
                  Editar
                </button>
              </div>

              <div className="reserva-alojamiento">
                {imagen ? (
                  <img src={imagen} alt="" onError={fotoRespaldo} />
                ) : (
                  <div className="sin-foto sin-foto-baja">⌂</div>
                )}
                <div>
                  <h3>{alojamiento.titulo}</h3>
                  <p className="texto-suave">⌖ {alojamiento.ciudad}</p>
                  <p className="texto-suave">
                    {NOMBRES_TIPO[alojamiento.tipoAlojamiento]} · Hasta{' '}
                    {alojamiento.capacidad} huéspedes
                  </p>
                </div>
              </div>

              <div className="reserva-datos">
                <div>
                  <strong>Fechas</strong>
                  <p>
                    {fechaCorta(entrada)} – {fechaCorta(salida)}
                  </p>
                  <p className="texto-suave">
                    {cotizacion.noches}{' '}
                    {cotizacion.noches === 1 ? 'noche' : 'noches'}
                  </p>
                </div>
                <div>
                  <strong>Huéspedes</strong>
                  <p>
                    {huespedes}{' '}
                    {huespedes === 1 ? 'huésped' : 'huéspedes'}
                  </p>
                </div>
                <div>
                  <strong>Política de cancelación</strong>
                  <p>{NOMBRES_POLITICA[politica.tipo]}</p>
                  <p className="texto-suave">
                    {explicarPolitica(politica)}
                  </p>
                </div>
              </div>
            </article>

            <article className="tarjeta">
              <div className="tarjeta-titulo">
                <h2>Resumen del precio</h2>
                <span className="etiqueta-verde">
                  ✓ Las fechas siguen disponibles
                </span>
              </div>

              <DesglosePrecio precio={cotizacion} />

              <p className="aviso">
                El precio puede variar si cambias las fechas o la
                cantidad de huéspedes. Las tarifas están incluidas en
                el total.
              </p>
            </article>

            <button
              type="button"
              className="boton-principal boton-ancho"
              onClick={() => setPaso('pago')}
            >
              Continuar al pago →
            </button>
          </div>

          {resumen}
        </div>
      )}

      {paso === 'pago' && (
        <div className="flujo-columnas">
          <form onSubmit={pagar} className="formulario-pago">
            <h1 className="titulo-serif">Método de pago</h1>
            <p className="texto-suave">
              Ingresa la información de tu tarjeta para completar la
              reserva.
            </p>

            <article className="tarjeta">
              <div className="tarjeta-titulo">
                <div>
                  <h2>Tarjeta de crédito o débito</h2>
                  <p className="texto-suave">
                    Pago seguro con nuestro proveedor de pagos.
                  </p>
                </div>
                <span className="marcas-tarjeta" aria-hidden="true">
                  VISA · Mastercard · AMEX
                </span>
              </div>

              <label>
                Número de tarjeta
                <input
                  name="numero"
                  inputMode="numeric"
                  autoComplete="cc-number"
                  placeholder="1234 5678 9012 3456"
                  value={tarjeta.numero}
                  onChange={cambiarTarjeta}
                  required
                />
              </label>

              <label>
                Nombre del titular
                <input
                  name="titular"
                  autoComplete="cc-name"
                  placeholder="Tu nombre completo"
                  maxLength={100}
                  value={tarjeta.titular}
                  onChange={cambiarTarjeta}
                  required
                />
              </label>

              <div className="dos-columnas">
                <label>
                  Fecha de expiración
                  <input
                    name="expiracion"
                    inputMode="numeric"
                    autoComplete="cc-exp"
                    placeholder="MM/AA"
                    value={tarjeta.expiracion}
                    onChange={cambiarTarjeta}
                    required
                  />
                </label>

                <label>
                  CVC
                  <input
                    name="cvc"
                    inputMode="numeric"
                    autoComplete="cc-csc"
                    placeholder="123"
                    value={tarjeta.cvc}
                    onChange={cambiarTarjeta}
                    required
                  />
                </label>
              </div>

              <label className="casilla">
                <input
                  type="checkbox"
                  checked={acepta}
                  onChange={(evento) => {
                    setAcepta(evento.target.checked)
                    setMensaje('')
                  }}
                />
                Acepto los términos y condiciones de StayHub y la
                política de privacidad.
              </label>

              {mensaje && (
                <p className="aviso aviso-error" role="alert">
                  {mensaje}
                </p>
              )}

              <button
                type="submit"
                className="boton-principal boton-ancho"
              >
                Confirmar y reservar — {pesos(cotizacion.total)} →
              </button>

              <p className="nota-centro">
                🔒 Tu información de pago está protegida. Solo guardamos
                los últimos 4 dígitos.
              </p>
            </article>
          </form>

          {resumen}
        </div>
      )}

      {paso === 'procesando' && (
        <div className="flujo-columnas">
          <div>
            <h1 className="titulo-serif">Procesando tu reserva...</h1>
            <p className="texto-suave">
              Estamos verificando la disponibilidad, procesando el pago
              y creando tu reserva.
            </p>

            <article className="tarjeta" aria-live="polite">
              <ul className="etapas">
                {ETAPAS_PROCESO.map((item, indice) => (
                  <li
                    key={item.titulo}
                    className={
                      indice < etapa
                        ? 'hecha'
                        : indice === etapa
                          ? 'en-curso'
                          : ''
                    }
                  >
                    <span className="etapa-icono" aria-hidden="true">
                      {indice < etapa ? '✓' : ''}
                    </span>
                    <div>
                      <strong>{item.titulo}</strong>
                      <p className="texto-suave">{item.texto}</p>
                    </div>
                  </li>
                ))}
              </ul>

              <p className="aviso">
                Este proceso puede tardar unos segundos. No cierres la
                ventana.
              </p>
            </article>
          </div>

          {resumen}
        </div>
      )}

      {paso === 'listo' && reserva && (
        <div className="flujo-columnas">
          <div>
            <div className="confirmada-cabecera">
              <span className="check-grande" aria-hidden="true">✓</span>
              <h1 className="titulo-serif">
                {reserva.estado === 'PENDIENTE_APROBACION'
                  ? '¡Solicitud enviada!'
                  : '¡Reserva confirmada!'}
              </h1>
              <p className="texto-suave">
                {reserva.estado === 'PENDIENTE_APROBACION'
                  ? `Tu pago quedó registrado. ${reserva.nombreAnfitrion} debe aprobar tu estadía en ${reserva.tituloAlojamiento}.`
                  : `Tu estadía en ${reserva.tituloAlojamiento} ha sido reservada exitosamente.`}
              </p>
            </div>

            <article className="tarjeta">
              <div className="confirmada-datos">
                <div>
                  <span className="texto-suave">Código de reserva</span>
                  <button
                    type="button"
                    className="codigo-reserva"
                    onClick={copiarCodigo}
                    title="Copiar código"
                  >
                    {reserva.codigo} {copiado ? '✓ Copiado' : '⧉'}
                  </button>
                </div>
                <div>
                  <span className="texto-suave">Estado</span>
                  <span
                    className={`estado-reserva estado-${reserva.estado.toLowerCase()}`}
                  >
                    {reserva.estado === 'PENDIENTE_APROBACION'
                      ? 'Esperando aprobación'
                      : '✓ Confirmada'}
                  </span>
                </div>
              </div>

              <div className="reserva-datos">
                <div>
                  <strong>Fechas</strong>
                  <p>
                    {fechaCorta(reserva.fechaLlegada)} –{' '}
                    {fechaCorta(reserva.fechaSalida)}
                  </p>
                  <p className="texto-suave">
                    {reserva.noches}{' '}
                    {reserva.noches === 1 ? 'noche' : 'noches'}
                  </p>
                </div>
                <div>
                  <strong>Huéspedes</strong>
                  <p>{reserva.cantidadHuespedes}</p>
                </div>
                <div>
                  <strong>Método de pago</strong>
                  <p>Tarjeta terminada en {reserva.ultimos4}</p>
                </div>
              </div>

              <p className="total-pagado">
                <span className="texto-suave">Total pagado</span>
                <strong>{pesos(reserva.total)}</strong>
              </p>
            </article>

            <div className="botones-final">
              <button
                type="button"
                className="boton-principal"
                onClick={onVerViajes}
              >
                Ver mis viajes →
              </button>
              <button
                type="button"
                className="boton-secundario"
                onClick={onExplorar}
              >
                Volver a explorar alojamientos
              </button>
            </div>
          </div>

          <aside className="tarjeta que-sigue">
            <h3>¿Qué sigue?</h3>
            <ol>
              <li>
                <strong>
                  {reserva.estado === 'PENDIENTE_APROBACION'
                    ? 'El anfitrión revisa tu solicitud'
                    : 'Reserva confirmada'}
                </strong>
                <p className="texto-suave">
                  Tu pago fue procesado y las fechas ya están
                  bloqueadas.
                </p>
              </li>
              <li>
                <strong>Gestiona tu reserva</strong>
                <p className="texto-suave">
                  Puedes verla o cancelarla desde <em>Mis viajes</em>.
                </p>
              </li>
              <li>
                <strong>Política de cancelación</strong>
                <p className="texto-suave">
                  {NOMBRES_POLITICA[politica.tipo]}.{' '}
                  {explicarPolitica(politica)}
                </p>
              </li>
            </ol>
          </aside>
        </div>
      )}
    </section>
  )
}

export default Reservar
