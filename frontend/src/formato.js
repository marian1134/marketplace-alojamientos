import { t, localeActual } from './idiomas'
// Formatos de dinero y fechas que usan las pantallas de reservas
export function pesos(valor) {
    if (valor === null || valor === undefined) {
        return '—';
    }
    return ('$' +
        Number(valor).toLocaleString(localeActual(), {
            maximumFractionDigits: 0,
        }) +
        ' COP');
}
// '2026-12-15' -> Date local (sin problemas de zona horaria)
export function aFecha(texto) {
    const [anio, mes, dia] = texto.split('-').map(Number);
    return new Date(anio, mes - 1, dia);
}
// Date -> '2026-12-15'
export function aTexto(fecha) {
    return [
        fecha.getFullYear(),
        String(fecha.getMonth() + 1).padStart(2, '0'),
        String(fecha.getDate()).padStart(2, '0'),
    ].join('-');
}
export function hoyTexto() {
    return aTexto(new Date());
}
export function fechaCorta(texto) {
    if (!texto) {
        return '';
    }
    return aFecha(texto).toLocaleDateString(localeActual(), {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
    });
}
export function contarNoches(entrada, salida) {
    if (!entrada || !salida) {
        return 0;
    }
    return Math.round((aFecha(salida) - aFecha(entrada)) / 86400000);
}
export const NOMBRES_ESTADO_RESERVA = {
    PENDIENTE_PAGO: 'Pendiente de pago',
    PENDIENTE_APROBACION: 'Esperando aprobación',
    CONFIRMADA: 'Confirmada',
    RECHAZADA: 'Rechazada',
    ANULADA: 'Anulada',
    CANCELADA: 'Cancelada',
    COMPLETADA: 'Completada',
};
export const NOMBRES_POLITICA = {
    FLEXIBLE: 'Cancelación flexible',
    MODERADA: 'Cancelación moderada',
    ESTRICTA: 'Cancelación estricta',
};
// Explica la política con palabras sencillas. Si se conoce la fecha de
// llegada, dice hasta qué día exacto se puede cancelar.
export function explicarPolitica(politica, fechaLlegada) {
    if (!politica) {
        return '';
    }
    const antes = Number(politica.porcentajeAntes);
    const despues = Number(politica.porcentajeDespues);
    const dias = politica.diasAnticipacion;
    const textoDias = t("{0} {1}", dias, dias === 1 ? t("d\u00EDa") : t("d\u00EDas"));
    const despuesTexto = despues > 0
        ? t("te devolvemos el {0} % del pago", despues) : t("no hay devoluci\u00F3n");
    let plazo = t("hasta {0} antes de la llegada", textoDias);
    if (fechaLlegada) {
        const limite = sumarDias(fechaLlegada, -dias);
        const hoy = hoyTexto();
        // La fecha límite ya pasó: solo aplica la regla de "después"
        if (limite < hoy) {
            return (t("Tu llegada es en menos de {0}, as\u00ED que ya pas\u00F3 el plazo ", textoDias) + t("de cancelaci\u00F3n con devoluci\u00F3n del {0} %. ", antes) + t("Si cancelas, {0}.", despuesTexto));
        }
        plazo = limite === hoy ? t("hasta hoy") : t("hasta el {0}", fechaCorta(limite));
    }
    const primera = antes === 100
        ? t("Cancelaci\u00F3n gratis {0}: te devolvemos el 100 % del pago.", plazo) : t("Si cancelas {0}, te devolvemos el {1} % del pago.", plazo, antes);
    const segunda = t("Si cancelas despu\u00E9s, {0}.", despuesTexto);
    return t("{0} {1}", primera, segunda);
}
// Nombre corto con mayúscula: 'Flexible', 'Moderada', 'Estricta'
export function nombreCortoPolitica(tipo) {
    const texto = (tipo ?? '').toLowerCase();
    return t(texto.charAt(0).toUpperCase() + texto.slice(1));
}
export function sumarDias(texto, dias) {
    const fecha = aFecha(texto);
    fecha.setDate(fecha.getDate() + dias);
    return aTexto(fecha);
}
// Límites de las fechas de la reserva
export const MAXIMO_NOCHES = 90;
export function fechaMaximaLlegada() {
    return sumarDias(hoyTexto(), 365);
}
export function plural(cantidad, uno, varios) {
    return `${cantidad} ${t(cantidad === 1 ? uno : varios)}`;
}
// Si una foto de internet no carga, se muestra la foto de la cabaña
export function fotoRespaldo(evento) {
    const imagen = evento.currentTarget;
    if (!imagen.dataset.respaldo) {
        imagen.dataset.respaldo = 'si';
        imagen.src = '/imagenes/registro-fondo.png';
    }
}
// $1.620.000 COP  o  US$405,00 USD
export function dinero(valor, moneda = 'COP') {
    if (valor === null || valor === undefined) {
        return '—';
    }
    if (moneda === 'USD') {
        return ('US$' +
            Number(valor).toLocaleString(localeActual(), {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
            }) +
            ' USD');
    }
    return pesos(valor);
}
// Total en pesos -> total en la moneda elegida (USD con 2 decimales)
export function convertirMoneda(valorCop, moneda, tasaUsd) {
    if (moneda === 'USD' && tasaUsd) {
        return Math.round((Number(valorCop) / Number(tasaUsd)) * 100) / 100;
    }
    return Number(valorCop);
}
// "15:00" o "15:00:00" → "3:00 p. m."
export function horaBonita(texto) {
    if (!texto) {
        return '';
    }
    const [horas, minutos] = texto.split(':').map(Number);
    const sufijo = horas < 12 ? t("a. m.") : t("p. m.");
    const hora12 = horas % 12 === 0 ? 12 : horas % 12;
    return `${hora12}:${String(minutos).padStart(2, '0')} ${sufijo}`;
}
