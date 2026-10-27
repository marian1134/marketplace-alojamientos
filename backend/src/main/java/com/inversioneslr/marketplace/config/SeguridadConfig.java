package com.inversioneslr.marketplace.config;

import jakarta.servlet.DispatcherType;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SeguridadConfig {

    @Bean
    public SecurityFilterChain configurarSeguridad(
            HttpSecurity http) throws Exception {

        http
                .authorizeHttpRequests(rutas -> rutas
                        .dispatcherTypeMatchers(DispatcherType.ERROR)
                        .permitAll()

                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/estado",
                                "/api/usuarios/csrf"
                        )
                        .permitAll()

                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/usuarios/registro",
                                "/api/usuarios/login",
                                "/api/usuarios/recuperar",
                                "/api/usuarios/nueva-clave"
                        )
                        .permitAll()

                        .anyRequest()
                        .authenticated()
                )

                .sessionManagement(sesion -> sesion
                        .sessionCreationPolicy(
                                SessionCreationPolicy.IF_REQUIRED
                        )
                )

                .exceptionHandling(errores -> errores
                        .authenticationEntryPoint(
                                (solicitud, respuesta, excepcion) ->
                                        respuesta.setStatus(
                                                HttpServletResponse.SC_UNAUTHORIZED
                                        )
                        )
                )

                .requestCache(cache -> cache.disable())

                .formLogin(formulario -> formulario.disable())

                .httpBasic(basico -> basico.disable())

                .logout(salida -> salida
                        .logoutUrl("/api/usuarios/logout")
                        .invalidateHttpSession(true)
                        .clearAuthentication(true)
                        .deleteCookies("JSESSIONID")
                        .logoutSuccessHandler(
                                (solicitud, respuesta, autenticacion) ->
                                        respuesta.setStatus(
                                                HttpServletResponse.SC_NO_CONTENT
                                        )
                        )
                );

        return http.build();
    }
}