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
import java.util.List;
import java.util.Map;

@Component
public class ClienteAsistente {
    private static final Logger log = LoggerFactory.getLogger(ClienteAsistente.class);
    private final String clave;
    private final RestClient cliente;

    @Autowired
    public ClienteAsistente(@Value("${OPENAI_API_KEY:}") String clave) {
        this(clave, crearCliente());
    }

    ClienteAsistente(String clave, RestClient cliente) {
        this.clave = clave == null ? "" : clave.strip();
        this.cliente = cliente;
    }

    public boolean configurado() { return !clave.isBlank(); }

    public String responder(String instrucciones, List<Map<String, String>> mensajes) {
        if (!configurado()) throw new FalloAsistente(HttpStatus.SERVICE_UNAVAILABLE, "IA_NO_CONFIGURADA");
        Map<String, Object> cuerpo = Map.of(
                "model", "gpt-5-mini",
                "instructions", instrucciones,
                "input", mensajes,
                "store", false,
                "max_output_tokens", 768,
                "reasoning", Map.of("effort", "minimal"),
                "text", Map.of("verbosity", "low")
        );
        Map<?, ?> respuesta;
        try {
            // Sin reintentos automaticos: un timeout no demuestra que no se haya cobrado.
            respuesta = cliente.post().uri("/v1/responses")
                    .headers(cabeceras -> cabeceras.setBearerAuth(clave))
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(cuerpo).retrieve().body(Map.class);
        } catch (RestClientResponseException error) {
            int estado = error.getStatusCode().value();
            log.warn("Consulta IA rechazada por OpenAI HTTP={}", estado);
            String codigo = estado == 429 ? "IA_CUOTA_PROVEEDOR"
                    : estado == 401 || estado == 403 ? "IA_CONFIGURACION" : "IA_PROVEEDOR";
            throw new FalloAsistente(HttpStatus.SERVICE_UNAVAILABLE, codigo);
       } catch (RuntimeException error) {
    Throwable causa = error;

    for (int i = 0; i < 10 && causa.getCause() != null; i++) {
        causa = causa.getCause();
    }

    log.warn(
            "Consulta IA fallida: tipo={}, causa={}",
            error.getClass().getSimpleName(),
            causa.getClass().getSimpleName()
    );

    throw new FalloAsistente(
            HttpStatus.GATEWAY_TIMEOUT,
            "IA_TIEMPO"
    );
}
        return extraerTexto(respuesta);
    }

    static String extraerTexto(Map<?, ?> respuesta) {
        if (respuesta == null || !(respuesta.get("status") instanceof String estado)
                || !("completed".equals(estado) || "incomplete".equals(estado))) {
            throw new FalloAsistente(HttpStatus.BAD_GATEWAY, "IA_SIN_RESPUESTA");
        }
        StringBuilder texto = new StringBuilder();
        if (respuesta.get("output") instanceof List<?> salida) {
            for (Object objeto : salida) {
                if (!(objeto instanceof Map<?, ?> mensaje) || !"message".equals(mensaje.get("type"))
                        || !"assistant".equals(mensaje.get("role"))
                        || !(mensaje.get("content") instanceof List<?> contenido)) continue;
                for (Object parte : contenido) {
                    if (parte instanceof Map<?, ?> campo && "output_text".equals(campo.get("type"))
                            && campo.get("text") instanceof String valor && !valor.isBlank()) {
                        if (!texto.isEmpty()) texto.append("\n");
                        texto.append(valor);
                    }
                }
            }
        }
        if (texto.isEmpty()) throw new FalloAsistente(HttpStatus.BAD_GATEWAY, "IA_SIN_RESPUESTA");
        String resultado = texto.toString().strip();
        if (resultado.length() > 1600) resultado = resultado.substring(0, 1599) + "…";
        if ("incomplete".equals(respuesta.get("status"))) {
            // No completar con una segunda llamada: el limite incluye razonamiento y texto visible.
            log.info("La respuesta IA alcanzo el limite de salida; se devuelve solo el texto disponible.");
        }
        return resultado;
    }

    private static RestClient crearCliente() {
        HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build();
        JdkClientHttpRequestFactory fabrica = new JdkClientHttpRequestFactory(http);
        fabrica.setReadTimeout(Duration.ofSeconds(45));
        return RestClient.builder().baseUrl("https://api.openai.com").requestFactory(fabrica).build();
    }
}
