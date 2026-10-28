package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.AlojamientoRequest;
import com.inversioneslr.marketplace.dto.AlojamientoResponse;
import com.inversioneslr.marketplace.model.EstadoPublicacion;
import com.inversioneslr.marketplace.service.AlojamientoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/alojamientos")
public class AlojamientoController {

 private final AlojamientoService alojamientoService;

    public AlojamientoController(AlojamientoService alojamientoService) {
        this.alojamientoService = alojamientoService;
    }

    @GetMapping
    public List<AlojamientoResponse> listarActivos() {
        return alojamientoService.listarActivos();
    }

    @GetMapping("/ciudad/{ciudad}")
    public List<AlojamientoResponse> buscarPorCiudad(
            @PathVariable String ciudad) {
        return alojamientoService.buscarActivosPorCiudad(ciudad);
    }

    @GetMapping("/anfitrion/{idAnfitrion}")
    public List<AlojamientoResponse> listarPorAnfitrion(
            @PathVariable Long idAnfitrion) {
        return alojamientoService.listarPorAnfitrion(idAnfitrion);
    }

    @GetMapping("/{id}")
    public AlojamientoResponse obtenerPorId(@PathVariable Long id) {
        return alojamientoService.obtenerPorId(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AlojamientoResponse crear(
            @Valid @RequestBody AlojamientoRequest request) {
        return alojamientoService.crear(request);
    }

    @PutMapping("/{id}")
    public AlojamientoResponse actualizar(
            @PathVariable Long id,
            @Valid @RequestBody AlojamientoRequest request) {
        return alojamientoService.guardarCambios(id, request);
    }

    @PatchMapping("/{id}/estado")
    public AlojamientoResponse cambiarEstado(
            @PathVariable Long id,
            @RequestParam EstadoPublicacion estado) {
        return alojamientoService.cambiarEstado(id, estado);
    }


}
