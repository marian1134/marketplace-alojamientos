package com.inversioneslr.marketplace;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// HU-01 · RF-01: registro de usuarios
class RegistroUsuarioTest extends PruebaIntegracion {

    private String registro(String correo, String telefono, String contrasena) {
        return """
                {"nombre": "Usuario de Prueba", "correo": "%s", "contrasena": "%s",
                 "telefono": "%s", "rol": "HUESPED"}
                """.formatted(correo, contrasena, telefono);
    }

    @Test
    @DisplayName("HU-01 CA1: con datos válidos se crea la cuenta")
    void registroValido() throws Exception {
        mvc.perform(post("/api/usuarios/registro").with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registro("nuevo.prueba@correo.com", "+573001234567", "Clave2026*")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.correo").value("nuevo.prueba@correo.com"))
                .andExpect(jsonPath("$.rol").value("HUESPED"));
    }

    @Test
    @DisplayName("HU-01 CA2: un correo ya registrado se rechaza")
    void correoRepetido() throws Exception {
        mvc.perform(post("/api/usuarios/registro").with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registro(HUESPED, "+573001234567", "Clave2026*")))
                .andExpect(status().isConflict());
    }

    @Test
    @DisplayName("HU-01 CA3: un celular que no es colombiano válido se rechaza")
    void celularInvalido() throws Exception {
        mvc.perform(post("/api/usuarios/registro").with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registro("otro.prueba@correo.com", "+572001234567", "Clave2026*")))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("RNF-01: una contraseña sin símbolo se rechaza")
    void contrasenaDebil() throws Exception {
        mvc.perform(post("/api/usuarios/registro").with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registro("debil.prueba@correo.com", "+573001234567", "abc12345")))
                .andExpect(status().isBadRequest());
    }
}
