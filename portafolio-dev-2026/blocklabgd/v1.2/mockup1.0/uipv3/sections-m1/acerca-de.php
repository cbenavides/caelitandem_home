<?php
/**
 * sections-m1/acerca-de.php — Partial Mejorado: Quiénes somos
 * Incluido desde website/index-m1.php; hereda su scope completo.
 * Variables esperadas: $qsH2, $qsSub, $qsConfianzaHtml, $qsMision, $qsVision, $qsHistoriaHtml
 */
?>
        <!-- ══════════════════════════════════════ QUIÉNES SOMOS (M1) ══ -->
        <section id="acerca-de" class="sec-pad-1-5 scroll-sm-top">
            <div class="section-header animate-on-scroll">
                <h2><?= h($qsH2) ?></h2>
                <p><?= $qsSub ?></p>
            </div>

            <div class="grid-layout grid-1-1-auto grid-acerca-cards">
                <!-- Ficha 1: 25 años / Confianza -->
                <div class="card-premium card-triad animate-on-scroll delay-100 info-col">
                    <div class="card-triad-badge">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                        <span>Trayectoria</span>
                    </div>
                    <div class="acerca-flex ck5-output">
                        <?= safeHtml($qsConfianzaHtml) ?>
                    </div>
                </div>

                <!-- Ficha 2: Misión -->
                <div class="card-premium card-triad animate-on-scroll delay-200 info-col">
                    <div class="card-triad-badge">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg>
                        <span>Misión</span>
                    </div>
                    <div class="acerca-flex ck5-output">
                        <?= safeHtml($qsMision) ?>
                    </div>
                </div>

                <!-- Ficha 3: Visión -->
                <div class="card-premium card-triad animate-on-scroll delay-300 info-col">
                    <div class="card-triad-badge">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                        <span>Visión</span>
                    </div>
                    <div class="acerca-flex ck5-output">
                        <?= safeHtml($qsVision) ?>
                    </div>
                </div>
            </div>

            <!-- Ficha ancha: Historia Institucional (Formato Editorial Médico) -->
            <div class="grid-single-history">
                <div class="card-premium card-history-editorial animate-on-scroll delay-100 info-col--stretch">
                    <div class="history-content-wrap">
                        <div class="history-header-accent">
                            <span class="history-icon-circle">
                                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                            </span>
                            <div>
                                <h3 class="history-title">Nuestra Historia y Compromiso con la Salud</h3>
                                <p class="history-subtitle">Evolución continua, rigor analítico y servicio humano en la región Mixteca</p>
                            </div>
                        </div>
                        <div class="faq-p--sm2 ck5-output history-body-text">
                            <?= safeHtml($qsHistoriaHtml) ?>
                        </div>
                    </div>
                </div>
            </div>
        </section>
