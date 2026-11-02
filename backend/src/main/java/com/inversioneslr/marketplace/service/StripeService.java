package com.inversioneslr.marketplace.service;

import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.model.PaymentMethod;
import com.stripe.model.Refund;
import com.stripe.net.RequestOptions;
import com.stripe.param.PaymentIntentCreateParams;
import com.stripe.param.PaymentIntentRetrieveParams;
import com.stripe.param.RefundCreateParams;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

// Conexión con Stripe. Si no hay clave secreta, Stripe queda apagado y la
// app usa el pago simulado.
@Service
public class StripeService {

    private static final Logger log = LoggerFactory.getLogger(StripeService.class);

    private final String claveSecreta;
    private final String clavePublica;

    public StripeService(
            @Value("${stripe.clave-secreta:}") String claveSecreta,
            @Value("${stripe.clave-publica:}") String clavePublica) {

        this.claveSecreta = claveSecreta == null ? "" : claveSecreta.trim();
        this.clavePublica = clavePublica == null ? "" : clavePublica.trim();
    }

    public boolean activo() {
        return !claveSecreta.isEmpty() && !clavePublica.isEmpty();
    }

    public String getClavePublica() {
        return clavePublica;
    }

    // Crea la intención de pago que el navegador confirma con la tarjeta
    public PaymentIntent crearIntencion(
            long centavos,
            String moneda,
            String descripcion,
            Map<String, String> datos,
            String claveIdempotencia) {

        PaymentIntentCreateParams parametros = PaymentIntentCreateParams.builder()
                .setAmount(centavos)
                .setCurrency(moneda.toLowerCase())
                .addPaymentMethodType("card")
                .setDescription(descripcion)
                .putAllMetadata(datos)
                .build();

        try {
            return PaymentIntent.create(parametros, opciones(claveIdempotencia));
        } catch (StripeException excepcion) {
            log.warn("Stripe no creó la intención de pago: {}", excepcion.getMessage());
            throw errorStripe(excepcion, "No se pudo iniciar el pago con Stripe.");
        }
    }

    public PaymentIntent obtener(String idIntencion) {

        PaymentIntentRetrieveParams parametros = PaymentIntentRetrieveParams.builder()
                .addExpand("payment_method")
                .build();

        try {
            return PaymentIntent.retrieve(idIntencion, parametros, opciones(null));
        } catch (StripeException excepcion) {
            throw errorStripe(excepcion, "No se pudo verificar el pago con Stripe.");
        }
    }

    // Últimos 4 dígitos de la tarjeta con que se pagó
    public String ultimos4(PaymentIntent intencion) {

        PaymentMethod metodo = intencion.getPaymentMethodObject();

        if (metodo != null && metodo.getCard() != null) {
            return metodo.getCard().getLast4();
        }

        return null;
    }

    // Devuelve dinero a la tarjeta. centavos = null devuelve todo.
    public void reembolsar(String idIntencion, Long centavos) {

        RefundCreateParams.Builder parametros = RefundCreateParams.builder()
                .setPaymentIntent(idIntencion);

        if (centavos != null) {
            parametros.setAmount(centavos);
        }

        try {
            Refund.create(parametros.build(), opciones(null));
        } catch (StripeException excepcion) {
            log.warn("Stripe no hizo la devolución: {}", excepcion.getMessage());
            throw errorStripe(excepcion, "No se pudo hacer la devolución en Stripe.");
        }
    }

    private RequestOptions opciones(String claveIdempotencia) {

        RequestOptions.RequestOptionsBuilder opciones = RequestOptions.builder()
                .setApiKey(claveSecreta);

        if (claveIdempotencia != null) {
            opciones.setIdempotencyKey(claveIdempotencia);
        }

        return opciones.build();
    }

    private ResponseStatusException errorStripe(StripeException excepcion, String mensaje) {

        String detalle = excepcion.getStripeError() != null
                && excepcion.getStripeError().getMessage() != null
                ? " " + excepcion.getStripeError().getMessage()
                : "";

        return new ResponseStatusException(HttpStatus.BAD_GATEWAY, mensaje + detalle);
    }
}
