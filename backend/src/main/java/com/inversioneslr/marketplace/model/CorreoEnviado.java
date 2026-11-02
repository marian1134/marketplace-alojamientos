package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;

// Tabla marketplace.correo_enviado: a quién se envió cada aviso y si funcionó
@Entity
@Table(name = "correo_enviado")
public class CorreoEnviado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idCorreo;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "notificacion_id", nullable = false, unique = true, columnDefinition = "INT UNSIGNED")
    private Notificacion notificacion;

    @Column(nullable = false, length = 150)
    private String destinatario;

    @Column(nullable = false, length = 150)
    private String asunto;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, length = 10)
    private EstadoCorreo estado = EstadoCorreo.PENDIENTE;

    @Column(nullable = false, columnDefinition = "SMALLINT")
    private Integer intentos = 0;

    @Column(length = 500)
    private String error;

    @Column(name = "enviado_en")
    private LocalDateTime enviadoEn;

    @Column(name = "creado_en", nullable = false)
    private LocalDateTime creadoEn;

    @PrePersist
    public void antesDeGuardar() {
        if (creadoEn == null) {
            creadoEn = LocalDateTime.now();
        }
    }

    public Long getIdCorreo() { return idCorreo; }
    public Notificacion getNotificacion() { return notificacion; }
    public void setNotificacion(Notificacion notificacion) { this.notificacion = notificacion; }
    public String getDestinatario() { return destinatario; }
    public void setDestinatario(String destinatario) { this.destinatario = destinatario; }
    public String getAsunto() { return asunto; }
    public void setAsunto(String asunto) { this.asunto = asunto; }
    public EstadoCorreo getEstado() { return estado; }
    public void setEstado(EstadoCorreo estado) { this.estado = estado; }
    public Integer getIntentos() { return intentos; }
    public void setIntentos(Integer intentos) { this.intentos = intentos; }
    public String getError() { return error; }
    public void setError(String error) { this.error = error; }
    public LocalDateTime getEnviadoEn() { return enviadoEn; }
    public void setEnviadoEn(LocalDateTime enviadoEn) { this.enviadoEn = enviadoEn; }
    public LocalDateTime getCreadoEn() { return creadoEn; }
}
