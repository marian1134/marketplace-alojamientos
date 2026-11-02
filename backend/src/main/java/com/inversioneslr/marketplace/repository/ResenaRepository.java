package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Resena;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface ResenaRepository extends JpaRepository<Resena, Long> {

    Optional<Resena> findByReserva_IdReserva(Long idReserva);

    boolean existsByReserva_IdReserva(Long idReserva);

    // Reseñas visibles de un alojamiento, las más recientes primero
    List<Resena> findByReserva_Alojamiento_IdAlojamientoAndVisibleTrueOrderByFechaDesc(
            Long idAlojamiento
    );

    // [idAlojamiento, promedio, cantidad] de varios alojamientos en una consulta
    @Query("select r.reserva.alojamiento.idAlojamiento, avg(r.calificacion), count(r) "
            + "from Resena r where r.visible = true "
            + "and r.reserva.alojamiento.idAlojamiento in :ids "
            + "group by r.reserva.alojamiento.idAlojamiento")
    List<Object[]> resumenPorAlojamiento(@Param("ids") Collection<Long> ids);
}
