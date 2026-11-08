package com.inversioneslr.marketplace;

import jakarta.persistence.EntityManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.UUID;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;

/**
 * Base de las pruebas de integración: levanta el backend completo contra
 * la base de datos de pruebas (scripts 01 a 14 con los datos del 04).
 * Cada prueba se deshace al terminar (@Transactional), así no se ensucia la base.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
// Las pruebas no consultan el DNS real para revisar los dominios de correo
@TestPropertySource(properties = "app.correo.verificar-dominio=false")
public abstract class PruebaIntegracion {

    protected static final String HUESPED = "huesped@stayhub.co";
    protected static final String ANFITRION = "anfitrion@stayhub.co";
    protected static final String ADMIN = "admin@stayhub.co";

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected JdbcTemplate jdbc;

    @Autowired
    protected EntityManager entidades;

    // Después de cambiar datos con SQL directo, se olvida la copia en memoria de JPA
    protected void refrescar() {
        entidades.flush();
        entidades.clear();
    }

    protected RequestPostProcessor huesped() {
        return user(HUESPED).roles("HUESPED");
    }

    protected RequestPostProcessor anfitrion() {
        return user(ANFITRION).roles("ANFITRION");
    }

    protected RequestPostProcessor administrador() {
        return user(ADMIN).roles("ADMINISTRADOR");
    }

    // Busca el id de un alojamiento de ejemplo por su título (script 04)
    protected long alojamiento(String titulo) {
        return jdbc.queryForObject(
                "SELECT id FROM publicacion WHERE titulo = ? LIMIT 1", Long.class, titulo);
    }

    protected static LocalDate enDias(int dias) {
        return LocalDate.now().plusDays(dias);
    }

    // Cuerpo JSON de una reserva pagada con la tarjeta de prueba (pago simulado sin Stripe)
    protected static String reservaJson(long idAlojamiento, LocalDate llegada, LocalDate salida,
                                        int huespedes, String clave) {
        return """
                {"idAlojamiento": %d, "fechaLlegada": "%s", "fechaSalida": "%s",
                 "cantidadHuespedes": %d, "claveIdempotencia": "%s",
                 "numeroTarjeta": "4242424242424242", "titular": "Prueba Automatica",
                 "expiracion": "12/30", "cvc": "123", "moneda": "COP"}
                """.formatted(idAlojamiento, llegada, salida, huespedes, clave);
    }

    protected static String nuevaClave() {
        return UUID.randomUUID().toString();
    }
}
