package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "mensaje_reserva")
public class MensajeReserva {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idMensaje;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reserva_id", nullable = false, columnDefinition = "INT UNSIGNED")
    private Reserva reserva;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "remitente_id", nullable = false, columnDefinition = "INT UNSIGNED")
    private Usuario remitente;

    @Column(nullable = false, length = 2000)
    private String contenido;

    @Column(name = "clave_cliente", nullable = false, columnDefinition = "CHAR(36)")
    private String claveCliente;

    @Column(name = "creada_en", nullable = false, updatable = false)
    private LocalDateTime creadaEn;

    @PrePersist
    public void antesDeGuardar() {
        if (creadaEn == null) creadaEn = LocalDateTime.now();
    }

    public Long getIdMensaje() { return idMensaje; }
    public Reserva getReserva() { return reserva; }
    public void setReserva(Reserva reserva) { this.reserva = reserva; }
    public Usuario getRemitente() { return remitente; }
    public void setRemitente(Usuario remitente) { this.remitente = remitente; }
    public String getContenido() { return contenido; }
    public void setContenido(String contenido) { this.contenido = contenido; }
    public String getClaveCliente() { return claveCliente; }
    public void setClaveCliente(String claveCliente) { this.claveCliente = claveCliente; }
    public LocalDateTime getCreadaEn() { return creadaEn; }
}
