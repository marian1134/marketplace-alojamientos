package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.Notificacion;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface NotificacionRepository
        extends JpaRepository<Notificacion, Long> {

    @Query("""
            SELECT n
            FROM Notificacion n
            WHERE LOWER(n.usuario.correo) = LOWER(:correo)
            ORDER BY n.creadaEn DESC, n.idNotificacion DESC
            """)
    List<Notificacion> buscarDelUsuario(
            @Param("correo") String correo,
            Pageable pagina);

    @Query("""
            SELECT COUNT(n)
            FROM Notificacion n
            WHERE LOWER(n.usuario.correo) = LOWER(:correo)
              AND n.leida = false
            """)
    long contarSinLeer(@Param("correo") String correo);

    @Query("""
            SELECT n
            FROM Notificacion n
            WHERE n.idNotificacion = :id
              AND LOWER(n.usuario.correo) = LOWER(:correo)
            """)
    Optional<Notificacion> buscarPropia(
            @Param("id") Long id,
            @Param("correo") String correo);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE Notificacion n
            SET n.leida = true
            WHERE LOWER(n.usuario.correo) = LOWER(:correo)
              AND n.leida = false
            """)
    int marcarTodasLeidas(@Param("correo") String correo);
}