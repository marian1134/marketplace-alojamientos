package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDate;

public record CotizacionRequest(
        @NotNull Long idAlojamiento,
        @NotNull LocalDate fechaLlegada,
        @NotNull LocalDate fechaSalida,
        @NotNull @Positive Integer cantidadHuespedes
) {
}
