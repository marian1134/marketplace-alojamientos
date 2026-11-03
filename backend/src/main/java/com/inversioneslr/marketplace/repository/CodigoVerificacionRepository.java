package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.CodigoVerificacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface CodigoVerificacionRepository extends JpaRepository<CodigoVerificacion, Long> {

    // El último código sin usar del usuario
    Optional<CodigoVerificacion> findFirstByUsuario_IdUsuarioAndUsadoFalseOrderByIdCodigoDesc(
            Long idUsuario
    );

    // Al pedir un código nuevo, los anteriores dejan de servir
    @Modifying
    @Query("UPDATE CodigoVerificacion c SET c.usado = true "
            + "WHERE c.usuario.idUsuario = :idUsuario AND c.usado = false")
    void anularPendientes(@Param("idUsuario") Long idUsuario);
}
