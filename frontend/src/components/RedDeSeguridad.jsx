import { Component } from 'react'

// Si una pantalla falla, muestra un mensaje en lugar de la página en blanco
class RedDeSeguridad extends Component {
  constructor(props) {
    super(props)
    this.state = { error: null }
  }

  static getDerivedStateFromError(error) {
    return { error }
  }

  componentDidCatch(error, informacion) {
    console.error('Error en la pantalla:', error, informacion)
  }

  render() {
    if (!this.state.error) {
      return this.props.children
    }

    return (
      <section className="contenedor">
        <div className="tarjeta vacio">
          <span aria-hidden="true">⚠️</span>
          <h2>Algo salió mal en esta pantalla</h2>
          <p className="texto-suave">
            Revisa que el backend esté encendido y actualizado (Ctrl + C y
            mvnw.cmd spring-boot:run) y vuelve a intentarlo.
          </p>
          <p className="aviso aviso-error">{String(this.state.error.message)}</p>
          <button
            type="button"
            className="boton-principal"
            onClick={() => {
              this.setState({ error: null })
              this.props.onVolver?.()
            }}
          >
            Volver a explorar
          </button>
        </div>
      </section>
    )
  }
}

export default RedDeSeguridad
