package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.ResenaHuespedResponse;
import com.inversioneslr.marketplace.dto.ResenaRequest;
import com.inversioneslr.marketplace.model.EstadoReserva;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.ResenaHuesped;
import com.inversioneslr.marketplace.model.Reserva;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.ResenaHuespedRepository;
import com.inversioneslr.marketplace.repository.ReservaParaResenaRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;

@Service
@Transactional
public class ResenaHuespedService {
    private final ResenaHuespedRepository resenas;
    private final ReservaParaResenaRepository reservas;
    private final UsuarioRepository usuarios;

    public ResenaHuespedService(ResenaHuespedRepository resenas,
            ReservaParaResenaRepository reservas, UsuarioRepository usuarios) {
        this.resenas = resenas;
        this.reservas = reservas;
        this.usuarios = usuarios;
    }

    @Transactional(readOnly = true)
    public List<ResenaHuespedResponse> listar(String correo) {
        obtenerUsuario(correo);
        return resenas.buscarDelAnfitrion(correo).stream()
                .map(resena -> ResenaHuespedResponse.desde(resena)).toList();
    }

    public ResenaHuespedResponse crear(Long idReserva, ResenaRequest datos, String correo) {
        Usuario usuario = obtenerUsuario(correo);
        Reserva reserva = reservas.buscarBloqueada(idReserva)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "No se encontró la reserva"));

        // La identidad del autor y la del huésped salen de la sesión y la reserva.
        if (!reserva.getAlojamiento().getAnfitrion().getIdUsuario()
                .equals(usuario.getIdUsuario())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Solo el anfitrión de esta reserva puede calificar al huésped");
        }
        if (reserva.getEstado() != EstadoReserva.COMPLETADA) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Podrás calificar al huésped cuando la reserva esté completada");
        }
        if (resenas.existsByReserva_IdReserva(idReserva)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Ya calificaste al huésped de esta reserva");
        }
        String comentario = datos.comentario() == null ? "" : datos.comentario().trim();
        if (datos.calificacion() == null || datos.calificacion() < 1
                || datos.calificacion() > 5 || comentario.length() < 10
                || comentario.length() > 1000) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Elige de 1 a 5 estrellas y escribe un comentario de 10 a 1000 caracteres");
        }

        ResenaHuesped resena = new ResenaHuesped();
        resena.setReserva(reserva);
        resena.setCalificacion(datos.calificacion());
        resena.setComentario(comentario);
        return ResenaHuespedResponse.desde(resenas.saveAndFlush(resena));
    }

    private Usuario obtenerUsuario(String correo) {
        if (correo == null || correo.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Debes iniciar sesión");
        }
        Usuario usuario = usuarios.findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "No se encontró el usuario de la sesión"));
        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "La cuenta no se encuentra activa");
        }
        return usuario;
    }
}
