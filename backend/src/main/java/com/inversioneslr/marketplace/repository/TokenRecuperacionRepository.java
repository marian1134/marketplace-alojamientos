package com.inversioneslr.marketplace.repository;

import com.inversioneslr.marketplace.model.TokenRecuperacion;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;

import java.util.Optional;

public interface TokenRecuperacionRepository
        extends JpaRepository<TokenRecuperacion, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<TokenRecuperacion> findByTokenHash(String tokenHash);
}