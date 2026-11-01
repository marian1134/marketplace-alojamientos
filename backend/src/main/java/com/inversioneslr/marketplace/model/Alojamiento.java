package com.inversioneslr.marketplace.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Tabla marketplace.publicacion (01_crear_marketplace.sql)
@Entity
@Table(name = "publicacion")
public class Alojamiento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idAlojamiento;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "anfitrion_id", nullable = false, columnDefinition = "INT UNSIGNED")
    private Usuario anfitrion;

    @Column(nullable = false, length = 120)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String descripcion;

    @Column(nullable = false, length = 80)
    private String ciudad;

    @Column(name = "ubicacion_descripcion", nullable = false, length = 200)
    private String direccion;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "tipo", nullable = false, length = 20)
    private TipoAlojamiento tipoAlojamiento;

    @Column(nullable = false, columnDefinition = "SMALLINT")
    private Integer capacidad;

    @Column(name = "precio_noche", nullable = false, precision = 12, scale = 2)
    private BigDecimal precioNoche;

    @Column(name = "tarifa_limpieza", nullable = false, precision = 12, scale = 2)
    private BigDecimal tarifaLimpieza = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "modo_reserva", nullable = false, length = 20)
    private ModoReserva modoReserva = ModoReserva.INMEDIATA;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "politica_id", nullable = false, columnDefinition = "INT UNSIGNED")
    private PoliticaCancelacion politica;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "etapa", nullable = false, length = 25)
    private EstadoPublicacion estado = EstadoPublicacion.BORRADOR;

    @Column(name = "motivo_etapa", length = 500)
    private String motivoEstado;

    @Column(name = "creado_en", nullable = false, updatable = false)
    private LocalDateTime fechaCreacion;

    @Column(name = "actualizado_en", nullable = false)
    private LocalDateTime fechaActualizacion;

    public Alojamiento() {
    }

    @PrePersist
    public void antesDeGuardar() {
        LocalDateTime ahora = LocalDateTime.now();
        if (fechaCreacion == null) {
            fechaCreacion = ahora;
        }
        fechaActualizacion = ahora;
    }

    @PreUpdate
    public void antesDeActualizar() {
        fechaActualizacion = LocalDateTime.now();
    }

    public Long getIdAlojamiento() {
        return idAlojamiento;
    }

    public void setIdAlojamiento(Long idAlojamiento) {
        this.idAlojamiento = idAlojamiento;
    }

    public Usuario getAnfitrion() {
        return anfitrion;
    }

    public void setAnfitrion(Usuario anfitrion) {
        this.anfitrion = anfitrion;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public String getCiudad() {
        return ciudad;
    }

    public void setCiudad(String ciudad) {
        this.ciudad = ciudad;
    }

    public String getDireccion() {
        return direccion;
    }

    public void setDireccion(String direccion) {
        this.direccion = direccion;
    }

    public TipoAlojamiento getTipoAlojamiento() {
        return tipoAlojamiento;
    }

    public void setTipoAlojamiento(TipoAlojamiento tipoAlojamiento) {
        this.tipoAlojamiento = tipoAlojamiento;
    }

    public Integer getCapacidad() {
        return capacidad;
    }

    public void setCapacidad(Integer capacidad) {
        this.capacidad = capacidad;
    }

    public BigDecimal getPrecioNoche() {
        return precioNoche;
    }

    public void setPrecioNoche(BigDecimal precioNoche) {
        this.precioNoche = precioNoche;
    }

    public BigDecimal getTarifaLimpieza() {
        return tarifaLimpieza;
    }

    public void setTarifaLimpieza(BigDecimal tarifaLimpieza) {
        this.tarifaLimpieza = tarifaLimpieza;
    }

    public ModoReserva getModoReserva() {
        return modoReserva;
    }

    public void setModoReserva(ModoReserva modoReserva) {
        this.modoReserva = modoReserva;
    }

    public PoliticaCancelacion getPolitica() {
        return politica;
    }

    public void setPolitica(PoliticaCancelacion politica) {
        this.politica = politica;
    }

    public EstadoPublicacion getEstado() {
        return estado;
    }

    public void setEstado(EstadoPublicacion estado) {
        this.estado = estado;
    }

    public String getMotivoEstado() {
        return motivoEstado;
    }

    public void setMotivoEstado(String motivoEstado) {
        this.motivoEstado = motivoEstado;
    }

    public LocalDateTime getFechaCreacion() {
        return fechaCreacion;
    }

    public LocalDateTime getFechaActualizacion() {
        return fechaActualizacion;
    }
}
