import { useRef, useState } from 'react'
import { enviarArchivo, enviarDatos } from '../api'

const MAXIMO_BYTES = 5 * 1024 * 1024
const TIPOS_PERMITIDOS = [
  'image/jpeg',
  'image/png',
  'image/webp',
]

function PanelHuesped({
  usuario,
  cantidadFavoritos,
  onExplorar,
  onViajes,
  onFavoritos,
  onPanelAnfitrion,
  onConvertirse,
  onCerrarSesion,
  onUsuarioActualizado,
  cerrando,
}) {
  const entradaFoto = useRef(null)
  const [subiendoFoto, setSubiendoFoto] = useState(false)
  const [eliminandoFoto, setEliminandoFoto] = useState(false)
  const [mensajeFoto, setMensajeFoto] = useState('')
  const [ayudaAbierta, setAyudaAbierta] = useState(false)
  const [temaAyuda, setTemaAyuda] = useState('busqueda')

  const nombreCompleto = usuario.nombre?.trim() || 'Usuario'
  const primerNombre = nombreCompleto.split(/\s+/)[0]

  const iniciales = nombreCompleto
    .split(/\s+/)
    .slice(0, 2)
    .map((palabra) => palabra.charAt(0).toUpperCase())
    .join('')

  const esAnfitrion = usuario.rol === 'ANFITRION'

  async function seleccionarFoto(evento) {
    const entrada = evento.currentTarget
    const archivo = entrada.files?.[0]

    if (!archivo) {
      return
    }

    if (!TIPOS_PERMITIDOS.includes(archivo.type)) {
      setMensajeFoto('La foto debe ser JPG, PNG o WebP.')
      entrada.value = ''
      return
    }

    if (archivo.size > MAXIMO_BYTES) {
      setMensajeFoto('La foto debe pesar máximo 5 MB.')
      entrada.value = ''
      return
    }

    setSubiendoFoto(true)
    setMensajeFoto('')

    try {
      const respuesta = await enviarArchivo(
        '/api/usuarios/perfil/foto',
        archivo
      )

      if (!respuesta.ok) {
        const error = await respuesta.json().catch(() => null)
        throw new Error(error?.message || 'No se pudo guardar la foto')
      }

      const usuarioActualizado = await respuesta.json()
      onUsuarioActualizado(usuarioActualizado)
      setMensajeFoto('Foto de perfil actualizada.')
    } catch (error) {
      setMensajeFoto(
        error.message || 'No se pudo actualizar la foto.'
      )
    } finally {
      setSubiendoFoto(false)
      entrada.value = ''
    }
  }

  async function eliminarFoto() {
    setEliminandoFoto(true)
    setMensajeFoto('')

    try {
      const respuesta = await enviarDatos(
        '/api/usuarios/perfil/foto',
        {},
        'DELETE'
      )

      if (!respuesta.ok) {
        throw new Error('No se pudo eliminar la foto')
      }

      const usuarioActualizado = await respuesta.json()
      onUsuarioActualizado(usuarioActualizado)
      setMensajeFoto('Foto de perfil eliminada.')
    } catch {
      setMensajeFoto('No se pudo eliminar la foto de perfil.')
    } finally {
      setEliminandoFoto(false)
    }
  }

  return (
    <section className="perfil-huesped">
      <div className="perfil-huesped-bienvenida">
        <div>
          <span className="perfil-huesped-etiqueta">
            MI CUENTA
          </span>

          <h1>¡Hola, {primerNombre}!</h1>

          <p>
            Administra tus viajes, alojamientos favoritos y
            datos personales desde un solo lugar.
          </p>
        </div>

        <button
          type="button"
          className="perfil-boton-principal"
          onClick={onExplorar}
        >
          Buscar alojamiento
        </button>
      </div>

      <div className="perfil-huesped-contenido">
        <div className="perfil-huesped-principal">
          <section className="perfil-accesos">
            <button
              type="button"
              className="perfil-acceso"
              onClick={onViajes}
            >
              <span className="perfil-acceso-icono" aria-hidden="true">
                ♧
              </span>
              <span>
                <strong>Mis viajes</strong>
                <small>Consulta tus reservas y próximos viajes.</small>
              </span>
              <span className="perfil-acceso-flecha" aria-hidden="true">
                →
              </span>
            </button>

            <button
              type="button"
              className="perfil-acceso"
              onClick={onFavoritos}
            >
              <span className="perfil-acceso-icono" aria-hidden="true">
                ♡
              </span>
              <span>
                <strong>Mis favoritos</strong>
                <small>
                  {cantidadFavoritos === 1
                    ? 'Tienes 1 alojamiento guardado.'
                    : `Tienes ${cantidadFavoritos} alojamientos guardados.`}
                </small>
              </span>
              <span className="perfil-acceso-flecha" aria-hidden="true">
                →
              </span>
            </button>

            {esAnfitrion && (
              <button
                type="button"
                className="perfil-acceso"
                onClick={onPanelAnfitrion}
              >
                <span className="perfil-acceso-icono" aria-hidden="true">
                  ⌂
                </span>
                <span>
                  <strong>Panel de anfitrión</strong>
                  <small>Administra tus alojamientos y reservas.</small>
                </span>
                <span className="perfil-acceso-flecha" aria-hidden="true">
                  →
                </span>
              </button>
            )}
          </section>

          <section className="perfil-informacion">
            <div className="perfil-seccion-encabezado">
              <div>
                <span className="perfil-seccion-etiqueta">
                  INFORMACIÓN PERSONAL
                </span>
                <h2>Datos de tu cuenta</h2>
              </div>
              <span className="perfil-estado-cuenta">Cuenta activa</span>
            </div>

            <dl className="perfil-informacion-lista">
              <div>
                <dt>Nombre completo</dt>
                <dd>{nombreCompleto}</dd>
              </div>
              <div>
                <dt>Correo electrónico</dt>
                <dd>{usuario.correo}</dd>
              </div>
              <div>
                <dt>Teléfono</dt>
                <dd>{usuario.telefono || 'Sin registrar'}</dd>
              </div>
              <div>
                <dt>Tipo de cuenta</dt>
                <dd>{esAnfitrion ? 'Anfitrión' : 'Huésped'}</dd>
              </div>
            </dl>
          </section>
        </div>

        <aside className="perfil-huesped-lateral">
          <section className="perfil-resumen">
            <div className="perfil-avatar-contenedor">
              <div className="perfil-avatar">
                {usuario.fotoUrl ? (
                  <img
                    src={usuario.fotoUrl}
                    alt={`Foto de perfil de ${nombreCompleto}`}
                  />
                ) : (
                  <span aria-hidden="true">{iniciales}</span>
                )}
              </div>

              <button
                type="button"
                className="perfil-cambiar-foto"
                onClick={() => entradaFoto.current?.click()}
                disabled={subiendoFoto}
                aria-label="Cambiar foto de perfil"
                title="Cambiar foto de perfil"
              >
                {subiendoFoto ? '…' : '📷'}
              </button>

              <input
                ref={entradaFoto}
                className="perfil-entrada-foto"
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={seleccionarFoto}
              />
            </div>

            <h2>{nombreCompleto}</h2>
            <p>{usuario.correo}</p>
            <span className="perfil-rol">
              {esAnfitrion ? 'Anfitrión' : 'Huésped'}
            </span>

            {usuario.fotoUrl && (
              <button
                type="button"
                className="perfil-eliminar-foto"
                onClick={eliminarFoto}
                disabled={eliminandoFoto || subiendoFoto}
              >
                {eliminandoFoto ? 'Eliminando...' : 'Eliminar foto'}
              </button>
            )}

            {mensajeFoto && (
              <p className="perfil-mensaje-foto" role="status">
                {mensajeFoto}
              </p>
            )}
          </section>

          {!esAnfitrion && (
            <section className="perfil-anfitrion-invitacion">
              <span aria-hidden="true">⌂</span>
              <h2>Comparte tu alojamiento</h2>
              <p>
                Conviértete en anfitrión con esta misma cuenta y
                comienza a publicar tus espacios.
              </p>
              <button type="button" onClick={onConvertirse}>
                Quiero ser anfitrión
              </button>
            </section>
          )}

          <section className="perfil-ayuda">
            <div className="perfil-ayuda-titulo">
              <span className="perfil-ayuda-icono" aria-hidden="true">
                ?
              </span>
              <div>
                <h2>¿Necesitas ayuda?</h2>
                <p>
                  Te ayudamos con tu búsqueda, tus reservas o
                  cualquier problema con tu cuenta.
                </p>
              </div>
            </div>

            <div className="perfil-ayuda-opciones">
              <button
                type="button"
                onClick={() => {
                  setTemaAyuda('busqueda')
                  setAyudaAbierta(true)
                }}
              >
                <span>Ayuda con mi búsqueda</span>
                <span aria-hidden="true">→</span>
              </button>

              <button
                type="button"
                onClick={() => {
                  setTemaAyuda('reserva')
                  setAyudaAbierta(true)
                }}
              >
                <span>Problemas con una reserva</span>
                <span aria-hidden="true">→</span>
              </button>

              <button
                type="button"
                onClick={() => {
                  setTemaAyuda('cuenta')
                  setAyudaAbierta(true)
                }}
              >
                <span>Problemas con mi cuenta</span>
                <span aria-hidden="true">→</span>
              </button>
            </div>

            <button
              type="button"
              className="perfil-ayuda-boton"
              onClick={() => setAyudaAbierta((abierta) => !abierta)}
              aria-expanded={ayudaAbierta}
              aria-controls="perfil-centro-ayuda"
            >
              {ayudaAbierta ? 'Cerrar ayuda' : 'Ir al centro de ayuda'}
            </button>

            {ayudaAbierta && (
              <div id="perfil-centro-ayuda" className="perfil-ayuda-detalle">
                {temaAyuda === 'busqueda' && (
                  <>
                    <h3>Ayuda con tu búsqueda</h3>
                    <p>
                      Revisa que la ciudad esté escrita correctamente,
                      que la fecha de salida sea posterior a la entrada y
                      que el alojamiento acepte la cantidad de huéspedes.
                    </p>
                    <button type="button" onClick={onExplorar}>
                      Volver a buscar
                    </button>
                  </>
                )}

                {temaAyuda === 'reserva' && (
                  <>
                    <h3>Ayuda con una reserva</h3>
                    <p>
                      En Mis viajes puedes consultar el estado, las fechas
                      y la información de cada reserva realizada.
                    </p>
                    <button type="button" onClick={onViajes}>
                      Ver mis viajes
                    </button>
                  </>
                )}

                {temaAyuda === 'cuenta' && (
                  <>
                    <h3>Ayuda con tu cuenta</h3>
                    <p>
                      Si tus datos no aparecen correctamente o no puedes
                      usar una función, cierra la sesión, vuelve a ingresar
                      y revisa de nuevo.
                    </p>
                  </>
                )}
              </div>
            )}
          </section>

          <button
            type="button"
            className="perfil-cerrar-sesion"
            onClick={onCerrarSesion}
            disabled={cerrando}
          >
            {cerrando ? 'Cerrando sesión...' : 'Cerrar sesión'}
          </button>
        </aside>
      </div>
    </section>
  )
}

export default PanelHuesped
