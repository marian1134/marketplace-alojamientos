package com.inversioneslr.marketplace.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Set;

// Monedas en que se puede pagar: pesos colombianos y dólares.
// Los precios se guardan en COP y se convierten con app.tasa-usd.
@Service
public class MonedaService {

    public static final String COP = "COP";
    public static final String USD = "USD";
    private static final Set<String> MONEDAS = Set.of(COP, USD);

    private final BigDecimal tasaUsd;

    public MonedaService(@Value("${app.tasa-usd:4000}") BigDecimal tasaUsd) {
        this.tasaUsd = tasaUsd;
    }

    public BigDecimal getTasaUsd() {
        return tasaUsd;
    }

    public String validar(String moneda) {

        String valor = moneda == null || moneda.isBlank()
                ? COP
                : moneda.trim().toUpperCase();

        if (!MONEDAS.contains(valor)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La moneda debe ser COP o USD"
            );
        }

        return valor;
    }

    // Valor en COP -> valor en la moneda elegida (USD con 2 decimales)
    public BigDecimal convertir(BigDecimal valorCop, String moneda) {

        if (USD.equals(moneda)) {
            return valorCop.divide(tasaUsd, 2, RoundingMode.HALF_UP);
        }

        return valorCop.setScale(0, RoundingMode.HALF_UP);
    }

    // Decimales con que se redondea cada moneda
    public int decimales(String moneda) {
        return USD.equals(moneda) ? 2 : 0;
    }

    // Stripe recibe los montos en centavos (COP y USD tienen 2 decimales)
    public long enCentavos(BigDecimal valor) {
        return valor.multiply(BigDecimal.valueOf(100))
                .setScale(0, RoundingMode.HALF_UP)
                .longValueExact();
    }
}
