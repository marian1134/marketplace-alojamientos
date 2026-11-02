package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.CalendarioResponse;
import com.inversioneslr.marketplace.dto.PeriodoRequest;
import com.inversioneslr.marketplace.service.CalendarioService;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
public class CalendarioController {

    private final CalendarioService calendarioService;

    public CalendarioController(CalendarioService calendarioService) {
        this.calendarioService = calendarioService;
    }

    @GetMapping("/api/v1/alojamientos/{id}/calendario")
    public CalendarioResponse obtener(@PathVariable Long id, Authentication autenticacion) {
        return calendarioService.obtener(id, autenticacion.getName());
    }

    @PostMapping("/api/v1/alojamientos/{id}/periodos")
    public CalendarioResponse agregarPeriodo(
            @PathVariable Long id,
            @Valid @RequestBody PeriodoRequest datos,
            Authentication autenticacion) {

        return calendarioService.agregarPeriodo(id, datos, autenticacion.getName());
    }

    @DeleteMapping("/api/v1/periodos/{idPeriodo}")
    public CalendarioResponse eliminarPeriodo(
            @PathVariable Long idPeriodo,
            Authentication autenticacion) {

        return calendarioService.eliminarPeriodo(idPeriodo, autenticacion.getName());
    }
}
