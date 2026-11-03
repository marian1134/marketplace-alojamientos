package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.PoliticaCancelacion;
import com.inversioneslr.marketplace.model.TipoPolitica;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PoliticaCancelacionRepository
        extends JpaRepository<PoliticaCancelacion, Long> {

    Optional<PoliticaCancelacion> findByTipo(TipoPolitica tipo);
}
