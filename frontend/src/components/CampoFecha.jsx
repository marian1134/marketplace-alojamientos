import { useEffect, useRef, useState } from 'react'
import { aFecha, aTexto } from '../formato'
import { IconoCalendario } from './Iconos'

const DIAS = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do']

// '2026-12-15' -> '15/12/2026'
export function fechaNumerica(texto) {
  if (!texto) {
    return ''
  }

  const [anio, mes, dia] = texto.split('-')
  return `${dia}/${mes}/${anio}`
}

// Selector de fecha propio: muestra dd/mm/aaaa en cualquier navegador y
// no deja elegir fechas fuera del rango ni días ocupados.
function CampoFecha({
  id,
  value,
  onChange,
  min,
  max,
  deshabilitada,
  placeholder = 'dd/mm/aaaa',
  bloqueado = false,
  className = '',
  etiqueta = 'Elegir fecha',
}) {
  const [abierto, setAbierto] = useState(false)
  const contenedor = useRef(null)

  const inicial = aFecha(value || min || aTexto(new Date()))
  const [mesVisible, setMesVisible] = useState({
    anio: inicial.getFullYear(),
    mes: inicial.getMonth(),
  })

  useEffect(() => {
    function cerrarAfuera(evento) {
      if (!contenedor.current?.contains(evento.target)) {
        setAbierto(false)
      }
    }

    function cerrarConEscape(evento) {
      if (evento.key === 'Escape') {
        setAbierto(false)
      }
    }

    document.addEventListener('mousedown', cerrarAfuera)
    document.addEventListener('keydown', cerrarConEscape)

    return () => {
      document.removeEventListener('mousedown', cerrarAfuera)
      document.removeEventListener('keydown', cerrarConEscape)
    }
  }, [])

  function abrir() {
    if (bloqueado) {
      return
    }

    const base = aFecha(value || min || aTexto(new Date()))
    setMesVisible({ anio: base.getFullYear(), mes: base.getMonth() })
    setAbierto(!abierto)
  }

  function moverMes(cantidad) {
    const fecha = new Date(mesVisible.anio, mesVisible.mes + cantidad, 1)
    setMesVisible({ anio: fecha.getFullYear(), mes: fecha.getMonth() })
  }

  function noDisponible(texto) {
    return (
      (min && texto < min) ||
      (max && texto > max) ||
      Boolean(deshabilitada?.(texto))
    )
  }

  const primero = new Date(mesVisible.anio, mesVisible.mes, 1)
  const huecos = (primero.getDay() + 6) % 7
  const totalDias = new Date(mesVisible.anio, mesVisible.mes + 1, 0).getDate()

  const nombreMes = primero.toLocaleDateString('es-CO', {
    month: 'long',
    year: 'numeric',
  })

  const ultimoDelMesAnterior = aTexto(new Date(mesVisible.anio, mesVisible.mes, 0))
  const primeroDelSiguiente = aTexto(new Date(mesVisible.anio, mesVisible.mes + 1, 1))

  return (
    <div className={`campo-fecha ${className}`} ref={contenedor}>
      <button
        id={id}
        type="button"
        className={value ? 'campo-fecha-boton' : 'campo-fecha-boton sin-valor'}
        onClick={abrir}
        aria-haspopup="dialog"
        aria-expanded={abierto}
        aria-label={value ? `${etiqueta}: ${fechaNumerica(value)}` : etiqueta}
      >
        <span>{value ? fechaNumerica(value) : placeholder}</span>
        <IconoCalendario tamano={18} />
      </button>

      {abierto && (
        <div className="calendario-popup" role="dialog" aria-label={etiqueta}>
          <div className="calendario-popup-cabecera">
            <button
              type="button"
              onClick={() => moverMes(-1)}
              disabled={Boolean(min) && ultimoDelMesAnterior < min}
              aria-label="Mes anterior"
            >
              ‹
            </button>
            <strong>{nombreMes}</strong>
            <button
              type="button"
              onClick={() => moverMes(1)}
              disabled={Boolean(max) && primeroDelSiguiente > max}
              aria-label="Mes siguiente"
            >
              ›
            </button>
          </div>

          <div className="calendario-popup-grilla">
            {DIAS.map((dia) => (
              <span key={dia} className="calendario-popup-dia-nombre">
                {dia}
              </span>
            ))}

            {Array.from({ length: huecos }, (_, indice) => (
              <span key={`hueco-${indice}`} />
            ))}

            {Array.from({ length: totalDias }, (_, indice) => {
              const texto = aTexto(
                new Date(mesVisible.anio, mesVisible.mes, indice + 1)
              )
              const bloqueadoDia = noDisponible(texto)

              return (
                <button
                  key={texto}
                  type="button"
                  className={texto === value ? 'elegido' : ''}
                  disabled={bloqueadoDia}
                  aria-pressed={texto === value}
                  aria-label={fechaNumerica(texto)}
                  onClick={() => {
                    onChange(texto)
                    setAbierto(false)
                  }}
                >
                  {indice + 1}
                </button>
              )
            })}
          </div>

          {value && (
            <button
              type="button"
              className="calendario-popup-borrar"
              onClick={() => {
                onChange('')
                setAbierto(false)
              }}
            >
              Borrar fecha
            </button>
          )}
        </div>
      )}
    </div>
  )
}

export default CampoFecha
