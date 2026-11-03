package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.DatosNuevaClave;
import com.inversioneslr.marketplace.dto.DatosRecuperacion;
import com.inversioneslr.marketplace.dto.InicioSesionRequest;
import com.inversioneslr.marketplace.dto.RegistroUsuarioRequest;
import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.dto.VerificarCodigoRequest;
import com.inversioneslr.marketplace.service.FotoPerfilService;
import com.inversioneslr.marketplace.service.RecuperacionService;
import com.inversioneslr.marketplace.service.SesionService;
import com.inversioneslr.marketplace.service.UsuarioService;
import com.inversioneslr.marketplace.service.VerificacionService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;
    private final RecuperacionService recuperacionService;
    private final SesionService sesionService;
    private final VerificacionService verificacionService;
    private final FotoPerfilService fotoPerfilService;

    public UsuarioController(
            UsuarioService usuarioService,
            RecuperacionService recuperacionService,
            SesionService sesionService,
            VerificacionService verificacionService,
            FotoPerfilService fotoPerfilService) {

        this.usuarioService = usuarioService;
        this.recuperacionService = recuperacionService;
        this.sesionService = sesionService;
        this.verificacionService = verificacionService;
        this.fotoPerfilService = fotoPerfilService;
    }

    @PostMapping("/registro")
    public ResponseEntity<UsuarioResponse> registrar(
            @Valid @RequestBody RegistroUsuarioRequest datos) {

        UsuarioResponse usuario = usuarioService.registrar(datos);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(usuario);
    }

    // Paso 1: correo y contraseña. Si están bien, se envía un código al
    // correo y todavía NO se abre la sesión.
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> iniciarSesion(
            @Valid @RequestBody InicioSesionRequest datos) {

        UsuarioResponse usuario = usuarioService.iniciarSesion(datos);

        verificacionService.enviarCodigo(usuario.correo());

        return ResponseEntity
                .status(HttpStatus.ACCEPTED)
                .body(Map.of(
                        "verificacionRequerida", true,
                        "correoOculto",
                        VerificacionService.ocultarCorreo(usuario.correo()),
                        "minutos", VerificacionService.MINUTOS_VIGENCIA
                ));
    }

    // Paso 2: el código que llegó al correo. Si está bien, se abre la sesión.
    @PostMapping("/verificar-codigo")
    public ResponseEntity<UsuarioResponse> verificarCodigo(
            @Valid @RequestBody VerificarCodigoRequest datos,
            HttpServletRequest solicitud,
            HttpServletResponse respuesta) {

        UsuarioResponse usuario = verificacionService.verificar(datos);

        return ResponseEntity.ok(
                sesionService.crearSesion(usuario, solicitud, respuesta)
        );
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

    // Devuelve los datos del usuario que tiene la sesión iniciada.
    @GetMapping("/perfil")
    public ResponseEntity<UsuarioResponse> obtenerPerfil(
            Authentication autenticacion) {

        UsuarioResponse usuario = usuarioService.obtenerPerfil(
                autenticacion.getName()
        );

        return ResponseEntity.ok(usuario);
    }

    // Guarda o reemplaza la foto del usuario de la sesión.
    // El archivo llega como multipart con el nombre "archivo".
    @PostMapping( value = "/perfil/foto",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<UsuarioResponse> actualizarFoto(
            @RequestParam("imagen") MultipartFile archivo,
            Authentication autenticacion) {

        UsuarioResponse usuario = fotoPerfilService.guardar(
                archivo,
                autenticacion.getName()
        );

        return ResponseEntity.ok(usuario);
    }

    // Elimina la foto guardada y vuelve a mostrar las iniciales del usuario.
    @DeleteMapping("/perfil/foto")
    public ResponseEntity<UsuarioResponse> eliminarFoto(
            Authentication autenticacion) {

        UsuarioResponse usuario = fotoPerfilService.eliminar(
                autenticacion.getName()
        );

        return ResponseEntity.ok(usuario);
    }
}
