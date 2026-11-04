package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.model.EstadoPago;
import com.inversioneslr.marketplace.model.EstadoReserva;
import com.inversioneslr.marketplace.model.Pago;
import com.inversioneslr.marketplace.model.Reserva;
import com.inversioneslr.marketplace.repository.PagoRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class NormalizadorReservaInmediata {
    private final PagoRepository pagos;
    private final AvisosReserva avisos;
    private final EntityManager entidades;

    public NormalizadorReservaInmediata(PagoRepository pagos, AvisosReserva avisos, EntityManager entidades) {
        this.pagos = pagos;
        this.avisos = avisos;
        this.entidades = entidades;
    }

    // Se ejecuta dentro de la transacción que consulta o gestiona la reserva.
    @Transactional(propagation = Propagation.MANDATORY)
    public void confirmarSiPendiente(Reserva reserva) {
        if (reserva.getEstado() != EstadoReserva.PENDIENTE_APROBACION) return;

        // Recarga el estado DESPUÉS de obtener el bloqueo: evita avisos duplicados
        // y no sobrescribe una cancelación que se haya guardado mientras esperaba.
        entidades.refresh(reserva, LockModeType.PESSIMISTIC_WRITE);
        if (reserva.getEstado() != EstadoReserva.PENDIENTE_APROBACION) return;

        Pago pago = pagos.findByReserva_IdReserva(reserva.getIdReserva()).orElse(null);
        if (pago == null) return;
        entidades.refresh(pago);
        if (pago.getEstado() != EstadoPago.APROBADO
                || pago.getMonto() == null || pago.getMonto().signum() <= 0
                || (pago.getMontoReembolsado() != null && pago.getMontoReembolsado().signum() > 0)) return;

        long noches = ChronoUnit.DAYS.between(reserva.getFechaLlegada(), reserva.getFechaSalida());
        if (noches <= 0) return;
        List<?> ocupadas = entidades.createNativeQuery(
                        "SELECT fecha FROM noche_reservada WHERE reserva_id = ?1 AND publicacion_id = ?2 "
                                + "AND fecha >= ?3 AND fecha < ?4 FOR UPDATE")
                .setParameter(1, reserva.getIdReserva())
                .setParameter(2, reserva.getAlojamiento().getIdAlojamiento())
                .setParameter(3, java.sql.Date.valueOf(reserva.getFechaLlegada()))
                .setParameter(4, java.sql.Date.valueOf(reserva.getFechaSalida()))
                .getResultList();
        if (ocupadas.size() != noches) return;

        reserva.setEstado(EstadoReserva.CONFIRMADA);
        if (!reserva.getFechaLlegada().isAfter(LocalDate.now().plusDays(1))) {
            reserva.setRecordatorioEnviado(true);
        }
        avisos.reservaConfirmadaAutomaticamente(reserva);
    }
}
