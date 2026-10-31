package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Alojamiento;
import com.inversioneslr.marketplace.model.EstadoPublicacion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AlojamientoRepository extends JpaRepository<Alojamiento, Long> {

    List<Alojamiento> findByEstado(EstadoPublicacion estado);
    List<Alojamiento> findByAnfitrion_IdUsuario(Long idAnfitrion);
    List<Alojamiento> findByCiudadIgnoreCaseAndEstado(
            String ciudad,
            EstadoPublicacion estado
    );

}
