package com.inversioneslr.marketplace.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;

@Configuration
public class ConfiguracionArchivos implements WebMvcConfigurer {

    private final Path carpetaImagenes;
    private final Path carpetaFotosPerfil;

    public ConfiguracionArchivos(
            @Value("${app.ruta-imagenes:uploads/alojamientos}")
            String rutaImagenes,
            @Value("${app.ruta-fotos-perfil:uploads/perfiles}")
            String rutaFotosPerfil) {

        this.carpetaImagenes = Path.of(rutaImagenes)
                .toAbsolutePath()
                .normalize();

        this.carpetaFotosPerfil = Path.of(rutaFotosPerfil)
                .toAbsolutePath()
                .normalize();
    }

    @Override
    public void addResourceHandlers(
            ResourceHandlerRegistry registry) {

        registry
                .addResourceHandler("/uploads/alojamientos/**")
                .addResourceLocations(
                        carpetaImagenes.toUri().toString()
                );

        registry
                .addResourceHandler("/uploads/perfiles/**")
                .addResourceLocations(
                        carpetaFotosPerfil.toUri().toString()
                );
    }
}
