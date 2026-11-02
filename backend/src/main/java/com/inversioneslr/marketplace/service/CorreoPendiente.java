package com.inversioneslr.marketplace.service;

// Un correo listo para enviar. Se envía solo si la operación
// (reserva, cancelación, etc.) quedó guardada en la base.
// idCorreo es la fila de correo_enviado donde se anota el resultado.
public record CorreoPendiente(
        Long idCorreo,
        String destinatario,
        String asunto,
        String texto) {
}
