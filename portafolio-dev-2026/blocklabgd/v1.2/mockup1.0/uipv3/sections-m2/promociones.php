<?php
/**
 * sections-m1/promociones.php — Partial Mejorado: Promociones diarias
 * Incluido desde website/index-m1.php; hereda su scope completo.
 * Variables esperadas: $promoH2, $promoSub, $promos, $waBase, $waTextoAg, $waSvg
 */
?>
        <!-- ══════════════════════════════════════════ PROMOCIONES (M1) ══ -->
        <section id="promociones" class="sec-promo scroll-sm-top">
            <div class="section-header animate-on-scroll">
                <h2><?= h($promoH2) ?></h2>
                <p><?= h($promoSub) ?></p>
            </div>
            <div class="promo-catalog-wrap animate-on-scroll">
                <div class="catalog-grid catalog-grid--bento">
                <?php
                // Día actual para badge "HOY" (ISO-8601: 1=lunes … 7=domingo)
                $todayMap = [1=>'lunes',2=>'martes',3=>'miercoles',4=>'jueves',5=>'viernes',6=>'sabado',7=>'domingo'];
                $todayKey = $todayMap[(int)date('N')] ?? '';

                function _normalizeDayM1(string $s): string {
                    return strtr(strtolower(trim($s)),
                        ['á'=>'a','é'=>'e','í'=>'i','ó'=>'o','ú'=>'u','ü'=>'u','ñ'=>'n']);
                }

                foreach ($promos as $p):
                    $diaRaw    = $p['dia_semana'] ?? '';
                    $diaKey    = _normalizeDayM1(strip_tags($diaRaw));
                    $diaNombre = !empty($diaRaw) ? trim($diaRaw) : 'Promoción';
                    $isHoy     = ($diaKey === $todayKey);
                    $imgUrl    = $p['imagen_fondo'] ?? '';

                    $diaPlain   = strip_tags($diaNombre);
                    $waTextFull = $waTextoAg
                        ? str_replace('{estudio}', $diaPlain, $waTextoAg)
                        : '';
                    $waCardUrl  = $waBase . ($waTextFull ? '?text=' . rawurlencode($waTextFull) : '');
                ?>
                    <div class="catalog-card catalog-card--m1 <?= $isHoy ? 'catalog-card--hoy' : '' ?>"
                         data-promo-img="<?= h($imgUrl) ?>"
                         data-promo-title="<?= h($diaPlain) ?>"
                         data-promo-title-html="<?= h($diaNombre) ?>">

                        <!-- Cabecera de la tarjeta: Día + Badge HOY -->
                        <div class="catalog-card-day-row">
                            <div class="catalog-card-day"><?= $diaNombre ?></div>
                            <?php if ($isHoy): ?>
                                <span class="catalog-badge badge-hoy-pulse">● HOY</span>
                            <?php endif; ?>
                        </div>

                        <!-- Imagen rectangular completa con cursor zoom y click para abrir modal -->
                        <?php if (!empty($imgUrl)): ?>
                            <div class="catalog-card-img-wrap catalog-card-img-wrap--clean"
                                 onclick="if(!event.target.closest('a') && typeof window.openPromoModal==='function') window.openPromoModal('<?= h($imgUrl) ?>', '<?= h($diaPlain) ?>');"
                                 title="Clic para ver imagen completa en alta resolución" role="button" tabindex="0">
                                <img src="<?= h($imgUrl) ?>" alt="<?= h($diaPlain) ?>" class="catalog-card-img" loading="lazy" decoding="async" width="400" height="200">
                                <div class="catalog-img-text-bar">
                                    <a href="<?= h($waCardUrl) ?>" target="_blank" rel="noopener noreferrer"
                                       class="catalog-img-text-action"
                                       aria-label="Agendar promoción de <?= h($diaPlain) ?> por WhatsApp"
                                       onclick="event.stopPropagation();">
                                        <?= $waSvg ?>
                                        <span>Agendar</span>
                                    </a>
                                    <div class="catalog-img-text-action catalog-img-text-action--hint" aria-hidden="true">
                                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>
                                        <span>Ver grande</span>
                                    </div>
                                </div>
                            </div>
                        <?php else: ?>
                            <div class="catalog-card-no-img-row">
                                <a href="<?= h($waCardUrl) ?>" target="_blank" rel="noopener noreferrer"
                                   class="catalog-text-link-wa"
                                   aria-label="Agendar promoción de <?= h($diaPlain) ?> por WhatsApp">
                                    <?= $waSvg ?>
                                    <span>Agendar</span>
                                </a>
                            </div>
                        <?php endif; ?>

                    </div>
                <?php endforeach; ?>
                </div>
            </div>
        </section>
