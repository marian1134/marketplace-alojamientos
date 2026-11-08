package com.inversioneslr.marketplace;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-18 · RF-15: cotización (alojamiento de ejemplo a $280.000 la noche y $50.000 de limpieza)
class CotizacionTest extends PruebaIntegracion {

    private String cotizacion(long id, int noches) {
        return """
                {"idAlojamiento": %d, "fechaLlegada": "%s", "fechaSalida": "%s", "cantidadHuespedes": 2}
                """.formatted(id, enDias(40), enDias(40 + noches));
    }

    @Test
    @DisplayName("HU-18 CA1: 3 noches = base + limpieza + 12,5 % de servicio, sin descuento")
    void tresNoches() throws Exception {
        long id = alojamiento("Apartamento con vista a la ciudad");
        mvc.perform(post("/api/v1/reservas/cotizacion").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cotizacion(id, 3)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.noches").value(3))
                .andExpect(jsonPath("$.subtotal").value(840000))
                .andExpect(jsonPath("$.tarifaLimpieza").value(50000))
                .andExpect(jsonPath("$.tarifaServicio").value(105000))
                .andExpect(jsonPath("$.descuentos").value(0))
                .andExpect(jsonPath("$.total").value(995000));
    }

    @Test
    @DisplayName("HU-18 CA2: 7 noches o más aplican el descuento semanal del 10 %")
    void descuentoSemanal() throws Exception {
        long id = alojamiento("Apartamento con vista a la ciudad");
        mvc.perform(post("/api/v1/reservas/cotizacion").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cotizacion(id, 7)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subtotal").value(1960000))
                .andExpect(jsonPath("$.descuentos").value(196000))
                .andExpect(jsonPath("$.total").value(2059000));
    }

    @Test
    @DisplayName("RN-07: no se cotiza si la salida es antes de la llegada")
    void fechasInvertidas() throws Exception {
        long id = alojamiento("Apartamento con vista a la ciudad");
        String cuerpo = """
                {"idAlojamiento": %d, "fechaLlegada": "%s", "fechaSalida": "%s", "cantidadHuespedes": 2}
                """.formatted(id, enDias(20), enDias(18));
        mvc.perform(post("/api/v1/reservas/cotizacion").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("RN-06: no se cotiza con más huéspedes que la capacidad")
    void excedeCapacidad() throws Exception {
        long id = alojamiento("Apartamento con vista a la ciudad");
        String cuerpo = """
                {"idAlojamiento": %d, "fechaLlegada": "%s", "fechaSalida": "%s", "cantidadHuespedes": 9}
                """.formatted(id, enDias(20), enDias(22));
        mvc.perform(post("/api/v1/reservas/cotizacion").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isBadRequest());
    }
}
