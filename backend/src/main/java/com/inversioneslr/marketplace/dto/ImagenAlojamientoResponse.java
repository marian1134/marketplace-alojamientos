package com.inversioneslr.marketplace.dto;

import java.time.LocalDateTime;

public record ImagenAlojamientoResponse(
        Long idImagen,
        Long idAlojamiento,
        String urlImagen,
        String nombreOriginal,
        String tipoContenido,
        boolean principal,
        Integer ordenImagen,
        LocalDateTime fechaCreacion
) {
}