package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.CalendarioResponse;
import com.inversioneslr.marketplace.dto.PeriodoRequest;
import com.inversioneslr.marketplace.model.Alojamiento;
import com.inversioneslr.marketplace.model.PeriodoDisponible;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.AlojamientoRepository;
import com.inversioneslr.marketplace.repository.NocheReservadaRepository;
import com.inversioneslr.marketplace.repository.PeriodoDisponibleRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

// Calendario y disponibilidad que maneja el anfitrión
@Service
@Transactional
public class CalendarioService {

    private static final long MAXIMO_DIAS_PERIODO = 730;

    private final PeriodoDisponibleRepository periodoRepository;
    private final NocheReservadaRepository nocheRepository;
    private final AlojamientoRepository alojamientoRepository;
    private final UsuarioRepository usuarioRepository;

    public CalendarioService(
            PeriodoDisponibleRepository periodoRepository,
            NocheReservadaRepository nocheRepository,
            AlojamientoRepository alojamientoRepository,
            UsuarioRepository usuarioRepository) {

        this.periodoRepository = periodoRepository;
        this.nocheRepository = nocheRepository;
        this.alojamientoRepository = alojamientoRepository;
        this.usuarioRepository = usuarioRepository;
    }

    @Transactional(readOnly = true)
    public CalendarioResponse obtener(Long idAlojamiento, String correo) {

        Alojamiento alojamiento = buscarDelAnfitrion(idAlojamiento, correo);

        return new CalendarioResponse(
                idAlojamiento,
                alojamiento.getTitulo(),
                periodoRepository
                        .findByIdAlojamientoOrderByFechaInicio(idAlojamiento)
                        .stream()
                        .map(periodo -> new CalendarioResponse.Periodo(
                                periodo.getIdPeriodo(),
                                periodo.getFechaInicio(),
                                periodo.getFechaFin()
                        ))
                        .toList(),
                nocheRepository
                        .findByIdAlojamientoAndFechaGreaterThanEqualOrderByFecha(
                                idAlojamiento,
                                LocalDate.now().minusMonths(1)
                        )
                        .stream()
                        .map(noche -> new CalendarioResponse.Noche(
                                noche.getFecha(),
                                noche.getReserva().getCodigo(),
                                noche.getReserva().getHuesped().getNombre()
                        ))
                        .toList()
        );
    }

    public CalendarioResponse agregarPeriodo(
            Long idAlojamiento,
            PeriodoRequest datos,
            String correo) {

        buscarDelAnfitrion(idAlojamiento, correo);

        if (!datos.fechaFin().isAfter(datos.fechaInicio())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La fecha final debe ser posterior a la inicial"
            );
        }

        if (datos.fechaFin().isBefore(LocalDate.now())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El periodo ya pasó"
            );
        }

        if (ChronoUnit.DAYS.between(datos.fechaInicio(), datos.fechaFin())
                > MAXIMO_DIAS_PERIODO) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Un periodo puede durar máximo 2 años"
            );
        }

        boolean seCruza = periodoRepository
                .findByIdAlojamientoOrderByFechaInicio(idAlojamiento)
                .stream()
                .anyMatch(periodo -> datos.fechaInicio().isBefore(periodo.getFechaFin())
                        && datos.fechaFin().isAfter(periodo.getFechaInicio()));

        if (seCruza) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ese periodo se cruza con otro que ya tienes"
            );
        }

        PeriodoDisponible periodo = new PeriodoDisponible();
        periodo.setIdAlojamiento(idAlojamiento);
        periodo.setFechaInicio(datos.fechaInicio());
        periodo.setFechaFin(datos.fechaFin());
        periodoRepository.save(periodo);

        return obtener(idAlojamiento, correo);
    }

    public CalendarioResponse eliminarPeriodo(Long idPeriodo, String correo) {

        PeriodoDisponible periodo = periodoRepository
                .findById(idPeriodo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "No se encontró el periodo"
                ));

        buscarDelAnfitrion(periodo.getIdAlojamiento(), correo);
        periodoRepository.delete(periodo);

        return obtener(periodo.getIdAlojamiento(), correo);
    }

    private Alojamiento buscarDelAnfitrion(Long idAlojamiento, String correo) {

        Usuario usuario = usuarioRepository
                .findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Debes iniciar sesión"
                ));

        Alojamiento alojamiento = alojamientoRepository
                .findById(idAlojamiento)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "No se encontró el alojamiento"
                ));

        if (!alojamiento.getAnfitrion().getIdUsuario().equals(usuario.getIdUsuario())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Este alojamiento no es tuyo"
            );
        }

        return alojamiento;
    }
}
