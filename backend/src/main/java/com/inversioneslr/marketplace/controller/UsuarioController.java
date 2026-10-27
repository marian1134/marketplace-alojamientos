package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.DatosNuevaClave;
import com.inversioneslr.marketplace.dto.DatosRecuperacion;
import com.inversioneslr.marketplace.dto.InicioSesionRequest;
import com.inversioneslr.marketplace.dto.RegistroUsuarioRequest;
import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.service.RecuperacionService;
import com.inversioneslr.marketplace.service.SesionService;
import com.inversioneslr.marketplace.service.UsuarioService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;
    private final RecuperacionService recuperacionService;
    private final SesionService sesionService;

    public UsuarioController(
            UsuarioService usuarioService,
            RecuperacionService recuperacionService,
            SesionService sesionService) {

        this.usuarioService = usuarioService;
        this.recuperacionService = recuperacionService;
        this.sesionService = sesionService;
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
            @Valid @RequestBody InicioSesionRequest datos,
            HttpServletRequest solicitud,
            HttpServletResponse respuesta) {

        UsuarioResponse usuario = sesionService.iniciarSesion(
                datos,
                solicitud,
                respuesta
        );

        return ResponseEntity.ok(usuario);
    }

    @GetMapping("/csrf")
    public ResponseEntity<Map<String, String>> obtenerCsrf(
            CsrfToken codigo) {

        return ResponseEntity.ok(
                Map.of(
                        "token", codigo.getToken(),
                        "headerName", codigo.getHeaderName()
                )
        );
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

    @GetMapping("/perfil")
public ResponseEntity<UsuarioResponse> obtenerPerfil(
        Authentication autenticacion) {

    UsuarioResponse usuario = usuarioService.obtenerPerfil(
            autenticacion.getName()
    );

    return ResponseEntity.ok(usuario);
}

}