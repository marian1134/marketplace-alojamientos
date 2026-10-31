package com.inversioneslr.marketplace.controller;

import com.inversioneslr.marketplace.dto.ImagenAlojamientoResponse;
import com.inversioneslr.marketplace.service.ImagenAlojamientoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/v1/alojamientos")
public class ImagenAlojamientoController {

    private final ImagenAlojamientoService imagenService;

    public ImagenAlojamientoController(
            ImagenAlojamientoService imagenService) {

        this.imagenService = imagenService;
    }

    @GetMapping("/{idAlojamiento}/imagenes")
    public List<ImagenAlojamientoResponse> listar(
            @PathVariable Long idAlojamiento) {

        return imagenService.listar(idAlojamiento);
    }

    @PostMapping(
            value = "/{idAlojamiento}/imagenes",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    @ResponseStatus(HttpStatus.CREATED)
    public ImagenAlojamientoResponse subir(
            @PathVariable Long idAlojamiento,
            @RequestPart("imagen") MultipartFile imagen,
            Authentication authentication) {

        return imagenService.subir(
                idAlojamiento,
                imagen,
                authentication
        );
    }

    @PatchMapping("/imagenes/{idImagen}/principal")
    public ImagenAlojamientoResponse marcarComoPrincipal(
            @PathVariable Long idImagen,
            Authentication authentication) {

        return imagenService.marcarComoPrincipal(
                idImagen,
                authentication
        );
    }

    @DeleteMapping("/imagenes/{idImagen}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(
            @PathVariable Long idImagen,
            Authentication authentication) {

        imagenService.eliminar(
                idImagen,
                authentication
        );
    }
}