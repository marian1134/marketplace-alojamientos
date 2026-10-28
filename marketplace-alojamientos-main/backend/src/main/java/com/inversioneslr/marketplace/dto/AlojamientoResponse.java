package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.EstadoPublicacion;
import com.inversioneslr.marketplace.model.TipoAlojamiento;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record AlojamientoReponse( 

    Long idAlojamiento,
    Long idAnfitrion,
    String titulo,
    String descripcion,
    String ciudad,
    String direccion,
    TipoAlojamiento tipoAlojamiento,
    Integer capacidad,
    BigDecimal precioNoche,
    EstadoPublicacion estado,
    LocalDateTime fechaCreacion,
    LocalDateTime fechaActualizacion



){}
