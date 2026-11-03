package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.ConfiguracionTarifas;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ConfiguracionTarifasRepository
        extends JpaRepository<ConfiguracionTarifas, Long> {

    Optional<ConfiguracionTarifas> findFirstByVigenteTrue();
}
