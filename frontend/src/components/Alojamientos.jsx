import { useEffect, useState } from 'react'
import { enviarDatos } from '../api'
import ImagenesAlojamiento from './ImagenesAlojamiento'
import { NOMBRES_TIPO } from '../tipos'
import { CIUDADES } from '../ciudades'

const formularioInicial = {
  titulo: '',
  descripcion: '',
  ciudad: '',
  direccion: '',
  tipoAlojamiento: 'APARTAMENTO',
  capacidad: '1',
  habitaciones: '1',
  banos: '1',
  horaCheckIn: '15:00',
  precioNoche: '',
  tarifaLimpieza: '0',
  tipoPolitica: 'MODERADA',
}


function Alojamientos({ onVolver }) {
  const [alojamientos, setAlojamientos] = useState([])
  const [formulario, setFormulario] =
    useState(formularioInicial)
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
          throw new Error(
            'No se pudieron consultar los alojamientos'
          )
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

  useEffect(() => {
    if (!mensaje) {
      return undefined
    }

    const temporizador = window.setTimeout(() => {
      setMensaje('')
    }, 4000)

    return () => {
      window.clearTimeout(temporizador)
    }
  }, [mensaje])

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
      habitaciones: Number(formulario.habitaciones || 1),
      banos: Number(formulario.banos || 1),
      horaCheckIn: formulario.horaCheckIn || '15:00',
      precioNoche: Number(formulario.precioNoche),
      tarifaLimpieza: Number(formulario.tarifaLimpieza || 0),
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
        throw new Error(
          'Solo una cuenta anfitrión puede gestionar alojamientos.'
        )
      }

      if (!respuesta.ok) {
        throw new Error(
          'No se pudo guardar el alojamiento.'
        )
      }

      const alojamientoGuardado =
        await respuesta.json()

      setAlojamientos((actuales) => {
        if (editandoId) {
          return actuales.map((alojamiento) =>
            alojamiento.idAlojamiento === editandoId
              ? alojamientoGuardado
              : alojamiento
          )
        }

        return [alojamientoGuardado, ...actuales]
      })

      setFormulario(formularioInicial)
      setEditandoId(null)

      setMensaje(
        editandoId
          ? 'Alojamiento actualizado correctamente.'
          : 'Alojamiento creado correctamente.'
      )
    } catch (error) {
      setMensaje(
        error.message ||
          'No se pudo guardar el alojamiento.'
      )
    } finally {
      setGuardando(false)
    }
  }

  function editarAlojamiento(alojamiento) {
    setEditandoId(alojamiento.idAlojamiento)

    setFormulario({
      titulo: alojamiento.titulo,
      descripcion: alojamiento.descripcion,
      ciudad: alojamiento.ciudad,
      direccion: alojamiento.direccion,
      tipoAlojamiento:
        alojamiento.tipoAlojamiento,
      capacidad: String(alojamiento.capacidad),
      habitaciones: String(alojamiento.habitaciones ?? 1),
      banos: String(alojamiento.banos ?? 1),
      horaCheckIn: (alojamiento.horaCheckIn ?? '15:00').slice(0, 5),
      precioNoche: String(alojamiento.precioNoche),
      tarifaLimpieza: String(alojamiento.tarifaLimpieza ?? 0),
      tipoPolitica: alojamiento.tipoPolitica ?? 'MODERADA',
    })

    setMensaje('')

    window.scrollTo({
      top: 0,
      behavior: 'smooth',
    })
  }

  function cancelarEdicion() {
    setEditandoId(null)
    setFormulario(formularioInicial)
    setMensaje('')
  }

  async function cambiarEstado(
    idAlojamiento,
    estado
  ) {
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
        if (respuesta.status === 400) {
          throw new Error(
            'Debes agregar al menos una fotografía antes de enviar el alojamiento a revisión.'
          )
        }

        throw new Error(
          'No se pudo cambiar el estado del alojamiento.'
        )
      }

      const actualizado = await respuesta.json()

      setAlojamientos((actuales) =>
        actuales.map((alojamiento) =>
          alojamiento.idAlojamiento ===
          idAlojamiento
            ? actualizado
            : alojamiento
        )
      )

      setMensaje(
        'Estado actualizado correctamente.'
      )
    } catch (error) {
      setMensaje(
        error.message ||
          'No se pudo cambiar el estado del alojamiento.'
      )
    }
  }

  function cambiarNumero(campo, cambio, minimo, maximo) {
    setFormulario((actual) => {
      const valor = Math.min(
        maximo,
        Math.max(minimo, Number(actual[campo] || minimo) + cambio)
      )
      return { ...actual, [campo]: String(valor) }
    })
  }

  const activos = alojamientos.filter(
    (alojamiento) => alojamiento.estado === 'ACTIVA'
  ).length

  const ciudadElegida = CIUDADES.find(
    (item) => item.ciudad === formulario.ciudad
  )

  return (
    <section className="mis-alojamientos">
      <nav className="migas-anfitrion" aria-label="Ubicación">
        <button type="button" onClick={onVolver}>
          Panel anfitrión
        </button>
        <span aria-hidden="true">›</span>
        <span>Mis alojamientos</span>
      </nav>

      <header className="mis-alojamientos-cabecera">
        <div>
          <h1 className="titulo-serif">Mis alojamientos</h1>
          <p className="texto-suave">
            Publica tus espacios y mantenlos al día para recibir más
            reservas.
          </p>
        </div>

        <div className="resumen-alojamientos">
          <div>
            <strong>{alojamientos.length}</strong>
            <span>publicados</span>
          </div>
          <div>
            <strong>{activos}</strong>
            <span>activos</span>
          </div>
        </div>
      </header>

      {mensaje && (
        <p role="status" className="aviso-flotante">
          {mensaje}
        </p>
      )}

      <div className="mis-alojamientos-columnas">
        <form
          className="formulario-alojamiento"
          onSubmit={guardarAlojamiento}
        >
          <div className="formulario-alojamiento-titulo">
            <h2>
              {editandoId ? 'Editar alojamiento' : 'Nuevo alojamiento'}
            </h2>
            {editandoId && (
              <span className="etiqueta-verde">Editando</span>
            )}
          </div>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">1</span>
              Información básica
            </legend>

            <div className="campo">
              <div className="campo-etiqueta">
                <label htmlFor="alojamiento-titulo">Título</label>
                <span className="contador">
                  {formulario.titulo.length}/120
                </span>
              </div>
              <input
                id="alojamiento-titulo"
                name="titulo"
                value={formulario.titulo}
                onChange={actualizarCampo}
                maxLength={120}
                placeholder="Cabaña con vista al lago"
                required
              />
            </div>

            <div className="campo">
              <div className="campo-etiqueta">
                <label htmlFor="alojamiento-descripcion">
                  Descripción
                </label>
                <span className="contador">
                  {formulario.descripcion.length}/5000
                </span>
              </div>
              <textarea
                id="alojamiento-descripcion"
                name="descripcion"
                value={formulario.descripcion}
                onChange={actualizarCampo}
                maxLength={5000}
                rows={5}
                placeholder="Cuenta qué hace especial tu alojamiento, cómo son los espacios y qué hay cerca."
                required
              />
            </div>
          </fieldset>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">2</span>
              Ubicación
            </legend>

            <div className="campos-dos">
              <div className="campo">
                <label htmlFor="alojamiento-ciudad">Ciudad</label>
                <select
                  id="alojamiento-ciudad"
                  name="ciudad"
                  value={formulario.ciudad}
                  onChange={actualizarCampo}
                  required
                >
                  <option value="">Elige la ciudad</option>

                  {formulario.ciudad && !ciudadElegida && (
                    <option value={formulario.ciudad}>
                      {formulario.ciudad}
                    </option>
                  )}

                  {CIUDADES.map((item) => (
                    <option key={item.ciudad} value={item.ciudad}>
                      {item.ciudad} ({item.departamento})
                    </option>
                  ))}
                </select>
              </div>

              <div className="campo">
                <label htmlFor="alojamiento-direccion">
                  Barrio o sector
                </label>
                <input
                  id="alojamiento-direccion"
                  name="direccion"
                  value={formulario.direccion}
                  onChange={actualizarCampo}
                  placeholder="Barrio o punto de referencia"
                  maxLength={200}
                  required
                />
              </div>
            </div>
          </fieldset>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">3</span>
              Espacio
            </legend>

            <div className="campo">
              <label htmlFor="alojamiento-tipo">Tipo de alojamiento</label>
              <select
                id="alojamiento-tipo"
                name="tipoAlojamiento"
                value={formulario.tipoAlojamiento}
                onChange={actualizarCampo}
                required
              >
                {Object.entries(NOMBRES_TIPO).map(([valor, nombre]) => (
                  <option key={valor} value={valor}>
                    {nombre}
                  </option>
                ))}
              </select>
            </div>

            <div className="contadores">
              {[
                ['capacidad', 'Huéspedes', 1, 16],
                ['habitaciones', 'Habitaciones', 1, 20],
                ['banos', 'Baños', 1, 20],
              ].map(([campo, texto, minimo, maximo]) => (
                <div className="contador-campo" key={campo}>
                  <span id={`etiqueta-${campo}`}>{texto}</span>
                  <div
                    className="contador-botones"
                    role="group"
                    aria-labelledby={`etiqueta-${campo}`}
                  >
                    <button
                      type="button"
                      aria-label={`Menos ${texto.toLowerCase()}`}
                      disabled={Number(formulario[campo]) <= minimo}
                      onClick={() => cambiarNumero(campo, -1, minimo, maximo)}
                    >
                      −
                    </button>
                    <strong aria-live="polite">{formulario[campo]}</strong>
                    <button
                      type="button"
                      aria-label={`Más ${texto.toLowerCase()}`}
                      disabled={Number(formulario[campo]) >= maximo}
                      onClick={() => cambiarNumero(campo, 1, minimo, maximo)}
                    >
                      +
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <div className="campo campo-corto">
              <label htmlFor="alojamiento-check-in">Hora de check-in</label>
              <input
                id="alojamiento-check-in"
                name="horaCheckIn"
                type="time"
                value={formulario.horaCheckIn}
                onChange={actualizarCampo}
                aria-describedby="ayuda-check-in"
                required
              />
              <small id="ayuda-check-in" className="ayuda">
                Desde esta hora el huésped puede hacer su check-in el día
                de llegada.
              </small>
            </div>
          </fieldset>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">4</span>
              Precio y cancelación
            </legend>

            <div className="campos-dos">
              <div className="campo">
                <label htmlFor="alojamiento-precio">Precio por noche</label>
                <div className="campo-dinero">
                  <span>$</span>
                  <input
                    id="alojamiento-precio"
                    name="precioNoche"
                    type="number"
                    inputMode="numeric"
                    value={formulario.precioNoche}
                    onChange={actualizarCampo}
                    min="1000"
                    step="1000"
                    placeholder="250000"
                    required
                  />
                  <span>COP</span>
                </div>
              </div>

              <div className="campo">
                <label htmlFor="alojamiento-limpieza">Tarifa de limpieza</label>
                <div className="campo-dinero">
                  <span>$</span>
                  <input
                    id="alojamiento-limpieza"
                    name="tarifaLimpieza"
                    type="number"
                    inputMode="numeric"
                    value={formulario.tarifaLimpieza}
                    onChange={actualizarCampo}
                    min="0"
                    step="1000"
                  />
                  <span>COP</span>
                </div>
              </div>
            </div>

            <div className="campo">
              <span className="etiqueta-campo">Política de cancelación</span>
              <div className="opciones-politica" role="radiogroup">
                {[
                  ['FLEXIBLE', 'Flexible', 'Devolución total hasta 1 día antes de la llegada.'],
                  ['MODERADA', 'Moderada', 'Total hasta 5 días antes; después, el 50 %.'],
                  ['ESTRICTA', 'Estricta', 'El 50 % hasta 7 días antes; después, nada.'],
                ].map(([valor, nombre, detalle]) => (
                  <label
                    key={valor}
                    className={
                      formulario.tipoPolitica === valor ? 'elegida' : ''
                    }
                  >
                    <input
                      type="radio"
                      name="tipoPolitica"
                      value={valor}
                      checked={formulario.tipoPolitica === valor}
                      onChange={actualizarCampo}
                    />
                    <strong>{nombre}</strong>
                    <span>{detalle}</span>
                  </label>
                ))}
              </div>
            </div>
          </fieldset>

          <div className="acciones-alojamiento-form">
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
            <button
              type="submit"
              className="boton-principal"
              disabled={guardando}
            >
              {guardando
                ? 'Guardando...'
                : editandoId
                  ? 'Guardar cambios'
                  : 'Crear alojamiento'}
            </button>
          </div>

          {!editandoId && (
            <p className="ayuda centrada">
              Se guarda como borrador. Agrega fotos y cámbialo a
              &quot;Activa&quot; para que los huéspedes lo vean.
            </p>
          )}
        </form>

        <aside className="vista-previa">
          <p className="etiqueta-vista">Vista previa</p>
          <div className="vista-previa-tarjeta">
            <div className="vista-previa-foto">
              <span>{NOMBRES_TIPO[formulario.tipoAlojamiento]}</span>
            </div>
            <div className="vista-previa-info">
              <strong>
                {formulario.titulo || 'Título de tu alojamiento'}
              </strong>
              <span className="texto-suave">
                {formulario.ciudad
                  ? `${formulario.ciudad}${ciudadElegida ? `, ${ciudadElegida.departamento}` : ''}`
                  : 'Ciudad'}
              </span>
              <span className="texto-suave">
                {formulario.capacidad} huéspedes · {formulario.habitaciones}{' '}
                {Number(formulario.habitaciones) === 1 ? 'habitación' : 'habitaciones'} ·{' '}
                {formulario.banos} {Number(formulario.banos) === 1 ? 'baño' : 'baños'}
              </span>
              <span>
                <strong>
                  {formulario.precioNoche
                    ? `$${Number(formulario.precioNoche).toLocaleString('es-CO')} COP`
                    : '$— COP'}
                </strong>{' '}
                noche
              </span>
            </div>
          </div>

          <ul className="consejos-anfitrion">
            <li>Un título corto y claro atrae más visitas.</li>
            <li>Agrega al menos 5 fotos con buena luz.</li>
            <li>Describe qué hay cerca: playas, parques, restaurantes.</li>
          </ul>
        </aside>
      </div>

      <section className="lista-mis-alojamientos">
        <h2>Alojamientos registrados</h2>

        {cargando ? (
          <p className="cargando">Cargando alojamientos...</p>
        ) : alojamientos.length === 0 ? (
          <div className="tarjeta vacio">
            <span aria-hidden="true">🏡</span>
            <h3>Aún no tienes alojamientos</h3>
            <p className="texto-suave">
              Completa el formulario de arriba para publicar el primero.
            </p>
          </div>
        ) : (
          <div className="grilla-mis-alojamientos">
            {alojamientos.map((alojamiento) => (
              <article
                className="tarjeta tarjeta-mi-alojamiento"
                key={alojamiento.idAlojamiento}
              >
                <div className="tarjeta-mi-alojamiento-cabecera">
                  <div>
                    <h3>{alojamiento.titulo}</h3>
                    <p className="texto-suave">
                      {alojamiento.ciudad} ·{' '}
                      {NOMBRES_TIPO[alojamiento.tipoAlojamiento] ??
                        alojamiento.tipoAlojamiento}
                    </p>
                  </div>
                  <span
                    className={`estado estado-${alojamiento.estado.toLowerCase()}`}
                  >
                    {alojamiento.estado.replaceAll('_', ' ').toLowerCase()}
                  </span>
                </div>

                <ul className="datos-mi-alojamiento">
                  <li>
                    <strong>
                      ${Number(alojamiento.precioNoche).toLocaleString('es-CO')}
                    </strong>
                    noche
                  </li>
                  <li>
                    <strong>{alojamiento.capacidad}</strong>
                    huéspedes
                  </li>
                  <li>
                    <strong>{alojamiento.habitaciones ?? 1}</strong>
                    {(alojamiento.habitaciones ?? 1) === 1 ? 'habitación' : 'habitaciones'}
                  </li>
                  <li>
                    <strong>{alojamiento.banos ?? 1}</strong>
                    {(alojamiento.banos ?? 1) === 1 ? 'baño' : 'baños'}
                  </li>
                </ul>

                <div className="acciones-mi-alojamiento">
                  <button
                    type="button"
                    className="boton-secundario"
                    onClick={() => editarAlojamiento(alojamiento)}
                  >
                    Editar
                  </button>

                  <select
                    aria-label={`Cambiar estado de ${alojamiento.titulo}`}
                    value={alojamiento.estado}
                    onChange={(evento) =>
                      cambiarEstado(alojamiento.idAlojamiento, evento.target.value)
                    }
                  >
                    <option value="BORRADOR">Borrador</option>
                    <option value="PENDIENTE_REVISION">Pendiente de revisión</option>
                    <option value="ACTIVA">Activa</option>
                    <option value="PAUSADA">Pausada</option>
                    {alojamiento.estado === 'BLOQUEADA' && (
                      <option value="BLOQUEADA" disabled>
                        Bloqueada por el administrador
                      </option>
                    )}
                  </select>
                </div>

                <details className="fotos-mi-alojamiento">
                  <summary>Fotos del alojamiento</summary>
                  <ImagenesAlojamiento
                    idAlojamiento={alojamiento.idAlojamiento}
                  />
                </details>
              </article>
            ))}
          </div>
        )}
      </section>
    </section>
  )
}

export default Alojamientos