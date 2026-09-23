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
                <!-- Datos de contacto — Cuadrícula semántica y directa -->
                <div class="card-premium animate-on-scroll delay-100 contact-card-horizontal contact-card-m1">
                    <div class="contact-header-wrap">
                        <div class="contact-header-badge">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
                            <span>Atención Inmediata</span>
                        </div>
                        <h3 class="acerca-h3">Información de Contacto y Servicios</h3>
                    </div>

                    <div class="contact-grid-horizontal contact-grid-m1">
                        <!-- Bloque 1: Dirección Física -->
                        <div class="info-row-item contact-box-m1">
                            <div class="contact-icon-bubble">
                                <img src="/laesh-web-assets-uipv1a/icons/map-pin.svg" alt="" class="icon-22" loading="lazy" decoding="async">
                            </div>
                            <div class="txt-base-lh">
                                <strong class="list-link-block">Dirección</strong>
                                <span class="contact-text-val"><?= h($cfgDir) ?></span>
                            </div>
                        </div>

                        <!-- Bloque 2: Teléfono de Oficina -->
                        <div class="info-row-item contact-box-m1">
                            <div class="contact-icon-bubble">
                                <img src="/laesh-web-assets-uipv1a/icons/phone.svg" alt="" class="icon-22" loading="lazy" decoding="async">
                            </div>
                            <div class="txt-base-lh">
                                <strong class="list-link-block">Teléfono de Atención</strong>
                                <a href="tel:<?= h($cfgTelDigit) ?>" class="resp-name contact-action-link" title="Llamar a recepción"><?= h($cfgTel) ?></a>
                            </div>
                        </div>

                        <!-- Bloque 3: WhatsApp y Email -->
                        <div class="contact-col-gap contact-box-m1">
                            <div class="info-row-item">
                                <div class="contact-icon-bubble contact-icon-wa">
                                    <img src="/laesh-web-assets-uipv1a/icons/whatsapp.svg" alt="" class="icon-22" loading="lazy" decoding="async">
                                </div>
                                <div class="txt-base-lh">
                                    <strong class="list-link-block">WhatsApp</strong>
                                    <a href="<?= h($waContactUrl) ?>" target="_blank" rel="noopener noreferrer" class="resp-name contact-action-link" title="Enviar mensaje de WhatsApp"><?= h($cfg('whatsapp_numero')) ?></a>
                                </div>
                            </div>
                            <div class="info-row-item">
                                <div class="contact-icon-bubble">
                                    <img src="/laesh-web-assets-uipv1a/icons/mail.svg" alt="" class="icon-22" loading="lazy" decoding="async">
                                </div>
                                <div class="txt-base-lh">
                                    <strong class="list-link-block">Correo Electrónico</strong>
                                    <a href="mailto:<?= h($cfgEmail) ?>" class="email-link-hover contact-action-link"><?= h($cfgEmail) ?></a>
                                </div>
                            </div>
                        </div>

                        <!-- Bloque 4: Horarios -->
                        <div class="info-row-item contact-box-m1">
                            <div class="contact-icon-bubble">
                                <img src="/laesh-web-assets-uipv1a/icons/clock.svg" alt="" class="icon-22" loading="lazy" decoding="async">
                            </div>
                            <div class="txt-base-lh">
                                <strong class="list-link-block">Horarios de Atención</strong>
                                <span class="contact-text-val"><?= h($cfgHorSem) ?><br><?= h($cfgHorDom) ?></span>
                            </div>
                        </div>

                        <!-- Bloque 5: Responsable Sanitario -->
                        <div class="info-row-item contact-box-m1 contact-box-resp">
                            <div class="contact-icon-bubble">
                                <img src="/laesh-web-assets-uipv1a/icons/user.svg" alt="" class="icon-22" loading="lazy" decoding="async">
                            </div>
                            <div class="contact-resp-body">
                                <strong class="resp-title">Responsable Sanitario</strong>
                                <span class="resp-name"><?= h($cfgRespNom) ?></span>
                                <span class="resp-cedulas">Céd. Prof. <?= h($cfgRespProf) ?> &bull; Céd. Esp. <?= h($cfgRespEsp) ?></span>
                            </div>
                        </div>

                    </div>
                </div>

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
