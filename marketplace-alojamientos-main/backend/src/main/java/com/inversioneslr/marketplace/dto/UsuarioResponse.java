package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.EstadoUsuario;

public record UsuarioResponse(
        Long idUsuario,
        String nombre,
        String apellido,
        String correo,
        String telefono,
        EstadoUsuario estado
) {
}