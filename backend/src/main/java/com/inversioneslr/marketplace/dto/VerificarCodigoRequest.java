package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

// Segundo paso del inicio de sesión: el código que llegó al correo
public record VerificarCodigoRequest(

        @NotBlank
        @Email
        String correo,

        @NotBlank
        @Pattern(regexp = "^\\d{6}$", message = "El código tiene 6 números")
        String codigo

) {
}
