import { useIdioma } from '../idiomas'
import './selector-idioma.css'

export default function SelectorIdioma({ portada = false, flotante = false }) {
  const { idioma, cambiarIdioma } = useIdioma()
  return (
    <label className={`selector-idioma${portada ? ' selector-idioma-portada' : ''}${flotante ? ' selector-idioma-flotante' : ''}`}>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" aria-hidden="true">
        <circle cx="12" cy="12" r="9" /><ellipse cx="12" cy="12" rx="4" ry="9" /><path d="M3 12h18" />
      </svg>
      <select aria-label="Idioma / Language" value={idioma} onChange={(evento) => cambiarIdioma(evento.target.value)}>
        <option value="es">ES · Español</option>
        <option value="en">EN · English</option>
      </select>
    </label>
  )
}
