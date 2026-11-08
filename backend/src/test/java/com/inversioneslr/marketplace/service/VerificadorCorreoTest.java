package com.inversioneslr.marketplace.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

// HU-03: solo se aceptan correos con formato real (prueba unitaria, sin internet)
class VerificadorCorreoTest {

    @Test
    @DisplayName("Acepta correos con formato real")
    void formatosValidos() {
        assertThat(VerificadorCorreo.formatoValido("sofia.lopez@gmail.com")).isTrue();
        assertThat(VerificadorCorreo.formatoValido("slopezcar@unbosque.edu.co")).isTrue();
    }

    @Test
    @DisplayName("Rechaza correos sin extensión, con espacios o con puntos seguidos")
    void formatosInvalidos() {
        assertThat(VerificadorCorreo.formatoValido("ana@correo")).isFalse();
        assertThat(VerificadorCorreo.formatoValido("ana correo@gmail.com")).isFalse();
        assertThat(VerificadorCorreo.formatoValido("ana..lopez@gmail.com")).isFalse();
        assertThat(VerificadorCorreo.formatoValido("@gmail.com")).isFalse();
    }

    @Test
    @DisplayName("Si la revisión del dominio está apagada, deja pasar")
    void revisionApagada() {
        assertThat(new VerificadorCorreo(false).dominioRecibeCorreos("ana@dominio-que-no-existe.xyz")).isTrue();
    }

    @Test
    @DisplayName("Rechaza dominios que no reciben correos y recuerda la respuesta")
    void dominioSinCorreos() {
        java.util.concurrent.atomic.AtomicInteger consultas = new java.util.concurrent.atomic.AtomicInteger();
        VerificadorCorreo verificador = new VerificadorCorreo(true, dominio -> {
            consultas.incrementAndGet();
            return dominio.equals("gmail.com");
        });
        assertThat(verificador.dominioRecibeCorreos("ana@gmail.com")).isTrue();
        assertThat(verificador.dominioRecibeCorreos("ana@inventado.xyz")).isFalse();
        assertThat(verificador.dominioRecibeCorreos("otra@gmail.com")).isTrue();
        assertThat(consultas.get()).isEqualTo(2);
    }

    @Test
    @DisplayName("La consulta al DNS responde sin lanzar errores")
    void consultaDns() {
        // Con o sin internet debe responder true o false, nunca fallar
        assertThat(VerificadorCorreo.consultarDns("dominio-que-no-existe.invalid")).isNotNull();
    }

    @Test
    @DisplayName("Rechaza correos con dos @ o demasiado largos")
    void otrosFormatos() {
        assertThat(VerificadorCorreo.formatoValido("ana@@gmail.com")).isFalse();
        assertThat(VerificadorCorreo.formatoValido("ana@gmail.c0m")).isFalse();
        assertThat(VerificadorCorreo.formatoValido(null)).isFalse();
        assertThat(VerificadorCorreo.formatoValido("a".repeat(200) + "@gmail.com")).isFalse();
    }
}
