package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.model.CorreoEnviado;
import com.inversioneslr.marketplace.model.EstadoCorreo;
import com.inversioneslr.marketplace.repository.CorreoEnviadoRepository;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

// HU-35 y HU-37: envío de correos por Brevo (API) o por Gmail (SMTP), sin internet
class CorreoServiceTest {

    private final JavaMailSender smtp = mock(JavaMailSender.class);
    private final CorreoEnviadoRepository registros = mock(CorreoEnviadoRepository.class);

    private CorreoService conBrevo(RestClient.Builder cliente) {
        return new CorreoService(smtp, "alojamientosmarketplace@gmail.com", "Alojamientos Marketplace",
                "clave-de-prueba", registros, cliente);
    }

    private CorreoService conGmail() {
        return new CorreoService(smtp, "alojamientosmarketplace@gmail.com", "Alojamientos Marketplace",
                "", registros, RestClient.builder());
    }

    @Test
    @DisplayName("Con clave de Brevo, el código de verificación sale por su API")
    void codigoPorBrevo() {
        RestClient.Builder cliente = RestClient.builder();
        MockRestServiceServer brevo = MockRestServiceServer.bindTo(cliente).build();
        brevo.expect(requestTo("https://api.brevo.com/v3/smtp/email"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("api-key", "clave-de-prueba"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("123456")))
                .andRespond(withSuccess("{\"messageId\":\"1\"}", org.springframework.http.MediaType.APPLICATION_JSON));

        conBrevo(cliente).enviarCodigo("ana@gmail.com", "Ana", "123456");

        brevo.verify();
        verify(smtp, never()).send(any(SimpleMailMessage.class));
    }

    @Test
    @DisplayName("Si Brevo rechaza el correo, se informa el error")
    void brevoRechaza() {
        RestClient.Builder cliente = RestClient.builder();
        MockRestServiceServer brevo = MockRestServiceServer.bindTo(cliente).build();
        brevo.expect(requestTo("https://api.brevo.com/v3/smtp/email")).andRespond(withStatus(HttpStatus.UNAUTHORIZED));

        assertThatThrownBy(() -> conBrevo(cliente).enviarEnlace("ana@gmail.com", "https://stayhub/?token=x"))
                .isInstanceOf(MailSendException.class);
    }

    @Test
    @DisplayName("Sin clave de Brevo, el código sale por Gmail (SMTP) con diseño HTML")
    void codigoPorGmail() {
        when(smtp.createMimeMessage()).thenReturn(new MimeMessage((Session) null));
        conGmail().enviarCodigo("ana@gmail.com", "Ana", "654321");
        verify(smtp).send(any(MimeMessage.class));
    }

    @Test
    @DisplayName("Los correos llevan el logo de StayHub arriba")
    void correoConLogo() {
        RestClient.Builder cliente = RestClient.builder();
        MockRestServiceServer brevo = MockRestServiceServer.bindTo(cliente).build();
        brevo.expect(requestTo("https://api.brevo.com/v3/smtp/email"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("https://logo.stayhub/icono.png")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Crear nueva contrase")))
                .andRespond(withSuccess("{\"messageId\":\"2\"}", org.springframework.http.MediaType.APPLICATION_JSON));

        CorreoService servicio = conBrevo(cliente);
        servicio.setUrlLogo("https://logo.stayhub/icono.png");
        servicio.enviarEnlace("ana@gmail.com", "https://stayhub/?token=x");

        brevo.verify();
    }

    @Test
    @DisplayName("Con el script de Gmail configurado, el correo sale por la cuenta de Google")
    void correoPorScriptDeGmail() {
        RestClient.Builder clienteScript = RestClient.builder();
        MockRestServiceServer google = MockRestServiceServer.bindTo(clienteScript).build();
        google.expect(requestTo("https://script.google.com/macros/s/prueba/exec"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"clave\":\"secreta\"")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("ana@gmail.com")))
                .andRespond(withSuccess("{\"ok\":true}", org.springframework.http.MediaType.APPLICATION_JSON));

        CorreoService servicio = conGmail();
        servicio.usarScript("https://script.google.com/macros/s/prueba/exec", "secreta", clienteScript);
        servicio.enviarCodigo("ana@gmail.com", "Ana", "111222");

        google.verify();
        verify(smtp, never()).send(any(MimeMessage.class));
    }

    @Test
    @DisplayName("Si el script de Gmail falla, el correo sale por Brevo")
    void scriptFallaYUsaBrevo() {
        RestClient.Builder clienteScript = RestClient.builder();
        MockRestServiceServer google = MockRestServiceServer.bindTo(clienteScript).build();
        google.expect(requestTo("https://script.google.com/macros/s/prueba/exec"))
                .andRespond(withSuccess("{\"ok\":false,\"error\":\"clave incorrecta\"}", org.springframework.http.MediaType.APPLICATION_JSON));
        RestClient.Builder clienteBrevo = RestClient.builder();
        MockRestServiceServer brevo = MockRestServiceServer.bindTo(clienteBrevo).build();
        brevo.expect(requestTo("https://api.brevo.com/v3/smtp/email"))
                .andRespond(withSuccess("{\"messageId\":\"3\"}", org.springframework.http.MediaType.APPLICATION_JSON));

        CorreoService servicio = conBrevo(clienteBrevo);
        servicio.usarScript("https://script.google.com/macros/s/prueba/exec", "secreta", clienteScript);
        servicio.enviarCodigo("ana@gmail.com", "Ana", "333444");

        google.verify();
        brevo.verify();
    }

    @Test
    @DisplayName("Si el script de Gmail no responde, se usa SMTP")
    void scriptSinRespuestaUsaSmtp() {
        RestClient.Builder clienteScript = RestClient.builder();
        MockRestServiceServer google = MockRestServiceServer.bindTo(clienteScript).build();
        google.expect(requestTo("https://script.google.com/macros/s/prueba/exec"))
                .andRespond(withStatus(HttpStatus.INTERNAL_SERVER_ERROR));
        when(smtp.createMimeMessage()).thenReturn(new MimeMessage((Session) null));

        CorreoService servicio = conGmail();
        servicio.usarScript("https://script.google.com/macros/s/prueba/exec", "secreta", clienteScript);
        servicio.enviarCodigo("ana@gmail.com", "Ana", "555666");

        verify(smtp).send(any(MimeMessage.class));
    }

    @Test
    @DisplayName("Sin logo configurado se usa el de la página publicada")
    void logoPorDefecto() {
        CorreoService servicio = conGmail();
        servicio.setUrlLogo(" ");
        assertThat(servicio.plantilla("Hola")).contains(CorreoService.LOGO_POR_DEFECTO).contains("Hola");
    }

    @Test
    @DisplayName("Un aviso de reserva se envía con HTML y queda como ENVIADO")
    void avisoEnviado() {
        CorreoEnviado registro = new CorreoEnviado();
        when(registros.findById(7L)).thenReturn(Optional.of(registro));
        when(smtp.createMimeMessage()).thenReturn(new MimeMessage((Session) null));

        conGmail().enviarAviso(new CorreoPendiente(7L, "ana@gmail.com", "Reserva confirmada",
                "Tu reserva quedó confirmada.", "Ver mis viajes", "https://stayhub/?ir=viajes"));

        verify(smtp).send(any(MimeMessage.class));
        assertThat(registro.getEstado()).isEqualTo(EstadoCorreo.ENVIADO);
    }

    @Test
    @DisplayName("Si el aviso falla, queda como FALLIDO con el motivo")
    void avisoFallido() {
        CorreoEnviado registro = new CorreoEnviado();
        when(registros.findById(8L)).thenReturn(Optional.of(registro));
        when(smtp.createMimeMessage()).thenReturn(new MimeMessage((Session) null));
        doThrow(new MailSendException("sin conexión")).when(smtp).send(any(MimeMessage.class));

        conGmail().enviarAviso(new CorreoPendiente(8L, "ana@gmail.com", "Reserva cancelada",
                "Tu reserva fue cancelada.", null, null));

        assertThat(registro.getEstado()).isEqualTo(EstadoCorreo.FALLIDO);
        assertThat(registro.getError()).contains("sin conexión");
    }

    @Test
    @DisplayName("Los usuarios de prueba (@stayhub.co) no reciben avisos")
    void usuarioDePrueba() {
        CorreoEnviado registro = new CorreoEnviado();
        when(registros.findById(9L)).thenReturn(Optional.of(registro));

        conGmail().enviarAviso(new CorreoPendiente(9L, "huesped@stayhub.co", "Aviso", "Texto", null, null));

        verify(smtp, never()).createMimeMessage();
        assertThat(registro.getEstado()).isEqualTo(EstadoCorreo.FALLIDO);
    }
}
