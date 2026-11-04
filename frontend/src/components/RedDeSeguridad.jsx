import { t, useIdioma } from '../idiomas'
import { Component } from 'react';
// Si una pantalla falla, muestra un mensaje en lugar de la página en blanco
class RedDeSeguridad extends Component {
    constructor(props) {
        super(props);
        this.state = { error: null };
    }
    static getDerivedStateFromError(error) {
        return { error };
    }
    componentDidCatch(error, informacion) {
        console.error(t("Error en la pantalla:"), error, informacion);
    }
    render() {
        if (!this.state.error) {
            return this.props.children;
        }
        return (<section className="contenedor">
        <div className="tarjeta vacio">
          <span aria-hidden="true">⚠️</span>
          <h2>{t("Algo sali\u00F3 mal en esta pantalla")}</h2>
          <p className="texto-suave">{t("Revisa que el backend est\u00E9 encendido y actualizado (Ctrl + C y mvnw.cmd spring-boot:run) y vuelve a intentarlo.")}</p>
          <p className="aviso aviso-error">{t(String(this.state.error.message))}</p>
          <button type="button" className="boton-principal" onClick={() => {
                this.setState({ error: null });
                this.props.onVolver?.();
            }}>{t("Volver a explorar")}</button>
        </div>
      </section>);
    }
}
export default function PantallaProtegida(props) { useIdioma(); return <RedDeSeguridad {...props} />; }
