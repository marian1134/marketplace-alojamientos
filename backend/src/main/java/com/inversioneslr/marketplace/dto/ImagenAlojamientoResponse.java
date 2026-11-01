package com.inversioneslr.marketplace.dto;

public record ImagenAlojamientoResponse(
        Long idImagen,
        Long idAlojamiento,
        String urlImagen,
        boolean principal,
        Integer ordenImagen
) {
}
