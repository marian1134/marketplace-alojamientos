package com.inversioneslr.marketplace.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
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
import java.util.function.Function;
import java.util.regex.Pattern;

/**
 * Revisa que un correo pueda existir de verdad: formato válido y un dominio
 * que reciba correos (registro MX o, en su defecto, una dirección en el DNS).
 * Así no se aceptan direcciones inventadas como ana@nada.xyz.
 */
@Component
public class VerificadorCorreo {

    private static final Logger log = LoggerFactory.getLogger(VerificadorCorreo.class);

    // Parte antes de la @ y cada parte del dominio. Se revisan por separado
    // (sin repeticiones anidadas) para que la validación sea siempre rápida.
    private static final Pattern USUARIO = Pattern.compile("[A-Za-z0-9._%+-]{1,64}");
    private static final Pattern PARTE_DOMINIO = Pattern.compile("[A-Za-z0-9-]{1,63}");
    private static final Pattern EXTENSION = Pattern.compile("[A-Za-z]{2,24}");

    private final boolean revisarDominio;
    private final Function<String, Boolean> consulta;
    private final Map<String, Boolean> dominiosRevisados = new ConcurrentHashMap<>();

    @Autowired
    public VerificadorCorreo(@Value("${app.correo.verificar-dominio:true}") boolean revisarDominio) {
        this(revisarDominio, VerificadorCorreo::consultarDns);
    }

    // Para las pruebas: permite simular la respuesta del DNS
    VerificadorCorreo(boolean revisarDominio, Function<String, Boolean> consulta) {
        this.revisarDominio = revisarDominio;
        this.consulta = consulta;
    }

    public static boolean formatoValido(String correo) {
        if (correo == null || correo.length() > 190) return false;
        int arroba = correo.indexOf('@');
        if (arroba <= 0 || arroba != correo.lastIndexOf('@')) return false;
        String usuario = correo.substring(0, arroba);
        if (!USUARIO.matcher(usuario).matches() || usuario.startsWith(".") || usuario.contains("..")) return false;
        String[] partes = correo.substring(arroba + 1).split("\\.", -1);
        if (partes.length < 2) return false;
        for (int i = 0; i < partes.length - 1; i++) {
            if (!PARTE_DOMINIO.matcher(partes[i]).matches()) return false;
        }
        return EXTENSION.matcher(partes[partes.length - 1]).matches();
    }

    // true si el dominio recibe correos. Si el DNS no responde, no se bloquea el registro.
    public boolean dominioRecibeCorreos(String correo) {
        if (!revisarDominio) return true;
        String dominio = correo.substring(correo.indexOf('@') + 1).toLowerCase(Locale.ROOT);
        return dominiosRevisados.computeIfAbsent(dominio, consulta);
    }

    static Boolean consultarDns(String dominio) {
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
