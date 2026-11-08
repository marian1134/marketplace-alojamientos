package com.inversioneslr.marketplace.controller;
import com.inversioneslr.marketplace.dto.*;
import com.inversioneslr.marketplace.service.AdministradorService;
import com.inversioneslr.marketplace.service.ReporteService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin")
public class AdministradorController {
    private final AdministradorService servicio;
    private final ReporteService reportes;
    public AdministradorController(AdministradorService servicio, ReporteService reportes) {
        this.servicio = servicio;
        this.reportes = reportes;
    }

    @PostMapping("/administradores")
    @ResponseStatus(HttpStatus.CREATED)
    public UsuarioResponse crearAdministrador(@Valid @RequestBody CrearAdministradorRequest datos,
                                               Authentication auth) {
        return servicio.crearAdministrador(datos, auth.getName());
    }

    // Reporte de gestión en Excel o PDF: tipo USUARIOS, PUBLICACIONES, RESERVAS, INGRESOS o DEMANDA
    @GetMapping("/exportar")
    public ResponseEntity<byte[]> exportar(@RequestParam ReporteService.Tipo tipo,
            @RequestParam ReporteService.Formato formato,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
            Authentication auth) {
        ReporteService.Archivo archivo = reportes.exportar(tipo, formato, desde, hasta, auth.getName());
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename(archivo.nombre(), StandardCharsets.UTF_8).build().toString())
                .contentType(MediaType.parseMediaType(archivo.tipoContenido()))
                .body(archivo.contenido());
    }

    @GetMapping("/resumen")
    public Map<String, Object> resumen(Authentication auth) { return servicio.resumen(auth.getName()); }

    @GetMapping("/{seccion:usuarios|alojamientos|reportes|auditoria}")
    public AdminPagina listar(@PathVariable String seccion,
            @RequestParam(defaultValue = "") String q, @RequestParam(defaultValue = "") String estado,
            @RequestParam(defaultValue = "0") int pagina, Authentication auth) {
        return servicio.listar(seccion, q, estado, pagina, auth.getName());
    }

    @PatchMapping("/usuarios/{id}/estado")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void usuario(@PathVariable Long id, @Valid @RequestBody AdminEstadoRequest datos, Authentication auth) {
        servicio.cambiarUsuario(id, datos, auth.getName());
    }
    @PatchMapping("/alojamientos/{id}/estado")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void alojamiento(@PathVariable Long id, @Valid @RequestBody AdminEstadoRequest datos, Authentication auth) {
        servicio.cambiarAlojamiento(id, datos, auth.getName());
    }
    @PatchMapping("/reportes/{id}/resolver")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reporte(@PathVariable Long id, @Valid @RequestBody AdminReporteRequest datos, Authentication auth) {
        servicio.resolverReporte(id, datos, auth.getName());
    }
}
