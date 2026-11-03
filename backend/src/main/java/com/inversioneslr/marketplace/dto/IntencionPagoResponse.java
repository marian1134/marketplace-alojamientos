package com.inversioneslr.marketplace.dto;

import java.math.BigDecimal;

public record IntencionPagoResponse(
        String idIntencion,
        String clientSecret,
        BigDecimal monto,
        String moneda
) {
}
