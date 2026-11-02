package com.inversioneslr.marketplace.dto;

import java.math.BigDecimal;

// Desglose del precio que ve el huésped antes de pagar
public record CotizacionResponse(
        long noches,
        BigDecimal precioNoche,
        BigDecimal subtotal,
        BigDecimal tarifaLimpieza,
        BigDecimal porcentajeServicio,
        BigDecimal tarifaServicio,
        BigDecimal descuentos,
        BigDecimal total,
        String moneda
) {
}
