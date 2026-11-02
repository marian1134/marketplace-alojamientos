package com.inversioneslr.marketplace.dto;

import java.math.BigDecimal;
import java.util.List;

// Lo que el navegador necesita saber para mostrar el pago
public record ConfiguracionPagoResponse(
        boolean stripeActivo,
        String clavePublica,
        BigDecimal tasaUsd,
        List<String> monedas
) {
}
