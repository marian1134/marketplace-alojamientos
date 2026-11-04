package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.MensajeReserva;
import java.time.LocalDateTime;

public record MensajeReservaResponse(
        Long id, String remitente, boolean propio,
        String contenido, LocalDateTime creadaEn
) {
    public static MensajeReservaResponse desde(MensajeReserva mensaje, Long idUsuario) {
        return new MensajeReservaResponse(
                mensaje.getIdMensaje(), mensaje.getRemitente().getNombre(),
                idUsuario.equals(mensaje.getRemitente().getIdUsuario()),
                mensaje.getContenido(), mensaje.getCreadaEn());
    }
}
