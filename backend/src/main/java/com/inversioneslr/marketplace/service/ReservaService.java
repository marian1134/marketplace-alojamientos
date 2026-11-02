package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.CotizacionRequest;
import com.inversioneslr.marketplace.dto.CotizacionResponse;
import com.inversioneslr.marketplace.dto.DetalleAlojamientoResponse;
import com.inversioneslr.marketplace.dto.ImagenAlojamientoResponse;
import com.inversioneslr.marketplace.dto.ReservaRequest;
import com.inversioneslr.marketplace.dto.ReservaResponse;
import com.inversioneslr.marketplace.dto.ResultadoBusqueda;
import com.inversioneslr.marketplace.model.Alojamiento;
import com.inversioneslr.marketplace.model.Cancelacion;
import com.inversioneslr.marketplace.model.ConfiguracionTarifas;
import com.inversioneslr.marketplace.model.Cotizacion;
import com.inversioneslr.marketplace.model.EstadoPago;
import com.inversioneslr.marketplace.model.EstadoPublicacion;
import com.inversioneslr.marketplace.model.EstadoReserva;
import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.model.ModoReserva;
import com.inversioneslr.marketplace.model.NocheReservada;
import com.inversioneslr.marketplace.model.Pago;
import com.inversioneslr.marketplace.model.PoliticaCancelacion;
import com.inversioneslr.marketplace.model.Reserva;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.AlojamientoRepository;
import com.inversioneslr.marketplace.repository.CancelacionRepository;
import com.inversioneslr.marketplace.repository.ConfiguracionTarifasRepository;
import com.inversioneslr.marketplace.repository.CotizacionRepository;
import com.inversioneslr.marketplace.repository.ImagenAlojamientoRepository;
import com.inversioneslr.marketplace.repository.NocheReservadaRepository;
import com.inversioneslr.marketplace.repository.PagoRepository;
import com.inversioneslr.marketplace.repository.ReservaRepository;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.text.Normalizer;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@Service
@Transactional
public class ReservaService {

    private static final long MAXIMO_NOCHES = 90;
    private static final BigDecimal CIEN = new BigDecimal("100");

    // Tarjeta de prueba que siempre se rechaza (las demás válidas se aprueban)
    private static final String TARJETA_RECHAZADA = "4000000000000002";

    private static final Set<EstadoReserva> CANCELABLES = Set.of(
            EstadoReserva.CONFIRMADA,
            EstadoReserva.PENDIENTE_APROBACION
    );

    private final ReservaRepository reservaRepository;
    private final NocheReservadaRepository nocheRepository;
    private final CotizacionRepository cotizacionRepository;
    private final PagoRepository pagoRepository;
    private final CancelacionRepository cancelacionRepository;
    private final ConfiguracionTarifasRepository configuracionRepository;
    private final AlojamientoRepository alojamientoRepository;
    private final ImagenAlojamientoRepository imagenRepository;
    private final UsuarioRepository usuarioRepository;
    private final AlojamientoService alojamientoService;
    private final ImagenAlojamientoService imagenService;

    private final SecureRandom aleatorio = new SecureRandom();

    public ReservaService(
            ReservaRepository reservaRepository,
            NocheReservadaRepository nocheRepository,
            CotizacionRepository cotizacionRepository,
            PagoRepository pagoRepository,
            CancelacionRepository cancelacionRepository,
            ConfiguracionTarifasRepository configuracionRepository,
            AlojamientoRepository alojamientoRepository,
            ImagenAlojamientoRepository imagenRepository,
            UsuarioRepository usuarioRepository,
            AlojamientoService alojamientoService,
            ImagenAlojamientoService imagenService) {

        this.reservaRepository = reservaRepository;
        this.nocheRepository = nocheRepository;
        this.cotizacionRepository = cotizacionRepository;
        this.pagoRepository = pagoRepository;
        this.cancelacionRepository = cancelacionRepository;
        this.configuracionRepository = configuracionRepository;
        this.alojamientoRepository = alojamientoRepository;
        this.imagenRepository = imagenRepository;
        this.usuarioRepository = usuarioRepository;
        this.alojamientoService = alojamientoService;
        this.imagenService = imagenService;
    }

    // ------------------------------------------------------------------
    // Detalle del alojamiento
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public DetalleAlojamientoResponse obtenerDetalle(Long idAlojamiento, String correo) {

        Usuario usuario = obtenerUsuario(correo);
        Alojamiento alojamiento = buscarAlojamiento(idAlojamiento);

        boolean esDueno = alojamiento.getAnfitrion()
                .getIdUsuario()
                .equals(usuario.getIdUsuario());

        if (alojamiento.getEstado() != EstadoPublicacion.ACTIVA && !esDueno) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Este alojamiento no está disponible"
            );
        }

        List<ImagenAlojamientoResponse> imagenes =
                imagenService.listar(idAlojamiento);

        List<LocalDate> nochesOcupadas = nocheRepository
                .findByIdAlojamientoAndFechaGreaterThanEqualOrderByFecha(
                        idAlojamiento,
                        LocalDate.now()
                )
                .stream()
                .map(NocheReservada::getFecha)
                .toList();

        PoliticaCancelacion politica = alojamiento.getPolitica();
        Usuario anfitrion = alojamiento.getAnfitrion();

        return new DetalleAlojamientoResponse(
                alojamientoService.obtenerPorId(idAlojamiento),
                imagenes,
                anfitrion.getNombre(),
                anfitrion.getCreadoEn() != null
                        ? anfitrion.getCreadoEn().getYear()
                        : null,
                nochesOcupadas,
                obtenerConfiguracion().getPorcentajeServicio(),
                new DetalleAlojamientoResponse.Politica(
                        politica.getTipo(),
                        politica.getDiasAnticipacion(),
                        politica.getPorcentajeAntes(),
                        politica.getPorcentajeDespues()
                )
        );
    }

    // ------------------------------------------------------------------
    // Búsqueda: alojamientos activos y libres en las fechas elegidas
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<ResultadoBusqueda> buscar(
            String destino,
            List<String> ciudades,
            LocalDate llegada,
            LocalDate salida,
            Integer huespedes,
            String correo) {

        obtenerUsuario(correo);

        boolean conFechas = llegada != null && salida != null;

        if (conFechas) {
            if (llegada.isBefore(LocalDate.now())) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "La fecha de llegada no puede estar en el pasado"
                );
            }

            if (!salida.isAfter(llegada)) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "La fecha de salida debe ser posterior a la de llegada"
                );
            }
        }

        String texto = normalizar(destino);
        List<String> listaCiudades = ciudades == null
                ? List.of()
                : ciudades.stream().map(this::normalizar).toList();

        long noches = conFechas
                ? ChronoUnit.DAYS.between(llegada, salida)
                : 0;

        // Alojamientos con alguna noche ocupada en esas fechas (una consulta)
        Set<Long> ocupados = conFechas
                ? new java.util.HashSet<>(nocheRepository.alojamientosOcupados(
                        llegada,
                        salida.minusDays(1)
                ))
                : Set.of();

        List<Alojamiento> encontrados = alojamientoRepository
                .findByEstado(EstadoPublicacion.ACTIVA)
                .stream()
                .filter(alojamiento -> {
                    String ciudad = normalizar(alojamiento.getCiudad());

                    if (!listaCiudades.isEmpty()) {
                        return listaCiudades.contains(ciudad);
                    }

                    // Busca en ciudad, título y ubicación (incluye el departamento)
                    return texto.isEmpty()
                            || ciudad.contains(texto)
                            || normalizar(alojamiento.getTitulo()).contains(texto)
                            || normalizar(alojamiento.getDireccion()).contains(texto);
                })
                .filter(alojamiento -> huespedes == null
                        || alojamiento.getCapacidad() >= huespedes)
                .filter(alojamiento -> !ocupados.contains(
                        alojamiento.getIdAlojamiento()
                ))
                .toList();

        // Foto principal de cada alojamiento (una consulta)
        java.util.Map<Long, String> portadas = new java.util.HashMap<>();

        if (!encontrados.isEmpty()) {
            imagenRepository
                    .findByAlojamiento_IdAlojamientoInOrderByOrdenImagenAscIdImagenAsc(
                            encontrados.stream()
                                    .map(Alojamiento::getIdAlojamiento)
                                    .toList()
                    )
                    .forEach(imagen -> portadas.putIfAbsent(
                            imagen.getAlojamiento().getIdAlojamiento(),
                            imagen.getUrlImagen()
                    ));
        }

        return encontrados
                .stream()
                .map(alojamiento -> new ResultadoBusqueda(
                        alojamientoService.obtenerPorId(
                                alojamiento.getIdAlojamiento()
                        ),
                        portadas.get(alojamiento.getIdAlojamiento()),
                        noches,
                        conFechas
                                ? alojamiento.getPrecioNoche()
                                        .multiply(BigDecimal.valueOf(noches))
                                        .add(alojamiento.getTarifaLimpieza())
                                : null
                ))
                .toList();
    }

    // "Medellín " -> "medellin" (sin tildes ni mayúsculas)
    private String normalizar(String texto) {

        if (texto == null) {
            return "";
        }

        return Normalizer.normalize(texto.trim(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT);
    }

    // ------------------------------------------------------------------
    // Cotización
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public CotizacionResponse cotizar(CotizacionRequest datos, String correo) {

        Usuario huesped = obtenerUsuario(correo);
        Alojamiento alojamiento = buscarAlojamiento(datos.idAlojamiento());

        validarSolicitud(
                alojamiento,
                huesped,
                datos.fechaLlegada(),
                datos.fechaSalida(),
                datos.cantidadHuespedes()
        );

        return calcularPrecio(
                alojamiento,
                datos.fechaLlegada(),
                datos.fechaSalida(),
                obtenerConfiguracion()
        );
    }

    // ------------------------------------------------------------------
    // Crear la reserva y pagarla (pago de prueba)
    // ------------------------------------------------------------------

    public ReservaResponse crear(ReservaRequest datos, String correo) {

        Usuario huesped = obtenerUsuario(correo);

        // Si ya llegó esta misma solicitud (doble clic), se devuelve la reserva creada
        var existente = reservaRepository
                .findByClaveIdempotencia(datos.claveIdempotencia());

        if (existente.isPresent()) {
            Reserva reserva = existente.get();

            if (!reserva.getHuesped().getIdUsuario().equals(huesped.getIdUsuario())) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "La solicitud ya fue utilizada"
                );
            }

            return convertir(reserva);
        }

        Alojamiento alojamiento = buscarAlojamiento(datos.idAlojamiento());

        validarSolicitud(
                alojamiento,
                huesped,
                datos.fechaLlegada(),
                datos.fechaSalida(),
                datos.cantidadHuespedes()
        );

        String numeroTarjeta = validarTarjeta(datos);

        if (numeroTarjeta.equals(TARJETA_RECHAZADA)) {
            throw new ResponseStatusException(
                    HttpStatus.PAYMENT_REQUIRED,
                    "El pago fue rechazado por el banco (tarjeta de prueba "
                            + "rechazada). Intenta con otra tarjeta."
            );
        }

        ConfiguracionTarifas configuracion = obtenerConfiguracion();
        CotizacionResponse precio = calcularPrecio(
                alojamiento,
                datos.fechaLlegada(),
                datos.fechaSalida(),
                configuracion
        );

        Reserva reserva = new Reserva();
        reserva.setCodigo(generarCodigo());
        reserva.setAlojamiento(alojamiento);
        reserva.setHuesped(huesped);
        reserva.setFechaLlegada(datos.fechaLlegada());
        reserva.setFechaSalida(datos.fechaSalida());
        reserva.setCantidadHuespedes(datos.cantidadHuespedes());
        reserva.setClaveIdempotencia(datos.claveIdempotencia());
        reserva.setEstado(
                alojamiento.getModoReserva() == ModoReserva.CON_APROBACION
                        ? EstadoReserva.PENDIENTE_APROBACION
                        : EstadoReserva.CONFIRMADA
        );

        reserva = reservaRepository.save(reserva);

        // Bloquea cada noche. Si otra persona reservó al mismo tiempo,
        // la llave de noche_reservada lo impide y se cancela todo.
        List<NocheReservada> noches = new ArrayList<>();

        for (LocalDate fecha = datos.fechaLlegada();
             fecha.isBefore(datos.fechaSalida());
             fecha = fecha.plusDays(1)) {

            noches.add(new NocheReservada(
                    alojamiento.getIdAlojamiento(),
                    fecha,
                    reserva
            ));
        }

        try {
            nocheRepository.saveAllAndFlush(noches);
        } catch (DataIntegrityViolationException excepcion) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Otra persona acaba de reservar alguna de esas fechas. "
                            + "Elige otras fechas."
            );
        }

        Cotizacion cotizacion = new Cotizacion();
        cotizacion.setReserva(reserva);
        cotizacion.setPrecioNoche(precio.precioNoche());
        cotizacion.setTarifaLimpieza(precio.tarifaLimpieza());
        cotizacion.setTarifaServicio(precio.tarifaServicio());
        cotizacion.setDescuentos(precio.descuentos());
        cotizacion.setTotal(precio.total());
        cotizacion.setConfiguracion(configuracion);
        cotizacionRepository.save(cotizacion);

        Pago pago = new Pago();
        pago.setReserva(reserva);
        pago.setMonto(precio.total());
        pago.setEstado(EstadoPago.APROBADO);
        pago.setReferencia("PRUEBA-" + UUID.randomUUID());
        pago.setUltimos4(numeroTarjeta.substring(numeroTarjeta.length() - 4));
        pago.setClaveIdempotencia(UUID.randomUUID().toString());
        pagoRepository.save(pago);

        return convertir(reserva);
    }

    // ------------------------------------------------------------------
    // Consultas
    // ------------------------------------------------------------------

    public List<ReservaResponse> listarMisReservas(String correo) {

        Usuario huesped = obtenerUsuario(correo);

        return reservaRepository
                .findByHuesped_IdUsuarioOrderByCreadaEnDesc(huesped.getIdUsuario())
                .stream()
                .peek(this::completarSiTermino)
                .map(this::convertir)
                .toList();
    }

    public List<ReservaResponse> listarReservasRecibidas(String correo) {

        Usuario anfitrion = obtenerUsuario(correo);

        return reservaRepository
                .findByAlojamiento_Anfitrion_IdUsuarioOrderByCreadaEnDesc(
                        anfitrion.getIdUsuario()
                )
                .stream()
                .peek(this::completarSiTermino)
                .map(this::convertir)
                .toList();
    }

    @Transactional(readOnly = true)
    public ReservaResponse obtener(Long idReserva, String correo) {

        Usuario usuario = obtenerUsuario(correo);
        Reserva reserva = buscarReserva(idReserva);

        boolean esHuesped = reserva.getHuesped()
                .getIdUsuario()
                .equals(usuario.getIdUsuario());

        boolean esAnfitrion = reserva.getAlojamiento()
                .getAnfitrion()
                .getIdUsuario()
                .equals(usuario.getIdUsuario());

        if (!esHuesped && !esAnfitrion) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No puedes ver esta reserva"
            );
        }

        return convertir(reserva);
    }

    // ------------------------------------------------------------------
    // Cancelación por el huésped (según la política del alojamiento)
    // ------------------------------------------------------------------

    public ReservaResponse cancelar(Long idReserva, String motivo, String correo) {

        Usuario huesped = obtenerUsuario(correo);
        Reserva reserva = buscarReserva(idReserva);

        if (!reserva.getHuesped().getIdUsuario().equals(huesped.getIdUsuario())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Solo el huésped puede cancelar su reserva"
            );
        }

        if (!puedeCancelar(reserva)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Esta reserva ya no se puede cancelar"
            );
        }

        PoliticaCancelacion politica = reserva.getAlojamiento().getPolitica();

        long diasFaltantes = ChronoUnit.DAYS.between(
                LocalDate.now(),
                reserva.getFechaLlegada()
        );

        BigDecimal porcentaje = diasFaltantes >= politica.getDiasAnticipacion()
                ? politica.getPorcentajeAntes()
                : politica.getPorcentajeDespues();

        Pago pago = pagoRepository
                .findByReserva_IdReserva(idReserva)
                .orElse(null);

        BigDecimal pagado = pago != null ? pago.getMonto() : BigDecimal.ZERO;

        BigDecimal devolucion = pagado
                .multiply(porcentaje)
                .divide(CIEN, 0, RoundingMode.HALF_UP);

        devolverDinero(pago, devolucion);

        if (politica.isLiberaFechas()) {
            nocheRepository.liberarNoches(idReserva);
        }

        reserva.setEstado(EstadoReserva.CANCELADA);
        reservaRepository.save(reserva);

        Cancelacion cancelacion = new Cancelacion();
        cancelacion.setReserva(reserva);
        cancelacion.setCanceladoPor(huesped.getIdUsuario());
        cancelacion.setMotivo(motivo.trim());
        cancelacion.setPorcentajeDevolucion(porcentaje);
        cancelacion.setValorDevolucion(devolucion);
        cancelacion.setFechasLiberadas(politica.isLiberaFechas());
        cancelacion.setEstadoFinal(EstadoReserva.CANCELADA.name());
        cancelacionRepository.save(cancelacion);

        return convertir(reserva);
    }

    // ------------------------------------------------------------------
    // Aprobación o rechazo por el anfitrión (modo CON_APROBACION)
    // ------------------------------------------------------------------

    public ReservaResponse aprobar(Long idReserva, String correo) {

        Reserva reserva = buscarReservaPendienteDelAnfitrion(idReserva, correo);

        reserva.setEstado(EstadoReserva.CONFIRMADA);
        reservaRepository.save(reserva);

        return convertir(reserva);
    }

    public ReservaResponse rechazar(Long idReserva, String motivo, String correo) {

        Reserva reserva = buscarReservaPendienteDelAnfitrion(idReserva, correo);

        Pago pago = pagoRepository
                .findByReserva_IdReserva(idReserva)
                .orElse(null);

        if (pago != null) {
            devolverDinero(pago, pago.getMonto());
        }

        nocheRepository.liberarNoches(idReserva);

        reserva.setEstado(EstadoReserva.RECHAZADA);
        reserva.setMotivoRechazo(motivo.trim());
        reservaRepository.save(reserva);

        return convertir(reserva);
    }

    // ------------------------------------------------------------------
    // Reglas de negocio
    // ------------------------------------------------------------------

    private void validarSolicitud(
            Alojamiento alojamiento,
            Usuario huesped,
            LocalDate llegada,
            LocalDate salida,
            Integer cantidadHuespedes) {

        if (alojamiento.getEstado() != EstadoPublicacion.ACTIVA) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Este alojamiento no está recibiendo reservas"
            );
        }

        if (alojamiento.getAnfitrion().getIdUsuario().equals(huesped.getIdUsuario())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "No puedes reservar tu propio alojamiento"
            );
        }

        if (llegada.isBefore(LocalDate.now())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La fecha de llegada no puede estar en el pasado"
            );
        }

        if (!salida.isAfter(llegada)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La fecha de salida debe ser posterior a la de llegada"
            );
        }

        if (ChronoUnit.DAYS.between(llegada, salida) > MAXIMO_NOCHES) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La estadía máxima es de " + MAXIMO_NOCHES + " noches"
            );
        }

        if (cantidadHuespedes > alojamiento.getCapacidad()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Este alojamiento admite máximo "
                            + alojamiento.getCapacidad() + " huéspedes"
            );
        }

        boolean ocupado = nocheRepository.existsByIdAlojamientoAndFechaBetween(
                alojamiento.getIdAlojamiento(),
                llegada,
                salida.minusDays(1)
        );

        if (ocupado) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "El alojamiento ya está reservado en alguna de esas fechas"
            );
        }
    }

    // subtotal = precio x noches; servicio = % del subtotal;
    // descuento semanal (7+ noches) o mensual (28+ noches) sobre el subtotal
    private CotizacionResponse calcularPrecio(
            Alojamiento alojamiento,
            LocalDate llegada,
            LocalDate salida,
            ConfiguracionTarifas configuracion) {

        long noches = ChronoUnit.DAYS.between(llegada, salida);

        BigDecimal precioNoche = alojamiento.getPrecioNoche();
        BigDecimal subtotal = precioNoche.multiply(BigDecimal.valueOf(noches));
        BigDecimal limpieza = alojamiento.getTarifaLimpieza();

        BigDecimal servicio = porcentajeDe(
                subtotal,
                configuracion.getPorcentajeServicio()
        );

        BigDecimal porcentajeDescuento = BigDecimal.ZERO;

        if (noches >= 28) {
            porcentajeDescuento = configuracion.getDescuentoMensual();
        } else if (noches >= 7) {
            porcentajeDescuento = configuracion.getDescuentoSemanal();
        }

        BigDecimal descuento = porcentajeDe(subtotal, porcentajeDescuento);

        BigDecimal total = subtotal
                .add(limpieza)
                .add(servicio)
                .subtract(descuento);

        return new CotizacionResponse(
                noches,
                precioNoche,
                subtotal,
                limpieza,
                configuracion.getPorcentajeServicio(),
                servicio,
                descuento,
                total,
                "COP"
        );
    }

    private BigDecimal porcentajeDe(BigDecimal valor, BigDecimal porcentaje) {
        return valor
                .multiply(porcentaje)
                .divide(CIEN, 0, RoundingMode.HALF_UP);
    }

    // Validación de la tarjeta de prueba: número (Luhn), fecha y CVC
    private String validarTarjeta(ReservaRequest datos) {

        String numero = datos.numeroTarjeta().replaceAll("[\\s-]", "");

        if (!numero.matches("\\d{13,19}") || !cumpleLuhn(numero)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El número de tarjeta no es válido"
            );
        }

        if (!datos.expiracion().matches("(0[1-9]|1[0-2])/\\d{2}")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La fecha de expiración debe tener el formato MM/AA"
            );
        }

        int mes = Integer.parseInt(datos.expiracion().substring(0, 2));
        int anio = 2000 + Integer.parseInt(datos.expiracion().substring(3));

        if (YearMonth.of(anio, mes).isBefore(YearMonth.now())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La tarjeta está vencida"
            );
        }

        if (!datos.cvc().matches("\\d{3,4}")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El CVC debe tener 3 o 4 dígitos"
            );
        }

        return numero;
    }

    private boolean cumpleLuhn(String numero) {

        int suma = 0;
        boolean doblar = false;

        for (int i = numero.length() - 1; i >= 0; i--) {
            int digito = numero.charAt(i) - '0';

            if (doblar) {
                digito *= 2;
                if (digito > 9) {
                    digito -= 9;
                }
            }

            suma += digito;
            doblar = !doblar;
        }

        return suma % 10 == 0;
    }

    private void devolverDinero(Pago pago, BigDecimal valor) {

        if (pago == null || valor.signum() <= 0) {
            return;
        }

        pago.setMontoReembolsado(valor);
        pago.setEstado(
                valor.compareTo(pago.getMonto()) >= 0
                        ? EstadoPago.REEMBOLSADO
                        : EstadoPago.REEMBOLSO_PARCIAL
        );
        pagoRepository.save(pago);
    }

    private boolean puedeCancelar(Reserva reserva) {
        return CANCELABLES.contains(reserva.getEstado())
                && reserva.getFechaLlegada().isAfter(LocalDate.now().minusDays(1));
    }

    // Una reserva confirmada cuya fecha de salida ya pasó queda COMPLETADA
    private void completarSiTermino(Reserva reserva) {

        if (reserva.getEstado() == EstadoReserva.CONFIRMADA
                && !reserva.getFechaSalida().isAfter(LocalDate.now())) {

            reserva.setEstado(EstadoReserva.COMPLETADA);
            reservaRepository.save(reserva);
        }
    }

    private String generarCodigo() {

        String codigo;

        do {
            codigo = "RSV-" + (100000 + aleatorio.nextInt(900000));
        } while (reservaRepository.existsByCodigo(codigo));

        return codigo;
    }

    private ConfiguracionTarifas obtenerConfiguracion() {

        return configuracionRepository
                .findFirstByVigenteTrue()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "Las tarifas no están configuradas. "
                                + "Ejecuta 03_configuracion_tarifas.sql"
                ));
    }

    private Usuario obtenerUsuario(String correo) {

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

        return usuario;
    }

    private Alojamiento buscarAlojamiento(Long idAlojamiento) {

        return alojamientoRepository
                .findById(idAlojamiento)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "No se encontró el alojamiento"
                ));
    }

    private Reserva buscarReserva(Long idReserva) {

        return reservaRepository
                .findById(idReserva)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "No se encontró la reserva"
                ));
    }

    private Reserva buscarReservaPendienteDelAnfitrion(Long idReserva, String correo) {

        Usuario anfitrion = obtenerUsuario(correo);
        Reserva reserva = buscarReserva(idReserva);

        if (!reserva.getAlojamiento().getAnfitrion().getIdUsuario()
                .equals(anfitrion.getIdUsuario())) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Esta reserva no es de tu alojamiento"
            );
        }

        if (reserva.getEstado() != EstadoReserva.PENDIENTE_APROBACION) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Esta reserva no está esperando aprobación"
            );
        }

        return reserva;
    }

    private ReservaResponse convertir(Reserva reserva) {

        Alojamiento alojamiento = reserva.getAlojamiento();
        Long idReserva = reserva.getIdReserva();

        Cotizacion cotizacion = cotizacionRepository
                .findByReserva_IdReserva(idReserva)
                .orElse(null);

        Pago pago = pagoRepository
                .findByReserva_IdReserva(idReserva)
                .orElse(null);

        Cancelacion cancelacion = cancelacionRepository
                .findByReserva_IdReserva(idReserva)
                .orElse(null);

        String imagen = imagenRepository
                .findByAlojamiento_IdAlojamientoOrderByOrdenImagenAscIdImagenAsc(
                        alojamiento.getIdAlojamiento()
                )
                .stream()
                .findFirst()
                .map(img -> img.getUrlImagen())
                .orElse(null);

        long noches = ChronoUnit.DAYS.between(
                reserva.getFechaLlegada(),
                reserva.getFechaSalida()
        );

        BigDecimal precioNoche = cotizacion != null
                ? cotizacion.getPrecioNoche()
                : alojamiento.getPrecioNoche();

        String motivo = cancelacion != null
                ? cancelacion.getMotivo()
                : reserva.getMotivoRechazo();

        return new ReservaResponse(
                idReserva,
                reserva.getCodigo(),
                reserva.getEstado(),
                reserva.getFechaLlegada(),
                reserva.getFechaSalida(),
                noches,
                reserva.getCantidadHuespedes(),
                alojamiento.getIdAlojamiento(),
                alojamiento.getTitulo(),
                alojamiento.getCiudad(),
                alojamiento.getTipoAlojamiento(),
                imagen,
                alojamiento.getPolitica().getTipo(),
                reserva.getHuesped().getNombre(),
                alojamiento.getAnfitrion().getNombre(),
                precioNoche,
                precioNoche.multiply(BigDecimal.valueOf(noches)),
                cotizacion != null ? cotizacion.getTarifaLimpieza() : null,
                cotizacion != null ? cotizacion.getTarifaServicio() : null,
                cotizacion != null ? cotizacion.getDescuentos() : null,
                cotizacion != null ? cotizacion.getTotal() : null,
                cotizacion != null ? cotizacion.getMoneda() : "COP",
                pago != null ? pago.getUltimos4() : null,
                cancelacion != null
                        ? cancelacion.getValorDevolucion()
                        : (pago != null && pago.getMontoReembolsado().signum() > 0
                                ? pago.getMontoReembolsado()
                                : null),
                motivo,
                puedeCancelar(reserva),
                reserva.getCreadaEn()
        );
    }
}
