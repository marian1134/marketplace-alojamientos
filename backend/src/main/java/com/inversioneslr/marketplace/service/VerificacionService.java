package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.dto.VerificarCodigoRequest;
import com.inversioneslr.marketplace.model.CodigoVerificacion;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.CodigoVerificacionRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Locale;

// Segundo paso del inicio de sesión: código de 6 números por correo.
// Vence a los 10 minutos, permite 5 intentos y solo se usa una vez.
@Service
public class VerificacionService {

    private static final org.slf4j.Logger log =
            org.slf4j.LoggerFactory.getLogger(VerificacionService.class);

    public static final int MINUTOS_VIGENCIA = 10;
    private static final int MAXIMO_INTENTOS = 5;

    private final CodigoVerificacionRepository codigoRepository;
    private final UsuarioRepository usuarioRepository;
    private final CorreoService correoService;
    private final BCryptPasswordEncoder cifrador = new BCryptPasswordEncoder();
    private final SecureRandom aleatorio = new SecureRandom();

    public VerificacionService(
            CodigoVerificacionRepository codigoRepository,
            UsuarioRepository usuarioRepository,
            CorreoService correoService) {

        this.codigoRepository = codigoRepository;
        this.usuarioRepository = usuarioRepository;
        this.correoService = correoService;
    }

    // Se llama solo después de comprobar la contraseña
    @Transactional
    public void enviarCodigo(String correo) {

        Usuario usuario = buscarUsuario(correo);

        codigoRepository.anularPendientes(usuario.getIdUsuario());

        String codigo = String.format("%06d", aleatorio.nextInt(1_000_000));

        CodigoVerificacion registro = new CodigoVerificacion();
        registro.setUsuario(usuario);
        registro.setCodigoHash(cifrador.encode(codigo));
        registro.setExpiraEn(LocalDateTime.now().plusMinutes(MINUTOS_VIGENCIA));
        codigoRepository.save(registro);

        // Usuarios de los datos de prueba (…@…stayhub.co): no tienen buzón
        // real, así que el código se muestra en la consola del backend
        if (usuario.getCorreo().toLowerCase().endsWith("stayhub.co")) {
            log.info("Código para entrar con el usuario de prueba {}: {}",
                    usuario.getCorreo(), codigo);
            return;
        }

        try {
            correoService.enviarCodigo(usuario.getCorreo(), usuario.getNombre(), codigo);
        } catch (MailException error) {
            // Si el correo no sale, el código no se guarda (se deshace todo)
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "No pudimos enviar el código a tu correo. Intenta de nuevo en un momento."
            );
        }
    }

    // Revisa el código. Si está bien, devuelve el usuario para abrir la sesión.
    @Transactional(noRollbackFor = ResponseStatusException.class)
    public UsuarioResponse verificar(VerificarCodigoRequest datos) {

        Usuario usuario = buscarUsuario(datos.correo());

        CodigoVerificacion registro = codigoRepository
                .findFirstByUsuario_IdUsuarioAndUsadoFalseOrderByIdCodigoDesc(
                        usuario.getIdUsuario()
                )
                .orElseThrow(this::codigoNoValido);

        if (registro.getExpiraEn().isBefore(LocalDateTime.now())) {
            registro.setUsado(true);
            throw new ResponseStatusException(
                    HttpStatus.GONE,
                    "El código venció. Pide uno nuevo."
            );
        }

        if (!cifrador.matches(datos.codigo(), registro.getCodigoHash())) {

            int intentos = registro.getIntentos() + 1;
            registro.setIntentos(intentos);

            if (intentos >= MAXIMO_INTENTOS) {
                registro.setUsado(true);
                throw new ResponseStatusException(
                        HttpStatus.TOO_MANY_REQUESTS,
                        "Escribiste mal el código demasiadas veces. Pide uno nuevo."
                );
            }

            int quedan = MAXIMO_INTENTOS - intentos;
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Código incorrecto. Te quedan " + quedan
                            + (quedan == 1 ? " intento." : " intentos.")
            );
        }

        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "La cuenta no se encuentra activa"
            );
        }

        registro.setUsado(true);

        return UsuarioResponse.desde(usuario);
    }

    // "al***@gmail.com": para mostrar a dónde se envió sin revelar el correo
    public static String ocultarCorreo(String correo) {

        int arroba = correo.indexOf('@');

        if (arroba <= 2) {
            return "***" + correo.substring(Math.max(arroba, 0));
        }

        return correo.substring(0, 2) + "***" + correo.substring(arroba);
    }

    private Usuario buscarUsuario(String correo) {
        return usuarioRepository
                .findByCorreoIgnoreCase(correo.trim().toLowerCase(Locale.ROOT))
                .orElseThrow(this::codigoNoValido);
    }

    private ResponseStatusException codigoNoValido() {
        return new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "El código no es válido. Inicia sesión de nuevo para recibir uno."
        );
    }
}
