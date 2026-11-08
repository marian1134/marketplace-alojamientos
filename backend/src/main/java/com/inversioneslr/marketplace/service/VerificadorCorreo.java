package com.inversioneslr.marketplace.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.naming.NameNotFoundException;
import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;
import javax.naming.directory.InitialDirContext;
import java.util.Hashtable;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

/**
 * Revisa que un correo pueda existir de verdad: formato válido y un dominio
 * que reciba correos (registro MX o, en su defecto, una dirección en el DNS).
 * Así no se aceptan direcciones inventadas como ana@nada.xyz.
 */
@Component
public class VerificadorCorreo {

    private static final Logger log = LoggerFactory.getLogger(VerificadorCorreo.class);

    // usuario@dominio.ext: letras, números y . _ % + - antes de la @; extensión de 2 letras o más
    private static final Pattern FORMATO = Pattern.compile(
            "^[A-Za-z0-9._%+-]{1,64}@(?=.{4,190}$)([A-Za-z0-9-]+\\.)+[A-Za-z]{2,24}$");

    private final boolean revisarDominio;
    private final Map<String, Boolean> dominiosRevisados = new ConcurrentHashMap<>();

    public VerificadorCorreo(@Value("${app.correo.verificar-dominio:true}") boolean revisarDominio) {
        this.revisarDominio = revisarDominio;
    }

    public static boolean formatoValido(String correo) {
        return correo != null && FORMATO.matcher(correo).matches()
                && !correo.contains("..") && !correo.startsWith(".");
    }

    // true si el dominio recibe correos. Si el DNS no responde, no se bloquea el registro.
    public boolean dominioRecibeCorreos(String correo) {
        if (!revisarDominio) return true;
        String dominio = correo.substring(correo.indexOf('@') + 1).toLowerCase(Locale.ROOT);
        return dominiosRevisados.computeIfAbsent(dominio, VerificadorCorreo::consultarDns);
    }

    private static Boolean consultarDns(String dominio) {
        Hashtable<String, String> entorno = new Hashtable<>();
        entorno.put("java.naming.factory.initial", "com.sun.jndi.dns.DnsContextFactory");
        entorno.put("com.sun.jndi.dns.timeout.initial", "2000");
        entorno.put("com.sun.jndi.dns.timeout.retries", "1");
        try {
            InitialDirContext dns = new InitialDirContext(entorno);
            Attributes registros = dns.getAttributes(dominio, new String[] {"MX", "A", "AAAA"});
            for (String tipo : new String[] {"MX", "A", "AAAA"}) {
                Attribute registro = registros.get(tipo);
                if (registro != null && registro.size() > 0) return true;
            }
            return false;
        } catch (NameNotFoundException noExiste) {
            return false;
        } catch (NamingException errorDns) {
            // Sin respuesta del DNS (red caída): se deja pasar para no bloquear a nadie
            log.warn("No se pudo revisar el dominio {}: {}", dominio, errorDns.getMessage());
            return true;
        }
    }
}
