package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UsuarioRepository
        extends JpaRepository<Usuario, Long> {

    boolean existsByCorreoIgnoreCase(String correo);

    Optional<Usuario> findByCorreoIgnoreCase(String correo);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("SELECT u FROM Usuario u WHERE LOWER(u.correo) = LOWER(:correo)")
    java.util.Optional<Usuario> bloquearPorCorreo(@org.springframework.data.repository.query.Param("correo") String correo);
}
