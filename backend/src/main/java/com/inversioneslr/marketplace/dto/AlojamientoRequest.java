package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.ModoReserva;
import com.inversioneslr.marketplace.model.TipoAlojamiento;
import com.inversioneslr.marketplace.model.TipoPolitica;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record AlojamientoRequest(

        @NotBlank
        @Size(max = 120)
        String titulo,

        @NotBlank
        @Size(max = 5000)
        String descripcion,

        @NotBlank
        @Size(max = 80)
        String ciudad,

        // Columna ubicacion_descripcion
        @NotBlank
        @Size(max = 200)
        String direccion,

        @NotNull
        TipoAlojamiento tipoAlojamiento,

        @NotNull
        @Positive
        @Max(1000)
        Integer capacidad,

        @NotNull
        @DecimalMin(value = "0.01")
        BigDecimal precioNoche,

        // Opcionales: si no llegan se usa 0, INMEDIATA y MODERADA
        @DecimalMin(value = "0.00")
        BigDecimal tarifaLimpieza,

        ModoReserva modoReserva,

        TipoPolitica tipoPolitica,

        // Opcionales: si no llegan se usa 1
        @Min(1) @Max(50)
        Integer habitaciones,

        @Min(1) @Max(50)
        Integer banos
) {
}
