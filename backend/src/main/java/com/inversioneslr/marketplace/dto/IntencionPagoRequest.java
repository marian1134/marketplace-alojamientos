package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

// Datos para iniciar el pago con Stripe antes de crear la reserva
public record IntencionPagoRequest(
        @NotNull Long idAlojamiento,
        @NotNull LocalDate fechaLlegada,
        @NotNull LocalDate fechaSalida,
        @NotNull @Positive Integer cantidadHuespedes,
        @Pattern(regexp = "COP|USD") String moneda,
        @NotBlank @Size(min = 36, max = 36) String claveIdempotencia
) {
}
