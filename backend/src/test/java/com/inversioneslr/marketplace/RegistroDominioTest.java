package com.inversioneslr.marketplace;

import com.inversioneslr.marketplace.service.VerificadorCorreo;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-03 y HU-07: correos con dominio real y nombre válido en el perfil
class RegistroDominioTest extends PruebaIntegracion {

    @MockitoBean
    private VerificadorCorreo verificador;

    @Test
    @DisplayName("HU-03: un correo cuyo dominio no recibe correos se rechaza")
    void dominioInexistente() throws Exception {
        when(verificador.dominioRecibeCorreos(anyString())).thenReturn(false);
        mvc.perform(post("/api/usuarios/registro").with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"nombre": "Ana Gomez", "correo": "ana@inventado-stayhub.xyz", "contrasena": "Clave2026*",
                                 "telefono": "+573001234567", "rol": "HUESPED"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(status().reason(org.hamcrest.Matchers.containsString("dominio")));
    }

    @Test
    @DisplayName("HU-07: el nombre del perfil debe tener solo letras y máximo 60 caracteres")
    void nombrePerfilInvalido() throws Exception {
        mvc.perform(patch("/api/usuarios/perfil").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Ana 123\", \"telefono\": \"+573001234567\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("HU-07: un nombre válido se guarda")
    void nombrePerfilValido() throws Exception {
        mvc.perform(patch("/api/usuarios/perfil").with(huesped()).with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Lina Niño\", \"telefono\": \"+573001234567\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Lina Niño"));
    }
}
