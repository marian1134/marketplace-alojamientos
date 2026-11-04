package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.MensajeReserva;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface MensajeReservaRepository extends JpaRepository<MensajeReserva, Long> {
    Optional<MensajeReserva> findByReserva_IdReservaAndRemitente_IdUsuarioAndClaveCliente(
            Long idReserva, Long idRemitente, String claveCliente);

    @Query("SELECT m FROM MensajeReserva m JOIN FETCH m.remitente WHERE m.reserva.idReserva = :reserva AND (:antes IS NULL OR m.idMensaje < :antes) ORDER BY m.idMensaje DESC")
    List<MensajeReserva> anteriores(@Param("reserva") Long reserva, @Param("antes") Long antes, Pageable pagina);

    @Query("SELECT m FROM MensajeReserva m JOIN FETCH m.remitente WHERE m.reserva.idReserva = :reserva AND m.idMensaje > :despues ORDER BY m.idMensaje ASC")
    List<MensajeReserva> nuevos(@Param("reserva") Long reserva, @Param("despues") Long despues, Pageable pagina);
}
