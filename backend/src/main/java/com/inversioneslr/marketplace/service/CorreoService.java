package com.inversioneslr.marketplace.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class CorreoService {

    private final JavaMailSender emisor;
    private final String remitente;

    public CorreoService(
            JavaMailSender emisor,
            @Value("${spring.mail.username}") String remitente) {

        this.emisor = emisor;
        this.remitente = remitente;
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
}