package com.inversioneslr.marketplace.dto;

import com.inversioneslr.marketplace.model.Notificacion;

import java.time.LocalDateTime;

public record NotificacionResponse(
        Long id,
        String tipo,
        String titulo,
        String mensaje,
        String entidad,
        Long entidadId,
        boolean leida,
        LocalDateTime creadaEn
) {

    public static NotificacionResponse desde(
            Notificacion notificacion) {

        return new NotificacionResponse(
                notificacion.getIdNotificacion(),
                notificacion.getTipo(),
                notificacion.getTitulo(),
                notificacion.getMensaje(),
                notificacion.getEntidad(),
                notificacion.getEntidadId(),
                notificacion.isLeida(),
                notificacion.getCreadaEn()
        );
    }
}