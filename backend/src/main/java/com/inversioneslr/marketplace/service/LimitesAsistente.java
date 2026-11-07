package com.inversioneslr.marketplace.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.time.Clock;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.Semaphore;

/** Limites para una presentacion: 200 intentos totales, 30/hora por cuenta, 2 simultaneos.
 * El contador total se guarda ANTES de llamar a la IA (Gemini) y no se devuelve si hay timeout.
 * Conservar el archivo entre reinicios/despliegues. No es un presupuesto monetario del proveedor.
 */
@Component
public class LimitesAsistente {
    private static final int MAXIMO_TOTAL = 200;
    private static final int MAXIMO_POR_HORA = 30;
    private final Path archivo;
    private final Clock reloj;
    private final Semaphore simultaneas = new Semaphore(2);
    private final Map<Long, Ventana> usuarios = new HashMap<>();

    @Autowired
    public LimitesAsistente(@Value("${app.ia.archivo-limites:./datos/asistente-ia-limites.properties}") String archivo) {
        this(Path.of(archivo).toAbsolutePath().normalize(), Clock.systemUTC());
    }

    LimitesAsistente(Path archivo, Clock reloj) { this.archivo = archivo; this.reloj = reloj; }

    public synchronized Turno reservar(Long usuario) {
        Instant ahora = reloj.instant();
        usuarios.entrySet().removeIf(e -> !ahora.isBefore(e.getValue().inicio.plusSeconds(3600)));
        Ventana ventana = usuarios.get(usuario);
        if (ventana != null && (ventana.intentos >= MAXIMO_POR_HORA
                || ahora.isBefore(ventana.ultimo.plusSeconds(3)))) {
            throw new FalloAsistente(HttpStatus.TOO_MANY_REQUESTS, "IA_LIMITE_USUARIO");
        }
        if (!simultaneas.tryAcquire()) {
            throw new FalloAsistente(HttpStatus.TOO_MANY_REQUESTS, "IA_OCUPADA");
        }
        try {
            incrementarTotal();
            if (ventana == null) ventana = new Ventana(ahora);
            ventana.intentos++;
            ventana.ultimo = ahora;
            usuarios.put(usuario, ventana);
            return new Turno();
        } catch (RuntimeException error) {
            simultaneas.release();
            throw error;
        }
    }

    private void incrementarTotal() {
        Path temporal = null;
        try {
            Files.createDirectories(archivo.getParent());
            // Archivo de bloqueo independiente: el contador se reemplaza atomicamente.
            try (FileChannel canal = FileChannel.open(archivo.resolveSibling(archivo.getFileName() + ".lock"),
                    StandardOpenOption.CREATE, StandardOpenOption.WRITE);
                 FileLock bloqueo = canal.lock()) {
                int total = 0;
                if (Files.exists(archivo)) {
                    Properties datos = new Properties();
                    try (InputStream entrada = Files.newInputStream(archivo)) { datos.load(entrada); }
                    if (!"1".equals(datos.getProperty("version"))) throw new IOException("Version no valida");
                    total = Integer.parseInt(datos.getProperty("intentos", "-1"));
                    if (total < 0) throw new IOException("Contador no valido");
                }
                if (total >= MAXIMO_TOTAL) {
                    throw new FalloAsistente(HttpStatus.TOO_MANY_REQUESTS, "IA_LIMITE_TOTAL");
                }
                Properties datos = new Properties();
                datos.setProperty("version", "1");
                datos.setProperty("intentos", Integer.toString(total + 1));
                temporal = Files.createTempFile(archivo.getParent(), "ia-limites-", ".tmp");
                try (OutputStream salida = Files.newOutputStream(temporal)) {
                    datos.store(salida, "StayHub: intentos IA reservados, incluidos errores del proveedor");
                }
                // Si el volumen no permite reemplazo atomico, falla sin hacer la llamada de pago.
                Files.move(temporal, archivo, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
            }
        } catch (FalloAsistente error) {
            throw error;
        } catch (IOException | RuntimeException error) {
            throw new FalloAsistente(HttpStatus.SERVICE_UNAVAILABLE, "IA_CONTADOR_NO_DISPONIBLE");
        } finally {
            if (temporal != null) {
                try { Files.deleteIfExists(temporal); } catch (IOException ignorado) { }
            }
        }
    }

    public final class Turno implements AutoCloseable {
        private boolean cerrado;
        @Override public synchronized void close() {
            if (!cerrado) { cerrado = true; simultaneas.release(); }
        }
    }

    private static class Ventana {
        private final Instant inicio;
        private Instant ultimo;
        private int intentos;
        private Ventana(Instant inicio) { this.inicio = inicio; this.ultimo = inicio; }
    }
}
