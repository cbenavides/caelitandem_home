# Notas Septiembre 2026 — LAESH Bloc Digital (KVM2)

> Bitácora de sesiones de trabajo septiembre 2026.
> Ver estado completo en `.agents/pending.md` (Ground Truth compartido).

---

## Sesión 8 — 2026-09-07 (Claude Code)

### CSS — `grid-acerca-cards` 2 col en tablet (fix nuclear)

Problema: fichas de "Quiénes Somos" se apilaban en 1 col en tablet portrait (641–1024px) pese a reglas previas.

**Root cause**: `style.css` `.grid-layout.grid-1-1-auto` con `auto-fit minmax(220px,1fr)` ganaba en cascada; además `display:grid` no era `!important` por lo que pudo caer a `block` silenciando `grid-template-columns`.

**Fix (landing.css — fin del archivo)**:
```css
/* Nuclear — especificidad 1,3,0 en capa !important */
#acerca-de .grid-layout.grid-1-1-auto.grid-acerca-cards {
    display: grid !important;
    grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
    gap: 1rem !important;
    /* ... */
}
@media (min-width: 1025px) {
    #acerca-de .grid-acerca-cards, .grid-acerca-cards {
        grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
    }
}
```
Desplegado a KVM2 (`sudo cp`). Verificado por usuario ✅.

---

### Seguridad / CMS — Validación servidor de dimensiones de imágenes

**Gap detectado**: `admrc/index.php` aceptaba cualquier imagen WebP que pasara el check de tipo/tamaño sin validar dimensiones → bypass HTTP posible.

**Fix** (`admrc/index.php`): `getimagesize($file['tmp_name'])` antes de `move_uploaded_file` → espejo exacto de `cms-upload.js slotRules()` por slot:

| Slot | Regla servidor añadida |
|---|---|
| `hero-*` | ancho 1280–1920px, landscape |
| `carousel-*` | exacto 800×580px |
| `ubicacion-croquis` | máx 756×577px, landscape |
| `promo-*` | exacto 900×486px |
| `calidad-*` | exacto 800×580px |
| `seo-og` | ancho 1200–1920px, landscape |
| genérico | ancho mínimo 800px |

**Fix adicional** (`gestion_web.php` l.942): `accept="image/webp,image/png,image/jpeg"` → `accept="image/webp"` en slots promo (consistencia con validación JS). Desplegado y verificado ✅.

---

### Infraestructura y verificaciones

| Check | Resultado |
|---|---|
| P-INFRA-01 DNS | CNAME `www→laesh.mx` + A `@→83.136.219.193` confirmados en panel DNS ✅ |
| S1 HTTPS/HSTS | `HTTP/2 200` + `strict-transport-security: max-age=31536000; includeSubDomains` en `https://laesh.mx` ✅ |
| PERF-03 Gzip | `content-encoding: gzip` en landing.css (cabecera HTTP KVM2) ✅ |
| A6 Contraste | Verificado OK en sesiones anteriores ✅ |

---

### Assets — G-IMG-01 y G-IMG-02 (specs corregidas)

- **G-IMG-01** — galería calidad: todas las imágenes CMS verificadas 800×580px ✅
- **G-IMG-02** — spec `01mapa-laesh.webp` corregida: rango válido 656–756×477–577px (no 1136×615px como documentado antes). Archivo local 656×477 ✅ dentro del rango.
- **`sala-de-espera.webp`** — reemplazado con `hero-slide4-20260906-1e644750.webp` del CMS (1600×800 · 101KB vs 260KB anterior). SSOT es el CMS; `sudo cp` no necesario en producción.

---

### P-LAESH-06 Portal Médico — Cerrado ✅

Verificación por análisis de código (`portal.css`):

- **Issue A (dropdown checkbox)**: `position:fixed` + `getBoundingClientRect()` JS + `.ficha-drop-item { display:flex; flex-wrap:nowrap; gap:5px }` + checkbox `flex-shrink:0`. Checkbox y texto siempre juntos. ✅
- **Issue B (Sexo radios móvil)**: grid `@media ≤767px` con `grid-column:4; grid-row:1` para `.form-group-sexo`. Alineación homogénea. ✅

Ninguna corrección necesaria — ambos issues ya resueltos en CSS. Cerrado en `pending.md`.

---

### Estado de deploy al cierre de sesión 8

| Archivo / Acción | Estado |
|---|---|
| `landing.css` (grid-acerca-cards nuclear fix) → KVM2 | ✅ Desplegado |
| `admrc/index.php` (dims servidor) → KVM2 | ✅ Desplegado |
| `gestion_web.php` (accept=image/webp promo) → KVM2 | ✅ Desplegado |
| `sala-de-espera.webp` (seed local) → local | ✅ Actualizado |
| Git commit sesiones 7+8 | ⏳ Pendiente instrucción explícita (usuario hace el commit) |

---

## Sesión 7 — 2026-09-07 (Claude Code)

### CMS — Estabilización completa de assets del home site (`index.php`)

**Bugs corregidos en producción:**

| Módulo | Bug | Fix |
|---|---|---|
| `cms_cleanup.php` | Filtro `tipo='imagen_url'` omitía calidad/carrusel/croquis insertados con `tipo='texto'` → cron los eliminaba | Filtro cambiado a patrón URL (`valor LIKE '/laesh-web-assets-uipv1a/cms/%'`) |
| `cms_cleanup.php` | No protegía URLs en tabla `configuraciones` | UNION añadido |
| `cms_cleanup.php` | No protegía `catalogo_promociones.imagen_fondo` | 3ª query añadida |
| `admrc/index.php` | Insertaba `tipo='texto'` hardcodeado para todas las imágenes CMS | Auto-detección: `str_starts_with($valor, '/cms/')` → `'imagen_url'` |
| `admrc/index.php` | `INSERT` sin `ON DUPLICATE KEY UPDATE` → actualizaciones de `tipo` perdidas | Cláusula ON DUPLICATE KEY UPDATE añadida |
| `web_contenidos` (BD) | 13 filas con `tipo='texto'` para rutas CMS | `UPDATE web_contenidos SET tipo='imagen_url' WHERE valor LIKE '/laesh-web-assets-uipv1a/cms/%'` |
| Cron `cache-renew` | `LAESH_DB_PASS=` vacío → PHP crasheaba silenciosamente antes del primer echo | `sed` en `/etc/cron.d/laesh-cache-renew` con valor real |
| `gestion-web.js` | 3 refs `area-*-dos.webp` nunca existieron | Redirigidas a `area-*-uno.webp` / variante existente |
| `website.js` | Tooltip: timer compartido faltaba; touch events generaban events sintéticos; `mouseenter` en tooltip no cancelaba cierre | Singleton timer 280ms + `isRealMouse()` + `mouseenter` en tooltip |
| `07_seed_catalogs.sql` | Hero slide 1 apuntaba a hash CMS (cambia en cada upload) | Cambiado a `/img/recepcion-de-pacientes.webp` (estático, siempre existe) |

**Datos de calidad restaurados (6 imágenes de promociones eliminadas por cron, ahora re-subidas):**
- `catalogo_promociones.imagen_fondo` para 6 promociones activas
- Cron nocturno (`cms_cleanup.php 01:00 AM`) ya protege estas URLs

**Orphans eliminados en servidor:**
- `/opt/laesh/assets/laesh-web-assets-uipv1a/img/og-laesh-1200x630.webp`
- `/opt/laesh/assets/laesh-web-assets-uipv1a/img/cms/` — 19 WebP legados (~1.6 MB)

---

### CSS — Fixes de compatibilidad y responsividad

| Fix | Archivos | Detalle |
|---|---|---|
| Chrome 92 `@layer` | `style.css`, `style-website.css` | Eliminados 6 wrappers `@layer base { }` — Chrome 92-98 los silencia (bug especificación) |
| Hero slide recorte | `landing.css` l.1169 + l.1261 | `background-size: cover` → `contain` en `≤1024px` / `≤767px`; `background-position: center center` |
| Responsividad `.calidad-cards-grid` | `landing.css` | Flex + `flex-wrap: wrap`; 2col `calc(50% - 0.5rem)` en 481–1024px; 1col en ≤480px |
| Responsividad `.catalog-grid` | `landing.css` | `min-width: 480px` → 2col (era 640px); `max-width: 479px` override 1col (era 767px) |
| Responsividad `.orden-acc-body` | `landing.css` | Nuevo bloque `@media (min-width: 540px) and (max-width: 767px)` → 2col |
| Responsividad `.grid-acerca-cards` | `landing.css` | `@media ≤1024px`: 2col sin `!important`; nuevo `@media ≤640px`: 1col. Cumple Regla 13 R8 |
| Comentario desincronizado | `landing.css` l.919 | "85% auto heredado" → documentado correctamente: `cover` en desktop, `contain` en móvil/tablet |

**Breakpoints resultantes:**
```
.calidad-cards-grid:  ≤480px=1col │ 481–1024px=2col │ >1024px=3col(flex)
.catalog-grid:        ≤479px=1col │ 480–1023px=2col │ ≥1024px=3col
.orden-acc-body:      <540px=1col  │ 540–767px=2col  │ 768–1024px=2col │ >1024px=base
.grid-acerca-cards:   ≤640px=1col  │ 641–1024px=2col │ >1024px=3col
```

---

### Estado de deploy al cierre de sesión

| Archivo / Acción | Estado |
|---|---|
| `cms_cleanup.php` → KVM2 | ✅ Desplegado |
| `admrc/index.php` → KVM2 | ✅ Desplegado |
| `style.css` (@layer fix) → KVM2 | ✅ Desplegado |
| `style-website.css` (@layer fix) → KVM2 | ✅ Desplegado |
| `website.js` (tooltip) → KVM2 | ✅ Desplegado |
| `gestion-web.js` (imagen refs) → KVM2 | ✅ Desplegado |
| Cron `laesh-cache-renew` LAESH_DB_PASS= | ✅ Fix en `/etc/cron.d/` |
| `landing.css` (responsividad + Issue-3 + comentario) → KVM2 | ✅ Desplegado |
| Orphans locales (`og-laesh-1200x630.webp` + `img/cms/`) | ✅ Eliminados |
| Git commit sesión 7 | ⏳ Pendiente instrucción explícita |

---

## Sesión 6 — 2026-09-06 (Claude Code)

- G1 `Logger::logAlways()` + request_id + session_id + url/method en `sys_logs`
- G-DEV-01 Modal perfil médico — fetch interceptor + validación celular `^\d{10}$`
- GET `/api/estudios` catálogos tabla plana fix
- Breadcrumb 🏠 Recepción en `admrc`
- BACKUP_MAX_AGE 7200→90000 (cron backup diario 20:00)
- Bug deploy: ruta `/opt/laesh/laesh-swbldi/` → correcta `/opt/laesh/www/laesh-swbldi/`
- Docs: `laesh-kvm2-prod/README.md` árbol completo + `Tecnica_Infraestructura_Despliegue.html` §19.3.3

---

## Sesión 5 — 2026-09-05 (Claude Code)

- Portal 404 fix KVM2: `try_files` sin `$uri/` + `include fastcgi_params` primero + `SCRIPT_NAME` explícito
- Nginx `nginx-laesh-domain.conf` verificado: local == servidor (287 líneas, contenido idéntico, SHA256 confirmado)

---

> **Nota**: Para el historial completo de sesiones anteriores a septiembre 2026
> ver `.agents/pending.md` → sección RESUELTOS RECIENTEMENTE.
