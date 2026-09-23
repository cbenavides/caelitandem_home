<?php
/**
 * sections-m2/video.php — Partial: Video Institucional Local HTML5
 * Incluido dinámicamente desde website/index-m2.php según el orden y visibilidad en CMS.
 */
?>
<!-- ══════════════════════════════════════ VIDEO INSTITUCIONAL (M2) ══ -->
<section id="video" class="sec-pad-1-5 scroll-sm-top hero-video-section" role="region" aria-label="Video Institucional LAESH">
    <div class="hero-video-wrap">
        <!-- Video HTML5 local en bucle sin audio (16:9 Completo, Cero Recortes) -->
        <video id="promo-main-video" autoplay muted loop playsinline preload="auto"
               poster="/laesh-web-assets-uipv1a/video/hero-poster.webp"
               class="hero-video-element"
               aria-hidden="true">
            <source src="/laesh-web-assets-uipv1a/video/hero-laesh.webm" type="video/webm">
            <source src="/laesh-web-assets-uipv1a/video/hero-laesh.mp4" type="video/mp4">
        </video>

        <!-- Botón accesible para pausar/reanudar el video -->
        <button type="button" id="btn-toggle-promo-video" class="hero-video-toggle-btn"
                aria-label="Pausar video" aria-pressed="false" title="Pausar o reproducir video">
            <svg id="icon-promo-pause" width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>
            <svg id="icon-promo-play" width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" style="display:none;"><polygon points="5,3 19,12 5,21"/></svg>
            <span id="label-promo-toggle">Pausar video</span>
        </button>
    </div>
</section>
