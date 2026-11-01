package com.inversioneslr.marketplace.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;

// Tabla marketplace.politica_cancelacion. Las filas vienen de 02_datos_iniciales.sql.
@Entity
@Table(name = "politica_cancelacion")
public class PoliticaCancelacion {

    @Id
    @Column(name = "id", columnDefinition = "INT UNSIGNED")
    private Long idPolitica;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, unique = true, length = 20)
    private TipoPolitica tipo;

    @Column(name = "dias_anticipacion", nullable = false, columnDefinition = "SMALLINT")
    private Integer diasAnticipacion;

    @Column(name = "porcentaje_antes", nullable = false, precision = 5, scale = 2)
    private BigDecimal porcentajeAntes;

    @Column(name = "porcentaje_despues", nullable = false, precision = 5, scale = 2)
    private BigDecimal porcentajeDespues;

    @Column(name = "libera_fechas", nullable = false)
    private boolean liberaFechas;

    public PoliticaCancelacion() {
    }

    public Long getIdPolitica() {
        return idPolitica;
    }

    public TipoPolitica getTipo() {
        return tipo;
    }

    public Integer getDiasAnticipacion() {
        return diasAnticipacion;
    }

    public BigDecimal getPorcentajeAntes() {
        return porcentajeAntes;
    }

    public BigDecimal getPorcentajeDespues() {
        return porcentajeDespues;
    }

    public boolean isLiberaFechas() {
        return liberaFechas;
    }
}
