package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.EstadoReporteResenaResponse;
import com.inversioneslr.marketplace.dto.ReporteResenaRequest;
import com.inversioneslr.marketplace.service.ReporteResenaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/resenas")
public class ReporteResenaController {
    private final ReporteResenaService servicio;

    public ReporteResenaController(ReporteResenaService servicio) {
        this.servicio = servicio;
    }

    @GetMapping("/{id}/reporte")
    public EstadoReporteResenaResponse consultar(
            @PathVariable Long id, Authentication autenticacion) {
        return servicio.consultar(id, correo(autenticacion));
    }

    @PostMapping("/{id}/reporte")
    @ResponseStatus(HttpStatus.CREATED)
    public EstadoReporteResenaResponse reportar(
            @PathVariable Long id,
            @Valid @RequestBody ReporteResenaRequest datos,
            Authentication autenticacion) {
        return servicio.reportar(id, datos, correo(autenticacion));
    }

    private String correo(Authentication autenticacion) {
        if (autenticacion == null || !autenticacion.isAuthenticated()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Inicia sesión de nuevo.");
        }
        return autenticacion.getName();
    }
}
