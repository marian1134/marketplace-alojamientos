package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.AdminPagina;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.Rol;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@Service
public class AvisoReporteService {
    private final JdbcTemplate jdbc;
    private final UsuarioRepository usuarios;

    public AvisoReporteService(JdbcTemplate jdbc, UsuarioRepository usuarios) {
        this.jdbc = jdbc;
        this.usuarios = usuarios;
    }

    // Se guarda junto al reporte. Si falla el aviso, se revierte toda la operación.
    @Transactional(propagation = Propagation.MANDATORY)
    public void nuevoReporte(Long idReporte) {
        jdbc.update("INSERT INTO notificacion "
                        + "(usuario_id, tipo, titulo, mensaje, entidad, entidad_id, leida, creada_en) "
                        + "SELECT id, 'REPORTE_RESENA_NUEVO', ?, ?, 'REPORTE_RESENA', ?, FALSE, CURRENT_TIMESTAMP "
                        + "FROM usuario WHERE rol = 'ADMINISTRADOR' AND estado = 'ACTIVA'",
                "Nuevo reporte de reseña #" + idReporte,
                "Hay un reporte pendiente de revisión. Ábrelo para revisar la reseña y el motivo.", idReporte);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void reporteAtendido(Long idReporte, Long idReportante, String decision) {
        String resultado = "OCULTAR".equals(decision)
                ? "La reseña fue ocultada tras la revisión."
                : "El administrador revisó y descartó el reporte.";
        jdbc.update("INSERT INTO notificacion "
                        + "(usuario_id, tipo, titulo, mensaje, entidad, entidad_id, leida, creada_en) "
                        + "VALUES (?, 'REPORTE_RESENA_ATENDIDO', ?, ?, 'REPORTE_RESENA', ?, FALSE, CURRENT_TIMESTAMP)",
                idReportante, "Tu reporte #" + idReporte + " fue atendido",
                "Revisamos tu reporte de reseña. " + resultado, idReporte);
    }

    @Transactional(readOnly = true)
    public AdminPagina obtenerParaAdministrador(Long id, String correo) {
        Usuario usuario = usuarios.findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Inicia sesión de nuevo."));
        if (usuario.getRol() != Rol.ADMINISTRADOR || usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo un administrador activo puede abrir este reporte.");
        }
        if (id == null || id <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El reporte no es válido.");
        }
        List<Map<String, Object>> filas = jdbc.queryForList("""
                SELECT rr.id, rr.resena_id AS idResena, rr.motivo, rr.fecha, rr.atendido,
                       r.comentario, r.calificacion, r.visible, r.motivo_ocultamiento AS motivoOcultamiento,
                       p.titulo AS alojamiento, autor.nombre AS autor, reportante.nombre AS reportante
                FROM reporte_resena rr JOIN resena r ON r.id = rr.resena_id
                JOIN reserva re ON re.id = r.reserva_id
                JOIN publicacion p ON p.id = re.publicacion_id
                JOIN usuario autor ON autor.id = re.huesped_id
                JOIN usuario reportante ON reportante.id = rr.reportado_por
                WHERE rr.id = ?
                """, id);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El reporte ya no está disponible.");
        }
        return new AdminPagina(filas, 1L, 0, 20);
    }
}
