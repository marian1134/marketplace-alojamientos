package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegistroUsuarioRequest(

        @NotBlank(message = "El nombre completo es obligatorio")
        @Size(max = 100, message = "El nombre no puede superar 100 caracteres")
        String nombre,

        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no tiene un formato válido")
        @Size(max = 150, message = "El correo no puede superar 150 caracteres")
        String correo,

        @NotBlank(message = "La contraseña es obligatoria")
        @Size(
                min = 8,
                max = 72,
                message = "La contraseña debe tener entre 8 y 72 caracteres"
        )
        @Pattern(
                regexp = "^(?=.*\\p{L})(?=.*\\d)(?=.*[^\\p{L}\\d\\s]).+$",
                message = "La contraseña debe tener al menos una letra, un número y un símbolo"
        )
        String contrasena,

        // Opcional
        // Celular de Colombia: +57 y 10 dígitos que empiezan por 3
        @Pattern(
                regexp = "^$|^\\+573[0-9]{9}$",
                message = "El celular debe tener 10 dígitos y empezar por 3 (ej.: +57 3001234567)"
        )
        String telefono,

        @NotBlank(message = "Debes elegir un tipo de cuenta")
        @Pattern(
                regexp = "HUESPED|ANFITRION",
                message = "El tipo de cuenta debe ser Huésped o Anfitrión"
        )
        String rol
) {
}
