package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.CotizacionRequest;
import com.inversioneslr.marketplace.dto.CotizacionResponse;
import com.inversioneslr.marketplace.dto.IntencionPagoRequest;
import com.inversioneslr.marketplace.dto.IntencionPagoResponse;
import com.stripe.model.PaymentIntent;
import com.inversioneslr.marketplace.dto.DetalleAlojamientoResponse;
import com.inversioneslr.marketplace.dto.ImagenAlojamientoResponse;
import com.inversioneslr.marketplace.dto.ReservaRequest;
import com.inversioneslr.marketplace.dto.CalendarioResponse;
import com.inversioneslr.marketplace.dto.ResenaRequest;
import com.inversioneslr.marketplace.dto.ResenaResponse;
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
import com.inversioneslr.marketplace.model.PeriodoDisponible;
import com.inversioneslr.marketplace.model.Resena;
import com.inversioneslr.marketplace.model.Reserva;
import com.inversioneslr.marketplace.model.Usuario;
import com.inversioneslr.marketplace.repository.AlojamientoRepository;
import com.inversioneslr.marketplace.repository.CancelacionRepository;
import com.inversioneslr.marketplace.repository.ConfiguracionTarifasRepository;
import com.inversioneslr.marketplace.repository.CotizacionRepository;
import com.inversioneslr.marketplace.repository.ImagenAlojamientoRepository;
import com.inversioneslr.marketplace.repository.NocheReservadaRepository;
import com.inversioneslr.marketplace.repository.PagoRepository;
import com.inversioneslr.marketplace.repository.FavoritoRepository;
import com.inversioneslr.marketplace.repository.PeriodoDisponibleRepository;
import com.inversioneslr.marketplace.repository.ResenaRepository;
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
import java.time.LocalDateTime;
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
    private static final long DIAS_PARA_REPORTAR_NO_SHOW = 2;

    private static final java.time.format.DateTimeFormatter HORA =
            java.time.format.DateTimeFormatter.ofPattern("h:mm a", Locale.forLanguageTag("es-CO"));
    private static final java.time.format.DateTimeFormatter FECHA_LARGA =
            java.time.format.DateTimeFormatter.ofPattern("d 'de' MMMM", Locale.forLanguageTag("es-CO"));

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
    private final ResenaRepository resenaRepository;
    private final PeriodoDisponibleRepository periodoRepository;
    private final FavoritoRepository favoritoRepository;
    private final AvisosReserva avisos;
    private final StripeService stripe;
    private final MonedaService monedas;

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
            ImagenAlojamientoService imagenService,
            ResenaRepository resenaRepository,
            PeriodoDisponibleRepository periodoRepository,
            FavoritoRepository favoritoRepository,
            AvisosReserva avisos,
            StripeService stripe,
            MonedaService monedas) {

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
        this.resenaRepository = resenaRepository;
        this.periodoRepository = periodoRepository;
        this.favoritoRepository = favoritoRepository;
        this.avisos = avisos;
        this.stripe = stripe;
        this.monedas = monedas;
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
                .map(noche -> noche.getFecha())
                .toList();

        PoliticaCancelacion politica = alojamiento.getPolitica();
        Usuario anfitrion = alojamiento.getAnfitrion();

        // Reseñas: promedio, cuántas hay de cada estrella y las 6 más recientes
        List<Resena> resenas = resenaRepository
                .findByReserva_Alojamiento_IdAlojamientoAndVisibleTrueOrderByFechaDesc(
                        idAlojamiento
                );

        Long[] porEstrella = {0L, 0L, 0L, 0L, 0L};
        resenas.forEach(resena -> porEstrella[resena.getCalificacion() - 1]++);

        Double promedio = resenas.isEmpty()
                ? null
                : resenas.stream()
                        .mapToInt(resena -> resena.getCalificacion())
                        .average()
                        .orElse(0);

        List<CalendarioResponse.Periodo> periodos = periodoRepository
                .findByIdAlojamientoOrderByFechaInicio(idAlojamiento)
                .stream()
                .filter(periodo -> !periodo.getFechaFin().isBefore(LocalDate.now()))
                .map(periodo -> new CalendarioResponse.Periodo(
                        periodo.getIdPeriodo(),
                        periodo.getFechaInicio(),
                        periodo.getFechaFin()
                ))
                .toList();

        boolean esFavorito = favoritoRepository.existsById(
                new com.inversioneslr.marketplace.model.Favorito.Llave(
                        usuario.getIdUsuario(),
                        idAlojamiento
                )
        );

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
                ),
                promedio,
                resenas.size(),
                List.of(porEstrella),
                resenas.stream().limit(6).map(this::convertirResena).toList(),
                periodos,
                esFavorito
        );
    }

    // ------------------------------------------------------------------
    // Reseñas: el huésped califica cuando termina su estadía
    // ------------------------------------------------------------------

    public ResenaResponse crearResena(Long idReserva, ResenaRequest datos, String correo) {

        Usuario huesped = obtenerUsuario(correo);
        Reserva reserva = buscarReserva(idReserva);

        if (!reserva.getHuesped().getIdUsuario().equals(huesped.getIdUsuario())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Solo el huésped de la reserva puede dejar la reseña"
            );
        }

        completarSiTermino(reserva);

        if (reserva.getEstado() != EstadoReserva.COMPLETADA) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Podrás dejar tu reseña cuando termine la estadía"
            );
        }

        if (resenaRepository.existsByReserva_IdReserva(idReserva)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ya dejaste una reseña para esta reserva"
            );
        }

        Resena resena = new Resena();
        resena.setReserva(reserva);
        resena.setCalificacion(datos.calificacion());
        resena.setComentario(datos.comentario().trim());

        return convertirResena(resenaRepository.save(resena));
    }

    private ResenaResponse convertirResena(Resena resena) {

        // Solo el primer nombre y la inicial del apellido: "Valentina R."
        String[] partes = resena.getReserva().getHuesped().getNombre().trim().split("\\s+");
        String nombre = partes.length > 1
                ? partes[0] + " " + partes[1].charAt(0) + "."
                : partes[0];

        return new ResenaResponse(
                resena.getIdResena(),
                nombre,
                resena.getCalificacion(),
                resena.getComentario(),
                resena.getFecha()
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

        if (llegada != null && salida != null) {
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
        Set<Long> ocupados = llegada != null && salida != null
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

        // Si el alojamiento tiene periodos, la estadía debe caber en uno
        if (llegada != null && salida != null && !encontrados.isEmpty()) {
            java.util.Map<Long, List<PeriodoDisponible>> periodos = periodoRepository
                    .findByIdAlojamientoIn(
                            encontrados.stream()
                                    .map(alojamiento -> alojamiento.getIdAlojamiento())
                                    .toList()
                    )
                    .stream()
                    .collect(java.util.stream.Collectors.groupingBy(
                            periodo -> periodo.getIdAlojamiento()
                    ));

            encontrados = encontrados.stream()
                    .filter(alojamiento -> {
                        List<PeriodoDisponible> lista =
                                periodos.get(alojamiento.getIdAlojamiento());

                        return lista == null || lista.stream()
                                .anyMatch(periodo -> periodo.contiene(llegada, salida));
                    })
                    .toList();
        }

        // Promedio de estrellas de cada alojamiento (una consulta)
        java.util.Map<Long, Object[]> calificaciones = new java.util.HashMap<>();

        if (!encontrados.isEmpty()) {
            resenaRepository
                    .resumenPorAlojamiento(
                            encontrados.stream()
                                    .map(alojamiento -> alojamiento.getIdAlojamiento())
                                    .toList()
                    )
                    .forEach(fila -> calificaciones.put((Long) fila[0], fila));
        }

        // Foto principal de cada alojamiento (una consulta)
        java.util.Map<Long, String> portadas = new java.util.HashMap<>();

        if (!encontrados.isEmpty()) {
            imagenRepository
                    .findByAlojamiento_IdAlojamientoInOrderByOrdenImagenAscIdImagenAsc(
                            encontrados.stream()
                                    .map(alojamiento -> alojamiento.getIdAlojamiento())
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
                                : null,
                        calificaciones.containsKey(alojamiento.getIdAlojamiento())
                                ? ((Number) calificaciones.get(alojamiento.getIdAlojamiento())[1])
                                        .doubleValue()
                                : null,
                        calificaciones.containsKey(alojamiento.getIdAlojamiento())
                                ? ((Number) calificaciones.get(alojamiento.getIdAlojamiento())[2])
                                        .longValue()
                                : 0
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
        String moneda = monedas.validar(datos.moneda());

        // Con Stripe el pago ya se hizo en el navegador: se verifica aquí
        PaymentIntent intencion = stripe.activo()
                ? verificarPagoStripe(datos, huesped, alojamiento, moneda)
                : null;

        try {
            return crearReservaPagada(datos, huesped, alojamiento, moneda, intencion);
        } catch (ResponseStatusException excepcion) {

            // Si la reserva no se pudo crear (por ejemplo, alguien tomó las
            // fechas), se devuelve el dinero que ya se cobró en Stripe
            if (intencion != null) {
                stripe.reembolsar(intencion.getId(), null);

                throw new ResponseStatusException(
                        excepcion.getStatusCode(),
                        excepcion.getReason()
                                + " Como ya habías pagado, te devolvimos el dinero."
                );
            }

            throw excepcion;
        }
    }

    private ReservaResponse crearReservaPagada(
            ReservaRequest datos,
            Usuario huesped,
            Alojamiento alojamiento,
            String moneda,
            PaymentIntent intencion) {

        validarSolicitud(
                alojamiento,
                huesped,
                datos.fechaLlegada(),
                datos.fechaSalida(),
                datos.cantidadHuespedes()
        );

        // Pago simulado: se validan los datos de la tarjeta
        String numeroTarjeta = intencion == null ? validarTarjeta(datos) : null;

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

        marcarRecordatorioSiLlegaPronto(reserva);

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
        pago.setMoneda(moneda);
        pago.setMonto(monedas.convertir(precio.total(), moneda));
        pago.setEstado(EstadoPago.APROBADO);
        pago.setClaveIdempotencia(UUID.randomUUID().toString());

        if (intencion != null) {
            pago.setReferencia(intencion.getId());
            pago.setUltimos4(stripe.ultimos4(intencion));
        } else {
            pago.setReferencia("PRUEBA-" + UUID.randomUUID());
            String tarjetaValidada = java.util.Objects.requireNonNull(
                    numeroTarjeta,
                    "El pago simulado requiere una tarjeta validada"
            );
            pago.setUltimos4(
                    tarjetaValidada.substring(tarjetaValidada.length() - 4)
            );
        }

        pagoRepository.save(pago);

        avisos.reservaCreada(reserva, pago, cotizacion);

        return convertir(reserva);
    }

    // ------------------------------------------------------------------
    // Pago con Stripe
    // ------------------------------------------------------------------

    // Paso 1: antes de pagar, se crea la intención de pago con el total
    @Transactional(readOnly = true)
    public IntencionPagoResponse crearIntencionPago(IntencionPagoRequest datos, String correo) {

        if (!stripe.activo()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Stripe no está configurado"
            );
        }

        Usuario huesped = obtenerUsuario(correo);
        Alojamiento alojamiento = buscarAlojamiento(datos.idAlojamiento());
        String moneda = monedas.validar(datos.moneda());

        validarSolicitud(
                alojamiento,
                huesped,
                datos.fechaLlegada(),
                datos.fechaSalida(),
                datos.cantidadHuespedes()
        );

        CotizacionResponse precio = calcularPrecio(
                alojamiento,
                datos.fechaLlegada(),
                datos.fechaSalida(),
                obtenerConfiguracion()
        );

        BigDecimal monto = monedas.convertir(precio.total(), moneda);

        // Estos datos se comparan después para que nadie cambie la reserva
        java.util.Map<String, String> datosReserva = java.util.Map.of(
                "idAlojamiento", String.valueOf(alojamiento.getIdAlojamiento()),
                "idHuesped", String.valueOf(huesped.getIdUsuario()),
                "llegada", datos.fechaLlegada().toString(),
                "salida", datos.fechaSalida().toString(),
                "huespedes", String.valueOf(datos.cantidadHuespedes()),
                "claveIdempotencia", datos.claveIdempotencia()
        );

        PaymentIntent intencion = stripe.crearIntencion(
                monedas.enCentavos(monto),
                moneda,
                "StayHub - " + alojamiento.getTitulo() + " ("
                        + datos.fechaLlegada() + " a " + datos.fechaSalida() + ")",
                datosReserva,
                "intencion-" + datos.claveIdempotencia() + "-" + moneda
        );

        return new IntencionPagoResponse(
                intencion.getId(),
                intencion.getClientSecret(),
                monto,
                moneda
        );
    }

    // Paso 2: al crear la reserva se confirma que Stripe sí cobró lo correcto
    private PaymentIntent verificarPagoStripe(
            ReservaRequest datos,
            Usuario huesped,
            Alojamiento alojamiento,
            String moneda) {

        if (datos.idIntencionPago() == null || datos.idIntencionPago().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Falta el pago con Stripe"
            );
        }

        if (pagoRepository.existsByReferencia(datos.idIntencionPago())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ese pago ya se usó en otra reserva"
            );
        }

        PaymentIntent intencion = stripe.obtener(datos.idIntencionPago());
        java.util.Map<String, String> guardados = intencion.getMetadata();

        boolean mismaReserva =
                String.valueOf(alojamiento.getIdAlojamiento()).equals(guardados.get("idAlojamiento"))
                && String.valueOf(huesped.getIdUsuario()).equals(guardados.get("idHuesped"))
                && datos.fechaLlegada().toString().equals(guardados.get("llegada"))
                && datos.fechaSalida().toString().equals(guardados.get("salida"))
                && String.valueOf(datos.cantidadHuespedes()).equals(guardados.get("huespedes"))
                && moneda.equalsIgnoreCase(intencion.getCurrency());

        if (!mismaReserva) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El pago no corresponde a esta reserva"
            );
        }

        if (!"succeeded".equals(intencion.getStatus())) {
            throw new ResponseStatusException(
                    HttpStatus.PAYMENT_REQUIRED,
                    "El pago no fue aprobado. Intenta con otra tarjeta."
            );
        }

        return intencion;
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

        String monedaPago = pago != null ? pago.getMoneda() : MonedaService.COP;

        BigDecimal devolucion = pagado
                .multiply(porcentaje)
                .divide(CIEN, monedas.decimales(monedaPago), RoundingMode.HALF_UP);

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

        avisos.reservaCancelada(reserva, motivo.trim(), devolucion, monedaPago);

        return convertir(reserva);
    }

    // ------------------------------------------------------------------
    // Check-in
    // ------------------------------------------------------------------

    public ReservaResponse hacerCheckIn(Long idReserva, String correo) {

        Usuario huesped = obtenerUsuario(correo);
        Reserva reserva = buscarReserva(idReserva);

        if (!reserva.getHuesped().getIdUsuario().equals(huesped.getIdUsuario())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Solo el huésped puede hacer el check-in de su reserva"
            );
        }

        if (reserva.getCheckInEn() != null) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ya hiciste el check-in de esta reserva"
            );
        }

        if (reserva.getEstado() != EstadoReserva.CONFIRMADA) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Solo puedes hacer check-in de una reserva confirmada"
            );
        }

        LocalDateTime ahora = LocalDateTime.now();
        LocalDateTime inicio = reserva.getFechaLlegada()
                .atTime(reserva.getAlojamiento().getHoraCheckIn());

        if (ahora.isBefore(inicio)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El check-in se habilita el "
                            + reserva.getFechaLlegada().format(FECHA_LARGA)
                            + " desde las " + inicio.toLocalTime().format(HORA)
            );
        }

        if (ahora.toLocalDate().isAfter(reserva.getFechaLlegada())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El plazo para hacer check-in terminó el "
                            + reserva.getFechaLlegada().format(FECHA_LARGA)
                            + " a las 11:59 p. m."
            );
        }

        reserva.setCheckInEn(ahora);
        reservaRepository.save(reserva);

        avisos.checkInRealizado(reserva);

        return convertir(reserva);
    }

    // El anfitrión cancela porque el huésped no hizo check-in el día de
    // llegada. La devolución sigue la política del alojamiento.
    public ReservaResponse cancelarPorNoPresentarse(Long idReserva, String correo) {

        Usuario anfitrion = obtenerUsuario(correo);
        Reserva reserva = buscarReserva(idReserva);

        if (!reserva.getAlojamiento().getAnfitrion().getIdUsuario()
                .equals(anfitrion.getIdUsuario())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Solo el anfitrión del alojamiento puede hacer esto"
            );
        }

        if (!noSePresento(reserva)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Solo puedes cancelar por no presentarse cuando pasó el "
                            + "día de llegada y el huésped no hizo check-in"
            );
        }

        PoliticaCancelacion politica = reserva.getAlojamiento().getPolitica();
        BigDecimal porcentaje = politica.getPorcentajeDespues();

        Pago pago = pagoRepository
                .findByReserva_IdReserva(idReserva)
                .orElse(null);

        BigDecimal pagado = pago != null ? pago.getMonto() : BigDecimal.ZERO;
        String monedaPago = pago != null ? pago.getMoneda() : MonedaService.COP;

        BigDecimal devolucion = pagado
                .multiply(porcentaje)
                .divide(CIEN, monedas.decimales(monedaPago), RoundingMode.HALF_UP);

        devolverDinero(pago, devolucion);

        // El alojamiento vuelve a quedar libre para esas fechas
        nocheRepository.liberarNoches(idReserva);

        reserva.setEstado(EstadoReserva.CANCELADA);
        reservaRepository.save(reserva);

        String motivo = "El huésped no se presentó ni hizo check-in";

        Cancelacion cancelacion = new Cancelacion();
        cancelacion.setReserva(reserva);
        cancelacion.setCanceladoPor(anfitrion.getIdUsuario());
        cancelacion.setMotivo(motivo);
        cancelacion.setPorcentajeDevolucion(porcentaje);
        cancelacion.setValorDevolucion(devolucion);
        cancelacion.setFechasLiberadas(true);
        cancelacion.setEstadoFinal(EstadoReserva.CANCELADA.name());
        cancelacionRepository.save(cancelacion);

        avisos.noSePresento(reserva, devolucion, monedaPago);

        return convertir(reserva);
    }

    // Correo de "mañana llegas" para las reservas confirmadas de mañana.
    // Lo llama RecordatoriosCheckIn cada hora.
    public int enviarRecordatoriosCheckIn() {

        List<Reserva> deManana = reservaRepository
                .findByEstadoAndFechaLlegadaAndRecordatorioEnviadoFalse(
                        EstadoReserva.CONFIRMADA,
                        LocalDate.now().plusDays(1)
                );

        for (Reserva reserva : deManana) {
            avisos.recordatorioCheckIn(reserva);
            reserva.setRecordatorioEnviado(true);
            reservaRepository.save(reserva);
        }

        return deManana.size();
    }

    // Si la llegada es hoy o mañana, el correo de confirmación ya trae los
    // datos del check-in y no hace falta el recordatorio.
    private void marcarRecordatorioSiLlegaPronto(Reserva reserva) {
        if (!reserva.getFechaLlegada().isAfter(LocalDate.now().plusDays(1))) {
            reserva.setRecordatorioEnviado(true);
        }
    }

    // ------------------------------------------------------------------
    // Aprobación o rechazo por el anfitrión (modo CON_APROBACION)
    // ------------------------------------------------------------------

    public ReservaResponse aprobar(Long idReserva, String correo) {

        Reserva reserva = buscarReservaPendienteDelAnfitrion(idReserva, correo);

        reserva.setEstado(EstadoReserva.CONFIRMADA);
        marcarRecordatorioSiLlegaPronto(reserva);
        reservaRepository.save(reserva);

        avisos.reservaAprobada(reserva);

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

        avisos.reservaRechazada(
                reserva,
                pago != null ? pago.getMonto() : BigDecimal.ZERO,
                pago != null ? pago.getMoneda() : MonedaService.COP
        );

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

        if (llegada.isAfter(LocalDate.now().plusYears(1))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Solo puedes reservar con máximo un año de anticipación"
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

        // Si el anfitrión definió periodos, la estadía debe caber en uno
        List<PeriodoDisponible> periodos = periodoRepository
                .findByIdAlojamientoOrderByFechaInicio(alojamiento.getIdAlojamiento());

        boolean fueraDePeriodo = !periodos.isEmpty() && periodos.stream()
                .noneMatch(periodo -> periodo.contiene(llegada, salida));

        if (fueraDePeriodo) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El anfitrión no recibe huéspedes en esas fechas. "
                            + "Revisa las fechas disponibles."
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

    // Validación de la tarjeta: número de 13 a 19 dígitos, fecha y CVC.
    // El pago es simulado: cualquier número con ese formato se aprueba.
    private String validarTarjeta(ReservaRequest datos) {

        if (datos.numeroTarjeta() == null || datos.titular() == null
                || datos.expiracion() == null || datos.cvc() == null) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Completa los datos de la tarjeta"
            );
        }

        String numero = datos.numeroTarjeta().replaceAll("[\\s-]", "");

        if (!numero.matches("\\d{13,19}")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El número de tarjeta debe tener entre 13 y 19 dígitos"
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

        if (YearMonth.of(anio, mes).isAfter(YearMonth.now().plusYears(20))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La fecha de expiración no es válida"
            );
        }

        if (!datos.cvc().matches("\\d{3}")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El CVC debe tener 3 dígitos"
            );
        }

        return numero;
    }

    private void devolverDinero(Pago pago, BigDecimal valor) {

        if (pago == null || valor.signum() <= 0) {
            return;
        }

        // Si se pagó con Stripe, la devolución se hace en Stripe
        if (pago.getReferencia() != null && pago.getReferencia().startsWith("pi_")) {
            stripe.reembolsar(pago.getReferencia(), monedas.enCentavos(valor));
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
                && reserva.getCheckInEn() == null
                && reserva.getFechaLlegada().isAfter(LocalDate.now().minusDays(1));
    }

    // El check-in se hace el día de llegada, desde la hora de check-in
    // del alojamiento hasta las 11:59 p. m.
    private boolean puedeHacerCheckIn(Reserva reserva) {

        LocalDateTime ahora = LocalDateTime.now();

        return reserva.getEstado() == EstadoReserva.CONFIRMADA
                && reserva.getCheckInEn() == null
                && ahora.toLocalDate().equals(reserva.getFechaLlegada())
                && !ahora.toLocalTime().isBefore(
                        reserva.getAlojamiento().getHoraCheckIn());
    }

    // Pasó el día de llegada y el huésped no hizo check-in
    private boolean noSePresento(Reserva reserva) {
        return reserva.getEstado() == EstadoReserva.CONFIRMADA
                && reserva.getCheckInEn() == null
                && LocalDate.now().isAfter(reserva.getFechaLlegada());
    }

    // Una reserva confirmada cuya fecha de salida ya pasó queda COMPLETADA.
    // Si el huésped no hizo check-in, el anfitrión tiene 2 días más para
    // reportar que no se presentó.
    private void completarSiTermino(Reserva reserva) {

        LocalDate limite = reserva.getCheckInEn() != null
                ? reserva.getFechaSalida()
                : reserva.getFechaSalida().plusDays(DIAS_PARA_REPORTAR_NO_SHOW);

        if (reserva.getEstado() == EstadoReserva.CONFIRMADA
                && !limite.isAfter(LocalDate.now())) {

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

        Resena resena = resenaRepository
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
                reserva.getCreadaEn(),
                reserva.getEstado() == EstadoReserva.COMPLETADA && resena == null,
                resena != null ? resena.getCalificacion() : null,
                pago != null ? pago.getMonto() : null,
                pago != null ? pago.getMoneda() : MonedaService.COP,
                alojamiento.getHoraCheckIn(),
                reserva.getCheckInEn(),
                puedeHacerCheckIn(reserva),
                noSePresento(reserva)
        );
    }
}
