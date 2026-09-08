# Notas Septiembre 2026 — LAESH Bloc Digital (KVM2)

> Bitácora de sesiones de trabajo septiembre 2026.
> Ver estado completo en `.agents/pending.md` (Ground Truth compartido).

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
