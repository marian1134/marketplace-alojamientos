package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;

import java.io.Serializable;
import java.time.LocalDate;
import java.util.Objects;

// Tabla marketplace.noche_reservada: una fila por noche ocupada.
// La llave (publicacion_id, fecha) impide reservar dos veces la misma noche.
@Entity
@Table(name = "noche_reservada")
@IdClass(NocheReservada.Llave.class)
public class NocheReservada {

    @Id
    @Column(name = "publicacion_id", columnDefinition = "INT UNSIGNED")
    private Long idAlojamiento;

    @Id
    @Column(nullable = false)
    private LocalDate fecha;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reserva_id", nullable = false, columnDefinition = "INT UNSIGNED")
    private Reserva reserva;

    public NocheReservada() {
    }

    public NocheReservada(Long idAlojamiento, LocalDate fecha, Reserva reserva) {
        this.idAlojamiento = idAlojamiento;
        this.fecha = fecha;
        this.reserva = reserva;
    }

    public Long getIdAlojamiento() { return idAlojamiento; }
    public LocalDate getFecha() { return fecha; }
    public Reserva getReserva() { return reserva; }

    public static class Llave implements Serializable {

        private Long idAlojamiento;
        private LocalDate fecha;

        public Llave() {
        }

        @Override
        public boolean equals(Object otro) {
            if (this == otro) return true;
            if (!(otro instanceof Llave llave)) return false;
            return Objects.equals(idAlojamiento, llave.idAlojamiento)
                    && Objects.equals(fecha, llave.fecha);
        }

        @Override
        public int hashCode() {
            return Objects.hash(idAlojamiento, fecha);
        }
    }
}
