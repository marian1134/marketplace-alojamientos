package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.EstadoReserva;
import com.inversioneslr.marketplace.model.Reserva;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ReservaRepository extends JpaRepository<Reserva, Long> {

    List<Reserva> findByHuesped_IdUsuarioOrderByCreadaEnDesc(Long idHuesped);

    List<Reserva> findByAlojamiento_Anfitrion_IdUsuarioOrderByCreadaEnDesc(
            Long idAnfitrion
    );

    Optional<Reserva> findByClaveIdempotencia(String claveIdempotencia);

    boolean existsByCodigo(String codigo);

    // Reservas que llegan en cierta fecha y aún no tienen recordatorio
    List<Reserva> findByEstadoAndFechaLlegadaAndRecordatorioEnviadoFalse(
            EstadoReserva estado,
            LocalDate fechaLlegada
    );
}
