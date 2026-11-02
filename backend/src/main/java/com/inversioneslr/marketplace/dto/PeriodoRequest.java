package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record PeriodoRequest(
        @NotNull LocalDate fechaInicio,
        @NotNull LocalDate fechaFin
) {
}
