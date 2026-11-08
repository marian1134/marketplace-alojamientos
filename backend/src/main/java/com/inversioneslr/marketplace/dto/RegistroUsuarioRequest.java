package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegistroUsuarioRequest(

        // Nombre de 3 a 60 caracteres: solo letras, espacios, punto, apóstrofo y guion
        @NotBlank(message = "El nombre completo es obligatorio")
        @Size(min = 3, max = 60, message = "El nombre debe tener entre 3 y 60 caracteres")
        @Pattern(regexp = "^[\\p{L}][\\p{L} .'-]*$", message = "El nombre solo puede tener letras y espacios")
        String nombre,

        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no tiene un formato válido")
        @Size(max = 100, message = "El correo no puede superar 100 caracteres")
        String correo,

        @NotBlank(message = "La contraseña es obligatoria")
        @Size(
                min = 8,
                max = 30,
                message = "La contraseña debe tener entre 8 y 30 caracteres"
        )
        @Pattern(
                regexp = "^(?=.*\\p{L})(?=.*\\d)(?=.*[^\\p{L}\\d\\s]).+$",
                message = "La contraseña debe tener al menos una letra, un número y un símbolo"
        )
        String contrasena,

        // Celular de Colombia con prefijo: +57 y 10 dígitos que empiezan por 3
        @NotBlank(message = "El celular es obligatorio")
        @Pattern(
                regexp = "^\\+573[0-9]{9}$",
                message = "El celular debe tener 10 dígitos y empezar por 3"
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
