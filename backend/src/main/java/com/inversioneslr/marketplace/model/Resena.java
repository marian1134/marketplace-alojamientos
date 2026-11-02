package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

// Tabla marketplace.resena: una reseña por reserva completada
@Entity
@Table(name = "resena")
public class Resena {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idResena;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reserva_id", nullable = false, unique = true, columnDefinition = "INT UNSIGNED")
    private Reserva reserva;

    @Column(nullable = false, columnDefinition = "SMALLINT")
    private Integer calificacion;

    @Column(nullable = false, length = 1000)
    private String comentario;

    @Column(nullable = false)
    private LocalDateTime fecha;

    @Column(nullable = false)
    private boolean visible = true;

    @Column(name = "motivo_ocultamiento", length = 500)
    private String motivoOcultamiento;

    @Column(name = "ocultada_por", columnDefinition = "INT UNSIGNED")
    private Long ocultadaPor;

    @PrePersist
    public void antesDeGuardar() {
        if (fecha == null) {
            fecha = LocalDateTime.now();
        }
    }

    public Long getIdResena() { return idResena; }
    public Reserva getReserva() { return reserva; }
    public void setReserva(Reserva reserva) { this.reserva = reserva; }
    public Integer getCalificacion() { return calificacion; }
    public void setCalificacion(Integer calificacion) { this.calificacion = calificacion; }
    public String getComentario() { return comentario; }
    public void setComentario(String comentario) { this.comentario = comentario; }
    public LocalDateTime getFecha() { return fecha; }
    public boolean isVisible() { return visible; }
}
