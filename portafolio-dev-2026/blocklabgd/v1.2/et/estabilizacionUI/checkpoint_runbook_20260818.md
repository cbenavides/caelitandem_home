# 📌 Checkpoint & Runbook de Reanudación — Proyecto LAESH
**Fecha de Checkpoint:** 18 de Agosto de 2026 (17:33 hrs)  
**Última Actualización:** 19 de Agosto de 2026  
**Estado:** Pausa Operativa Estandarizada / Listo para Reanudación  

---

## 1. 🔍 Resumen del Estado Actual y Ground Truth

Al 18 de Agosto de 2026 (17:33 hrs), se ha completado la **migración completa a la arquitectura PHP micro-framework (Flight PHP + Plates Engine + Delight Auth + HTMX)** de los tres portales principales del ecosistema LAESH:

1. **Sitio Web Público y Autenticación:** `index.php`, `webapp/login.php`, `webapp/logout.php`.
2. **CMS Admin (`/laesh/adrc/`):** `admrc/index.php` + `admrc/views/gestion_web.php` (Protegido por `gestionar_cms` / Rol `ADMIN`).
3. **Portal Médico (`/laesh/md/`):** `md/index.php` + `md/views/medicos.php` + `md/negocio/Ordenes.php` (Protegido por `ver_ordenes_propias`).
4. **Portal Recepción (`/laesh/rc/`):** `rc/index.php` + `rc/views/labadmin.php` + `rc/negocio/Ordenes.php` (Protegido por `gestionar_ordenes`).

---

## 2. 🏛️ Arquitectura por Capas y Seguridad en 3 Niveles

### 📂 Estructura de Capas (Módulos & Commons)
```
laesh-swbldi/
├── commons/                  ← [CAPA TRANSVERSAL]
│   ├── DB.php                (PDO Singleton & DB::logFallback)
│   ├── Logger.php            (Auditoría sys_logs & fallback plano)
│   ├── Response.php          (Server-Driven HTMX Responses)
│   ├── RbacManager.php       (Middleware RBAC)
│   └── autoload.php          (Autoloader PSR-4 para Common\, RC\Negocio\, MD\Negocio\, ADMRC\Negocio\)
├── rc/                       ← [PORTAL RECEPCIÓN]
│   ├── index.php             (Controller Flight PHP)
│   ├── negocio/Ordenes.php   (Negocio: Alta pacientes + Stored Procedure CrearOrdenLaboratorio)
│   └── views/labadmin.php    (View: Plates PHP + Renderizado Dinámico + RBAC Granular)
├── md/                       ← [PORTAL MÉDICO]
│   ├── index.php             (Controller Flight PHP)
│   ├── negocio/Ordenes.php   (Negocio: Solicitudes Digitales + Stored Procedure)
│   └── views/medicos.php     (View: Plates PHP + Renderizado Dinámico)
└── admrc/                    ← [CMS ADMIN]
    ├── index.php             (Controller Flight PHP)
    └── views/gestion_web.php (View: Plates PHP)
```

### 🛡️ Blindaje de Seguridad en 3 Niveles
1. **Nivel 1 (Frontend):** Navegación en la misma pestaña post-login (`window.location.href = portalUrl`). Apertura del logo corporativo en nueva pestaña (`target="_blank" rel="noopener"`) manejada de forma centralizada en `app.js` (fase de captura `useCapture: true`), libre de parches inline y conforme a la política CSP `script-src 'self'`.
2. **Nivel 2 (Backend & RBAC UI):** Validación obligatoria de permisos en routers de Flight PHP. En `rc/views/labadmin.php`, las secciones administrativas (*Contenidos del Sitio Web*, menú *Médicos*, panel `#panel-medicos` y la columna *Operaciones*) están envueltas en `<?php if (!empty($isAdmin)): ?>` y se excluyen del DOM para el perfil `RECEPCION`.
3. **Nivel 3 (Destrucción de Sesión & CSRF):** Cierre forzado de sesiones pasadas en `login.php` (`Flight::auth()->logOut()`) antes de procesar nuevas credenciales. Verificación `hash_equals()` y rotación del token CSRF tras cada `POST`.
4. **Nivel Resiliencia (Fallback JS Cliente 1-Clic — Opción B para Servidores Estáticos):** En `laesh-web-assets-uipv1a/js/website.js`, el manejador del modal de login permite **acceso con 1-clic de fricción cero en la versión HTML estática (OCI VM `uipv1a`)**. Si los inputs de usuario/contraseña se dejan vacíos o si la petición al servidor PHP no está disponible (404/500), al presionar el botón "Ingresar", el JS redirige instantáneamente al mockup HTML correspondiente (`medicos.html`, `labadmin.html`, `gestion-web.html`) según la opción del menú seleccionada, facilitando la demostración visual rápida sin necesidad de tipear credenciales. Si se ingresan datos reales y existe el stack PHP, se ejecuta la autenticación PDO/Delight Auth.

---

## 🔐 3. Validaciones de Inputs de Login y Datos de Prueba

### 📋 Reglas de Validación de Formulario (`website.js` & `login.php`):
* **Campo Teléfono (`telefono` / `username`):**
  * **Regla:** Exactamente 10 dígitos numéricos (`/^\d{10}$/`).
  * **Comportamiento Backend (Phone-as-Email):** Transforma el número `999000000X` en el correo virtual `999000000X@laesh.local` para autenticación transparente en `Delight\Auth`.
* **Campo Contraseña (`password`):**
  * **Regla Cliente (JS):** Mínimo 4 caracteres (`passVal.length >= 4`), eliminando bloqueos de expresiones regulares rígidas para compatibilidad total con contraseñas reales y de prueba.
  * **Regla Servidor (PHP):** Validación hash segura bcrypt/argon2 mediante `Delight\Auth`.

### 🔑 Credenciales de Prueba del Sistema (`laesh_db`):
| Rol Operativo | Teléfono / Usuario | Email Virtual | Contraseña de Prueba | Destino RBAC Post-Login |
| :--- | :--- | :--- | :--- | :--- |
| **Administrador (`ADMIN`)** | `9990000001` | `9990000001@laesh.local` | `password123#` | `/laesh/adrc/` (CMS Admin) |
| **Recepción (`RECEPCION`)** | `9990000002` | `9990000002@laesh.local` | `password123#` | `/laesh/rc/` (Portal Recepción) |
| **Médico (`MEDICO`)** | `9990000003` | `9990000003@laesh.local` | `password123#` | `/laesh/md/` (Portal Médicos) |

---

## 4. 💾 Base de Datos MariaDB y Stored Procedures (`laesh_db`)

* **Stored Procedure `CrearOrdenLaboratorio`:** Genera folios canónicos `LAESH-XXXXX` con incremento en `folios_control`, insertando simultáneamente en `ordenes` y `historial_estados_orden`.
* **Detalle de Órdenes y Pacientes:** Búsqueda/alta automática en `pacientes` e inserción en `detalle_ordenes`.
* **Observabilidad:** Traza de eventos en `sys_logs` y captura de fallos PDO en `fallback_log`.

---

## 🔄 5. Protocolo de Merge Quirúrgico (Futuros cambios en HTMLs → Plantillas PHP)

Si durante la pausa operativa se realizan modificaciones visuales o de maquetación en los archivos estáticos `website/uipv1/*.html` (`medicos.html`, `labadmin.html`, `gestion-web.html`), el procedimiento estandarizado para trasladar los cambios a las vistas Plates PHP sin romper la lógica es:

### 📋 Checklist de Merge (Paso a Paso):
1. **Identificar la plantilla de destino:**
   * `website/uipv1/medicos.html` $\rightarrow$ `md/views/medicos.php`
   * `website/uipv1/labadmin.html` $\rightarrow$ `rc/views/labadmin.php`
   * `website/uipv1/gestion-web.html` $\rightarrow$ `admrc/views/gestion_web.php`
2. **Preservar el Bloque de Encabezado PHP:**
   ```php
   <!DOCTYPE html>
   <?php
   /**
    * Fuente SSOT HTML: website/uipv1/...html (R15.1 - Merge iterativo)
    */
   ?>
   ```
3. **Preservar Variables Dinámicas:**
   * Nombre de usuario/médico: `<?= htmlspecialchars($nombreUsuario, ENT_QUOTES, 'UTF-8') ?>`
   * Inputs ocultos CSRF: `<input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">`
4. **Preservar Atributos y Script HTMX:**
   * `<form id="..." hx-post="..." hx-target="#a11y-live" hx-swap="innerHTML" hx-indicator="#loading-spinner">`
   * `<script src="/laesh-web-assets-uipv1a/js/htmx.min.js"></script>`
5. **Preservar Condicionales RBAC:**
   * `<?php if (!empty($isAdmin)): ?>` envolviendo `#nav-gestion-web`, menú *Médicos*, `#panel-medicos` y la columna *Operaciones*.
6. **Preservar Loops PHP:**
   * `<?php foreach ($ordenesRecientes as $ord): ?>` en `labadmin.php`.
   * `<?php foreach ($ordenesPropias as $ord): ?>` en `medicos.php`.
7. **Verificar Ausencia de Eventos Inline:**
   * No incluir `onclick="..."` en enlaces o botones. Mantener marcados semánticos puros.

---

## 🛠️ 6. Comandos Útiles para el Checkpoint y Reanudación

### A. Respaldar la Base de Datos MariaDB (Dump físico):
```bash
docker compose -f /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor/docker-compose.yml exec db mariadb-dump -u root -pcomite_2026 laesh_db > /home/carlos/GitHub/caelitandem_home/restaurantb/laesh_db_checkpoint_20260818.sql
```

### B. Validar Sintaxis PHP de los Módulos:
```bash
docker compose -f /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor/docker-compose.yml exec web php -l /var/www/html/laesh-swbldi/commons/autoload.php
docker compose -f /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor/docker-compose.yml exec web php -l /var/www/html/laesh-swbldi/rc/negocio/Ordenes.php
docker compose -f /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor/docker-compose.yml exec web php -l /var/www/html/laesh-swbldi/md/negocio/Ordenes.php
docker compose -f /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor/docker-compose.yml exec web php -l /var/www/html/laesh-swbldi/rc/index.php
docker compose -f /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor/docker-compose.yml exec web php -l /var/www/html/laesh-swbldi/md/index.php
docker compose -f /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor/docker-compose.yml exec web php -l /var/www/html/laesh-swbldi/rc/views/labadmin.php
docker compose -f /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor/docker-compose.yml exec web php -l /var/www/html/laesh-swbldi/md/views/medicos.php
```

### C. Estado del Repositorio Git:
Todos los cambios están comiteados y la rama de trabajo está 100% limpia (`nothing to commit, working tree clean` en commit `543082b` — *fix(ui): publicar maqueta estatica uipv1a en OCI VM con fallback 1-clic y exclusiones*).

---

## 🌐 7. Despliegue Estático en OCI VM (uipv1a) & Fallback 1-Clic

**Fecha de Publicación en OCI VM:** 19 de Agosto de 2026  
**Último Commit de Despliegue:** `543082b793c1b070506cba82509263517e4a4291`  
**Ruta Remota HTML:** `ubuntu@oci-vm:/home/ubuntu/n8n-php/mvps/laesh-ui/uipv1a/`  
**Ruta Remota Activos:** `ubuntu@oci-vm:/home/ubuntu/n8n-php/laesh-web-assets-uipv1a/`  

### 📋 Exclusiones Aplicadas en Despliegue Estático:
* `webapp/` (Excluido de la versión demo OCI VM)
* `estabilizacionUI/` (Excluido y purgado del servidor remoto)
* `*.php` (Sin archivos ni stack PHP en servidor estático)
* `*.sql` (Sin dumps de BD en servidor estático)

### ⚙️ Comportamiento Fallback 1-Clic (`laesh-web-assets-uipv1a/js/website.js`):
* En entornos estáticos sin PHP (OCI VM `uipv1a`), al hacer clic en "Ingresar" en el modal de login sin escribir credenciales o cuando el servidor PHP no responde, `website.js` ejecuta `redirectToStaticPortalFallback()`, redirigiendo en 1 clic al portal HTML seleccionado (`medicos.html`, `labadmin.html`, `gestion-web.html`) para demostración ágil de maquetación.

---

### 🎨 8. Actualización de Maquetación: Split 2-Columnas & Buscador Autocomplete (19/08/2026)

**Activos Desplegados a OCI VM:**
* `laesh-swbldi/website/uipv1/medicos.html` $\rightarrow$ `/home/ubuntu/n8n-php/mvps/laesh-ui/uipv1a/medicos.html`
* `laesh-swbldi/website/uipv1/labadmin.html` $\rightarrow$ `/home/ubuntu/n8n-php/mvps/laesh-ui/uipv1a/labadmin.html`
* `laesh-web-assets-uipv1a/css/portal.css` $\rightarrow$ `/home/ubuntu/n8n-php/laesh-web-assets-uipv1a/css/portal.css`
* `laesh-web-assets-uipv1a/js/medicos.js` $\rightarrow$ `/home/ubuntu/n8n-php/laesh-web-assets-uipv1a/js/medicos.js`
* `laesh-web-assets-uipv1a/js/labadmin.js` $\rightarrow$ `/home/ubuntu/n8n-php/laesh-web-assets-uipv1a/js/labadmin.js`

**Ajustes Visuales y Funcionales Aplicados:**
1. **Layout Split 60% / 40% (Portal Médicos):**
   * Columna Izquierda (60%): 10 fichas visuales de categorías principales.
   * Columna Derecha (40%): Contenedor dinámico `#contenedor-estudios-dinamico` con badge de conteo y chips/tags interactivos de remoción (`×`).
2. **Encabezado & Campo de Búsqueda Autocomplete:**
   * Alineado quirúrgicamente sobre la columna derecha (40%).
   * Icono de lupita SVG colocado por afuera a la izquierda del inputext.
   * Borde resaltado de 2px azul (`border: 2px solid var(--primary)`), fuente amplia de `0.95rem` y foco glow.
   * Autocomplete en tiempo real buscando sobre el catálogo completo de 18 categorías.
3. **Corrección de Enlace "Contenidos del Sitio Web" en `labadmin.html`:**
   * Corregido elemento `#nav-gestion-web` a etiqueta nativa `<a href="gestion-web.html">`.
   * En `labadmin.js`, ajustada la lógica de redirección para navegar a `gestion-web.html` en maquetas estáticas (OCI VM `uipv1a`) y a `/laesh/adrc/` en entornos PHP.
4. **Estrategia Opción A (Congelamiento de Capa PHP):**
   * La vista backend PHP `md/views/medicos.php` permanece congelada en el checkpoint `543082b`. Todo el comportamiento de la maqueta en OCI VM se ejecuta en cliente autónomo via Vanilla JS.
