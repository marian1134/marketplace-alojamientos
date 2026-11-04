package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.EstadoReporteResenaResponse;
import com.inversioneslr.marketplace.dto.ReporteResenaRequest;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@Service
public class ReporteResenaService {
    private final UsuarioRepository usuarios;
    private final JdbcTemplate jdbc;
    private final AvisoReporteService avisos;

    public ReporteResenaService(UsuarioRepository usuarios, JdbcTemplate jdbc, AvisoReporteService avisos) {
        this.usuarios = usuarios;
        this.jdbc = jdbc;
        this.avisos = avisos;
    }

    @Transactional(readOnly = true)
    public EstadoReporteResenaResponse consultar(Long id, String correo) {
        Usuario usuario = usuarioActivo(correo, false);
        Map<String, Object> resena = resenaAccesible(id, usuario, false);
        if (esAutor(resena, usuario)) {
            return new EstadoReporteResenaResponse(false, false, "Esta reseña es tuya.");
        }
        boolean reportada = yaReportada(id, usuario.getIdUsuario());
        return new EstadoReporteResenaResponse(reportada, !reportada,
                reportada ? "Ya reportaste esta reseña." : "");
    }

    @Transactional
    public EstadoReporteResenaResponse reportar(Long id, ReporteResenaRequest datos, String correo) {
        String motivo = datos.motivo() == null ? "" : datos.motivo().strip();
        if (motivo.length() < 10 || motivo.length() > 500) {
            throw error(HttpStatus.BAD_REQUEST, "Escribe un motivo de 10 a 500 caracteres.");
        }
        Usuario usuario = usuarioActivo(correo, true);
        // Serializa el alta con otros reportes y con la moderación de esta reseña.
        Map<String, Object> resena = resenaAccesible(id, usuario, true);
        if (esAutor(resena, usuario)) {
            throw error(HttpStatus.FORBIDDEN, "No puedes reportar tu propia reseña.");
        }
        if (yaReportada(id, usuario.getIdUsuario())) {
            throw error(HttpStatus.CONFLICT, "Ya reportaste esta reseña.");
        }
        try {
            jdbc.update("INSERT INTO reporte_resena (resena_id, reportado_por, motivo, fecha, atendido) "
                            + "VALUES (?, ?, ?, CURRENT_TIMESTAMP, FALSE)",
                    id, usuario.getIdUsuario(), motivo);
        } catch (DuplicateKeyException duplicado) {
            throw error(HttpStatus.CONFLICT, "Ya reportaste esta reseña.");
        }
        Long idReporte = jdbc.queryForObject(
                "SELECT id FROM reporte_resena WHERE resena_id = ? AND reportado_por = ?",
                Long.class, id, usuario.getIdUsuario());
        if (idReporte == null) throw new IllegalStateException("No se encontró el reporte recién guardado");
        avisos.nuevoReporte(idReporte);
        return new EstadoReporteResenaResponse(true, false,
                "Reporte enviado. El administrador lo revisará.");
    }

    private Usuario usuarioActivo(String correo, boolean bloquear) {
        Usuario usuario = (bloquear ? usuarios.bloquearPorCorreo(correo)
                : usuarios.findByCorreoIgnoreCase(correo))
                .orElseThrow(() -> error(HttpStatus.UNAUTHORIZED, "Inicia sesión de nuevo."));
        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw error(HttpStatus.UNAUTHORIZED, "La cuenta no se encuentra activa.");
        }
        return usuario;
    }

    private Map<String, Object> resenaAccesible(Long id, Usuario usuario, boolean bloquear) {
        if (id == null || id <= 0) {
            throw error(HttpStatus.BAD_REQUEST, "La reseña no es válida.");
        }
        // Primero bloquea solo la reseña; coincide con el orden de moderación.
        List<Map<String, Object>> resenas = jdbc.queryForList(
                "SELECT id, visible, reserva_id FROM resena WHERE id = ?" + (bloquear ? " FOR UPDATE" : ""), id);
        if (resenas.isEmpty() || !booleano(resenas.get(0).get("visible"))) {
            throw error(HttpStatus.NOT_FOUND, "La reseña ya no está disponible.");
        }
        Object idReserva = resenas.get(0).get("reserva_id");
        List<Map<String, Object>> referencias = jdbc.queryForList(
                "SELECT re.huesped_id AS autorId, p.anfitrion_id AS anfitrionId, p.etapa "
                        + "FROM reserva re JOIN publicacion p ON p.id = re.publicacion_id WHERE re.id = ?", idReserva);
        if (referencias.isEmpty()) {
            throw error(HttpStatus.NOT_FOUND, "La reseña ya no está disponible.");
        }
        Map<String, Object> referencia = referencias.get(0);
        if (!"ACTIVA".equals(referencia.get("etapa"))
                && ((Number) referencia.get("anfitrionId")).longValue() != usuario.getIdUsuario().longValue()) {
            throw error(HttpStatus.NOT_FOUND, "El alojamiento no está disponible.");
        }
        return referencia;
    }

    private boolean yaReportada(Long id, Long idUsuario) {
        Long cantidad = jdbc.queryForObject(
                "SELECT COUNT(*) FROM reporte_resena WHERE resena_id = ? AND reportado_por = ?",
                Long.class, id, idUsuario);
        return cantidad != null && cantidad > 0;
    }

    private boolean esAutor(Map<String, Object> resena, Usuario usuario) {
        return ((Number) resena.get("autorId")).longValue() == usuario.getIdUsuario().longValue();
    }

    private static boolean booleano(Object valor) {
        return Boolean.TRUE.equals(valor) || (valor instanceof Number numero && numero.intValue() != 0);
    }

    private static ResponseStatusException error(HttpStatus estado, String mensaje) {
        return new ResponseStatusException(estado, mensaje);
    }
}
