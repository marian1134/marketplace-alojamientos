package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

// Datos para crear la reserva y pagarla (pago de prueba) en un solo paso
public record ReservaRequest(
        @NotNull Long idAlojamiento,
        @NotNull LocalDate fechaLlegada,
        @NotNull LocalDate fechaSalida,
        @NotNull @Positive Integer cantidadHuespedes,

        // Evita crear dos reservas si el huésped da doble clic
        @NotBlank @Size(min = 36, max = 36) String claveIdempotencia,

        @NotBlank @Size(max = 23) String numeroTarjeta,
        @NotBlank @Size(max = 100) String titular,
        @NotBlank @Size(max = 5) String expiracion,
        @NotBlank @Size(min = 3, max = 3) String cvc
) {
}
