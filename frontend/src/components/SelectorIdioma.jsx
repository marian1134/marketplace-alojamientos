import { useIdioma } from '../idiomas'
import './selector-idioma.css'

const IDIOMAS = [
  { codigo: 'es', corto: 'ES', nombre: 'Español' },
  { codigo: 'en', corto: 'EN', nombre: 'English' },
]

// Botón de idioma con el globo. El select nativo queda encima, invisible,
// para que en el celular se abra la lista propia del teléfono.
export default function SelectorIdioma({ portada = false, flotante = false }) {
  const { idioma, cambiarIdioma } = useIdioma()
  const actual = IDIOMAS.find((opcion) => opcion.codigo === idioma) ?? IDIOMAS[0]
  return (
    <label className={`selector-idioma${portada ? ' selector-idioma-portada' : ''}${flotante ? ' selector-idioma-flotante' : ''}`} title="Idioma / Language">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" aria-hidden="true">
        <circle cx="12" cy="12" r="9" /><ellipse cx="12" cy="12" rx="4" ry="9" /><path d="M3 12h18" />
      </svg>
      <span className="selector-idioma-texto" aria-hidden="true">
        <span className="selector-idioma-corto">{actual.corto}</span>
        <span className="selector-idioma-nombre">{actual.nombre}</span>
      </span>
      <svg className="selector-idioma-flecha" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" aria-hidden="true">
        <path d="m6 9 6 6 6-6" />
      </svg>
      <select aria-label="Idioma / Language" value={idioma} onChange={(evento) => cambiarIdioma(evento.target.value)}>
        {IDIOMAS.map((opcion) => (
          <option key={opcion.codigo} value={opcion.codigo}>{opcion.corto} · {opcion.nombre}</option>
        ))}
      </select>
    </label>
  )
}
