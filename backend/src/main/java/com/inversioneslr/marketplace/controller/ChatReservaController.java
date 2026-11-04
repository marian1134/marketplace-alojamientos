package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.*;
import com.inversioneslr.marketplace.service.ChatReservaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/reservas/{idReserva}/mensajes")
public class ChatReservaController {
    private final ChatReservaService servicio;

    public ChatReservaController(ChatReservaService servicio) {
        this.servicio = servicio;
    }

    @GetMapping
    public ConversacionReservaResponse listar(
            @PathVariable Long idReserva,
            @RequestParam(required = false) Long antes,
            @RequestParam(required = false) Long despues,
            Authentication autenticacion) {
        return servicio.listar(idReserva, antes, despues, autenticacion.getName());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public MensajeReservaResponse enviar(
            @PathVariable Long idReserva, @Valid @RequestBody MensajeReservaRequest datos,
            Authentication autenticacion) {
        return servicio.enviar(idReserva, datos, autenticacion.getName());
    }
}
