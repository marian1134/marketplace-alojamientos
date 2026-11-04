package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.*;

public record CrearAdministradorRequest(
        @NotBlank @Size(min = 2, max = 100) String nombre,
        @NotBlank @Email @Size(max = 150) String correo,
        @NotBlank @Size(min = 8, max = 72)
        @Pattern(regexp = "^(?=.*\\p{L})(?=.*\\d)(?=.*[^\\p{L}\\d\\s]).+$",
                message = "La contraseña debe tener al menos una letra, un número y un símbolo")
        String contrasena
) {}
