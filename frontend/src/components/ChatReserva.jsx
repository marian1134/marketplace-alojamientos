import { useCallback, useEffect, useId, useLayoutEffect, useRef, useState } from 'react'
import { consultar, enviarDatos, leerError } from '../api'
import './chat-reserva.css'

// Se monta una sola conversación por pantalla. Al cerrarla se conserva en MySQL.
function ChatReserva({ reserva, onCerrar }) {
  const tituloId = useId()
  const campoId = useId()
  const ventana = useRef(null)
  const lista = useRef(null)
  const activo = useRef(false)
  const enviandoRef = useRef(false)
  const clavePendiente = useRef(null)
  const cursor = useRef(0)
  const inicializado = useRef(false)
  const desplazamiento = useRef(null)
  const [mensajes, setMensajes] = useState([])
  const [interlocutor, setInterlocutor] = useState('')
  const [contenido, setContenido] = useState('')
  const [cargando, setCargando] = useState(true)
  const [enviando, setEnviando] = useState(false)
  const [cargandoAnteriores, setCargandoAnteriores] = useState(false)
  const [hayAnteriores, setHayAnteriores] = useState(false)
  const [sinSesion, setSinSesion] = useState(false)
  const [error, setError] = useState('')
  const [errorEnvio, setErrorEnvio] = useState('')
  const [recarga, setRecarga] = useState(0)
  const ruta = `/api/v1/reservas/${reserva.idReserva}/mensajes`

  const integrar = useCallback((nuevos, modo = 'nuevos') => {
    if (!activo.current) return
    const elemento = lista.current
    if (modo === 'anteriores') {
      desplazamiento.current = { altura: elemento?.scrollHeight ?? 0, arriba: elemento?.scrollTop ?? 0 }
    } else if (modo === 'enviado' || !elemento ||
        elemento.scrollHeight - elemento.scrollTop - elemento.clientHeight < 90) {
      desplazamiento.current = 'final'
    }
    for (const mensaje of nuevos) cursor.current = Math.max(cursor.current, mensaje.id)
    setMensajes((actuales) => {
      const porId = new Map(actuales.map((mensaje) => [mensaje.id, mensaje]))
      for (const mensaje of nuevos) porId.set(mensaje.id, mensaje)
      return Array.from(porId.values()).sort((a, b) => a.id - b.id)
    })
  }, [])

  useLayoutEffect(() => {
    const elemento = lista.current
    if (elemento && desplazamiento.current) {
      if (desplazamiento.current === 'final') {
        elemento.scrollTop = elemento.scrollHeight
      } else {
        elemento.scrollTop = desplazamiento.current.arriba +
          elemento.scrollHeight - desplazamiento.current.altura
      }
      desplazamiento.current = null
    }
  }, [mensajes, cargando])

  useEffect(() => {
    activo.current = true
    const dialogo = ventana.current
    dialogo?.showModal()
    return () => {
      activo.current = false
      dialogo?.close()
    }
  }, [])

  useEffect(() => {
    let vigente = true
    let temporizador
    let accesoDenegado = false
    async function cargar() {
      try {
        // Primer acceso: últimos 50. Luego avanza sin saltar mensajes.
        let mas
        let lotes = 0
        do {
          const respuesta = await consultar(
            inicializado.current ? `${ruta}?despues=${cursor.current}` : ruta
          )
          if (!vigente) return
          if (!respuesta.ok) {
            if ([401, 403].includes(respuesta.status)) {
              accesoDenegado = true
              setSinSesion(true)
            }
            throw new Error(await leerError(respuesta, 'No se pudo actualizar el chat.'))
          }
          const datos = await respuesta.json()
          if (!vigente) return
          const primera = !inicializado.current
          inicializado.current = true
          setInterlocutor(datos.interlocutor)
          if (primera) setHayAnteriores(datos.hayMas)
          integrar(datos.mensajes)
          mas = !primera && datos.hayMas
          lotes += 1
        } while (mas && lotes < 5 && vigente)
        setError('')
      } catch (excepcion) {
        if (vigente) setError(excepcion.message || 'No se pudo conectar con el servidor.')
      } finally {
        if (vigente) {
          setCargando(false)
          if (!accesoDenegado) temporizador = window.setTimeout(() => {
            if (document.visibilityState === 'visible') cargar()
            else programar()
          }, 5000)
        }
      }
    }
    function programar() {
      temporizador = window.setTimeout(() => {
        if (document.visibilityState === 'visible') cargar()
        else programar()
      }, 5000)
    }
    cargar()
    return () => {
      vigente = false
      window.clearTimeout(temporizador)
    }
  }, [ruta, recarga, integrar])

  async function cargarAnteriores() {
    if (!mensajes.length || cargandoAnteriores) return
    setCargandoAnteriores(true)
    try {
      const respuesta = await consultar(`${ruta}?antes=${mensajes[0].id}`)
      if (!respuesta.ok) throw new Error(await leerError(respuesta, 'No se pudieron cargar los mensajes anteriores.'))
      const datos = await respuesta.json()
      if (activo.current) {
        integrar(datos.mensajes, 'anteriores')
        setHayAnteriores(datos.hayMas)
        setError('')
      }
    } catch (excepcion) {
      if (activo.current) setError(excepcion.message || 'No se pudo conectar con el servidor.')
    } finally {
      if (activo.current) setCargandoAnteriores(false)
    }
  }

  async function enviar(evento) {
    evento.preventDefault()
    const texto = contenido.trim()
    if (!texto || enviandoRef.current || sinSesion || cargando) return
    enviandoRef.current = true
    setEnviando(true)
    setErrorEnvio('')
    try {
      // Conserva la clave al reintentar el mismo texto después de un fallo de red.
      if (!clavePendiente.current || clavePendiente.current.texto !== texto) {
        clavePendiente.current = { texto, clave: crypto.randomUUID() }
      }
      const respuesta = await enviarDatos(ruta, {
        contenido: texto,
        claveCliente: clavePendiente.current.clave,
      })
      if (!respuesta.ok) {
        if ([401, 403].includes(respuesta.status) && activo.current) setSinSesion(true)
        throw new Error(await leerError(respuesta, 'No se pudo enviar el mensaje.'))
      }
      const mensaje = await respuesta.json()
      if (activo.current) {
        // El cursor se actualiza solo con GET: un POST no debe saltar mensajes ajenos.
        const ultimoConsultado = cursor.current
        integrar([mensaje], 'enviado')
        cursor.current = ultimoConsultado
        setContenido('')
        clavePendiente.current = null
      }
    } catch (excepcion) {
      if (activo.current) setErrorEnvio(excepcion.message || 'No se pudo conectar. Tu mensaje sigue en el formulario.')
    } finally {
      enviandoRef.current = false
      if (activo.current) setEnviando(false)
    }
  }

  function hora(valor) {
    return new Intl.DateTimeFormat('es-CO', {
      day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
    }).format(new Date(valor))
  }

  return (
    <dialog ref={ventana} className="chat-reserva" aria-labelledby={tituloId}
      onCancel={(evento) => { evento.preventDefault(); onCerrar() }}>
      <header className="chat-reserva-cabecera">
        <div>
          <h2 id={tituloId}>Chat de la reserva</h2>
          <p>{reserva.codigo} · {reserva.tituloAlojamiento}</p>
          {interlocutor && <strong>Con {interlocutor}</strong>}
        </div>
        <button type="button" className="chat-reserva-cerrar" aria-label="Cerrar chat"
          onClick={onCerrar}>×</button>
      </header>
      <div className="chat-reserva-historial" ref={lista} aria-label="Mensajes de la reserva">
        {hayAnteriores && (
          <button type="button" className="chat-reserva-anteriores" onClick={cargarAnteriores}
            disabled={cargandoAnteriores}>
            {cargandoAnteriores ? 'Cargando...' : 'Ver mensajes anteriores'}
          </button>
        )}
        {cargando ? <p role="status">Cargando conversación...</p> :
          !mensajes.length && !error && (
            <p className="chat-reserva-vacio">Todavía no hay mensajes. Escribe para coordinar tu estadía.</p>
          )}
        <ol aria-label="Conversación">
          {mensajes.map((mensaje) => (
            <li key={mensaje.id} className={mensaje.propio ? 'chat-reserva-mensaje propio' : 'chat-reserva-mensaje'}>
              <strong>{mensaje.propio ? 'Tú' : mensaje.remitente}</strong>
              <p>{mensaje.contenido}</p>
              <time dateTime={mensaje.creadaEn}>{hora(mensaje.creadaEn)}</time>
            </li>
          ))}
        </ol>
      </div>
      {error && <div className="chat-reserva-error" role="alert">
        {error}{' '}
        {!sinSesion && <button type="button" onClick={() => setRecarga((n) => n + 1)}>Reintentar</button>}
      </div>}
      <form onSubmit={enviar} className="chat-reserva-formulario">
        <label htmlFor={campoId}>Tu mensaje</label>
        <textarea id={campoId} value={contenido} maxLength={2000} rows={3} required
          disabled={enviando || sinSesion || cargando}
          placeholder="Escribe al huésped o al anfitrión..."
          onChange={(evento) => { setContenido(evento.target.value); setErrorEnvio('') }} />
        <div className="chat-reserva-pie">
          <span>{contenido.length}/2000</span>
          <button type="submit" disabled={!contenido.trim() || enviando || sinSesion || cargando}>
            {enviando ? 'Enviando...' : 'Enviar mensaje'}
          </button>
        </div>
        {errorEnvio && <p className="chat-reserva-error" role="alert">{errorEnvio}</p>}
        {sinSesion && <p role="alert">No puedes enviar mensajes con esta sesión. Cierra el chat y verifica tu cuenta.</p>}
      </form>
    </dialog>
  )
}

export default ChatReserva
