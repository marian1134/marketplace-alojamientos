package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;

import java.math.BigDecimal;

// Tabla marketplace.cotizacion: precios congelados al momento de reservar
@Entity
@Table(name = "cotizacion")
public class Cotizacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idCotizacion;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reserva_id", nullable = false, unique = true, columnDefinition = "INT UNSIGNED")
    private Reserva reserva;

    @Column(name = "precio_noche", nullable = false, precision = 12, scale = 2)
    private BigDecimal precioNoche;

    @Column(name = "tarifa_limpieza", nullable = false, precision = 12, scale = 2)
    private BigDecimal tarifaLimpieza;

    @Column(name = "tarifa_servicio", nullable = false, precision = 12, scale = 2)
    private BigDecimal tarifaServicio;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal descuentos = BigDecimal.ZERO;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal total;

    @Column(nullable = false, columnDefinition = "CHAR(3)")
    private String moneda = "COP";

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "configuracion_id", nullable = false, columnDefinition = "INT UNSIGNED")
    private ConfiguracionTarifas configuracion;

    public Long getIdCotizacion() { return idCotizacion; }
    public Reserva getReserva() { return reserva; }
    public void setReserva(Reserva reserva) { this.reserva = reserva; }
    public BigDecimal getPrecioNoche() { return precioNoche; }
    public void setPrecioNoche(BigDecimal precioNoche) { this.precioNoche = precioNoche; }
    public BigDecimal getTarifaLimpieza() { return tarifaLimpieza; }
    public void setTarifaLimpieza(BigDecimal tarifaLimpieza) { this.tarifaLimpieza = tarifaLimpieza; }
    public BigDecimal getTarifaServicio() { return tarifaServicio; }
    public void setTarifaServicio(BigDecimal tarifaServicio) { this.tarifaServicio = tarifaServicio; }
    public BigDecimal getDescuentos() { return descuentos; }
    public void setDescuentos(BigDecimal descuentos) { this.descuentos = descuentos; }
    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }
    public String getMoneda() { return moneda; }
    public ConfiguracionTarifas getConfiguracion() { return configuracion; }
    public void setConfiguracion(ConfiguracionTarifas configuracion) { this.configuracion = configuracion; }
}
