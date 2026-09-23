(function () {
    'use strict';

    // El endpoint de subida dinámico se pasa a través de una etiqueta <meta> para evitar bloqueos por CSP.
    const metaUpload = document.querySelector('meta[name="cms-upload-url"]');
    const UPLOAD_ENDPOINT = metaUpload ? metaUpload.content : '/laesh/adrc/cms/upload';

    /** Devuelve el CSRF token vigente (<meta> o data-csrf del botón). */
    function getCsrf() {
        const meta = document.querySelector('meta[name="csrf-token"]');
        if (meta && meta.content) return meta.content;
        return document.getElementById('btn-cms-save-action')?.dataset?.csrf ?? '';
    }

    /** Actualiza el CSRF token tras cada rotación en el servidor (global para CMS y upload). */
    function refreshCsrf(newToken) {
        if (!newToken) return;
        const meta = document.querySelector('meta[name="csrf-token"]');
        if (meta) meta.content = newToken;
        const btn = document.getElementById('btn-cms-save-action');
        if (btn) {
            btn.dataset.csrf = newToken;
            btn.setAttribute('data-csrf', newToken);
        }
        document.querySelectorAll('input[name="csrf_token"]').forEach(el => el.value = newToken);
    }
    window.refreshCsrf = refreshCsrf;

    let toastTimer = null;

    /** Muestra el toast CMS. Los errores (isError=true) NUNCA se cierran solos; requieren clic en la '✖'. */
    function showToast(msg, isError) {
        const toast = document.getElementById('toast');
        if (!toast) return;

        if (toastTimer) { clearTimeout(toastTimer); toastTimer = null; }

        const iconSvg = isError
            ? '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="flex-shrink:0"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>'
            : '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="flex-shrink:0"><polyline points="20 6 9 17 4 12"></polyline></svg>';

        toast.innerHTML = `<div style="display:flex;align-items:center;gap:8px;flex:1">${iconSvg}<span>${msg}</span></div>
            <button type="button" class="cms-toast-close" id="btn-toast-close" title="Cerrar notificación">✖</button>`;

        toast.classList.toggle('toast--error', !!isError);
        toast.classList.add('visible');

        // Botón de cierre manual
        const closeBtn = document.getElementById('btn-toast-close');
        if (closeBtn) {
            closeBtn.onclick = function (e) {
                e.stopPropagation();
                if (toastTimer) { clearTimeout(toastTimer); toastTimer = null; }
                toast.classList.remove('visible');
            };
        }

        // Si NO es error, auto-ocultar tras 4 segundos. Si ES ERROR, PERMANECE ABIERTO INDEFINIDAMENTE.
        if (!isError) {
            toastTimer = setTimeout(() => {
                toast.classList.remove('visible');
            }, 4000);
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        document.querySelectorAll('input[type="file"][data-upload-slot]').forEach(function (input) {
            input.addEventListener('change', async function () {
                if (!this.files[0]) return;

                const slot        = this.dataset.uploadSlot   || 'cms';
                const previewId   = this.dataset.previewId    || null;
                const targetInput = this.dataset.targetInput  || null;
                const file        = this.files[0];

                // ── Validación de formato — solo WebP para todos los slots ────────────
                if (file.type !== 'image/webp') {
                    showToast(
                        `Formato no permitido (${file.type || 'desconocido'}). Solo se acepta <strong>WebP</strong>.<br>` +
                        'Usa Squoosh → Format: WebP antes de subir.',
                        true
                    );
                    this.value = '';
                    return;
                }

                // ── Reglas por slot (alineadas con Guía CMS §5.1–§5.6) ──────────────
                // Slots reales (data-upload-slot en gestion_web.php):
                //   hero-{slide1…5}       → Banner Hero
                //   carousel-{1…16}       → Carrusel Especialidades
                //   ubicacion-croquis     → Croquis de Ubicación
                //   promo-{lun…dom}       → Cards de Promociones
                //   calidad-gallery{1…3}  → Galería de Calidad
                //   (default)             → Imagen CMS genérica
                function slotRules(s) {
                    if (/^hero-/.test(s))              return { maxKb: 150, minW: 1280, maxW: 1920,                              landscape: true, label: 'Banner Hero',             hint: 'WebP · Quality 72–80 · Effort 6 · 1 280–1 920 px ancho · Orientación Horizontal · alto proporcional · máx. 150 KB, óptimo 60 KB' };
                    if (/^carousel-/.test(s))          return { maxKb: 150, exactW: 800, exactH: 580,                                        label: 'Carrusel Especialidades', hint: 'WebP · Quality 75 · Effort 6 · exacto 800×580 px · máx. 150 KB, óptimo 60 KB' };
                    if (/^ubicacion-croquis$/.test(s)) return { maxKb: 150, maxW: 756, maxH: 577, landscape: true,      label: 'Croquis de Ubicación',    hint: 'WebP · Quality 85 · Effort 6 · 756 × 577 px (máx) · Orientación Horizontal · máx. 150 KB, óptimo 60 KB' };
                    if (/^promo-/.test(s))             return { maxKb: 150, exactW: 1200, minH: 600, maxH: 675,                              label: 'Card de Promociones',     hint: 'WebP · Quality 72 · Effort 6 · exacto 1200 px ancho · alto 600–675 px · máx. 150 KB, óptimo 60 KB' };
                    if (/^calidad-/.test(s))           return { maxKb: 150, exactW: 800, exactH: 580,                                       label: 'Galería de Calidad',      hint: 'WebP · Quality 75 · Effort 6 · exacto 800×580 px · máx. 150 KB, óptimo 60 KB' };
                    if (/^seo-og$/.test(s))            return { maxKb: 150, minW: 1200, maxW: 1920,                              landscape: true, label: 'Imagen Open Graph (SEO)', hint: 'WebP · 1 200 × 630 px recomendado (ratio 1.91:1) · Orientación Horizontal · máx. 150 KB, óptimo 60 KB' };
                    return                                    { maxKb: 150, minW: 800,                                                        label: 'Imagen CMS',              hint: 'WebP · mín. 800 px ancho · máx. 150 KB, óptimo 60 KB' };
                }
                const rules = slotRules(slot);

                // ── Validación de tamaño ─────────────────────────────────────────────
                const sizeKb = (file.size / 1024).toFixed(1);
                if (file.size > rules.maxKb * 1024) {
                    showToast(
                        `Peso ${sizeKb} KB supera el máximo de ${rules.maxKb} KB para ${rules.label}.<br>` +
                        'Optimiza la imagen (baja Quality o reduce dimensiones).',
                        true
                    );
                    this.value = '';
                    return;
                }

                // ── Validación de dimensiones (requiere cargar la imagen) ────────────
                try {
                    const objUrl = URL.createObjectURL(file);
                    const img    = new Image();
                    await new Promise((res, rej) => { img.onload = res; img.onerror = rej; img.src = objUrl; });
                    URL.revokeObjectURL(objUrl);
                    const w = img.naturalWidth, h = img.naturalHeight;

                    // Dimensiones exactas (carrusel, croquis, promociones)
                    if (rules.exactW !== undefined && w !== rules.exactW) {
                        showToast(`Dimensiones incorrectas (${w}×${h} px) para ${rules.label}.<br><small>Requerido: ${rules.hint}</small>`, true);
                        this.value = ''; return;
                    }
                    if (rules.exactH !== undefined && h !== rules.exactH) {
                        showToast(`Dimensiones incorrectas (${w}×${h} px) para ${rules.label}.<br><small>Requerido: ${rules.hint}</small>`, true);
                        this.value = ''; return;
                    }

                    // Rango de ancho (hero, banner, default)
                    if (rules.minW !== undefined && w < rules.minW) {
                        showToast(`Ancho ${w} px menor al mínimo de ${rules.minW} px para ${rules.label}. Spec: ${rules.hint}`, true);
                        this.value = ''; return;
                    }
                    if (rules.maxW !== undefined && w > rules.maxW) {
                        showToast(`Ancho ${w} px mayor al máximo de ${rules.maxW} px para ${rules.label}. Spec: ${rules.hint}`, true);
                        this.value = ''; return;
                    }

                    // Rango de alto (hero)
                    if (rules.minH !== undefined && h < rules.minH) {
                        showToast(`Alto ${h} px menor al mínimo de ${rules.minH} px para ${rules.label}. Spec: ${rules.hint}`, true);
                        this.value = ''; return;
                    }
                    if (rules.maxH !== undefined && h > rules.maxH) {
                        showToast(`Alto ${h} px mayor al máximo de ${rules.maxH} px para ${rules.label}. Spec: ${rules.hint}`, true);
                        this.value = ''; return;
                    }

                    // Orientación horizontal obligatoria
                    if (rules.landscape && h >= w) {
                        showToast(`La imagen (${w}×${h} px) debe tener Orientación Horizontal (ancho > alto). Spec: ${rules.hint}`, true);
                        this.value = ''; return;
                    }
                } catch (e) {
                    console.error('[cms-upload] Error al verificar dimensiones:', e);
                    showToast('Error técnico al leer las dimensiones de la imagen.', true);
                    this.value = '';
                    return;
                }

                // Construir FormData
                const fd = new FormData();
                fd.append('file',       file);
                fd.append('slot',       slot);
                fd.append('csrf_token', getCsrf());

                // Indicador visual
                const box = this.closest('.image-upload-box');
                if (box) box.style.opacity = '0.5';

                try {
                    const res = await fetch(UPLOAD_ENDPOINT, { method: 'POST', body: fd });
                    const resText = await res.text();
                    let data;
                    try {
                        data = JSON.parse(resText);
                    } catch (pErr) {
                        console.error('[cms-upload] Server returned non-JSON response:', res.status, resText);
                        showToast(`Error del servidor (${res.status}): ${resText.substring(0, 160) || res.statusText}`, true);
                        this.value = '';
                        return;
                    }

                    if (res.ok && data.ok) {
                        // Actualizar preview
                        if (previewId) {
                            const img = document.getElementById(previewId);
                            if (img) {
                                img.src = data.url + '?t=' + Date.now();
                                img.style.display = '';
                            }
                        }
                        // Poblar campo de texto con la URL subida
                        if (targetInput) {
                            const inp = document.getElementById(targetInput);
                            if (inp) {
                                inp.value = data.url;
                                var lblId = 'lbl-img-' + inp.id.replace('url-img-', '');
                                var lbl = document.getElementById(lblId);
                                if (lbl) lbl.textContent = data.url.split('/').pop();
                                inp.dispatchEvent(new Event('change', { bubbles: true }));
                            }
                        }
                        // Rotar CSRF
                        refreshCsrf(data.csrf_token);
                        showToast(data.msg || '¡Imagen cargada exitosamente!', false);
                    } else {
                        console.error('[cms-upload] Server rejected upload:', res.status, data);
                        showToast(data.msg || `Error (${res.status}) al subir la imagen al servidor.`, true);
                        this.value = '';
                    }
                } catch (err) {
                    console.error('[cms-upload]', err);
                    showToast(`Error de red/conectividad: ${err.message || 'Sin respuesta del servidor.'}`, true);
                    this.value = '';
                } finally {
                    if (box) box.style.opacity = '';
                }
            });
        });
    });
}());
