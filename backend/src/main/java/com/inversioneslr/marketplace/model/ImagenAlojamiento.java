package com.inversioneslr.marketplace.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

// Tabla marketplace.imagen (01_crear_marketplace.sql).
// La imagen principal es la de orden 0.
@Entity
@Table(name = "imagen")
public class ImagenAlojamiento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idImagen;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "publicacion_id", nullable = false, columnDefinition = "INT UNSIGNED")
    private Alojamiento alojamiento;

    @Column(name = "url", nullable = false, length = 500)
    private String urlImagen;

    @Column(name = "orden", nullable = false, columnDefinition = "SMALLINT")
    private Integer ordenImagen = 0;

    public ImagenAlojamiento() {
    }

    public boolean isPrincipal() {
        return ordenImagen != null && ordenImagen == 0;
    }

    public Long getIdImagen() {
        return idImagen;
    }

    public void setIdImagen(Long idImagen) {
        this.idImagen = idImagen;
    }

    public Alojamiento getAlojamiento() {
        return alojamiento;
    }

    public void setAlojamiento(Alojamiento alojamiento) {
        this.alojamiento = alojamiento;
    }

    public String getUrlImagen() {
        return urlImagen;
    }

    public void setUrlImagen(String urlImagen) {
        this.urlImagen = urlImagen;
    }

    public Integer getOrdenImagen() {
        return ordenImagen;
    }

    public void setOrdenImagen(Integer ordenImagen) {
        this.ordenImagen = ordenImagen;
    }
}
