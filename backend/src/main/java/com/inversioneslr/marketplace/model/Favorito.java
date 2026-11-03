package com.inversioneslr.marketplace.model;

import jakarta.persistence.*;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Objects;

// Tabla marketplace.favorito (06_resenas_favoritos.sql):
// alojamientos que cada usuario guardó con el corazón
@Entity
@Table(name = "favorito")
@IdClass(Favorito.Llave.class)
public class Favorito {

    @Id
    @Column(name = "usuario_id", columnDefinition = "INT UNSIGNED")
    private Long idUsuario;

    @Id
    @Column(name = "publicacion_id", columnDefinition = "INT UNSIGNED")
    private Long idAlojamiento;

    @Column(name = "creado_en", nullable = false)
    private LocalDateTime creadoEn;

    public Favorito() {
    }

    public Favorito(Long idUsuario, Long idAlojamiento) {
        this.idUsuario = idUsuario;
        this.idAlojamiento = idAlojamiento;
        this.creadoEn = LocalDateTime.now();
    }

    public Long getIdUsuario() { return idUsuario; }
    public Long getIdAlojamiento() { return idAlojamiento; }
    public LocalDateTime getCreadoEn() { return creadoEn; }

    public static class Llave implements Serializable {

        private Long idUsuario;
        private Long idAlojamiento;

        public Llave() {
        }

        public Llave(Long idUsuario, Long idAlojamiento) {
            this.idUsuario = idUsuario;
            this.idAlojamiento = idAlojamiento;
        }

        @Override
        public boolean equals(Object otro) {
            if (this == otro) return true;
            if (!(otro instanceof Llave llave)) return false;
            return Objects.equals(idUsuario, llave.idUsuario)
                    && Objects.equals(idAlojamiento, llave.idAlojamiento);
        }

        @Override
        public int hashCode() {
            return Objects.hash(idUsuario, idAlojamiento);
        }
    }
}
