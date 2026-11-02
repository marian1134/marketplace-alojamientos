package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Favorito;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FavoritoRepository extends JpaRepository<Favorito, Favorito.Llave> {

    List<Favorito> findByIdUsuarioOrderByCreadoEnDesc(Long idUsuario);
}
