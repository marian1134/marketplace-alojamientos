package com.inversioneslr.marketplace.dto;

public record EstadoReporteResenaResponse(
        boolean reportada,
        boolean puedeReportar,
        String mensaje
) {
}
