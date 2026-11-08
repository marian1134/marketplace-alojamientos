package com.inversioneslr.marketplace.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// Contrato de la API REST: /v3/api-docs (JSON) y /swagger-ui.html (página)
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI contratoStayHub() {
        return new OpenAPI().info(new Info()
                .title("StayHub · API del Marketplace de Alojamientos")
                .version("1.0.0")
                .description("Servicios REST de Inversiones LR: usuarios, alojamientos, disponibilidad, búsqueda, "
                        + "cotización, reservas, pagos (Stripe en modo prueba), notificaciones, reseñas y administración. "
                        + "La autenticación es por sesión (cookie) y las operaciones que modifican datos requieren el token CSRF "
                        + "de GET /api/usuarios/csrf.")
                .contact(new Contact().name("Equipo StayHub").url("https://github.com/marian1134/marketplace-alojamientos")));
    }
}
