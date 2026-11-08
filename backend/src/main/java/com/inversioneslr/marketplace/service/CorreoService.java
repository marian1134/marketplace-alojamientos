package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.model.CorreoEnviado;
import com.inversioneslr.marketplace.model.EstadoCorreo;
import com.inversioneslr.marketplace.repository.CorreoEnviadoRepository;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.mail.MailException;
import org.springframework.mail.MailPreparationException;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.util.HtmlUtils;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
public class CorreoService {

    private static final Logger log = LoggerFactory.getLogger(CorreoService.class);

    private final JavaMailSender emisor;
    private final String remitente;
    private final String correoRemitente;
    private final String nombreRemitente;
    private final CorreoEnviadoRepository correoRepository;
    // Con clave de Brevo los correos salen por su API (HTTPS). Sirve en servidores
    // que bloquean el envío por SMTP, como el plan gratis de Render.
    private final String claveBrevo;
    private final RestClient brevo;

    // Logo de StayHub que va arriba de cada correo (imagen pública de la página)
    static final String LOGO_POR_DEFECTO = "https://stayhub-fawn.vercel.app/icono-192.png";
    private String urlLogo = LOGO_POR_DEFECTO;

    // Envío por la cuenta de Gmail con un Google Apps Script (por HTTPS).
    // Así el correo sale desde Google y Gmail muestra la foto de perfil de la
    // cuenta en vez de la inicial. Si el script falla, se usa Brevo o SMTP.
    private String urlScript = "";
    private String claveScript = "";
    private RestClient script;

    @Value("${GOOGLE_SCRIPT_URL:}")
    void setUrlScript(String url) {
        usarScript(url, claveScript, null);
    }

    @Value("${GOOGLE_SCRIPT_CLAVE:}")
    void setClaveScript(String clave) {
        usarScript(urlScript, clave, null);
    }

    // El script de Google responde con una redirección: hay que seguirla
    // para leer si el correo salió
    void usarScript(String url, String clave, RestClient.Builder cliente) {
        this.urlScript = url == null ? "" : url.strip();
        this.claveScript = clave == null ? "" : clave.strip();
        RestClient.Builder constructor = cliente != null ? cliente : RestClient.builder()
                .requestFactory(new org.springframework.http.client.JdkClientHttpRequestFactory(
                        java.net.http.HttpClient.newBuilder()
                                .followRedirects(java.net.http.HttpClient.Redirect.ALWAYS)
                                .connectTimeout(java.time.Duration.ofSeconds(10))
                                .build()));
        this.script = constructor.build();
    }

    private boolean hayScript() {
        return !urlScript.isEmpty() && !claveScript.isEmpty();
    }

    @Value("${app.correo.logo:" + LOGO_POR_DEFECTO + "}")
    void setUrlLogo(String urlLogo) {
        if (urlLogo != null && !urlLogo.isBlank()) {
            this.urlLogo = urlLogo.strip();
        }
    }

    @org.springframework.beans.factory.annotation.Autowired
    public CorreoService(
            JavaMailSender emisor,
            @Value("${spring.mail.username}") String correoRemitente,
            @Value("${app.correo.nombre:Alojamientos Marketplace}") String nombreRemitente,
            @Value("${BREVO_API_KEY:}") String claveBrevo,
            CorreoEnviadoRepository correoRepository) {
        this(emisor, correoRemitente, nombreRemitente, claveBrevo, correoRepository, RestClient.builder());
    }

    // Para las pruebas: permite simular la API de Brevo
    CorreoService(
            JavaMailSender emisor,
            String correoRemitente,
            String nombreRemitente,
            String claveBrevo,
            CorreoEnviadoRepository correoRepository,
            RestClient.Builder clienteBrevo) {

        this.emisor = emisor;
        this.correoRemitente = correoRemitente;
        this.nombreRemitente = nombreRemitente;
        // Así se ve en la bandeja: "Alojamientos Marketplace <cuenta@gmail.com>"
        this.remitente = nombreRemitente + " <" + correoRemitente + ">";
        this.correoRepository = correoRepository;
        this.claveBrevo = claveBrevo == null ? "" : claveBrevo.strip();
        this.brevo = clienteBrevo.baseUrl("https://api.brevo.com").build();
    }

    // Envía un correo por Brevo (si hay clave) o por SMTP. El html es opcional.
    private void enviar(String destinatario, String asunto, String texto, String html) {
        if (hayScript()) {
            try {
                enviarPorScript(destinatario, asunto, texto, html);
                return;
            } catch (MailException error) {
                log.warn("El script de Gmail no envió el correo, se intenta por otro medio: {}",
                        error.getMessage());
            }
        }
        if (!claveBrevo.isEmpty()) {
            enviarPorBrevo(destinatario, asunto, texto, html);
            return;
        }
        if (html == null) {
            SimpleMailMessage mensaje = new SimpleMailMessage();
            mensaje.setFrom(remitente);
            mensaje.setTo(destinatario);
            mensaje.setSubject(asunto);
            mensaje.setText(texto);
            emisor.send(mensaje);
            return;
        }
        try {
            MimeMessage mensaje = emisor.createMimeMessage();
            MimeMessageHelper ayudante = new MimeMessageHelper(mensaje, true, "UTF-8");
            ayudante.setFrom(remitente);
            ayudante.setTo(destinatario);
            ayudante.setSubject(asunto);
            ayudante.setText(texto, html);
            emisor.send(mensaje);
        } catch (MessagingException error) {
            throw new MailPreparationException("No se pudo armar el correo", error);
        }
    }

    private void enviarPorScript(String destinatario, String asunto, String texto, String html) {
        Map<String, Object> cuerpo = new java.util.HashMap<>(Map.of(
                "clave", claveScript,
                "para", destinatario,
                "asunto", asunto,
                "texto", texto,
                "nombre", nombreRemitente
        ));
        if (html != null) cuerpo.put("html", html);
        Map<?, ?> respuesta;
        try {
            respuesta = script.post().uri(urlScript)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(cuerpo)
                    .retrieve()
                    .body(Map.class);
        } catch (RestClientException error) {
            throw new MailSendException("El script de Gmail no respondió: " + error.getMessage(), error);
        }
        if (respuesta == null || !Boolean.TRUE.equals(respuesta.get("ok"))) {
            Object motivo = respuesta == null ? "sin respuesta" : respuesta.get("error");
            throw new MailSendException("El script de Gmail rechazó el correo: " + motivo);
        }
    }

    private void enviarPorBrevo(String destinatario, String asunto, String texto, String html) {
        Map<String, Object> cuerpo = new java.util.HashMap<>(Map.of(
                "sender", Map.of("name", nombreRemitente, "email", correoRemitente),
                "to", List.of(Map.of("email", destinatario)),
                "subject", asunto,
                "textContent", texto
        ));
        if (html != null) cuerpo.put("htmlContent", html);
        try {
            brevo.post().uri("/v3/smtp/email")
                    .header("api-key", claveBrevo)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(cuerpo)
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientException error) {
            throw new MailSendException("Brevo rechazó el correo: " + error.getMessage(), error);
        }
    }

    public void enviarEnlace(String destinatario, String enlace) {
        enviar(destinatario, "Recupera tu contraseña de StayHub",
                "Hola,\n\n"
                + "Recibimos una solicitud para cambiar tu contraseña "
                + "de StayHub.\n\n"
                + "Abre este enlace para crear una nueva contraseña:\n"
                + enlace
                + "\n\nEste enlace vence en 15 minutos "
                + "y solo puede utilizarse una vez.\n\n"
                + "Si no solicitaste este cambio, ignora este correo.\n\n"
                + "Equipo StayHub",
                plantilla("<p style=\"margin:0 0 16px\">Hola,</p>"
                        + "<p style=\"margin:0 0 16px\">Recibimos una solicitud para cambiar tu contraseña de StayHub.</p>"
                        + boton("Crear nueva contraseña", enlace)
                        + "<p style=\"margin:0 0 16px;color:#5b6b69;font-size:13px\">Este enlace vence en 15 minutos "
                        + "y solo puede utilizarse una vez. Si no solicitaste este cambio, ignora este correo.</p>"));
    }

    // Código de 6 números para entrar. No se guarda en notificacion ni en los
    // logs porque es secreto.
    public void enviarCodigo(String destinatario, String nombre, String codigo) {
        enviar(destinatario, "Tu código para entrar a StayHub: " + codigo,
                "Hola, " + nombre + ".\n\n"
                + "Tu código para iniciar sesión en StayHub es:\n\n"
                + "    " + codigo + "\n\n"
                + "Vence en " + VerificacionService.MINUTOS_VIGENCIA + " minutos "
                + "y solo se puede usar una vez.\n\n"
                + "Si no intentaste entrar, alguien conoce tu contraseña: "
                + "cámbiala desde \"¿Olvidaste tu contraseña?\".\n\n"
                + "Equipo StayHub",
                plantilla("<p style=\"margin:0 0 16px\">Tu código para iniciar sesión en StayHub es:</p>"
                        + "<p style=\"margin:0 0 20px;font-size:32px;font-weight:bold;letter-spacing:8px;"
                        + "color:#0b5d4b\">" + HtmlUtils.htmlEscape(codigo) + "</p>"
                        + "<p style=\"margin:0 0 16px;color:#5b6b69;font-size:13px\">Vence en "
                        + VerificacionService.MINUTOS_VIGENCIA + " minutos y solo se puede usar una vez. "
                        + "Si no intentaste entrar, cambia tu contraseña desde «¿Olvidaste tu contraseña?».</p>"));
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
            enviar(correo.destinatario(), correo.asunto(), textoPlano(correo), html(correo));
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
    private String html(CorreoPendiente correo) {

        String cuerpo = HtmlUtils.htmlEscape(correo.texto()).replace("\n", "<br>");

        String enlace = tieneBoton(correo) ? boton(correo.botonTexto(), correo.botonEnlace()) : "";

        return plantilla("<p style=\"margin:0 0 16px\">" + cuerpo + "</p>" + enlace);
    }

    private static String boton(String texto, String enlace) {
        return "<p style=\"margin:24px 0\"><a href=\""
                + HtmlUtils.htmlEscape(enlace)
                + "\" style=\"background:#0b5d4b;color:#ffffff;padding:12px 24px;"
                + "border-radius:8px;text-decoration:none;font-weight:bold;"
                + "display:inline-block\">"
                + HtmlUtils.htmlEscape(texto)
                + "</a></p>";
    }

    // Diseño común de los correos: encabezado verde con el logo, contenido y pie
    String plantilla(String contenido) {
        return "<div style=\"margin:0;padding:24px 12px;background:#f3f6f4\">"
                + "<table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" "
                + "style=\"max-width:560px;margin:0 auto;background:#ffffff;border-radius:14px;"
                + "overflow:hidden;font-family:Arial,sans-serif;font-size:15px;line-height:1.5;color:#1f2933\">"
                + "<tr><td style=\"padding:18px 24px;background:#0b5d4b\">"
                + "<img src=\"" + HtmlUtils.htmlEscape(urlLogo) + "\" width=\"40\" height=\"40\" alt=\"\" "
                + "style=\"vertical-align:middle;border:0;border-radius:10px\">"
                + "<span style=\"vertical-align:middle;margin-left:12px;color:#ffffff;font-size:22px;"
                + "font-weight:bold;font-family:Georgia,serif\">StayHub</span>"
                + "</td></tr>"
                + "<tr><td style=\"padding:28px 24px 8px\">" + contenido + "</td></tr>"
                + "<tr><td style=\"padding:16px 24px 24px;color:#7a8a87;font-size:12px;"
                + "border-top:1px solid #e6ecea\">"
                + "Equipo StayHub · Inversiones LR<br>Este es un correo automático, no lo respondas."
                + "</td></tr></table></div>";
    }

    private static String recortar(String texto, int maximo) {
        return texto.length() <= maximo ? texto : texto.substring(0, maximo);
    }
}
