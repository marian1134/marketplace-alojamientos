import { useEffect, useState } from 'react'
import { enviarDatos, leerError } from '../api'

const SEGUNDOS_PARA_REENVIAR = 30

// Segundo paso del inicio de sesión: escribir el código de 6 números
// que llegó al correo.
function CodigoVerificacion({
  correo,
  contrasena,
  correoOculto,
  minutos,
  onSesion,
  onVolver,
}) {
  const [codigo, setCodigo] = useState('')
  const [mensaje, setMensaje] = useState('')
  const [enviando, setEnviando] = useState(false)
  const [espera, setEspera] = useState(SEGUNDOS_PARA_REENVIAR)

  // Cuenta regresiva para poder pedir otro código
  useEffect(() => {
    if (espera <= 0) {
      return
    }

    const temporizador = setTimeout(() => setEspera(espera - 1), 1000)

    return () => clearTimeout(temporizador)
  }, [espera])

  async function verificar(evento) {
    evento.preventDefault()

    if (!/^\d{6}$/.test(codigo)) {
      setMensaje('El código tiene 6 números.')
      return
    }

    setEnviando(true)
    setMensaje('')

    try {
      const respuesta = await enviarDatos('/api/usuarios/verificar-codigo', {
        correo,
        codigo,
      })

      if (!respuesta.ok) {
        setMensaje(
          await leerError(respuesta, 'No se pudo verificar el código.')
        )
        setCodigo('')
        return
      }

      onSesion?.(await respuesta.json())
    } catch {
      setMensaje(
        'No se pudo completar la solicitud. Comprueba que el servidor esté funcionando.'
      )
    } finally {
      setEnviando(false)
    }
  }

  async function reenviar() {
    setEnviando(true)
    setMensaje('')

    try {
      const respuesta = await enviarDatos('/api/usuarios/login', {
        correo,
        contrasena,
      })

      if (respuesta.status !== 202) {
        setMensaje(
          await leerError(respuesta, 'No se pudo enviar otro código.')
        )
        return
      }

      setCodigo('')
      setEspera(SEGUNDOS_PARA_REENVIAR)
      setMensaje('Te enviamos un código nuevo. El anterior ya no sirve.')
    } catch {
      setMensaje('No se pudo conectar con el servidor.')
    } finally {
      setEnviando(false)
    }
  }

  return (
    <section>
      <h1>Verifica que eres tú</h1>
      <p>
        Te enviamos un código de 6 números a <strong>{correoOculto}</strong>.
        Vence en {minutos} minutos.
      </p>

      <form onSubmit={verificar}>
        <div>
          <label htmlFor="codigo-verificacion">Código</label>

          <input
            id="codigo-verificacion"
            name="codigo"
            className="campo-codigo"
            inputMode="numeric"
            autoComplete="one-time-code"
            pattern="\d{6}"
            maxLength={6}
            placeholder="000000"
            value={codigo}
            onChange={(evento) =>
              setCodigo(evento.target.value.replace(/\D/g, '').slice(0, 6))
            }
            autoFocus
            required
          />

          <small>
            ¿No lo ves? Revisa la carpeta de spam o promociones.
          </small>
        </div>

        <button type="submit" disabled={enviando || codigo.length !== 6}>
          {enviando ? 'Verificando...' : 'Entrar'}
        </button>

        <p role="status">{mensaje}</p>

        <button
          type="button"
          className="boton-enlace"
          onClick={reenviar}
          disabled={enviando || espera > 0}
        >
          {espera > 0
            ? `Pedir otro código (en ${espera} s)`
            : 'Pedir otro código'}
        </button>

        <button type="button" className="boton-enlace" onClick={onVolver}>
          ← Volver
        </button>
      </form>
    </section>
  )
}

export default CodigoVerificacion
