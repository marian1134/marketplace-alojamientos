import { t, useIdioma } from '../idiomas'
import { useEffect, useRef, useState } from 'react'
import { historialIa, preguntarIa } from './asistente-ia-api'

const CONTENIDO_AYUDA = {
  busqueda: {
    titulo: 'Ayuda con tu búsqueda',
    texto: 'Verifica la ciudad, las fechas y la cantidad de huéspedes. La fecha de salida debe ser posterior a la fecha de entrada.',
  },
  reserva: {
    titulo: 'Problemas con una reserva',
    texto: 'Entra a Mis viajes para revisar el estado, las fechas y los datos del alojamiento reservado.',
  },
  cuenta: {
    titulo: 'Problemas con tu cuenta',
    texto: 'Comprueba tus datos e intenta cerrar e iniciar sesión nuevamente. Si el problema continúa, guarda una captura del mensaje de error.',
  },
}
const ERRORES = {
  IA_SESION: ['Inicia sesión para usar el asistente de IA.', 'Sign in to use the AI assistant.'],
  IA_PROTECCION: ['No se pudo validar la sesión. Recarga la página e inténtalo de nuevo.', 'Your session could not be validated. Refresh the page and try again.'],
  IA_NO_CONFIGURADA: ['La IA todavía no está habilitada. Puedes consultar las guías rápidas.', 'AI is not enabled yet. You can use the quick guides.'],
  IA_LIMITE_TOTAL: ['Se alcanzó el límite de consultas de esta demostración. Las guías rápidas siguen disponibles.', 'This demo has reached its question limit. Quick guides are still available.'],
  IA_LIMITE_USUARIO: ['Espera unos segundos antes de preguntar de nuevo. El máximo es de 30 consultas por hora por cuenta.', 'Wait a few seconds before asking again. Each account can make up to 30 requests per hour.'],
  IA_OCUPADA: ['El asistente está atendiendo otras consultas. Inténtalo en unos segundos.', 'The assistant is handling other questions. Try again in a few seconds.'],
  IA_CONTADOR_NO_DISPONIBLE: ['La IA no está disponible temporalmente. Usa las guías rápidas.', 'AI is temporarily unavailable. Use the quick guides.'],
  IA_CUOTA_PROVEEDOR: ['El servicio de IA no tiene cuota disponible o está limitado. Inténtalo más tarde.', 'The AI service has no available quota or is rate limited. Try again later.'],
  IA_CONFIGURACION: ['El servicio de IA necesita que el equipo revise su configuración.', 'The team needs to check the AI service configuration.'],
  IA_TIEMPO: ['La IA tardó demasiado. No se reenvió tu pregunta automáticamente.', 'AI took too long. Your question was not resent automatically.'],
  IA_SIN_RESPUESTA: ['No llegó una respuesta completa. Prueba con una pregunta más corta.', 'No complete answer was received. Try a shorter question.'],
  IA_DATOS: ['Escribe una pregunta de hasta 800 caracteres.', 'Write a question of up to 800 characters.'],
  IA_PROVEEDOR: ['No se pudo consultar la IA. Las guías rápidas siguen disponibles.', 'AI could not be reached. Quick guides are still available.'],
}

export default function SoporteFlotante() {
  const { idioma } = useIdioma()
  const tr = (es, en) => idioma === 'en' ? en : es
  const [abierto, setAbierto] = useState(false)
  const [pestana, setPestana] = useState('ia')
  const [tema, setTema] = useState(null)
  const [estado, setEstado] = useState(null)
  const [mensajes, setMensajes] = useState([])
  const [pregunta, setPregunta] = useState('')
  const [enviando, setEnviando] = useState(false)
  const [error, setError] = useState('')
  const panel = useRef(null)
  const activador = useRef(null)
  const entrada = useRef(null)
  const final = useRef(null)
  const pendiente = useRef(null)
  const consultaEstado = useRef(null)
  const revision = useRef(0)
  const cuenta = useRef(null)
  const ayudaSeleccionada = tema ? CONTENIDO_AYUDA[tema] : null

  useEffect(() => {
    if (!abierto) return undefined
    async function comprobar() {
      consultaEstado.current?.abort()
      const controlador = new AbortController()
      consultaEstado.current = controlador
      const version = revision.current
      try {
        const respuesta = await fetch('/api/v1/asistente/estado', {
          credentials: 'same-origin', cache: 'no-store', signal: controlador.signal,
        })
        const datos = respuesta.ok ? await respuesta.json() : null
        if (controlador.signal.aborted || version !== revision.current) return
        setEstado(datos && typeof datos.disponible === 'boolean' && typeof datos.autenticado === 'boolean'
          ? datos : { disponible: false, autenticado: false })
        const identidad = datos?.autenticado ? String(datos.cuenta) : ''
        if (!datos?.autenticado || (cuenta.current !== null && cuenta.current !== identidad)) {
          revision.current++
          pendiente.current?.abort()
          pendiente.current = null
          setEnviando(false)
          setMensajes([])
          setPregunta('')
          setError('')
        }
        cuenta.current = identidad
      } catch {
        if (!controlador.signal.aborted && version === revision.current) {
          setEstado({ disponible: false, autenticado: false })
        }
      }
    }
    function cambioSesion() {
      revision.current++
      pendiente.current?.abort()
      pendiente.current = null
      setEnviando(false)
      setMensajes([])
      setPregunta('')
      setError('')
      setEstado(null)
      cuenta.current = null
      comprobar()
    }
    comprobar()
    window.addEventListener('stayhub:sesion', cambioSesion)
    window.addEventListener('focus', comprobar)
    return () => {
      consultaEstado.current?.abort()
      window.removeEventListener('stayhub:sesion', cambioSesion)
      window.removeEventListener('focus', comprobar)
    }
  }, [abierto])

  // La conversacion tampoco debe sobrevivir a un cambio de cuenta con el panel cerrado.
  useEffect(() => {
    function limpiarCerrado() {
      if (abierto) return
      revision.current++
      pendiente.current?.abort()
      pendiente.current = null
      setEnviando(false)
      setMensajes([])
      setPregunta('')
      setError('')
      setEstado(null)
      cuenta.current = null
    }
    window.addEventListener('stayhub:sesion', limpiarCerrado)
    return () => window.removeEventListener('stayhub:sesion', limpiarCerrado)
  }, [abierto])

  useEffect(() => () => { pendiente.current?.abort() }, [])
  useEffect(() => {
    if (abierto) final.current?.scrollIntoView({ block: 'nearest' })
  }, [abierto, mensajes, enviando, pestana])
  useEffect(() => {
    if (abierto) panel.current?.focus()
  }, [abierto])

  function cerrar() {
    setAbierto(false)
    setTema(null)
    activador.current?.focus()
  }

  async function enviar(evento) {
    evento.preventDefault()
    const texto = pregunta.trim()
    if (!texto || texto.length > 800 || pendiente.current || !estado?.autenticado || !estado?.disponible) return
    const controlador = new AbortController()
    pendiente.current = controlador
    const version = revision.current
    const historial = historialIa(mensajes)
    setEnviando(true)
    setError('')
    const temporizador = window.setTimeout(() => controlador.abort(), 55000)
    try {
      const respuesta = await preguntarIa({ pregunta: texto, idioma, historial }, controlador.signal)
      if (version !== revision.current) return
      setMensajes(actuales => [...actuales, { rol: 'user', texto }, { rol: 'assistant', texto: respuesta }].slice(-40))
      setPregunta('')
    } catch (fallo) {
      if (version !== revision.current) return
      const codigo = fallo.name === 'AbortError' ? 'IA_TIEMPO' : fallo.message
      setError(ERRORES[codigo] ? codigo : 'IA_PROVEEDOR')
      if (codigo === 'IA_SESION') {
        setMensajes([])
        setEstado(actual => ({ ...actual, autenticado: false }))
      }
    } finally {
      window.clearTimeout(temporizador)
      if (pendiente.current === controlador) {
        pendiente.current = null
        setEnviando(false)
        entrada.current?.focus()
      }
    }
  }

  const puedePreguntar = estado?.autenticado && estado?.disponible
  return (
    <div className="soporte-flotante">
      {abierto && (
        <section id="panel-soporte" ref={panel} tabIndex={-1} className="soporte-panel soporte-panel--ia"
          role="dialog" aria-modal="false" aria-labelledby="titulo-soporte"
          onKeyDown={evento => { if (evento.key === 'Escape') cerrar() }}>
          <div className="soporte-encabezado">
            <div>
              <span className="soporte-etiqueta">{t('CENTRO DE AYUDA')}</span>
              <h2 id="titulo-soporte">{tr('Asistente de StayHub', 'StayHub assistant')}</h2>
            </div>
            <button type="button" className="soporte-cerrar" onClick={cerrar} aria-label={t('Cerrar ayuda')}>×</button>
          </div>
          <div className="soporte-pestanas" role="group" aria-label={tr('Tipo de ayuda', 'Help type')}>
            <button type="button" aria-pressed={pestana === 'ia'} onClick={() => setPestana('ia')}>{tr('Asistente IA', 'AI assistant')}</button>
            <button type="button" aria-pressed={pestana === 'guias'} onClick={() => setPestana('guias')}>{tr('Guías rápidas', 'Quick guides')}</button>
          </div>
          {pestana === 'ia' ? (
            <>
              <p className="soporte-introduccion">{tr(
                'Te oriento sobre StayHub. Soy una IA y puedo equivocarme. No realizo cambios en tu cuenta ni en tus reservas.',
                'I can help you use StayHub. I am an AI and may make mistakes. I cannot change your account or bookings.')}</p>
              {!estado && <p role="status">{tr('Comprobando disponibilidad…', 'Checking availability…')}</p>}
              {estado && !estado.disponible && <p className="soporte-aviso" role="status">{tr(...ERRORES.IA_NO_CONFIGURADA)}</p>}
              {estado?.disponible && !estado.autenticado && <p className="soporte-aviso" role="status">{tr(...ERRORES.IA_SESION)}</p>}
              <div className="soporte-conversacion" role="log" aria-live="polite" aria-relevant="additions" aria-label={tr('Conversación con la IA', 'AI conversation')}>
                {mensajes.length === 0 && <p className="soporte-vacio">{tr('¿Cómo reservo? ¿Cuándo puedo hacer check-in? Pregúntame.', 'How do I book? When can I check in? Ask me.')}</p>}
                {mensajes.map((mensaje, indice) => (
                  <div key={indice} className={`soporte-mensaje soporte-mensaje--${mensaje.rol}`}>
                    <strong>{mensaje.rol === 'user' ? tr('Tú', 'You') : tr('Asistente IA', 'AI assistant')}</strong>
                    <p>{mensaje.texto}</p>
                  </div>
                ))}
                {enviando && <p className="soporte-pensando" role="status">{tr('Consultando a la IA…', 'Asking AI…')}</p>}
                <span ref={final} />
              </div>
              {puedePreguntar && mensajes.length === 0 && <div className="soporte-sugerencias">
                {[
                  ['¿Cómo hago una reserva?', 'How do I make a booking?'],
                  ['¿Cuándo puedo hacer check-in?', 'When can I check in?'],
                  ['¿Cómo dejo una reseña?', 'How do I leave a review?'],
                ].map(par => <button type="button" key={par[0]} disabled={enviando} onClick={() => { setPregunta(tr(...par)); entrada.current?.focus() }}>{tr(...par)}</button>)}
              </div>}
              {error && <p className="soporte-error" role="alert">{tr(...ERRORES[error])}</p>}
              <form className="soporte-formulario" onSubmit={enviar}>
                <label htmlFor="pregunta-ia">{tr('Tu pregunta', 'Your question')}</label>
                <textarea id="pregunta-ia" ref={entrada} rows={2} maxLength={800} value={pregunta}
                  onChange={evento => setPregunta(evento.target.value)} disabled={!puedePreguntar || enviando}
                  placeholder={tr('Pregunta sobre cómo usar StayHub…', 'Ask how to use StayHub…')} />
                <div className="soporte-acciones">
                  <span>{pregunta.length}/800</span>
                  <button type="button" disabled={enviando || mensajes.length === 0} onClick={() => { setMensajes([]); setError(''); setPregunta('') }}>{tr('Limpiar', 'Clear')}</button>
                  <button type="submit" disabled={!puedePreguntar || enviando || !pregunta.trim()}>{enviando ? tr('Enviando…', 'Sending…') : tr('Enviar', 'Send')}</button>
                </div>
              </form>
              <p className="soporte-privacidad">{tr('Tu pregunta y un contexto breve se envían a OpenAI. No compartas contraseñas, códigos ni datos de tarjetas.', 'Your question and a short context are sent to OpenAI. Do not share passwords, verification codes or card details.')}</p>
            </>
          ) : (
            <>
              <p className="soporte-introduccion">{t('Selecciona la opción que se relacione con tu problema.')}</p>
              <div className="soporte-opciones">
                <button type="button" onClick={() => setTema('busqueda')}><span aria-hidden="true">⌕</span><span><strong>{t('Ayuda con mi búsqueda')}</strong><small>{t('Ciudad, fechas o huéspedes')}</small></span><span aria-hidden="true">→</span></button>
                <button type="button" onClick={() => setTema('reserva')}><span aria-hidden="true">▣</span><span><strong>{t('Problemas con una reserva')}</strong><small>{t('Estado o información del viaje')}</small></span><span aria-hidden="true">→</span></button>
                <button type="button" onClick={() => setTema('cuenta')}><span aria-hidden="true">♙</span><span><strong>{t('Problemas con mi cuenta')}</strong><small>{t('Inicio de sesión o datos personales')}</small></span><span aria-hidden="true">→</span></button>
              </div>
              {ayudaSeleccionada && <div className="soporte-respuesta" role="status"><h3>{t(ayudaSeleccionada.titulo)}</h3><p>{t(ayudaSeleccionada.texto)}</p></div>}
            </>
          )}
        </section>
      )}
      <button type="button" ref={activador} className="soporte-activador" onClick={() => abierto ? cerrar() : setAbierto(true)} aria-expanded={abierto} aria-controls="panel-soporte">
        <span className="soporte-signo" aria-hidden="true">?</span><span>{abierto ? t('Cerrar ayuda') : t('¿Necesitas ayuda?')}</span>
      </button>
    </div>
  )
}
