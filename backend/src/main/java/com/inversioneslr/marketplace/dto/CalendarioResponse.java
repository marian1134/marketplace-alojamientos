package com.inversioneslr.marketplace.dto;

import java.time.LocalDate;
import java.util.List;

// Calendario del anfitrión: periodos en que recibe huéspedes y noches reservadas
public record CalendarioResponse(
        Long idAlojamiento,
        String titulo,
        List<Periodo> periodos,
        List<Noche> nochesReservadas
) {

    public record Periodo(Long idPeriodo, LocalDate fechaInicio, LocalDate fechaFin) {
    }

    public record Noche(LocalDate fecha, String codigoReserva, String nombreHuesped) {
    }
}
