package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

// Datos para crear la reserva y pagarla en un solo paso.
// Con Stripe llega idIntencionPago (el pago ya hecho en el navegador);
// sin Stripe llegan los datos de la tarjeta para el pago simulado.
public record ReservaRequest(
        @NotNull Long idAlojamiento,
        @NotNull LocalDate fechaLlegada,
        @NotNull LocalDate fechaSalida,
        @NotNull @Positive Integer cantidadHuespedes,

        // Evita crear dos reservas si el huésped da doble clic
        @NotBlank @Size(min = 36, max = 36) String claveIdempotencia,

        @Size(max = 23) String numeroTarjeta,
        @Size(max = 100) String titular,
        @Size(max = 5) String expiracion,
        @Size(max = 3) String cvc,

        // COP (pesos colombianos) o USD (dólares). Si no llega: COP
        @Pattern(regexp = "COP|USD") String moneda,

        // Id de la intención de pago de Stripe (pi_...)
        @Size(max = 100) String idIntencionPago
) {
}
