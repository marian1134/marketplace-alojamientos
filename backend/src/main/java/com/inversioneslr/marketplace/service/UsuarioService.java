package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.ActualizarPerfilRequest;
import com.inversioneslr.marketplace.dto.InicioSesionRequest;
import com.inversioneslr.marketplace.dto.RegistroUsuarioRequest;
import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.Rol;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Locale;
import java.util.Set;

@Service
public class UsuarioService {

    // RNF-SEG-03: 5 intentos fallidos bloquean el login 15 minutos
    private static final int MAXIMO_INTENTOS = 5;
    private static final int MINUTOS_BLOQUEO = 15;

    private final UsuarioRepository usuarioRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    private final VerificadorCorreo verificadorCorreo;

    public UsuarioService(UsuarioRepository usuarioRepository, VerificadorCorreo verificadorCorreo) {
        this.usuarioRepository = usuarioRepository;
        this.verificadorCorreo = verificadorCorreo;
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    @Transactional
    public UsuarioResponse registrar(RegistroUsuarioRequest datos) {

        if (datos.rol() == null
                || !Set.of("HUESPED", "ANFITRION").contains(datos.rol())) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El tipo de cuenta debe ser Huésped o Anfitrión"
            );
        }

        String correo = datos.correo()
                .trim()
                .toLowerCase(Locale.ROOT);

        // Solo correos que puedan existir: formato válido y dominio que recibe correos
        if (!VerificadorCorreo.formatoValido(correo)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Escribe un correo válido, por ejemplo nombre@gmail.com"
            );
        }
        if (!verificadorCorreo.dominioRecibeCorreos(correo)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El dominio de ese correo no existe o no recibe correos. Revisa que esté bien escrito."
            );
        }

        if (usuarioRepository.existsByCorreoIgnoreCase(correo)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ya existe un usuario registrado con ese correo"
            );
        }

        if (datos.contrasena()
                .getBytes(StandardCharsets.UTF_8).length > 72) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La contraseña no puede superar 72 bytes"
            );
        }

        Usuario usuario = new Usuario();
        usuario.setNombre(datos.nombre().trim());
        usuario.setCorreo(correo);
        usuario.setContrasenaHash(
                passwordEncoder.encode(datos.contrasena())
        );
        usuario.setRol(Rol.valueOf(datos.rol()));
        usuario.setEstado(EstadoUsuario.ACTIVA);

        if (datos.telefono() != null
                && !datos.telefono().isBlank()) {

            usuario.setTelefono(datos.telefono().trim());
        }

        Usuario guardado = usuarioRepository.save(usuario);

        return UsuarioResponse.desde(guardado);
    }

    // noRollbackFor: el contador de intentos fallidos debe guardarse
    // aunque se responda con error.
    @Transactional(noRollbackFor = ResponseStatusException.class)
    public UsuarioResponse iniciarSesion(InicioSesionRequest datos) {

        String correo = datos.correo()
                .trim()
                .toLowerCase(Locale.ROOT);

        Usuario usuario = usuarioRepository
                .findByCorreoIgnoreCase(correo)
                .orElseThrow(this::credencialesIncorrectas);

        LocalDateTime ahora = LocalDateTime.now();

        if (usuario.getBloqueadoHasta() != null
                && usuario.getBloqueadoHasta().isAfter(ahora)) {

            throw new ResponseStatusException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Demasiados intentos fallidos. Intenta de nuevo en "
                            + MINUTOS_BLOQUEO + " minutos"
            );
        }

        boolean contrasenaCorrecta =
                datos.contrasena().getBytes(StandardCharsets.UTF_8).length <= 72
                && passwordEncoder.matches(
                        datos.contrasena(),
                        usuario.getContrasenaHash()
                );

        if (!contrasenaCorrecta) {
            registrarIntentoFallido(usuario, ahora);
            throw credencialesIncorrectas();
        }

        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "La cuenta no se encuentra activa"
            );
        }

        usuario.setIntentosFallidos(0);
        usuario.setBloqueadoHasta(null);

        return UsuarioResponse.desde(usuario);
    }

    @Transactional(readOnly = true)
    public UsuarioResponse obtenerPerfil(String correo) {

        Usuario usuario = usuarioRepository
                .findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "La cuenta de la sesión no existe"
                ));

        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "La cuenta no se encuentra activa"
            );
        }

        return UsuarioResponse.desde(usuario);
    }

    // Solo modifica la cuenta de la sesión; el correo y el rol no cambian.
    @Transactional
    public UsuarioResponse actualizarPerfil(String correo, ActualizarPerfilRequest datos) {
        Usuario usuario = usuarioRepository.bloquearPorCorreo(correo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "La cuenta de la sesión no existe"
                ));
        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "La cuenta no se encuentra activa"
            );
        }

        String nombre = datos.nombre() == null ? "" : datos.nombre().strip();
        String telefono = datos.telefono() == null ? "" : datos.telefono().strip();
        if (nombre.length() < 3 || nombre.length() > 60 || !nombre.matches("^[\\p{L}][\\p{L} .'-]*$")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "El nombre debe tener entre 3 y 60 caracteres y solo letras"
            );
        }
        // Celular de Colombia: +57 y 10 dígitos que empiezan por 3
        if (!telefono.matches("\\+573[0-9]{9}")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El celular debe tener 10 dígitos y empezar por 3"
            );
        }
        usuario.setNombre(nombre);
        usuario.setTelefono(telefono);
        return UsuarioResponse.desde(usuarioRepository.save(usuario));
    }

    private void registrarIntentoFallido(Usuario usuario, LocalDateTime ahora) {
        int intentos = usuario.getIntentosFallidos() + 1;

        if (intentos >= MAXIMO_INTENTOS) {
            usuario.setIntentosFallidos(0);
            usuario.setBloqueadoHasta(ahora.plusMinutes(MINUTOS_BLOQUEO));
        } else {
            usuario.setIntentosFallidos(intentos);
        }

        usuarioRepository.save(usuario);
    }

    private ResponseStatusException credencialesIncorrectas() {
        return new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Correo o contraseña incorrectos"
        );
    }
}
