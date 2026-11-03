package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class FotoPerfilService {

    private static final long MAXIMO_BYTES = 5L * 1024 * 1024;
    private static final String PREFIJO_URL = "/uploads/perfiles/";

    private static final Set<String> TIPOS_PERMITIDOS = Set.of(
            "image/jpeg",
            "image/png",
            "image/webp"
    );

    private static final Map<String, String> EXTENSIONES = Map.of(
            "image/jpeg", ".jpg",
            "image/png", ".png",
            "image/webp", ".webp"
    );

    private final UsuarioRepository usuarioRepository;
    private final Path carpetaFotos;

    public FotoPerfilService(
            UsuarioRepository usuarioRepository,
            @Value("${app.ruta-fotos-perfil:uploads/perfiles}")
            String rutaFotos) {

        this.usuarioRepository = usuarioRepository;
        this.carpetaFotos = Path.of(rutaFotos)
                .toAbsolutePath()
                .normalize();
    }

    @Transactional
    public UsuarioResponse guardar(
            MultipartFile archivo,
            String correo) {

        validarArchivo(archivo);
        Usuario usuario = obtenerUsuarioActivo(correo);

        String extension = EXTENSIONES.get(archivo.getContentType());
        String nombreArchivo = "usuario-"
                + usuario.getIdUsuario()
                + "-"
                + UUID.randomUUID()
                + extension;

        Path destino = carpetaFotos.resolve(nombreArchivo).normalize();

        if (!destino.startsWith(carpetaFotos)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El nombre del archivo no es válido"
            );
        }

        String fotoAnterior = usuario.getFotoUrl();

        try {
            Files.createDirectories(carpetaFotos);

            try (InputStream entrada = archivo.getInputStream()) {
                Files.copy(
                        entrada,
                        destino,
                        StandardCopyOption.REPLACE_EXISTING
                );
            }

            usuario.setFotoUrl(PREFIJO_URL + nombreArchivo);
            Usuario guardado = usuarioRepository.save(usuario);

            eliminarArchivoAnterior(fotoAnterior, nombreArchivo);

            return UsuarioResponse.desde(guardado);
        } catch (IOException excepcion) {
            eliminarSilenciosamente(destino);

            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se pudo guardar la foto de perfil"
            );
        } catch (RuntimeException excepcion) {
            eliminarSilenciosamente(destino);
            throw excepcion;
        }
    }

    @Transactional
    public UsuarioResponse eliminar(String correo) {
        Usuario usuario = obtenerUsuarioActivo(correo);
        String fotoAnterior = usuario.getFotoUrl();

        usuario.setFotoUrl(null);
        Usuario guardado = usuarioRepository.save(usuario);

        eliminarArchivoAnterior(fotoAnterior, null);

        return UsuarioResponse.desde(guardado);
    }

    private Usuario obtenerUsuarioActivo(String correo) {
        Usuario usuario = usuarioRepository
                .findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "La cuenta de la sesión no existe"
                ));

        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "La cuenta no se encuentra activa"
            );
        }

        return usuario;
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
                    "La foto debe pesar máximo 5 MB"
            );
        }

        if (!TIPOS_PERMITIDOS.contains(archivo.getContentType())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La foto debe ser JPG, PNG o WebP"
            );
        }
    }

    private void eliminarArchivoAnterior(
            String fotoAnterior,
            String nombreNuevo) {

        if (fotoAnterior == null
                || !fotoAnterior.startsWith(PREFIJO_URL)) {
            return;
        }

        String nombreAnterior = fotoAnterior.substring(PREFIJO_URL.length());

        if (nombreAnterior.isBlank()
                || nombreAnterior.equals(nombreNuevo)) {
            return;
        }

        Path archivoAnterior = carpetaFotos
                .resolve(Path.of(nombreAnterior).getFileName())
                .normalize();

        if (archivoAnterior.startsWith(carpetaFotos)) {
            eliminarSilenciosamente(archivoAnterior);
        }
    }

    private void eliminarSilenciosamente(Path archivo) {
        try {
            Files.deleteIfExists(archivo);
        } catch (IOException ignored) {
            // La foto nueva ya quedó guardada; una foto antigua no bloquea la operación.
        }
    }
}
