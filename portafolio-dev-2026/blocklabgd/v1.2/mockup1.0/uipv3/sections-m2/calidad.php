<?php
/**
 * sections-m1/calidad.php — Partial Mejorado: Calidad / Galería
 * Incluido desde website/index-m1.php; hereda su scope completo.
 * Variables esperadas: $calH2, $calSub, $calidadCards
 */
?>
        <!-- ══════════════════════════════════════════════ CALIDAD (M1) ══ -->
        <section id="calidad" class="sec-pad-1-5 scroll-sm-top">
            <div class="section-header animate-on-scroll">
                <h2><?= h($calH2) ?></h2>
                <p><?= h($calSub) ?></p>
            </div>
            <div class="map-bar quality-grid-wrapper">
                <div class="specialties-carousel-viewport animate-on-scroll">
                    <div class="calidad-cards-grid">
                        <?php foreach ($calidadCards as $qc): ?>
                        <div class="carousel-card card-calidad-premium">
                            <div class="carousel-card__img-box">
                                <img src="<?= h($qc['img']) ?>" alt="<?= h($qc['alt']) ?>"
                                     width="800" height="580" loading="lazy" decoding="async">
                            </div>
                            <div class="carousel-card__body ck5-output">
                                <div class="calidad-badge-sub">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                                    <span>Control de Calidad</span>
                                </div>
                                <h3><?= h($qc['titulo']) ?></h3>
                                <?php if ($qc['desc']): ?><p><?= h($qc['desc']) ?></p><?php endif; ?>
                            </div>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
            </div>
        </section>
