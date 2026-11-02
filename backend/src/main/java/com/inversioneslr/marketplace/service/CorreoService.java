package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.model.CorreoEnviado;
import com.inversioneslr.marketplace.model.EstadoCorreo;
import com.inversioneslr.marketplace.repository.CorreoEnviadoRepository;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.web.util.HtmlUtils;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.time.LocalDateTime;

@Service
public class CorreoService {

    private static final Logger log = LoggerFactory.getLogger(CorreoService.class);

    private final JavaMailSender emisor;
    private final String remitente;
    private final CorreoEnviadoRepository correoRepository;

    public CorreoService(
            JavaMailSender emisor,
            @Value("${spring.mail.username}") String correoRemitente,
            @Value("${app.correo.nombre:Alojamientos Marketplace}") String nombreRemitente,
            CorreoEnviadoRepository correoRepository) {

        this.emisor = emisor;
        // Así se ve en la bandeja: "Alojamientos Marketplace <cuenta@gmail.com>"
        this.remitente = nombreRemitente + " <" + correoRemitente + ">";
        this.correoRepository = correoRepository;
    }

    public void enviarEnlace(String destinatario, String enlace) {

        SimpleMailMessage mensaje = new SimpleMailMessage();

        mensaje.setFrom(remitente);
        mensaje.setTo(destinatario);
        mensaje.setSubject("Recupera tu contraseña de StayHub");

        mensaje.setText(
                "Hola,\n\n"
                + "Recibimos una solicitud para cambiar tu contraseña "
                + "de StayHub.\n\n"
                + "Abre este enlace para crear una nueva contraseña:\n"
                + enlace
                + "\n\nEste enlace vence en 15 minutos "
                + "y solo puede utilizarse una vez.\n\n"
                + "Si no solicitaste este cambio, ignora este correo.\n\n"
                + "Equipo StayHub"
        );

        emisor.send(mensaje);
    }

    // Código de 6 números para entrar. No se guarda en notificacion ni en los
    // logs porque es secreto.
    public void enviarCodigo(String destinatario, String nombre, String codigo) {

        SimpleMailMessage mensaje = new SimpleMailMessage();

        mensaje.setFrom(remitente);
        mensaje.setTo(destinatario);
        mensaje.setSubject("Tu código para entrar a StayHub: " + codigo);

        mensaje.setText(
                "Hola, " + nombre + ".\n\n"
                + "Tu código para iniciar sesión en StayHub es:\n\n"
                + "    " + codigo + "\n\n"
                + "Vence en " + VerificacionService.MINUTOS_VIGENCIA + " minutos "
                + "y solo se puede usar una vez.\n\n"
                + "Si no intentaste entrar, alguien conoce tu contraseña: "
                + "cámbiala desde \"¿Olvidaste tu contraseña?\".\n\n"
                + "Equipo StayHub"
        );

        emisor.send(mensaje);
    }

    // Avisos de reservas. Se envían en segundo plano y solo cuando la
    // operación ya quedó guardada: si el correo falla, la reserva no se pierde.
    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void enviarAviso(CorreoPendiente correo) {

        CorreoEnviado registro = correoRepository
                .findById(correo.idCorreo())
                .orElse(null);

        // Los usuarios de los datos de prueba (…@…stayhub.co) no tienen buzón
        // real: no se les envía para no recibir avisos de "dirección no encontrada"
        if (correo.destinatario().toLowerCase().endsWith("stayhub.co")) {
            if (registro != null) {
                registro.setEstado(EstadoCorreo.FALLIDO);
                registro.setError("Usuario de prueba: no tiene buzón real");
                correoRepository.save(registro);
            }
            return;
        }

        try {
            // El correo va en dos versiones: texto simple y HTML con botón
            MimeMessage mensaje = emisor.createMimeMessage();
            MimeMessageHelper ayudante = new MimeMessageHelper(mensaje, true, "UTF-8");

            ayudante.setFrom(remitente);
            ayudante.setTo(correo.destinatario());
            ayudante.setSubject(correo.asunto());
            ayudante.setText(textoPlano(correo), html(correo));

            emisor.send(mensaje);
            log.info("Correo enviado: {}", correo.asunto());

            if (registro != null) {
                registro.setEstado(EstadoCorreo.ENVIADO);
                registro.setEnviadoEn(LocalDateTime.now());
                registro.setError(null);
            }
        } catch (MailException | MessagingException error) {
            log.warn("No se pudo enviar el correo \"{}\": {}",
                    correo.asunto(), error.getMessage());

            if (registro != null) {
                registro.setEstado(EstadoCorreo.FALLIDO);
                registro.setError(recortar(String.valueOf(error.getMessage()), 500));
            }
        }

        if (registro != null) {
            registro.setIntentos(registro.getIntentos() + 1);
            correoRepository.save(registro);
        }
    }

    private static boolean tieneBoton(CorreoPendiente correo) {
        return correo.botonTexto() != null && correo.botonEnlace() != null;
    }

    private static String textoPlano(CorreoPendiente correo) {

        if (!tieneBoton(correo)) {
            return correo.texto();
        }

        return correo.texto() + "\n\n" + correo.botonTexto() + ": " + correo.botonEnlace();
    }

    // Versión HTML: el mismo texto, con saltos de línea y un botón verde
    private static String html(CorreoPendiente correo) {

        String cuerpo = HtmlUtils.htmlEscape(correo.texto()).replace("\n", "<br>");

        String boton = tieneBoton(correo)
                ? "<p style=\"margin:28px 0\"><a href=\""
                        + HtmlUtils.htmlEscape(correo.botonEnlace())
                        + "\" style=\"background:#0b5d4b;color:#ffffff;padding:12px 24px;"
                        + "border-radius:8px;text-decoration:none;font-weight:bold;"
                        + "display:inline-block\">"
                        + HtmlUtils.htmlEscape(correo.botonTexto())
                        + "</a></p>"
                : "";

        return "<div style=\"font-family:Arial,sans-serif;font-size:15px;"
                + "line-height:1.5;color:#1f2933;max-width:560px\">"
                + cuerpo + boton + "</div>";
    }

    private static String recortar(String texto, int maximo) {
        return texto.length() <= maximo ? texto : texto.substring(0, maximo);
    }
}
