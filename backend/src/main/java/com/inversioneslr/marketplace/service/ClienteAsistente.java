package com.inversioneslr.marketplace.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Habla con la IA de Google (Gemini), que tiene plan gratis.
 * La clave se crea en aistudio.google.com y se pasa en GEMINI_API_KEY.
 */
@Component
public class ClienteAsistente {
    private static final Logger log = LoggerFactory.getLogger(ClienteAsistente.class);
    private final String clave;
    private final String modelo;
    private final RestClient cliente;

    @Autowired
    public ClienteAsistente(
            @Value("${GEMINI_API_KEY:}") String clave,
            @Value("${GEMINI_MODEL:gemini-2.5-flash}") String modelo) {
        this(clave, modelo, crearCliente());
    }

    ClienteAsistente(String clave, String modelo, RestClient cliente) {
        this.clave = clave == null ? "" : clave.strip();
        this.modelo = modelo == null || modelo.isBlank() ? "gemini-2.5-flash" : modelo.strip();
        this.cliente = cliente;
    }

    public boolean configurado() { return !clave.isBlank(); }

    public String responder(String instrucciones, List<Map<String, String>> mensajes) {
        if (!configurado()) throw new FalloAsistente(HttpStatus.SERVICE_UNAVAILABLE, "IA_NO_CONFIGURADA");

        // Gemini llama "model" a las respuestas del asistente
        List<Map<String, Object>> contenidos = new ArrayList<>();
        for (Map<String, String> mensaje : mensajes) {
            String rol = "assistant".equals(mensaje.get("role")) ? "model" : "user";
            contenidos.add(Map.of(
                    "role", rol,
                    "parts", List.of(Map.of("text", mensaje.get("content")))
            ));
        }
        Map<String, Object> cuerpo = Map.of(
                "systemInstruction", Map.of("parts", List.of(Map.of("text", instrucciones))),
                "contents", contenidos,
                "generationConfig", Map.of("maxOutputTokens", 2048, "temperature", 0.4)
        );

        Map<?, ?> respuesta;
        try {
            // Sin reintentos automaticos para no gastar la cuota gratis.
            respuesta = cliente.post().uri("/v1beta/models/{modelo}:generateContent", modelo)
                    .header("x-goog-api-key", clave)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(cuerpo).retrieve().body(Map.class);
        } catch (RestClientResponseException error) {
            int estado = error.getStatusCode().value();
            log.warn("Consulta IA rechazada por Gemini HTTP={}", estado);
            String codigo = estado == 429 ? "IA_CUOTA_PROVEEDOR"
                    : estado == 400 || estado == 401 || estado == 403 || estado == 404
                    ? "IA_CONFIGURACION" : "IA_PROVEEDOR";
            throw new FalloAsistente(HttpStatus.SERVICE_UNAVAILABLE, codigo);
        } catch (RuntimeException error) {
            Throwable causa = error;
            for (int i = 0; i < 10 && causa.getCause() != null; i++) {
                causa = causa.getCause();
            }
            log.warn("Consulta IA fallida: tipo={}, causa={}",
                    error.getClass().getSimpleName(), causa.getClass().getSimpleName());
            throw new FalloAsistente(HttpStatus.GATEWAY_TIMEOUT, "IA_TIEMPO");
        }
        return extraerTexto(respuesta);
    }

    static String extraerTexto(Map<?, ?> respuesta) {
        if (respuesta == null || !(respuesta.get("candidates") instanceof List<?> candidatos)
                || candidatos.isEmpty() || !(candidatos.get(0) instanceof Map<?, ?> candidato)) {
            throw new FalloAsistente(HttpStatus.BAD_GATEWAY, "IA_SIN_RESPUESTA");
        }
        StringBuilder texto = new StringBuilder();
        if (candidato.get("content") instanceof Map<?, ?> contenido
                && contenido.get("parts") instanceof List<?> partes) {
            for (Object parte : partes) {
                // Las partes "thought" son el razonamiento interno: no se muestran
                if (parte instanceof Map<?, ?> campo && !Boolean.TRUE.equals(campo.get("thought"))
                        && campo.get("text") instanceof String valor && !valor.isBlank()) {
                    if (!texto.isEmpty()) texto.append("\n");
                    texto.append(valor);
                }
            }
        }
        if (texto.isEmpty()) throw new FalloAsistente(HttpStatus.BAD_GATEWAY, "IA_SIN_RESPUESTA");
        String resultado = texto.toString().strip();
        if (resultado.length() > 1600) resultado = resultado.substring(0, 1599) + "…";
        if ("MAX_TOKENS".equals(candidato.get("finishReason"))) {
            log.info("La respuesta IA alcanzo el limite de salida; se devuelve solo el texto disponible.");
        }
        return resultado;
    }

    private static RestClient crearCliente() {
        HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build();
        JdkClientHttpRequestFactory fabrica = new JdkClientHttpRequestFactory(http);
        fabrica.setReadTimeout(Duration.ofSeconds(45));
        return RestClient.builder().baseUrl("https://generativelanguage.googleapis.com")
                .requestFactory(fabrica).build();
    }
}
