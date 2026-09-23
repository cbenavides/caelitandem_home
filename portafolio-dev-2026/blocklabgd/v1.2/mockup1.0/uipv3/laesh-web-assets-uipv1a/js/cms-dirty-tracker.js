/**
 * cms-dirty-tracker.js — v2 — Módulo unificado de rastreo, persistencia y protección de cambios en CMS
 *
 * Responsabilidades:
 * 1. Inicializa baseline (dataset.original) para inputs, textareas, selects y CKEditor 5.
 * 2. Muestra/remueve punto rojo (.cms-field-dirty-dot) en la esquina superior izquierda del campo.
 * 3. Sincroniza el contador exacto del badge (.tab-change-badge) en la pestaña correspondiente.
 * 4. [v2] beforeunload Guard: intercepta cierre/refresh de pestaña si hay cambios sin publicar.
 * 5. [v2] Draft Auto-Save: persiste cambios en localStorage en tiempo real por panel.
 * 6. [v2] Draft Restore: al cargar la página, detecta borradores y ofrece restaurarlos.
 * 7. Resetea el estado (indicadores + draft localStorage) tras una publicación exitosa.
 */
(function(window, document) {
    'use strict';

    var TRACK_SELECTOR = 'input[name]:not([type="file"]), textarea[name], select[name]';
    var DRAFT_PREFIX   = 'cms_draft_';   // Clave en localStorage: cms_draft_{panelId}
    var DRAFT_MAX_AGE  = 7 * 86400 * 1000; // 7 días en ms — borradores más viejos se descartan
    var activePanelIds = [
        'panel-hero',
        'panel-quienes-somos',
        'panel-especialidades',
        'panel-promociones',
        'panel-calidad',
        'panel-ubicacion',
        'panel-footer',
        'panel-aviso-privacidad',
        'panel-video-promo',
        'panel-configuracion-general',
        'panel-seo'
    ];

    // Bandera global: ¿hay AL MENOS UN campo sucio en cualquier panel activo?
    var _hasDirtyFields = false;
    // Bandera de persistencia local: false = solo guard + dots/badges, sin tocar localStorage
    var _draftEnabled   = true;

    var CmsDirtyTracker = {

        // ══════════════════════════════════════════════════════════════════
        //  INIT
        // ══════════════════════════════════════════════════════════════════

        /**
         * Inicializa la supervisión en los paneles especificados o por defecto.
         * @param {string[]} panelIds   IDs de paneles a monitorear
         * @param {object}   [options]  Opciones:
         *   enableDraft {boolean} — true (default): activa Auto-Save + Restore en localStorage.
         *                           false: solo activa guard beforeunload + dots/badges (sin localStorage).
         */
        init: function(panelIds, options) {
            if (Array.isArray(panelIds)) {
                activePanelIds = panelIds;
            }
            var opts = options || {};
            _draftEnabled = (opts.enableDraft !== false); // default true; false para deshabilitar localStorage
            var self = this;

            // 1. Restaurar borradores (solo si persistencia habilitada)
            if (_draftEnabled) {
                self._restoreDraftsIfAny();
            }

            // 2. Inicializar baseline de cada panel
            activePanelIds.forEach(function(panelId) {
                var panel = document.getElementById(panelId);
                if (!panel) return;
                self.initPanelBaseline(panel);
            });

            // 3. Delegación de eventos: input/change en cualquier campo rastreable
            document.addEventListener('input', function(e) {
                if (self.shouldTrack(e.target)) self.evalField(e.target);
            });
            document.addEventListener('change', function(e) {
                if (self.shouldTrack(e.target)) self.evalField(e.target);
            });

            // 4. Instalar guard de beforeunload
            self._installBeforeUnloadGuard();
        },

        // ══════════════════════════════════════════════════════════════════
        //  TRACKING
        // ══════════════════════════════════════════════════════════════════

        /** Determina si el elemento pertenece a uno de los paneles supervisados. */
        shouldTrack: function(el) {
            if (!el || !el.name) return false;
            var panel = el.closest('.cms-panel');
            if (!panel || !panel.id) return false;
            return activePanelIds.indexOf(panel.id) !== -1;
        },

        /** Guarda el valor inicial en dataset.original para todos los campos de un panel. */
        initPanelBaseline: function(panelEl) {
            var self = this;
            panelEl.querySelectorAll(TRACK_SELECTOR).forEach(function(el) {
                if (el.dataset.original === undefined) {
                    if (el.type === 'checkbox' || el.type === 'radio') {
                        el.dataset.original = el.checked ? '1' : '0';
                    } else {
                        el.dataset.original = el.value;
                    }
                }
                self.evalField(el);
            });
        },

        /**
         * Evalúa si un campo ha cambiado respecto a su valor original.
         * Si cambió: marca el dot rojo y guarda borrador en localStorage.
         */
        evalField: function(el) {
            var original = el.dataset.original !== undefined ? el.dataset.original : '';
            var current;
            if (el.type === 'checkbox' || el.type === 'radio') {
                current = el.checked ? '1' : '0';
            } else {
                current = el.value !== undefined ? el.value : '';
            }
            var isDirty  = (current !== original);

            if (isDirty) {
                this.markField(el);
            } else {
                this.unmarkField(el);
            }

            var panel = el.closest('.cms-panel');
            if (panel) {
                this.updateBadge(panel);
                if (_draftEnabled) this._saveDraft(panel); // [v2] Persistir borrador (si habilitado)
            }

            this._syncDirtyFlag();  // [v2] Actualizar bandera global (siempre — necesario para guard)
            return isDirty;
        },

        /** Inyecta el indicador rojo (.cms-field-dirty-dot) en el contenedor del campo. */
        markField: function(el) {
            var wrapper = this.findWrapper(el);
            if (!wrapper) return;
            if (!wrapper.querySelector('.cms-field-dirty-dot')) {
                var dot = document.createElement('span');
                dot.className = 'cms-field-dirty-dot';
                dot.title = 'Campo modificado sin publicar';
                wrapper.appendChild(dot);
            }
        },

        /** Remueve el indicador rojo del contenedor del campo. */
        unmarkField: function(el) {
            var wrapper = this.findWrapper(el);
            if (!wrapper) return;
            var dot = wrapper.querySelector('.cms-field-dirty-dot');
            if (dot) dot.remove();
        },

        /** Busca el contenedor (.field-group o .image-upload-box) para anclar el punto rojo. */
        findWrapper: function(el) {
            var fg = el.closest('.field-group');
            if (fg) return fg;
            var box = el.closest('.image-upload-box');
            if (box) return box;
            return el.parentElement;
        },

        /** Cuenta los campos sucios en el panel y actualiza el badge de la pestaña. */
        updateBadge: function(panelEl) {
            if (!panelEl) return;
            var section = panelEl.getAttribute('data-section') || panelEl.id.replace('panel-', '');
            var tab = document.getElementById('tab-' + section);
            if (!tab) return;

            var count = 0;
            panelEl.querySelectorAll(TRACK_SELECTOR).forEach(function(el) {
                var orig = el.dataset.original !== undefined ? el.dataset.original : '';
                var current;
                if (el.type === 'checkbox' || el.type === 'radio') {
                    current = el.checked ? '1' : '0';
                } else {
                    current = el.value !== undefined ? el.value : '';
                }
                if (current !== orig) count++;
            });

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
        },

        /**
         * Resetea la línea base tras publicación exitosa.
         * Limpia indicadores rojos, badge de pestaña y draft de localStorage.
         */
        resetPanel: function(panelEl, section) {
            if (!panelEl) return;
            var self = this;

            panelEl.querySelectorAll(TRACK_SELECTOR).forEach(function(el) {
                if (el.type === 'checkbox' || el.type === 'radio') {
                    el.dataset.original = el.checked ? '1' : '0';
                } else {
                    el.dataset.original = el.value;
                }
                self.unmarkField(el);
            });

            var secName = section || panelEl.getAttribute('data-section') || panelEl.id.replace('panel-', '');
            var tab = document.getElementById('tab-' + secName);
            if (tab) {
                var badge = tab.querySelector('.tab-change-badge');
                if (badge) badge.remove();
            }

            self._clearDraft(panelEl.id); // [v2] Limpiar draft al publicar
            self._syncDirtyFlag();
        },

        /** Conecta un editor CKEditor 5 para notificar cambios en tiempo real. */
        bindCkeditor: function(editorInstance, textareaEl) {
            if (!editorInstance || !textareaEl) return;
            var self = this;
            editorInstance.model.document.on('change:data', function() {
                textareaEl.value = editorInstance.getData();
                self.evalField(textareaEl);
            });
        },

        // ══════════════════════════════════════════════════════════════════
        //  [v2] BEFOREUNLOAD GUARD
        // ══════════════════════════════════════════════════════════════════

        /**
         * Instala el listener de beforeunload.
         * Los navegadores modernos muestran su propio mensaje genérico (no personalizable).
         * Basta con asignar event.returnValue (o llamar a preventDefault()) para activar el diálogo.
         * Safari aún puede mostrar el texto de returnValue.
         */
        _installBeforeUnloadGuard: function() {
            window.addEventListener('beforeunload', function(e) {
                if (!_hasDirtyFields) return; // Sin cambios: dejar salir sin interrupciones
                var msg = 'Tienes cambios sin publicar en el CMS. Los datos NO se guardarán en el servidor si sales ahora.';
                e.preventDefault();     // Estándar W3C
                e.returnValue = msg;    // Legacy (Chrome < 119, Safari)
                return msg;
            });
        },

        // ══════════════════════════════════════════════════════════════════
        //  [v2] DRAFT AUTO-SAVE (localStorage)
        // ══════════════════════════════════════════════════════════════════

        /**
         * Serializa los campos sucios del panel y los persiste en localStorage.
         * Formato: { timestamp, panelId, fields: { name: value } }
         */
        _saveDraft: function(panelEl) {
            if (!panelEl) return;
            try {
                var dirtyFields = {};
                var hasDirty    = false;
                panelEl.querySelectorAll(TRACK_SELECTOR).forEach(function(el) {
                    var orig = el.dataset.original !== undefined ? el.dataset.original : '';
                    var current;
                    if (el.type === 'checkbox' || el.type === 'radio') {
                        current = el.checked ? '1' : '0';
                    } else {
                        current = el.value !== undefined ? el.value : '';
                    }
                    if (current !== orig && el.name) {
                        dirtyFields[el.name] = current;
                        hasDirty = true;
                    }
                });

                var key = DRAFT_PREFIX + panelEl.id;
                if (hasDirty) {
                    localStorage.setItem(key, JSON.stringify({
                        timestamp : Date.now(),
                        panelId   : panelEl.id,
                        fields    : dirtyFields
                    }));
                } else {
                    localStorage.removeItem(key); // Panel limpio: borrar draft previo
                }
            } catch(e) {
                // localStorage no disponible (modo privado extremo, quota llena) — fail silently
            }
        },

        /** Elimina el borrador de un panel del localStorage. */
        _clearDraft: function(panelId) {
            try { localStorage.removeItem(DRAFT_PREFIX + panelId); } catch(e) {}
        },

        /**
         * Al cargar la página, revisa si existe algún borrador válido en localStorage.
         * Si existen, muestra un banner fijo con botones "Restaurar" / "Descartar".
         */
        _restoreDraftsIfAny: function() {
            var self  = this;
            var found = [];

            activePanelIds.forEach(function(panelId) {
                try {
                    var raw = localStorage.getItem(DRAFT_PREFIX + panelId);
                    if (!raw) return;
                    var draft = JSON.parse(raw);
                    // Descartar borradores expirados (> 7 días)
                    if (!draft || !draft.fields || (Date.now() - draft.timestamp) > DRAFT_MAX_AGE) {
                        localStorage.removeItem(DRAFT_PREFIX + panelId);
                        return;
                    }
                    found.push(draft);
                } catch(e) {}
            });

            if (found.length === 0) return;

            // Nombres legibles por panelId
            var panelLabels = {
                'panel-hero'            : 'Banner Principal',
                'panel-quienes-somos'   : 'Quiénes somos',
                'panel-especialidades'  : 'Estudios de Rutina',
                'panel-promociones'     : 'Promociones Vigentes',
                'panel-calidad'         : 'Calidad e Instalaciones',
                'panel-ubicacion'       : 'Ubicación y Contacto',
                'panel-footer'          : 'Pie de Página',
                'panel-seo'             : 'SEO y Metadatos',
                'panel-aviso-privacidad': 'Aviso de Privacidad'
            };

            var panelNames = found.map(function(d) {
                return panelLabels[d.panelId] || d.panelId;
            });

            // Construir banner
            var banner = document.createElement('div');
            banner.id  = 'cms-draft-recovery-banner';
            banner.setAttribute('role', 'alert');
            banner.innerHTML =
                '<span style="flex:1;line-height:1.4;">' +
                '📝 <strong>Borradores sin publicar detectados</strong> en: <em>' + panelNames.join(', ') + '</em>. ' +
                '¿Restaurar los cambios de tu sesión anterior?</span>' +
                '<button id="cms-draft-restore-btn">✅ Restaurar</button>' +
                '<button id="cms-draft-discard-btn">🗑 Descartar</button>';

            banner.style.cssText = [
                'position:fixed','top:0','left:0','right:0','z-index:9990',
                'display:flex','align-items:center','gap:12px',
                'background:#fef9c3','border-bottom:2px solid #ca8a04',
                'padding:11px 20px','font-size:0.88rem','font-family:inherit',
                'box-shadow:0 2px 16px rgba(0,0,0,0.13)'
            ].join(';');

            // Estilos de botones inline (no dependen de gestion-web.css cargado aún)
            banner.querySelector('#cms-draft-restore-btn').style.cssText =
                'background:#0052b7;color:#fff;border:none;border-radius:6px;' +
                'padding:7px 16px;font-weight:700;cursor:pointer;white-space:nowrap;flex-shrink:0;';
            banner.querySelector('#cms-draft-discard-btn').style.cssText =
                'background:#fff;color:#ef4444;border:1.5px solid #ef4444;border-radius:6px;' +
                'padding:7px 14px;font-weight:700;cursor:pointer;white-space:nowrap;flex-shrink:0;';

            document.body.insertBefore(banner, document.body.firstChild);

            // Botón Restaurar: inyecta los valores guardados en los campos correspondientes
            document.getElementById('cms-draft-restore-btn').addEventListener('click', function() {
                found.forEach(function(draft) {
                    var panelEl = document.getElementById(draft.panelId);
                    if (!panelEl) return;
                    Object.keys(draft.fields).forEach(function(name) {
                        // Soporta name="campo" y name="campo[]" (arrays de checkbox/radio)
                        var el = panelEl.querySelector('[name="' + name + '"]');
                        if (!el) el = panelEl.querySelector('[name="' + name.replace(/\[\]$/, '') + '"]');
                        if (el) {
                            if (el.type === 'checkbox' || el.type === 'radio') {
                                el.checked = (draft.fields[name] === '1');
                            } else {
                                el.value = draft.fields[name];
                                // Si es un textarea asociado a CKEditor, sincronizar el editor visual
                                if (el.tagName === 'TEXTAREA' && el.classList.contains('ck5-hidden-data') && el.id) {
                                    var mountId  = el.id.replace('-data', '');
                                    var camelKey = '_' + mountId.replace(/-([a-z0-9])/g, function(g) { return g[1].toUpperCase(); });
                                    var legacyKey= 'ck_' + mountId.replace(/-/g, '_');
                                    var ed = (window._ckState && (window._ckState[camelKey] || window._ckState[legacyKey])) || window[camelKey] || window[legacyKey];
                                    if (ed && typeof ed.setData === 'function') {
                                        ed.setData(el.value);
                                    }
                                }
                            }
                            self.evalField(el); // Re-evaluar: marca dot rojo + badge
                        }
                    });
                });
                banner.remove();
            });

            // Botón Descartar: limpia los drafts y cierra el banner
            document.getElementById('cms-draft-discard-btn').addEventListener('click', function() {
                found.forEach(function(draft) { self._clearDraft(draft.panelId); });
                banner.remove();
            });
        },

        // ══════════════════════════════════════════════════════════════════
        //  INTERNO — Bandera global de "hay cambios sucios"
        // ══════════════════════════════════════════════════════════════════

        /**
         * Recalcula si existe AL MENOS UN campo sucio en cualquier panel activo.
         * Actualiza _hasDirtyFields — usado por el beforeunload guard.
         */
        _syncDirtyFlag: function() {
            var dirty = false;
            activePanelIds.forEach(function(panelId) {
                if (dirty) return; // Short-circuit
                var panel = document.getElementById(panelId);
                if (!panel) return;
                panel.querySelectorAll(TRACK_SELECTOR).forEach(function(el) {
                    var orig = el.dataset.original !== undefined ? el.dataset.original : '';
                    var current;
                    if (el.type === 'checkbox' || el.type === 'radio') {
                        current = el.checked ? '1' : '0';
                    } else {
                        current = el.value !== undefined ? el.value : '';
                    }
                    if (current !== orig) dirty = true;
                });
            });
            _hasDirtyFields = dirty;
        }
    };

    window.CmsDirtyTracker = CmsDirtyTracker;

})(window, document);


