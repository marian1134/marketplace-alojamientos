import { t, useIdioma, localeActual } from '../idiomas'
import { useEffect, useState } from 'react';
import { enviarDatos } from '../api';
import ImagenesAlojamiento from './ImagenesAlojamiento';
import { NOMBRES_TIPO } from '../tipos';
import { CIUDADES } from '../ciudades';
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
    servicios: [],
    reglas: '',
};
function Alojamientos({ onVolver }) {
    useIdioma();
    const [alojamientos, setAlojamientos] = useState([]);
    const [formulario, setFormulario] = useState(formularioInicial);
    const [editandoId, setEditandoId] = useState(null);
    const [cargando, setCargando] = useState(true);
    const [guardando, setGuardando] = useState(false);
    const [mensaje, setMensaje] = useState('');
    // Catálogo de servicios (Wifi, piscina, cocina...)
    const [catalogo, setCatalogo] = useState([]);
    useEffect(() => {
        fetch('/api/v1/alojamientos/servicios', { credentials: 'same-origin' })
            .then((respuesta) => (respuesta.ok ? respuesta.json() : []))
            .then(setCatalogo)
            .catch(() => { });
    }, []);
    function cambiarServicio(id) {
        setFormulario((actual) => ({
            ...actual,
            servicios: actual.servicios.includes(id)
                ? actual.servicios.filter((elegido) => elegido !== id)
                : [...actual.servicios, id],
        }));
    }
    useEffect(() => {
        let activo = true;
        async function cargarAlojamientos() {
            try {
                const respuesta = await fetch('/api/v1/alojamientos/mis-alojamientos', {
                    credentials: 'same-origin',
                    cache: 'no-store',
                });
                if (respuesta.status === 403) {
                    if (activo) {
                        setMensaje(t("Esta cuenta no tiene permisos de anfitri\u00F3n."));
                    }
                    return;
                }
                if (!respuesta.ok) {
                    throw new Error(t("No se pudieron consultar los alojamientos"));
                }
                const datos = await respuesta.json();
                if (activo) {
                    setAlojamientos(datos);
                }
            }
            catch {
                if (activo) {
                    setMensaje(t("No se pudieron cargar los alojamientos."));
                }
            }
            finally {
                if (activo) {
                    setCargando(false);
                }
            }
        }
        cargarAlojamientos();
        return () => {
            activo = false;
        };
    }, []);
    useEffect(() => {
        if (!mensaje) {
            return undefined;
        }
        const temporizador = window.setTimeout(() => {
            setMensaje('');
        }, 4000);
        return () => {
            window.clearTimeout(temporizador);
        };
    }, [mensaje]);
    function actualizarCampo(evento) {
        const { name, value } = evento.target;
        setFormulario((actual) => ({
            ...actual,
            [name]: value,
        }));
    }
    async function guardarAlojamiento(evento) {
        evento.preventDefault();
        setGuardando(true);
        setMensaje('');
        const datos = {
            ...formulario,
            capacidad: Number(formulario.capacidad),
            habitaciones: Number(formulario.habitaciones || 1),
            banos: Number(formulario.banos || 1),
            horaCheckIn: formulario.horaCheckIn || '15:00',
            precioNoche: Number(formulario.precioNoche),
            tarifaLimpieza: Number(formulario.tarifaLimpieza || 0),
            // Una regla por línea
            reglas: formulario.reglas.split('\n').map((regla) => regla.trim()).filter(Boolean).slice(0, 10),
        };
        const ruta = editandoId
            ? `/api/v1/alojamientos/${editandoId}`
            : '/api/v1/alojamientos';
        const metodo = editandoId ? 'PUT' : 'POST';
        try {
            const respuesta = await enviarDatos(ruta, datos, metodo);
            if (respuesta.status === 403) {
                throw new Error(t("Solo una cuenta anfitri\u00F3n puede gestionar alojamientos."));
            }
            if (!respuesta.ok) {
                throw new Error(t("No se pudo guardar el alojamiento."));
            }
            const alojamientoGuardado = await respuesta.json();
            setAlojamientos((actuales) => {
                if (editandoId) {
                    return actuales.map((alojamiento) => alojamiento.idAlojamiento === editandoId
                        ? alojamientoGuardado
                        : alojamiento);
                }
                return [alojamientoGuardado, ...actuales];
            });
            setFormulario(formularioInicial);
            setEditandoId(null);
            setMensaje(editandoId
                ? t("Alojamiento actualizado correctamente.") : t("Alojamiento creado correctamente."));
        }
        catch (error) {
            setMensaje(error.message || t("No se pudo guardar el alojamiento."));
        }
        finally {
            setGuardando(false);
        }
    }
    function editarAlojamiento(alojamiento) {
        setEditandoId(alojamiento.idAlojamiento);
        setFormulario({
            titulo: alojamiento.titulo,
            descripcion: alojamiento.descripcion,
            ciudad: alojamiento.ciudad,
            direccion: alojamiento.direccion,
            tipoAlojamiento: alojamiento.tipoAlojamiento,
            capacidad: String(alojamiento.capacidad),
            habitaciones: String(alojamiento.habitaciones ?? 1),
            banos: String(alojamiento.banos ?? 1),
            horaCheckIn: (alojamiento.horaCheckIn ?? '15:00').slice(0, 5),
            precioNoche: String(alojamiento.precioNoche),
            tarifaLimpieza: String(alojamiento.tarifaLimpieza ?? 0),
            tipoPolitica: alojamiento.tipoPolitica ?? 'MODERADA',
            servicios: catalogo.filter((servicio) => (alojamiento.servicios ?? []).includes(servicio.nombre)).map((servicio) => servicio.id),
            reglas: (alojamiento.reglas ?? []).join('\n'),
        });
        setMensaje('');
        window.scrollTo({
            top: 0,
            behavior: 'smooth',
        });
    }
    function cancelarEdicion() {
        setEditandoId(null);
        setFormulario(formularioInicial);
        setMensaje('');
    }
    async function cambiarEstado(idAlojamiento, estado) {
        setMensaje('');
        try {
            const ruta = `/api/v1/alojamientos/${idAlojamiento}` +
                `/estado?estado=${encodeURIComponent(estado)}`;
            const respuesta = await enviarDatos(ruta, {}, 'PATCH');
            if (!respuesta.ok) {
                if (respuesta.status === 400) {
                    throw new Error(t("Debes agregar al menos una fotograf\u00EDa antes de enviar el alojamiento a revisi\u00F3n."));
                }
                throw new Error(t("No se pudo cambiar el estado del alojamiento."));
            }
            const actualizado = await respuesta.json();
            setAlojamientos((actuales) => actuales.map((alojamiento) => alojamiento.idAlojamiento ===
                idAlojamiento
                ? actualizado
                : alojamiento));
            setMensaje(t("Estado actualizado correctamente."));
        }
        catch (error) {
            setMensaje(error.message || t("No se pudo cambiar el estado del alojamiento."));
        }
    }
    function cambiarNumero(campo, cambio, minimo, maximo) {
        setFormulario((actual) => {
            const valor = Math.min(maximo, Math.max(minimo, Number(actual[campo] || minimo) + cambio));
            return { ...actual, [campo]: String(valor) };
        });
    }
    const activos = alojamientos.filter((alojamiento) => alojamiento.estado === 'ACTIVA').length;
    const ciudadElegida = CIUDADES.find((item) => item.ciudad === formulario.ciudad);
    return (<section className="mis-alojamientos">
      <nav className="migas-anfitrion" aria-label={t("Ubicaci\u00F3n")}>
        <button type="button" onClick={onVolver}>{t("Panel anfitri\u00F3n")}</button>
        <span aria-hidden="true">›</span>
        <span>{t("Mis alojamientos")}</span>
      </nav>

      <header className="mis-alojamientos-cabecera">
        <div>
          <h1 className="titulo-serif">{t("Mis alojamientos")}</h1>
          <p className="texto-suave">{t("Publica tus espacios y mantenlos al d\u00EDa para recibir m\u00E1s reservas.")}</p>
        </div>

        <div className="resumen-alojamientos">
          <div>
            <strong>{alojamientos.length}</strong>
            <span>{t("publicados")}</span>
          </div>
          <div>
            <strong>{activos}</strong>
            <span>{t("activos")}</span>
          </div>
        </div>
      </header>

      {mensaje && (<p role="status" className="aviso-flotante">
          {t(mensaje)}
        </p>)}

      <div className="mis-alojamientos-columnas">
        <form className="formulario-alojamiento" onSubmit={guardarAlojamiento}>
          <div className="formulario-alojamiento-titulo">
            <h2>
              {editandoId ? t("Editar alojamiento") : t("Nuevo alojamiento")}
            </h2>
            {editandoId && (<span className="etiqueta-verde">{t("Editando")}</span>)}
          </div>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">1</span>{t("Informaci\u00F3n b\u00E1sica")}</legend>

            <div className="campo">
              <div className="campo-etiqueta">
                <label htmlFor="alojamiento-titulo">{t("T\u00EDtulo")}</label>
                <span className="contador">
                  {formulario.titulo.length}/120
                </span>
              </div>
              <input id="alojamiento-titulo" name="titulo" value={formulario.titulo} onChange={actualizarCampo} maxLength={120} placeholder={t("Caba\u00F1a con vista al lago")} required/>
            </div>

            <div className="campo">
              <div className="campo-etiqueta">
                <label htmlFor="alojamiento-descripcion">{t("Descripci\u00F3n")}</label>
                <span className="contador">
                  {formulario.descripcion.length}/5000
                </span>
              </div>
              <textarea id="alojamiento-descripcion" name="descripcion" value={formulario.descripcion} onChange={actualizarCampo} maxLength={5000} rows={5} placeholder={t("Cuenta qu\u00E9 hace especial tu alojamiento, c\u00F3mo son los espacios y qu\u00E9 hay cerca.")} required/>
            </div>
          </fieldset>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">2</span>{t("Ubicaci\u00F3n")}</legend>

            <div className="campos-dos">
              <div className="campo">
                <label htmlFor="alojamiento-ciudad">{t("Ciudad")}</label>
                <select id="alojamiento-ciudad" name="ciudad" value={formulario.ciudad} onChange={actualizarCampo} required>
                  <option value="">{t("Elige la ciudad")}</option>

                  {formulario.ciudad && !ciudadElegida && (<option value={formulario.ciudad}>
                      {formulario.ciudad}
                    </option>)}

                  {CIUDADES.map((item) => (<option key={item.ciudad} value={item.ciudad}>
                      {item.ciudad} ({item.departamento})
                    </option>))}
                </select>
              </div>

              <div className="campo">
                <label htmlFor="alojamiento-direccion">{t("Barrio o sector")}</label>
                <input id="alojamiento-direccion" name="direccion" value={formulario.direccion} onChange={actualizarCampo} placeholder={t("Barrio o punto de referencia")} maxLength={200} required/>
              </div>
            </div>
          </fieldset>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">3</span>{t("Espacio")}</legend>

            <div className="campo">
              <label htmlFor="alojamiento-tipo">{t("Tipo de alojamiento")}</label>
              <select id="alojamiento-tipo" name="tipoAlojamiento" value={formulario.tipoAlojamiento} onChange={actualizarCampo} required>
                {Object.entries(NOMBRES_TIPO).map(([valor, nombre]) => (<option key={valor} value={valor}>
                    {t(nombre)}
                  </option>))}
              </select>
            </div>

            <div className="contadores">
              {[
            ['capacidad', t("Hu\u00E9spedes"), 1, 16],
            [t("habitaciones"), t("Habitaciones"), 1, 20],
            ['banos', t("Ba\u00F1os"), 1, 20],
        ].map(([campo, texto, minimo, maximo]) => (<div className="contador-campo" key={campo}>
                  <span id={`etiqueta-${campo}`}>{t(texto)}</span>
                  <div className="contador-botones" role="group" aria-labelledby={`etiqueta-${campo}`}>
                    <button type="button" aria-label={t(t("Menos {0}", texto.toLowerCase()))} disabled={Number(formulario[campo]) <= minimo} onClick={() => cambiarNumero(campo, -1, minimo, maximo)}>
                      −
                    </button>
                    <strong aria-live="polite">{formulario[campo]}</strong>
                    <button type="button" aria-label={t(t("M\u00E1s {0}", texto.toLowerCase()))} disabled={Number(formulario[campo]) >= maximo} onClick={() => cambiarNumero(campo, 1, minimo, maximo)}>
                      +
                    </button>
                  </div>
                </div>))}
            </div>

            <div className="campo campo-corto">
              <label htmlFor="alojamiento-check-in">{t("Hora de check-in")}</label>
              <input id="alojamiento-check-in" name="horaCheckIn" type="time" value={formulario.horaCheckIn} onChange={actualizarCampo} aria-describedby="ayuda-check-in" required/>
              <small id="ayuda-check-in" className="ayuda">{t("Desde esta hora el hu\u00E9sped puede hacer su check-in el d\u00EDa de llegada.")}</small>
            </div>
          </fieldset>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">4</span>{t("Precio y cancelaci\u00F3n")}</legend>

            <div className="campos-dos">
              <div className="campo">
                <label htmlFor="alojamiento-precio">{t("Precio por noche")}</label>
                <div className="campo-dinero">
                  <span>$</span>
                  <input id="alojamiento-precio" name="precioNoche" type="number" inputMode="numeric" value={formulario.precioNoche} onChange={actualizarCampo} min="1000" step="1000" placeholder="250000" required/>
                  <span>COP</span>
                </div>
              </div>

              <div className="campo">
                <label htmlFor="alojamiento-limpieza">{t("Tarifa de limpieza")}</label>
                <div className="campo-dinero">
                  <span>$</span>
                  <input id="alojamiento-limpieza" name="tarifaLimpieza" type="number" inputMode="numeric" value={formulario.tarifaLimpieza} onChange={actualizarCampo} min="0" step="1000"/>
                  <span>COP</span>
                </div>
              </div>
            </div>

            <div className="campo">
              <span className="etiqueta-campo">{t("Pol\u00EDtica de cancelaci\u00F3n")}</span>
              <div className="opciones-politica" role="radiogroup">
                {[
            ['FLEXIBLE', t("Flexible"), t("Devoluci\u00F3n total hasta 1 d\u00EDa antes de la llegada.")],
            ['MODERADA', t("Moderada"), t("Total hasta 5 d\u00EDas antes; despu\u00E9s, el 50 %.")],
            ['ESTRICTA', t("Estricta"), t("El 50 % hasta 7 d\u00EDas antes; despu\u00E9s, nada.")],
        ].map(([valor, nombre, detalle]) => (<label key={valor} className={formulario.tipoPolitica === valor ? 'elegida' : ''}>
                    <input type="radio" name="tipoPolitica" value={valor} checked={formulario.tipoPolitica === valor} onChange={actualizarCampo}/>
                    <strong>{t(nombre)}</strong>
                    <span>{t(detalle)}</span>
                  </label>))}
              </div>
            </div>
          </fieldset>

          <fieldset className="seccion-formulario">
            <legend>
              <span className="numero-seccion">5</span>{t("Servicios y reglas")}</legend>

            <div className="campo">
              <span className="etiqueta-servicios">{t("Servicios que ofreces")}</span>
              <div className="servicios-opciones">
                {catalogo.map((servicio) => (<label key={servicio.id} className={formulario.servicios.includes(servicio.id) ? 'servicio-opcion elegido' : 'servicio-opcion'}>
                    <input type="checkbox" checked={formulario.servicios.includes(servicio.id)} onChange={() => cambiarServicio(servicio.id)}/>
                    {t(servicio.nombre)}
                  </label>))}
              </div>
            </div>

            <div className="campo">
              <label htmlFor="alojamiento-reglas">{t("Reglas del alojamiento (una por línea)")}</label>
              <textarea id="alojamiento-reglas" name="reglas" rows={4} value={formulario.reglas} onChange={actualizarCampo} placeholder={t("No se permite fumar dentro del alojamiento.")} maxLength={3000}/>
            </div>
          </fieldset>

          <div className="acciones-alojamiento-form">
            {editandoId && (<button type="button" className="boton-secundario" onClick={cancelarEdicion} disabled={guardando}>{t("Cancelar")}</button>)}
            <button type="submit" className="boton-principal" disabled={guardando}>
              {guardando
            ? t("Guardando...") : editandoId
            ? t("Guardar cambios") : t("Crear alojamiento")}
            </button>
          </div>

          {!editandoId && (<p className="ayuda centrada">{t("Se guarda como borrador. Agrega fotos y c\u00E1mbialo a \"Activa\" para que los hu\u00E9spedes lo vean.")}</p>)}
        </form>

        <aside className="vista-previa">
          <p className="etiqueta-vista">{t("Vista previa")}</p>
          <div className="vista-previa-tarjeta">
            <div className="vista-previa-foto">
              <span>{t(NOMBRES_TIPO[formulario.tipoAlojamiento])}</span>
            </div>
            <div className="vista-previa-info">
              <strong>
                {formulario.titulo || t("T\u00EDtulo de tu alojamiento")}
              </strong>
              <span className="texto-suave">
                {formulario.ciudad
            ? `${formulario.ciudad}${ciudadElegida ? `, ${ciudadElegida.departamento}` : ''}`
            : t("Ciudad")}
              </span>
              <span className="texto-suave">
                {formulario.capacidad}{t(" hu\u00E9spedes \u00B7 ")}{formulario.habitaciones}{' '}
                {Number(formulario.habitaciones) === 1 ? t("habitaci\u00F3n") : t("habitaciones")} ·{' '}
                {formulario.banos} {Number(formulario.banos) === 1 ? t("ba\u00F1o") : t("ba\u00F1os")}
              </span>
              <span>
                <strong>
                  {formulario.precioNoche
            ? `$${Number(formulario.precioNoche).toLocaleString(localeActual())} COP`
            : '$— COP'}
                </strong>{' '}{t("noche")}</span>
            </div>
          </div>

          <ul className="consejos-anfitrion">
            <li>{t("Un t\u00EDtulo corto y claro atrae m\u00E1s visitas.")}</li>
            <li>{t("Agrega al menos 5 fotos con buena luz.")}</li>
            <li>{t("Describe qu\u00E9 hay cerca: playas, parques, restaurantes.")}</li>
          </ul>
        </aside>
      </div>

      <section className="lista-mis-alojamientos">
        <h2>{t("Alojamientos registrados")}</h2>

        {cargando ? (<p className="cargando">{t("Cargando alojamientos...")}</p>) : alojamientos.length === 0 ? (<div className="tarjeta vacio">
            <span aria-hidden="true">🏡</span>
            <h3>{t("A\u00FAn no tienes alojamientos")}</h3>
            <p className="texto-suave">{t("Completa el formulario de arriba para publicar el primero.")}</p>
          </div>) : (<div className="grilla-mis-alojamientos">
            {alojamientos.map((alojamiento) => (<article className="tarjeta tarjeta-mi-alojamiento" key={alojamiento.idAlojamiento}>
                <div className="tarjeta-mi-alojamiento-cabecera">
                  <div>
                    <h3>{alojamiento.titulo}</h3>
                    <p className="texto-suave">
                      {alojamiento.ciudad} ·{' '}
                      {t(NOMBRES_TIPO[alojamiento.tipoAlojamiento] ??
                    alojamiento.tipoAlojamiento)}
                    </p>
                  </div>
                  <span className={`estado estado-${alojamiento.estado.toLowerCase()}`}>
                    {t(alojamiento.estado.replaceAll('_', ' ').toLowerCase())}
                  </span>
                </div>

                <ul className="datos-mi-alojamiento">
                  <li>
                    <strong>
                      ${Number(alojamiento.precioNoche).toLocaleString(localeActual())}
                    </strong>{t("noche")}</li>
                  <li>
                    <strong>{alojamiento.capacidad}</strong>{t("hu\u00E9spedes")}</li>
                  <li>
                    <strong>{alojamiento.habitaciones ?? 1}</strong>
                    {(alojamiento.habitaciones ?? 1) === 1 ? t("habitaci\u00F3n") : t("habitaciones")}
                  </li>
                  <li>
                    <strong>{alojamiento.banos ?? 1}</strong>
                    {(alojamiento.banos ?? 1) === 1 ? t("ba\u00F1o") : t("ba\u00F1os")}
                  </li>
                </ul>

                <div className="acciones-mi-alojamiento">
                  <button type="button" className="boton-secundario" onClick={() => editarAlojamiento(alojamiento)}>{t("Editar")}</button>

                  <select aria-label={t(t("Cambiar estado de {0}", alojamiento.titulo))} value={alojamiento.estado} onChange={(evento) => cambiarEstado(alojamiento.idAlojamiento, evento.target.value)}>
                    <option value="BORRADOR">{t("Borrador")}</option>
                    <option value="PENDIENTE_REVISION">{t("Pendiente de revisi\u00F3n")}</option>
                    <option value="ACTIVA">{t("Activa")}</option>
                    <option value="PAUSADA">{t("Pausada")}</option>
                    {alojamiento.estado === 'BLOQUEADA' && (<option value="BLOQUEADA" disabled>{t("Bloqueada por el administrador")}</option>)}
                  </select>
                </div>

                <details className="fotos-mi-alojamiento">
                  <summary>{t("Fotos del alojamiento")}</summary>
                  <ImagenesAlojamiento idAlojamiento={alojamiento.idAlojamiento}/>
                </details>
              </article>))}
          </div>)}
      </section>
    </section>);
}
export default Alojamientos;
