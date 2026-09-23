/* medicos.js — lógica del portal de médicos (extraído de medicos.html) */
// Purga atómica de datos de prueba rezagados en localStorage (agosto 2026)
try {
    localStorage.removeItem('laesh_orders');
} catch (e) {}

        // ── Tabs internos del panel Nueva Orden ─────────────────────
        function switchSubTab(id, btn) {
            document.querySelectorAll('#panel-nueva-orden .portal-tab-panel').forEach(p => p.classList.remove('active'));
            document.querySelectorAll('#panel-nueva-orden .portal-tab').forEach(b => {
                b.classList.remove('active');
                b.setAttribute('aria-selected', 'false');
            });
            var panel = document.getElementById('subtab-' + id);
            if (panel) panel.classList.add('active');
            if (btn) { btn.classList.add('active'); btn.setAttribute('aria-selected', 'true'); }
            // Mostrar botones solo cuando el tab activo es Generar Orden Digital
            var tabBtns = document.getElementById('tab-bar-btns');
            if (tabBtns) tabBtns.style.display = (id === 'generar') ? 'flex' : 'none';
        }

        // ── Abanicos de grupos de estudios ──────────────────────────
        function toggleOrdenAcc(id) {
            var body = document.getElementById(id);
            if (!body) return;
            var arrow = document.getElementById('arr-' + id);
            var isCollapsed = body.classList.contains('collapsed');
            body.classList.toggle('collapsed', !isCollapsed);
            if (arrow) arrow.style.transform = isCollapsed ? 'rotate(0deg)' : 'rotate(-90deg)';
        }

        // ── GAP-MD-05 (2026-09-22): el botón "Crear e Imprimir Orden" solo
        // se pone en verde cuando el formulario está correctamente
        // capturado (mismo criterio que el guard de submit más abajo:
        // paciente + celular válidos, y al menos un estudio u "otros
        // estudios"). Por defecto queda en gris — evita que el médico
        // asuma que ya puede imprimir con datos incompletos.
        function isOrdenFormReady() {
            var paciente = document.getElementById('paciente');
            var celular  = document.getElementById('celular');
            if (!paciente || !celular) return false;
            if (!paciente.checkValidity() || !celular.checkValidity()) return false;
            if (!paciente.value.trim() || !celular.value.trim()) return false;
            var checkedBoxes = document.querySelectorAll('input[name="estudios[]"]:checked');
            var otrosEl = document.getElementById('otros-estudios');
            var hasEstudios = checkedBoxes.length > 0 || (otrosEl && otrosEl.value.trim() !== '');
            return !!hasEstudios;
        }
        function updateImprimirButtonState() {
            var ready = isOrdenFormReady();
            document.querySelectorAll('.btn-imprimir-orden, #btn-imprimir-mob').forEach(function(btn) {
                btn.classList.toggle('is-ready', ready);
            });
        }
        window.updateImprimirButtonState = updateImprimirButtonState;
        (function() {
            var formOrdenEl = document.getElementById('form-orden');
            if (!formOrdenEl) return;
            formOrdenEl.addEventListener('input', updateImprimirButtonState);
            formOrdenEl.addEventListener('change', updateImprimirButtonState);
        })();

        // ── Formulario: Crear e Imprimir Orden ──────────────────────
        document.getElementById('form-orden').addEventListener('submit', function(e) {
            e.preventDefault();
            var p      = document.getElementById('paciente').value.trim();
            var celular = document.getElementById('celular').value.trim();
            var edadEl  = document.getElementById('edad');
            var edad    = edadEl ? edadEl.value.trim() : '';
            var sexoEl = document.querySelector('input[name="sexo"]:checked');
            var sexo   = sexoEl ? sexoEl.value : '';
            var dx     = document.getElementById('diagnostico').value.trim();
            var otros  = document.getElementById('otros-estudios').value.trim();

            if (!p)      { if(typeof window.showToast==='function') showToast('El nombre del paciente es obligatorio.', 'error'); else alert('El nombre del paciente es obligatorio.'); return; }
            if (!celular) { if(typeof window.showToast==='function') showToast('El celular es obligatorio.', 'error'); else alert('El celular es obligatorio.'); return; }

            // Recolectar estudios seleccionados y deduplicar (fichas + acordeones pueden solaparse)
            var checkedBoxes = document.querySelectorAll('input[name="estudios[]"]:checked');
            var estudiosArr  = Array.from(checkedBoxes).map(function(cb) { return cb.value; });
            estudiosArr = estudiosArr.filter(function(v, i, a) { return a.indexOf(v) === i; });

            if (estudiosArr.length === 0 && !otros.trim()) {
                if(typeof window.showToast==='function') showToast('Por favor, selecciona al menos un estudio o indica adicionales.', 'warning');
                else alert('Por favor, selecciona al menos un estudio o indica estudios adicionales.');
                return;
            }
            
            // Preservar datos capturados del paciente antes de cualquier reseteo del formulario
            window.__LAST_SUBMITTED_ORDER__ = {
                paciente: p,
                celular: celular,
                edad: edad,
                sexo: sexo,
                dx: dx,
                otros: otros,
                estudios: estudiosArr
            };
            
            // G-1: Prevención de doble envío
            var submitBtn = document.querySelector('#form-orden button[type="submit"]');
            var originalText = submitBtn ? submitBtn.innerHTML : '';
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span class="spinner-btn"></span> Procesando...';
            }
            
            // HTMX se encargará del request. No abrimos el modal aquí.
        });

        // ── Escuchar evento HX-Trigger desde el backend cuando la orden se crea exitosamente
        // GAP-RC-01 (cerrado 2026-09-21): antes este handler reconstruía a mano los
        // ~14 campos de la orden (paciente/celular/edad/sexo/diagnóstico/estudios/
        // datos del médico) desde el formulario+localStorage+perfil, y los empujaba
        // por querystring — ese plumbing frágil causó bugs reales de datos faltantes.
        // Ahora la ventana de impresión consulta la orden real por folio directo a
        // BD (ver solicitud-dac.js + GET /laesh/md/api/orden) — solo hace falta
        // pasarle el folio.
        document.body.addEventListener('ordenCreada', function(e) {
            var folioReal = e.detail.folio || '1';
            verSolicitudDigital(folioReal);

            // Restablecer botón
            var submitBtn = document.querySelector('#form-orden button[type="submit"]');
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg> <span class="btn-imprimir-texto">Crear e Imprimir Orden</span>';
            }

            // Limpiar automáticamente el formulario tras crear la orden exitosamente sin disparar el window.confirm()
            var form = document.getElementById('form-orden');
            if (form) {
                form.reset();
                var checkboxes = form.querySelectorAll('input[type="checkbox"]');
                checkboxes.forEach(function(cb) {
                    cb.checked = false;
                    cb.dispatchEvent(new Event('change', { bubbles: true }));
                });
                if (typeof window.updateImprimirButtonState === 'function') window.updateImprimirButtonState();
            }
        });


        // Rastreo anti-sonido-inicial (espejo de lastRemitidos en labadmin)
        let lastResultados = 0;

        function refreshData() {
            // Contar ordenes listos en el DOM real de MariaDB
            const tbody = document.querySelector('#tabla-medico tbody');
            if (!tbody) return;
            const countResultados = tbody.querySelectorAll('.badge-listos').length;
            const badge = document.getElementById('badge-resultados');
            if (!badge) return;

            if (countResultados > 0) {
                badge.innerText = countResultados;
                badge.classList.add('show');
                if (countResultados > lastResultados) {
                    badge.classList.add('pulse');
                    playResultadosDing();
                    setTimeout(() => badge.classList.remove('pulse'), 3000);
                }
                document.title = `(${countResultados}) Portal Médico - LAESH`;
            } else {
                badge.classList.remove('show');
                badge.classList.remove('pulse');
                document.title = "Portal Médico - LAESH";
            }
            lastResultados = countResultados;
        }

        // Sonido distintivo para resultados listos (tono ascendente suave — distinto del silbato de recepción)
        function playResultadosDing() {
            try {
                const ctx = new (window.AudioContext || window.webkitAudioContext)();
                [880, 1100].forEach(function(freq, i) {
                    const osc  = ctx.createOscillator();
                    const gain = ctx.createGain();
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.type = 'sine';
                    osc.frequency.value = freq;
                    const t0 = ctx.currentTime + i * 0.2;
                    gain.gain.setValueAtTime(0, t0);
                    gain.gain.linearRampToValueAtTime(0.25, t0 + 0.02);
                    gain.gain.exponentialRampToValueAtTime(0.001, t0 + 0.28);
                    osc.start(t0);
                    osc.stop(t0 + 0.28);
                });
            } catch(e) { /* Audio no soportado */ }
        }

        // Overlay iframe compartido para solicitudes DAC (centralizado en app.js)
        var _abrirSolOverlay = window._abrirSolOverlay || function(url) {
            var prev = document.getElementById('sol-overlay');
            if (prev) prev.remove();
            var overlay = document.createElement('div');
            overlay.id = 'sol-overlay';
            overlay.className = 'sol-overlay';
            var iframe = document.createElement('iframe');
            iframe.src = url;
            iframe.title = 'Solicitud Digital de Análisis Clínicos';
            overlay.appendChild(iframe);
            document.body.appendChild(overlay);
        };
        // Bug B (auditoría 2026-09-21): faltaba el parámetro diagnostico — al
        // reabrir/reimprimir una solicitud ya creada desde la tabla, el
        // diagnóstico siempre se perdía aunque estuviera correctamente guardado
        // en BD, porque esta función nunca lo incluía en la URL del popup.
        // GAP-RC-01 (cerrado 2026-09-21): la ventana de impresión ahora consulta la
        // orden real por folio vía GET /laesh/md/api/orden (ver solicitud-dac.js) —
        // ya no hace falta reunir/pasar cada campo a mano. Los demás argumentos se
        // conservan solo por compatibilidad con call sites existentes (ignorados).
        function verSolicitudDigital(id) {
            var p = new URLSearchParams();
            p.set('id', id || '1');
            p.set('portal', 'md');
            _abrirSolOverlay('/laesh/rc/views/solicitud_dac_impr.php?' + p.toString());
        }


        function filtrarEstadisticasMedico() {
            const select = document.getElementById('filtro-periodo-medico');
            const val = select.value;
            
            let ordenes = 34;
            let completadas = 31;
            let tiempo = "4.5 hrs";
            let lblText = '';
            
            if (val === 'dia') {
                ordenes = 2;
                completadas = 2;
                tiempo = "3.8 hrs";
                lblText = 'HOY';
            } else if (val === 'semana') {
                ordenes = 12;
                completadas = 11;
                tiempo = "4.2 hrs";
                lblText = 'SEMANA';
            } else if (val === 'mes') {
                ordenes = 34;
                completadas = 31;
                tiempo = "4.5 hrs";
                lblText = 'MES';
            } else if (val === 'anio') {
                ordenes = 412;
                completadas = 395;
                tiempo = "4.8 hrs";
                lblText = 'AÑO';
            } else if (val === 'fecha') {
                const inputInicio = document.getElementById('fecha-inicio-medico').value || '2026-07-01';
                const inputFin = document.getElementById('fecha-fin-medico').value || '2026-07-28';
                
                const fInicio = inputInicio.split('-').reverse().join('/');
                const fFin = inputFin.split('-').reverse().join('/');
                
                ordenes = 18;
                completadas = 16;
                tiempo = "4.3 hrs";
                lblText = `${fInicio} al ${fFin}`;
            }
            
            if (document.getElementById('stat-ordenes-medico')) document.getElementById('stat-ordenes-medico').innerText = ordenes;
            if (document.getElementById('stat-completadas-medico')) document.getElementById('stat-completadas-medico').innerText = completadas;
            var elTiempo = document.getElementById('stat-tiempo-medico');
            if (elTiempo) elTiempo.innerText = tiempo;
            if (document.getElementById('lbl-ordenes-medico')) document.getElementById('lbl-ordenes-medico').innerText = `ÓRDENES EMITIDAS (${lblText})`;
        }

        function manejarCambioFiltroMedico() {
            const select = document.getElementById('filtro-periodo-medico');
            const rangeContainer = document.getElementById('rango-fechas-medico');
            if (select.value === 'fecha') {
                rangeContainer.style.display = 'inline-flex';
                const inputInicio = document.getElementById('fecha-inicio-medico');
                try {
                    inputInicio.showPicker();
                } catch (e) {
                    inputInicio.click();
                }
            } else {
                rangeContainer.style.display = 'none';
                filtrarEstadisticasMedico();
            }
        }

        // Carga inicial — poblar cache de MariaDB y verificar notificaciones
        refreshData();

        // Buscador Inteligente Médico (Consulta MariaDB SSOT)
        const inputBuscadorMedico = document.getElementById('input-buscador-medico');
        window.__MD_SEARCH_RESULTS__ = window.__MD_SEARCH_RESULTS__ || {};

        if (inputBuscadorMedico) {
            function posicionarAutocompleteMedico() {
                const autocompleteList = document.getElementById('autocomplete-list-medico');
                if (!autocompleteList) return;
                const rect = inputBuscadorMedico.getBoundingClientRect();
                autocompleteList.style.top   = (rect.bottom + 4) + 'px';
                autocompleteList.style.left  = rect.left + 'px';
                autocompleteList.style.width = Math.max(rect.width, 260) + 'px';
            }

            let searchTimerMedico = null;

            inputBuscadorMedico.addEventListener('input', function() {
                const query = this.value.trim();
                const autocompleteList = document.getElementById('autocomplete-list-medico');

                if (searchTimerMedico) clearTimeout(searchTimerMedico);

                if (query.length < 1) {
                    if (autocompleteList) {
                        autocompleteList.style.display = 'none';
                        autocompleteList.innerHTML = '';
                    }
                    return;
                }

                searchTimerMedico = setTimeout(function() {
                    fetch('/laesh/md/api/buscar-ordenes?q=' + encodeURIComponent(query))
                        .then(res => res.json())
                        .then(data => {
                            if (!autocompleteList) return;
                            if (data.success && Array.isArray(data.ordenes) && data.ordenes.length > 0) {
                                window.__MD_SEARCH_RESULTS__ = {};
                                autocompleteList.innerHTML = data.ordenes.map(m => {
                                    const folVal  = m.folio || ('LSH-' + m.id);
                                    window.__MD_SEARCH_RESULTS__[folVal] = m;
                                    window.__MD_SEARCH_RESULTS__[m.id] = m;
                                    const nameVal = m.paciente || '';
                                    const estVal  = m.estado || 'Emitida';
                                    return '<div class="autocomplete-item-medico"' +
                                         ' data-action="search-select-medico" data-id="' + folVal + '">' +
                                        '<strong>' + folVal + '</strong> - ' + nameVal + ' <span class="autocomplete-estado">(' + estVal + ')</span>' +
                                    '</div>';
                                }).join('');
                                posicionarAutocompleteMedico();
                                autocompleteList.style.display = 'block';
                            } else {
                                autocompleteList.innerHTML = '<div style="padding: 10px 14px; color: #94a3b8; font-style: italic; font-size: 0.85rem;">Sin resultados para "' + query + '"</div>';
                                posicionarAutocompleteMedico();
                                autocompleteList.style.display = 'block';
                            }
                        })
                        .catch(err => {
                            console.error("Error en búsqueda backend médico MariaDB:", err);
                            if (autocompleteList) autocompleteList.style.display = 'none';
                        });
                }, 200);
            });

            // Re-posicionar si el viewport cambia (rotación, resize)
            window.addEventListener('resize', function() {
                const autocompleteList = document.getElementById('autocomplete-list-medico');
                if (autocompleteList && autocompleteList.style.display !== 'none') {
                    posicionarAutocompleteMedico();
                }
            });

            document.addEventListener('click', (e) => {
                const autocompleteList = document.getElementById('autocomplete-list-medico');
                if (autocompleteList && !inputBuscadorMedico.contains(e.target) && !autocompleteList.contains(e.target)) {
                    autocompleteList.style.display = 'none';
                }
            });
        }
        
        function handleSearchSelectMedico(id) {
            const list = document.getElementById('autocomplete-list-medico');
            if (list) list.style.display = 'none';

            // GAP 4: todos los estados abren solicitud_dac_impr.html directamente
            verSolicitudDigital(id);
        }

        let medicoCatalogCurrentPage  = 1;
        const medicoCatalogItemsPerPage = 10;
        let medicoCatalogSearchQuery   = '';

        function getFlatCatalog() {
            if (Array.isArray(window.laeshFlatCatalog) && window.laeshFlatCatalog.length > 0) {
                return window.laeshFlatCatalog;
            }
            var flat = [];
            if (Array.isArray(window.laeshCatalogData)) {
                window.laeshCatalogData.forEach(function(group) {
                    if (Array.isArray(group.categorias)) {
                        group.categorias.forEach(function(cat) {
                            if (Array.isArray(cat.estudios)) {
                                cat.estudios.forEach(function(est) {
                                    flat.push({
                                        id: est.id,
                                        clave: est.clave,
                                        nombre: est.nombre,
                                        muestra: est.muestra,
                                        contenedor: est.contenedor,
                                        tiempo: est.tiempo,
                                        preparacion: est.preparacion,
                                        pruebas_incluidas: est.pruebas_incluidas,
                                        categoriaId: cat.id,
                                        categoriaNombre: cat.nombre,
                                        grupoId: group.id,
                                        grupoTitulo: group.titulo
                                    });
                                });
                            }
                        });
                    }
                });
            }
            window.laeshFlatCatalog = flat;
            return flat;
        }

        function renderMedicoCatalogTable(page) {
            const tbody = document.querySelector('#tabla-catalogo-medico tbody');
            const totalLabel = document.getElementById('medico-catalog-total');
            const totalLabelBottom = document.getElementById('medico-catalog-total-bottom');
            const paginationWrap = document.getElementById('medico-catalog-pagination');
            const paginationWrapBottom = document.getElementById('medico-catalog-pagination-bottom');
            if (!tbody) return;

            medicoCatalogCurrentPage = page || 1;
            var catalog = getFlatCatalog();

            // Filtrado multicampo en tiempo real
            var q = (medicoCatalogSearchQuery || '').trim().toLowerCase();
            var filtered = catalog;
            if (q) {
                filtered = catalog.filter(item => {
                    var cName = (item.nombre || '').toLowerCase();
                    var cClave = (item.clave || '').toString().toLowerCase();
                    var cArea = (item.categoriaNombre || item.categoria || '').toLowerCase();
                    var cPrep = (item.preparacion || '').toLowerCase();
                    var cMuestra = (item.muestra || '').toLowerCase();
                    var cPruebas = Array.isArray(item.pruebas_incluidas) ? item.pruebas_incluidas.join(' ').toLowerCase() : (item.pruebas_incluidas || '').toLowerCase();
                    return cName.includes(q) || cClave.includes(q) || cArea.includes(q) || cPrep.includes(q) || cMuestra.includes(q) || cPruebas.includes(q);
                });
            }

            var totalText = 'Total: ' + filtered.length + ' estudios';
            if (totalLabel) totalLabel.textContent = totalText;
            if (totalLabelBottom) totalLabelBottom.textContent = totalText;

            if (filtered.length === 0) {
                tbody.innerHTML = '<tr><td colspan="8" style="text-align:center; padding: 2rem; color: #94a3b8; font-weight: 500;">No se encontraron estudios que coincidan con la búsqueda.</td></tr>';
                if (paginationWrap) paginationWrap.innerHTML = '';
                if (paginationWrapBottom) paginationWrapBottom.innerHTML = '';
                return;
            }

            // Paginación estricta de 10 en 10
            var totalPages = Math.ceil(filtered.length / medicoCatalogItemsPerPage);
            if (medicoCatalogCurrentPage > totalPages) medicoCatalogCurrentPage = totalPages;
            if (medicoCatalogCurrentPage < 1) medicoCatalogCurrentPage = 1;

            var startIdx = (medicoCatalogCurrentPage - 1) * medicoCatalogItemsPerPage;
            var endIdx   = Math.min(startIdx + medicoCatalogItemsPerPage, filtered.length);
            var pageItems = filtered.slice(startIdx, endIdx);

            tbody.innerHTML = pageItems.map((item, idx) => {
                var rowNum = startIdx + idx + 1;
                var reqPrep = (typeof item.preparacion === 'string' && item.preparacion.trim() !== '') ? item.preparacion.trim() : '<span style="color:#94a3b8; font-style:italic;">Consultar en LAESH</span>';
                var reqMuestra = (typeof item.muestra === 'string' && item.muestra.trim() !== '') ? item.muestra.trim() : '<span style="color:#94a3b8; font-style:italic;">Consultar en LAESH</span>';
                var reqContenedor = (typeof item.contenedor === 'string' && item.contenedor.trim() !== '') ? item.contenedor.trim() : '<span style="color:#94a3b8; font-style:italic;">Consultar en LAESH</span>';
                var reqTiempo = (item.tiempo !== null && item.tiempo !== undefined && String(item.tiempo).trim() !== '') ? String(item.tiempo).trim().replace(/\.0$/, '') : '<span style="color:#94a3b8; font-style:italic;">Consultar en LAESH</span>';

                var pruebasListStr = '';
                if (Array.isArray(item.pruebas_incluidas)) {
                    pruebasListStr = item.pruebas_incluidas.join('\n');
                } else if (typeof item.pruebas_incluidas === 'string') {
                    pruebasListStr = item.pruebas_incluidas.trim();
                }

                var reqPruebas = '<span style="color:#94a3b8; font-style:italic;">Consultar en LAESH</span>';
                if (pruebasListStr !== '') {
                    var items = pruebasListStr.split(/[\n,]+/).map(s => s.trim()).filter(s => s !== '');
                    reqPruebas = '<ul style="margin:0; padding-left:1.1rem; font-size:0.85em; color:#334155;">' + items.map(s => '<li>' + s + '</li>').join('') + '</ul>';
                }

                return `
                    <tr style="background-color: ${idx % 2 === 0 ? '#ffffff' : '#f8fafc'}; border-bottom: 1px solid #f1f5f9;">
                        <td style="text-align: center; font-weight: 600; color: #64748b; font-size: 0.85rem;">${rowNum}</td>
                        <td style="white-space: normal; min-width: 240px; font-weight: 600; color: #0f172a; font-size: 0.88rem;">${item.nombre || ''}</td>
                        <td style="white-space: normal; color: #334155; font-size: 0.85rem;">${reqMuestra}</td>
                        <td style="white-space: normal; color: #334155; font-size: 0.85rem;">${reqContenedor}</td>
                        <td style="color: #334155; font-size: 0.85rem;">${reqTiempo}</td>
                        <td style="white-space: normal; color: #475569; font-size: 0.85rem;">${item.categoriaNombre || item.categoria || '—'}</td>
                        <td style="white-space: normal; min-width: 220px; color: #1e293b; font-size: 0.85rem;">${reqPrep}</td>
                        <td style="white-space: normal; min-width: 260px; font-size: 0.85rem;"><div style="max-height:80px; overflow-y:auto;">${reqPruebas}</div></td>
                    </tr>
                `;
            }).join('');

            // Renderizar controles de paginación minimalistas de 7 en 7
            function buildPaginationControls(container) {
                if (!container) return;
                container.innerHTML = '';
                if (totalPages <= 1) return;

                var maxButtons = 7;
                var startP = Math.max(1, medicoCatalogCurrentPage - Math.floor(maxButtons / 2));
                var endP = Math.min(totalPages, startP + maxButtons - 1);
                if (endP - startP + 1 < maxButtons) startP = Math.max(1, endP - maxButtons + 1);

                var baseStyle = "background: transparent; border: none; color: #475569; cursor: pointer; padding: 4px 8px; font-size: 0.92rem; font-weight: 600; min-width: 28px; display: inline-flex; align-items: center; justify-content: center; user-select: none; transition: color 0.15s ease;";
                var activeStyle = "background: transparent; border: none; border-bottom: 2px solid #0052B7; color: #0052B7; font-weight: 800; cursor: default; padding: 4px 8px; font-size: 0.95rem; min-width: 28px; display: inline-flex; align-items: center; justify-content: center; user-select: none;";
                var disabledStyle = "background: transparent; border: none; color: #cbd5e1; cursor: not-allowed; padding: 4px 8px; font-size: 0.92rem; font-weight: 600; min-width: 28px; display: inline-flex; align-items: center; justify-content: center; opacity: 0.4; user-select: none;";

                // Botón Anterior « (Avanza 7 páginas atrás)
                var btnPrev = document.createElement('button');
                btnPrev.type = 'button';
                btnPrev.innerHTML = '«';
                btnPrev.title = '7 páginas atrás';
                btnPrev.setAttribute('aria-label', '7 páginas atrás');
                if (medicoCatalogCurrentPage > 1) {
                    btnPrev.style = baseStyle;
                    btnPrev.onclick = function() { renderMedicoCatalogTable(Math.max(1, medicoCatalogCurrentPage - 7)); };
                } else {
                    btnPrev.style = disabledStyle;
                    btnPrev.disabled = true;
                }
                container.appendChild(btnPrev);

                // Botones numéricos de página (Minimalistas sin recuadros)
                for (var i = startP; i <= endP; i++) {
                    var btnP = document.createElement('button');
                    btnP.type = 'button';
                    btnP.style = (i === medicoCatalogCurrentPage) ? activeStyle : baseStyle;
                    btnP.textContent = i;
                    btnP.setAttribute('aria-label', 'Página ' + i);
                    (function(pNum) {
                        if (pNum !== medicoCatalogCurrentPage) {
                            btnP.onclick = function() { renderMedicoCatalogTable(pNum); };
                        }
                    })(i);
                    container.appendChild(btnP);
                }

                // Botón Siguiente » (Avanza 7 páginas adelante)
                var btnNext = document.createElement('button');
                btnNext.type = 'button';
                btnNext.innerHTML = '»';
                btnNext.title = '7 páginas adelante';
                btnNext.setAttribute('aria-label', '7 páginas adelante');
                if (medicoCatalogCurrentPage < totalPages) {
                    btnNext.style = baseStyle;
                    btnNext.onclick = function() { renderMedicoCatalogTable(Math.min(totalPages, medicoCatalogCurrentPage + 7)); };
                } else {
                    btnNext.style = disabledStyle;
                    btnNext.disabled = true;
                }
                container.appendChild(btnNext);
            }

            buildPaginationControls(paginationWrap);
            buildPaginationControls(paginationWrapBottom);
        }

        function refreshCatalog() {
            renderMedicoCatalogTable(1);
        }

        // Listener del buscador en tiempo real de Catálogo (Pacientes usa hx-get en la vista — GAP-MD-01)
        document.addEventListener('DOMContentLoaded', function() {
            var inputSearchCat = document.getElementById('input-buscar-catalogo-medico');
            if (inputSearchCat) {
                inputSearchCat.addEventListener('input', function() {
                    medicoCatalogSearchQuery = this.value;
                    renderMedicoCatalogTable(1);
                });
            }
        });

        // Cambiar Paneles / Tabs en Portal Médico (Rock-Solid)
        const panelLabels = {
            'panel-nueva-orden':       'Nueva Orden',
            'panel-historial-medico':  'Órdenes Anteriores',
            'panel-pacientes-medico':  'Pacientes',
            'panel-reportes-medico':   'Reportes',
            'panel-catalogo-medico':   'Catálogo de Estudios'
        };
        function cambiarTabMedico(panelId, el) {
            document.querySelectorAll('.sidebar .nav-item').forEach(i => i.classList.remove('active'));
            if (el) el.classList.add('active');
            document.querySelectorAll('.tab-panel').forEach(p => p.style.display = 'none');
            const target = document.getElementById(panelId);
            if (target) target.style.display = 'block';
            const bc = document.getElementById('header-bc-current');
            if (bc && panelLabels[panelId]) bc.textContent = panelLabels[panelId];

            if (panelId === 'panel-catalogo-medico')   refreshCatalog();
        }

        // Refrescar badge cuando la pestaña cambia
        window.addEventListener('storage', function() {
            refreshData();
        });

        // ── Floating Search (SFS) — medicos ─────────────────────────────────────
        // Toggle rail extraído a sidebar-rail.js (compartido con labadmin/gestion-web).
        // Este bloque maneja solo la búsqueda flotante específica del Portal Médico.
        (function() {
            var floatEl  = document.getElementById('float-search-medico');
            var sfsInput = document.getElementById('sfs-input-medico');
            var sfsRes   = document.getElementById('sfs-results-medico');
            var lupita   = document.getElementById('sidebar-search-btn');

            function closeSFS() {
                if (!floatEl) return;
                floatEl.classList.remove('sfs-open');
                if (sfsRes) { sfsRes.classList.remove('sfs-r-open'); sfsRes.innerHTML = ''; }
                if (sfsInput) sfsInput.value = '';
            }

            // sidebar-rail.js emite este evento al expandir → cerrar SFS
            document.addEventListener('laesh:sidebarExpand', closeSFS);

            let sfsTimerMedico = null;
            function renderSFS(query) {
                sfsRes.innerHTML = '';
                sfsRes.classList.remove('sfs-r-open');
                if (query.length < 1) return;
                if (sfsTimerMedico) clearTimeout(sfsTimerMedico);

                sfsTimerMedico = setTimeout(function() {
                    fetch('/laesh/md/api/buscar-ordenes?q=' + encodeURIComponent(query))
                        .then(res => res.json())
                        .then(data => {
                            sfsRes.innerHTML = '';
                            if (data.success && Array.isArray(data.ordenes) && data.ordenes.length > 0) {
                                window.__MD_SEARCH_RESULTS__ = window.__MD_SEARCH_RESULTS__ || {};
                                data.ordenes.forEach(function(m) {
                                    const folVal  = m.folio || ('LSH-' + m.id);
                                    window.__MD_SEARCH_RESULTS__[folVal] = m;
                                    window.__MD_SEARCH_RESULTS__[m.id] = m;
                                    const nameVal = m.paciente || '';
                                    const estVal  = m.estado || 'Emitida';
                                    var div = document.createElement('div');
                                    div.className = 'sfs-item';
                                    div.innerHTML = '<strong>' + folVal + '</strong> &mdash; ' + nameVal
                                        + ' <span class="sfs-estado">(' + estVal + ')</span>';
                                    div.addEventListener('mousedown', function(e) {
                                        e.preventDefault();
                                        closeSFS();
                                        handleSearchSelectMedico(folVal, nameVal, m.estudios, m.fecha, estVal, m.diagnostico, m.celular || m.telefono, m.edad, m.sexo);
                                    });
                                    sfsRes.appendChild(div);
                                });
                            } else {
                                var empty = document.createElement('div');
                                empty.className = 'sfs-empty';
                                empty.textContent = 'Sin resultados para "' + query + '"';
                                sfsRes.appendChild(empty);
                            }
                            sfsRes.classList.add('sfs-r-open');
                        })
                        .catch(err => {
                            console.error("Error en sfs search médico:", err);
                        });
                }, 200);
            }

            if (lupita && floatEl) {
                lupita.addEventListener('click', function(e) {
                    // Si sidebar expandido (desktop): usa el input embebido → no-op aquí
                    if (window.laeshSidebarRail && window.laeshSidebarRail.isExpanded()) return;
                    // Tablet/móvil (≤1024px): búsqueda inline — la maneja initPortalSearch (app.js)
                    if (window.innerWidth <= 1024) return;
                    // Desktop colapsado: abrir popup SFS flotante
                    e.stopPropagation();
                    var rect = lupita.getBoundingClientRect();
                    floatEl.style.top = rect.top + 'px';
                    if (floatEl.classList.contains('sfs-open')) {
                        closeSFS();
                    } else {
                        floatEl.classList.add('sfs-open');
                        setTimeout(function() { if (sfsInput) sfsInput.focus(); }, 40);
                    }
                });
            }

            if (sfsInput) {
                sfsInput.addEventListener('input', function() { renderSFS(this.value.trim()); });
                sfsInput.addEventListener('keydown', function(e) {
                    if (e.key === 'Escape') closeSFS();
                });
            }

            document.addEventListener('click', function(e) {
                // Tablet/móvil: initPortalSearch (app.js) gestiona el cierre — no interferir
                if (window.innerWidth <= 1024) return;
                if (!floatEl || !floatEl.classList.contains('sfs-open')) return;
                if (!floatEl.contains(e.target) && e.target !== lupita) closeSFS();
            });
        })();

/* ── Bloque 2: Editar Perfil Médico ── */
    (function() {
        var especialidades = [
            'Medicina General','Medicina Interna','Medicina Familiar',
            'Cirugía General','Ortopedia y Traumatología','Ginecología y Obstetricia',
            'Pediatría','Cardiología','Neumología','Gastroenterología',
            'Neurología','Neurocirugía','Urología','Oftalmología','Otorrinolaringología',
            'Dermatología','Psiquiatría','Reumatología','Endocrinología','Hematología',
            'Oncología','Nefrología','Infectología','Angiología y Cirugía Vascular',
            'Medicina de Rehabilitación','Radiología e Imagen','Anestesiología',
            'Patología Clínica','Nutriología Clínica','Odontología','Estomatología',
            'Geriatría','Alergología e Inmunología','Medicina del Deporte',
            'Cirugía Plástica y Reconstructiva','Medicina de Urgencias','Neonatología'
        ];
        var universidades = [
            'UABJO — Universidad Autónoma Benito Juárez de Oaxaca',
            'Universidad Tecnológica de la Mixteca',
            'UNAM — Universidad Nacional Autónoma de México',
            'IPN — Instituto Politécnico Nacional',
            'Universidad Veracruzana',
            'Universidad de Guadalajara',
            'Benemérita Universidad Autónoma de Puebla',
            'Otra institución'
        ];
        var lugares = [
            'Consultorio Particular', 'IMSS', 'ISSSTE', 'ISSSTE Estatal',
            'SSA — Secretaría de Salud', 'Hospital Civil', 'Cruz Roja Mexicana',
            'Clínica Privada', 'Hospital Privado', 'Otro'
        ];

        function poblarSelect(idSelect, items) {
            var sel = document.getElementById(idSelect);
            if (!sel) return;
            if (sel.options.length > 1) return; // Opciones renderizadas por el servidor
            items.forEach(function(item, idx) {
                var opt = document.createElement('option');
                opt.value = idx + 1;
                opt.textContent = item;
                sel.appendChild(opt);
            });
        }

        document.addEventListener('DOMContentLoaded', function() {
            poblarSelect('prof_universidad',   universidades);
            poblarSelect('prof_lugar_trabajo', lugares);
        });

        // ── Tabs internos del panel Mi Perfil ───────────────────────
        function switchPerfilSubTab(id, btn) {
            document.querySelectorAll('#panel-mi-perfil .portal-tab-panel').forEach(function(p) {
                p.classList.remove('active');
            });
            document.querySelectorAll('#panel-mi-perfil .portal-tab').forEach(function(b) {
                b.classList.remove('active');
                b.setAttribute('aria-selected', 'false');
            });
            var panel = document.getElementById('subtab-perfil-' + id);
            if (panel) panel.classList.add('active');
            if (btn) {
                btn.classList.add('active');
                btn.setAttribute('aria-selected', 'true');
            }
        }
        window.switchPerfilSubTab = switchPerfilSubTab;
    })();

/* ── P-LAESH-01 Phase3: event listeners (reemplaza onclick=/onchange= del HTML) ── */
document.addEventListener('DOMContentLoaded', function() {
    // Nav items → cambiarTabMedico delegation
    document.querySelectorAll('.nav-item[data-panel]').forEach(function(item) {
        item.addEventListener('click', function() {
            if (typeof window.cambiarTabMedico === 'function')
                window.cambiarTabMedico(this.getAttribute('data-panel'), this);
        });
        // A-01: activación por teclado para role="button" (Enter / Espacio)
        item.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                this.click();
            }
        });
    });

    // Sub-tabs: generar orden / órdenes hoy
    var tabGenerar     = document.getElementById('tab-generar');
    var tabOrdenesHoy  = document.getElementById('tab-ordenes-hoy');
    if (tabGenerar)    tabGenerar.addEventListener('click',    function() { if (typeof window.switchSubTab === 'function') window.switchSubTab('generar', this); });
    if (tabOrdenesHoy) tabOrdenesHoy.addEventListener('click', function() { if (typeof window.switchSubTab === 'function') window.switchSubTab('ordenes-hoy', this); });

    // Sub-tabs: Mi Perfil (Cambiar contraseña / Actualizar datos)
    var tabPerfilPass = document.getElementById('tab-perfil-password');
    var tabPerfilDatos= document.getElementById('tab-perfil-datos');
    if (tabPerfilPass) tabPerfilPass.addEventListener('click', function() { if (typeof window.switchPerfilSubTab === 'function') window.switchPerfilSubTab('password', this); });
    if (tabPerfilDatos)tabPerfilDatos.addEventListener('click',function() { if (typeof window.switchPerfilSubTab === 'function') window.switchPerfilSubTab('datos', this); });

    // Formulario 1: Cambiar Contraseña (Mi Perfil)
    var formPass = document.getElementById('form-cambiar-password-perfil');
    if (formPass) {
        formPass.addEventListener('submit', function(e) {
            e.preventDefault();
            var form = this;
            var btn = document.getElementById('btn-submit-password');
            var oldPass = (form.querySelector('[name="old_password"]') || {}).value || '';
            var newPass = (form.querySelector('[name="new_password"]') || {}).value || '';
            var confPass = (form.querySelector('[name="confirm_password"]') || {}).value || '';

            if (!oldPass || !newPass || !confPass) {
                if (typeof window.showToast === 'function') showToast('Por favor complete todos los campos de contraseña.', 'error');
                return;
            }
            if (newPass !== confPass) {
                if (typeof window.showToast === 'function') showToast('La nueva contraseña y su confirmación no coinciden.', 'error');
                return;
            }
            if (newPass.length < 8 || newPass.length > 10) {
                if (typeof window.showToast === 'function') showToast('La nueva contraseña debe tener entre 8 y 10 caracteres.', 'error');
                return;
            }

            var origHtml = btn ? btn.innerHTML : '';
            if (btn) { btn.disabled = true; btn.innerHTML = 'Actualizando...'; }

            var formData = new FormData(form);
            fetch('/laesh/md/perfil/cambiar-password', {
                method: 'POST',
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
                body: formData
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (btn) { btn.disabled = false; btn.innerHTML = origHtml; }
                if (data.success) {
                    if (typeof window.showToast === 'function') showToast(data.mensaje || '✓ Contraseña actualizada exitosamente.', 'success');
                    form.reset();
                } else {
                    if (typeof window.showToast === 'function') showToast(data.error || 'Error al cambiar la contraseña.', 'error');
                }
            })
            .catch(function(err) {
                if (btn) { btn.disabled = false; btn.innerHTML = origHtml; }
                if (typeof window.showToast === 'function') showToast('Error de conexión al actualizar la contraseña.', 'error');
            });
        });
    }

    // Formulario 2: Actualizar mis datos (Mi Perfil)
    var formDatos = document.getElementById('form-actualizar-datos-perfil');
    if (formDatos) {
        formDatos.addEventListener('submit', function(e) {
            e.preventDefault();
            var form = this;
            var btn = document.getElementById('btn-submit-datos');

            var origHtml = btn ? btn.innerHTML : '';
            if (btn) { btn.disabled = true; btn.innerHTML = 'Guardando...'; }

            var formData = new FormData(form);
            fetch('/laesh/md/perfil/actualizar-datos', {
                method: 'POST',
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
                body: formData
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (btn) { btn.disabled = false; btn.innerHTML = origHtml; }
                if (data.success) {
                    if (typeof window.showToast === 'function') showToast(data.mensaje || '✓ Datos del perfil actualizados exitosamente.', 'success');
                    if (data.nombre_completo) {
                        var chipLabel = document.querySelector('.mob-user-chip__label');
                        if (chipLabel) chipLabel.textContent = data.nombre_completo;
                    }
                } else {
                    if (typeof window.showToast === 'function') showToast(data.error || 'Error al actualizar los datos del perfil.', 'error');
                }
            })
            .catch(function(err) {
                if (btn) { btn.disabled = false; btn.innerHTML = origHtml; }
                if (typeof window.showToast === 'function') showToast('Error de conexión al guardar los datos.', 'error');
            });
        });
    }

    // Acordeón orden — delegación por data-acc
    document.querySelectorAll('[data-acc]').forEach(function(btn) {
        btn.addEventListener('click', function() {
            if (typeof window.toggleOrdenAcc === 'function')
                window.toggleOrdenAcc(this.getAttribute('data-acc'));
        });
    });

    // Botón limpiar orden (Desktop & Móvil) — UX-01: confirmación antes de destruir la selección
    var btnLimpiarOrden = document.getElementById('btn-limpiar-orden');
    var btnLimpiarMob   = document.getElementById('btn-limpiar-mob');
    var ejecutarLimpiar = function() {
        var form = document.getElementById('form-orden');
        if (!form) return;

        /* GAP-MD-06 (2026-09-22): la advertencia debe cubrir CUALQUIER campo
           con datos (antes solo miraba paciente/celular/checkboxes/radios —
           edad, diagnóstico u "otros estudios" capturados a solas no
           disparaban el confirm). */
        var tieneChecks = form.querySelectorAll('input[type="checkbox"]:checked, input[type="radio"]:checked').length > 0;
        var tieneTexto = Array.from(form.querySelectorAll('input[type="text"], input[type="tel"]'))
            .some(function(inp) { return inp.value.trim() !== ''; });
        var tieneContenido = tieneChecks || tieneTexto;
        if (tieneContenido && !window.confirm('¿Limpiar toda la orden? Se perderán el nombre del paciente, los datos y los estudios seleccionados.')) return;

        form.reset();
        var checkboxes = form.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(function(cb) {
            cb.checked = false;
            cb.dispatchEvent(new Event('change', { bubbles: true }));
        });
        if (typeof window.updateImprimirButtonState === 'function') window.updateImprimirButtonState();
    };
    if (btnLimpiarOrden) btnLimpiarOrden.addEventListener('click', ejecutarLimpiar);
    if (btnLimpiarMob)   btnLimpiarMob.addEventListener('click', ejecutarLimpiar);

    // Filtros historial/estadísticas
    var selFiltros = [
        ['select-fecha-medico',      function() { if (typeof window.manejarCambioFiltroMedico === 'function') window.manejarCambioFiltroMedico(); }],
        ['select-estado-medico',     function() { if (typeof window.filtrarHistorialMedico === 'function') window.filtrarHistorialMedico(); }],
        ['select-periodo-estadisticas-medico', function() { if (typeof window.filtrarEstadisticasMedico === 'function') window.filtrarEstadisticasMedico(); }]
    ];
    selFiltros.forEach(function(pair) {
        var el = document.getElementById(pair[0]);
        if (el) el.addEventListener('change', pair[1]);
    });

    // (modal-resultados legacy removido de DOM)


    /* ── Delegación CSP-safe: reemplaza onclick= en filas generadas vía innerHTML ── */
    function _medOrderAction(action, id, targetEl) {
        // GAP-RC-01 (cerrado 2026-09-21): 'ver-solicitud' ya solo necesita el
        // folio — la ventana de impresión consulta el resto directo a BD.
        // 'ver-resultados' se eliminó (mismo día): el botón real "Ver
        // Resultados" ahora es un <a href="/laesh/md/orden/pdf?id=..."> directo
        // (ver medicos.php/md/index.php) — ya no dispara esta acción.
        if (action === 'ver-solicitud') {
            verSolicitudDigital(id);
        }
    }

    // Delegación a nivel documento para clicks de acciones (folio, resultados, etc.) resistente a swaps HTMX
    document.addEventListener('click', function(e) {
        var el = e.target.closest('#tabla-medico [data-action], #tabla-historial-completo [data-action]');
        if (!el) return;
        var action = el.getAttribute('data-action');
        if (action === 'ver-solicitud') {
            e.preventDefault();
            _medOrderAction(action, el.getAttribute('data-id'), el);
        }
    });

    // autocomplete buscador médico (MariaDB SSOT)
    var autoBoxMedico = document.getElementById('autocomplete-list-medico');
    if (autoBoxMedico) autoBoxMedico.addEventListener('click', function(e) {
        var el = e.target.closest('[data-action="search-select-medico"]');
        if (!el) return;
        var mId = el.getAttribute('data-id');
        var order = window.__MD_SEARCH_RESULTS__ ? window.__MD_SEARCH_RESULTS__[mId] : null;
        if (order) {
            handleSearchSelectMedico(
                order.folio || order.id,
                order.paciente,
                order.estudios,
                order.fecha,
                order.estado,
                order.diagnostico,
                order.celular || order.telefono,
                order.edad,
                order.sexo
            );
        } else {
            handleSearchSelectMedico(mId, mId, '', '', 'Emitida');
        }
    });

    /* ── Poblar Grilla "20 Est.Med" — EXCLUSIVAMENTE desde catalog-compiled.js ──
       Fuente única de verdad: window.laeshTop20EstMed. Sin fetch/SQL live.
       Se refresca junto con el resto del catálogo vía WS 'catalogo_actualizado'
       (ws-client.js recarga catalog-compiled.js completo → hay que re-poblar). */
    function populateMandatoryGrid() {
        var grid = document.getElementById('fichas-estudios-grid');
        if (!grid) return;
        var top20 = (typeof window.laeshTop20EstMed !== 'undefined' && Array.isArray(window.laeshTop20EstMed)) ? window.laeshTop20EstMed : [];

        grid.innerHTML = '';
        top20.forEach(function(est) {
            var label = document.createElement('label');
            label.className = 'estudio-mandatory-card';
            // Bug real 2026-09-21 (auditoría solicitud digital): este checkbox se
            // llamaba "estudio_item" (singular, sin corchetes) pero el backend lee
            // $_POST['estudios'] — el envío nativo del form vía hx-post nunca
            // llegaba al servidor como array bajo esa clave, así que CUALQUIER
            // estudio marcado por el médico se perdía en silencio (orden se creaba
            // igual, con estudios=[] en BD, sin error visible). Confirmado contra
            // una orden real en producción (LAESH-00026). Renombrado a "estudios[]"
            // para que PHP lo reciba correctamente como array bajo la misma clave
            // que ya usa RC\Negocio\Ordenes::crearOrden() y curl/tests.
            label.innerHTML =
                '<input type="checkbox" name="estudios[]" value="' + (est.nombre || '').replace(/"/g, '&quot;') + '" data-clave="' + (est.clave || '') + '">' +
                '<div class="estudio-mandatory-info">' +
                    '<span class="estudio-mandatory-title">' + (est.nombre || '') + '</span>' +
                '</div>';
            grid.appendChild(label);
        });
    }
    window.populateMandatoryGrid = populateMandatoryGrid;

    /* ── Grilla de 10 fichas + Autocomplete de 18 Categorías + Contenedor Dinámico ── */
    (function initFichasCat() {
        populateMandatoryGrid();
        var grid = document.getElementById('fichas-estudios-grid');
        var form = document.getElementById('form-orden');
        if (!form) return;

        var openDrop = null;
        var lazyBodies = new Map();
        var initialCounts = new Map();

        /* PERF-01: Extraer elementos del DOM en carga */
        if (grid) {
            grid.querySelectorAll('.ficha-dropdown').forEach(function(drop) {
                var body = drop.querySelector('.ficha-dropdown__body');
                if (body) {
                    var cbs = body.querySelectorAll('input[type="checkbox"]');
                    initialCounts.set(drop.id, cbs.length);
                    lazyBodies.set(drop.id, body.innerHTML);
                    body.innerHTML = '';
                }
            });
        }

        function closeDrop() {
            if (!openDrop) return;
            var btn = openDrop.previousElementSibling;
            openDrop.classList.remove('open');
            openDrop.style.top  = '';
            openDrop.style.left = '';
            if (btn) {
                btn.setAttribute('aria-expanded', 'false');
                btn.focus();
            }
            openDrop = null;
        }

        function _positionDrop(dropEl, btnEl) {
            var btnRect = btnEl.getBoundingClientRect();
            var vpW     = window.innerWidth;
            var vpH     = window.innerHeight;
            var maxW    = Math.min(450, vpW - 20);
            var top  = btnRect.bottom + 5;
            var left = btnRect.left;
            if (left + maxW > vpW - 8) left = Math.max(4, vpW - maxW - 8);
            var dropH = dropEl.offsetHeight;
            if (top + dropH > vpH - 8 && btnRect.top >= dropH + 8) {
                top = btnRect.top - dropH - 5;
            }
            dropEl.style.top  = top  + 'px';
            dropEl.style.left = left + 'px';
        }

        function openDropEl(dropEl, btnEl) {
            if (openDrop && openDrop !== dropEl) closeDrop();
            var body = dropEl.querySelector('.ficha-dropdown__body');
            if (body && body.children.length === 0) {
                body.innerHTML = lazyBodies.get(dropEl.id) || '';
            }
            dropEl.classList.add('open');
            btnEl.setAttribute('aria-expanded', 'true');
            openDrop = dropEl;
            _positionDrop(dropEl, btnEl);
            var firstFocusable = dropEl.querySelector('.ficha-drop-close, input[type="checkbox"]');
            if (firstFocusable) firstFocusable.focus();
        }

        function updateFichaCount(ficha) {
            var sel = ficha.querySelector('.ficha-cat__sel');
            if (!sel) return;
            var dropId = ficha.getAttribute('aria-controls');
            var drop = dropId ? document.getElementById(dropId) : null;
            if (!drop) return;
            var body = drop.querySelector('.ficha-dropdown__body');
            var checked = 0;
            var totalN  = initialCounts.get(dropId) || 0;
            if (body && body.children.length > 0) {
                checked = body.querySelectorAll('input[type="checkbox"]:checked').length;
            }
            sel.innerHTML = '<span class="ficha-sel-x">' + checked + '</span> de <span class="ficha-sel-n">' + totalN + '</span>';
            ficha.classList.toggle('has-selection', checked > 0);
        }

        /* ── Actualizar Contenedor Dinámico de Chips (Columna Derecha) ── */
        function updateChipsContainer() {
            var listEl = document.getElementById('estudios-chips-list');
            var emptyEl = document.getElementById('estudios-chips-empty');
            var badgeEl = document.getElementById('cnt-estudios-chips-num');
            if (!listEl) return;

            var checked = form.querySelectorAll('input[name="estudios[]"]:checked');
            var selectedVals = Array.from(checked).map(function(cb) { return cb.value; });
            selectedVals = selectedVals.filter(function(v, i, a) { return a.indexOf(v) === i; });

            // Corrección 2026-09-22 (reportado desde producción): "Otros Estudios"
            // guarda correctamente en otros_estudios (no en estudios[] — ver
            // agregarOtrosEstudiosASeleccion), pero el médico no tenía ninguna
            // confirmación visual de qué quedó capturado ahí, y esperaba verlo
            // reflejado en "Estudios Seleccionados". Se muestran aquí como chips
            // de solo lectura visual — distinguibles (borde azul, sin quitar del
            // input de texto que es la fuente real) — sin tocar estudios[].
            var otrosVals = [];
            if (otrosEstudiosInput) {
                otrosVals = otrosEstudiosInput.value.split(',')
                    .map(function(s) { return s.trim(); })
                    .filter(function(s) { return s.length > 0; });
            }

            var totalCount = selectedVals.length + otrosVals.length;

            if (totalCount === 0) {
                if (emptyEl) emptyEl.style.display = 'block';
                listEl.innerHTML = '';
                if (badgeEl) badgeEl.textContent = '0 seleccionados';
            } else {
                if (emptyEl) emptyEl.style.display = 'none';
                if (badgeEl) badgeEl.textContent = totalCount + (totalCount === 1 ? ' seleccionado' : ' seleccionados');

                var catalogChips = selectedVals.map(function(val) {
                    return '<div class="chip-estudio-tag">' +
                        '<span>' + val + '</span>' +
                        '<button type="button" class="chip-estudio-remove" data-action="remove-chip" data-val="' + val.replace(/"/g, '&quot;') + '" aria-label="Remover ' + val.replace(/"/g, '&quot;') + '">&times;</button>' +
                    '</div>';
                }).join('');

                var otrosChips = otrosVals.map(function(val) {
                    return '<div class="chip-estudio-tag chip-estudio-tag--otros" title="Otros Estudios (texto libre)">' +
                        '<span>' + val + '</span>' +
                        '<button type="button" class="chip-estudio-remove" data-action="remove-chip-otros" data-val="' + val.replace(/"/g, '&quot;') + '" aria-label="Quitar ' + val.replace(/"/g, '&quot;') + '">&times;</button>' +
                    '</div>';
                }).join('');

                listEl.innerHTML = catalogChips + otrosChips;
            }
            updateTotalBadge();
            if (typeof window.updateImprimirButtonState === 'function') window.updateImprimirButtonState();
        }

        function updateTotalBadge() {
            var tabText = document.getElementById('tab-generar-text');
            if (!tabText) return;
            var checked = form.querySelectorAll('input[name="estudios[]"]:checked');
            var vals = Array.from(checked).map(function(cb) { return cb.value; });
            vals = vals.filter(function(v, i, a) { return a.indexOf(v) === i; });
            if (vals.length > 0) {
                tabText.innerHTML = 'Orden <span class="tab-badge-estudios">(' + vals.length + ' Est.)</span>';
            } else {
                tabText.innerHTML = 'Orden';
            }
        }

        /* ── Eventos de Fichas (Columna Izquierda) ── */
        if (grid) {
            grid.addEventListener('click', function(e) {
                var btn = e.target.closest('.ficha-cat');
                if (btn) {
                    var dropId = btn.getAttribute('aria-controls');
                    var drop   = dropId ? document.getElementById(dropId) : null;
                    if (!drop) return;
                    if (drop.classList.contains('open')) closeDrop();
                    else openDropEl(drop, btn);
                    return;
                }
                if (e.target.closest('.ficha-drop-close')) {
                    closeDrop();
                }
            });

            grid.addEventListener('change', function(e) {
                if (e.target.type !== 'checkbox') return;
                var fpKey = e.target.getAttribute('data-fp');
                if (fpKey) {
                    var btn = grid.querySelector('.ficha-cat[data-ficha="' + fpKey + '"]');
                    if (btn) updateFichaCount(btn);
                }
                updateChipsContainer();
            });
        }

        /* ── Evento Delegado: Remover Chip desde Contenedor Derecha ── */
        var chipsContainer = document.getElementById('contenedor-estudios-dinamico');
        if (chipsContainer) {
            chipsContainer.addEventListener('click', function(e) {
                var btnOtros = e.target.closest('[data-action="remove-chip-otros"]');
                if (btnOtros) {
                    var valOtros = btnOtros.getAttribute('data-val');
                    if (valOtros && otrosEstudiosInput) {
                        var restantes = otrosEstudiosInput.value.split(',')
                            .map(function(s) { return s.trim(); })
                            .filter(function(s) { return s.length > 0 && s.toLowerCase() !== valOtros.toLowerCase(); });
                        otrosEstudiosInput.value = restantes.join(', ');
                        updateChipsContainer();
                    }
                    return;
                }

                var btn = e.target.closest('[data-action="remove-chip"]');
                if (!btn) return;
                var val = btn.getAttribute('data-val');
                if (!val) return;

                var checkboxes = form.querySelectorAll('input[name="estudios[]"]');
                checkboxes.forEach(function(cb) {
                    if (cb.value === val) {
                        cb.checked = false;
                    }
                });

                if (grid) {
                    grid.querySelectorAll('.ficha-cat').forEach(function(fBtn) {
                        updateFichaCount(fBtn);
                    });
                }
                updateChipsContainer();
            });
        }

        /* ── Sanitización de Inputs (Sin Bucle de Mutación / Preserva Selección) ── */
        function sanitizeInputPreserveSelection(el, regex, maxLen) {
            var val = el.value;
            var clean = val.replace(regex, '');
            if (maxLen && clean.length > maxLen) {
                clean = clean.slice(0, maxLen);
            }
            if (val !== clean) {
                var start = el.selectionStart;
                var end = el.selectionEnd;
                el.value = clean;
                if (start !== null && end !== null) {
                    el.setSelectionRange(Math.min(start, clean.length), Math.min(end, clean.length));
                }
            }
        }

        var pacienteInput = document.getElementById('paciente');
        var edadInput     = document.getElementById('edad');
        var celularInput  = document.getElementById('celular');

        if (pacienteInput) {
            // Auto-focus al cargar la página para que el médico pueda escribir inmediatamente
            setTimeout(function() {
                if (document.activeElement !== pacienteInput) {
                    try { pacienteInput.focus(); } catch(e) {}
                }
            }, 50);

            pacienteInput.addEventListener('input', function() {
                sanitizeInputPreserveSelection(this, /[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, 35);
            });
        }

        if (edadInput) {
            edadInput.addEventListener('input', function() {
                sanitizeInputPreserveSelection(this, /[^0-9]/g, 3);
            });
        }

        if (celularInput) {
            celularInput.addEventListener('input', function() {
                sanitizeInputPreserveSelection(this, /[^0-9]/g, 10);
            });
        }

        /* ── Autocomplete Search In-Memory SSOT (catalog-compiled.js / Offline-First) ── */
        var inputSearchFicha = document.getElementById('input-buscar-estudio-ficha');
        var dropdownFichasRes = document.getElementById('autocomplete-results-fichas');

        if (inputSearchFicha && dropdownFichasRes) {
            inputSearchFicha.addEventListener('input', function() {
                var q = this.value.toLowerCase().trim();
                if (q.length < 2) {
                    dropdownFichasRes.classList.add('d-none');
                    dropdownFichasRes.innerHTML = '';
                    return;
                }
                
                var catalog = getFlatCatalog();
                var matches = catalog.filter(function(m) {
                    var nameMatch  = m.nombre && m.nombre.toLowerCase().includes(q);
                    var claveMatch = m.clave && m.clave.toLowerCase().includes(q);
                    var catMatch   = m.categoriaNombre && m.categoriaNombre.toLowerCase().includes(q);
                    return nameMatch || claveMatch || catMatch;
                }).slice(0, 12);

                if (matches.length > 0) {
                    dropdownFichasRes.innerHTML = matches.map(function(m) {
                        var catName = m.categoriaNombre || m.categoria || '';
                        return '<div class="autocomplete-fichas-item" data-action="select-autocomplete-study" data-val="' + m.nombre.replace(/"/g, '&quot;') + '">' +
                            '<span>' + m.nombre + '</span>' +
                            '<span class="cat-tag">' + catName + '</span>' +
                        '</div>';
                    }).join('');
                    dropdownFichasRes.classList.remove('d-none');
                } else {
                    dropdownFichasRes.innerHTML = '<div class="autocomplete-no-results">Sin resultados en catálogo</div>';
                    dropdownFichasRes.classList.remove('d-none');
                }
            });

            dropdownFichasRes.addEventListener('click', function(e) {
                var itemEl = e.target.closest('[data-action="select-autocomplete-study"]');
                if (!itemEl) return;
                var val = itemEl.getAttribute('data-val');
                if (!val) return;

                var foundCb = Array.from(form.querySelectorAll('input[name="estudios[]"]')).find(function(cb) {
                    return cb.value === val;
                });

                if (foundCb) {
                    foundCb.checked = true;
                    var fpKey = foundCb.getAttribute('data-fp');
                    if (fpKey && grid) {
                        var fBtn = grid.querySelector('.ficha-cat[data-ficha="' + fpKey + '"]');
                        if (fBtn) updateFichaCount(fBtn);
                    }
                } else {
                    var hiddenCb = document.createElement('input');
                    hiddenCb.type = 'checkbox';
                    hiddenCb.name = 'estudios[]';
                    hiddenCb.value = val;
                    hiddenCb.checked = true;
                    hiddenCb.setAttribute('data-auto-added', 'true');
                    hiddenCb.style.display = 'none';
                    form.appendChild(hiddenCb);
                }

                inputSearchFicha.value = '';
                dropdownFichasRes.classList.add('d-none');
                dropdownFichasRes.innerHTML = '';
                updateChipsContainer();
            });

            document.addEventListener('click', function(e) {
                if (!e.target.closest('.estudios-autocomplete-wrap')) {
                    dropdownFichasRes.classList.add('d-none');
                }
            });
        }

        /* ── "Otros Estudios" — texto libre independiente de Estudios Seleccionados ──
           Corrección 2026-09-21: antes este botón fusionaba lo escrito aquí dentro
           de "Estudios seleccionados" (checkboxes estudios[]) y vaciaba este campo,
           por lo que el backend nunca recibía otros_estudios y el dato terminaba
           listado como si fuera un estudio de catálogo. Ahora solo normaliza/dedup
           el texto y lo deja en este mismo input, que se envía tal cual como
           otros_estudios — sin tocar estudios[]. */
        var otrosEstudiosInput = document.getElementById('otros-estudios');
        var btnAddOtros = document.getElementById('btn-agregar-otros-estudios');

        // Corrección 2026-09-22 (reportado desde producción, móvil): el botón
        // "+" normaliza el texto correctamente (verificado con orden real:
        // otros_estudios se guardó bien separado) pero no daba NINGUNA señal
        // visible al tocarlo — en el caso normal (un solo estudio, sin
        // duplicados) el texto queda idéntico, así que en pantalla no cambia
        // nada y parece que el botón no respondió. Se agrega una confirmación
        // visual breve (ícono de check + destello verde) en cada toque válido.
        var otrosAddFeedbackTimer = null;
        function mostrarConfirmacionOtrosEstudios() {
            if (!btnAddOtros) return;
            if (otrosAddFeedbackTimer) clearTimeout(otrosAddFeedbackTimer);
            var svgPlus = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>';
            var svgCheck = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"></polyline></svg>';
            btnAddOtros.innerHTML = svgCheck;
            btnAddOtros.style.background = '#d1fae5';
            btnAddOtros.style.borderColor = '#16a34a';
            btnAddOtros.style.color = '#16a34a';
            otrosAddFeedbackTimer = setTimeout(function() {
                btnAddOtros.innerHTML = svgPlus;
                btnAddOtros.style.background = '';
                btnAddOtros.style.borderColor = '';
                btnAddOtros.style.color = '';
            }, 900);
        }

        function agregarOtrosEstudiosASeleccion() {
            if (!otrosEstudiosInput) return;
            var rawVal = otrosEstudiosInput.value.trim();
            if (!rawVal) return;

            var items = rawVal.split(',').map(function(s) { return s.trim(); }).filter(function(s) { return s.length > 0; });
            if (items.length === 0) return;

            var seen = {};
            var deduped = [];
            items.forEach(function(val) {
                var k = val.toLowerCase();
                if (!seen[k]) { seen[k] = true; deduped.push(val); }
            });

            otrosEstudiosInput.value = deduped.join(', ');
            mostrarConfirmacionOtrosEstudios();
            updateChipsContainer();
        }

        if (btnAddOtros) {
            btnAddOtros.addEventListener('click', function(e) {
                e.preventDefault();
                agregarOtrosEstudiosASeleccion();
            });
        }

        if (otrosEstudiosInput) {
            otrosEstudiosInput.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    agregarOtrosEstudiosASeleccion();
                }
            });
        }

        form.addEventListener('reset', function() {
            setTimeout(function() {
                if (grid) {
                    grid.querySelectorAll('.ficha-cat').forEach(function(fBtn) { updateFichaCount(fBtn); });
                }
                updateChipsContainer();
            }, 50);
        });

        document.addEventListener('click', function(e) {
            if (!openDrop) return;
            if (!e.target.closest('.ficha-wrap')) closeDrop();
        });

        document.addEventListener('keydown', function(e) {
            if (!openDrop) return;
            if (e.key === 'Escape') { closeDrop(); return; }
            if (e.key === 'Tab') {
                var focusable = Array.from(openDrop.querySelectorAll(
                    'button:not([disabled]), input[type="checkbox"]:not([disabled]), [tabindex]:not([tabindex="-1"])'
                ));
                if (focusable.length === 0) return;
                var first = focusable[0];
                var last  = focusable[focusable.length - 1];
                if (e.shiftKey && document.activeElement === first) {
                    e.preventDefault(); last.focus();
                } else if (!e.shiftKey && document.activeElement === last) {
                    e.preventDefault(); first.focus();
                }
            }
        });

        var _mainContent = document.querySelector('.main-content');
        if (_mainContent) {
            _mainContent.addEventListener('scroll', function() {
                if (openDrop) closeDrop();
            }, { passive: true });
        }

        window.addEventListener('resize', function() {
            if (openDrop) closeDrop();
        }, { passive: true });

        if (grid) {
            var fichas = grid.querySelectorAll('.ficha-cat');
            fichas.forEach(updateFichaCount);
        }
        updateChipsContainer();

        /* ── Accesibilidad A11Y: Anuncios aria-live y cambio de panel ── */
        var a11yLive = document.getElementById('a11y-live');
        function announceA11y(msg) {
            if (!a11yLive) return;
            a11yLive.textContent = '';
            requestAnimationFrame(function() { a11yLive.textContent = msg; });
        }
        document.querySelectorAll('[data-panel]').forEach(function(navItem) {
            navItem.addEventListener('click', function() {
                var label = navItem.getAttribute('aria-label') || navItem.textContent.trim();
                announceA11y('Panel activo: ' + label);
            });
        });
    })();
});
