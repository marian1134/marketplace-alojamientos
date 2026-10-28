package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

import com.inversioneslr.marketplace.model.TipoAlojamiento;


public record AlojamientoRequest( 

     @NotNull
        @Positive
        Long idAnfitrion,

        @NotBlank
        @Size(max = 150)
        String titulo,

        @NotBlank
        @Size(max = 2000)
        String descripcion,

        @NotBlank
        @Size(max = 150)
        String ciudad,

        @NotBlank
        @Size(max = 150)
        String direccion,

        @NotNull
        TipoAlojamiento tipoAlojamiento,

        @NotNull
        @Positive
        Integer capacidad,

        @NotNull
        @DecimalMin(value = "0.01")
        BigDecimal precioNoche

) {}


