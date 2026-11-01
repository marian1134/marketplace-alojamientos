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
// Lee el mensaje de error que envía el backend
export async function leerError(respuesta, porDefecto) {
  try {
    const datos = await respuesta.json()

    if (datos?.message) {
      return datos.message
    }
  } catch {
    // La respuesta no traía JSON
  }

  if (respuesta.status === 401) {
    return 'Tu sesión terminó. Inicia sesión de nuevo.'
  }

  return porDefecto
}

export async function consultar(ruta) {
  return fetch(ruta, {
    credentials: 'same-origin',
    cache: 'no-store',
  })
}
