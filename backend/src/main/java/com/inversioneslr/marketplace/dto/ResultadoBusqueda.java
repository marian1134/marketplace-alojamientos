package com.inversioneslr.marketplace.dto;

import java.math.BigDecimal;

// Un alojamiento disponible en la búsqueda, con su foto y precio estimado
public record ResultadoBusqueda(
        AlojamientoResponse alojamiento,
        String imagenPortada,
        long noches,
        BigDecimal totalEstimado
) {
}
