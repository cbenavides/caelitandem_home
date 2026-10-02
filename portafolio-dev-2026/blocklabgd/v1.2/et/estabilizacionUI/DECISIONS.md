# DECISIONS.md — Registro de Decisiones de Arquitectura
## Proyecto: LAESH — Bloc Digital y Sitio Web Corporativo
### Directorio: `blocklabgd/v1.2/et/`

Registro cronológico de decisiones de diseño tomadas durante las sesiones de documentación técnica. Cada entrada cierra una alternativa con razonamiento explícito para que futuras iteraciones no re-debatan sin contexto.

---

## Sesión: Agosto 2026 — Modelo de Datos, Auth y Seguridad

### D-01 · `edad_al_emitir` en ORDENES, no en PACIENTES
**Área:** ORDENES  
**Fecha:** 2026-08-17  
**Decisión:** El campo `edad_al_emitir TINYINT UNSIGNED NOT NULL` vive en la tabla `ordenes`, no en `pacientes`.  
**Razón:** La edad del paciente cambia con el tiempo. El registro en `ordenes` captura el dato clínico en el momento exacto de emisión — dato histórico inmutable. Si viviera en `pacientes`, recalcular la edad con `fecha_nacimiento` daría un resultado distinto al que el médico tenía en mente al emitir la orden.  
**Fuente UI:** campo `<input name="edad">` en `form-orden` de `medicos.html`.

---

### D-02 · ESTUDIOS — dos campos de categoría independientes
**Área:** ESTUDIOS  
**Fecha:** 2026-08-17  
**Decisión:** Dos columnas separadas:
- `categoria` (VARCHAR): valores del `<select id="estudio-categoria">` de labadmin — Hematología | Bioquímica | Uroanálisis | Inmunología | Otros
- `tipo_web` (VARCHAR): rutina | check_up — controla en qué sección del sitio público aparece el estudio

**Razón:** Las dos dimensiones tienen consumidores distintos y valores incompatibles. `categoria` es para el administrador interno; `tipo_web` es para el renderizador del sitio web público (ET §R1.5).  
**Alternativa descartada:** Un solo campo con valores mezclados.

---

### D-03 · CATALOGOS_UI — tabla polimórfica para selects dinámicos
**Área:** PERFILES_MEDICOS  
**Fecha:** 2026-08-17  
**Decisión:** Tabla `catalogos_ui (id, tipo, valor, orden, activo)` con campo `tipo` discriminador ('universidad' | 'lugar_trabajo'). `perfiles_medicos.universidad_id` y `lugar_trabajo_id` son INT FK → `catalogos_ui(id)`.  
**Razón:** Los `<select id="med-universidad">` y `<select id="med-lugar">` en ambos portales (medicos.html y labadmin.html) están vacíos en el HTML — sus opciones son dinámicas desde el backend. Deben ser administrables sin deploy. La tabla polimórfica es extensible: nuevos tipos de select requieren solo INSERT de filas.  
**Alternativas descartadas:**
- Dos tablas separadas (`cat_universidades`, `cat_lugares_trabajo`): duplicación de estructura sin beneficio.
- VARCHAR libre: no administrable desde panel; opciones descontroladas.

---

### D-04 · Links sociales en CONFIGURACIONES, no en WEB_CONTENIDOS
**Área:** CONFIGURACIONES  
**Fecha:** 2026-08-17  
**Decisión:** `whatsapp_url`, `facebook_url`, `maps_embed_url` y `tiempo_rotacion_dias` van en `configuraciones` como claves de instancia global.  
**Razón:** Instrucción explícita del cliente. Los links sociales son configuración global de la instancia, no contenido editorial de una sección específica del sitio.  
**Alternativa descartada:** WEB_CONTENIDOS bajo `seccion=ubicacion`.

---

### D-05 · Estado del médico en PERFILES_MEDICOS, no reemplazando EMPLEADOS.activo
**Área:** PERFILES_MEDICOS / EMPLEADOS  
**Fecha:** 2026-08-17  
**Decisión:** `cat_estados_medico` (1=Activo | 2=Pausado) enlazado desde `perfiles_medicos.estado_id FK`. `empleados.activo TINYINT` permanece como boolean para personal general (recepción, admin).  
**Razón:** El estado rico (Pausado) es semántico para médicos: un médico Pausado no puede crear órdenes pero su historial clínico queda intacto. Para recepción/admin el boolean es suficiente y no amerita catálogo.  
**Alternativa descartada:** Reemplazar `empleados.activo` globalmente con FK al catálogo — sobrediseño para los roles no-médico.

---

### D-06 · `historial_estados_orden` = tabla de "movimientos" del sistema
**Área:** Sistema / Trazabilidad  
**Fecha:** 2026-08-17  
**Decisión:** `historial_estados_orden` es la tabla de movimientos operativos. Registra cada transición: quién la hizo, desde qué estado, hacia cuál, y el timestamp. Es la fuente de verdad para reportes de tiempos de atención y auditoría operativa.  
**Alternativa descartada:** Tabla genérica de auditoría unificada — la estructura específica de transiciones de estado no encaja en un modelo genérico.

---

### D-07 · Valores canónicos de WEB_CONTENIDOS.seccion desde gestion-web.html
**Área:** WEB_CONTENIDOS  
**Fecha:** 2026-08-17  
**Decisión:** Los valores de `seccion` se derivan de los atributos `data-section` del HTML de `gestion-web.html`:  
`hero | quienes-somos | especialidades | promociones | calidad | ubicacion | privacidad | seo`  
Los valores anteriores (`acerca_de`, `estudios`, `contacto`) eran incorrectos.  
**Razón:** El JS del frontend usa `data-section` como llave para activar paneles y construir las peticiones AJAX. El backend debe usar exactamente el mismo valor; de lo contrario, la UNIQUE KEY `uq_sec_subsec_clave` no coincide y se crean filas duplicadas.

---

### D-08 · users_resets — nunca se usa, excluido por contrato
**Área:** Delight-Auth  
**Fecha:** 2026-08-17  
**Decisión:** La tabla `users_resets` existe en el schema (generada por `$auth->install()`) pero nunca genera filas en LAESH. El reset lo realiza el admin directamente via `admin()->changePasswordForUserById()` sin token por email.  
**Razón:** Excluido explícitamente por contrato. Anexo A Bloc Digital: _"Se excluye la recuperación automatizada de contraseña ('olvidé mi contraseña')."_

---

### D-09 · users_confirmations — bypaseada, admin crea con verified=1
**Área:** Delight-Auth  
**Fecha:** 2026-08-17  
**Decisión:** El flujo de confirmación de email no se usa. El admin crea médicos invocando `admin()->createUserWithUniqueUsername()` y los marca como `verified=1` directamente.  
**Razón:** El sistema es privado — no hay auto-registro público. Los médicos son dados de alta por el administrador.

---

### D-10 · CSRF/Anti-resubmit — `$_SESSION`, sin tabla de BD
**Área:** Seguridad  
**Fecha:** 2026-08-17  
**Decisión:** `\Common\CsrfGuard` opera sobre `$_SESSION['csrf_token']` (string 64 hex, `random_bytes`). Sin tabla de BD. Token rotado tras cada POST exitoso. El guard se ejecuta como primer paso de todo controlador de mutación, antes de cualquier llamada a Delight-Auth o PDO.  
**Razón:** La sesión PHP es el mecanismo estándar y suficiente. Una tabla de tokens en BD introduciría latencia de conexión en cada request de mutación y complejidad de purga de tokens expirados.

---

### D-11 · force_logout como mecanismo de invalidación masiva
**Área:** Delight-Auth / Seguridad  
**Fecha:** 2026-08-17  
**Decisión:** Al resetear contraseña, el admin invoca `logOutEverywhereForUserById()`. Delight-Auth escribe `force_logout = UNIX_TIMESTAMP()` en `users` y elimina todas las filas del usuario en `users_remembered`. En cada request subsecuente del objetivo, la librería rechaza la sesión si `force_logout > session_start`.  
**Razón:** Una sola escritura invalida todas las sesiones activas en cualquier dispositivo, incluyendo tokens "recordarme" de larga duración. Sin necesidad de rastrear sesiones individuales.

---

### D-12 · DDL de Delight-Auth via $auth->install(), nunca manual
**Área:** Delight-Auth  
**Fecha:** 2026-08-17  
**Decisión:** Las tablas `users`, `users_remembered`, `users_throttling`, `users_audit_log`, `users_2fa`, `users_confirmations`, `users_resets` se crean **exclusivamente** vía `$auth->install()`. No se escriben DDLs manuales para estas tablas.  
**Razón:** Los DDLs manuales rompen actualizaciones futuras de la librería y generan riesgo de inconsistencia de charset/collation (Delight-Auth usa `latin1_general_cs` para columnas de tokens por razones de rendimiento de índices).

---

### D-13 · Doble log en reset de contraseña: users_audit_log + sys_logs
**Área:** Auditoría  
**Fecha:** 2026-08-17  
**Decisión:** El reset de contraseña por admin genera dos registros:
1. `users_audit_log`: `event_type='PASSWORD_CHANGED_BY_ADMIN'`, `admin_id=ID_del_admin` — gestionado automáticamente por Delight-Auth.
2. `sys_logs`: `level='WARN'`, con IP, admin_id y target_id — gestionado por `\Common\Logger`.  
**Razón:** `users_audit_log.admin_id` provee trazabilidad estructurada de "quién hizo qué sobre quién". `sys_logs` provee contexto operativo (IP, timestamp real del servidor) para correlacionar con otros eventos del sistema.  
**Alternativa descartada:** Solo `sys_logs` propio — perdería el campo `admin_id` estructurado y el `event_type` nativo de Delight-Auth.

---

## Sesión: Octubre 2026 — Optimización de Modelo Físico, OPcache L2 y Cache-Busting

### D-14 · Primary Key `id AUTO_INCREMENT` y unicidad virtual en `rel_igabinete_vinculos`
**Área:** Base de Datos / Catálogos Clínicos  
**Fecha:** 2026-10-02  
**Decisión:** En `rel_igabinete_vinculos` se incorpora una PK física explícita `id INT UNSIGNED AUTO_INCREMENT` y se añade la columna virtual generada `subgabinete_uid INT AS (IFNULL(subgabinete_id, 0)) VIRTUAL` para respaldar la restricción `UNIQUE KEY uq_vinculo_unico (igabinete_id, gabinete_id, subgabinete_uid)`.  
**Razón:** La tabla carecía de PK (provocando la creación del índice implícito de 6 bytes `GEN_CLUST_INDEX` en InnoDB). Una PK compuesta sobre `(igabinete_id, gabinete_id, subgabinete_id)` es inviable en MariaDB debido a que 5 de los 14 registros tienen `subgabinete_id = NULL` (vínculos directos a nivel Área/Gabinete), lo que dispararía el Error 1138 (*Invalid use of NULL value*). La columna virtual y la PK física garantizan indexación agrupada nativa y unicidad absoluta de relaciones.  
**Alternativa descartada:** PK compuesta permitiendo NULLs (prohibida por el motor MariaDB/InnoDB).

---

### D-15 · `catalogo_promociones.dia_semana` como `VARCHAR(255)`, no `ENUM`
**Área:** Base de Datos / CMS Promociones  
**Fecha:** 2026-10-02  
**Decisión:** Se migra la columna `catalogo_promociones.dia_semana` de `TEXT` a `VARCHAR(255) NOT NULL`.  
**Razón:** Aunque el assessment sugería `ENUM('lunes','martes',...)`, los datos reales ingresados vía CKEditor en el CMS contienen marcado HTML enriquecido (ej. `<p>Lunes</p>`). Convertirlo a `ENUM` truncaría y corrompería irreversiblemente los datos de producción. `VARCHAR(255)` mantiene el almacenamiento *in-row* en el bloque de datos de InnoDB (eliminando la sobrecarga de *off-page storage* de `TEXT`), preservando al 100% la compatibilidad con el editor web.  
**Alternativa descartada:** `ENUM` estricto (rompe contenido enriquecido existente).

---

### D-16 · Cache-Busting determinístico vía `filemtime` a 3 niveles en Activos Compilados
**Área:** Frontend UI / Activos Estáticos  
**Fecha:** 2026-10-02  
**Decisión:** En `md/views/medicos.php` y `rc/views/labadmin.php`, se sustituye `?v=<?= time() ?>` por `?v=<?= @filemtime(__DIR__ . '/../../../laesh-web-assets-uipv1a/js/catalog-compiled.js') ?: time() ?>`.  
**Razón:** El anti-patrón `time()` forzaba al navegador a descargar 670 KB de JavaScript en cada segundo y en cada navegación entre pestañas, invalidando la caché HTTP. Con `filemtime`, Nginx y el navegador sirven el activo con `HTTP 304 Not Modified` o desde *Memory Cache* (0 ms). `CatalogBuilder::build()` actualiza el `mtime` del archivo en disco al modificarse el catálogo, forzando la descarga únicamente cuando existen cambios reales. Se fijó la profundidad exacta a 3 niveles (`/../../..`) para resolver la ruta física correcta desde `views/`.  
**Alternativa descartada:** Mantener `time()` (desperdicio masivo de ancho de banda y latencia innecesaria en consultorios).

---

### D-17 · Ciclo de Vida y Purga Física de Tokens JTI en OPcache File Store
**Área:** Caché L2 / Rendimiento & Seguridad  
**Fecha:** 2026-10-02  
**Decisión:** 
1. Se extendió `crons/cache_renew.php` para realizar la purga física y el desregistro en OPcache (`opcache_invalidate`) de todos los archivos `laesh_cache_*_JTI_*.php` con antigüedad mayor a 24 horas (`> 86400 s`).
2. Se ajustaron los permisos de `/opt/laesh/cache/` a `0775 (drwxrwxr-x)` bajo propiedad `www-data:www-data`.
3. Se refactorizó `commons/Cache.php` con fallback canónico automático a `/opt/laesh/cache/` si existe, y se expuso el método público `Cache::getCacheDir()`.  
**Razón:** Los tokens JTI generaban archivos individuales temporales en disco que nunca se eliminaban (acumulando 172 archivos zombis), arriesgando la saturación de `opcache.max_accelerated_files=4000` y provocando la evicción del código fuente de la aplicación en RAM. La purga diaria y los permisos unificados garantizan cero fugas de descriptores de archivo tanto en ejecuciones FPM como CLI.  
**Alternativa descartada:** Confiar solo en la expiración lógica en base de datos sin limpiar disco ni OPcache.

---

## Gaps de UI documentados (no son decisiones de modelo, son deudas técnicas)

| ID | Gap | Archivo | Estado |
|---|---|---|---|
| UI-G01 | `precio` en ESTUDIOS no está expuesto en la grilla ni en el modal de labadmin | `labadmin.html` | Pendiente backlog |
| UI-G02 | Los 5 inputs del Panel Ubicación/Contacto en gestion-web.html no tienen atributo `name` — el JS los captura por ID | `gestion-web.html` | Pendiente corrección |
| UI-G03 | `users_2fa` existe en schema pero 2FA no está en alcance v1 | — | Candidato v2 |
