package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.EstadoPublicacion;
import com.inversioneslr.marketplace.model.ModoReserva;
import com.inversioneslr.marketplace.model.TipoAlojamiento;
import com.inversioneslr.marketplace.model.TipoPolitica;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record AlojamientoResponse(
        Long idAlojamiento,
        Long idAnfitrion,
        String titulo,
        String descripcion,
        String ciudad,
        String direccion,
        TipoAlojamiento tipoAlojamiento,
        Integer capacidad,
        BigDecimal precioNoche,
        BigDecimal tarifaLimpieza,
        ModoReserva modoReserva,
        TipoPolitica tipoPolitica,
        EstadoPublicacion estado,
        String motivoEstado,
        LocalDateTime fechaCreacion,
        LocalDateTime fechaActualizacion
) {
}
