package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.RegistroUsuarioRequest;
import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.Rol;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.model.UsuarioRol;
import com.inversioneslr.marketplace.repository.RolRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import com.inversioneslr.marketplace.repository.UsuarioRolRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.inversioneslr.marketplace.dto.InicioSesionRequest;

import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Set;

@Service
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final UsuarioRolRepository usuarioRolRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    public UsuarioService(
            UsuarioRepository usuarioRepository,
            RolRepository rolRepository,
            UsuarioRolRepository usuarioRolRepository) {

        this.usuarioRepository = usuarioRepository;
        this.rolRepository = rolRepository;
        this.usuarioRolRepository = usuarioRolRepository;
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    @Transactional
    public UsuarioResponse registrar(RegistroUsuarioRequest datos) {

        if (datos.rol() == null
                || !Set.of("USUARIO", "ANFITRION").contains(datos.rol())) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El tipo de cuenta debe ser Huésped o Anfitrión"
            );
        }

        Rol rol = rolRepository
                .findByNombreIgnoreCase(datos.rol())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "El tipo de cuenta no está configurado"
                ));

        String correo = datos.correo()
                .trim()
                .toLowerCase(Locale.ROOT);

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
        usuario.setApellido(datos.apellido().trim());
        usuario.setCorreo(correo);
        usuario.setContrasenaHash(
                passwordEncoder.encode(datos.contrasena())
        );
        usuario.setEstado(EstadoUsuario.ACTIVO);

        if (datos.telefono() != null
                && !datos.telefono().isBlank()) {

            usuario.setTelefono(datos.telefono().trim());
        }

        Usuario guardado = usuarioRepository.save(usuario);

        UsuarioRol usuarioRol = new UsuarioRol();
        usuarioRol.setUsuario(guardado);
        usuarioRol.setRol(rol);
        usuarioRol.setEstado(true);

        usuarioRolRepository.save(usuarioRol);

        return new UsuarioResponse(
                guardado.getIdUsuario(),
                guardado.getNombre(),
                guardado.getApellido(),
                guardado.getCorreo(),
                guardado.getTelefono(),
                guardado.getEstado()
        );
    }

    @Transactional(readOnly = true)
public UsuarioResponse iniciarSesion(InicioSesionRequest datos) {

    String correo = datos.correo()
            .trim()
            .toLowerCase(Locale.ROOT);

    Usuario usuario = usuarioRepository
            .findByCorreoIgnoreCase(correo)
            .orElseThrow(() -> new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Correo o contraseña incorrectos"
            ));

    if (datos.contrasena()
            .getBytes(StandardCharsets.UTF_8).length > 72) {

        throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Correo o contraseña incorrectos"
        );
    }

    boolean contrasenaCorrecta = passwordEncoder.matches(
            datos.contrasena(),
            usuario.getContrasenaHash()
    );

    if (!contrasenaCorrecta) {
        throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Correo o contraseña incorrectos"
        );
    }

    if (usuario.getEstado() != EstadoUsuario.ACTIVO) {
        throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "El usuario no se encuentra activo"
        );
    }

    return new UsuarioResponse(
            usuario.getIdUsuario(),
            usuario.getNombre(),
            usuario.getApellido(),
            usuario.getCorreo(),
            usuario.getTelefono(),
            usuario.getEstado()
    );
}
@Transactional(readOnly = true)
public UsuarioResponse obtenerPerfil(String correo) {

    Usuario usuario = usuarioRepository
            .findByCorreoIgnoreCase(correo)
            .orElseThrow(() -> new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "La cuenta de la sesión no existe"
            ));

    if (usuario.getEstado() != EstadoUsuario.ACTIVO) {
        throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "La cuenta no se encuentra activa"
        );
    }

    return new UsuarioResponse(
            usuario.getIdUsuario(),
            usuario.getNombre(),
            usuario.getApellido(),
            usuario.getCorreo(),
            usuario.getTelefono(),
            usuario.getEstado()
    );
}

}