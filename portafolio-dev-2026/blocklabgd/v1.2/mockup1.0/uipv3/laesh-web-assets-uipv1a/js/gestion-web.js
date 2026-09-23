/* Interceptor global de promesas no capturadas de extensiones de navegador (Chrome/Edge/Brave) */
window.addEventListener('unhandledrejection', function(event) {
    if (event && event.reason) {
        var msg = (event.reason.message || event.reason.toString() || '');
        if (msg.includes('Could not establish connection') || msg.includes('Receiving end does not exist')) {
            event.preventDefault();
        }
    }
});

/* gestion-web.js — lógica del portal de gestión web CMS (extraído de gestion-web.html) */
        const panelLabelsGestion = {
            'hero': '1. Banner Principal',
            'quienes-somos': '2. Quiénes somos',
            'especialidades': '3. Estudios',
            'promociones': '4. Promociones Vigentes',
            'calidad': '5. Calidad e Instalaciones',
            'ubicacion': '6. Ubicación y Contacto',
            'footer': '7. Pie de Página',
            'aviso-privacidad': '8. Aviso de Privacidad',
            'video-promo': '9. Video promo',
            'configuracion-general': '10. Ordenamiento',
            'seo': '11. Metadatos'
        };

        function showPanel(name) {
            document.querySelectorAll('.cms-panel').forEach(p => p.classList.remove('active'));
            const targetPanel = document.getElementById('panel-' + name);
            if (targetPanel) targetPanel.classList.add('active');

            // Sincronizar pestaña superior activa + ARIA (A-01)
            document.querySelectorAll('.cms-tab').forEach(function(t) {
                t.classList.remove('active');
                t.setAttribute('aria-selected', 'false');
                t.setAttribute('tabindex', '-1');
            });
            const targetTab = document.getElementById('tab-' + name);
            if (targetTab) {
                targetTab.classList.add('active');
                targetTab.setAttribute('aria-selected', 'true');
                targetTab.setAttribute('tabindex', '0');
            }

            // Actualizar breadcrumb
            const bc = document.getElementById('header-bc-current');
            if (bc && panelLabelsGestion[name]) bc.textContent = panelLabelsGestion[name];
        }

        function activateTab(el) {
            document.querySelectorAll('.cms-tab').forEach(function(t) {
                t.classList.remove('active');
                t.setAttribute('aria-selected', 'false');
                t.setAttribute('tabindex', '-1');
            });
            el.classList.add('active');
            el.setAttribute('aria-selected', 'true');
            el.setAttribute('tabindex', '0');
        }

        function activateNav(el) {
            document.querySelectorAll('.sidebar .nav-item').forEach(n => n.classList.remove('active'));
            el.classList.add('active');
        }

        
        // ── Seguimiento de cambios por pestaña (module scope — usado por publishCmsSection) ──
        /** Selector de todos los campos rastreables (con name, no file). */
        const TRACK_SELECTOR = 'input[name]:not([type="file"]), textarea[name], select[name]';

        /** Inicializa data-original en todos los campos de todos los paneles. */
        function initChangeTracking() {
            if (window.CmsDirtyTracker) {
                window.CmsDirtyTracker.init([
                    'panel-hero',
                    'panel-quienes-somos',
                    'panel-especialidades',
                    'panel-promociones',
                    'panel-calidad',
                    'panel-ubicacion',
                    'panel-footer',
                    'panel-seo',
                    'panel-aviso-privacidad'
                ], { enableDraft: false });
                return;
            }
            document.querySelectorAll('.cms-panel').forEach(function(panel) {
                panel.querySelectorAll(TRACK_SELECTOR).forEach(function(el) {
                    el.dataset.original = el.value;
                });
            });
        }

        /** Cuenta campos modificados en un panel. */
        function countPanelChanges(panelEl) {
            var n = 0;
            panelEl.querySelectorAll(TRACK_SELECTOR).forEach(function(el) {
                var orig = el.dataset.original !== undefined ? el.dataset.original : '';
                var current;
                if (el.type === 'checkbox' || el.type === 'radio') {
                    current = el.checked ? '1' : '0';
                } else {
                    current = el.value !== undefined ? el.value : '';
                }
                if (current !== orig) n++;
            });
            return n;
        }

        /** Actualiza (o borra) el badge rojo de la pestaña correspondiente. */
        function updateTabBadge(section, count) {
            var tab = document.getElementById('tab-' + section);
            if (!tab) return;
            var badge = tab.querySelector('.tab-change-badge');
            if (count === 0) {
                if (badge) badge.remove();
                return;
            }
            if (!badge) {
                badge = document.createElement('span');
                badge.className = 'tab-change-badge';
                tab.appendChild(badge);
            }
            badge.textContent = count;
        }

        /** Recalcula y muestra el badge del panel que contiene el campo editado. */
        function onFieldChange(el) {
            if (window.CmsDirtyTracker) {
                window.CmsDirtyTracker.evalField(el);
                return;
            }
            var panel = el.closest('.cms-panel');
            if (!panel) return;
            var section = panel.getAttribute('data-section') || panel.id.replace('panel-', '');
            updateTabBadge(section, countPanelChanges(panel));
        }

        /** Resetea data-original tras publicar exitosamente y borra el badge. */
        function resetChangeTracking(panelEl, section) {
            if (window.CmsDirtyTracker) {
                window.CmsDirtyTracker.resetPanel(panelEl, section);
                return;
            }
            panelEl.querySelectorAll(TRACK_SELECTOR).forEach(function(el) {
                el.dataset.original = el.value;
            });
            updateTabBadge(section, 0);
        }

        /**
         * publishCmsSection — POST al backend /laesh/adrc/cms/save
         *
         * Lee el panel activo (.cms-panel.active), recopila todos los campos
         * con atributo name (formato subseccion__clave), añade csrf_token y
         * seccion, y hace fetch() al endpoint declarado en el botón publicar.
         *
         * En éxito muestra el toast verde; en error muestra toast rojo + log.
         */
        /** Sincroniza las instancias activas de CKEditor 5 con sus textareas ocultas antes de evaluar o publicar. */
        function syncCkeditors(panel) {
            if (!panel) return;
            panel.querySelectorAll('textarea.ck5-hidden-data').forEach(function(ta) {
                var mountId  = ta.id.replace('-data', '');
                var camelKey = '_' + mountId.replace(/-([a-z0-9])/g, function(g) { return g[1].toUpperCase(); });
                var legacyKey= 'ck_' + mountId.replace(/-/g, '_');

                var ed = (window._ckState && (window._ckState[camelKey] || window._ckState[legacyKey])) || window[camelKey] || window[legacyKey];
                if (ed && typeof ed.getData === 'function') {
                    ta.value = ed.getData();
                }
            });
        }

        /** Publica la sección activa del CMS mediante POST a /cms/save. */
        function publishCmsSection() {
            var btn       = document.getElementById('btn-cms-save-action');
            var panel     = document.querySelector('.cms-panel.active');
            var toast     = document.getElementById('toast');

            if (!btn || !panel) return;

            // Sincronizar editores CKEditor antes de contar cambios o serializar
            syncCkeditors(panel);

            var csrf     = btn.getAttribute('data-csrf') || '';
            var endpoint = btn.getAttribute('data-endpoint') || '/laesh/adrc/cms/save';
            var seccion  = panel.getAttribute('data-section') || panel.id.replace('panel-', '');

            // Confirmación con conteo de cambios pendientes
            var nCambios = countPanelChanges(panel);
            var labelSec = panelLabelsGestion[seccion] || seccion;
            if (nCambios === 0) {
                alert('Sin cambios en «' + labelSec + '» — no hay nada que publicar.');
                return;
            }
            var msgConfirm = '¿Publicar ' + nCambios + ' cambio' + (nCambios !== 1 ? 's' : '') + ' en «' + labelSec + '»?\nEsta acción actualizará el sitio en producción.';
            if (!window.confirm(msgConfirm)) return;

            // Recopilar todos los inputs/textareas con name dentro del panel activo
            var params = new URLSearchParams();
            params.set('csrf_token', csrf);
            params.set('seccion', seccion);

            panel.querySelectorAll('input[name], textarea[name], select[name]').forEach(function(el) {
                if (el.type === 'file' || el.disabled) return;
                if ((el.type === 'checkbox' || el.type === 'radio') && !el.checked) return;

                if (el.name.endsWith('[]')) {
                    params.append(el.name, el.value || '');
                } else {
                    params.set(el.name, el.value || '');
                }
            });

            // Feedback visual: deshabilitar botón durante el envío
            btn.disabled = true;
            var originalHtml = btn.innerHTML;
            btn.innerHTML = '<span style="display:inline-block;width:12px;height:12px;border:2px solid currentColor;border-right-color:transparent;border-radius:50%;animation:spin 0.7s linear infinite;vertical-align:middle;margin-right:6px;"></span>Publicando…';

            fetch(endpoint, {
                method:      'POST',
                credentials: 'same-origin',
                headers:     { 'Content-Type': 'application/x-www-form-urlencoded' },
                body:        params.toString()
            })
            .then(function(resp) { return resp.json(); })
            .then(function(data) {
                btn.disabled = false;
                btn.innerHTML = originalHtml;

                if (data.ok) {
                    // Actualizar data-csrf y todos los inputs csrf_token en el DOM con el token rotado
                    if (data.csrf_token) {
                        btn.setAttribute('data-csrf', data.csrf_token);
                        if (typeof window.refreshCsrf === 'function') {
                            window.refreshCsrf(data.csrf_token);
                        }
                    }
                    // Resetear tracking: publicado = nuevo original, badge desaparece
                    resetChangeTracking(panel, seccion);
                    // Toast éxito
                    if (toast) {
                        toast.textContent = data.msg || '¡Cambios publicados exitosamente!';
                        toast.classList.remove('toast--error');
                        toast.classList.add('show');
                        setTimeout(function() { toast.classList.remove('show'); }, 3500);
                    }
                } else {
                    if (toast) {
                        toast.textContent = data.msg || 'Error al publicar. Intenta de nuevo.';
                        toast.classList.add('toast--error', 'show');
                        setTimeout(function() { toast.classList.remove('show', 'toast--error'); }, 4000);
                    }
                    console.warn('[LAESH CMS] Error publicando sección:', data.msg);
                }
            })
            .catch(function(err) {
                btn.disabled = false;
                btn.innerHTML = originalHtml;
                if (toast) {
                    toast.textContent = 'Error de conexión. Verifica tu red e intenta de nuevo.';
                    toast.classList.add('toast--error', 'show');
                    setTimeout(function() { toast.classList.remove('show', 'toast--error'); }, 4000);
                }
                console.error('[LAESH CMS] Fetch error:', err);
            });
        }

        function simulateSave() {
            // Mantenido como alias por compatibilidad — delega a publishCmsSection
            publishCmsSection();
        }

        /**
         * previewCmsSection — Vista previa sin publicar (borrador de sesión)
         *
         * Serializa los campos del panel activo y hace POST a /cms/preview-draft.
         * El backend almacena los datos en $_SESSION['cms_draft'][seccion].
         * Si la respuesta es ok, abre /laesh/?_preview=1#{anchor} en pestaña nueva.
         * La producción (visitantes públicos) no es afectada en ningún momento.
         */
        function previewCmsSection() {
            var panel  = document.querySelector('.cms-panel.active');
            var toast  = document.getElementById('toast');

            // Derivar sección desde data-section del panel o desde su id (igual que publishCmsSection)
            var seccion = panel
                ? (panel.getAttribute('data-section') || panel.id.replace('panel-', ''))
                : '';
            if (!seccion || !panel) return;

            // Sincronizar editores CKEditor antes de serializar
            syncCkeditors(panel);

            // Abrir pestaña en blanco de forma síncrona durante el evento de clic para evitar el bloqueo de emergentes (popup blocker)
            var previewWin = null;
            try {
                previewWin = window.open('about:blank', '_blank');
            } catch (e) {
                console.warn('[LAESH CMS] No se pudo abrir ventana preliminar:', e);
            }

            var savBtn = document.getElementById('btn-cms-save-action');
            var csrf   = savBtn ? savBtn.getAttribute('data-csrf') : '';

            // Recopilar campos del panel activo (igual que publishCmsSection)
            var params = new URLSearchParams();
            params.set('csrf_token', csrf);
            params.set('seccion', seccion);
            panel.querySelectorAll('input[name], textarea[name], select[name]').forEach(function(el) {
                if (el.type === 'file' || el.disabled) return;
                if ((el.type === 'checkbox' || el.type === 'radio') && !el.checked) return;

                if (el.name.endsWith('[]')) {
                    params.append(el.name, el.value || '');
                } else {
                    params.set(el.name, el.value || '');
                }
            });

            // Estado visual del botón mientras se envía
            var previewBtns = document.querySelectorAll('.btn-cms-preview');
            previewBtns.forEach(function(b) { b.disabled = true; b.textContent = '⏳ Preparando…'; });

            fetch('/laesh/adrc/cms/preview-draft', {
                method:      'POST',
                credentials: 'same-origin',
                headers:     { 'Content-Type': 'application/x-www-form-urlencoded' },
                body:        params.toString()
            })
            .then(function(resp) { return resp.json(); })
            .then(function(data) {
                previewBtns.forEach(function(b) { b.disabled = false; b.textContent = '👁 Vista previa'; });
                if (data.ok && data.url) {
                    if (previewWin && !previewWin.closed) {
                        previewWin.location.href = data.url;
                    } else {
                        window.open(data.url, '_blank', 'noopener');
                    }
                } else {
                    if (previewWin && !previewWin.closed) previewWin.close();
                    if (toast) {
                        toast.textContent = data.msg || 'No se pudo abrir la vista previa.';
                        toast.classList.add('toast--error', 'show');
                        setTimeout(function() { toast.classList.remove('show', 'toast--error'); }, 4000);
                    }
                }
            })
            .catch(function(err) {
                if (previewWin && !previewWin.closed) previewWin.close();
                previewBtns.forEach(function(b) { b.disabled = false; b.textContent = '👁 Vista previa'; });
                console.error('[LAESH CMS] preview-draft error:', err);
                if (toast) {
                    toast.textContent = 'Error de conexión al preparar la vista previa.';
                    toast.classList.add('toast--error', 'show');
                    setTimeout(function() { toast.classList.remove('show', 'toast--error'); }, 4000);
                }
            });
        }


/* ── P-LAESH-01 Phase3: event listeners (reemplaza onclick=/onchange= del HTML) ── */
document.addEventListener('DOMContentLoaded', function() {
    // Inyectar por defecto valor actual en duro (5 segundos) si no viene poblado
    var inputHeroTrans = document.getElementById('input-hero-transition');
    if (inputHeroTrans) {
        if (!inputHeroTrans.value) inputHeroTrans.value = "5";
        inputHeroTrans.addEventListener('keydown', function(e) {
            var allowed = ['0','1','2','3','4','5','6','7','8','9','Backspace','Tab','ArrowLeft','ArrowRight','Delete','Home','End'];
            if (e.ctrlKey || e.metaKey) return;
            if (!allowed.includes(e.key)) {
                e.preventDefault();
            }
        });
        inputHeroTrans.addEventListener('paste', function(e) {
            var text = (e.clipboardData || window.clipboardData).getData('text');
            if (!/^\d+$/.test(text)) {
                e.preventDefault();
            }
        });
        inputHeroTrans.addEventListener('input', function() {
            this.value = this.value.replace(/[^0-9]/g, '').slice(0, 3);
        });
    }

    // Sidebar nav items con data-section → showPanel + activateNav
    document.querySelectorAll('.sidebar .nav-item[data-section]').forEach(function(item) {
        item.addEventListener('click', function() {
            showPanel(this.getAttribute('data-section'));
            activateNav(this);
        });
        // A-01: activación por teclado para role="button" (Enter / Espacio)
        item.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                this.click();
            }
        });
    });

    // Tabs superiores con data-section → showPanel + activateTab
    document.querySelectorAll('.cms-tab[data-section]').forEach(function(tab) {
        tab.addEventListener('click', function() {
            showPanel(this.getAttribute('data-section'));
            activateTab(this);
        });
    });

    // Botón guardar/publicar
    var btnSave = document.getElementById('btn-cms-save-action');
    if (btnSave) btnSave.addEventListener('click', simulateSave);

    // Botón Vista Previa en la barra de tabs (único, sticky)
    var btnPreviewTab = document.getElementById('btn-preview-tabbar');
    if (btnPreviewTab) btnPreviewTab.addEventListener('click', previewCmsSection);

    // Registrar evento en todos los campos (input + change para selects)
    document.querySelectorAll('.cms-panel ' + TRACK_SELECTOR).forEach(function(el) {
        el.addEventListener('input',  function() { onFieldChange(this); });
        el.addEventListener('change', function() { onFieldChange(this); });
    });

    // Inicializar valores originales (después de que initCurrentValueLabels() ya corrió)
    initChangeTracking();

    // Piso mínimo absoluto: solo para campos vacíos (evita maxlength=0 o 1).
    // La regla real es: valor_actual.length + 2.
    const CHAR_FLOOR = { text: 4, tel: 4, url: 10, email: 10, textarea: 8 };

    // Contador universal de caracteres en tiempo real (esquina superior derecha del label)
    function updateCharCounter(el) {
        if (!el) return;

        // Campos marcados data-no-limit: sin contador ni restricción de maxlength.
        if (el.hasAttribute('data-no-limit')) return;

        // Si ya tiene data-max o maxlength explícito, respetarlo.
        // Si no, calcular valor_actual.length + 2 (con piso mínimo) y escribirlo.
        let max;
        const explicit = el.getAttribute('data-max') || el.getAttribute('maxlength');
        if (explicit) {
            max = parseInt(explicit, 10);
        } else {
            const tag   = el.tagName.toLowerCase();
            const type  = tag === 'textarea' ? 'textarea' : (el.getAttribute('type') || 'text');
            const floor = CHAR_FLOOR[type] || 4;
            max = Math.max((el.value ? el.value.length : 0) + 15, floor);
            el.setAttribute('maxlength', max);   // ← el navegador bloquea a partir de aquí
        }

        const len = el.value ? el.value.length : 0;

        // Buscar el label propio hermano anterior, o la etiqueta label dentro del field-group contenedor directo
        let label = el.previousElementSibling;
        while (label && label.tagName.toLowerCase() !== 'label') {
            label = label.previousElementSibling;
        }
        if (!label) {
            const fg = el.closest('.field-group');
            if (fg) label = fg.querySelector('label');
        }
        if (!label) return;

        let counter = label.querySelector('.char-counter');
        if (!counter) {
            counter = document.createElement('span');
            counter.className = 'char-counter';
            label.appendChild(counter);
        }

        counter.textContent = len + ' / ' + max + ' char';
        counter.classList.remove('ok', 'warn', 'limit');
        const ratio = len / max;
        if (ratio > 1) {
            counter.classList.add('limit');
        } else if (ratio >= 0.85) {
            counter.classList.add('warn');
        } else if (len > 0) {
            counter.classList.add('ok');
        }
    }

    const CHAR_SELECTOR = 'input[type="text"], input[type="tel"], input[type="url"], input[type="email"], textarea';

    function refreshAllCharCounters() {
        document.querySelectorAll(CHAR_SELECTOR).forEach(function(input) {
            if (input.type === 'hidden' || input.type === 'file' || input.id === 'login-redirect-target') return;
            updateCharCounter(input);
        });
    }

    document.querySelectorAll(CHAR_SELECTOR).forEach(function(input) {
        if (input.type === 'hidden' || input.type === 'file') return;
        input.addEventListener('input', function() { updateCharCounter(this); });
        input.addEventListener('change', function() { updateCharCounter(this); });
    });

    // ── Valor publicado actual como pista bajo cada label ──────────────────────
    // Lee el value inicial de cada campo (= valor en BD) y muestra una pista
    // "Publicado: «…»" entre el label y el control, para referencia al editar.
    function initCurrentValueLabels() {
        document.querySelectorAll(CHAR_SELECTOR).forEach(function(el) {
            if (el.type === 'hidden' || el.type === 'file') return;
            if (el.hasAttribute('data-no-limit')) return; // URL/Ancla CTA: sin pista
            if (el.id === 'login-redirect-target') return;

            var fg = el.closest('.field-group');
            var label = fg ? fg.querySelector('label') : null;
            if (!label) return;

            var current = (el.value || '').trim();

            var hint = document.createElement('span');
            hint.className = 'cms-field-published';

            if (!current) {
                hint.textContent = 'Publicado: (vacío)';
                hint.classList.add('cms-field-published--empty');
            } else if (el.tagName.toLowerCase() === 'textarea') {
                hint.textContent = 'Publicado: ' + current.length + ' car.';
                hint.title = current;
            } else {
                var display = current.length > 40 ? current.substring(0, 40) + '…' : current;
                hint.textContent = 'Publicado: «' + display + '»';
                hint.title = current;
            }

            // Insertar entre el label y el control
            label.insertAdjacentElement('afterend', hint);
        });
    }

    // Actualizar contadores al inicio y al cambiar de slide o ficha
    setTimeout(refreshAllCharCounters, 100);
    initCurrentValueLabels();

    // Lógica reactiva para enterarse de notificaciones de recepción (labadmin)
    let lastRemitidosCMS = 0;
    function refreshNotificacionesCMS() {
        fetch('/laesh/admrc/api/notificaciones')
            .then(res => res.json())
            .then(data => {
                if (data && data.success) {
                    const count = data.emitidas || 0;
                    const badge = document.getElementById('badge-notif-cms');

                    if (badge) {
                        badge.innerText = count;
                        if (count > 0) {
                            badge.classList.add('show');
                            if (count > lastRemitidosCMS) {
                                badge.classList.add('pulse');
                                if (typeof playWhistle === 'function') {
                                    playWhistle();
                                }
                                setTimeout(() => badge.classList.remove('pulse'), 3000);
                            }
                            document.title = `(${count}) Gestión Web - LAESH`;
                        } else {
                            badge.classList.remove('show');
                            badge.classList.remove('pulse');
                            document.title = "Gestión Web - LAESH";
                        }
                    }
                    lastRemitidosCMS = count;
                }
            })
            .catch(() => {});
    }

    // Inicializar y escuchar cambios de LocalStorage
    refreshNotificacionesCMS();
    setInterval(refreshNotificacionesCMS, 4000);
    window.addEventListener('storage', refreshNotificacionesCMS);

    // ── Drag-and-drop: Panel Orden de Secciones ───────────────────────────────
    // Inicializa el reordenamiento HTML5 nativo en el panel configuracion-general.
    // Solo se activa cuando el elemento #seccion-order-list existe en el DOM.
    (function initSectionOrderDnD() {
        var list = document.getElementById('seccion-order-list');
        var hiddenInput = document.getElementById('seccion-order-input');
        if (!list || !hiddenInput) return;

        function serializeOrder() {
            var ids = Array.from(list.querySelectorAll('[data-seccion-id]'))
                          .map(function(el) { return el.getAttribute('data-seccion-id'); });
            hiddenInput.value = ids.join(',');
        }

        var draggingEl = null;

        list.addEventListener('dragstart', function(e) {
            draggingEl = e.target.closest('[data-seccion-id]');
            if (!draggingEl) return;
            draggingEl.classList.add('dnd-dragging');
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', draggingEl.getAttribute('data-seccion-id'));
        });

        list.addEventListener('dragend', function() {
            if (draggingEl) {
                draggingEl.classList.remove('dnd-dragging');
                draggingEl = null;
            }
            list.querySelectorAll('.dnd-over').forEach(function(el) {
                el.classList.remove('dnd-over');
            });
            serializeOrder();
            if (window.CmsDirtyTracker && typeof window.CmsDirtyTracker.evalField === 'function') {
                window.CmsDirtyTracker.evalField(hiddenInput);
            }
        });

        // Trigger evalField al cambiar los radio buttons de encendido/apagado
        list.querySelectorAll('.sec-toggle-radio').forEach(function(radio) {
            radio.addEventListener('change', function() {
                if (window.CmsDirtyTracker && typeof window.CmsDirtyTracker.evalField === 'function') {
                    window.CmsDirtyTracker.evalField(radio);
                }
            });
        });

        list.addEventListener('dragover', function(e) {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
            var target = e.target.closest('[data-seccion-id]');
            if (!target || target === draggingEl) return;
            list.querySelectorAll('.dnd-over').forEach(function(el) { el.classList.remove('dnd-over'); });
            target.classList.add('dnd-over');
            var rect = target.getBoundingClientRect();
            var midY = rect.top + rect.height / 2;
            if (e.clientY < midY) {
                list.insertBefore(draggingEl, target);
            } else {
                list.insertBefore(draggingEl, target.nextSibling);
            }
        });

        list.addEventListener('dragleave', function(e) {
            var target = e.target.closest('[data-seccion-id]');
            if (target) target.classList.remove('dnd-over');
        });

        list.addEventListener('drop', function(e) {
            e.preventDefault();
        });

        // Inicializar el valor del hidden input desde el orden actual del DOM
        serializeOrder();

        // Actualizar el display de texto cada vez que se serializa
        function updateDisplay() {
            serializeOrder();
            var display = document.getElementById('seccion-order-display');
            if (display) display.textContent = hiddenInput.value || '(predeterminado)';
        }
        list.addEventListener('dragend', updateDisplay, true);
    })();
});
