package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.*;
import com.inversioneslr.marketplace.model.*;
import com.inversioneslr.marketplace.repository.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import java.nio.charset.StandardCharsets;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.*;

@Service
@Transactional
public class AdministradorService {
    private final UsuarioRepository usuarios;
    private final AdministradorConsultas consultas;
    private final JdbcTemplate jdbc;
    private final AvisoReporteService avisos;
    public AdministradorService(UsuarioRepository usuarios, AdministradorConsultas consultas, JdbcTemplate jdbc, AvisoReporteService avisos) {
        this.usuarios = usuarios; this.consultas = consultas; this.jdbc = jdbc; this.avisos = avisos;
    }

    public UsuarioResponse crearAdministrador(CrearAdministradorRequest datos, String correo) {
        Usuario actor = administrador(correo);
        String nombre = datos.nombre() == null ? "" : datos.nombre().strip();
        String email = datos.correo() == null ? "" : datos.correo().strip().toLowerCase(Locale.ROOT);
        String clave = datos.contrasena();
        if (nombre.length() < 2 || nombre.length() > 100 || email.isBlank() || email.length() > 150) {
            throw error(HttpStatus.BAD_REQUEST, "Revisa el nombre y el correo del administrador.");
        }
        if (clave == null || clave.length() < 8 || clave.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw error(HttpStatus.BAD_REQUEST, "La contraseña debe tener al menos 8 caracteres y no superar 72 bytes.");
        }
        if (usuarios.existsByCorreoIgnoreCase(email)) {
            throw error(HttpStatus.CONFLICT, "Ya existe una cuenta con ese correo. Usa un correo distinto.");
        }
        Usuario nuevo = new Usuario();
        nuevo.setNombre(nombre);
        nuevo.setCorreo(email);
        nuevo.setContrasenaHash(new BCryptPasswordEncoder().encode(clave));
        // El rol se fija en el servidor: el formulario no puede elegirlo.
        nuevo.setRol(Rol.ADMINISTRADOR);
        nuevo.setEstado(EstadoUsuario.ACTIVA);
        Usuario guardado;
        try {
            guardado = usuarios.saveAndFlush(nuevo);
        } catch (DataIntegrityViolationException ex) {
            throw error(HttpStatus.CONFLICT, "No se pudo crear la cuenta. Comprueba que el correo no esté registrado.");
        }
        auditar(actor, "CREAR_ADMINISTRADOR", "USUARIO", guardado.getIdUsuario(),
                "Cuenta administrativa creada: " + guardado.getCorreo());
        return UsuarioResponse.desde(guardado);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> resumen(String correo) {
        administrador(correo);
        Map<String, Object> resumen = new LinkedHashMap<>(consultas.resumen());
        resumen.put("reservasPorEstado", consultas.reservasPorEstado());
        resumen.put("ciudadesConMasDemanda", consultas.ciudadesConMasDemanda(5));
        return resumen;
    }

    @Transactional(readOnly = true)
    public AdminPagina listar(String seccion, String q, String estado, int pagina, String correo) {
        administrador(correo);
        if (pagina < 0 || pagina > 100000 || q == null || q.length() > 100) {
            throw error(HttpStatus.BAD_REQUEST, "La página o el texto de búsqueda no es válido.");
        }
        String texto = q.strip();
        return switch (seccion) {
            case "usuarios" -> {
                validarFiltro(estado, Set.of("ACTIVA", "INACTIVA", "RESTRINGIDA"));
                yield consultas.usuarios(texto, estado, pagina);
            }
            case "alojamientos" -> {
                validarFiltro(estado, Set.of("BORRADOR", "PENDIENTE_REVISION", "ACTIVA", "PAUSADA", "BLOQUEADA"));
                yield consultas.alojamientos(texto, estado, pagina);
            }
            case "reportes" -> {
                validarFiltro(estado, Set.of("PENDIENTES", "ATENDIDOS"));
                yield consultas.reportes(texto, estado, pagina);
            }
            case "auditoria" -> consultas.auditoria(texto, pagina);
            default -> throw error(HttpStatus.NOT_FOUND, "La sección no existe.");
        };
    }

    public void cambiarUsuario(Long id, AdminEstadoRequest datos, String correo) {
        Usuario admin = administrador(correo);
        String motivo = motivo(datos.motivo());
        validarFiltroObligatorio(datos.estado(), Set.of("ACTIVA", "INACTIVA", "RESTRINGIDA"));
        Map<String, Object> actual = fila("SELECT id, rol, estado FROM usuario WHERE id = ? FOR UPDATE", id);
        if (id.equals(admin.getIdUsuario()) || "ADMINISTRADOR".equals(actual.get("rol"))) {
            throw error(HttpStatus.CONFLICT, "No puedes cambiar tu cuenta ni la de otro administrador desde este panel.");
        }
        verificarEstado(actual.get("estado"), datos.estadoActual());
        if (datos.estado().equals(actual.get("estado"))) throw error(HttpStatus.CONFLICT, "La cuenta ya tiene ese estado.");
        jdbc.update("UPDATE usuario SET estado = ?, motivo_restriccion = ? WHERE id = ?",
                datos.estado(), datos.estado().equals("ACTIVA") ? null : motivo, id);
        int pausados = 0;
        if (!datos.estado().equals("ACTIVA")) {
            pausados = jdbc.update("UPDATE publicacion SET etapa = 'PAUSADA', motivo_etapa = LEFT(?, 500) "
                            + "WHERE anfitrion_id = ? AND etapa IN ('ACTIVA','PENDIENTE_REVISION')",
                    "Cuenta del anfitrión no activa: " + motivo, id);
        }
        auditar(admin, "CAMBIAR_ESTADO_USUARIO", "USUARIO", id,
                actual.get("estado") + " -> " + datos.estado() + ". Alojamientos pausados: " + pausados + ". " + motivo);
    }

    public void cambiarAlojamiento(Long id, AdminEstadoRequest datos, String correo) {
        Usuario admin = administrador(correo);
        String motivo = motivo(datos.motivo());
        validarFiltroObligatorio(datos.estado(), Set.of("BLOQUEADA", "PAUSADA", "ACTIVA"));
        // Mismo orden de bloqueos que el servicio del anfitrión: usuario y publicación.
        Map<String, Object> referencia = fila("SELECT anfitrion_id FROM publicacion WHERE id = ?", id);
        Long anfitrion = ((Number) referencia.get("anfitrion_id")).longValue();
        Map<String, Object> propietario = fila("SELECT id, estado FROM usuario WHERE id = ? FOR UPDATE", anfitrion);
        Map<String, Object> actual = fila("SELECT id, etapa AS estado FROM publicacion WHERE id = ? FOR UPDATE", id);
        verificarEstado(actual.get("estado"), datos.estadoActual());
        String anterior = actual.get("estado").toString();
        boolean permitida = switch (datos.estado()) {
            case "BLOQUEADA" -> !anterior.equals("BLOQUEADA");
            case "PAUSADA" -> anterior.equals("BLOQUEADA");
            case "ACTIVA" -> anterior.equals("PENDIENTE_REVISION");
            default -> false;
        };
        if (!permitida) throw error(HttpStatus.CONFLICT, "La transición de estado no está permitida.");
        if (datos.estado().equals("ACTIVA")) {
            if (!"ACTIVA".equals(propietario.get("estado"))) {
                throw error(HttpStatus.CONFLICT, "La cuenta del anfitrión no está activa.");
            }
            Long imagenes = jdbc.queryForObject("SELECT COUNT(*) FROM imagen WHERE publicacion_id = ?", Long.class, id);
            if (imagenes == null || imagenes == 0) throw error(HttpStatus.CONFLICT, "El alojamiento necesita al menos una imagen para publicarse.");
        }
        jdbc.update("UPDATE publicacion SET etapa = ?, motivo_etapa = ? WHERE id = ?", datos.estado(), motivo, id);
        auditar(admin, "MODERAR_ALOJAMIENTO", "PUBLICACION", id, anterior + " -> " + datos.estado() + ". " + motivo);
    }

    public void resolverReporte(Long id, AdminReporteRequest datos, String correo) {
        Usuario admin = administrador(correo);
        String motivo = motivo(datos.motivo());
        if (datos.decision() == null || !Set.of("OCULTAR", "DESCARTAR").contains(datos.decision()) || datos.visibleActual() == null) {
            throw error(HttpStatus.BAD_REQUEST, "La decisión del reporte no es válida.");
        }
        Map<String, Object> referencia = fila("SELECT resena_id FROM reporte_resena WHERE id = ?", id);
        Long idResena = ((Number) referencia.get("resena_id")).longValue();
        Map<String, Object> resena = fila("SELECT id, visible FROM resena WHERE id = ? FOR UPDATE", idResena);
        Map<String, Object> reporte = fila("SELECT id, atendido, reportado_por FROM reporte_resena WHERE id = ? FOR UPDATE", id);
        if (booleano(reporte.get("atendido"))) throw error(HttpStatus.CONFLICT, "Este reporte ya fue atendido. Actualiza la lista.");
        if (booleano(resena.get("visible")) != datos.visibleActual()) {
            throw error(HttpStatus.CONFLICT, "La visibilidad de la reseña cambió. Actualiza la lista.");
        }
        if (datos.decision().equals("OCULTAR")) {
            jdbc.update("UPDATE resena SET visible = FALSE, motivo_ocultamiento = ?, ocultada_por = ? WHERE id = ?",
                    motivo, admin.getIdUsuario(), idResena);
        }
        jdbc.update("UPDATE reporte_resena SET atendido = TRUE WHERE id = ?", id);
        avisos.reporteAtendido(id, ((Number) reporte.get("reportado_por")).longValue(), datos.decision());
        auditar(admin, "RESOLVER_REPORTE", "REPORTE_RESENA", id,
                datos.decision() + ". Reseña " + idResena + ". " + motivo);
    }

    private Usuario administrador(String correo) {
        Usuario usuario = usuarios.findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> error(HttpStatus.UNAUTHORIZED, "Inicia sesión de nuevo."));
        if (usuario.getRol() != Rol.ADMINISTRADOR || usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw error(HttpStatus.FORBIDDEN, "Solo un administrador activo puede usar este panel.");
        }
        return usuario;
    }

    private Map<String, Object> fila(String sql, Long id) {
        List<Map<String, Object>> filas = jdbc.queryForList(sql, id);
        if (filas.isEmpty()) throw error(HttpStatus.NOT_FOUND, "No se encontró el registro.");
        return filas.get(0);
    }

    private void auditar(Usuario admin, String accion, String entidad, Long id, String detalle) {
        jdbc.update("INSERT INTO evento_auditoria (usuario_id, rol, servicio, accion, entidad, entidad_id, resultado, detalle) "
                        + "VALUES (?, 'ADMINISTRADOR', 'ADMINISTRACION', ?, ?, ?, 'EXITO', ?)",
                admin.getIdUsuario(), accion, entidad, id.toString(), detalle);
    }

    private static boolean booleano(Object valor) {
        return Boolean.TRUE.equals(valor) || (valor instanceof Number numero && numero.intValue() != 0);
    }
    private static String motivo(String valor) {
        String limpio = valor == null ? "" : valor.strip();
        if (limpio.length() < 10 || limpio.length() > 500) {
            throw error(HttpStatus.BAD_REQUEST, "Escribe un motivo de 10 a 500 caracteres.");
        }
        return limpio;
    }
    private static void verificarEstado(Object actual, String esperado) {
        if (!Objects.equals(actual, esperado)) {
            throw error(HttpStatus.CONFLICT, "El estado cambió desde que abriste la lista. Actualízala antes de continuar.");
        }
    }
    private static void validarFiltro(String estado, Set<String> permitidos) {
        if (estado == null || (!estado.isEmpty() && !permitidos.contains(estado))) {
            throw error(HttpStatus.BAD_REQUEST, "El filtro de estado no es válido.");
        }
    }
    private static void validarFiltroObligatorio(String estado, Set<String> permitidos) {
        if (estado == null || !permitidos.contains(estado)) throw error(HttpStatus.BAD_REQUEST, "El estado no es válido.");
    }
    private static ResponseStatusException error(HttpStatus estado, String mensaje) {
        return new ResponseStatusException(estado, mensaje);
    }
}
