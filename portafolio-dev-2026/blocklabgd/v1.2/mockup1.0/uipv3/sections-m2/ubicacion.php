<?php
/**
 * sections-m1/ubicacion.php — Partial Mejorado: Ubicación y Contacto
 * Incluido desde website/index-m1.php; hereda su scope completo.
 * Variables esperadas: $ubH2, $ubSub, $cfgDir, $cfgTelDigit, $cfgTel, $cfgEmail,
 *   $waContactUrl, $cfg, $cfgHorSem, $cfgHorDom, $cfgRespNom, $cfgRespProf,
 *   $cfgRespEsp, $c, $cfgNombreC, $cfgMapsUrl, $mapsEmbed
 */
?>
        <!-- ══════════════════════════════════════ UBICACIÓN Y CONTACTO (M1) ══ -->
        <section id="ubicacion" class="sec-pad-1 scroll-sm-top">
            <div class="section-header animate-on-scroll">
                <h2><?= h($ubH2) ?></h2>
                <p><?= h($ubSub) ?></p>
            </div>

            <div class="location-stack-layout">

                <!-- Mapa — Croquis de ubicación con botón a Mapa Interactivo externo -->
                <div class="card-premium animate-on-scroll delay-200 map-card map-card-m1">
                    <div class="map-bottom-bar">
                        <button type="button" id="btn-map-static" class="map-tab-btn active cursor-default">
                            <img src="/laesh-web-assets-uipv1a/icons/eye.svg" alt="" loading="lazy" decoding="async">
                            Croquis de Acceso
                        </button>
                        <span class="map-sep">|</span>
                        <a href="<?= h($cfgMapsUrl) ?>"
                           target="_blank" rel="noopener noreferrer"
                           id="btn-map-interactive" class="map-tab-btn map-link-flex btn-maps-cta">
                            <img src="/laesh-web-assets-uipv1a/icons/map-pin.svg" alt="" loading="lazy" decoding="async">
                            Abrir en Google Maps / Waze ↗
                        </a>
                    </div>
                    <div id="map-static" class="map-static-wrap">
                        <div class="map-zoom-link">
                            <?php $croquisImg = $c('ubicacion','croquis','imagen_url'); ?>
                            <?php if (!empty($croquisImg)): ?>
                            <img src="<?= h($croquisImg) ?>"
                                 alt="Croquis de Ubicación <?= h($cfgNombreC) ?>"
                                 class="map-zoom-img" width="1136" height="615"
                                 loading="lazy" decoding="async">
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>
        </section>
