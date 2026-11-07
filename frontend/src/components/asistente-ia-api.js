// Solo llama al backend de StayHub. La clave de la IA (Gemini) nunca viaja al navegador.
export async function preguntarIa(datos, signal) {
  const csrf = await fetch('/api/usuarios/csrf', {
    credentials: 'same-origin', cache: 'no-store', signal,
  })
  if (!csrf.ok) throw new Error(csrf.status === 401 ? 'IA_SESION' : 'IA_PROTECCION')
  const proteccion = await csrf.json()
  if (!proteccion?.headerName || !proteccion?.token) throw new Error('IA_PROTECCION')
  const respuesta = await fetch('/api/v1/asistente/preguntar', {
    method: 'POST', credentials: 'same-origin', signal,
    headers: { 'Content-Type': 'application/json', [proteccion.headerName]: proteccion.token },
    body: JSON.stringify(datos),
  })
  let contenido
  try { contenido = await respuesta.json() } catch { contenido = null }
  if (!respuesta.ok) {
    if (respuesta.status === 401) throw new Error('IA_SESION')
    if (respuesta.status === 403) throw new Error('IA_PROTECCION')
    throw new Error(contenido?.codigo || 'IA_PROVEEDOR')
  }
  if (typeof contenido?.respuesta !== 'string' || !contenido.respuesta.trim()) {
    throw new Error('IA_SIN_RESPUESTA')
  }
  return contenido.respuesta
}

// Contexto breve: como maximo dos intercambios y 4.000 caracteres.
export function historialIa(mensajes) {
  const seleccion = []
  let caracteres = 0
  for (const mensaje of mensajes.slice(-4).reverse()) {
    const texto = mensaje.texto.slice(0, 1600)
    if (caracteres + texto.length > 4000) break
    seleccion.unshift({ rol: mensaje.rol, texto })
    caracteres += texto.length
  }
  return seleccion
}
