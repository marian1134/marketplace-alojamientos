package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Cancelacion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CancelacionRepository extends JpaRepository<Cancelacion, Long> {

    Optional<Cancelacion> findByReserva_IdReserva(Long idReserva);
}
