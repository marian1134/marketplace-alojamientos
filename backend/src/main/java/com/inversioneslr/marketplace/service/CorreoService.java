package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.model.CorreoEnviado;
import com.inversioneslr.marketplace.model.EstadoCorreo;
import com.inversioneslr.marketplace.repository.CorreoEnviadoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
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
            @Value("${spring.mail.username}") String remitente,
            CorreoEnviadoRepository correoRepository) {

        this.emisor = emisor;
        this.remitente = remitente;
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

    // Avisos de reservas. Se envían en segundo plano y solo cuando la
    // operación ya quedó guardada: si el correo falla, la reserva no se pierde.
    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void enviarAviso(CorreoPendiente correo) {

        SimpleMailMessage mensaje = new SimpleMailMessage();

        mensaje.setFrom(remitente);
        mensaje.setTo(correo.destinatario());
        mensaje.setSubject(correo.asunto());
        mensaje.setText(correo.texto());

        CorreoEnviado registro = correoRepository
                .findById(correo.idCorreo())
                .orElse(null);

        try {
            emisor.send(mensaje);
            log.info("Correo enviado: {}", correo.asunto());

            if (registro != null) {
                registro.setEstado(EstadoCorreo.ENVIADO);
                registro.setEnviadoEn(LocalDateTime.now());
                registro.setError(null);
            }
        } catch (MailException error) {
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

    private static String recortar(String texto, int maximo) {
        return texto.length() <= maximo ? texto : texto.substring(0, maximo);
    }
}
