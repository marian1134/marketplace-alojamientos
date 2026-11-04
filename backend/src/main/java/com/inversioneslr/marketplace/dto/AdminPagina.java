package com.inversioneslr.marketplace.dto;
import java.util.List;
public record AdminPagina(List<java.util.Map<String, Object>> contenido, long total, int pagina, int tamano) {}
