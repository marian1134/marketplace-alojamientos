package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.model.Rol;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Reportes de gestión para el administrador, en Excel (XLSX) o PDF.
 * Cada exportación queda registrada (quién y cuándo) en exportacion_reporte
 * y en la auditoría.
 */
@Service
public class ReporteService {

    public enum Tipo { USUARIOS, PUBLICACIONES, RESERVAS, INGRESOS, DEMANDA }
    public enum Formato { XLSX, PDF }

    // Archivo generado. Como guarda un arreglo de bytes, compara y muestra su contenido (no la referencia)
    public record Archivo(String nombre, String tipoContenido, byte[] contenido) {

        @Override
        public boolean equals(Object otro) {
            return otro instanceof Archivo archivo
                    && nombre.equals(archivo.nombre)
                    && tipoContenido.equals(archivo.tipoContenido)
                    && Arrays.equals(contenido, archivo.contenido);
        }

        @Override
        public int hashCode() {
            return 31 * Objects.hash(nombre, tipoContenido) + Arrays.hashCode(contenido);
        }

        @Override
        public String toString() {
            return "Archivo[nombre=" + nombre + ", tipoContenido=" + tipoContenido + ", bytes=" + contenido.length + "]";
        }
    }

    private record Consulta(String titulo, List<String> columnas, List<String> claves, String sql) { }

    private static final ZoneId BOGOTA = ZoneId.of("America/Bogota");

    private final JdbcTemplate jdbc;
    private final UsuarioRepository usuarios;

    public ReporteService(JdbcTemplate jdbc, UsuarioRepository usuarios) {
        this.jdbc = jdbc;
        this.usuarios = usuarios;
    }

    @Transactional
    public Archivo exportar(Tipo tipo, Formato formato, LocalDate desde, LocalDate hasta, String correo) {
        Usuario admin = usuarios.findByCorreoIgnoreCase(correo)
                .filter(u -> u.getRol() == Rol.ADMINISTRADOR)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo un administrador puede exportar reportes."));
        if (desde != null && hasta != null && hasta.isBefore(desde)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La fecha final debe ser igual o posterior a la inicial.");
        }

        Consulta consulta = consulta(tipo);
        // Rango de fechas opcional: si no llega, se usa todo el historial
        LocalDateTime inicio = (desde == null ? LocalDate.of(2000, 1, 1) : desde).atStartOfDay();
        LocalDateTime fin = (hasta == null ? LocalDate.of(2100, 1, 1) : hasta).plusDays(1).atStartOfDay();
        List<Map<String, Object>> filas = jdbc.queryForList(consulta.sql(), inicio, fin);

        String generado = LocalDateTime.now(BOGOTA).format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
        String rango = (desde == null ? "inicio" : desde.toString()) + " a " + (hasta == null ? "hoy" : hasta.toString());
        String encabezado = "Generado el " + generado + " por " + admin.getNombre() + " (" + admin.getCorreo() + ") · Periodo: " + rango;

        byte[] contenido = formato == Formato.XLSX
                ? excel(consulta, filas, encabezado)
                : pdf(consulta, filas, encabezado);

        jdbc.update("INSERT INTO exportacion_reporte (tipo_reporte, formato, solicitado_por, fecha_desde, fecha_hasta) VALUES (?, ?, ?, ?, ?)",
                tipo.name(), formato.name(), admin.getIdUsuario(), desde, hasta);
        jdbc.update("INSERT INTO evento_auditoria (usuario_id, rol, servicio, accion, entidad, entidad_id, resultado, detalle) "
                        + "VALUES (?, 'ADMINISTRADOR', 'ADMINISTRACION', 'EXPORTAR_REPORTE', 'REPORTE', ?, 'EXITO', ?)",
                admin.getIdUsuario(), tipo.name(), "Reporte " + tipo + " en " + formato + " (" + filas.size() + " filas, " + rango + ")");

        String nombre = "stayhub_" + tipo.name().toLowerCase() + "_" + LocalDate.now(BOGOTA) + (formato == Formato.XLSX ? ".xlsx" : ".pdf");
        String tipoContenido = formato == Formato.XLSX
                ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                : "application/pdf";
        return new Archivo(nombre, tipoContenido, contenido);
    }

    private static Consulta consulta(Tipo tipo) {
        return switch (tipo) {
            case USUARIOS -> new Consulta("Usuarios registrados",
                    List.of("ID", "Nombre", "Correo", "Rol", "Estado", "Registro"),
                    List.of("id", "nombre", "email", "rol", "estado", "creado_en"),
                    "SELECT id, nombre, email, rol, estado, creado_en FROM usuario WHERE creado_en >= ? AND creado_en < ? ORDER BY id");
            case PUBLICACIONES -> new Consulta("Publicaciones",
                    List.of("ID", "Título", "Ciudad", "Tipo", "Capacidad", "Precio noche (COP)", "Estado", "Anfitrión"),
                    List.of("id", "titulo", "ciudad", "tipo", "capacidad", "precio_noche", "etapa", "anfitrion"),
                    "SELECT p.id, p.titulo, p.ciudad, p.tipo, p.capacidad, p.precio_noche, p.etapa, u.email AS anfitrion "
                            + "FROM publicacion p JOIN usuario u ON u.id = p.anfitrion_id "
                            + "WHERE p.creado_en >= ? AND p.creado_en < ? ORDER BY p.ciudad, p.id");
            case RESERVAS -> new Consulta("Reservas",
                    List.of("Código", "Alojamiento", "Ciudad", "Huésped", "Llegada", "Salida", "Huéspedes", "Estado", "Total (COP)"),
                    List.of("codigo", "alojamiento", "ciudad", "huesped", "fecha_llegada", "fecha_salida", "cantidad_huespedes", "estado", "total"),
                    "SELECT r.codigo, p.titulo AS alojamiento, p.ciudad, u.email AS huesped, r.fecha_llegada, r.fecha_salida, "
                            + "r.cantidad_huespedes, r.estado, c.total FROM reserva r JOIN publicacion p ON p.id = r.publicacion_id "
                            + "JOIN usuario u ON u.id = r.huesped_id LEFT JOIN cotizacion c ON c.reserva_id = r.id "
                            + "WHERE r.creada_en >= ? AND r.creada_en < ? ORDER BY r.creada_en DESC");
            case INGRESOS -> new Consulta("Ingresos estimados por mes",
                    List.of("Mes", "Reservas", "Ingresos estimados (COP)", "Tarifa de servicio (COP)"),
                    List.of("mes", "reservas", "ingresos", "servicio"),
                    "SELECT DATE_FORMAT(r.creada_en, '%Y-%m') AS mes, COUNT(*) AS reservas, COALESCE(SUM(c.total), 0) AS ingresos, "
                            + "COALESCE(SUM(c.tarifa_servicio), 0) AS servicio FROM reserva r LEFT JOIN cotizacion c ON c.reserva_id = r.id "
                            + "WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA') AND r.creada_en >= ? AND r.creada_en < ? "
                            + "GROUP BY mes ORDER BY mes");
            case DEMANDA -> new Consulta("Demanda por ciudad y tipo de alojamiento",
                    List.of("Ciudad", "Tipo", "Reservas", "Noches reservadas", "Ingresos (COP)"),
                    List.of("ciudad", "tipo", "reservas", "noches", "ingresos"),
                    "SELECT p.ciudad, p.tipo, COUNT(*) AS reservas, SUM(DATEDIFF(r.fecha_salida, r.fecha_llegada)) AS noches, "
                            + "COALESCE(SUM(c.total), 0) AS ingresos FROM reserva r JOIN publicacion p ON p.id = r.publicacion_id "
                            + "LEFT JOIN cotizacion c ON c.reserva_id = r.id WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA') "
                            + "AND r.creada_en >= ? AND r.creada_en < ? GROUP BY p.ciudad, p.tipo ORDER BY reservas DESC, ingresos DESC");
        };
    }

    private static String texto(Object valor) {
        if (valor == null) return "";
        if (valor instanceof BigDecimal numero) return numero.stripTrailingZeros().toPlainString();
        return String.valueOf(valor).replace('T', ' ');
    }

    private static byte[] excel(Consulta consulta, List<Map<String, Object>> filas, String encabezado) {
        try (XSSFWorkbook libro = new XSSFWorkbook(); ByteArrayOutputStream salida = new ByteArrayOutputStream()) {
            Sheet hoja = libro.createSheet(consulta.titulo().length() > 30 ? consulta.titulo().substring(0, 30) : consulta.titulo());
            XSSFFont negrita = libro.createFont();
            negrita.setBold(true);
            CellStyle estiloTitulo = libro.createCellStyle();
            estiloTitulo.setFont(negrita);

            hoja.createRow(0).createCell(0).setCellValue("StayHub · " + consulta.titulo());
            hoja.getRow(0).getCell(0).setCellStyle(estiloTitulo);
            hoja.createRow(1).createCell(0).setCellValue(encabezado);

            Row cabecera = hoja.createRow(3);
            for (int i = 0; i < consulta.columnas().size(); i++) {
                cabecera.createCell(i).setCellValue(consulta.columnas().get(i));
                cabecera.getCell(i).setCellStyle(estiloTitulo);
            }
            int n = 4;
            for (Map<String, Object> fila : filas) {
                Row row = hoja.createRow(n++);
                for (int i = 0; i < consulta.claves().size(); i++) {
                    Object valor = fila.get(consulta.claves().get(i));
                    if (valor instanceof Number numero) row.createCell(i).setCellValue(numero.doubleValue());
                    else row.createCell(i).setCellValue(texto(valor));
                }
            }
            for (int i = 0; i < consulta.columnas().size(); i++) hoja.autoSizeColumn(i);
            libro.write(salida);
            return salida.toByteArray();
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo generar el archivo de Excel.");
        }
    }

    private static byte[] pdf(Consulta consulta, List<Map<String, Object>> filas, String encabezado) {
        ByteArrayOutputStream salida = new ByteArrayOutputStream();
        Document documento = new Document(PageSize.A4.rotate(), 28, 28, 28, 28);
        PdfWriter.getInstance(documento, salida);
        documento.open();
        Color verde = new Color(11, 79, 69);
        documento.add(new Paragraph("StayHub · " + consulta.titulo(), FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16, verde)));
        documento.add(new Paragraph(encabezado, FontFactory.getFont(FontFactory.HELVETICA, 9, Color.DARK_GRAY)));
        documento.add(new Paragraph(" "));

        PdfPTable tabla = new PdfPTable(consulta.columnas().size());
        tabla.setWidthPercentage(100);
        tabla.setHeaderRows(1);
        Font fuenteCabecera = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, Color.WHITE);
        Font fuente = FontFactory.getFont(FontFactory.HELVETICA, 8);
        for (String columna : consulta.columnas()) {
            PdfPCell celda = new PdfPCell(new Phrase(columna, fuenteCabecera));
            celda.setBackgroundColor(verde);
            celda.setPadding(5);
            tabla.addCell(celda);
        }
        for (Map<String, Object> fila : filas) {
            for (String clave : consulta.claves()) {
                PdfPCell celda = new PdfPCell(new Phrase(texto(fila.get(clave)), fuente));
                celda.setPadding(4);
                if (fila.get(clave) instanceof Number) celda.setHorizontalAlignment(Element.ALIGN_RIGHT);
                tabla.addCell(celda);
            }
        }
        if (filas.isEmpty()) {
            PdfPCell celda = new PdfPCell(new Phrase("No hay datos en el periodo elegido.", fuente));
            celda.setColspan(consulta.columnas().size());
            tabla.addCell(celda);
        }
        documento.add(tabla);
        documento.add(new Paragraph("Total de filas: " + filas.size(), FontFactory.getFont(FontFactory.HELVETICA, 9)));
        documento.close();
        return salida.toByteArray();
    }
}
