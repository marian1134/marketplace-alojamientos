package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.ImagenAlojamientoResponse;
import com.inversioneslr.marketplace.model.Alojamiento;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.ImagenAlojamiento;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.AlojamientoRepository;
import com.inversioneslr.marketplace.repository.ImagenAlojamientoRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import com.inversioneslr.marketplace.repository.UsuarioRolRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
public class ImagenAlojamientoService {

    private static final int MAXIMO_IMAGENES = 10;
    private static final long MAXIMO_BYTES = 5L * 1024L * 1024L;

    private static final Set<String> TIPOS_PERMITIDOS = Set.of(
            "image/jpeg",
            "image/png",
            "image/webp"
    );

    private final ImagenAlojamientoRepository imagenRepository;
    private final AlojamientoRepository alojamientoRepository;
    private final UsuarioRepository usuarioRepository;
    private final UsuarioRolRepository usuarioRolRepository;
    private final Path carpetaImagenes;

    public ImagenAlojamientoService(
            ImagenAlojamientoRepository imagenRepository,
            AlojamientoRepository alojamientoRepository,
            UsuarioRepository usuarioRepository,
            UsuarioRolRepository usuarioRolRepository,
            @Value("${app.ruta-imagenes:uploads/alojamientos}")
            String rutaImagenes) {

        this.imagenRepository = imagenRepository;
        this.alojamientoRepository = alojamientoRepository;
        this.usuarioRepository = usuarioRepository;
        this.usuarioRolRepository = usuarioRolRepository;
        this.carpetaImagenes = Path.of(rutaImagenes)
                .toAbsolutePath()
                .normalize();
    }

    @Transactional(readOnly = true)
    public List<ImagenAlojamientoResponse> listar(
            Long idAlojamiento) {

        if (!alojamientoRepository.existsById(idAlojamiento)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "El alojamiento no existe"
            );
        }

        return imagenRepository
                .findByAlojamiento_IdAlojamientoOrderByPrincipalDescOrdenImagenAsc(
                        idAlojamiento
                )
                .stream()
                .map(this::convertirRespuesta)
                .toList();
    }

    @Transactional
    public ImagenAlojamientoResponse subir(
            Long idAlojamiento,
            MultipartFile archivo,
            Authentication authentication) {

        Alojamiento alojamiento = obtenerAlojamientoDelAnfitrion(
                idAlojamiento,
                authentication
        );

        validarArchivo(archivo);

        long cantidad = imagenRepository
                .countByAlojamiento_IdAlojamiento(idAlojamiento);

        if (cantidad >= MAXIMO_IMAGENES) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El alojamiento ya tiene el máximo de 10 imágenes"
            );
        }

        String tipoContenido = archivo.getContentType()
                .toLowerCase(Locale.ROOT);

        String extension = obtenerExtension(tipoContenido);
        String nombreGuardado = UUID.randomUUID() + extension;
        Path destino = carpetaImagenes
                .resolve(nombreGuardado)
                .normalize();

        if (!destino.getParent().equals(carpetaImagenes)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El nombre del archivo no es válido"
            );
        }

        try {
            Files.createDirectories(carpetaImagenes);

            Files.copy(
                    archivo.getInputStream(),
                    destino,
                    StandardCopyOption.REPLACE_EXISTING
            );
        } catch (IOException excepcion) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se pudo guardar la imagen"
            );
        }

        ImagenAlojamiento imagen = new ImagenAlojamiento();
        imagen.setAlojamiento(alojamiento);
        imagen.setUrlImagen(
                "/uploads/alojamientos/" + nombreGuardado
        );
        imagen.setNombreOriginal(
                limitarNombreOriginal(archivo.getOriginalFilename())
        );
        imagen.setTipoContenido(tipoContenido);
        imagen.setPrincipal(cantidad == 0);
        imagen.setOrdenImagen((int) cantidad);

        ImagenAlojamiento guardada;

        try {
            guardada = imagenRepository.save(imagen);
        } catch (RuntimeException excepcion) {
            eliminarArchivoFisico(destino);

            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se pudo registrar la imagen"
            );
        }

        return convertirRespuesta(guardada);
    }

    @Transactional
    public ImagenAlojamientoResponse marcarComoPrincipal(
            Long idImagen,
            Authentication authentication) {

        ImagenAlojamiento seleccionada = obtenerImagen(idImagen);

        Long idAlojamiento = seleccionada
                .getAlojamiento()
                .getIdAlojamiento();

        obtenerAlojamientoDelAnfitrion(
                idAlojamiento,
                authentication
        );

        List<ImagenAlojamiento> imagenes = imagenRepository
                .findByAlojamiento_IdAlojamientoOrderByPrincipalDescOrdenImagenAsc(
                        idAlojamiento
                );

        for (ImagenAlojamiento imagen : imagenes) {
            imagen.setPrincipal(
                    Objects.equals(
                            imagen.getIdImagen(),
                            seleccionada.getIdImagen()
                    )
            );
        }

        imagenRepository.saveAll(imagenes);

        return convertirRespuesta(seleccionada);
    }

    @Transactional
    public void eliminar(
            Long idImagen,
            Authentication authentication) {

        ImagenAlojamiento imagen = obtenerImagen(idImagen);

        Long idAlojamiento = imagen
                .getAlojamiento()
                .getIdAlojamiento();

        obtenerAlojamientoDelAnfitrion(
                idAlojamiento,
                authentication
        );

        boolean eraPrincipal = imagen.isPrincipal();

        imagenRepository.delete(imagen);
        imagenRepository.flush();

        Path archivo = carpetaImagenes.resolve(
                Path.of(imagen.getUrlImagen())
                        .getFileName()
                        .toString()
        );

        eliminarArchivoFisico(archivo);

        if (eraPrincipal) {
            List<ImagenAlojamiento> restantes = imagenRepository
                    .findByAlojamiento_IdAlojamientoOrderByPrincipalDescOrdenImagenAsc(
                            idAlojamiento
                    );

            if (!restantes.isEmpty()) {
                ImagenAlojamiento nuevaPrincipal = restantes.get(0);
                nuevaPrincipal.setPrincipal(true);
                imagenRepository.save(nuevaPrincipal);
            }
        }
    }

    private ImagenAlojamiento obtenerImagen(Long idImagen) {
        return imagenRepository
                .findById(idImagen)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "La imagen no existe"
                ));
    }

    private Alojamiento obtenerAlojamientoDelAnfitrion(
            Long idAlojamiento,
            Authentication authentication) {

        if (authentication == null
                || !authentication.isAuthenticated()) {

            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Debes iniciar sesión"
            );
        }

        Usuario usuario = usuarioRepository
                .findByCorreoIgnoreCase(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "La sesión no es válida"
                ));

        if (usuario.getEstado() != EstadoUsuario.ACTIVO) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "La cuenta no está activa"
            );
        }

        boolean esAnfitrion = usuarioRolRepository
                .existsByUsuario_IdUsuarioAndRol_NombreIgnoreCaseAndEstadoTrue(
                        usuario.getIdUsuario(),
                        "ANFITRION"
                );

        if (!esAnfitrion) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Solo los anfitriones pueden administrar imágenes"
            );
        }

        Alojamiento alojamiento = alojamientoRepository
                .findById(idAlojamiento)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "El alojamiento no existe"
                ));

        if (!Objects.equals(
                alojamiento.getAnfitrion().getIdUsuario(),
                usuario.getIdUsuario())) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No puedes modificar las imágenes de otro alojamiento"
            );
        }

        return alojamiento;
    }

    private void validarArchivo(MultipartFile archivo) {
        if (archivo == null || archivo.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Debes seleccionar una imagen"
            );
        }

        if (archivo.getSize() > MAXIMO_BYTES) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La imagen no puede superar 5 MB"
            );
        }

        String tipo = archivo.getContentType();

        if (tipo == null
                || !TIPOS_PERMITIDOS.contains(
                        tipo.toLowerCase(Locale.ROOT))) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Solo se permiten imágenes JPG, PNG o WebP"
            );
        }
    }

    private String obtenerExtension(String tipoContenido) {
        return switch (tipoContenido) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El tipo de imagen no está permitido"
            );
        };
    }

    private String limitarNombreOriginal(String nombre) {
        String resultado = nombre == null || nombre.isBlank()
                ? "imagen"
                : Path.of(nombre).getFileName().toString();

        if (resultado.length() > 255) {
            return resultado.substring(resultado.length() - 255);
        }

        return resultado;
    }

    private void eliminarArchivoFisico(Path archivo) {
        try {
            Files.deleteIfExists(archivo);
        } catch (IOException excepcion) {
            // El registro puede eliminarse aunque el archivo ya no exista.
        }
    }

    private ImagenAlojamientoResponse convertirRespuesta(
            ImagenAlojamiento imagen) {

        return new ImagenAlojamientoResponse(
                imagen.getIdImagen(),
                imagen.getAlojamiento().getIdAlojamiento(),
                imagen.getUrlImagen(),
                imagen.getNombreOriginal(),
                imagen.getTipoContenido(),
                imagen.isPrincipal(),
                imagen.getOrdenImagen(),
                imagen.getFechaCreacion()
        );
    }
}