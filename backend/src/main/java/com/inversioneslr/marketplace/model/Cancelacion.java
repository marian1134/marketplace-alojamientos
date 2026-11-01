package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Tabla marketplace.cancelacion: guarda cuánto se devolvió y por qué
@Entity
@Table(name = "cancelacion")
public class Cancelacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idCancelacion;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reserva_id", nullable = false, unique = true, columnDefinition = "INT UNSIGNED")
    private Reserva reserva;

    @Column(name = "cancelado_por", nullable = false, columnDefinition = "INT UNSIGNED")
    private Long canceladoPor;

    @Column(nullable = false)
    private LocalDateTime fecha;

    @Column(nullable = false, length = 500)
    private String motivo;

    @Column(name = "porcentaje_devolucion", nullable = false, precision = 5, scale = 2)
    private BigDecimal porcentajeDevolucion;

    @Column(name = "valor_devolucion", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorDevolucion;

    @Column(name = "fechas_liberadas", nullable = false)
    private boolean fechasLiberadas;

    @Column(name = "estado_final", nullable = false, length = 25)
    private String estadoFinal;

    @PrePersist
    public void antesDeGuardar() {
        if (fecha == null) {
            fecha = LocalDateTime.now();
        }
    }

    public Long getIdCancelacion() { return idCancelacion; }
    public Reserva getReserva() { return reserva; }
    public void setReserva(Reserva reserva) { this.reserva = reserva; }
    public Long getCanceladoPor() { return canceladoPor; }
    public void setCanceladoPor(Long canceladoPor) { this.canceladoPor = canceladoPor; }
    public LocalDateTime getFecha() { return fecha; }
    public String getMotivo() { return motivo; }
    public void setMotivo(String motivo) { this.motivo = motivo; }
    public BigDecimal getPorcentajeDevolucion() { return porcentajeDevolucion; }
    public void setPorcentajeDevolucion(BigDecimal porcentajeDevolucion) { this.porcentajeDevolucion = porcentajeDevolucion; }
    public BigDecimal getValorDevolucion() { return valorDevolucion; }
    public void setValorDevolucion(BigDecimal valorDevolucion) { this.valorDevolucion = valorDevolucion; }
    public boolean isFechasLiberadas() { return fechasLiberadas; }
    public void setFechasLiberadas(boolean fechasLiberadas) { this.fechasLiberadas = fechasLiberadas; }
    public String getEstadoFinal() { return estadoFinal; }
    public void setEstadoFinal(String estadoFinal) { this.estadoFinal = estadoFinal; }
}
