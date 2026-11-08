# Publicar StayHub en internet (y usarla como app en el celular)

Se publican 3 partes, todas con plan gratis:

| Parte | Servicio | Resultado |
|---|---|---|
| Base de datos MySQL | **Aiven** (aiven.io) | Guarda usuarios, alojamientos y reservas |
| Backend (Java) | **Render** (render.com) | `https://stayhub-backend.onrender.com` |
| Frontend (página) | **Vercel** (vercel.com) | `https://stayhub-….vercel.app` (con HTTPS) |

> Los planes gratis cambian con el tiempo. Si alguno ya no es gratis, se puede usar otro
> servicio equivalente: el proyecto solo necesita MySQL 8, un servicio que corra Docker y
> un hosting de páginas estáticas.

## 0. Copia del repositorio (fork)

Render y Vercel solo leen repositorios de la propia cuenta. Con tu cuenta de GitHub:

1. Entra a https://github.com/marian1134/marketplace-alojamientos
2. Arriba a la derecha: **Fork** → **Create fork**.
3. Cuando el repositorio original tenga cambios nuevos, en tu fork: **Sync fork** → **Update branch**.

## 1. Base de datos en Aiven

1. Crea una cuenta en https://aiven.io (puede ser con Google o GitHub).
2. **Create service** → **MySQL** → plan **Free** → elige la región más cercana → **Create**.
3. Espera a que diga **Running** (unos minutos).
4. En **Connection information** copia: **Host**, **Port**, **User** (`avnadmin`) y **Password**.
5. En **MySQL Workbench**: **+** (nueva conexión):
   - Hostname y Port: los de Aiven.
   - Username: `avnadmin` · Password: **Store in Vault** → pega la de Aiven.
   - Pestaña **SSL** → Use SSL: **Require**.
   - **Test Connection** → **OK**.
6. Abre esa conexión y ejecuta, en orden, los scripts de `backend/database`:
   `01`, `02`, `03`, `04`, `05`, `06`, `07`, `08`, `09`, `10`, `11`, `13`, `14` y `16`.

## 2. Backend en Render

1. Crea una cuenta en https://render.com con **GitHub**.
2. **New** → **Web Service** → elige tu fork `marketplace-alojamientos`.
3. Configura:
   - **Name:** `stayhub-backend` (así la dirección queda igual a la que espera el frontend).
   - **Root Directory:** `backend`
   - **Runtime / Language:** **Docker**
   - **Instance type:** **Free**
4. En **Environment Variables** agrega:

| Nombre | Valor |
|---|---|
| `DB_URL` | `jdbc:mysql://HOST:PORT/marketplace?sslMode=REQUIRED` (con el Host y Port de Aiven) |
| `DB_USERNAME` | `avnadmin` |
| `DB_PASSWORD` | la contraseña de Aiven |
| `MAIL_USERNAME` | `alojamientosmarketplace@gmail.com` |
| `MAIL_PASSWORD` | la contraseña de aplicación del correo |
| `GEMINI_API_KEY` | la clave de Gemini |
| `URL_FRONTEND` | la dirección de Vercel (se completa en el paso 3) |
| `STRIPE_SECRET_KEY` y `STRIPE_PUBLISHABLE_KEY` | opcionales (sin ellas el pago es simulado) |

5. **Create Web Service**. La primera vez tarda unos 10 minutos.
6. Prueba: abre `https://stayhub-backend.onrender.com/api/estado` → debe decir
   *Backend de Inversiones LR funcionando*.

> Si Render le pone otro nombre (por ejemplo `stayhub-backend-x1y2`), cambia esa dirección
> en `frontend/vercel.json` de tu fork (las dos líneas que dicen `onrender.com`).

## 3. Frontend en Vercel

1. Crea una cuenta en https://vercel.com con **GitHub**.
2. **Add New…** → **Project** → **Import** tu fork.
3. **Root Directory:** `frontend` · **Framework Preset:** Vite → **Deploy**.
4. Copia la dirección que te da (por ejemplo `https://stayhub-xyz.vercel.app`).
5. Vuelve a Render → **Environment** → pon esa dirección en `URL_FRONTEND` → **Save** (se reinicia solo).

## 4. Instalarla en el celular

- **Android (Chrome):** abre la dirección de Vercel → menú **⋮** → **Instalar app**.
- **iPhone (Safari):** abre la dirección → **Compartir** → **Agregar a inicio**.

Queda el ícono de StayHub y abre en pantalla completa.

## A tener en cuenta

- En el plan gratis, Render **apaga el backend si nadie lo usa** un rato: la primera visita
  tarda cerca de un minuto. Antes de una presentación, ábranla unos minutos antes.
- Las fotos que suban los anfitriones se guardan en el disco del servidor y se borran cuando
  Render reinicia. Las de los alojamientos de ejemplo no se afectan.
- Las claves solo van en las variables de entorno de Render, nunca en el repositorio.
