package com.inversioneslr.marketplace.service;

import org.springframework.http.HttpStatus;

/** Codigo publico controlado; nunca devuelve mensajes ni credenciales del proveedor. */
public class FalloAsistente extends RuntimeException {
    private final HttpStatus estado;
    private final String codigo;

    public FalloAsistente(HttpStatus estado, String codigo) {
        super(codigo);
        this.estado = estado;
        this.codigo = codigo;
    }

    public HttpStatus getEstado() { return estado; }
    public String getCodigo() { return codigo; }
}
