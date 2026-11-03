package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.Rol;
import com.inversioneslr.marketplace.model.Usuario;

public record UsuarioResponse(
        Long idUsuario,
        String nombre,
        String correo,
        String telefono,
        String fotoUrl,
        Rol rol,
        EstadoUsuario estado
) {

    public static UsuarioResponse desde(Usuario usuario) {
        return new UsuarioResponse(
                usuario.getIdUsuario(),
                usuario.getNombre(),
                usuario.getCorreo(),
                usuario.getTelefono(),
                usuario.getFotoUrl(),
                usuario.getRol(),
                usuario.getEstado()
        );
    }
}
