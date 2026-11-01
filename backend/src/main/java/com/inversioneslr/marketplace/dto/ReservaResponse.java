package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.EstadoReserva;
import com.inversioneslr.marketplace.model.TipoAlojamiento;
import com.inversioneslr.marketplace.model.TipoPolitica;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record ReservaResponse(
        Long idReserva,
        String codigo,
        EstadoReserva estado,
        LocalDate fechaLlegada,
        LocalDate fechaSalida,
        long noches,
        Integer cantidadHuespedes,

        Long idAlojamiento,
        String tituloAlojamiento,
        String ciudad,
        TipoAlojamiento tipoAlojamiento,
        String imagenPortada,
        TipoPolitica tipoPolitica,

        String nombreHuesped,
        String nombreAnfitrion,

        BigDecimal precioNoche,
        BigDecimal subtotal,
        BigDecimal tarifaLimpieza,
        BigDecimal tarifaServicio,
        BigDecimal descuentos,
        BigDecimal total,
        String moneda,
        String ultimos4,

        BigDecimal valorDevolucion,
        String motivo,
        boolean puedeCancelar,
        LocalDateTime creadaEn
) {
}
