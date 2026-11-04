package com.inversioneslr.marketplace.dto;
import jakarta.validation.constraints.*;
public record AdminReporteRequest(
        @NotBlank @Pattern(regexp = "OCULTAR|DESCARTAR") String decision,
        @NotBlank @Size(min = 10, max = 500) String motivo,
        @NotNull Boolean visibleActual
) {}
