package com.inversioneslr.marketplace;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.List;

import static org.hamcrest.Matchers.hasItems;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-09 · RF-07 y RF-10: publicar un alojamiento con servicios y reglas
class ServiciosYReglasTest extends PruebaIntegracion {

    @Test
    @DisplayName("RF-10: el catálogo de servicios está disponible")
    void catalogo() throws Exception {
        mvc.perform(get("/api/v1/alojamientos/servicios").with(anfitrion()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].nombre", hasItems("Wifi", "Piscina", "Cocina")));
    }

    @Test
    @DisplayName("HU-09 CA1 · RF-10: el anfitrión publica con servicios y reglas")
    void publicarConServiciosYReglas() throws Exception {
        List<Long> ids = jdbc.queryForList("SELECT id FROM servicio WHERE nombre IN ('Wifi', 'Piscina') ORDER BY id", Long.class);
        String cuerpo = """
                {"titulo": "Casa de prueba con piscina", "descripcion": "Casa amplia para probar la publicación.",
                 "ciudad": "Villa de Leyva", "direccion": "Vereda centro", "tipoAlojamiento": "CASA",
                 "capacidad": 6, "precioNoche": 300000, "tarifaLimpieza": 40000, "tipoPolitica": "FLEXIBLE",
                 "servicios": [%d, %d], "reglas": ["No se permite fumar.", "No se admiten fiestas."]}
                """.formatted(ids.get(0), ids.get(1));
        mvc.perform(post("/api/v1/alojamientos").with(anfitrion()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.estado").value("BORRADOR"))
                .andExpect(jsonPath("$.servicios", hasItems("Wifi", "Piscina")))
                .andExpect(jsonPath("$.reglas", hasItems("No se permite fumar.", "No se admiten fiestas.")));
    }

    @Test
    @DisplayName("HU-09 CA2 · RN-06: no se publica con capacidad 0")
    void capacidadCero() throws Exception {
        String cuerpo = """
                {"titulo": "Sin capacidad", "descripcion": "Prueba de validación.", "ciudad": "Cali",
                 "direccion": "Centro", "tipoAlojamiento": "CASA", "capacidad": 0, "precioNoche": 100000}
                """;
        mvc.perform(post("/api/v1/alojamientos").with(anfitrion()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("RF-10: un servicio que no existe se rechaza")
    void servicioInexistente() throws Exception {
        String cuerpo = """
                {"titulo": "Servicio raro", "descripcion": "Prueba de validación.", "ciudad": "Cali",
                 "direccion": "Centro", "tipoAlojamiento": "CASA", "capacidad": 2, "precioNoche": 100000,
                 "servicios": [999999]}
                """;
        mvc.perform(post("/api/v1/alojamientos").with(anfitrion()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isBadRequest());
    }
}
