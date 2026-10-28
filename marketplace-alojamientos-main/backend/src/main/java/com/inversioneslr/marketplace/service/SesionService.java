package com.inversioneslr.marketplace.service;

import com.inversioneslr.marketplace.dto.InicioSesionRequest;
import com.inversioneslr.marketplace.dto.UsuarioResponse;
import com.inversioneslr.marketplace.repository.UsuarioRolRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.session.ChangeSessionIdAuthenticationStrategy;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.csrf.CsrfAuthenticationStrategy;
import org.springframework.security.web.csrf.HttpSessionCsrfTokenRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
public class SesionService {

    private final UsuarioService usuarioService;
    private final UsuarioRolRepository roles;

    public SesionService(
            UsuarioService usuarioService,
            UsuarioRolRepository roles) {

        this.usuarioService = usuarioService;
        this.roles = roles;
    }

    @Transactional(readOnly = true)
    public UsuarioResponse iniciarSesion(
            InicioSesionRequest datos,
            HttpServletRequest solicitud,
            HttpServletResponse respuesta) {

        UsuarioResponse usuario = usuarioService.iniciarSesion(datos);

        var permisos = roles
                .findByUsuario_IdUsuarioAndEstadoTrue(
                        usuario.idUsuario()
                )
                .stream()
                .map(asignacion -> new SimpleGrantedAuthority(
                        "ROLE_" + asignacion.getRol()
                                .getNombre()
                                .toUpperCase(Locale.ROOT)
                ))
                .toList();

        var autenticacion =
                UsernamePasswordAuthenticationToken.authenticated(
                        usuario.correo(),
                        null,
                        permisos
                );

        var cambioSesion =
                new ChangeSessionIdAuthenticationStrategy();

        cambioSesion.onAuthentication(
                autenticacion,
                solicitud,
                respuesta
        );

        var proteccionCsrf = new CsrfAuthenticationStrategy(
                new HttpSessionCsrfTokenRepository()
        );

        proteccionCsrf.onAuthentication(
                autenticacion,
                solicitud,
                respuesta
        );

        SecurityContext contexto =
                SecurityContextHolder.createEmptyContext();

        contexto.setAuthentication(autenticacion);
        SecurityContextHolder.setContext(contexto);

        var repositorioSesion =
                new HttpSessionSecurityContextRepository();

        repositorioSesion.saveContext(
                contexto,
                solicitud,
                respuesta
        );

        solicitud.getSession().setMaxInactiveInterval(30 * 60);

        return usuario;
    }
}