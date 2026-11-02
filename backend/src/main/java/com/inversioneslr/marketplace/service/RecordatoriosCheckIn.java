package com.inversioneslr.marketplace.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

// Revisa cada hora (y un minuto después de arrancar) si hay reservas que
// llegan mañana, y les envía el recordatorio de check-in.
@Component
public class RecordatoriosCheckIn {

    private static final Logger log = LoggerFactory.getLogger(RecordatoriosCheckIn.class);

    private final ReservaService reservaService;

    public RecordatoriosCheckIn(ReservaService reservaService) {
        this.reservaService = reservaService;
    }

    @Scheduled(initialDelay = 60_000, fixedDelay = 3_600_000)
    public void enviar() {

        int enviados = reservaService.enviarRecordatoriosCheckIn();

        if (enviados > 0) {
            log.info("Recordatorios de check-in enviados: {}", enviados);
        }
    }
}
