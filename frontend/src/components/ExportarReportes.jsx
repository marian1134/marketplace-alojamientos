import { t, useIdioma } from '../idiomas'
import { useState } from 'react';
const TIPOS = [
    ['RESERVAS', 'Reservas'], ['INGRESOS', 'Ingresos estimados por mes'], ['DEMANDA', 'Demanda por ciudad y tipo'],
    ['PUBLICACIONES', 'Publicaciones'], ['USUARIOS', 'Usuarios'],
];
// Descarga reportes de gestión en Excel o PDF (queda registrado quién y cuándo)
export default function ExportarReportes() {
    useIdioma();
    const [tipo, setTipo] = useState('RESERVAS');
    const [formato, setFormato] = useState('XLSX');
    const [desde, setDesde] = useState('');
    const [hasta, setHasta] = useState('');
    const [estado, setEstado] = useState('');
    const [descargando, setDescargando] = useState(false);
    async function exportar(evento) {
        evento.preventDefault();
        if (desde && hasta && hasta < desde) {
            setEstado(t("La fecha final debe ser igual o posterior a la inicial."));
            return;
        }
        setDescargando(true);
        setEstado('');
        try {
            const parametros = new URLSearchParams({ tipo, formato });
            if (desde) parametros.set('desde', desde);
            if (hasta) parametros.set('hasta', hasta);
            const respuesta = await fetch(`/api/v1/admin/exportar?${parametros}`, { credentials: 'same-origin' });
            if (!respuesta.ok) {
                throw new Error(respuesta.status === 403 ? t("No tienes permiso para exportar reportes.") : t("No se pudo generar el reporte."));
            }
            const nombre = /filename\*?=(?:UTF-8'')?"?([^";]+)/i.exec(respuesta.headers.get('Content-Disposition') || '')?.[1]
                || `reporte.${formato.toLowerCase()}`;
            const enlace = document.createElement('a');
            enlace.href = URL.createObjectURL(await respuesta.blob());
            enlace.download = decodeURIComponent(nombre);
            document.body.appendChild(enlace);
            enlace.click();
            enlace.remove();
            URL.revokeObjectURL(enlace.href);
            setEstado(t("Reporte descargado. La exportación quedó registrada en la auditoría."));
        }
        catch (fallo) {
            setEstado(fallo.message);
        }
        finally {
            setDescargando(false);
        }
    }
    return (<article className="tarjeta admin-exportar">
      <h2>{t("Exportar reportes")}</h2>
      <p className="texto-suave">{t("Descarga la información de gestión en Excel o PDF. Si no eliges fechas, se incluye todo el historial.")}</p>
      <form onSubmit={exportar}>
        <label>{t("Reporte")}
          <select value={tipo} onChange={(e) => setTipo(e.target.value)}>
            {TIPOS.map(([valor, nombre]) => <option key={valor} value={valor}>{t(nombre)}</option>)}
          </select>
        </label>
        <label>{t("Formato")}
          <select value={formato} onChange={(e) => setFormato(e.target.value)}>
            <option value="XLSX">Excel (.xlsx)</option>
            <option value="PDF">PDF</option>
          </select>
        </label>
        <label>{t("Desde")}
          <input type="date" value={desde} onChange={(e) => setDesde(e.target.value)}/>
        </label>
        <label>{t("Hasta")}
          <input type="date" value={hasta} onChange={(e) => setHasta(e.target.value)}/>
        </label>
        <button type="submit" className="boton-principal" disabled={descargando}>
          {descargando ? t("Generando...") : t("Exportar")}
        </button>
      </form>
      {estado && <p role="status">{estado}</p>}
    </article>);
}
