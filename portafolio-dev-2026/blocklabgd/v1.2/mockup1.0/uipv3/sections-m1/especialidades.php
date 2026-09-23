<?php
/**
 * sections-m1/especialidades.php — Partial Mejorado: Estudios / Catálogo
 * Incluido desde website/index-m1.php; hereda su scope completo.
 * Variables esperadas: $catalogH2, $catalogSub, $carouselCards, $catalogNota, $cg, GRUPO_SVGS
 */
?>
        <!-- ═══════════════════════════════════════════════ ESTUDIOS (M1) ══ -->
        <section id="especialidades" class="sec-pad-1-5 scroll-sm-top">
            <div class="section-header animate-on-scroll">
                <h2><?= h($catalogH2) ?></h2>
                <p><?= h($catalogSub) ?></p>
            </div>

            <!-- Carrusel de áreas e infraestructura del laboratorio -->
            <div class="map-bar specialties-carousel-wrapper">
                <button type="button" class="carousel-arrow-btn carousel-arrow-btn--left"
                        id="btn-carousel-prev" aria-label="Anterior">
                    <img src="/laesh-web-assets-uipv1a/icons/chevron-left.svg" alt="" class="icon-24" loading="lazy" decoding="async">
                </button>
                <div class="specialties-carousel-viewport">
                    <div id="specialties-track" class="specialties-carousel-track">
                        <?php $ccIdx = 0; foreach ($carouselCards as $cc): $ccIdx++; ?>
                        <div class="carousel-card">
                            <div class="carousel-card__img-box">
                                <img src="<?= h($cc['img']) ?>" alt="Área de Laboratorio LAESH"
                                     width="800" height="580"
                                     loading="<?= $ccIdx <= 2 ? 'eager' : 'lazy' ?>"
                                     decoding="<?= $ccIdx <= 2 ? 'sync' : 'async' ?>">
                            </div>
                            <div class="carousel-card__body ck5-output">
                                <?= safeHtml($cc['texto']) ?>
                            </div>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
                <button type="button" class="carousel-arrow-btn carousel-arrow-btn--right"
                        id="btn-carousel-next" aria-label="Siguiente">
                    <img src="/laesh-web-assets-uipv1a/icons/chevron-right.svg" alt="" class="icon-24" loading="lazy" decoding="async">
                </button>
            </div>

            <div class="carousel-progress-wrap">
                <div id="carousel-progress" class="carousel-progress"
                     role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"
                     aria-label="Progreso del carrusel de especialidades">
                    <div id="carousel-progress-fill" class="carousel-progress-fill"></div>
                </div>
            </div>
            <div id="specialties-dots" class="hero-dots specialties-dots"
                 aria-label="Navegación de especialidades" role="region"></div>

            <!-- ── Catálogo de Estudios — 4 abanicos desde web_contenidos.especialidades ── -->
            <div class="section-catalog">
                <!-- Nota al pie / introducción del catálogo -->
                <div class="section-catalog__header-box">
                    <div class="section-catalog__badge">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                        <span>Directorio Clínico</span>
                    </div>
                    <p class="section-catalog__note"><?= h($catalogNota) ?></p>
                </div>

                <?php foreach ($cg as $gi => $grupo): ?>
                <?php if (empty($grupo['fichas'])) continue; ?>
                <div class="orden-acc">
                    <button type="button"
                            class="orden-acc-hdr<?= $gi > 1 ? ' collapsed-btn' : '' ?>"
                            data-acc="cg<?= $gi ?>">
                        <span class="flex-ic-8">
                            <span class="acc-group-icon"><?= GRUPO_SVGS[$gi] ?? GRUPO_SVGS[1] ?></span>
                            <span class="acc-group-title"><?= h($grupo['titulo']) ?></span>
                        </span>
                        <div class="acc-hdr-right">
                            <span class="acc-count-badge"><?= count($grupo['fichas']) ?> categorías</span>
                            <svg id="arr-cg<?= $gi ?>" width="20" height="20" viewBox="0 0 24 24" fill="none"
                                 stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"
                                 class="<?= $gi === 1 ? 'chevron-open' : 'chevron-arrow-svg' ?>">
                                <polyline points="6 9 12 15 18 9"/>
                            </svg>
                        </div>
                    </button>
                    <div id="cg<?= $gi ?>" class="orden-acc-body<?= $gi > 1 ? ' collapsed' : '' ?>">
                        <?php foreach ($grupo['fichas'] as $subcat): ?>
                        <div class="orden-cat">
                            <div class="orden-cat-hdr">
                                <span class="orden-cat-dot"></span>
                                <?= h($subcat['cat']) ?>
                            </div>
                            <div class="orden-cat-body">
                                <?php foreach ($subcat['items'] as $estItem): ?>
                                <div class="precio-cat-item"
                                     data-clave="<?= h($estItem['clave_interna'] ?? '') ?>"
                                     data-tiempo="<?= h($estItem['tiempo_procesamiento'] ?? '') ?>"
                                     data-muestra="<?= h($estItem['muestra_requerida'] ?? '') ?>"
                                     data-contenedor="<?= h($estItem['contenedor'] ?? '') ?>"
                                     data-pruebas="<?= h($estItem['pruebas_incluidas'] ?? '') ?>"
                                     data-preparacion="<?= h($estItem['preparacion'] ?? '') ?>">
                                    <span class="precio-cat-nombre"><?= h($estItem['nombre'] ?? '') ?></span>
                                    <?php if (!empty($estItem['tiempo_procesamiento'])): ?>
                                    <span class="precio-cat-meta"><?= h($estItem['tiempo_procesamiento']) ?></span>
                                    <?php endif; ?>
                                </div>
                                <?php endforeach; ?>
                            </div>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
                <?php endforeach; ?>
            </div><!-- /section-catalog -->
        </section>
