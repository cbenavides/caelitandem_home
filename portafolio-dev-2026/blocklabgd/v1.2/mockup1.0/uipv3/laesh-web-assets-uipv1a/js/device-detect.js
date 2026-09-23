/**
 * device-detect.js — LAESH Device/Browser/OS Detection
 * -------------------------------------------------------
 * Corre SÍNCRONO en <head> antes de los <link> CSS para que los
 * atributos data-* estén presentes en la primera evaluación de CSS.
 *
 * Estampa en <html>:
 *   data-os       = "ios" | "android" | "desktop"
 *   data-browser  = "safari" | "chrome" | "firefox" | "edge" | "other"
 *   data-input    = "touch" | "mouse"
 *   data-dpr      = "1" | "2" | "3"      (Device Pixel Ratio redondeado)
 *
 * Uso en CSS (targeting.css):
 *   :root[data-os="ios"]      .clase { ... }
 *   :root[data-browser="safari"] input { ... }
 *   :root[data-input="touch"] .btn  { min-height: 44px; }
 *
 * NO modifica clases — solo data-attributes para máxima especificidad
 * y sin conflictos con el sistema de clases existente.
 */
(function () {
    try {
        var html = document.documentElement;
        if (!html) return;
        var ua   = navigator.userAgent || '';

        /* ── OS (incluye detección iPadOS 13+) ──────────────────────── */
        var isIPadOS = (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
        if (/iP(hone|od|ad)/.test(ua) || isIPadOS) {
            html.dataset.os = 'ios';
        } else if (/Android/.test(ua)) {
            html.dataset.os = 'android';
        } else {
            html.dataset.os = 'desktop';
        }

        /* ── BROWSER ─────────────────────────────────────────────────
           Orden importante: Edge contiene "Chrome", Chrome contiene
           "Safari" → evaluar de más específico a más genérico.          */
        if (/Edg\//.test(ua)) {
            html.dataset.browser = 'edge';
        } else if (/OPR\/|Opera/.test(ua)) {
            html.dataset.browser = 'opera';
        } else if (/Chrome\//.test(ua) && !/Chromium\//.test(ua)) {
            html.dataset.browser = 'chrome';
        } else if (/Firefox\//.test(ua)) {
            html.dataset.browser = 'firefox';
        } else if (/Safari\//.test(ua)) {
            /* Safari puro: incluye Mobile Safari en iOS              */
            html.dataset.browser = 'safari';
        } else {
            html.dataset.browser = 'other';
        }

        /* ── INPUT TYPE ─────────────────────────────────────────────── */
        if ('ontouchstart' in window || (navigator.maxTouchPoints && navigator.maxTouchPoints > 0)) {
            html.dataset.input = 'touch';
        } else {
            html.dataset.input = 'mouse';
        }

        /* ── DEVICE PIXEL RATIO ─────────────────────────────────────── */
        var dpr = window.devicePixelRatio || 1;
        html.dataset.dpr = dpr >= 2.5 ? '3' : dpr >= 1.5 ? '2' : '1';
    } catch (e) {
        /* Hardening: Silencio defensivo en entornos restringidos / legados sin soporte dataset */
    }
})();
