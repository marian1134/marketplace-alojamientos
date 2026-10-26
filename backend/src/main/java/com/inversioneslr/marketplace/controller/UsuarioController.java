package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.RegistroUsuarioRequest;
import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;

    public UsuarioController(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    @PostMapping("/registro")
    public ResponseEntity<UsuarioResponse> registrar(
            @Valid @RequestBody RegistroUsuarioRequest datos) {

        UsuarioResponse usuario = usuarioService.registrar(datos);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(usuario);
    }
}