import { useState } from 'react'

const CONTENIDO_AYUDA = {
  busqueda: {
    titulo: 'Ayuda con tu búsqueda',
    texto:
      'Verifica la ciudad, las fechas y la cantidad de huéspedes. La fecha de salida debe ser posterior a la fecha de entrada.',
  },
  reserva: {
    titulo: 'Problemas con una reserva',
    texto:
      'Entra a Mis viajes para revisar el estado, las fechas y los datos del alojamiento reservado.',
  },
  cuenta: {
    titulo: 'Problemas con tu cuenta',
    texto:
      'Comprueba tus datos e intenta cerrar e iniciar sesión nuevamente. Si el problema continúa, guarda una captura del mensaje de error.',
  },
}

function SoporteFlotante() {
  const [abierto, setAbierto] = useState(false)
  const [tema, setTema] = useState(null)

  const ayudaSeleccionada = tema ? CONTENIDO_AYUDA[tema] : null

  function cerrar() {
    setAbierto(false)
    setTema(null)
  }

  return (
    <div className="soporte-flotante">
      {abierto && (
        <section
          id="panel-soporte"
          className="soporte-panel"
          aria-label="Centro de ayuda"
        >
          <div className="soporte-encabezado">
            <div>
              <span className="soporte-etiqueta">CENTRO DE AYUDA</span>
              <h2>¿Cómo podemos ayudarte?</h2>
            </div>

            <button
              type="button"
              className="soporte-cerrar"
              onClick={cerrar}
              aria-label="Cerrar ayuda"
            >
              ×
            </button>
          </div>

          <p className="soporte-introduccion">
            Selecciona la opción que se relacione con tu problema.
          </p>

          <div className="soporte-opciones">
            <button type="button" onClick={() => setTema('busqueda')}>
              <span aria-hidden="true">⌕</span>
              <span>
                <strong>Ayuda con mi búsqueda</strong>
                <small>Ciudad, fechas o huéspedes</small>
              </span>
              <span aria-hidden="true">→</span>
            </button>

            <button type="button" onClick={() => setTema('reserva')}>
              <span aria-hidden="true">▣</span>
              <span>
                <strong>Problemas con una reserva</strong>
                <small>Estado o información del viaje</small>
              </span>
              <span aria-hidden="true">→</span>
            </button>

            <button type="button" onClick={() => setTema('cuenta')}>
              <span aria-hidden="true">♙</span>
              <span>
                <strong>Problemas con mi cuenta</strong>
                <small>Inicio de sesión o datos personales</small>
              </span>
              <span aria-hidden="true">→</span>
            </button>
          </div>

          {ayudaSeleccionada && (
            <div className="soporte-respuesta" role="status">
              <h3>{ayudaSeleccionada.titulo}</h3>
              <p>{ayudaSeleccionada.texto}</p>
            </div>
          )}
        </section>
      )}

      <button
        type="button"
        className="soporte-activador"
        onClick={() => {
          setAbierto((actual) => !actual)
          if (abierto) setTema(null)
        }}
        aria-expanded={abierto}
        aria-controls="panel-soporte"
      >
        <span className="soporte-signo" aria-hidden="true">?</span>
        <span>{abierto ? 'Cerrar ayuda' : '¿Necesitas ayuda?'}</span>
      </button>
    </div>
  )
}

export default SoporteFlotante
