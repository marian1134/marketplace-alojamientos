package com.inversioneslr.marketplace;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-16, HU-17, HU-18: un visitante busca, ve y cotiza sin cuenta; para reservar inicia sesión
class VisitanteTest extends PruebaIntegracion {

    @Test
    @DisplayName("HU-16: un visitante sin sesión puede buscar alojamientos")
    void visitanteBusca() throws Exception {
        long id = alojamiento("Villa frente al mar");
        mvc.perform(get("/api/v1/busqueda")
                        .param("llegada", enDias(200).toString())
                        .param("salida", enDias(202).toString())
                        .param("huespedes", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.alojamiento.idAlojamiento == " + id + ")]").exists());
    }

    @Test
    @DisplayName("HU-17: un visitante ve el detalle, sin favoritos marcados")
    void visitanteVeDetalle() throws Exception {
        long id = alojamiento("Villa frente al mar");
        mvc.perform(get("/api/v1/alojamientos/" + id + "/detalle"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.alojamiento.idAlojamiento").value(id))
                .andExpect(jsonPath("$.esFavorito").value(false));
    }

    @Test
    @DisplayName("HU-18: un visitante puede ver el precio de su estadía")
    void visitanteCotiza() throws Exception {
        long id = alojamiento("Apartamento con vista a la ciudad");
        String cuerpo = """
                {"idAlojamiento": %d, "fechaLlegada": "%s", "fechaSalida": "%s", "cantidadHuespedes": 2}
                """.formatted(id, enDias(40), enDias(43));
        mvc.perform(post("/api/v1/reservas/cotizacion").with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(995000));
    }

    @Test
    @DisplayName("HU-19: para reservar sí hay que iniciar sesión")
    void visitanteNoReserva() throws Exception {
        long id = alojamiento("Villa frente al mar");
        mvc.perform(post("/api/v1/reservas").with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reservaJson(id, enDias(210), enDias(212), 2, nuevaClave())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("HU-17: con sesión, el huésped ve el detalle y si es su favorito")
    void huespedVeDetalle() throws Exception {
        long id = alojamiento("Villa frente al mar");
        mvc.perform(get("/api/v1/alojamientos/" + id + "/detalle").with(huesped()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.esFavorito").value(false));
    }

    @Test
    @DisplayName("HU-18: el anfitrión no puede cotizar su propio alojamiento")
    void anfitrionNoCotizaLoSuyo() throws Exception {
        long id = alojamiento("Villa frente al mar");
        String cuerpo = """
                {"idAlojamiento": %d, "fechaLlegada": "%s", "fechaSalida": "%s", "cantidadHuespedes": 2}
                """.formatted(id, enDias(50), enDias(52));
        mvc.perform(post("/api/v1/reservas/cotizacion").with(anfitrion()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("HU-16: con sesión, la búsqueda también funciona")
    void huespedBusca() throws Exception {
        mvc.perform(get("/api/v1/busqueda").with(huesped()).param("destino", "Cartagena"))
                .andExpect(status().isOk());
    }
}
