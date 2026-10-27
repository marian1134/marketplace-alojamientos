package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.UsuarioRol;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UsuarioRolRepository
        extends JpaRepository<UsuarioRol, Long> {

    @EntityGraph(attributePaths = "rol")
    List<UsuarioRol> findByUsuario_IdUsuarioAndEstadoTrue(
            Long idUsuario
    );
}