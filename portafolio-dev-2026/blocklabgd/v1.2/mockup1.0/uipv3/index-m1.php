<?php
/**
 * index-m1.php — Sitio Web Público LAESH (Versión Clon con Mejoras UI/UX M1)
 *
 * Mantiene intacta la lógica de backend, seguridad y datos de index.php.
 * Carga hojas de estilo optimizadas (style-website-m1.css, landing-m1.css)
 * e incluye las secciones perfeccionadas desde sections-m1/.
 */
declare(strict_types=1);
require_once __DIR__ . '/../commons/commons.php';

// ── HTTP Caching & Performance Optimization Headers ───────────────────────────
if (empty($_SESSION['auth_logged_in'])) {
    header('Cache-Control: public, max-age=300, must-revalidate');
} else {
    header('Cache-Control: no-cache, must-revalidate');
}

// ── CSRF para modal de login ────────────────────────────────────────────────
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// ── Helpers ─────────────────────────────────────────────────────────────────
function h(mixed $v): string {
    return htmlspecialchars((string)($v ?? ''), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
function waNum(string $raw): string {
    return preg_replace('/\D/', '', $raw);
}
function safeHtml(mixed $v): string {
    $html = strip_tags((string)($v ?? ''), ['strong','em','b','i','br','p','ul','ol','li','a','span','table','tbody','tr','td','th','thead','hr','figure','iframe','h1','h2','h3','h4','h5','h6','u','s','blockquote','oembed','div','img','mark']);
    $html = preg_replace('/\s+on\w+\s*=\s*(?:"[^"]*"|\'[^\']*\'|[^\s>]*)/i', '', $html);
    $html = preg_replace('/href\s*=\s*["\']?\s*javascript:/i', 'href="#" data-blocked=', $html);

    $html = preg_replace_callback('/<oembed\s+url=["\']([^"\']+)["\']\s*>\s*<\/oembed>/i', function($matches) {
        $url = $matches[1];
        if (preg_match('/(?:youtube\.com\/(?:watch\?v=|embed\/|v\/)|youtu\.be\/)([\w-]+)/i', $url, $m)) {
            $yId = $m[1];
            return '<div style="position:relative;padding-bottom:56.25%;height:0;overflow:hidden;border-radius:12px;box-shadow:0 4px 16px rgba(0,0,0,0.12);">' .
                   '<iframe src="https://www.youtube.com/embed/' . $yId . '" style="position:absolute;top:0;left:0;width:100%;height:100%;border:0;border-radius:12px;" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>' .
                   '</div>';
        }
        if (preg_match('/vimeo\.com\/(?:video\/)?(\d+)/i', $url, $m)) {
            $vId = $m[1];
            return '<div style="position:relative;padding-bottom:56.25%;height:0;overflow:hidden;border-radius:12px;">' .
                   '<iframe src="https://player.vimeo.com/video/' . $vId . '" style="position:absolute;top:0;left:0;width:100%;height:100%;border:0;" allowfullscreen></iframe>' .
                   '</div>';
        }
        return '<a href="' . htmlspecialchars($url, ENT_QUOTES, 'UTF-8') . '" target="_blank" rel="noopener">' . htmlspecialchars($url, ENT_QUOTES, 'UTF-8') . '</a>';
    }, $html);

    $html = preg_replace('/^(?:\s*<p>(?:&nbsp;|\s)*<\/p>)+/i', '', $html);
    $html = preg_replace('/(?:\s*<p>(?:&nbsp;|\s)*<\/p>)+\s*$/i', '', trim($html));

    return $html;
}

function cmsVal(?array $c, string $sec, ?string $sub, string $clave, string $default = ''): string {
    if (!is_array($c)) return $default;
    $subKey = $sub ?? '';
    if (isset($c[$sec][$subKey][$clave])) {
        return (string)$c[$sec][$subKey][$clave];
    }
    if ($subKey === '' && isset($c[$sec][''][$clave])) {
        return (string)$c[$sec][''][$clave];
    }
    return $default;
}

function parseFichas(string $text): array {
    $groups = [];
    foreach (explode("\n", $text) as $line) {
        $line = trim($line);
        if ($line === '') continue;
        if (preg_match('/^\[(.+?)\]\s*(.+)/', $line, $m)) {
            $items = array_values(array_filter(
                array_map('trim', explode(',', $m[2]))
            ));
            if ($items) {
                $groups[] = ['cat' => trim($m[1]), 'items' => $items];
            }
        }
    }
    return $groups;
}

// ── Conexión DB ─────────────────────────────────────────────────────────────
$db = Flight::db();

// ── Caché L2: OPcache PHP File Store ─────────────────────────────────────────
\Common\Cache::init('', defined('APP_ENV') ? APP_ENV : 'prod');

if (!empty($_GET['reset_cache'])) {
    if (function_exists('opcache_reset')) { @opcache_reset(); }
    \Common\Cache::clear();
}
$_bypassCache = (!empty($_SESSION['auth_logged_in']) && !empty($_GET['_preview']) && !empty($_SESSION['cms_draft'])) || !empty($_GET['nocache']) || !empty($_GET['reset_cache']);

// ── 1a. configuraciones ─────────────────────────────────────────────────────
$configRaw = $_bypassCache ? null : \Common\Cache::get(\Common\Cache::KEY_CFG);
if ($configRaw === null) {
    $configRaw = $db->query("SELECT clave, valor FROM configuraciones")->fetchAll(\PDO::FETCH_KEY_PAIR) ?: [];
    if (!$_bypassCache) \Common\Cache::set(\Common\Cache::KEY_CFG, $configRaw);
}

// ── 1b. web_contenidos → $cms ────────────────────────────────────────────────
$_cmsRaw = $_bypassCache ? null : \Common\Cache::get(\Common\Cache::KEY_CMS);
if ($_cmsRaw === null) {
    $_cmsRaw = [];
    foreach ($db->query("SELECT seccion, subseccion, clave, valor FROM web_contenidos ORDER BY id")->fetchAll(\PDO::FETCH_ASSOC) as $row) {
        $_cmsRaw[$row['seccion']][$row['subseccion']][$row['clave']] = $row['valor'];
    }
    if (!$_bypassCache) \Common\Cache::set(\Common\Cache::KEY_CMS, $_cmsRaw);
}
$cms = $_cmsRaw;

// ── 2. Preview de borrador CMS ──────────────────────────────────────────────
$isPreview = !empty($_GET['_preview'])
    && !empty($_SESSION['auth_logged_in'])
    && !empty($_SESSION['cms_draft']);
if ($isPreview) {
    foreach ($_SESSION['cms_draft'] as $draftSec => $campos) {
        foreach ($campos as $rawKey => $val) {
            if (str_starts_with($rawKey, '_cfg_')) {
                $configRaw[substr($rawKey, 5)] = $val;
                continue;
            }
            [$sub, $clave] = array_pad(explode('__', $rawKey, 2), 2, $rawKey);
            $cms[$draftSec][$sub][$clave] = $val;
        }
    }
}

// ── 3. Helpers y Variables Funcionales ──────────────────────────────────────
$cfg = fn(string $k, string $d = '') => (!isset($configRaw[$k]) || $configRaw[$k] === '') ? $d : $configRaw[$k];
$c   = fn(string $sec, string $sub, string $k, string $d = '') => (!isset($cms[$sec][$sub][$k]) || $cms[$sec][$sub][$k] === '') ? $d : $cms[$sec][$sub][$k];

$cfgNombreLab = $cfg('nombre_laboratorio');
$cfgNombreC   = $cfg('nombre_corto');
$cfgTel       = $cfg('telefono');
$cfgTelDigit  = waNum($cfgTel);
$cfgWA        = waNum($cfg('whatsapp_numero'));
$cfgEmail     = $cfg('email_contacto');
$cfgDirCalle  = $cfg('direccion_calle', 'Azucenas #8, Fracc. Jardines del Sur');
$cfgCiudad    = $cfg('ciudad', 'Huajuapan de León');
$cfgEstado    = $cfg('estado', 'Oaxaca');
$cfgCP        = $cfg('cp', '69000');
$cfgDir       = trim("{$cfgDirCalle}, {$cfgCiudad}, {$cfgEstado}" . ($cfgCP ? ". C.P. {$cfgCP}" : ""));
$cfgHorSem    = $cfg('horario_semana');
$cfgHorDom    = $cfg('horario_domingo');
$cfgHrsOpen   = $cfg('hrs_open');
$cfgHrsClose  = $cfg('hrs_close');
$cfgDomOpen   = $cfg('dom_open');
$cfgDomClose  = $cfg('dom_close');
$cfgRespNom   = $cfg('responsable_nombre');
$cfgRespProf  = $cfg('responsable_cedula_prof');
$cfgRespEsp   = $cfg('responsable_cedula_esp');
$cfgFB        = $cfg('facebook_url');
$cfgMapsUrl   = $cfg('maps_url');
$cfgGeoLat    = (float)($cfg('geo_lat') ?: 17.8028691);
$cfgGeoLng    = (float)($cfg('geo_lng') ?: -97.7779575);

$waBase        = "https://wa.me/52{$cfgWA}";
$waTextoInfo   = $cfg('wa_texto_info');
$waTextoAg     = $cfg('wa_texto_agendar');
$waInfoUrl     = $waBase . '?text=' . rawurlencode($waTextoInfo);
$waContactUrl  = $waInfoUrl;

$c = fn(string $sec, string $sub, string $k, string $d = '') => $cms[$sec][$sub][$k] ?? $d;

const GRUPO_SVGS = [
    1 => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>',
    2 => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>',
    3 => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>',
    4 => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 3H5a2 2 0 0 0-2 2v4m6-6h10a2 2 0 0 1 2 2v4M9 3v18m0 0h10a2 2 0 0 0 2-2V9M9 21H5a2 2 0 0 1-2-2V9m0 0h18"/></svg>',
];

// ── 1c. Árbol de estudios clínicos ──────────────────────────────────────────
$cg = $_bypassCache ? null : \Common\Cache::get(\Common\Cache::KEY_TREE);
if ($cg === null) {
    $cg = [];
    $treeStmt = $db->query("
        SELECT 
            grupo_id, 
            grupo_titulo,
            cat_id, 
            cat_nombre,
            clave_interna, 
            estudio_nombre, 
            tiempo_procesamiento, 
            muestra_requerida, 
            preparacion, 
            contenedor, 
            pruebas_incluidas
        FROM vw_website_arbol_estudios
        ORDER BY grupo_orden ASC, grupo_id ASC, cat_orden ASC, estudio_nombre ASC
    ");
    $treeRows = $treeStmt ? $treeStmt->fetchAll(\PDO::FETCH_ASSOC) : [];

    $gMap = [];
    $gIdxMap = [];
    $currGIdx = 0;
    foreach ($treeRows as $r) {
        $gid = (int)$r['grupo_id'];
        if (!isset($gIdxMap[$gid])) {
            $currGIdx++;
            $gIdxMap[$gid] = $currGIdx;
            $cg[$currGIdx] = ['titulo' => $r['grupo_titulo'], 'fichas' => []];
        }
        $gi    = $gIdxMap[$gid];
        $catId = (string)$r['cat_id'];
        if (!isset($gMap[$gid][$catId])) {
            $gMap[$gid][$catId] = count($cg[$gi]['fichas']);
            $cg[$gi]['fichas'][] = ['cat' => $r['cat_nombre'], 'items' => []];
        }
        $cPos = $gMap[$gid][$catId];
        $cg[$gi]['fichas'][$cPos]['items'][] = [
            'clave_interna'        => $r['clave_interna'],
            'nombre'               => $r['estudio_nombre'],
            'tiempo_procesamiento' => $r['tiempo_procesamiento'],
            'muestra_requerida'    => $r['muestra_requerida'],
            'preparacion'          => $r['preparacion'],
            'contenedor'           => $r['contenedor'],
            'pruebas_incluidas'    => $r['pruebas_incluidas'],
        ];
    }
    if (!$_bypassCache) \Common\Cache::set(\Common\Cache::KEY_TREE, $cg);
}

$heroAutoplay = min(90, max(0, (int)$c('hero', 'config', 'transition_time', '5')));
$qsConfianzaHtml = $c('quienes-somos', 'ficha4', 'texto');

$carouselCards = [];
for ($ci = 1; $ci <= 16; $ci++) {
    $cActivo = $c('especialidades', "carousel{$ci}", 'activo', $ci <= 12 ? '1' : '0');
    if ($cActivo === '0') continue;
    $cHtml = trim((string)$c('especialidades', "carousel{$ci}", 'texto'));
    if ($cHtml === '') continue;
    $cImg = trim((string)$c('especialidades', 'config', "carousel{$ci}_img", $cfg("carousel{$ci}_img", '')));
    $carouselCards[$ci] = [
        'img'   => $cImg,
        'texto' => $cHtml,
    ];
}

$_calDef = [
    1 => ['Área de Hematología',      'Análisis de biometría hemática y células sanguíneas con rigor científico y alta precisión.'],
    2 => ['Química Clínica',          'Determinación automatizada de metabolitos, perfil lipídico y enzimas específicas.'],
    3 => ['Microbiología y Cultivos', 'Aislamiento, tinción de Gram y pruebas de susceptibilidad a antimicrobianos.'],
];
$calidadCards = [];
for ($qi = 1; $qi <= 3; $qi++) {
    $qActivo = $c('calidad', "gallery{$qi}", 'activo', '1');
    if ($qActivo === '0') continue;
    $calidadCards[$qi] = [
        'img'    => $c('calidad', "gallery{$qi}", 'imagen_url', ''),
        'alt'    => $_calDef[$qi][0],
        'titulo' => $c('calidad', "gallery{$qi}", 'titulo',      $_calDef[$qi][0]),
        'desc'   => $c('calidad', "gallery{$qi}", 'descripcion', $_calDef[$qi][1]),
    ];
}

$promos = $_bypassCache ? null : \Common\Cache::get(\Common\Cache::KEY_PROMOS);
if ($promos === null) {
    $promoStmt = $db->query(
        "SELECT id, dia_semana, imagen_fondo, activo
         FROM catalogo_promociones
         WHERE activo = 1
         ORDER BY orden ASC, id ASC"
    );
    $promos = $promoStmt ? $promoStmt->fetchAll(\PDO::FETCH_ASSOC) : [];
    if (!$_bypassCache) \Common\Cache::set(\Common\Cache::KEY_PROMOS, $promos);
}

if ($isPreview && !empty($_SESSION['cms_draft']['promociones'])) {
    $promoDraft = $_SESSION['cms_draft']['promociones'];
    $draftPromos = [];
    foreach ([1,2,3,4,5,6,7] as $pId) {
        if (!isset($promoDraft["promo_active_{$pId}"])) continue;
        $existingRow = null;
        foreach ($promos as $row) {
            if ($row['id'] == $pId) {
                $existingRow = $row;
                break;
            }
        }
        $draftRow = $existingRow ?: ['id' => $pId];
        $draftRow['dia_semana']   = $promoDraft["promo_dia_semana_{$pId}"] ?? '';
        $draftRow['imagen_fondo'] = $promoDraft["promo_img_{$pId}"] ?? '';
        $draftRow['activo']       = 1;
        $draftPromos[] = $draftRow;
    }
    $promos = $draftPromos;
}

$navTagL1 = $c('hero', 'navbar', 'tagline_l1');
$navTagL2 = $c('hero', 'navbar', 'tagline_l2');

$heroSliderMode = $c('hero', 'config', 'slider_mode', 'sync');
$heroFixedImgIdx = (int)$c('hero', 'config', 'fixed_image', '1');

$slides = [];
for ($si = 1; $si <= 5; $si++) {
    $imgUrl = $c('hero', "slide{$si}", 'imagen_url', '');
    $slides[$si] = [
        'etiqueta'    => $c('hero', "slide{$si}", 'etiqueta'),
        'titulo'      => $c('hero', "slide{$si}", 'titulo'),
        'descripcion' => $c('hero', "slide{$si}", 'descripcion'),
        'cta_texto'   => $c('hero', "slide{$si}", 'cta_texto'),
        'cta_href'    => $c('hero', "slide{$si}", 'cta_href'),
        'imagen_url'  => $imgUrl,
        'bg_style'    => (!in_array($heroSliderMode, ['decoupled', 'decoupled_hidden', 'fixed_all']) && $imgUrl)
            ? 'background-image:url(' . h($imgUrl) . ');'
            : '',
    ];
}

$heroParentBgStyle = '';
$hasParentBg = in_array($heroSliderMode, ['decoupled', 'decoupled_hidden', 'fixed_all']);
if ($hasParentBg) {
    $fixedUrl = $slides[$heroFixedImgIdx]['imagen_url'] ?? '';
    if ($fixedUrl) {
        $heroParentBgStyle = ' style="background-image:url(' . h($fixedUrl) . '); background-size: cover; background-position: center center; background-repeat: no-repeat;"';
    }
}

$slide5DescRaw = $slides[5]['descripcion'];
$slide5DescGenerated = (h($cfgDirCalle ?: $cfgDir) . ', ' . h($cfgCiudad) . ', ' . h($cfgEstado) . '.<br>'
      . h($cfgHorSem) . ' &nbsp;|&nbsp; ' . h($cfgHorDom) . ' &nbsp;|&nbsp; Tel: ' . h($cfgTel));
$slide5DescHTML = $slide5DescRaw ? h($slide5DescRaw) : $slide5DescGenerated;

$hideHeroMessages = in_array($heroSliderMode, ['sync_hidden', 'decoupled_hidden']);
$useFixedMessage = in_array($heroSliderMode, ['sync_fixed_msg', 'fixed_all']);

$msgs = [];
for ($si = 1; $si <= 5; $si++) {
    $srcIdx = $useFixedMessage ? $heroFixedImgIdx : $si;
    $msgs[$si] = $slides[$srcIdx];
    $msgs[$si]['desc_html'] = ($srcIdx === 5) ? $slide5DescHTML : h($slides[$srcIdx]['descripcion']);
}

$qsH2         = $c('quienes-somos', 'seccion',   'h2');
$qsSub        = $c('quienes-somos', 'seccion',   'subtitulo');
$qsCompromiso = $c('quienes-somos', 'seccion',   'compromiso');
$qsMision     = $c('quienes-somos', 'ficha2',    'texto');
$qsVision     = $c('quienes-somos', 'ficha3',    'texto');
$qsHistoriaHtml = $c('quienes-somos', 'ficha1', 'texto');
$qsRespBio      = $c('quienes-somos', 'resp', 'bio');
$qsRespFraseTpl = $c('quienes-somos', 'resp', 'frase_trayectoria');
$qsRespFrase    = str_replace('{lab}', h($cfgNombreC), h($qsRespFraseTpl));
$qsFiloCita   = $c('quienes-somos', 'filosofia', 'tagline');
$qsFiloTxt    = $c('quienes-somos', 'filosofia', 'texto');

$catalogH2   = $c('especialidades', 'seccion',  'h2');
$catalogSub  = $c('especialidades', 'seccion',  'subtitulo');
$catalogNota = $c('especialidades', 'catalogo', 'nota_pie');

$promoH2  = $c('promociones', 'banner', 'titulo');
$promoSub = $c('promociones', 'banner', 'subtitulo');

$calH2  = $c('calidad', 'seccion', 'h2');
$calSub = $c('calidad', 'seccion', 'subtitulo');

$ubH2      = $c('ubicacion', 'seccion', 'h2');
$ubSub     = $c('ubicacion', 'seccion', 'subtitulo');

$footerBgColor = $c('footer', 'estilo', 'bg_color', '#0f172a');
$footerHtml    = safeHtml(trim($c('footer', 'contenido', 'cuerpo_html')));
$avisoHtml     = $c('aviso-privacidad', 'contenido', 'cuerpo_html');

$schemaName  = h($c('seo', 'schema', 'schema_name') ?: 'Laboratorio de Especialidades Hematológicas S.C.');
$schemaType  = h($c('seo', 'schema', 'schema_type') ?: 'MedicalLaboratory');
$seoTitle    = $c('seo', 'meta', 'title') ?: 'LAESH — Laboratorio de Especialidades Hematológicas | Huajuapan';
$seoDesc     = $c('seo', 'meta', 'description') ?: 'Laboratorio de análisis clínicos y estudios hematológicos de alta precisión en Huajuapan de León, Oaxaca.';

$waSvg = '<svg width="18" height="18" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">'
       . '<path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>'
       . '<path d="M12 0C5.373 0 0 5.373 0 12c0 2.124.558 4.118 1.532 5.845L0 24l6.335-1.652A11.954 11.954 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22c-1.885 0-3.65-.508-5.17-1.395l-.37-.22-3.76.981 1.005-3.665-.243-.382A9.944 9.944 0 012 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>'
       . '</svg>';
?>
<!DOCTYPE html>
<html lang="es-MX">
<head>
    <meta charset="UTF-8">
    <meta name="color-scheme" content="light">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= h($seoTitle) ?></title>
    <meta name="description" content="<?= h($seoDesc) ?>">
    <meta name="theme-color" content="#71CA11">
    <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1">
    <?php
    $ogTitle    = $c('seo','og','og_title') ?: $seoTitle;
    $ogDesc     = $c('seo','og','og_description') ?: $seoDesc;
    $ogSiteName = $c('seo','og','site_name') ?: 'LAESH — Laboratorio de Especialidades Hematológicas S.C.';
    $ogImgRaw  = $c('seo','og','og_image');
    $ogImg     = ($ogImgRaw && str_starts_with($ogImgRaw, '/')) ? 'https://laesh.mx' . $ogImgRaw : $ogImgRaw;
    $ogImgExt  = strtolower(pathinfo((string)$ogImgRaw, PATHINFO_EXTENSION));
    $ogImgMime = match($ogImgExt) {
        'jpg', 'jpeg' => 'image/jpeg',
        'png'         => 'image/png',
        'webp'        => 'image/webp',
        default       => 'image/webp',
    };
    ?>
    <meta property="og:title" content="<?= h($ogTitle) ?>">
    <meta property="og:description" content="<?= h($ogDesc) ?>">
    <meta property="og:site_name" content="<?= h($ogSiteName) ?>">
    <meta property="og:image" content="<?= h($ogImg) ?>">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://laesh.mx/">
    <meta property="og:locale" content="es_MX">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="<?= h($ogTitle) ?>">
    <meta name="twitter:description" content="<?= h($ogDesc) ?>">
    <meta name="twitter:image" content="<?= h($ogImg) ?>">
    <link rel="canonical" href="https://laesh.mx/">
    <link rel="alternate" hreflang="es-MX" href="https://laesh.mx/">
    <link rel="icon" type="image/svg+xml" href="/laesh-web-assets-uipv1a/img/favicon.svg">
    <meta http-equiv="Content-Security-Policy" content="default-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self' data:; img-src 'self' data: https://*.ggpht.com https://*.gstatic.com https://*.google.com https://*.googleusercontent.com https://*.tile.openstreetmap.org https://*.openstreetmap.org https://i.ytimg.com; frame-src https://maps.google.com https://www.google.com https://google.com https://*.google.com https://www.openstreetmap.org https://www.youtube.com https://youtube.com https://open.spotify.com https://player.vimeo.com https://www.dailymotion.com https://www.instagram.com https://www.facebook.com https://platform.twitter.com https://twitframe.com; script-src 'self' 'unsafe-inline' https://maps.google.com https://www.google.com; connect-src 'self' ws: wss: https://*.google.com https://*.openstreetmap.org;">
    <script src="/laesh-web-assets-uipv1a/js/device-detect.js?v=<?= time() ?>"></script>
    <link rel="stylesheet" href="/laesh-web-assets-uipv1a/css/tokens.css?v=<?= time() ?>">
    <link rel="stylesheet" href="/laesh-web-assets-uipv1a/css/fonts.css?v=<?= time() ?>">
    <link rel="stylesheet" href="/laesh-web-assets-uipv1a/css/style.css?v=<?= time() ?>">
    <link rel="stylesheet" href="/laesh-web-assets-uipv1a/css/style-website-m1.css?v=<?= time() ?>">
    <link rel="stylesheet" href="/laesh-web-assets-uipv1a/css/landing-m1.css?v=<?= time() ?>">
    <link rel="stylesheet" href="/laesh-web-assets-uipv1a/css/ckeditor-content.css?v=<?= time() ?>">
    <link rel="stylesheet" href="/laesh-web-assets-uipv1a/css/targeting.css?v=<?= time() ?>">
    <link rel="stylesheet" href="/laesh-web-assets-uipv1a/css/tablet-samsung-tabs10ultra.css?v=<?= time() ?>">
    <link rel="preload" href="/laesh-web-assets-uipv1a/fonts/cabin-latin-normal-w400.woff2" as="font" type="font/woff2" crossorigin>
    <link rel="preload" href="/laesh-web-assets-uipv1a/fonts/outfit-latin-normal-w300.woff2" as="font" type="font/woff2" crossorigin>

    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "<?= $schemaType ?>",
      "name": "<?= $schemaName ?>",
      "@id": "https://laesh.mx",
      "url": "https://laesh.mx",
      "logo": "https://laesh.mx/laesh-web-assets-uipv1a/img/logo-laesh.webp",
      "image": "https://laesh.mx/laesh-web-assets-uipv1a/img/logo-laesh.webp",
      "telephone": "+52<?= h(waNum($cfgTel)) ?>",
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "<?= h($cfgDirCalle) ?>",
        "addressLocality": "<?= h($cfgCiudad) ?>",
        "addressRegion": "<?= h($cfgEstado) ?>",
        "postalCode": "<?= h($cfgCP) ?>",
        "addressCountry": "MX"
      },
      "geo": {
        "@type": "GeoCoordinates",
        "latitude": <?= $cfgGeoLat ?>,
        "longitude": <?= $cfgGeoLng ?>
      },
      "sameAs": [
        "<?= h($cfgFB ?: 'https://www.facebook.com/LAESH.Huajuapan/') ?>"
      ],
      "openingHoursSpecification": [
        {
          "@type": "OpeningHoursSpecification",
          "dayOfWeek": ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],
          "opens": "<?= h($cfgHrsOpen ?: '07:00') ?>",
          "closes": "<?= h($cfgHrsClose ?: '21:00') ?>"
        },
        {
          "@type": "OpeningHoursSpecification",
          "dayOfWeek": "Sunday",
          "opens": "<?= h($cfgDomOpen ?: '07:00') ?>",
          "closes": "<?= h($cfgDomClose ?: '15:00') ?>"
        }
      ],
      "description": "<?= h($seoDesc) ?>"
    }
    </script>
</head>
<body>

<?php if ($isPreview): ?>
<div id="cms-preview-badge" role="alert" aria-live="polite"
     style="position:fixed;top:8px;right:8px;z-index:99999;
            display:flex;flex-direction:column;align-items:center;gap:7px;
            background:#ef4444;color:#ffffff;border-radius:14px;
            font:600 0.9rem/1.3 system-ui,sans-serif;
            padding:12px 14px;
            box-shadow:0 6px 20px rgba(239,68,68,0.45);
            max-width:120px;text-align:center;">
    <span style="font-size:1.35rem;line-height:1;" aria-hidden="true">🔍</span>
    <span style="color:#ffffff;letter-spacing:0.01em;font-weight:700;">Vista<br>Previa</span>
    <hr style="border:none;border-top:1px solid rgba(255,255,255,0.3);width:100%;margin:2px 0;">
    <span style="color:#ffffff;font-weight:600;font-size:0.82rem;line-height:1.25;">
        BORRADOR M1
    </span>
</div>
<?php endif; ?>

    <div id="cookie-banner" class="cookie-banner" role="dialog" aria-label="Aviso de cookies" aria-live="polite">
        <p class="cookie-banner__text">
            Este sitio utiliza almacenamiento local para mejorar la experiencia de navegación.
            <a href="#" class="cookie-banner__link" id="cookie-privacy-link">Ver Aviso de Privacidad</a>
        </p>
        <button type="button" id="cookie-accept" class="cookie-banner__btn">Aceptar</button>
    </div>
    <a href="#main-content" class="skip-link">Ir al contenido principal</a>

    <!-- NAVBAR FIJO MEJORADO -->
    <nav class="navbar-sticky" id="landing-navbar" aria-label="Menú principal">
        <div style="display:flex;align-items:center;">
            <a href="/laesh/index-m1.php" class="logo"
               aria-label="LAESH — Laboratorio de Especialidades Hematológicas, ir al inicio">
                <img src="/laesh-web-assets-uipv1a/img/logo-laesh.webp"
                     alt="LAESH — <?= h($cfgNombreLab) ?>"
                     class="hero-logo" decoding="async" fetchpriority="high"
                     width="2634" height="571">
            </a>
            <span class="navbar-tagline"><?= h($navTagL1) ?><br><?= h($navTagL2) ?></span>
        </div>
        <button type="button" class="nav-hamburger" id="nav-hamburger"
                aria-label="Abrir menú" aria-expanded="false">
            <span></span><span></span><span></span>
        </button>
        <?php
        $_SEC_DEFAULT = ['inicio','acerca-de','especialidades','promociones','calidad','ubicacion','video'];
        $_secNavLabels = [
            'acerca-de'     => ['label' => 'Quiénes somos',        'href' => '#acerca-de'],
            'especialidades'=> ['label' => 'Estudios',             'href' => '#especialidades'],
            'promociones'   => ['label' => 'Promociones',          'href' => '#promociones'],
            'calidad'       => ['label' => 'Calidad',              'href' => '#calidad'],
            'ubicacion'     => ['label' => 'Ubicación y Contacto', 'href' => '#ubicacion'],
        ];
        $isVideoActive = $cfg('video_active', '1') !== '0';

        $_secOrderRaw = $cfg('seccion_order');
        if ($_secOrderRaw !== '') {
            $_parsed = array_unique(array_filter(
                array_map('trim', explode(',', $_secOrderRaw)),
                fn($s) => in_array($s, $_SEC_DEFAULT, true)
            ));
            $_missing = array_diff($_SEC_DEFAULT, $_parsed);
            $sectionOrder = array_values(array_merge($_parsed, $_missing));
        } else {
            $sectionOrder = $_SEC_DEFAULT;
        }
        unset($_SEC_DEFAULT, $_secOrderRaw, $_parsed, $_missing);

        if (!$isVideoActive) {
            $sectionOrder = array_values(array_filter($sectionOrder, fn($s) => $s !== 'video'));
        }
        ?>
        <div class="nav-links" id="nav-links-mobile">
            <a href="#inicio">Inicio</a>
            <?php foreach ($sectionOrder as $_navSec):
                if (isset($_secNavLabels[$_navSec])):
            ?>
            <a href="<?= $_secNavLabels[$_navSec]['href'] ?>"><?= h($_secNavLabels[$_navSec]['label']) ?></a>
            <?php endif; endforeach; unset($_navSec); ?>
            <a href="#" class="login-trigger btn-nav-medicos"
               data-target="medicos" data-title="Acceso" role="button">
                <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 2v2"/><path d="M5 2v2"/><path d="M5 3H4a2 2 0 0 0-2 2v4a6 6 0 0 0 12 0V5a2 2 0 0 0-2-2h-1"/><path d="M8 15a6 6 0 0 0 12 0v-3"/><circle cx="20" cy="10" r="2"/></svg>
                <span>Acceso Médicos</span>
            </a>
        </div>
    </nav>

    <main id="main-content">
        <div class="landing-nav-spacer"></div>

        <?php
        foreach ($sectionOrder as $_secId):
            if ($_secId === 'inicio'):
        ?>
        <!-- ═══════════════════════════════════════════════ HERO (M1) ══ -->
        <section id="inicio" class="hero-premium">
            <div class="hero-slides" data-autoplay="<?= in_array($heroSliderMode, ['decoupled_hidden', 'fixed_all']) ? 0 : $heroAutoplay ?>" role="region"
                 aria-label="Presentación principal" aria-roledescription="carrusel"<?= $heroParentBgStyle ?>>

                <?php for ($si = 1; $si <= 5; $si++): ?>
                <div class="hero-slide <?= ($si === 1) ? 'active' : '' ?> <?= !$hasParentBg ? "bg-slide-{$si}" : '' ?>"<?= $slides[$si]['bg_style'] ? ' style="' . $slides[$si]['bg_style'] . '"' : '' ?>>
                    <?php if (!$hideHeroMessages): ?>
                    <div class="hero-glass-card">
                        <?php if (!empty($msgs[$si]['etiqueta'])): ?>
                            <span><?= h($msgs[$si]['etiqueta']) ?></span>
                        <?php endif; ?>
                        <?php if ($si === 1): ?>
                            <h1><?= h($msgs[$si]['titulo']) ?></h1>
                        <?php else: ?>
                            <h2><?= h($msgs[$si]['titulo']) ?></h2>
                        <?php endif; ?>
                        <?php if (!empty($msgs[$si]['desc_html'])): ?>
                            <p><?= $msgs[$si]['desc_html'] ?></p>
                        <?php endif; ?>
                        <?php if (!empty($msgs[$si]['cta_texto'])): ?>
                            <div>
                                <a href="<?= h($msgs[$si]['cta_href']) ?>" class="btn-secondary">
                                    <span><?= h($msgs[$si]['cta_texto']) ?></span>
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
                                </a>
                            </div>
                        <?php endif; ?>
                    </div>
                    <?php endif; ?>
                </div>
                <?php endfor; ?>
            </div>

            <?php if (!in_array($heroSliderMode, ['decoupled_hidden', 'fixed_all'])): ?>
            <div class="hero-dots" aria-label="Navegación de diapositivas">
                <button class="hero-dot active" data-slide="0" aria-label="Diapositiva 1 de 5" aria-pressed="true"></button>
                <button class="hero-dot"        data-slide="1" aria-label="Diapositiva 2 de 5" aria-pressed="false"></button>
                <button class="hero-dot"        data-slide="2" aria-label="Diapositiva 3 de 5" aria-pressed="false"></button>
                <button class="hero-dot"        data-slide="3" aria-label="Diapositiva 4 de 5" aria-pressed="false"></button>
                <button class="hero-dot"        data-slide="4" aria-label="Diapositiva 5 de 5" aria-pressed="false"></button>
            </div>
            <button type="button" id="hero-pause-btn" class="hero-pause-btn"
                    aria-label="Pausar presentación" aria-pressed="false">
                <svg id="hero-icon-pause" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>
                <svg id="hero-icon-play"  width="13" height="13" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" class="d-none"><polygon points="5,3 19,12 5,21"/></svg>
                <span id="hero-pause-label" class="hero-pause-label">Pausar</span>
            </button>
            <?php endif; ?>
            <span id="hero-announcer" class="sr-only" aria-live="polite" aria-atomic="true"></span>
        </section>
        <?php
            else:
                include __DIR__ . '/sections-m1/' . $_secId . '.php';
            endif;
        endforeach;
        unset($sectionOrder, $_secId, $_secNavLabels, $isVideoActive);
        ?>

        <!-- ══════════════════════════════════════════════ FOOTER ══ -->
        <footer class="footer-main" style="background: <?= h($footerBgColor) ?> !important;" role="contentinfo">
            <?= $footerHtml ?>
        </footer>
    </main>

    <!-- Botón WhatsApp flotante -->
    <a href="<?= h($waInfoUrl) ?>" class="whatsapp-float"
       target="_blank" rel="noopener noreferrer"
       title="Contáctanos por WhatsApp" aria-label="Contáctanos por WhatsApp">
        <svg width="32" height="32" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
            <path d="M12.012 2c-5.506 0-9.989 4.478-9.99 9.984a9.96 9.96 0 0 0 1.335 4.975L2 22l5.195-1.364A9.936 9.936 0 0 0 12.006 22c5.507 0 9.991-4.479 9.992-9.986.002-2.668-1.036-5.18-2.924-7.069C17.186 3.057 14.675 2.002 12.012 2zm5.72 14.15c-.314.88-1.543 1.62-2.13 1.7-.587.08-1.173.28-4.08-.93-3.72-1.54-6.12-5.32-6.3-5.57-.18-.25-1.47-1.95-1.47-3.72 0-1.78.93-2.65 1.26-3 .33-.35.72-.44.96-.44h.69c.22 0 .52-.08.82.64.3.72 1.02 2.48 1.11 2.66.09.18.15.39.03.63-.12.24-.18.39-.36.6-.18.21-.38.47-.54.63-.18.18-.37.38-.16.73.21.35.93 1.54 2 2.49 1.38 1.23 2.54 1.61 2.9 1.79.36.18.57.15.78-.09.21-.24.9-1.05 1.14-1.41.24-.36.48-.3.8-.18.33.12 2.07 1.02 2.43 1.2.36.18.6.27.69.42.09.15.09.87-.22 1.75z"/>
        </svg>
    </a>

    <!-- Botón Facebook flotante -->
    <?php if ($cfgFB): ?>
    <a class="social-float fb-bg" href="<?= h($cfgFB) ?>"
       target="_blank" rel="noopener noreferrer"
       title="Visita nuestro Facebook" aria-label="Visita nuestro Facebook">
        <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
            <path d="M24 12.073C24 5.405 18.627 0 12 0S0 5.405 0 12.073C0 18.1 4.388 23.094 10.125 24v-8.437H7.078v-3.49h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.49h-2.796V24C19.612 23.094 24 18.1 24 12.073z"/>
        </svg>
    </a>
    <?php endif; ?>

    <!-- Modal: Aviso de Privacidad -->
    <div id="modal-privacidad" class="modal" role="dialog" aria-modal="true" aria-labelledby="modal-privacidad-title">
        <div class="modal-content modal-lg">
            <div class="modal-header">
                <h3 id="modal-privacidad-title">Aviso de Privacidad — <?= h($cfgNombreC) ?></h3>
                <button type="button" class="close-modal" aria-label="Cerrar">&times;</button>
            </div>
            <div class="modal-body modal-scroll-h">
                <?= $avisoHtml ?>
            </div>
        </div>
    </div>

    <!-- Modal: Acceso Portal (Login) -->
    <div id="modal-login" class="modal" role="dialog" aria-modal="true" aria-labelledby="modal-login-title">
        <div class="modal-content modal-login-box">
            <div class="modal-header">
                <h3 id="modal-login-title">Acceso Médico</h3>
                <button type="button" class="close-modal" id="btn-cerrar-login" aria-label="Cerrar">&times;</button>
            </div>
            <div class="modal-body">
                <form id="form-login-portal" class="form-col-1rem" novalidate autocomplete="off">
                    <input type="hidden" id="login-redirect-target" value="medico">
                    <input type="hidden" id="login-csrf-token" name="csrf_token"
                           value="<?= h($_SESSION['csrf_token']) ?>">
                    <input type="hidden" id="login-portal-name" name="portal" value="medico">
                    <div>
                        <label class="form-label" for="login-phone">Usuario <span class="req">*</span></label>
                        <input type="text" inputmode="numeric" id="login-phone" name="telefono" required
                               class="form-input" maxlength="10"
                               placeholder="Número de teléfono (10 dígitos)"
                               autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false">
                    </div>
                    <div>
                        <label class="form-label" for="login-pass">Contraseña <span class="req">*</span></label>
                        <input type="text" id="login-pass" name="password" required
                               class="form-input" maxlength="10"
                               placeholder="••••••••••"
                               autocomplete="off" autocorrect="off" autocapitalize="none"
                               spellcheck="false">
                    </div>
                    <div id="login-error-msg" class="login-error-box"></div>
                    <button type="submit" id="btn-login-submit" class="btn btn-primary">Ingresar</button>
                </form>
            </div>
        </div>
    </div>

    <!-- Modal: Vista de Imagen Completa (Promociones) -->
    <div id="modal-img-promo" class="modal modal-promo-overlay" role="dialog" aria-modal="true" aria-labelledby="modal-img-promo-title">
        <div class="modal-content modal-img-promo-content">
            <div class="modal-header modal-img-promo-header">
                <div id="modal-img-promo-title" class="modal-img-promo-title ck-content">Promoción — Imagen Completa</div>
                <button type="button" class="close-modal" onclick="closePromoModal()" aria-label="Cerrar">&times;</button>
            </div>
            <div class="modal-body modal-img-promo-body">
                <img id="modal-img-promo-src" src=""
                     class="modal-img-promo-real"
                     alt="Imagen Completa de Promoción" loading="lazy">
            </div>
        </div>
    </div>

    <script>
        window.LAESH_HERO_AUTOPLAY = <?= $heroAutoplay ?>;

        window.openPromoModal = function(imgSrc, title) {
            var promoModal = document.getElementById('modal-img-promo');
            if (!promoModal) return;
            var promoImgSrc = document.getElementById('modal-img-promo-src');
            var promoTitle = document.getElementById('modal-img-promo-title');

            if (promoImgSrc && imgSrc) promoImgSrc.src = imgSrc;
            if (promoTitle) promoTitle.innerHTML = title || 'Promoción — Imagen Completa';

            promoModal.classList.add('show');
            document.body.classList.add('modal-open');
        };

        window.closePromoModal = function() {
            var promoModal = document.getElementById('modal-img-promo');
            if (promoModal) {
                promoModal.classList.remove('show');
                document.body.classList.remove('modal-open');
            }
        };

        document.addEventListener('click', function(e) {
            var btn = e.target.closest('.btn-promo-whatsapp') || e.target.closest('a');
            if (btn) return;

            var card = e.target.closest('.catalog-card') || e.target.closest('[data-promo-img]');
            if (!card) return;

            var imgSrc = card.getAttribute('data-promo-img');
            if (!imgSrc || imgSrc.trim() === '') {
                var imgEl = card.querySelector('.catalog-card-img') || card.querySelector('img');
                if (imgEl) imgSrc = imgEl.getAttribute('src');
            }
            if (!imgSrc || imgSrc.trim() === '') return;

            var title = card.getAttribute('data-promo-title-html') || card.getAttribute('data-promo-title') || 'Promoción — Imagen Completa';
            if (typeof window.openPromoModal === 'function') {
                window.openPromoModal(imgSrc, title);
            }
        });

        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' || e.keyCode === 27) {
                if (typeof window.closePromoModal === 'function') window.closePromoModal();
            }
        });

        document.addEventListener('DOMContentLoaded', function() {
            var promoModal = document.getElementById('modal-img-promo');
            if (promoModal) {
                var closeBtn = promoModal.querySelector('.close-modal');
                if (closeBtn) {
                    closeBtn.addEventListener('click', function() {
                        if (typeof window.closePromoModal === 'function') window.closePromoModal();
                    });
                }
                promoModal.addEventListener('click', function(e) {
                    if (e.target === promoModal) {
                        if (typeof window.closePromoModal === 'function') window.closePromoModal();
                    }
                });
            }
        });
    </script>
    <script>
    (function(){
        var els = document.querySelectorAll('.animate-on-scroll');
        if (!els.length) return;
        if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            els.forEach(function(el){ el.classList.add('visible'); });
            window._laeshObserver = 'noop';
            return;
        }
        if (!('IntersectionObserver' in window)) {
            els.forEach(function(el){ el.classList.add('visible'); });
            window._laeshObserver = 'noop';
            return;
        }
        var io = new IntersectionObserver(function(entries){
            entries.forEach(function(e){
                if (e.isIntersecting) { e.target.classList.add('visible'); }
            });
        }, { threshold: 0.05, rootMargin: '0px' });
        els.forEach(function(el){ io.observe(el); });
        window._laeshObserver = io;
    })();
    </script>
    <script src="/laesh-web-assets-uipv1a/js/htmx.min.js" async fetchpriority="low"></script>
    <script src="/laesh-web-assets-uipv1a/js/website.js?v=<?= @filemtime(__DIR__ . '/../../laesh-web-assets-uipv1a/js/website.js') ?: time() ?>" defer></script>

</body>
</html>
