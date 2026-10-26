package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsuarioRepository
        extends JpaRepository<Usuario, Long> {

    boolean existsByCorreoIgnoreCase(String correo);
}