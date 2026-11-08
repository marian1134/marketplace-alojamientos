package com.inversioneslr.marketplace.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

// Servicio (amenity) que ofrece un alojamiento: Wifi, piscina, cocina...
@Entity
@Table(name = "servicio")
public class Servicio {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idServicio;

    @Column(nullable = false, length = 60, unique = true)
    private String nombre;

    public Long getIdServicio() {
        return idServicio;
    }

    public String getNombre() {
        return nombre;
    }
}
