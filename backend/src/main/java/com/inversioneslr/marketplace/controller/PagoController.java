package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.ConfiguracionPagoResponse;
import com.inversioneslr.marketplace.dto.IntencionPagoRequest;
import com.inversioneslr.marketplace.dto.IntencionPagoResponse;
import com.inversioneslr.marketplace.service.MonedaService;
import com.inversioneslr.marketplace.service.ReservaService;
import com.inversioneslr.marketplace.service.StripeService;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/pagos")
public class PagoController {

    private final ReservaService reservaService;
    private final StripeService stripeService;
    private final MonedaService monedaService;

    public PagoController(
            ReservaService reservaService,
            StripeService stripeService,
            MonedaService monedaService) {

        this.reservaService = reservaService;
        this.stripeService = stripeService;
        this.monedaService = monedaService;
    }

    @GetMapping("/configuracion")
    public ConfiguracionPagoResponse configuracion() {

        return new ConfiguracionPagoResponse(
                stripeService.activo(),
                stripeService.activo() ? stripeService.getClavePublica() : null,
                monedaService.getTasaUsd(),
                List.of(MonedaService.COP, MonedaService.USD)
        );
    }

    @PostMapping("/intencion")
    public IntencionPagoResponse crearIntencion(
            @Valid @RequestBody IntencionPagoRequest datos,
            Authentication autenticacion) {

        return reservaService.crearIntencionPago(datos, autenticacion.getName());
    }
}
