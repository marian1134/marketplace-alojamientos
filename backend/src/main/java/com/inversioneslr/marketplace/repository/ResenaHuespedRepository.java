package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.ResenaHuesped;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface ResenaHuespedRepository extends JpaRepository<ResenaHuesped, Long> {
    boolean existsByReserva_IdReserva(Long idReserva);

    @Query("""
            SELECT rh FROM ResenaHuesped rh
            JOIN FETCH rh.reserva r
            JOIN FETCH r.alojamiento a
            JOIN FETCH a.anfitrion anfitrion
            JOIN FETCH r.huesped huesped
            WHERE LOWER(anfitrion.correo) = LOWER(:correo)
            ORDER BY rh.fecha DESC, rh.id DESC
            """)
    List<ResenaHuesped> buscarDelAnfitrion(@Param("correo") String correo);
}
