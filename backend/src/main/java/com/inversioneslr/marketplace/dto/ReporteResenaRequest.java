package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ReporteResenaRequest(
        @NotBlank(message = "Escribe el motivo del reporte")
        @Size(max = 500, message = "El motivo no puede superar 500 caracteres")
        String motivo
) {
}
