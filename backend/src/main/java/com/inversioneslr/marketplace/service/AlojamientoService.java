package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.AlojamientoRequest;
import com.inversioneslr.marketplace.dto.AlojamientoResponse;
import com.inversioneslr.marketplace.model.Alojamiento;
import com.inversioneslr.marketplace.model.EstadoPublicacion;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.ModoReserva;
import com.inversioneslr.marketplace.model.PoliticaCancelacion;
import com.inversioneslr.marketplace.model.Rol;
import com.inversioneslr.marketplace.model.TipoPolitica;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.AlojamientoRepository;
import com.inversioneslr.marketplace.repository.ImagenAlojamientoRepository;
import com.inversioneslr.marketplace.repository.PoliticaCancelacionRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.List;

@Service
@Transactional
public class AlojamientoService {

    private final AlojamientoRepository alojamientoRepository;
    private final ImagenAlojamientoRepository imagenRepository;
    private final UsuarioRepository usuarioRepository;
    private final PoliticaCancelacionRepository politicaRepository;

    public AlojamientoService(
            AlojamientoRepository alojamientoRepository,
            ImagenAlojamientoRepository imagenRepository,
            UsuarioRepository usuarioRepository,
            PoliticaCancelacionRepository politicaRepository) {

        this.alojamientoRepository = alojamientoRepository;
        this.imagenRepository = imagenRepository;
        this.usuarioRepository = usuarioRepository;
        this.politicaRepository = politicaRepository;
    }

    @Transactional(readOnly = true)
    public List<AlojamientoResponse> listarActivos() {

        return alojamientoRepository
                .findByEstado(EstadoPublicacion.ACTIVA)
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AlojamientoResponse> buscarActivosPorCiudad(
            String ciudad) {

        if (ciudad == null || ciudad.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La ciudad es obligatoria"
            );
        }

        return alojamientoRepository
                .findByCiudadIgnoreCaseAndEstado(
                        ciudad.trim(),
                        EstadoPublicacion.ACTIVA
                )
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AlojamientoResponse> listarMisAlojamientos(
            String correo) {

        Usuario anfitrion = obtenerAnfitrion(correo);

        return alojamientoRepository
                .findByAnfitrion_IdUsuario(
                        anfitrion.getIdUsuario()
                )
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public AlojamientoResponse obtenerPorId(Long id) {

        return convertirAResponse(buscarEntidad(id));
    }

    public AlojamientoResponse crear(
            AlojamientoRequest request,
            String correo) {

        validarRequest(request);

        Usuario anfitrion = obtenerAnfitrion(correo);

        Alojamiento alojamiento = new Alojamiento();
        alojamiento.setAnfitrion(anfitrion);
        copiarDatos(request, alojamiento);
        alojamiento.setEstado(EstadoPublicacion.BORRADOR);

        Alojamiento guardado =
                alojamientoRepository.save(alojamiento);

        return convertirAResponse(guardado);
    }

    public AlojamientoResponse guardarCambios(
            Long id,
            AlojamientoRequest request,
            String correo) {

        validarRequest(request);

        Usuario anfitrion = obtenerAnfitrion(correo);
        Alojamiento alojamiento = buscarEntidad(id);

        verificarPropietario(alojamiento, anfitrion);

        copiarDatos(request, alojamiento);

        Alojamiento guardado =
                alojamientoRepository.save(alojamiento);

        return convertirAResponse(guardado);
    }

    public AlojamientoResponse cambiarEstado(
            Long id,
            EstadoPublicacion estado,
            String correo) {

        if (estado == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El estado es obligatorio"
            );
        }

        Usuario anfitrion = obtenerAnfitrion(correo);
        Alojamiento alojamiento = buscarEntidad(id);

        verificarPropietario(alojamiento, anfitrion);

        boolean necesitaImagen =
                estado == EstadoPublicacion.PENDIENTE_REVISION
                || estado == EstadoPublicacion.ACTIVA;

        long cantidadImagenes = imagenRepository
                .countByAlojamiento_IdAlojamiento(id);

        if (necesitaImagen && cantidadImagenes == 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Debes agregar al menos una imagen "
                            + "antes de publicar el alojamiento"
            );
        }

        alojamiento.setEstado(estado);

        Alojamiento guardado =
                alojamientoRepository.save(alojamiento);

        return convertirAResponse(guardado);
    }

    private Usuario obtenerAnfitrion(String correo) {

        if (correo == null || correo.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Debes iniciar sesión"
            );
        }

        Usuario usuario = usuarioRepository
                .findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "No se encontró el usuario de la sesión"
                ));

        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "La cuenta no se encuentra activa"
            );
        }

        boolean esAnfitrion = usuario.getRol() == Rol.ANFITRION;

        if (!esAnfitrion) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Solo los anfitriones pueden gestionar alojamientos"
            );
        }

        return usuario;
    }

    private void verificarPropietario(
            Alojamiento alojamiento,
            Usuario anfitrion) {

        if (!alojamiento.getAnfitrion()
                .getIdUsuario()
                .equals(anfitrion.getIdUsuario())) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No puedes modificar el alojamiento de otro anfitrión"
            );
        }
    }

    private Alojamiento buscarEntidad(Long id) {

        return alojamientoRepository
                .findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "No se encontró el alojamiento con ID " + id
                ));
    }

    private void copiarDatos(
            AlojamientoRequest request,
            Alojamiento alojamiento) {

        alojamiento.setTitulo(request.titulo().trim());

        alojamiento.setDescripcion(
                request.descripcion().trim()
        );

        alojamiento.setCiudad(request.ciudad().trim());

        alojamiento.setDireccion(
                request.direccion().trim()
        );

        alojamiento.setTipoAlojamiento(
                request.tipoAlojamiento()
        );

        alojamiento.setCapacidad(request.capacidad());

        alojamiento.setPrecioNoche(
                request.precioNoche()
        );

        alojamiento.setTarifaLimpieza(
                request.tarifaLimpieza() != null
                        ? request.tarifaLimpieza()
                        : BigDecimal.ZERO
        );

        alojamiento.setModoReserva(
                request.modoReserva() != null
                        ? request.modoReserva()
                        : ModoReserva.INMEDIATA
        );

        TipoPolitica tipoPolitica = request.tipoPolitica() != null
                ? request.tipoPolitica()
                : TipoPolitica.MODERADA;

        PoliticaCancelacion politica = politicaRepository
                .findByTipo(tipoPolitica)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "La política de cancelación no está configurada. "
                                + "Ejecuta 02_datos_iniciales.sql"
                ));

        alojamiento.setPolitica(politica);
    }

    private void validarRequest(
            AlojamientoRequest request) {

        if (request == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Los datos del alojamiento son obligatorios"
            );
        }
    }

    private AlojamientoResponse convertirAResponse(
            Alojamiento alojamiento) {

        return new AlojamientoResponse(
                alojamiento.getIdAlojamiento(),
                alojamiento.getAnfitrion().getIdUsuario(),
                alojamiento.getTitulo(),
                alojamiento.getDescripcion(),
                alojamiento.getCiudad(),
                alojamiento.getDireccion(),
                alojamiento.getTipoAlojamiento(),
                alojamiento.getCapacidad(),
                alojamiento.getPrecioNoche(),
                alojamiento.getTarifaLimpieza(),
                alojamiento.getModoReserva(),
                alojamiento.getPolitica().getTipo(),
                alojamiento.getEstado(),
                alojamiento.getMotivoEstado(),
                alojamiento.getFechaCreacion(),
                alojamiento.getFechaActualizacion()
        );
    }
}