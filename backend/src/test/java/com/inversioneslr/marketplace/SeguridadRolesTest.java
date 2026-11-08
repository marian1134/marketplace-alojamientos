package com.inversioneslr.marketplace;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-05 · RF-03: rutas protegidas por rol
class SeguridadRolesTest extends PruebaIntegracion {

    @Test
    @DisplayName("HU-05 CA1: un huésped no puede entrar al panel de administración")
    void huespedNoEsAdministrador() throws Exception {
        mvc.perform(get("/api/v1/admin/resumen").with(huesped()))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("HU-05 CA2: sin sesión no se puede buscar ni ver el detalle")
    void sinSesionNoHayBusqueda() throws Exception {
        mvc.perform(get("/api/v1/busqueda"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("HU-28: el administrador sí ve el resumen del dashboard")
    void administradorVeResumen() throws Exception {
        mvc.perform(get("/api/v1/admin/resumen").with(administrador()))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("RF-13: la portada pública lista alojamientos sin sesión")
    void listadoPublico() throws Exception {
        mvc.perform(get("/api/v1/alojamientos"))
                .andExpect(status().isOk());
    }
}
