package com.inversioneslr.marketplace.dto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
public record AdminEstadoRequest(
        @NotBlank @Size(max = 25) String estado,
        @NotBlank @Size(min = 10, max = 500) String motivo,
        @NotBlank @Size(max = 25) String estadoActual
) {}
