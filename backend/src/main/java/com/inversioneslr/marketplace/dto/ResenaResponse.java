package com.inversioneslr.marketplace.dto;

import java.time.LocalDateTime;

public record ResenaResponse(
        Long idResena,
        String nombreHuesped,
        Integer calificacion,
        String comentario,
        LocalDateTime fecha
) {
}
