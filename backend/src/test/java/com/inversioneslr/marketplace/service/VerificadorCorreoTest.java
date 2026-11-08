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
}
