package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.ImagenAlojamiento;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ImagenAlojamientoRepository
        extends JpaRepository<ImagenAlojamiento, Long> {

    // La primera de la lista (orden 0) es la principal
    List<ImagenAlojamiento> findByAlojamiento_IdAlojamientoOrderByOrdenImagenAscIdImagenAsc(
            Long idAlojamiento
    );

    long countByAlojamiento_IdAlojamiento(Long idAlojamiento);

    // Imágenes de varios alojamientos en una sola consulta (búsqueda)
    List<ImagenAlojamiento> findByAlojamiento_IdAlojamientoInOrderByOrdenImagenAscIdImagenAsc(
            java.util.Collection<Long> idsAlojamientos
    );
}
