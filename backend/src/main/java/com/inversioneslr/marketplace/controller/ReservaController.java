package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.CotizacionRequest;
import com.inversioneslr.marketplace.dto.CotizacionResponse;
import com.inversioneslr.marketplace.dto.DetalleAlojamientoResponse;
import com.inversioneslr.marketplace.dto.MotivoRequest;
import com.inversioneslr.marketplace.dto.ReservaRequest;
import com.inversioneslr.marketplace.dto.ReservaResponse;
import com.inversioneslr.marketplace.dto.ResultadoBusqueda;
import com.inversioneslr.marketplace.service.ReservaService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
public class ReservaController {

    private final ReservaService reservaService;

    public ReservaController(ReservaService reservaService) {
        this.reservaService = reservaService;
    }

    @GetMapping("/api/v1/alojamientos/{id}/detalle")
    public DetalleAlojamientoResponse obtenerDetalle(
            @PathVariable Long id,
            Authentication autenticacion) {

        return reservaService.obtenerDetalle(id, autenticacion.getName());
    }

    @GetMapping("/api/v1/busqueda")
    public List<ResultadoBusqueda> buscar(
            @RequestParam(required = false) String destino,
            @RequestParam(required = false) List<String> ciudades,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate llegada,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate salida,
            @RequestParam(required = false) Integer huespedes,
            Authentication autenticacion) {

        return reservaService.buscar(
                destino,
                ciudades,
                llegada,
                salida,
                huespedes,
                autenticacion.getName()
        );
    }

    @PostMapping("/api/v1/reservas/cotizacion")
    public CotizacionResponse cotizar(
            @Valid @RequestBody CotizacionRequest datos,
            Authentication autenticacion) {

        return reservaService.cotizar(datos, autenticacion.getName());
    }

    @PostMapping("/api/v1/reservas")
    @ResponseStatus(HttpStatus.CREATED)
    public ReservaResponse crear(
            @Valid @RequestBody ReservaRequest datos,
            Authentication autenticacion) {

        return reservaService.crear(datos, autenticacion.getName());
    }

    @GetMapping("/api/v1/reservas/mis-reservas")
    public List<ReservaResponse> listarMisReservas(
            Authentication autenticacion) {

        return reservaService.listarMisReservas(autenticacion.getName());
    }

    @GetMapping("/api/v1/reservas/recibidas")
    public List<ReservaResponse> listarReservasRecibidas(
            Authentication autenticacion) {

        return reservaService.listarReservasRecibidas(autenticacion.getName());
    }

    @GetMapping("/api/v1/reservas/{id}")
    public ReservaResponse obtener(
            @PathVariable Long id,
            Authentication autenticacion) {

        return reservaService.obtener(id, autenticacion.getName());
    }

    @PostMapping("/api/v1/reservas/{id}/cancelar")
    public ReservaResponse cancelar(
            @PathVariable Long id,
            @Valid @RequestBody MotivoRequest datos,
            Authentication autenticacion) {

        return reservaService.cancelar(id, datos.motivo(), autenticacion.getName());
    }

    @PatchMapping("/api/v1/reservas/{id}/aprobar")
    public ReservaResponse aprobar(
            @PathVariable Long id,
            Authentication autenticacion) {

        return reservaService.aprobar(id, autenticacion.getName());
    }

    @PatchMapping("/api/v1/reservas/{id}/rechazar")
    public ReservaResponse rechazar(
            @PathVariable Long id,
            @Valid @RequestBody MotivoRequest datos,
            Authentication autenticacion) {

        return reservaService.rechazar(id, datos.motivo(), autenticacion.getName());
    }
}
