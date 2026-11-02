package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Tabla marketplace.configuracion_tarifas: porcentaje de servicio y descuentos.
// Solo una fila puede estar vigente.
@Entity
@Table(name = "configuracion_tarifas")
public class ConfiguracionTarifas {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idConfiguracion;

    @Column(name = "porcentaje_servicio", nullable = false, precision = 5, scale = 2)
    private BigDecimal porcentajeServicio;

    @Column(name = "descuento_semanal", nullable = false, precision = 5, scale = 2)
    private BigDecimal descuentoSemanal;

    @Column(name = "descuento_mensual", nullable = false, precision = 5, scale = 2)
    private BigDecimal descuentoMensual;

    @Column(nullable = false)
    private boolean vigente;

    @Column(name = "actualizado_por", nullable = false, columnDefinition = "INT UNSIGNED")
    private Long actualizadoPor;

    @Column(name = "actualizado_en", nullable = false)
    private LocalDateTime actualizadoEn;

    public Long getIdConfiguracion() { return idConfiguracion; }
    public BigDecimal getPorcentajeServicio() { return porcentajeServicio; }
    public BigDecimal getDescuentoSemanal() { return descuentoSemanal; }
    public BigDecimal getDescuentoMensual() { return descuentoMensual; }
    public boolean isVigente() { return vigente; }
}
