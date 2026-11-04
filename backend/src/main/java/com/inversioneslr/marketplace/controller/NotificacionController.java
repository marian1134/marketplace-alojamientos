package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.service.NotificacionService;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/notificaciones")
public class NotificacionController {

    private final NotificacionService notificacionService;

    public NotificacionController(
            NotificacionService notificacionService) {

        this.notificacionService = notificacionService;
    }

    @GetMapping
    public NotificacionService.Bandeja listar(
            Authentication autenticacion) {

        return notificacionService.listar(
                autenticacion.getName()
        );
    }

    @PatchMapping("/{id}/leida")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void marcarLeida(
            @PathVariable("id") Long id,
            Authentication autenticacion) {

        notificacionService.marcarLeida(
                id,
                autenticacion.getName()
        );
    }

    @PatchMapping("/leidas")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void marcarTodasLeidas(
            Authentication autenticacion) {

        notificacionService.marcarTodasLeidas(
                autenticacion.getName()
        );
    }
}