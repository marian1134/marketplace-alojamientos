package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.*;
import com.inversioneslr.marketplace.model.*;
import com.inversioneslr.marketplace.repository.*;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class ChatReservaService {
    private static final int TAMANO = 50;
    private final ChatReservaRepository reservas;
    private final MensajeReservaRepository mensajes;
    private final UsuarioRepository usuarios;
    private final NotificacionRepository notificaciones;

    public ChatReservaService(ChatReservaRepository reservas,
                              MensajeReservaRepository mensajes,
                              UsuarioRepository usuarios,
                              NotificacionRepository notificaciones) {
        this.reservas = reservas;
        this.mensajes = mensajes;
        this.usuarios = usuarios;
        this.notificaciones = notificaciones;
    }

    @Transactional(readOnly = true)
    public ConversacionReservaResponse listar(Long id, Long antes, Long despues, String correo) {
        Usuario usuario = usuarioActivo(correo);
        Reserva reserva = reservaPropia(id, usuario);
        if ((antes != null && antes <= 0) || (despues != null && despues < 0)
                || (antes != null && despues != null)) {
            throw error(HttpStatus.BAD_REQUEST, "Usa un solo cursor válido para consultar el chat.");
        }
        List<MensajeReserva> encontrados = despues == null
                ? mensajes.anteriores(id, antes, PageRequest.of(0, TAMANO + 1))
                : mensajes.nuevos(id, despues, PageRequest.of(0, TAMANO + 1));
        boolean hayMas = encontrados.size() > TAMANO;
        List<MensajeReserva> pagina = new ArrayList<>(
                encontrados.subList(0, Math.min(TAMANO, encontrados.size())));
        if (despues == null) Collections.reverse(pagina);
        boolean huesped = usuario.getIdUsuario().equals(reserva.getHuesped().getIdUsuario());
        String interlocutor = huesped
                ? reserva.getAlojamiento().getAnfitrion().getNombre()
                : reserva.getHuesped().getNombre();
        return new ConversacionReservaResponse(
                id, reserva.getCodigo(), reserva.getAlojamiento().getTitulo(), interlocutor,
                pagina.stream().map(m -> MensajeReservaResponse.desde(m, usuario.getIdUsuario())).toList(),
                hayMas);
    }

    public MensajeReservaResponse enviar(Long id, MensajeReservaRequest datos, String correo) {
        Usuario usuario = usuarioActivo(correo);
        Reserva reserva = reservaPropia(id, usuario);
        String texto = datos.contenido() == null ? "" : datos.contenido().strip();
        String clave;
        try {
            clave = UUID.fromString(datos.claveCliente()).toString();
        } catch (IllegalArgumentException | NullPointerException ex) {
            throw error(HttpStatus.BAD_REQUEST, "La identificación del mensaje no es válida.");
        }
        if (texto.isBlank() || texto.length() > 2000) {
            throw error(HttpStatus.BAD_REQUEST, "Escribe un mensaje de 1 a 2000 caracteres.");
        }

        reservas.bloquear(id).orElseThrow(() -> error(HttpStatus.NOT_FOUND, "La reserva no existe."));
        var existente = mensajes.findByReserva_IdReservaAndRemitente_IdUsuarioAndClaveCliente(
                id, usuario.getIdUsuario(), clave);
        if (existente.isPresent()) {
            if (!existente.get().getContenido().equals(texto)) {
                throw error(HttpStatus.CONFLICT, "Ese identificador ya corresponde a otro mensaje.");
            }
            return MensajeReservaResponse.desde(existente.get(), usuario.getIdUsuario());
        }
        MensajeReserva mensaje = new MensajeReserva();
        mensaje.setReserva(reserva);
        mensaje.setRemitente(usuario);
        mensaje.setContenido(texto);
        mensaje.setClaveCliente(clave);
        MensajeReserva guardado = mensajes.saveAndFlush(mensaje);
        notificarDestinatario(reserva, usuario, texto);
        return MensajeReservaResponse.desde(guardado, usuario.getIdUsuario());
    }

    // Mensaje y aviso se guardan en la misma transacción.
    // El retorno por claveCliente existente ocurre antes de crear este aviso.
    private void notificarDestinatario(Reserva reserva, Usuario remitente, String texto) {
        boolean escribeHuesped = remitente.getIdUsuario()
                .equals(reserva.getHuesped().getIdUsuario());
        Usuario destinatario = escribeHuesped
                ? reserva.getAlojamiento().getAnfitrion()
                : reserva.getHuesped();

        if (destinatario.getIdUsuario().equals(remitente.getIdUsuario())) return;

        Notificacion aviso = new Notificacion();
        aviso.setUsuario(destinatario);
        aviso.setTipo("MENSAJE_CHAT");
        aviso.setTitulo(recortar("Nuevo mensaje de " + remitente.getNombre(), 120));
        aviso.setMensaje(recortar(
                "Reserva " + reserva.getCodigo() + " · "
                        + reserva.getAlojamiento().getTitulo() + ": "
                        + texto.replaceAll("\\s+", " "),
                500));
        aviso.setEntidad("RESERVA");
        aviso.setEntidadId(reserva.getIdReserva());
        aviso.setLeida(false);
        notificaciones.save(aviso);
    }

    private static String recortar(String valor, int limite) {
        int cantidad = valor.codePointCount(0, valor.length());
        if (cantidad <= limite) return valor;
        return valor.substring(0, valor.offsetByCodePoints(0, limite - 1)) + "…";
    }

    private Usuario usuarioActivo(String correo) {
        Usuario usuario = usuarios.findByCorreoIgnoreCase(correo)
                .orElseThrow(() -> error(HttpStatus.UNAUTHORIZED, "Inicia sesión de nuevo."));
        if (usuario.getEstado() != EstadoUsuario.ACTIVA) {
            throw error(HttpStatus.FORBIDDEN, "Tu cuenta no puede utilizar el chat.");
        }
        return usuario;
    }

    private Reserva reservaPropia(Long id, Usuario usuario) {
        Reserva reserva = reservas.buscar(id)
                .orElseThrow(() -> error(HttpStatus.NOT_FOUND, "La reserva no existe."));
        Long propio = usuario.getIdUsuario();
        if (!propio.equals(reserva.getHuesped().getIdUsuario())
                && !propio.equals(reserva.getAlojamiento().getAnfitrion().getIdUsuario())) {
            throw error(HttpStatus.FORBIDDEN, "No tienes acceso al chat de esta reserva.");
        }
        return reserva;
    }

    private static ResponseStatusException error(HttpStatus estado, String mensaje) {
        return new ResponseStatusException(estado, mensaje);
    }
}
