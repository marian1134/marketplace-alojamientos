package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.ConversacionReservaResponse;
import com.inversioneslr.marketplace.dto.MensajeReservaRequest;
import com.inversioneslr.marketplace.dto.MensajeReservaResponse;
import com.inversioneslr.marketplace.model.*;
import com.inversioneslr.marketplace.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

// HU del chat de la reserva: huésped y anfitrión conversan sobre una reserva (prueba unitaria, sin base de datos)
class ChatReservaServiceTest {

    private ChatReservaRepository reservas;
    private MensajeReservaRepository mensajes;
    private UsuarioRepository usuarios;
    private NotificacionRepository notificaciones;
    private ChatReservaService servicio;

    private Usuario huesped;
    private Usuario anfitrion;
    private Usuario extrano;
    private Reserva reserva;

    @BeforeEach
    void preparar() {
        reservas = mock(ChatReservaRepository.class);
        mensajes = mock(MensajeReservaRepository.class);
        usuarios = mock(UsuarioRepository.class);
        notificaciones = mock(NotificacionRepository.class);
        servicio = new ChatReservaService(reservas, mensajes, usuarios, notificaciones);

        huesped = usuario(1L, "Ana Huésped", "ana@correo.com");
        anfitrion = usuario(2L, "Luis Anfitrión", "luis@correo.com");
        extrano = usuario(3L, "Otra Persona", "otra@correo.com");

        Alojamiento alojamiento = new Alojamiento();
        alojamiento.setTitulo("Cabaña en Guatapé");
        alojamiento.setAnfitrion(anfitrion);

        reserva = new Reserva();
        ReflectionTestUtils.setField(reserva, "idReserva", 10L);
        reserva.setCodigo("RES-0010");
        reserva.setHuesped(huesped);
        reserva.setAlojamiento(alojamiento);

        when(reservas.buscar(10L)).thenReturn(Optional.of(reserva));
        when(reservas.bloquear(10L)).thenReturn(Optional.of(reserva));
        when(mensajes.saveAndFlush(any(MensajeReserva.class))).thenAnswer(i -> {
            MensajeReserva m = i.getArgument(0);
            ReflectionTestUtils.setField(m, "idMensaje", 99L);
            return m;
        });
    }

    private Usuario usuario(Long id, String nombre, String correo) {
        Usuario u = new Usuario();
        u.setIdUsuario(id);
        u.setNombre(nombre);
        u.setCorreo(correo);
        u.setEstado(EstadoUsuario.ACTIVA);
        when(usuarios.findByCorreoIgnoreCase(correo)).thenReturn(Optional.of(u));
        return u;
    }

    private MensajeReserva mensaje(long id, Usuario remitente, String texto) {
        MensajeReserva m = new MensajeReserva();
        ReflectionTestUtils.setField(m, "idMensaje", id);
        m.setReserva(reserva);
        m.setRemitente(remitente);
        m.setContenido(texto);
        m.setClaveCliente(UUID.randomUUID().toString());
        return m;
    }

    private List<MensajeReserva> mensajesDescendentes(int cantidad) {
        List<MensajeReserva> lista = new ArrayList<>();
        for (int i = cantidad; i >= 1; i--) lista.add(mensaje(i, huesped, "Mensaje " + i));
        return lista;
    }

    private static MensajeReservaRequest pedido(String texto) {
        return new MensajeReservaRequest(texto, UUID.randomUUID().toString());
    }

    private static HttpStatus estadoDe(Throwable t) {
        return HttpStatus.valueOf(((ResponseStatusException) t).getStatusCode().value());
    }

    // ---------- Acceso al chat ----------

    @Test
    @DisplayName("El huésped ve la conversación con el nombre del anfitrión")
    void huespedVeConversacion() {
        when(mensajes.anteriores(eq(10L), isNull(), any(Pageable.class)))
                .thenReturn(List.of(mensaje(2, anfitrion, "Hola"), mensaje(1, huesped, "Buenas")));

        ConversacionReservaResponse r = servicio.listar(10L, null, null, "ana@correo.com");

        assertThat(r.codigoReserva()).isEqualTo("RES-0010");
        assertThat(r.tituloAlojamiento()).isEqualTo("Cabaña en Guatapé");
        assertThat(r.interlocutor()).isEqualTo("Luis Anfitrión");
        assertThat(r.mensajes()).hasSize(2);
    }

    @Test
    @DisplayName("El anfitrión ve la conversación con el nombre del huésped")
    void anfitrionVeConversacion() {
        when(mensajes.anteriores(eq(10L), isNull(), any(Pageable.class))).thenReturn(List.of());

        ConversacionReservaResponse r = servicio.listar(10L, null, null, "luis@correo.com");

        assertThat(r.interlocutor()).isEqualTo("Ana Huésped");
    }

    @Test
    @DisplayName("Un usuario que no es parte de la reserva no puede ver el chat")
    void extranoNoVeChat() {
        assertThatThrownBy(() -> servicio.listar(10L, null, null, "otra@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.FORBIDDEN));
    }

    @Test
    @DisplayName("Una reserva que no existe responde 404")
    void reservaInexistente() {
        when(reservas.buscar(77L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> servicio.listar(77L, null, null, "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    @DisplayName("Sin una sesión válida pide iniciar sesión de nuevo")
    void sinSesion() {
        when(usuarios.findByCorreoIgnoreCase("nadie@correo.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> servicio.listar(10L, null, null, "nadie@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.UNAUTHORIZED));
    }

    @Test
    @DisplayName("Una cuenta restringida no puede usar el chat")
    void cuentaRestringida() {
        huesped.setEstado(EstadoUsuario.RESTRINGIDA);

        assertThatThrownBy(() -> servicio.listar(10L, null, null, "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.FORBIDDEN));
    }

    // ---------- Paginación ----------

    @Test
    @DisplayName("Los mensajes se muestran del más antiguo al más reciente")
    void ordenCronologico() {
        when(mensajes.anteriores(eq(10L), isNull(), any(Pageable.class))).thenReturn(mensajesDescendentes(3));

        ConversacionReservaResponse r = servicio.listar(10L, null, null, "ana@correo.com");

        assertThat(r.mensajes()).extracting(MensajeReservaResponse::id).containsExactly(1L, 2L, 3L);
        assertThat(r.hayMas()).isFalse();
    }

    @Test
    @DisplayName("Se muestran 50 mensajes por página y avisa si hay más")
    void paginaDeCincuenta() {
        when(mensajes.anteriores(eq(10L), isNull(), any(Pageable.class))).thenReturn(mensajesDescendentes(51));

        ConversacionReservaResponse r = servicio.listar(10L, null, null, "ana@correo.com");

        assertThat(r.mensajes()).hasSize(50);
        assertThat(r.hayMas()).isTrue();
    }

    @Test
    @DisplayName("Consultar los mensajes nuevos usa el cursor 'después' y conserva el orden")
    void mensajesNuevos() {
        when(mensajes.nuevos(eq(10L), eq(5L), any(Pageable.class)))
                .thenReturn(List.of(mensaje(6, anfitrion, "a"), mensaje(7, huesped, "b")));

        ConversacionReservaResponse r = servicio.listar(10L, null, 5L, "ana@correo.com");

        assertThat(r.mensajes()).extracting(MensajeReservaResponse::id).containsExactly(6L, 7L);
        verify(mensajes, never()).anteriores(any(), any(), any());
    }

    @Test
    @DisplayName("No se pueden usar los dos cursores a la vez")
    void dosCursores() {
        assertThatThrownBy(() -> servicio.listar(10L, 5L, 2L, "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    @DisplayName("Un cursor negativo o cero es inválido")
    void cursorInvalido() {
        assertThatThrownBy(() -> servicio.listar(10L, 0L, null, "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.BAD_REQUEST));
        assertThatThrownBy(() -> servicio.listar(10L, null, -1L, "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    @DisplayName("Cada mensaje indica si lo escribió el usuario que consulta")
    void marcaMensajesPropios() {
        when(mensajes.anteriores(eq(10L), isNull(), any(Pageable.class)))
                .thenReturn(List.of(mensaje(2, anfitrion, "Hola"), mensaje(1, huesped, "Buenas")));

        ConversacionReservaResponse r = servicio.listar(10L, null, null, "ana@correo.com");

        assertThat(r.mensajes()).extracting(MensajeReservaResponse::propio).containsExactly(true, false);
    }

    // ---------- Envío de mensajes ----------

    @Test
    @DisplayName("El huésped envía un mensaje y se guarda sin espacios sobrantes")
    void enviarMensaje() {
        MensajeReservaResponse r = servicio.enviar(10L, pedido("  ¿A qué hora es el check-in?  "), "ana@correo.com");

        assertThat(r.id()).isEqualTo(99L);
        assertThat(r.contenido()).isEqualTo("¿A qué hora es el check-in?");
        assertThat(r.propio()).isTrue();
        verify(reservas).bloquear(10L);
    }

    @Test
    @DisplayName("No se permite enviar un mensaje vacío")
    void mensajeVacio() {
        assertThatThrownBy(() -> servicio.enviar(10L, pedido("   "), "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.BAD_REQUEST));
        verify(mensajes, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("No se permite un mensaje de más de 2000 caracteres")
    void mensajeMuyLargo() {
        assertThatThrownBy(() -> servicio.enviar(10L, pedido("x".repeat(2001)), "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    @DisplayName("La identificación del mensaje debe ser un UUID válido")
    void claveInvalida() {
        assertThatThrownBy(() -> servicio.enviar(10L, new MensajeReservaRequest("Hola", "no-es-uuid"), "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    @DisplayName("Si el mensaje se reenvía (doble clic), no se duplica")
    void reintentoNoDuplica() {
        String clave = UUID.randomUUID().toString();
        MensajeReserva existente = mensaje(50, huesped, "Hola");
        when(mensajes.findByReserva_IdReservaAndRemitente_IdUsuarioAndClaveCliente(10L, 1L, clave))
                .thenReturn(Optional.of(existente));

        MensajeReservaResponse r = servicio.enviar(10L, new MensajeReservaRequest("Hola", clave), "ana@correo.com");

        assertThat(r.id()).isEqualTo(50L);
        verify(mensajes, never()).saveAndFlush(any());
        verify(notificaciones, never()).save(any());
    }

    @Test
    @DisplayName("La misma identificación con otro texto responde conflicto")
    void claveRepetidaOtroTexto() {
        String clave = UUID.randomUUID().toString();
        when(mensajes.findByReserva_IdReservaAndRemitente_IdUsuarioAndClaveCliente(10L, 1L, clave))
                .thenReturn(Optional.of(mensaje(50, huesped, "Hola")));

        assertThatThrownBy(() -> servicio.enviar(10L, new MensajeReservaRequest("Otro texto", clave), "ana@correo.com"))
                .satisfies(e -> assertThat(estadoDe(e)).isEqualTo(HttpStatus.CONFLICT));
    }

    // ---------- Notificaciones ----------

    @Test
    @DisplayName("Cuando el huésped escribe, el anfitrión recibe una notificación")
    void notificaAlAnfitrion() {
        servicio.enviar(10L, pedido("Llego a las 3 pm"), "ana@correo.com");

        ArgumentCaptor<Notificacion> aviso = ArgumentCaptor.forClass(Notificacion.class);
        verify(notificaciones).save(aviso.capture());
        assertThat(aviso.getValue().getUsuario()).isSameAs(anfitrion);
        assertThat(aviso.getValue().getTipo()).isEqualTo("MENSAJE_CHAT");
        assertThat(aviso.getValue().getTitulo()).isEqualTo("Nuevo mensaje de Ana Huésped");
        assertThat(aviso.getValue().getMensaje()).contains("RES-0010", "Cabaña en Guatapé", "Llego a las 3 pm");
        assertThat(aviso.getValue().getEntidadId()).isEqualTo(10L);
    }

    @Test
    @DisplayName("Cuando el anfitrión responde, el huésped recibe la notificación y un texto largo se recorta")
    void notificaAlHuespedYRecorta() {
        servicio.enviar(10L, pedido("a".repeat(1500)), "luis@correo.com");

        ArgumentCaptor<Notificacion> aviso = ArgumentCaptor.forClass(Notificacion.class);
        verify(notificaciones).save(aviso.capture());
        assertThat(aviso.getValue().getUsuario()).isSameAs(huesped);
        assertThat(aviso.getValue().getMensaje()).hasSize(500).endsWith("…");
    }
}
