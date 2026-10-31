import { useEffect, useState } from 'react'
import { enviarDatos } from '../api'

const formularioInicial = {
  titulo: '',
  descripcion: '',
  ciudad: '',
  direccion: '',
  tipoAlojamiento: 'APARTAMENTO',
  capacidad: '1',
  precioNoche: '',
}

function Alojamientos({ onVolver }) {
  const [alojamientos, setAlojamientos] = useState([])
  const [formulario, setFormulario] = useState(formularioInicial)
  const [editandoId, setEditandoId] = useState(null)
  const [cargando, setCargando] = useState(true)
  const [guardando, setGuardando] = useState(false)
  const [mensaje, setMensaje] = useState('')

  useEffect(() => {
    let activo = true

    async function cargarAlojamientos() {
      try {
        const respuesta = await fetch(
          '/api/v1/alojamientos/mis-alojamientos',
          {
            credentials: 'same-origin',
            cache: 'no-store',
          }
        )

        if (respuesta.status === 403) {
          if (activo) {
            setMensaje(
              'Esta cuenta no tiene permisos de anfitrión.'
            )
          }
          return
        }

        if (!respuesta.ok) {
          throw new Error('No se pudieron consultar los alojamientos')
        }

        const datos = await respuesta.json()

        if (activo) {
          setAlojamientos(datos)
        }
      } catch {
        if (activo) {
          setMensaje(
            'No se pudieron cargar los alojamientos.'
          )
        }
      } finally {
        if (activo) {
          setCargando(false)
        }
      }
    }

    cargarAlojamientos()

    return () => {
      activo = false
    }
  }, [])

  function actualizarCampo(evento) {
    const { name, value } = evento.target

    setFormulario((actual) => ({
      ...actual,
      [name]: value,
    }))
  }

  async function guardarAlojamiento(evento) {
    evento.preventDefault()

    setGuardando(true)
    setMensaje('')

    const datos = {
      ...formulario,
      capacidad: Number(formulario.capacidad),
      precioNoche: Number(formulario.precioNoche),
    }

    const ruta = editandoId
      ? `/api/v1/alojamientos/${editandoId}`
      : '/api/v1/alojamientos'

    const metodo = editandoId ? 'PUT' : 'POST'

    try {
      const respuesta = await enviarDatos(
        ruta,
        datos,
        metodo
      )

      if (respuesta.status === 403) {
        setMensaje(
          'Solo una cuenta anfitrión puede gestionar alojamientos.'
        )
        return
      }

      if (respuesta.status === 400) {
        setMensaje(
          'Revisa la información ingresada en el formulario.'
        )
        return
      }

      if (!respuesta.ok) {
        throw new Error('No se pudo guardar el alojamiento')
      }

      const guardado = await respuesta.json()

      setAlojamientos((actuales) => {
        if (editandoId) {
          return actuales.map((alojamiento) =>
            alojamiento.idAlojamiento === editandoId
              ? guardado
              : alojamiento
          )
        }

        return [guardado, ...actuales]
      })

      setFormulario(formularioInicial)
      setEditandoId(null)
      setMensaje(
        editandoId
          ? 'Alojamiento actualizado correctamente.'
          : 'Alojamiento creado correctamente.'
      )
    } catch {
      setMensaje(
        'No se pudo guardar el alojamiento. Intenta nuevamente.'
      )
    } finally {
      setGuardando(false)
    }
  }

  function editarAlojamiento(alojamiento) {
    setFormulario({
      titulo: alojamiento.titulo,
      descripcion: alojamiento.descripcion,
      ciudad: alojamiento.ciudad,
      direccion: alojamiento.direccion,
      tipoAlojamiento: alojamiento.tipoAlojamiento,
      capacidad: String(alojamiento.capacidad),
      precioNoche: String(alojamiento.precioNoche),
    })

    setEditandoId(alojamiento.idAlojamiento)
    setMensaje('')

    window.scrollTo({
      top: 0,
      behavior: 'smooth',
    })
  }

  function cancelarEdicion() {
    setFormulario(formularioInicial)
    setEditandoId(null)
    setMensaje('')
  }

  async function cambiarEstado(idAlojamiento, estado) {
    setMensaje('')

    try {
      const ruta =
        `/api/v1/alojamientos/${idAlojamiento}` +
        `/estado?estado=${encodeURIComponent(estado)}`

      const respuesta = await enviarDatos(
        ruta,
        {},
        'PATCH'
      )

      if (!respuesta.ok) {
        throw new Error('No se pudo cambiar el estado')
      }

      const actualizado = await respuesta.json()

      setAlojamientos((actuales) =>
        actuales.map((alojamiento) =>
          alojamiento.idAlojamiento === idAlojamiento
            ? actualizado
            : alojamiento
        )
      )

      setMensaje('Estado actualizado correctamente.')
    } catch {
      setMensaje(
        'No se pudo cambiar el estado del alojamiento.'
      )
    }
  }

  return (
    <section className="alojamientos-panel">
      <div className="alojamientos-encabezado">
        <button
          type="button"
          className="boton-enlace"
          onClick={onVolver}
        >
          ← Volver al perfil
        </button>

        <h1>Mis alojamientos</h1>

        <p>
          Crea y administra los alojamientos que compartes en
          StayHub.
        </p>
      </div>

      <form
        className="alojamiento-formulario"
        onSubmit={guardarAlojamiento}
      >
        <h2>
          {editandoId
            ? 'Editar alojamiento'
            : 'Nuevo alojamiento'}
        </h2>

        <div>
          <label htmlFor="alojamiento-titulo">
            Título
          </label>

          <input
            id="alojamiento-titulo"
            name="titulo"
            value={formulario.titulo}
            onChange={actualizarCampo}
            maxLength={150}
            required
          />
        </div>

        <div>
          <label htmlFor="alojamiento-descripcion">
            Descripción
          </label>

          <textarea
            id="alojamiento-descripcion"
            name="descripcion"
            value={formulario.descripcion}
            onChange={actualizarCampo}
            maxLength={2000}
            rows={4}
            required
          />
        </div>

        <div className="formulario-dos-columnas">
          <div>
            <label htmlFor="alojamiento-ciudad">
              Ciudad
            </label>

            <input
              id="alojamiento-ciudad"
              name="ciudad"
              value={formulario.ciudad}
              onChange={actualizarCampo}
              maxLength={150}
              required
            />
          </div>

          <div>
            <label htmlFor="alojamiento-direccion">
              Dirección
            </label>

            <input
              id="alojamiento-direccion"
              name="direccion"
              value={formulario.direccion}
              onChange={actualizarCampo}
              maxLength={150}
              required
            />
          </div>
        </div>

        <div className="formulario-dos-columnas">
          <div>
            <label htmlFor="alojamiento-tipo">
              Tipo de alojamiento
            </label>

            <select
              id="alojamiento-tipo"
              name="tipoAlojamiento"
              value={formulario.tipoAlojamiento}
              onChange={actualizarCampo}
              required
            >
              <option value="APARTAMENTO">
                Apartamento
              </option>
              <option value="CASA">Casa</option>
              <option value="HABITACION">
                Habitación
              </option>
              <option value="FINCA">Finca</option>
              <option value="CABAÑA">Cabaña</option>
              <option value="OTRO">Otro</option>
            </select>
          </div>

          <div>
            <label htmlFor="alojamiento-capacidad">
              Capacidad
            </label>

            <input
              id="alojamiento-capacidad"
              name="capacidad"
              type="number"
              value={formulario.capacidad}
              onChange={actualizarCampo}
              min="1"
              step="1"
              required
            />
          </div>
        </div>

        <div>
          <label htmlFor="alojamiento-precio">
            Precio por noche
          </label>

          <input
            id="alojamiento-precio"
            name="precioNoche"
            type="number"
            value={formulario.precioNoche}
            onChange={actualizarCampo}
            min="0.01"
            step="0.01"
            required
          />
        </div>

        <div className="acciones-formulario">
          <button type="submit" disabled={guardando}>
            {guardando
              ? 'Guardando...'
              : editandoId
                ? 'Guardar cambios'
                : 'Crear alojamiento'}
          </button>

          {editandoId && (
            <button
              type="button"
              className="boton-secundario"
              onClick={cancelarEdicion}
              disabled={guardando}
            >
              Cancelar
            </button>
          )}
        </div>
      </form>

      <p role="status" className="mensaje-alojamientos">
        {mensaje}
      </p>

      <div className="alojamientos-lista">
        <h2>Alojamientos registrados</h2>

        {cargando ? (
          <p>Cargando alojamientos...</p>
        ) : alojamientos.length === 0 ? (
          <p>Todavía no tienes alojamientos registrados.</p>
        ) : (
          alojamientos.map((alojamiento) => (
            <article
              className="alojamiento-tarjeta"
              key={alojamiento.idAlojamiento}
            >
              <div className="alojamiento-tarjeta-cabecera">
                <div>
                  <h3>{alojamiento.titulo}</h3>
                  <p>
                    {alojamiento.ciudad} ·{' '}
                    {alojamiento.tipoAlojamiento}
                  </p>
                </div>

                <span
                  className={`estado estado-${alojamiento.estado.toLowerCase()}`}
                >
                  {alojamiento.estado.replaceAll('_', ' ')}
                </span>
              </div>

              <p>{alojamiento.descripcion}</p>

              <dl>
                <div>
                  <dt>Capacidad</dt>
                  <dd>{alojamiento.capacidad} personas</dd>
                </div>

                <div>
                  <dt>Precio por noche</dt>
                  <dd>
                    ${Number(
                      alojamiento.precioNoche
                    ).toLocaleString('es-CO')}
                  </dd>
                </div>
              </dl>

              <div className="acciones-alojamiento">
                <button
                  type="button"
                  className="boton-secundario"
                  onClick={() =>
                    editarAlojamiento(alojamiento)
                  }
                >
                  Editar
                </button>

                <select
                  aria-label={`Cambiar estado de ${alojamiento.titulo}`}
                  value={alojamiento.estado}
                  onChange={(evento) =>
                    cambiarEstado(
                      alojamiento.idAlojamiento,
                      evento.target.value
                    )
                  }
                >
                  <option value="BORRADOR">Borrador</option>
                  <option value="PENDIENTE_REVISION">
                    Pendiente de revisión
                  </option>
                  <option value="ACTIVO">Activo</option>
                  <option value="PAUSADO">Pausado</option>
                </select>
              </div>
            </article>
          ))
        )}
      </div>
    </section>
  )
}

export default Alojamientos