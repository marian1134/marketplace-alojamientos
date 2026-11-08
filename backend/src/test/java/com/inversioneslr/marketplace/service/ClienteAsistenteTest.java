package com.inversioneslr.marketplace.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

// HU-30 · RF-34: lectura de la respuesta de Google Gemini (prueba unitaria, sin internet)
class ClienteAsistenteTest {

    @Test
    @DisplayName("Toma el texto de la respuesta y omite el razonamiento interno")
    void extraeTexto() {
        Map<String, Object> respuesta = Map.of("candidates", List.of(Map.of(
                "finishReason", "STOP",
                "content", Map.of("parts", List.of(
                        Map.of("text", "pensando...", "thought", true),
                        Map.of("text", "Para cancelar entra a Mis viajes."))))));
        assertThat(ClienteAsistente.extraerTexto(respuesta)).isEqualTo("Para cancelar entra a Mis viajes.");
    }

    @Test
    @DisplayName("Sin candidatos responde con el error IA_SIN_RESPUESTA")
    void sinRespuesta() {
        assertThatThrownBy(() -> ClienteAsistente.extraerTexto(Map.of("candidates", List.of())))
                .isInstanceOf(FalloAsistente.class);
    }

    @Test
    @DisplayName("Lee el motivo del error de Google sin exponer la clave")
    void motivoDeGoogle() {
        String cuerpo = "{\"error\": {\"code\": 400, \"message\": \"API key not valid. Please pass a valid API key.\"}}";
        assertThat(ClienteAsistente.mensajeDeGoogle(cuerpo)).isEqualTo("API key not valid. Please pass a valid API key.");
    }

    @Test
    @DisplayName("Sin clave el asistente queda como no configurado")
    void sinClave() {
        assertThat(new ClienteAsistente("", "gemini-3-flash", null).configurado()).isFalse();
        assertThat(new ClienteAsistente("\"AIzaFalsa\"", "gemini-3-flash", null).configurado()).isTrue();
    }
}
