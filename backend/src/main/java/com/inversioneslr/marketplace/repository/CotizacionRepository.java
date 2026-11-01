package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Cotizacion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CotizacionRepository extends JpaRepository<Cotizacion, Long> {

    Optional<Cotizacion> findByReserva_IdReserva(Long idReserva);
}
