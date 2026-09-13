-- =============================================================================
-- m003_cms_url_and_diasemana_fix.sql
-- Correcciones CMS: URLs /img/cms/ → /cms/ y dia_semana HTML → texto plano
--
-- Aplicar en KVM2:
--   mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db \
--     < ~/staging/laesh-src/setup/bds/laesh/migrations/m003_cms_url_and_diasemana_fix.sql
--
-- Idempotente: puede ejecutarse múltiples veces sin efecto secundario.
--
-- Secciones:
--   A. web_contenidos — normalizar URLs /img/cms/ → /cms/
--   B. configuraciones — normalizar URLs /img/cms/ → /cms/  (og_image, etc.)
--   C. catalogo_promociones — dia_semana: limpiar HTML CKEditor → texto plano
-- =============================================================================

SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- ── A. web_contenidos — normalizar prefijo URL de imágenes CMS ────────────────
-- Problema: uploader antiguo guardaba /laesh-web-assets-uipv1a/img/cms/...
--           en lugar del canónico  /laesh-web-assets-uipv1a/cms/...
-- Resultado: cms_cleanup.php no reconocía esas URLs → borraba los archivos como huérfanos.
-- Fix: REPLACE es idempotente — si la URL ya es correcta, no cambia nada.

UPDATE `web_contenidos`
SET `valor` = REPLACE(
    `valor`,
    '/laesh-web-assets-uipv1a/img/cms/',
    '/laesh-web-assets-uipv1a/cms/'
)
WHERE `valor` LIKE '/laesh-web-assets-uipv1a/img/cms/%';

-- ── B. configuraciones — misma normalización para og_image y similares ────────

UPDATE `configuraciones`
SET `valor` = REPLACE(
    `valor`,
    '/laesh-web-assets-uipv1a/img/cms/',
    '/laesh-web-assets-uipv1a/cms/'
)
WHERE `valor` LIKE '/laesh-web-assets-uipv1a/img/cms/%';

-- ── C. catalogo_promociones — dia_semana: HTML CKEditor → texto plano ─────────
-- Problema: CKEditor guardaba HTML con estilos en dia_semana:
--   <p style="margin:0px;..."><span style="font-size:...">Lunes</span></p>
-- Resultado: la función _normalizeDay() en promociones.php hace strip_tags()
--   antes de comparar con $todayKey, pero el dato mostrado al usuario era HTML crudo.
-- Fix: REGEXP_REPLACE elimina todas las etiquetas HTML y deja solo el texto plano.
-- Idempotente: si dia_semana ya es texto plano, REGEXP_REPLACE no cambia nada.

UPDATE `catalogo_promociones`
SET `dia_semana` = TRIM(REGEXP_REPLACE(`dia_semana`, '<[^>]+>', ''))
WHERE `dia_semana` REGEXP '<[^>]+>';

-- ── Verificación (ejecutar manualmente para confirmar) ────────────────────────
-- SELECT id, dia_semana FROM catalogo_promociones ORDER BY id;
-- SELECT COUNT(*) AS urls_img_cms_restantes
--   FROM web_contenidos WHERE valor LIKE '%/img/cms/%';
-- SELECT COUNT(*) AS configs_img_cms_restantes
--   FROM configuraciones WHERE valor LIKE '%/img/cms/%';
