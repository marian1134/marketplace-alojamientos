package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.DatosRecuperacion;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.TokenRecuperacion;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.TokenRecuperacionRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.inversioneslr.marketplace.dto.DatosNuevaClave;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.server.ResponseStatusException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Locale;

@Service
public class RecuperacionService {

    private final UsuarioRepository usuarios;
    private final TokenRecuperacionRepository recuperaciones;
    private final CorreoService correo;
    private final String urlFrontend;

    private final SecureRandom generador = new SecureRandom();

    public RecuperacionService(
            UsuarioRepository usuarios,
            TokenRecuperacionRepository recuperaciones,
            CorreoService correo,
            @Value("${app.url-frontend:http://localhost:5173}")
            String urlFrontend) {

        this.usuarios = usuarios;
        this.recuperaciones = recuperaciones;
        this.correo = correo;
        this.urlFrontend = urlFrontend;
    }

    @Transactional
    public void solicitar(DatosRecuperacion datos) {

        String correoNormalizado = datos.correo()
                .trim()
                .toLowerCase(Locale.ROOT);

        Usuario usuario = usuarios
                .findByCorreoIgnoreCase(correoNormalizado)
                .orElse(null);

        if (usuario == null
                || usuario.getEstado() != EstadoUsuario.ACTIVA) {
            return;
        }

        byte[] bytes = new byte[32];
        generador.nextBytes(bytes);

        String codigo = Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(bytes);

        LocalDateTime ahora = LocalDateTime.now(ZoneOffset.UTC);

        TokenRecuperacion recuperacion = new TokenRecuperacion();
        recuperacion.setUsuario(usuario);
        recuperacion.setTokenHash(calcularHuella(codigo));
        recuperacion.setFechaCreacion(ahora);
        recuperacion.setFechaExpiracion(ahora.plusMinutes(15));
        recuperacion.setUsado(false);

        recuperaciones.save(recuperacion);

        String enlace = urlFrontend + "/?token=" + codigo;

        correo.enviarEnlace(usuario.getCorreo(), enlace);
    }


    @Transactional
public void cambiarClave(DatosNuevaClave datos) {

    String huella = calcularHuella(datos.token());

    TokenRecuperacion recuperacion = recuperaciones
            .findByTokenHash(huella)
            .orElseThrow(() -> new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El enlace no es válido o ya venció"
            ));

    LocalDateTime ahora = LocalDateTime.now(ZoneOffset.UTC);

    if (recuperacion.isUsado()
            || !recuperacion.getFechaExpiracion().isAfter(ahora)) {

        throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El enlace no es válido o ya venció"
        );
    }

    Usuario usuario = recuperacion.getUsuario();

    if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
        throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "No se puede cambiar la contraseña de esta cuenta"
        );
    }

    if (datos.contrasena()
            .getBytes(StandardCharsets.UTF_8).length > 72) {

        throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "La contraseña no puede superar 72 bytes"
        );
    }

    BCryptPasswordEncoder protector = new BCryptPasswordEncoder();

    usuario.setContrasenaHash(
            protector.encode(datos.contrasena())
    );

    recuperacion.setUsado(true);

    usuarios.save(usuario);
    recuperaciones.save(recuperacion);
}

    private String calcularHuella(String codigo) {

        try {
            MessageDigest algoritmo =
                    MessageDigest.getInstance("SHA-256");

            byte[] resultado = algoritmo.digest(
                    codigo.getBytes(StandardCharsets.UTF_8)
            );

            return HexFormat.of().formatHex(resultado);

        } catch (NoSuchAlgorithmException excepcion) {
            throw new IllegalStateException(
                    "No se pudo generar la huella del código",
                    excepcion
            );
        }
    }
}