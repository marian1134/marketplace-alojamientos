package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record DatosNuevaClave(

        @NotBlank(message = "El código es obligatorio")
        @Pattern(
                regexp = "[A-Za-z0-9_-]{43}",
                message = "El código de recuperación no es válido"
        )
        String token,

        @NotBlank(message = "La contraseña es obligatoria")
        @Size(
                min = 8,
                max = 72,
                message = "La contraseña debe tener entre 8 y 72 caracteres"
        )
        String contrasena

) {
}