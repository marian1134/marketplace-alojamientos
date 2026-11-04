package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.NotificacionResponse;
import com.inversioneslr.marketplace.model.Notificacion;
import com.inversioneslr.marketplace.repository.NotificacionRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class NotificacionService {

    private final NotificacionRepository notificacionRepository;

    public NotificacionService(
            NotificacionRepository notificacionRepository) {

        this.notificacionRepository = notificacionRepository;
    }

    // Incluye los 50 avisos más recientes y el total sin leer.
    public record Bandeja(
            List<NotificacionResponse> notificaciones,
            long sinLeer
    ) {
    }

    @Transactional(readOnly = true)
    public Bandeja listar(String correo) {
        List<NotificacionResponse> notificaciones =
                notificacionRepository.buscarDelUsuario(
                                correo,
                                PageRequest.of(0, 50)
                        )
                        .stream()
                        .map(NotificacionResponse::desde)
                        .toList();

        long sinLeer = notificacionRepository.contarSinLeer(correo);

        return new Bandeja(notificaciones, sinLeer);
    }

    @Transactional
    public void marcarLeida(Long id, String correo) {
        // El correo viene de la sesión, no del navegador.
        Notificacion notificacion = notificacionRepository
                .buscarPropia(id, correo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "La notificación no existe"
                ));

        notificacion.setLeida(true);
    }

    @Transactional
    public void marcarTodasLeidas(String correo) {
        notificacionRepository.marcarTodasLeidas(correo);
    }
}