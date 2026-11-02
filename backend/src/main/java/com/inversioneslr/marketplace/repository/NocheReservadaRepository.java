package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.NocheReservada;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface NocheReservadaRepository
        extends JpaRepository<NocheReservada, NocheReservada.Llave> {

    // Noches ocupadas del alojamiento desde una fecha (para el calendario)
    List<NocheReservada> findByIdAlojamientoAndFechaGreaterThanEqualOrderByFecha(
            Long idAlojamiento,
            LocalDate desde
    );

    // ¿Alguna noche del rango [desde, hasta] ya está ocupada?
    boolean existsByIdAlojamientoAndFechaBetween(
            Long idAlojamiento,
            LocalDate desde,
            LocalDate hasta
    );

    // Alojamientos que tienen alguna noche ocupada en el rango (para la búsqueda)
    @Query("select distinct n.idAlojamiento from NocheReservada n "
            + "where n.fecha between :desde and :hasta")
    List<Long> alojamientosOcupados(
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta
    );

    @Modifying
    @Query("delete from NocheReservada n where n.reserva.idReserva = :idReserva")
    void liberarNoches(@Param("idReserva") Long idReserva);
}
