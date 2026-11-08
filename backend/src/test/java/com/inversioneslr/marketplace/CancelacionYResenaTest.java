package com.inversioneslr.marketplace;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-21 · RF-18 (cancelación) y HU-23 · RF-22 (reseñas)
class CancelacionYResenaTest extends PruebaIntegracion {

    private long reservar(String titulo, int desde, int hasta) throws Exception {
        String json = mvc.perform(post("/api/v1/reservas").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reservaJson(alojamiento(titulo), enDias(desde), enDias(hasta), 2, nuevaClave())))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return Long.parseLong(json.replaceAll(".*\"idReserva\":(\\d+).*", "$1"));
    }

    @Test
    @DisplayName("HU-21 CA1: con política Flexible y tiempo de sobra se devuelve todo y se liberan las noches")
    void cancelacionConDevolucionTotal() throws Exception {
        long reserva = reservar("Cabaña frente al lago", 30, 32);

        mvc.perform(post("/api/v1/reservas/" + reserva + "/cancelar").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"motivo\": \"Cambio de planes\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("CANCELADA"));

        Integer noches = jdbc.queryForObject(
                "SELECT COUNT(*) FROM noche_reservada WHERE reserva_id = ?", Integer.class, reserva);
        assertThat(noches).isZero();

        // RN-13: queda registrado quién, por qué y cuánto se devolvió
        var registro = jdbc.queryForMap(
                "SELECT c.motivo, c.porcentaje_devolucion, c.valor_devolucion, p.monto "
                        + "FROM cancelacion c JOIN pago p ON p.reserva_id = c.reserva_id WHERE c.reserva_id = ?", reserva);
        assertThat(registro.get("motivo")).isEqualTo("Cambio de planes");
        assertThat(((Number) registro.get("porcentaje_devolucion")).doubleValue()).isEqualTo(100.0);
        assertThat(((Number) registro.get("valor_devolucion")).doubleValue())
                .isEqualTo(((Number) registro.get("monto")).doubleValue());
    }

    @Test
    @DisplayName("HU-21 CA2: con política Estricta y poca anticipación no hay devolución")
    void cancelacionSinDevolucion() throws Exception {
        long reserva = reservar("Glamping en la montaña", 3, 5);

        mvc.perform(post("/api/v1/reservas/" + reserva + "/cancelar").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"motivo\": \"Enfermedad\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("CANCELADA"));

        Double porcentaje = jdbc.queryForObject(
                "SELECT porcentaje_devolucion FROM cancelacion WHERE reserva_id = ?", Double.class, reserva);
        assertThat(porcentaje).isZero();
    }

    @Test
    @DisplayName("HU-23 CA2 · RN-17: no se puede reseñar una reserva que aún no termina")
    void resenaAntesDeTiempo() throws Exception {
        long reserva = reservar("Cabaña frente al lago", 40, 42);
        mvc.perform(post("/api/v1/reservas/" + reserva + "/resena").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"calificacion\": 5, \"comentario\": \"Todo excelente, muy recomendado\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("HU-23 CA1 y CA3: se reseña una estancia terminada y solo una vez")
    void resenaDeEstanciaTerminada() throws Exception {
        long reserva = reservar("Cabaña frente al lago", 44, 46);
        // Se simula que la estancia ya pasó
        refrescar();
        jdbc.update("DELETE FROM noche_reservada WHERE reserva_id = ?", reserva);
        jdbc.update("UPDATE reserva SET fecha_llegada = ?, fecha_salida = ?, estado = 'COMPLETADA' WHERE id = ?",
                enDias(-5), enDias(-3), reserva);
        refrescar();

        String resena = "{\"calificacion\": 4, \"comentario\": \"Muy buena estadía, todo limpio\"}";
        mvc.perform(post("/api/v1/reservas/" + reserva + "/resena").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(resena))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/v1/reservas/" + reserva + "/resena").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(resena))
                .andExpect(status().is4xxClientError());
    }
}
