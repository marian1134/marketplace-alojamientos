async function obtenerCsrf() {
  const respuesta = await fetch('/api/usuarios/csrf', {
    credentials: 'same-origin',
    cache: 'no-store',
  })

  if (!respuesta.ok) {
    throw new Error(
      'No se pudo obtener la protección del formulario'
    )
  }

  return respuesta.json()
}

export async function enviarDatos(
  ruta,
  datos,
  metodo = 'POST'
) {
  const csrf = await obtenerCsrf()

  return fetch(ruta, {
    method: metodo,
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json',
      [csrf.headerName]: csrf.token,
    },
    body: JSON.stringify(datos),
  })
}

export async function enviarArchivo(ruta, archivo) {
  const csrf = await obtenerCsrf()
  const formulario = new FormData()

  formulario.append('imagen', archivo)

  return fetch(ruta, {
    method: 'POST',
    credentials: 'same-origin',
    headers: {
      [csrf.headerName]: csrf.token,
    },
    body: formulario,
  })
}