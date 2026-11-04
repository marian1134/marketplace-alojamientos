package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.AdminPagina;
import com.inversioneslr.marketplace.service.AvisoReporteService;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/admin/avisos/reportes")
public class AvisoReporteController {
    private final AvisoReporteService servicio;
    public AvisoReporteController(AvisoReporteService servicio) { this.servicio = servicio; }

    @GetMapping("/{id}")
    public AdminPagina abrir(@PathVariable Long id, Authentication autenticacion) {
        if (autenticacion == null || !autenticacion.isAuthenticated()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Inicia sesión de nuevo.");
        }
        return servicio.obtenerParaAdministrador(id, autenticacion.getName());
    }
}
