package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.DatosNuevaClave;
import com.inversioneslr.marketplace.dto.DatosRecuperacion;
import com.inversioneslr.marketplace.dto.InicioSesionRequest;
import com.inversioneslr.marketplace.dto.RegistroUsuarioRequest;
import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.service.RecuperacionService;
import com.inversioneslr.marketplace.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;
    private final RecuperacionService recuperacionService;

    public UsuarioController(
            UsuarioService usuarioService,
            RecuperacionService recuperacionService) {

        this.usuarioService = usuarioService;
        this.recuperacionService = recuperacionService;
    }

    @PostMapping("/registro")
    public ResponseEntity<UsuarioResponse> registrar(
            @Valid @RequestBody RegistroUsuarioRequest datos) {

        UsuarioResponse usuario = usuarioService.registrar(datos);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(usuario);
    }

    @PostMapping("/login")
    public ResponseEntity<UsuarioResponse> iniciarSesion(
            @Valid @RequestBody InicioSesionRequest datos) {

        UsuarioResponse usuario = usuarioService.iniciarSesion(datos);

        return ResponseEntity.ok(usuario);
    }

    @PostMapping("/recuperar")
    public ResponseEntity<Map<String, String>> solicitarRecuperacion(
            @Valid @RequestBody DatosRecuperacion datos) {

        recuperacionService.solicitar(datos);

        return ResponseEntity.ok(
                Map.of(
                        "mensaje",
                        "Si existe una cuenta activa con ese correo, "
                        + "recibirás un enlace para cambiar tu contraseña."
                )
        );
    }

    @PostMapping("/nueva-clave")
    public ResponseEntity<Map<String, String>> cambiarClave(
            @Valid @RequestBody DatosNuevaClave datos) {

        recuperacionService.cambiarClave(datos);

        return ResponseEntity.ok(
                Map.of(
                        "mensaje",
                        "Contraseña actualizada. Ya puedes iniciar sesión."
                )
        );
    }
}