package com.inversioneslr.marketplace.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;

public record PreguntaAsistenteRequest(
        @NotBlank @Size(max = 800) String pregunta,
        @NotNull @Pattern(regexp = "es|en") String idioma,
        @Size(max = 4) List<@NotNull @Valid Mensaje> historial
) {
    public record Mensaje(
            @NotNull @Pattern(regexp = "user|assistant") String rol,
            @NotBlank @Size(max = 1600) String texto
    ) {}
}
