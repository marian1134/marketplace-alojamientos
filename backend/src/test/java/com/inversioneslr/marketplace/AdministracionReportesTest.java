package com.inversioneslr.marketplace;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-28 · RF-26 (dashboard), HU-29 · RF-27 (reportes) y contrato OpenAPI
class AdministracionReportesTest extends PruebaIntegracion {

    @Test
    @DisplayName("HU-28: el resumen trae reservas por estado, ingresos estimados y ciudades con más demanda")
    void dashboardCompleto() throws Exception {
        mvc.perform(get("/api/v1/admin/resumen").with(administrador()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reservas").exists())
                .andExpect(jsonPath("$.ingresosEstimados").exists())
                .andExpect(jsonPath("$.reservasPorEstado").isArray())
                .andExpect(jsonPath("$.ciudadesConMasDemanda").isArray());
    }

    @Test
    @DisplayName("HU-29 CA1: el administrador descarga el reporte de reservas en Excel y queda registrado")
    void reporteExcel() throws Exception {
        Integer antes = jdbc.queryForObject("SELECT COUNT(*) FROM exportacion_reporte", Integer.class);
        byte[] archivo = mvc.perform(get("/api/v1/admin/exportar").with(administrador())
                        .param("tipo", "RESERVAS").param("formato", "XLSX"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", containsString(".xlsx")))
                .andReturn().getResponse().getContentAsByteArray();
        // Un .xlsx es un archivo ZIP: empieza por "PK"
        assertThat(new String(archivo, 0, 2)).isEqualTo("PK");
        Integer despues = jdbc.queryForObject("SELECT COUNT(*) FROM exportacion_reporte", Integer.class);
        assertThat(despues).isEqualTo(antes + 1);
    }

    @Test
    @DisplayName("HU-29: el reporte de demanda por ciudad sale en PDF")
    void reportePdf() throws Exception {
        byte[] archivo = mvc.perform(get("/api/v1/admin/exportar").with(administrador())
                        .param("tipo", "DEMANDA").param("formato", "PDF")
                        .param("desde", "2026-01-01").param("hasta", "2026-12-31"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/pdf"))
                .andReturn().getResponse().getContentAsByteArray();
        assertThat(new String(archivo, 0, 4)).isEqualTo("%PDF");
    }

    @Test
    @DisplayName("HU-29: un huésped no puede exportar reportes")
    void huespedNoExporta() throws Exception {
        mvc.perform(get("/api/v1/admin/exportar").with(huesped())
                        .param("tipo", "USUARIOS").param("formato", "PDF"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("El contrato OpenAPI está publicado en /v3/api-docs")
    void contratoOpenApi() throws Exception {
        mvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("StayHub")))
                .andExpect(content().string(containsString("/api/v1/reservas")));
    }
}
