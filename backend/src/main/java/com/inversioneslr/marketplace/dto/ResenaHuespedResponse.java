package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.ResenaHuesped;
import java.time.LocalDateTime;

public record ResenaHuespedResponse(
        Long id,
        Long idReserva,
        Integer calificacion,
        String comentario,
        LocalDateTime fecha) {
    public static ResenaHuespedResponse desde(ResenaHuesped resena) {
        return new ResenaHuespedResponse(
                resena.getId(), resena.getReserva().getIdReserva(),
                resena.getCalificacion(), resena.getComentario(), resena.getFecha());
    }
}
