import { useEffect, useState } from 'react'
import { enviarArchivo, enviarDatos } from '../api'


const MAXIMO_IMAGENES = 10
const MAXIMO_BYTES = 5 * 1024 * 1024

const TIPOS_PERMITIDOS = [
  'image/jpeg',
  'image/png',
  'image/webp',
]

function ImagenesAlojamiento({ idAlojamiento }) {
  const [imagenes, setImagenes] = useState([])
  const [cargando, setCargando] = useState(true)
  const [subiendo, setSubiendo] = useState(false)
  const [mensaje, setMensaje] = useState('')

  async function cargarImagenes() {
    try {
      const respuesta = await fetch(
        `/api/v1/alojamientos/${idAlojamiento}/imagenes`,
        {
          credentials: 'same-origin',
          cache: 'no-store',
        }
      )

      if (!respuesta.ok) {
        throw new Error('No se pudieron consultar las imágenes')
      }

      const datos = await respuesta.json()
      setImagenes(datos)
    } catch {
      setMensaje('No se pudieron cargar las imágenes.')
    } finally {
      setCargando(false)
    }
  }

  useEffect(() => {
    cargarImagenes()
  }, [idAlojamiento])

  async function seleccionarImagenes(evento) {
    const entrada = evento.currentTarget
    const archivos = Array.from(entrada.files ?? [])

    if (archivos.length === 0) {
      return
    }

    const espaciosDisponibles =
      MAXIMO_IMAGENES - imagenes.length

    if (archivos.length > espaciosDisponibles) {
      setMensaje(
        `Solo puedes agregar ${espaciosDisponibles} imagen(es) más.`
      )
      entrada.value = ''
      return
    }

    const archivoInvalido = archivos.find(
      (archivo) =>
        !TIPOS_PERMITIDOS.includes(archivo.type) ||
        archivo.size > MAXIMO_BYTES
    )

    if (archivoInvalido) {
      setMensaje(
        'Las imágenes deben ser JPG, PNG o WebP y pesar máximo 5 MB.'
      )
      entrada.value = ''
      return
    }

    setSubiendo(true)
    setMensaje('')

    try {
      for (const archivo of archivos) {
        const respuesta = await enviarArchivo(
          `/api/v1/alojamientos/${idAlojamiento}/imagenes`,
          archivo
        )

        if (!respuesta.ok) {
          throw new Error('No se pudo subir una imagen')
        }
      }

      setMensaje('Las imágenes se guardaron correctamente.')
      await cargarImagenes()
    } catch {
      setMensaje(
        'No se pudieron guardar todas las imágenes. Intenta nuevamente.'
      )
    } finally {
      setSubiendo(false)
      entrada.value = ''
    }
  }

  async function seleccionarPortada(idImagen) {
    setMensaje('')

    try {
      const respuesta = await enviarDatos(
        `/api/v1/alojamientos/imagenes/${idImagen}/principal`,
        {},
        'PATCH'
      )

      if (!respuesta.ok) {
        throw new Error('No se pudo cambiar la portada')
      }

      setMensaje('La portada se actualizó correctamente.')
      await cargarImagenes()
    } catch {
      setMensaje('No se pudo cambiar la imagen de portada.')
    }
  }

  async function eliminarImagen(idImagen) {
    const confirmado = window.confirm(
      '¿Deseas eliminar esta imagen?'
    )

    if (!confirmado) {
      return
    }

    setMensaje('')

    try {
      const respuesta = await enviarDatos(
        `/api/v1/alojamientos/imagenes/${idImagen}`,
        {},
        'DELETE'
      )

      if (!respuesta.ok) {
        throw new Error('No se pudo eliminar la imagen')
      }

      setMensaje('La imagen se eliminó correctamente.')
      await cargarImagenes()
    } catch {
      setMensaje('No se pudo eliminar la imagen.')
    }
  }

  return (
    <section className="imagenes-alojamiento">
      <div className="imagenes-encabezado">
        <div>
          <h4>Fotografías</h4>
          <p>
            {imagenes.length} de {MAXIMO_IMAGENES} imágenes
          </p>
        </div>

        <label className="boton-agregar-imagen">
          {subiendo ? 'Subiendo...' : 'Agregar imágenes'}

          <input
            type="file"
            accept="image/jpeg,image/png,image/webp"
            multiple
            onChange={seleccionarImagenes}
            disabled={
              subiendo ||
              imagenes.length >= MAXIMO_IMAGENES
            }
          />
        </label>
      </div>

      {cargando ? (
        <p>Cargando imágenes...</p>
      ) : imagenes.length === 0 ? (
        <p className="sin-imagenes">
          Este alojamiento todavía no tiene fotografías.
        </p>
      ) : (
        <div className="galeria-imagenes">
          {imagenes.map((imagen) => (
            <article
              className="imagen-tarjeta"
              key={imagen.idImagen}
            >
              <div className="imagen-contenedor">
                <img
                  src={imagen.urlImagen}
                  alt={`Fotografía del alojamiento ${idAlojamiento}`}
                />

                {imagen.principal && (
                  <span className="etiqueta-portada">
                    Portada
                  </span>
                )}
              </div>

              <div className="imagen-acciones">
                {!imagen.principal && (
                  <button
                    type="button"
                    onClick={() =>
                      seleccionarPortada(imagen.idImagen)
                    }
                  >
                    Usar como portada
                  </button>
                )}

                <button
                  type="button"
                  className="boton-eliminar-imagen"
                  onClick={() =>
                    eliminarImagen(imagen.idImagen)
                  }
                >
                  Eliminar
                </button>
                            </div>
            </article>
          ))}
        </div>
      )}

      {mensaje && (
        <p className="mensaje-imagenes" role="status">
          {mensaje}
        </p>
      )}
    </section>
  )
}

export default ImagenesAlojamiento