import { t, useIdioma } from '../idiomas'
import { useEffect, useState } from 'react';
import { enviarArchivo, enviarDatos } from '../api';
const MAXIMO_IMAGENES = 10;
const MAXIMO_BYTES = 5 * 1024 * 1024;
const TIPOS_PERMITIDOS = [
    'image/jpeg',
    'image/png',
    'image/webp',
];
function ImagenesAlojamiento({ idAlojamiento }) {
    useIdioma();
    const [imagenes, setImagenes] = useState([]);
    const [cargando, setCargando] = useState(true);
    const [subiendo, setSubiendo] = useState(false);
    const [mensaje, setMensaje] = useState('');
    async function cargarImagenes() {
        try {
            const respuesta = await fetch(`/api/v1/alojamientos/${idAlojamiento}/imagenes`, {
                credentials: 'same-origin',
                cache: 'no-store',
            });
            if (!respuesta.ok) {
                throw new Error(t("No se pudieron consultar las im\u00E1genes"));
            }
            const datos = await respuesta.json();
            setImagenes(datos);
        }
        catch {
            setMensaje(t("No se pudieron cargar las im\u00E1genes."));
        }
        finally {
            setCargando(false);
        }
    }
    useEffect(() => {
        cargarImagenes();
    }, [idAlojamiento]);
    async function seleccionarImagenes(evento) {
        const entrada = evento.currentTarget;
        const archivos = Array.from(entrada.files ?? []);
        if (archivos.length === 0) {
            return;
        }
        const espaciosDisponibles = MAXIMO_IMAGENES - imagenes.length;
        if (archivos.length > espaciosDisponibles) {
            setMensaje(t("Solo puedes agregar {0} imagen(es) m\u00E1s.", espaciosDisponibles));
            entrada.value = '';
            return;
        }
        const archivoInvalido = archivos.find((archivo) => !TIPOS_PERMITIDOS.includes(archivo.type) ||
            archivo.size > MAXIMO_BYTES);
        if (archivoInvalido) {
            setMensaje(t("Las im\u00E1genes deben ser JPG, PNG o WebP y pesar m\u00E1ximo 5 MB."));
            entrada.value = '';
            return;
        }
        setSubiendo(true);
        setMensaje('');
        try {
            for (const archivo of archivos) {
                const respuesta = await enviarArchivo(`/api/v1/alojamientos/${idAlojamiento}/imagenes`, archivo);
                if (!respuesta.ok) {
                    throw new Error(t("No se pudo subir una imagen"));
                }
            }
            setMensaje(t("Las im\u00E1genes se guardaron correctamente."));
            await cargarImagenes();
        }
        catch {
            setMensaje(t("No se pudieron guardar todas las im\u00E1genes. Intenta nuevamente."));
        }
        finally {
            setSubiendo(false);
            entrada.value = '';
        }
    }
    async function seleccionarPortada(idImagen) {
        setMensaje('');
        try {
            const respuesta = await enviarDatos(`/api/v1/alojamientos/imagenes/${idImagen}/principal`, {}, 'PATCH');
            if (!respuesta.ok) {
                throw new Error(t("No se pudo cambiar la portada"));
            }
            setMensaje(t("La portada se actualiz\u00F3 correctamente."));
            await cargarImagenes();
        }
        catch {
            setMensaje(t("No se pudo cambiar la imagen de portada."));
        }
    }
    async function eliminarImagen(idImagen) {
        const confirmado = window.confirm(t("\u00BFDeseas eliminar esta imagen?"));
        if (!confirmado) {
            return;
        }
        setMensaje('');
        try {
            const respuesta = await enviarDatos(`/api/v1/alojamientos/imagenes/${idImagen}`, {}, 'DELETE');
            if (!respuesta.ok) {
                throw new Error(t("No se pudo eliminar la imagen"));
            }
            setMensaje(t("La imagen se elimin\u00F3 correctamente."));
            await cargarImagenes();
        }
        catch {
            setMensaje(t("No se pudo eliminar la imagen."));
        }
    }
    return (<section className="imagenes-alojamiento">
      <div className="imagenes-encabezado">
        <div>
          <h4>{t("Fotograf\u00EDas")}</h4>
          <p>
            {imagenes.length}{t(" de ")}{MAXIMO_IMAGENES}{t("im\u00E1genes")}</p>
        </div>

        <label className="boton-agregar-imagen">
          {subiendo ? 'Subiendo...' : t("Agregar im\u00E1genes")}

          <input type="file" accept="image/jpeg,image/png,image/webp" multiple onChange={seleccionarImagenes} disabled={subiendo ||
            imagenes.length >= MAXIMO_IMAGENES}/>
        </label>
      </div>

      {cargando ? (<p>{t("Cargando im\u00E1genes...")}</p>) : imagenes.length === 0 ? (<p className="sin-imagenes">{t("Este alojamiento todav\u00EDa no tiene fotograf\u00EDas.")}</p>) : (<div className="galeria-imagenes">
          {imagenes.map((imagen) => (<article className="imagen-tarjeta" key={imagen.idImagen}>
              <div className="imagen-contenedor">
                <img src={imagen.urlImagen} alt={t(t("Fotograf\u00EDa del alojamiento {0}", idAlojamiento))}/>

                {imagen.principal && (<span className="etiqueta-portada">{t("Portada")}</span>)}
              </div>

              <div className="imagen-acciones">
                {!imagen.principal && (<button type="button" onClick={() => seleccionarPortada(imagen.idImagen)}>{t("Usar como portada")}</button>)}

                <button type="button" className="boton-eliminar-imagen" onClick={() => eliminarImagen(imagen.idImagen)}>{t("Eliminar")}</button>
                            </div>
            </article>))}
        </div>)}

      {mensaje && (<p className="mensaje-imagenes" role="status">
          {t(mensaje)}
        </p>)}
    </section>);
}
export default ImagenesAlojamiento;
