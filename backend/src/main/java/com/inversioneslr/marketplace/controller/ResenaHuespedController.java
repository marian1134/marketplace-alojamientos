package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.ResenaHuespedResponse;
import com.inversioneslr.marketplace.dto.ResenaRequest;
import com.inversioneslr.marketplace.service.ResenaHuespedService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
public class ResenaHuespedController {
    private final ResenaHuespedService servicio;

    public ResenaHuespedController(ResenaHuespedService servicio) {
        this.servicio = servicio;
    }

    @GetMapping("/api/v1/resenas-huesped/mis-calificaciones")
    public List<ResenaHuespedResponse> listar(Authentication autenticacion) {
        return servicio.listar(autenticacion.getName());
    }

    @PostMapping("/api/v1/reservas/{id}/resena-huesped")
    @ResponseStatus(HttpStatus.CREATED)
    public ResenaHuespedResponse crear(@PathVariable("id") Long id,
            @Valid @RequestBody ResenaRequest datos, Authentication autenticacion) {
        return servicio.crear(id, datos, autenticacion.getName());
    }
}
