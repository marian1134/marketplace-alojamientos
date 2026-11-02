package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.ResultadoBusqueda;
import com.inversioneslr.marketplace.model.EstadoPublicacion;
import com.inversioneslr.marketplace.model.Favorito;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.AlojamientoRepository;
import com.inversioneslr.marketplace.repository.FavoritoRepository;
import com.inversioneslr.marketplace.repository.ImagenAlojamientoRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@Transactional
public class FavoritoService {

    private final FavoritoRepository favoritoRepository;
    private final AlojamientoRepository alojamientoRepository;
    private final ImagenAlojamientoRepository imagenRepository;
    private final UsuarioRepository usuarioRepository;
    private final AlojamientoService alojamientoService;

    public FavoritoService(
            FavoritoRepository favoritoRepository,
            AlojamientoRepository alojamientoRepository,
            ImagenAlojamientoRepository imagenRepository,
            UsuarioRepository usuarioRepository,
            AlojamientoService alojamientoService) {

        this.favoritoRepository = favoritoRepository;
        this.alojamientoRepository = alojamientoRepository;
        this.imagenRepository = imagenRepository;
        this.usuarioRepository = usuarioRepository;
        this.alojamientoService = alojamientoService;
    }

    // Ids de los favoritos del usuario (para pintar los corazones)
    @Transactional(readOnly = true)
    public List<Long> listarIds(String correo) {

        return favoritoRepository
                .findByIdUsuarioOrderByCreadoEnDesc(obtenerUsuario(correo).getIdUsuario())
                .stream()
                .map(Favorito::getIdAlojamiento)
                .toList();
    }

    // Favoritos con foto, solo de alojamientos que siguen activos
    @Transactional(readOnly = true)
    public List<ResultadoBusqueda> listar(String correo) {

        return listarIds(correo)
                .stream()
                .map(id -> alojamientoRepository.findById(id).orElse(null))
                .filter(alojamiento -> alojamiento != null
                        && alojamiento.getEstado() == EstadoPublicacion.ACTIVA)
                .map(alojamiento -> new ResultadoBusqueda(
                        alojamientoService.obtenerPorId(alojamiento.getIdAlojamiento()),
                        imagenRepository
                                .findByAlojamiento_IdAlojamientoOrderByOrdenImagenAscIdImagenAsc(
                                        alojamiento.getIdAlojamiento()
                                )
                                .stream()
                                .findFirst()
                                .map(imagen -> imagen.getUrlImagen())
                                .orElse(null),
                        0,
                        null,
                        null,
                        0
                ))
                .toList();
    }

    public void agregar(Long idAlojamiento, String correo) {

        Usuario usuario = obtenerUsuario(correo);

        if (!alojamientoRepository.existsById(idAlojamiento)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "No se encontró el alojamiento"
            );
        }

        var llave = new Favorito.Llave(usuario.getIdUsuario(), idAlojamiento);

        if (!favoritoRepository.existsById(llave)) {
            favoritoRepository.save(new Favorito(usuario.getIdUsuario(), idAlojamiento));
        }
    }

    public void quitar(Long idAlojamiento, String correo) {

        Usuario usuario = obtenerUsuario(correo);

        favoritoRepository.deleteById(
                new Favorito.Llave(usuario.getIdUsuario(), idAlojamiento)
        );
    }

    private Usuario obtenerUsuario(String correo) {

        return usuarioRepository
                .findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Debes iniciar sesión"
                ));
    }
}
