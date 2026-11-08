# Correos desde la cuenta de Gmail (con foto de perfil)

Los correos salen por Brevo, y por eso Gmail muestra una letra ("A") en lugar
de la foto de la cuenta. Con este script los correos salen desde la propia
cuenta de Gmail (alojamientosmarketplace@gmail.com), y Gmail muestra su foto
de perfil. Si el script falla, el backend usa Brevo automáticamente.

Límite de Gmail gratis: unos 100 correos al día.

## Pasos (una sola vez)

1. Entra a <https://script.google.com> con la cuenta **alojamientosmarketplace@gmail.com**.
2. **Nuevo proyecto**. Borra lo que trae y pega el contenido de `Codigo.gs`. Ponle de nombre *StayHub correos* y guarda (ícono del disquete).
3. **Configuración del proyecto** (engranaje, a la izquierda) → **Propiedades del script** → **Agregar propiedad**:
   - Propiedad: `CLAVE`
   - Valor: una clave larga inventada por ustedes (no la compartan ni la suban a GitHub).
4. Arriba a la derecha: **Implementar** → **Nueva implementación** → en el engranaje elige **Aplicación web**:
   - Ejecutar como: **Yo**
   - Quién tiene acceso: **Cualquier usuario**
   - **Implementar** → **Autorizar acceso** → elige la cuenta → *Configuración avanzada* → *Ir a StayHub correos* → **Permitir**.
5. Copia la **URL de la aplicación web** (termina en `/exec`).
6. En Render → servicio del backend → **Environment** → agrega:
   - `GOOGLE_SCRIPT_URL` = la URL del paso 5
   - `GOOGLE_SCRIPT_CLAVE` = la misma clave del paso 3
   
   Guarda; Render vuelve a desplegar solo.
7. Foto visible para todos: en <https://myaccount.google.com> → **Información personal** → **Foto** → que sea visible para **cualquier persona**.

## Cómo saber si funciona

Crea una cuenta nueva en la página o pide el código para entrar. El correo debe
llegar con la foto de perfil de la cuenta. Gmail puede tardar unas horas en
mostrar la foto nueva la primera vez. En los logs de Render debe salir
`Correo enviado`; si el script falla, sale `El script de Gmail no envió el
correo, se intenta por otro medio` y el correo se envía por Brevo.

Si cambian el código del script: **Implementar** → **Gestionar implementaciones** →
lápiz → Versión: **Nueva versión** → Implementar (la URL no cambia).
