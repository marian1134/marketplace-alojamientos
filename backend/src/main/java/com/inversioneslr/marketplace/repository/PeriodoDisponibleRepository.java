package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.PeriodoDisponible;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface PeriodoDisponibleRepository
        extends JpaRepository<PeriodoDisponible, Long> {

    List<PeriodoDisponible> findByIdAlojamientoOrderByFechaInicio(Long idAlojamiento);

    List<PeriodoDisponible> findByIdAlojamientoIn(Collection<Long> idsAlojamientos);
}
