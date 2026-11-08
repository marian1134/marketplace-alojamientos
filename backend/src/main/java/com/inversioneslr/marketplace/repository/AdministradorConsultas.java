package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.dto.AdminPagina;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class AdministradorConsultas {
    private static final int TAMANO = 20;
    private final JdbcTemplate jdbc;
    public AdministradorConsultas(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public Map<String, Object> resumen() {
        return jdbc.queryForMap("""
                SELECT (SELECT COUNT(*) FROM usuario) AS usuarios,
                  (SELECT COUNT(*) FROM usuario WHERE estado <> 'ACTIVA') AS usuariosNoActivos,
                  (SELECT COUNT(*) FROM publicacion) AS alojamientos,
                  (SELECT COUNT(*) FROM publicacion WHERE etapa = 'ACTIVA') AS alojamientosActivos,
                  (SELECT COUNT(*) FROM publicacion WHERE etapa = 'BLOQUEADA') AS alojamientosBloqueados,
                  (SELECT COUNT(*) FROM publicacion WHERE etapa = 'PENDIENTE_REVISION') AS pendientesRevision,
                  (SELECT COUNT(*) FROM reporte_resena WHERE atendido = FALSE) AS reportesPendientes,
                  (SELECT COUNT(*) FROM reserva) AS reservas,
                  (SELECT COALESCE(SUM(c.total), 0) FROM cotizacion c JOIN reserva r ON r.id = c.reserva_id
                     WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')) AS ingresosEstimados
                """);
    }

    // Cantidad de reservas en cada estado (dashboard)
    public List<Map<String, Object>> reservasPorEstado() {
        return jdbc.queryForList("SELECT estado, COUNT(*) AS cantidad FROM reserva GROUP BY estado ORDER BY cantidad DESC");
    }

    // Ciudades con más reservas confirmadas o completadas (dashboard)
    public List<Map<String, Object>> ciudadesConMasDemanda(int limite) {
        return jdbc.queryForList("""
                SELECT p.ciudad, COUNT(*) AS reservas, COALESCE(SUM(c.total), 0) AS ingresos
                FROM reserva r JOIN publicacion p ON p.id = r.publicacion_id
                LEFT JOIN cotizacion c ON c.reserva_id = r.id
                WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
                GROUP BY p.ciudad ORDER BY reservas DESC, ingresos DESC LIMIT ?
                """, limite);
    }

    public AdminPagina usuarios(String q, String estado, int pagina) {
        String where = " WHERE (LOWER(nombre) LIKE ? OR LOWER(email) LIKE ?) ";
        List<Object> args = new ArrayList<>(List.of(patron(q), patron(q)));
        if (!estado.isEmpty()) { where += " AND estado = ? "; args.add(estado); }
        return pagina("SELECT id, nombre, email, rol, estado, motivo_restriccion AS motivo, creado_en AS creadoEn FROM usuario",
                "SELECT COUNT(*) FROM usuario", where, " ORDER BY id DESC ", args, pagina);
    }

    public AdminPagina alojamientos(String q, String estado, int pagina) {
        String from = " FROM publicacion p JOIN usuario u ON u.id = p.anfitrion_id ";
        String where = " WHERE (LOWER(p.titulo) LIKE ? OR LOWER(p.ciudad) LIKE ? OR LOWER(u.email) LIKE ?) ";
        List<Object> args = new ArrayList<>(List.of(patron(q), patron(q), patron(q)));
        if (!estado.isEmpty()) { where += " AND p.etapa = ? "; args.add(estado); }
        return pagina("SELECT p.id, p.titulo, p.ciudad, p.etapa AS estado, p.motivo_etapa AS motivo, "
                        + "p.precio_noche AS precioNoche, u.nombre AS anfitrion, u.email AS emailAnfitrion" + from,
                "SELECT COUNT(*)" + from, where, " ORDER BY p.id DESC ", args, pagina);
    }

    public AdminPagina reportes(String q, String estado, int pagina) {
        String from = """
                 FROM reporte_resena rr JOIN resena r ON r.id = rr.resena_id
                 JOIN reserva re ON re.id = r.reserva_id
                 JOIN publicacion p ON p.id = re.publicacion_id
                 JOIN usuario autor ON autor.id = re.huesped_id
                 JOIN usuario reportante ON reportante.id = rr.reportado_por
                """;
        String where = " WHERE (LOWER(p.titulo) LIKE ? OR LOWER(rr.motivo) LIKE ? OR LOWER(autor.nombre) LIKE ?) ";
        List<Object> args = new ArrayList<>(List.of(patron(q), patron(q), patron(q)));
        if (!estado.isEmpty()) { where += " AND rr.atendido = ? "; args.add(estado.equals("ATENDIDOS")); }
        return pagina("SELECT rr.id, rr.resena_id AS idResena, rr.motivo, rr.fecha, rr.atendido, "
                        + "r.comentario, r.calificacion, r.visible, r.motivo_ocultamiento AS motivoOcultamiento, "
                        + "p.titulo AS alojamiento, autor.nombre AS autor, reportante.nombre AS reportante" + from,
                "SELECT COUNT(*)" + from, where, " ORDER BY rr.atendido ASC, rr.id DESC ", args, pagina);
    }

    public AdminPagina auditoria(String q, int pagina) {
        String from = " FROM evento_auditoria e LEFT JOIN usuario u ON u.id = e.usuario_id ";
        String where = " WHERE e.servicio = 'ADMINISTRACION' AND (LOWER(e.accion) LIKE ? OR LOWER(COALESCE(e.detalle,'')) LIKE ?) ";
        return pagina("SELECT e.id, e.fecha_hora AS fecha, u.nombre AS administrador, e.accion, "
                        + "e.entidad, e.entidad_id AS entidadId, e.detalle, e.resultado" + from,
                "SELECT COUNT(*)" + from, where, " ORDER BY e.id DESC ",
                new ArrayList<>(List.of(patron(q), patron(q))), pagina);
    }

    private AdminPagina pagina(String select, String count, String where, String order,
                                List<Object> args, int pagina) {
        Long total = jdbc.queryForObject(count + where, Long.class, args.toArray());
        args.add(TAMANO);
        args.add(pagina * TAMANO);
        return new AdminPagina(jdbc.queryForList(select + where + order + " LIMIT ? OFFSET ?", args.toArray()),
                total == null ? 0L : total, pagina, TAMANO);
    }

    private static String patron(String q) { return "%" + q.toLowerCase(Locale.ROOT) + "%"; }
}
