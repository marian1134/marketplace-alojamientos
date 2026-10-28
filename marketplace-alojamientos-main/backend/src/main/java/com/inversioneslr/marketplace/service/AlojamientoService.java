package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.AlojamientoRequest;
import com.inversioneslr.marketplace.dto.AlojamientoResponse;
import com.inversioneslr.marketplace.model.Alojamiento;
import com.inversioneslr.marketplace.model.EstadoPublicacion;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.AlojamientoRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional

public class AlojamientoService {

   private final AlojamientoRepository alojamientoRepository;
    private final UsuarioRepository usuarioRepository;

    public AlojamientoService(
            AlojamientoRepository alojamientoRepository,
            UsuarioRepository usuarioRepository) {
        this.alojamientoRepository = alojamientoRepository;
        this.usuarioRepository = usuarioRepository;
    }

    /**
     * @return
     */
    @Transactional(readOnly = true)
    public List<AlojamientoResponse> listarActivos() {
        return alojamientoRepository.findByEstado(EstadoPublicacion.ACTIVO)
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AlojamientoResponse> buscarActivosPorCiudad(String ciudad) {
        if (ciudad == null || ciudad.isBlank()) {
            throw new IllegalArgumentException("La ciudad es obligatoria.");
        }

        return alojamientoRepository
                .findByCiudadIgnoreCaseAndEstado(
                        ciudad.trim(),
                        EstadoPublicacion.ACTIVO)
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AlojamientoResponse> listarPorAnfitrion(Long idAnfitrion) {
        return alojamientoRepository
                .findByAnfitrion_IdUsuario(idAnfitrion)
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public AlojamientoResponse obtenerPorId(Long id) {
        return convertirAResponse(buscarEntidad(id));
    }

    public AlojamientoResponse crear(AlojamientoRequest request) {
        validarRequest(request);

        Usuario anfitrion = usuarioRepository
                .findById(request.idAnfitrion())
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "No se encontró el usuario anfitrión."));

        Alojamiento alojamiento = new Alojamiento();
        alojamiento.setAnfitrion(anfitrion);
        copiarDatos(request, alojamiento);
        alojamiento.setEstado(EstadoPublicacion.BORRADOR);

        return convertirAResponse(alojamientoRepository.save(alojamiento));
    }

    public AlojamientoResponse guardarCambios(
            Long id, AlojamientoRequest request) {
        validarRequest(request);

        Alojamiento existente = buscarEntidad(id);

        if (!existente.getAnfitrion().getIdUsuario()
                .equals(request.idAnfitrion())) {
            throw new IllegalArgumentException(
                    "El anfitrión no coincide con el propietario del alojamiento.");
        }

        copiarDatos(request, existente);

        return convertirAResponse(alojamientoRepository.save(existente));
    }

    public AlojamientoResponse cambiarEstado(
            Long id, EstadoPublicacion estado) {
        if (estado == null) {
            throw new IllegalArgumentException(
                    "El estado es obligatorio.");
        }

        Alojamiento alojamiento = buscarEntidad(id);
        alojamiento.setEstado(estado);

        return convertirAResponse(alojamientoRepository.save(alojamiento));
    }

    private Alojamiento buscarEntidad(Long id) {
        return alojamientoRepository.findById(id)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "No se encontró el alojamiento con ID " + id));
    }

    private void copiarDatos(
            AlojamientoRequest request, Alojamiento alojamiento) {
        alojamiento.setTitulo(request.titulo().trim());
        alojamiento.setDescripcion(request.descripcion().trim());
        alojamiento.setCiudad(request.ciudad().trim());
        alojamiento.setDireccion(request.direccion().trim());
        alojamiento.setTipoAlojamiento(request.tipoAlojamiento());
        alojamiento.setCapacidad(request.capacidad());
        alojamiento.setPrecioNoche(request.precioNoche());
    }

    private void validarRequest(AlojamientoRequest request) {
        if (request == null) {
            throw new IllegalArgumentException(
                    "Los datos del alojamiento son obligatorios.");
        }
    }

    private AlojamientoResponse convertirAResponse(Alojamiento alojamiento) {
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
                alojamiento.getEstado(),
                alojamiento.getFechaCreacion(),
                alojamiento.getFechaActualizacion()
        );
    }

}
