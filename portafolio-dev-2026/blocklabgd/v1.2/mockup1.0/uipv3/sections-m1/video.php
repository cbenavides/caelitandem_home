<?php
/**
 * sections-m1/video.php — Partial: Video Institucional / Promo
 * Incluido dinámicamente desde website/index-m1.php según el orden y visibilidad en CMS.
 */
$_videoHtml = $c('video-promo', 'contenido', 'cuerpo_html');
if (trim($_videoHtml) === '') {
    $_videoHtml = $c('video-promo', '', 'cuerpo_html');
}
if (trim($_videoHtml) === '') {
    $_videoHtml = '<div style="position:relative; padding-bottom:56.25%; height:0; overflow:hidden; border-radius:16px; box-shadow:0 8px 24px rgba(0,0,0,0.12);">' .
                  '<iframe style="position:absolute; top:0; left:0; width:100%; height:100%; border:0; border-radius:16px;" ' .
                  'src="https://www.youtube.com/embed/dQw4w9WgXcQ" title="Video Institucional LAESH" ' .
                  'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>' .
                  '</div>';
}
?>
<!-- ══════════════════════════════════════ VIDEO PROMO (M1) ══ -->
<section id="video" class="sec-pad-1-5 scroll-sm-top">
    <div class="grid-single-history">
        <div class="card-premium animate-on-scroll delay-100 info-col--stretch card-video-m1">
            <div class="video-container-wrap">
                <div class="faq-p--sm2 ck5-output">
                    <?= safeHtml($_videoHtml) ?>
                </div>
            </div>
        </div>
    </div>
</section>
<?php unset($_videoHtml); ?>
