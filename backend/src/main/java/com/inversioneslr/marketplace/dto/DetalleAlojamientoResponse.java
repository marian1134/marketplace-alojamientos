package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.TipoPolitica;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

// Todo lo que muestra la pantalla de detalle del alojamiento
public record DetalleAlojamientoResponse(
        AlojamientoResponse alojamiento,
        List<ImagenAlojamientoResponse> imagenes,
        String nombreAnfitrion,
        Integer anfitrionDesde,
        List<LocalDate> nochesOcupadas,
        BigDecimal porcentajeServicio,
        Politica politica,
        Double promedioCalificacion,
        long cantidadResenas,
        List<Long> distribucionEstrellas,
        List<ResenaResponse> resenas,
        List<CalendarioResponse.Periodo> periodosDisponibles,
        boolean esFavorito
) {

    public record Politica(
            TipoPolitica tipo,
            Integer diasAnticipacion,
            BigDecimal porcentajeAntes,
            BigDecimal porcentajeDespues
    ) {
    }
}
