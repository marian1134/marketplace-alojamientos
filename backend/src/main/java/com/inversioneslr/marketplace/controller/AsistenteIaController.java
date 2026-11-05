package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.PreguntaAsistenteRequest;
import com.inversioneslr.marketplace.service.AsistenteIaService;
import com.inversioneslr.marketplace.service.FalloAsistente;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/asistente")
public class AsistenteIaController {
    private final AsistenteIaService asistente;
    public AsistenteIaController(AsistenteIaService asistente) { this.asistente = asistente; }

    @GetMapping("/estado")
    public ResponseEntity<Map<String, Object>> estado(Authentication autenticacion) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(asistente.estado(autenticacion));
    }

    @PostMapping("/preguntar")
    public ResponseEntity<Map<String, String>> preguntar(@Valid @RequestBody PreguntaAsistenteRequest datos,
                                                       Authentication autenticacion) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(Map.of("respuesta", asistente.preguntar(datos, autenticacion)));
    }

    @ExceptionHandler(FalloAsistente.class)
    public ResponseEntity<Map<String, String>> fallo(FalloAsistente error) {
        return ResponseEntity.status(error.getEstado()).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", error.getCodigo()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> datosInvalidos() {
        return ResponseEntity.badRequest().cacheControl(CacheControl.noStore()).body(Map.of("codigo", "IA_DATOS"));
    }
}
