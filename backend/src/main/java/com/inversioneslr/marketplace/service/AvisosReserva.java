package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.model.Alojamiento;
import com.inversioneslr.marketplace.model.CorreoEnviado;
import com.inversioneslr.marketplace.model.EstadoReserva;
import com.inversioneslr.marketplace.model.Notificacion;
import com.inversioneslr.marketplace.model.Pago;
import com.inversioneslr.marketplace.model.Reserva;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.CorreoEnviadoRepository;
import com.inversioneslr.marketplace.repository.NotificacionRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

// Avisos al huésped y al anfitrión cuando una reserva se crea, se aprueba,
// se rechaza o se cancela. Cada aviso queda guardado en `notificacion`
// y en `correo_enviado`, y luego se envía por correo.
@Service
public class AvisosReserva {

    private static final Locale COLOMBIA = Locale.forLanguageTag("es-CO");

    private static final DateTimeFormatter FECHA =
            DateTimeFormatter.ofPattern("d 'de' MMMM 'de' yyyy", COLOMBIA);

    private static final String FIRMA = "\n\nEquipo StayHub";

    private final ApplicationEventPublisher publicador;
    private final NotificacionRepository notificacionRepository;
    private final CorreoEnviadoRepository correoRepository;

    public AvisosReserva(
            ApplicationEventPublisher publicador,
            NotificacionRepository notificacionRepository,
            CorreoEnviadoRepository correoRepository) {

        this.publicador = publicador;
        this.notificacionRepository = notificacionRepository;
        this.correoRepository = correoRepository;
    }

    // El huésped pagó: reserva confirmada o solicitud enviada al anfitrión
    public void reservaCreada(Reserva reserva, Pago pago, BigDecimal total) {

        Usuario huesped = reserva.getHuesped();
        Usuario anfitrion = reserva.getAlojamiento().getAnfitrion();
        boolean confirmada = reserva.getEstado() == EstadoReserva.CONFIRMADA;

        String pagoTexto = "\n\nPago recibido\n"
                + "Total pagado: " + dinero(total) + "\n"
                + "Tarjeta terminada en " + pago.getUltimos4() + "\n"
                + "Referencia del pago: " + pago.getReferencia();

        if (confirmada) {
            avisar(huesped, "RESERVA_CONFIRMADA", reserva,
                    "Tu reserva " + reserva.getCodigo() + " está confirmada",
                    "Tu reserva en " + titulo(reserva) + " está confirmada. "
                            + "Pagaste " + dinero(total) + ".",
                    "Hola, " + huesped.getNombre() + ".\n\n"
                            + "¡Tu reserva está confirmada! Estos son los datos:"
                            + datosReserva(reserva)
                            + pagoTexto
                            + "\n\nAnfitrión: " + anfitrion.getNombre()
                            + "\n\n¡Buen viaje!");

            avisar(anfitrion, "NUEVA_RESERVA", reserva,
                    "Nueva reserva " + reserva.getCodigo() + " en " + titulo(reserva),
                    huesped.getNombre() + " reservó y pagó " + titulo(reserva)
                            + " (" + fechas(reserva) + ").",
                    "Hola, " + anfitrion.getNombre() + ".\n\n"
                            + huesped.getNombre() + " reservó y pagó tu alojamiento."
                            + datosReserva(reserva)
                            + "\nTotal pagado por el huésped: " + dinero(total));
        } else {
            avisar(huesped, "SOLICITUD_ENVIADA", reserva,
                    "Recibimos tu solicitud de reserva " + reserva.getCodigo(),
                    "Tu solicitud para " + titulo(reserva)
                            + " está esperando la aprobación del anfitrión.",
                    "Hola, " + huesped.getNombre() + ".\n\n"
                            + "Tu pago fue recibido y la solicitud se envió al anfitrión. "
                            + "Te avisaremos por correo cuando la apruebe o la rechace. "
                            + "Si la rechaza, se te devuelve todo el dinero."
                            + datosReserva(reserva)
                            + pagoTexto);

            avisar(anfitrion, "SOLICITUD_RECIBIDA", reserva,
                    "Tienes una solicitud de reserva por aprobar: " + reserva.getCodigo(),
                    huesped.getNombre() + " quiere reservar " + titulo(reserva)
                            + " (" + fechas(reserva) + "). Apruébala o recházala.",
                    "Hola, " + anfitrion.getNombre() + ".\n\n"
                            + huesped.getNombre() + " quiere reservar tu alojamiento y ya pagó."
                            + datosReserva(reserva)
                            + "\nTotal pagado por el huésped: " + dinero(total)
                            + "\n\nEntra a tu panel de anfitrión en StayHub "
                            + "para aprobar o rechazar la solicitud.");
        }
    }

    // El anfitrión aprobó la solicitud
    public void reservaAprobada(Reserva reserva) {

        Usuario huesped = reserva.getHuesped();

        avisar(huesped, "RESERVA_APROBADA", reserva,
                "Tu reserva " + reserva.getCodigo() + " fue aprobada",
                "El anfitrión aprobó tu reserva en " + titulo(reserva) + ".",
                "Hola, " + huesped.getNombre() + ".\n\n"
                        + "¡Buenas noticias! El anfitrión aprobó tu solicitud "
                        + "y tu reserva está confirmada."
                        + datosReserva(reserva)
                        + "\n\n¡Buen viaje!");
    }

    // El anfitrión rechazó la solicitud: se devuelve todo
    public void reservaRechazada(Reserva reserva, BigDecimal devolucion) {

        Usuario huesped = reserva.getHuesped();

        avisar(huesped, "RESERVA_RECHAZADA", reserva,
                "Tu solicitud de reserva " + reserva.getCodigo() + " fue rechazada",
                "El anfitrión rechazó tu solicitud para " + titulo(reserva)
                        + ". Te devolvemos " + dinero(devolucion) + ".",
                "Hola, " + huesped.getNombre() + ".\n\n"
                        + "El anfitrión no pudo aceptar tu solicitud."
                        + datosReserva(reserva)
                        + "\nMotivo: " + reserva.getMotivoRechazo()
                        + "\n\nTe devolveremos " + dinero(devolucion)
                        + " a la misma tarjeta con la que pagaste.");
    }

    // El huésped canceló su reserva
    public void reservaCancelada(Reserva reserva, String motivo, BigDecimal devolucion) {

        Usuario huesped = reserva.getHuesped();
        Usuario anfitrion = reserva.getAlojamiento().getAnfitrion();

        String devolucionTexto = devolucion.signum() > 0
                ? "Te devolveremos " + dinero(devolucion)
                        + " a la misma tarjeta con la que pagaste."
                : "Según la política de cancelación del alojamiento, "
                        + "esta cancelación no tiene devolución.";

        avisar(huesped, "RESERVA_CANCELADA", reserva,
                "Cancelaste tu reserva " + reserva.getCodigo(),
                "Cancelaste tu reserva en " + titulo(reserva)
                        + ". Devolución: " + dinero(devolucion) + ".",
                "Hola, " + huesped.getNombre() + ".\n\n"
                        + "Tu reserva quedó cancelada."
                        + datosReserva(reserva)
                        + "\n\n" + devolucionTexto);

        avisar(anfitrion, "CANCELACION_RECIBIDA", reserva,
                "El huésped canceló la reserva " + reserva.getCodigo(),
                huesped.getNombre() + " canceló su reserva en " + titulo(reserva)
                        + " (" + fechas(reserva) + ").",
                "Hola, " + anfitrion.getNombre() + ".\n\n"
                        + huesped.getNombre() + " canceló su reserva en tu alojamiento."
                        + datosReserva(reserva)
                        + "\nMotivo: " + motivo
                        + "\n\nEsas fechas pueden volver a estar disponibles "
                        + "según tu política de cancelación.");
    }

    // ------------------------------------------------------------------

    // Guarda la notificación y el registro del correo (en la misma
    // transacción de la reserva) y deja el correo listo para enviarse.
    private void avisar(
            Usuario usuario,
            String tipo,
            Reserva reserva,
            String asunto,
            String resumen,
            String texto) {

        Notificacion notificacion = new Notificacion();
        notificacion.setUsuario(usuario);
        notificacion.setTipo(tipo);
        notificacion.setTitulo(recortar(asunto, 120));
        notificacion.setMensaje(recortar(resumen, 500));
        notificacion.setEntidad("RESERVA");
        notificacion.setEntidadId(reserva.getIdReserva());
        notificacionRepository.save(notificacion);

        CorreoEnviado correo = new CorreoEnviado();
        correo.setNotificacion(notificacion);
        correo.setDestinatario(usuario.getCorreo());
        correo.setAsunto(recortar(asunto, 150));
        correoRepository.save(correo);

        publicador.publishEvent(new CorreoPendiente(
                correo.getIdCorreo(),
                usuario.getCorreo(),
                correo.getAsunto(),
                texto + FIRMA
        ));
    }

    private String datosReserva(Reserva reserva) {

        Alojamiento alojamiento = reserva.getAlojamiento();

        return "\n\nCódigo de reserva: " + reserva.getCodigo() + "\n"
                + "Alojamiento: " + alojamiento.getTitulo()
                + " (" + alojamiento.getCiudad() + ")\n"
                + "Llegada: " + reserva.getFechaLlegada().format(FECHA) + "\n"
                + "Salida: " + reserva.getFechaSalida().format(FECHA) + "\n"
                + "Huéspedes: " + reserva.getCantidadHuespedes() + "\n";
    }

    private String fechas(Reserva reserva) {
        return reserva.getFechaLlegada().format(FECHA)
                + " al " + reserva.getFechaSalida().format(FECHA);
    }

    private String titulo(Reserva reserva) {
        return reserva.getAlojamiento().getTitulo();
    }

    private String dinero(BigDecimal valor) {

        NumberFormat formato = NumberFormat.getCurrencyInstance(COLOMBIA);
        formato.setMaximumFractionDigits(0);

        return formato.format(valor) + " COP";
    }

    private static String recortar(String texto, int maximo) {
        return texto.length() <= maximo ? texto : texto.substring(0, maximo - 1) + "…";
    }
}
