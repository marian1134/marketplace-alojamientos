package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Reserva;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

// Serializa las calificaciones sobre una misma reserva para evitar duplicados.
public interface ReservaParaResenaRepository extends Repository<Reserva, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM Reserva r WHERE r.idReserva = :id")
    Optional<Reserva> buscarBloqueada(@Param("id") Long id);
}
