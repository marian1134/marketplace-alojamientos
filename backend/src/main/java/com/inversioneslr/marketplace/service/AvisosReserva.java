package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.model.Alojamiento;
import com.inversioneslr.marketplace.model.CorreoEnviado;
import com.inversioneslr.marketplace.model.Cotizacion;
import com.inversioneslr.marketplace.model.EstadoReserva;
import com.inversioneslr.marketplace.model.Notificacion;
import com.inversioneslr.marketplace.model.Pago;
import com.inversioneslr.marketplace.model.Reserva;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.CorreoEnviadoRepository;
import com.inversioneslr.marketplace.repository.NotificacionRepository;
import org.springframework.beans.factory.annotation.Value;
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

    private static final DateTimeFormatter FECHA_HORA =
            DateTimeFormatter.ofPattern("d 'de' MMMM 'de' yyyy, h:mm a", COLOMBIA);

    private static final String FIRMA = "\n\nEquipo StayHub";

    private static final DateTimeFormatter HORA =
            DateTimeFormatter.ofPattern("h:mm a", COLOMBIA);

    private final ApplicationEventPublisher publicador;
    private final NotificacionRepository notificacionRepository;
    private final CorreoEnviadoRepository correoRepository;

    // Enlaces de los botones: "Mis viajes" del huésped y panel del anfitrión
    private final String enlaceViajes;
    private final String enlacePanel;

    public AvisosReserva(
            ApplicationEventPublisher publicador,
            NotificacionRepository notificacionRepository,
            CorreoEnviadoRepository correoRepository,
            @Value("${app.url-frontend:http://localhost:5173}") String urlFrontend) {

        this.publicador = publicador;
        this.notificacionRepository = notificacionRepository;
        this.correoRepository = correoRepository;
        this.enlaceViajes = urlFrontend + "/?ir=viajes";
        this.enlacePanel = urlFrontend + "/?ir=panel";
    }

    // El huésped pagó: reserva confirmada o solicitud enviada al anfitrión
    public void reservaCreada(Reserva reserva, Pago pago, Cotizacion cotizacion) {

        Usuario huesped = reserva.getHuesped();
        Usuario anfitrion = reserva.getAlojamiento().getAnfitrion();
        boolean confirmada = reserva.getEstado() == EstadoReserva.CONFIRMADA;
        BigDecimal total = pago.getMonto();
        String moneda = pago.getMoneda();

        String pagoTexto = "\n\nPago recibido\n"
                + "Total pagado: " + dinero(total, moneda) + "\n"
                + "Tarjeta terminada en " + pago.getUltimos4() + "\n"
                + "Referencia del pago: " + pago.getReferencia();

        comprobantePago(reserva, pago, cotizacion);

        if (confirmada) {
            avisar(huesped, "RESERVA_CONFIRMADA", reserva,
                    "Tu reserva " + reserva.getCodigo() + " está confirmada",
                    "Tu reserva en " + titulo(reserva) + " está confirmada. "
                            + "Pagaste " + dinero(total, moneda) + ".",
                    "Hola, " + huesped.getNombre() + ".\n\n"
                            + "¡Tu reserva está confirmada! Estos son los datos:"
                            + datosReserva(reserva)
                            + pagoTexto
                            + "\n\nAnfitrión: " + anfitrion.getNombre()
                            + checkInTexto(reserva)
                            + "\n\n¡Buen viaje!",
                    "Ver mi reserva", enlaceViajes);

            avisar(anfitrion, "NUEVA_RESERVA", reserva,
                    "Nueva reserva " + reserva.getCodigo() + " en " + titulo(reserva),
                    huesped.getNombre() + " reservó y pagó " + titulo(reserva)
                            + " (" + fechas(reserva) + ").",
                    "Hola, " + anfitrion.getNombre() + ".\n\n"
                            + huesped.getNombre() + " reservó y pagó tu alojamiento."
                            + datosReserva(reserva)
                            + "Hora de check-in: desde las " + horaCheckIn(reserva) + "\n"
                            + "\nTotal pagado por el huésped: " + dinero(total, moneda)
                            + "\n\nTe avisaremos por correo cuando el huésped haga su check-in.",
                    "Ir a mi panel", enlacePanel);
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
                            + "\nTotal pagado por el huésped: " + dinero(total, moneda)
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
                        + checkInTexto(reserva)
                        + "\n\n¡Buen viaje!",
                "Ver mi reserva", enlaceViajes);
    }

    // Un día antes de la llegada
    public void recordatorioCheckIn(Reserva reserva) {

        Usuario huesped = reserva.getHuesped();

        avisar(huesped, "RECORDATORIO_CHECK_IN", reserva,
                "Mañana llegas a " + titulo(reserva) + ": recuerda tu check-in",
                "Mañana es tu llegada a " + titulo(reserva)
                        + ". Haz tu check-in desde las " + horaCheckIn(reserva) + ".",
                "Hola, " + huesped.getNombre() + ".\n\n"
                        + "¡Mañana empieza tu viaje!"
                        + datosReserva(reserva)
                        + checkInTexto(reserva),
                "Ver mi reserva", enlaceViajes);
    }

    // El huésped hizo check-in: confirmación para él y aviso al anfitrión
    public void checkInRealizado(Reserva reserva) {

        Usuario huesped = reserva.getHuesped();
        Usuario anfitrion = reserva.getAlojamiento().getAnfitrion();
        String hora = reserva.getCheckInEn().toLocalTime().format(HORA);

        avisar(huesped, "CHECK_IN_CONFIRMADO", reserva,
                "Check-in confirmado: " + titulo(reserva),
                "Hiciste check-in en " + titulo(reserva) + " a las " + hora + ".",
                "Hola, " + huesped.getNombre() + ".\n\n"
                        + "Tu check-in quedó registrado a las " + hora
                        + ". ¡Disfruta tu estadía!"
                        + datosReserva(reserva),
                null, null);

        avisar(anfitrion, "CHECK_IN_HUESPED", reserva,
                huesped.getNombre() + " hizo check-in en " + titulo(reserva),
                huesped.getNombre() + " hizo check-in a las " + hora + ".",
                "Hola, " + anfitrion.getNombre() + ".\n\n"
                        + huesped.getNombre() + " hizo check-in en tu alojamiento a las "
                        + hora + "."
                        + datosReserva(reserva),
                "Ir a mi panel", enlacePanel);
    }

    // El anfitrión canceló porque el huésped no hizo check-in
    public void noSePresento(Reserva reserva, BigDecimal devolucion, String moneda) {

        Usuario huesped = reserva.getHuesped();
        Usuario anfitrion = reserva.getAlojamiento().getAnfitrion();

        String devolucionTexto = devolucion.signum() > 0
                ? "Según la política de cancelación, te devolveremos "
                        + dinero(devolucion, moneda) + " a la misma tarjeta con la que pagaste."
                : "Según la política de cancelación del alojamiento, "
                        + "esta cancelación no tiene devolución.";

        avisar(huesped, "CANCELADA_NO_SE_PRESENTO", reserva,
                "Tu reserva " + reserva.getCodigo() + " fue cancelada por no hacer check-in",
                "El anfitrión canceló tu reserva en " + titulo(reserva)
                        + " porque no hiciste check-in.",
                "Hola, " + huesped.getNombre() + ".\n\n"
                        + "No registramos tu check-in el día de llegada, así que el "
                        + "anfitrión canceló la reserva."
                        + datosReserva(reserva)
                        + "\n" + devolucionTexto,
                null, null);

        avisar(anfitrion, "NO_SE_PRESENTO_CONFIRMADO", reserva,
                "Cancelaste la reserva " + reserva.getCodigo() + " por no presentarse",
                "Cancelaste la reserva de " + huesped.getNombre()
                        + ". Las fechas quedaron libres.",
                "Hola, " + anfitrion.getNombre() + ".\n\n"
                        + "La reserva de " + huesped.getNombre()
                        + " quedó cancelada porque no hizo check-in."
                        + datosReserva(reserva)
                        + "\nEsas fechas ya están libres para nuevas reservas.",
                null, null);
    }

    // El anfitrión rechazó la solicitud: se devuelve todo
    public void reservaRechazada(Reserva reserva, BigDecimal devolucion, String moneda) {

        Usuario huesped = reserva.getHuesped();

        avisar(huesped, "RESERVA_RECHAZADA", reserva,
                "Tu solicitud de reserva " + reserva.getCodigo() + " fue rechazada",
                "El anfitrión rechazó tu solicitud para " + titulo(reserva)
                        + ". Te devolvemos " + dinero(devolucion, moneda) + ".",
                "Hola, " + huesped.getNombre() + ".\n\n"
                        + "El anfitrión no pudo aceptar tu solicitud."
                        + datosReserva(reserva)
                        + "\nMotivo: " + reserva.getMotivoRechazo()
                        + "\n\nTe devolveremos " + dinero(devolucion, moneda)
                        + " a la misma tarjeta con la que pagaste.");
    }

    // El huésped canceló su reserva
    public void reservaCancelada(
            Reserva reserva,
            String motivo,
            BigDecimal devolucion,
            String moneda) {

        Usuario huesped = reserva.getHuesped();
        Usuario anfitrion = reserva.getAlojamiento().getAnfitrion();

        String devolucionTexto = devolucion.signum() > 0
                ? "Te devolveremos " + dinero(devolucion, moneda)
                        + " a la misma tarjeta con la que pagaste."
                : "Según la política de cancelación del alojamiento, "
                        + "esta cancelación no tiene devolución.";

        avisar(huesped, "RESERVA_CANCELADA", reserva,
                "Cancelaste tu reserva " + reserva.getCodigo(),
                "Cancelaste tu reserva en " + titulo(reserva)
                        + ". Devolución: " + dinero(devolucion, moneda) + ".",
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

    // Comprobante de pago: correo aparte con el desglose del cobro
    private void comprobantePago(Reserva reserva, Pago pago, Cotizacion cotizacion) {

        Usuario huesped = reserva.getHuesped();
        long noches = java.time.temporal.ChronoUnit.DAYS.between(
                reserva.getFechaLlegada(),
                reserva.getFechaSalida()
        );

        BigDecimal subtotal = cotizacion.getPrecioNoche()
                .multiply(BigDecimal.valueOf(noches));

        String conversion = "USD".equals(pago.getMoneda())
                ? "\nTotal en pesos: " + dinero(cotizacion.getTotal(), "COP")
                        + "\nCobrado en dólares: " + dinero(pago.getMonto(), "USD")
                : "";

        String texto = "Hola, " + huesped.getNombre() + ".\n\n"
                + "Este es el comprobante de tu pago en StayHub."
                + "\n\nCOMPROBANTE DE PAGO"
                + "\nNúmero de comprobante: " + pago.getReferencia()
                + "\nFecha del pago: " + java.time.LocalDateTime.now(java.time.ZoneId.of("America/Bogota")).format(FECHA_HORA)
                + "\nMétodo de pago: tarjeta terminada en " + pago.getUltimos4()
                + "\nMoneda: " + nombreMoneda(pago.getMoneda())
                + datosReserva(reserva)
                + "\nDETALLE DEL COBRO"
                + "\n" + dinero(cotizacion.getPrecioNoche(), "COP") + " x " + noches
                + (noches == 1 ? " noche" : " noches") + ": " + dinero(subtotal, "COP")
                + "\nTarifa de limpieza: " + dinero(cotizacion.getTarifaLimpieza(), "COP")
                + "\nTarifa de servicio StayHub: " + dinero(cotizacion.getTarifaServicio(), "COP")
                + (cotizacion.getDescuentos().signum() > 0
                        ? "\nDescuento: -" + dinero(cotizacion.getDescuentos(), "COP")
                        : "")
                + conversion
                + "\n\nTOTAL PAGADO: " + dinero(pago.getMonto(), pago.getMoneda())
                + "\n\nGuarda este correo como soporte de tu pago.";

        avisar(huesped, "COMPROBANTE_PAGO", reserva,
                "Comprobante de pago - reserva " + reserva.getCodigo(),
                "Pagaste " + dinero(pago.getMonto(), pago.getMoneda())
                        + " por tu reserva en " + titulo(reserva) + ".",
                texto);
    }

    // ------------------------------------------------------------------

    private void avisar(
            Usuario usuario,
            String tipo,
            Reserva reserva,
            String asunto,
            String resumen,
            String texto) {

        avisar(usuario, tipo, reserva, asunto, resumen, texto, null, null);
    }

    // Guarda la notificación y el registro del correo (en la misma
    // transacción de la reserva) y deja el correo listo para enviarse.
    private void avisar(
            Usuario usuario,
            String tipo,
            Reserva reserva,
            String asunto,
            String resumen,
            String texto,
            String botonTexto,
            String botonEnlace) {

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
                texto + FIRMA,
                botonTexto,
                botonEnlace
        ));
    }

    private String checkInTexto(Reserva reserva) {
        return "\n\nCheck-in\n"
                + "Haz tu check-in el " + reserva.getFechaLlegada().format(FECHA)
                + ", desde las " + horaCheckIn(reserva) + " hasta las 11:59 p. m., "
                + "desde \"Mis viajes\" en StayHub.\n"
                + "Si no haces el check-in ese día, el anfitrión podrá cancelar tu reserva.";
    }

    private String horaCheckIn(Reserva reserva) {
        return reserva.getAlojamiento().getHoraCheckIn().format(HORA);
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

    // $1.620.000 COP  o  US$405,00 USD
    private String dinero(BigDecimal valor, String moneda) {

        if ("USD".equals(moneda)) {
            NumberFormat formato = NumberFormat.getNumberInstance(COLOMBIA);
            formato.setMinimumFractionDigits(2);
            formato.setMaximumFractionDigits(2);
            return "US$" + formato.format(valor) + " USD";
        }

        NumberFormat formato = NumberFormat.getCurrencyInstance(COLOMBIA);
        formato.setMaximumFractionDigits(0);

        return formato.format(valor) + " COP";
    }

    private String nombreMoneda(String moneda) {
        return "USD".equals(moneda) ? "Dólares (USD)" : "Pesos colombianos (COP)";
    }

    private static String recortar(String texto, int maximo) {
        return texto.length() <= maximo ? texto : texto.substring(0, maximo - 1) + "…";
    }
}
