package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Reserva;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface ChatReservaRepository extends Repository<Reserva, Long> {
    @Query("SELECT r FROM Reserva r JOIN FETCH r.huesped JOIN FETCH r.alojamiento a JOIN FETCH a.anfitrion WHERE r.idReserva = :id")
    Optional<Reserva> buscar(@Param("id") Long id);

    // Serializa envíos de una reserva para que reintentar no duplique mensajes.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM Reserva r WHERE r.idReserva = :id")
    Optional<Reserva> bloquear(@Param("id") Long id);
}
