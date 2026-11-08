package com.inversioneslr.marketplace;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-15, HU-17 · RF-12, RF-16, RF-17 · RNF-02, RNF-03: reserva inmediata sin superposición
class ReservaTest extends PruebaIntegracion {

    private long reservar(long id, LocalDate llegada, LocalDate salida, String clave, int esperado) throws Exception {
        var resultado = mvc.perform(post("/api/v1/reservas").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reservaJson(id, llegada, salida, 2, clave)))
                .andExpect(status().is(esperado))
                .andReturn();
        return esperado == 201
                ? Long.parseLong(resultado.getResponse().getContentAsString().replaceAll(".*\"idReserva\":(\\d+).*", "$1"))
                : -1;
    }

    @Test
    @DisplayName("HU-15 CA1: con pago aprobado la reserva queda CONFIRMADA y bloquea sus noches")
    void reservaConfirmadaAlInstante() throws Exception {
        long id = alojamiento("Villa frente al mar");
        long reserva = reservar(id, enDias(50), enDias(53), nuevaClave(), 201);

        mvc.perform(get("/api/v1/reservas/" + reserva).with(huesped()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("CONFIRMADA"));

        Integer noches = jdbc.queryForObject(
                "SELECT COUNT(*) FROM noche_reservada WHERE reserva_id = ?", Integer.class, reserva);
        assertThat(noches).isEqualTo(3);
    }

    @Test
    @DisplayName("HU-15 CA2 · RN-08: no se pueden reservar noches que ya están ocupadas")
    void sinReservasSuperpuestas() throws Exception {
        long id = alojamiento("Villa frente al mar");
        reservar(id, enDias(60), enDias(64), nuevaClave(), 201);
        // Se cruza con la anterior en las noches 62 y 63
        reservar(id, enDias(62), enDias(66), nuevaClave(), 409);
    }

    @Test
    @DisplayName("RNF-03: repetir la misma solicitud (doble clic) no crea otra reserva")
    void idempotencia() throws Exception {
        long id = alojamiento("Villa frente al mar");
        String clave = nuevaClave();
        long primera = reservar(id, enDias(70), enDias(72), clave, 201);
        long segunda = reservar(id, enDias(70), enDias(72), clave, 201);
        assertThat(segunda).isEqualTo(primera);
    }

    @Test
    @DisplayName("HU-15: una tarjeta vencida no permite reservar")
    void tarjetaVencida() throws Exception {
        long id = alojamiento("Villa frente al mar");
        String cuerpo = reservaJson(id, enDias(80), enDias(82), 2, nuevaClave()).replace("12/30", "01/20");
        mvc.perform(post("/api/v1/reservas").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("HU-17 CA1: la reserva aparece en Mis viajes del huésped")
    void apareceEnMisViajes() throws Exception {
        long id = alojamiento("Villa frente al mar");
        long reserva = reservar(id, enDias(90), enDias(92), nuevaClave(), 201);
        mvc.perform(get("/api/v1/reservas/mis-reservas").with(huesped()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.idReserva == " + reserva + ")]").exists());
    }

    @Test
    @DisplayName("HU-11 CA1: un alojamiento con esas noches ocupadas no sale en la búsqueda")
    void ocupadoNoSaleEnBusqueda() throws Exception {
        long id = alojamiento("Villa frente al mar");
        reservar(id, enDias(100), enDias(103), nuevaClave(), 201);
        mvc.perform(get("/api/v1/busqueda").with(huesped())
                        .param("llegada", enDias(101).toString())
                        .param("salida", enDias(102).toString())
                        .param("huespedes", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.alojamiento.idAlojamiento == " + id + ")]").doesNotExist());
    }
}
