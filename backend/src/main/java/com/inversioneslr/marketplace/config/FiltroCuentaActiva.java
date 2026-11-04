package com.inversioneslr.marketplace.config;

import com.inversioneslr.marketplace.model.EstadoUsuario;
import com.inversioneslr.marketplace.repository.UsuarioRepository;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

public class FiltroCuentaActiva extends OncePerRequestFilter {
    private final UsuarioRepository usuarios;
    public FiltroCuentaActiva(UsuarioRepository usuarios) { this.usuarios = usuarios; }

    @Override
    protected void doFilterInternal(HttpServletRequest solicitud, HttpServletResponse respuesta,
                                    FilterChain cadena) throws ServletException, IOException {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        String ruta = solicitud.getServletPath();
        if (ruta.startsWith("/api/") && !ruta.equals("/api/usuarios/logout")
                && auth != null && auth.isAuthenticated() && !(auth instanceof AnonymousAuthenticationToken)) {
            var usuario = usuarios.findByCorreoIgnoreCase(auth.getName());
            if (usuario.isEmpty() || usuario.get().getEstado() != EstadoUsuario.ACTIVA) {
                var sesion = solicitud.getSession(false);
                if (sesion != null) sesion.invalidate();
                SecurityContextHolder.clearContext();
                respuesta.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                respuesta.setContentType("application/json");
                respuesta.setCharacterEncoding("UTF-8");
                respuesta.getWriter().write("{\"message\":\"Tu cuenta no está activa. La sesión se cerró.\"}");
                return;
            }
        }
        cadena.doFilter(solicitud, respuesta);
    }
}
