package com.inversioneslr.marketplace.dto;

import java.util.List;

public record ConversacionReservaResponse(
        Long idReserva, String codigoReserva, String tituloAlojamiento,
        String interlocutor, List<MensajeReservaResponse> mensajes, boolean hayMas
) {}
