import { useSyncExternalStore } from 'react'
import ingles from './en.json'

const CLAVE = 'stayhub.idioma'
const normalizar = (texto) => texto.replace(/\s+/g, ' ').trim()
function leerIdioma() {
  try { return window.localStorage.getItem(CLAVE) === 'en' ? 'en' : 'es' } catch { return 'es' }
}
let idioma = typeof window === 'undefined' ? 'es' : leerIdioma()
const oyentes = new Set()
export function idiomaActual() { return idioma }
export function localeActual() { return idioma === 'en' ? 'en-US' : 'es-CO' }
function reflejarIdioma() {
  if (typeof document !== 'undefined') document.documentElement.lang = idioma
}
reflejarIdioma()
export function cambiarIdioma(valor) {
  if (!['es', 'en'].includes(valor)) return
  idioma = valor
  try { window.localStorage.setItem(CLAVE, valor) } catch { /* El selector funciona aunque el navegador bloquee el almacenamiento. */ }
  reflejarIdioma()
  for (const avisar of oyentes) avisar()
}
function suscribir(avisar) { oyentes.add(avisar); return () => oyentes.delete(avisar) }
export function useIdioma() {
  const actual = useSyncExternalStore(suscribir, idiomaActual, idiomaActual)
  return { idioma: actual, cambiarIdioma }
}
if (typeof window !== 'undefined') {
  window.addEventListener('storage', (evento) => {
    if (evento.key === CLAVE || evento.key === null) {
      idioma = leerIdioma()
      reflejarIdioma()
      for (const avisar of oyentes) avisar()
    }
  })
}

const inverso = Object.fromEntries(Object.entries(ingles).map(([es, en]) => [en, es]))
const escapar = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
const patrones = Object.entries(ingles).filter(([es, en]) => es !== en && /\{\d+\}/.test(es)).sort((a, b) => b[0].replace(/\{\d+\}/g, '').length - a[0].replace(/\{\d+\}/g, '').length).map(([es, en]) => {
  function crear(plantilla) {
    const indices = []
    let fuente = '', inicio = 0
    for (const m of plantilla.matchAll(/\{(\d+)\}/g)) {
      fuente += escapar(plantilla.slice(inicio, m.index)) + '(.*?)'
      indices.push(Number(m[1])); inicio = m.index + m[0].length
    }
    fuente += escapar(plantilla.slice(inicio))
    return { expresion: new RegExp('^' + fuente + '$'), indices }
  }
  return { es, en, origen: crear(es), destino: crear(en) }
})
function completar(plantilla, valores) {
  return plantilla.replace(/\{(\d+)\}/g, (coincidencia, i) => valores[i] === undefined ? coincidencia : String(valores[i]))
}
// Se usa solo para textos de interfaz, nunca para traducir contenido escrito por usuarios.
export function t(texto, ...valores) {
  if (typeof texto !== 'string') return texto
  const clave = normalizar(texto)
  let salida = idioma === 'en' ? ingles[clave] : inverso[clave]
  if (salida === undefined && idioma === 'es' && ingles[clave] !== undefined) salida = clave
  if (salida === undefined && idioma === 'en' && inverso[clave] !== undefined) salida = clave
  if (salida === undefined && valores.length === 0) {
    for (const patron of patrones) {
      const lado = idioma === 'en' ? patron.origen : patron.destino
      const coincidencia = lado.expresion.exec(clave)
      if (!coincidencia) continue
      const argumentos = []
      lado.indices.forEach((indice, j) => { argumentos[indice] = coincidencia[j + 1] })
      salida = completar(idioma === 'en' ? patron.en : patron.es, argumentos)
      break
    }
  }
  if (salida === undefined) return valores.length ? completar(texto, valores) : texto
  const inicio = /^\s/.test(texto) ? ' ' : ''
  const fin = /\s$/.test(texto) ? ' ' : ''
  return inicio + completar(salida, valores) + fin
}
