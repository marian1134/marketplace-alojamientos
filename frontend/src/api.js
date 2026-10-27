export async function enviarDatos(ruta, datos) {
  const respuestaCsrf = await fetch('/api/usuarios/csrf', {
    credentials: 'same-origin',
    cache: 'no-store',
  })

  if (!respuestaCsrf.ok) {
    throw new Error('No se pudo obtener la protección del formulario')
  }

  const csrf = await respuestaCsrf.json()

  return fetch(ruta, {
    method: 'POST',
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json',
      [csrf.headerName]: csrf.token,
    },
    body: JSON.stringify(datos),
  })
}