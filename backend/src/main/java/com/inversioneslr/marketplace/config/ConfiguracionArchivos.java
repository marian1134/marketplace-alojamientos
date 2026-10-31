package com.inversioneslr.marketplace.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;

@Configuration
public class ConfiguracionArchivos implements WebMvcConfigurer {

    private final Path carpetaImagenes;

    public ConfiguracionArchivos(
            @Value("${app.ruta-imagenes:uploads/alojamientos}")
            String rutaImagenes) {

        this.carpetaImagenes = Path.of(rutaImagenes)
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
    }
}