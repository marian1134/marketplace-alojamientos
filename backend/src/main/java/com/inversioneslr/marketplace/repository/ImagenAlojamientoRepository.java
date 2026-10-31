package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.ImagenAlojamiento;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ImagenAlojamientoRepository
        extends JpaRepository<ImagenAlojamiento, Long> {

    List<ImagenAlojamiento>
            findByAlojamiento_IdAlojamientoOrderByPrincipalDescOrdenImagenAsc(
                    Long idAlojamiento
            );

    long countByAlojamiento_IdAlojamiento(Long idAlojamiento);

    boolean existsByAlojamiento_IdAlojamientoAndPrincipalTrue(
            Long idAlojamiento
    );
}