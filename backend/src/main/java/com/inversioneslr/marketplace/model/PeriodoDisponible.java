package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;

import java.time.LocalDate;

// Tabla marketplace.periodo_disponible: fechas en que el anfitrión recibe
// huéspedes. Si un alojamiento no tiene periodos, está disponible siempre.
@Entity
@Table(name = "periodo_disponible")
public class PeriodoDisponible {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idPeriodo;

    @Column(name = "publicacion_id", nullable = false, columnDefinition = "INT UNSIGNED")
    private Long idAlojamiento;

    @Column(name = "fecha_inicio", nullable = false)
    private LocalDate fechaInicio;

    @Column(name = "fecha_fin", nullable = false)
    private LocalDate fechaFin;

    public Long getIdPeriodo() { return idPeriodo; }
    public Long getIdAlojamiento() { return idAlojamiento; }
    public void setIdAlojamiento(Long idAlojamiento) { this.idAlojamiento = idAlojamiento; }
    public LocalDate getFechaInicio() { return fechaInicio; }
    public void setFechaInicio(LocalDate fechaInicio) { this.fechaInicio = fechaInicio; }
    public LocalDate getFechaFin() { return fechaFin; }
    public void setFechaFin(LocalDate fechaFin) { this.fechaFin = fechaFin; }

    // ¿La estadía [llegada, salida) cabe completa dentro del periodo?
    public boolean contiene(LocalDate llegada, LocalDate salida) {
        return !llegada.isBefore(fechaInicio) && !salida.isAfter(fechaFin);
    }
}
