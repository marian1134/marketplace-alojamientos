package com.inversioneslr.marketplace.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class EstadoController {

    @GetMapping("/api/estado")
    public String consultarEstado() {
        return "Backend de Inversiones LR funcionando";
    }
}