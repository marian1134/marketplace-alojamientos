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


    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("SELECT a FROM Alojamiento a WHERE a.idAlojamiento = :id")
    java.util.Optional<Alojamiento> bloquearPorId(@org.springframework.data.repository.query.Param("id") Long id);
}
