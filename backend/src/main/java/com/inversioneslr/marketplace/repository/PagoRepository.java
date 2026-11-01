package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Pago;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PagoRepository extends JpaRepository<Pago, Long> {

    Optional<Pago> findByReserva_IdReserva(Long idReserva);
}
