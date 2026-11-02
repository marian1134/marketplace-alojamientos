package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.ResultadoBusqueda;
import com.inversioneslr.marketplace.service.FavoritoService;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/favoritos")
public class FavoritoController {

    private final FavoritoService favoritoService;

    public FavoritoController(FavoritoService favoritoService) {
        this.favoritoService = favoritoService;
    }

    @GetMapping
    public List<ResultadoBusqueda> listar(Authentication autenticacion) {
        return favoritoService.listar(autenticacion.getName());
    }

    @GetMapping("/ids")
    public List<Long> listarIds(Authentication autenticacion) {
        return favoritoService.listarIds(autenticacion.getName());
    }

    @PostMapping("/{idAlojamiento}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void agregar(@PathVariable Long idAlojamiento, Authentication autenticacion) {
        favoritoService.agregar(idAlojamiento, autenticacion.getName());
    }

    @DeleteMapping("/{idAlojamiento}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void quitar(@PathVariable Long idAlojamiento, Authentication autenticacion) {
        favoritoService.quitar(idAlojamiento, autenticacion.getName());
    }
}
