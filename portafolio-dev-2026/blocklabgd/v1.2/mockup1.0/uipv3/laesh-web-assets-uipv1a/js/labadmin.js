/* labadmin.js — lógica del portal de recepción (extraído de labadmin.html) */
        function obtenerEspecialidadMedico(medicoNombre) {
            if (!medicoNombre) return 'Medicina General';
            if (medicoNombre.includes('Elena')) return 'Ginecología y Obstetricia';
            if (medicoNombre.includes('Hedilberto') || medicoNombre.includes('Reyes')) return 'Medicina Interna';
            if (medicoNombre.includes('Santiago') || medicoNombre.includes('Blanco')) return 'Hematología Especializada';
            if (medicoNombre.includes('Martínez') || medicoNombre.includes('Carlos')) return 'Pediatría y Patología';
            return 'Medicina General';
        }
        let lastRemitidos = 0;

        function refreshData() {
            // Deshabilitado: La tabla '#tabla-recepcion' ya es generada por PHP (labadmin.php) 
            // e incluye atributos HTMX funcionales. La inyección de mocks desde localStorage rompía la UI y borraba
            // los folios reales emitidos por la Base de Datos.
        }


        // Carga inicial (MariaDB SSOT)
        fetch('/laesh/rc/api/notificaciones')
            .then(res => res.json())
            .then(data => {
                if (data && data.success) {
                    lastRemitidos = data.emitidas || 0;
                }
            })
            .catch(() => {});
        refreshData();
        refreshHistorialAdmin();
        
        // Lógica de Autocompletado en Vivo MariaDB (por Folio, Paciente, Médico o Diagnóstico)
        const inputBuscador = document.getElementById('input-buscador');
        const autoBox = document.getElementById('autocomplete-list');
        window.__RC_SEARCH_RESULTS__ = window.__RC_SEARCH_RESULTS__ || {};

        if (inputBuscador && autoBox) {
            function posicionarAutocompleteAdmin() {
                const rect = inputBuscador.getBoundingClientRect();
                autoBox.style.top   = (rect.bottom + 4) + 'px';
                autoBox.style.left  = rect.left + 'px';
                autoBox.style.width = Math.max(rect.width, 260) + 'px';
            }

            let searchTimerAdmin = null;

            inputBuscador.addEventListener('input', function() {
                const query = this.value.trim();
                if (searchTimerAdmin) clearTimeout(searchTimerAdmin);

                if (query.length < 1) {
                    autoBox.style.display = 'none';
                    autoBox.innerHTML = '';
                    return;
                }

                searchTimerAdmin = setTimeout(function() {
                    fetch('/laesh/rc/api/buscar-ordenes?q=' + encodeURIComponent(query))
                        .then(res => res.json())
                        .then(data => {
                            if (data.success && Array.isArray(data.ordenes) && data.ordenes.length > 0) {
                                window.__RC_SEARCH_RESULTS__ = {};
                                autoBox.innerHTML = data.ordenes.map(m => {
                                    const folVal = m.folio || ('LSH-' + m.id);
                                    window.__RC_SEARCH_RESULTS__[folVal] = m;
                                    window.__RC_SEARCH_RESULTS__[m.id] = m;
                                    const estVal = m.estado || 'Emitida';
                                    const medStr = m.medico ? `<span style="color:#64748b; font-size:0.8rem;"> (${m.medico})</span>` : '';
                                    return `
                                        <div class="autocomplete-item-medico"
                                             data-action="search-select-admin" data-id="${folVal}">
                                            <strong>${folVal}</strong> — ${m.paciente}${medStr}
                                            <span class="autocomplete-estado"> (${estVal})</span>
                                        </div>
                                    `;
                                }).join('');
                                posicionarAutocompleteAdmin();
                                autoBox.style.display = 'block';
                            } else {
                                autoBox.innerHTML = `<div style="padding: 10px 14px; color: #94a3b8; font-style: italic; font-size: 0.85rem;">Sin resultados para "${query}"</div>`;
                                posicionarAutocompleteAdmin();
                                autoBox.style.display = 'block';
                            }
                        })
                        .catch(err => {
                            console.error("Error en búsqueda backend MariaDB:", err);
                            autoBox.style.display = 'none';
                        });
                }, 200);
            });

            // Re-posicionar si el viewport cambia (rotación, resize)
            window.addEventListener('resize', function() {
                if (autoBox.style.display !== 'none') posicionarAutocompleteAdmin();
            });

            document.addEventListener('click', (e) => {
                if (!inputBuscador.contains(e.target) && !autoBox.contains(e.target)) {
                    autoBox.style.display = 'none';
                }
            });
        }

        // ── Selección de resultado del autocomplete expandido (MariaDB SSOT) ────────
        // Corrección 2026-09-22: esta función tenía dos caminos, ambos rotos.
        // 1) Estado Remitido: intentaba escribir en un <iframe> dentro de
        //    #modal-solicitud-preview, pero ese modal nunca tuvo un <iframe> (solo
        //    una <img src="solicitudd.png"> estática) — así que jamás mostró datos
        //    reales, solo una imagen genérica siempre igual.
        // 2) Cualquier otro estado: filtrarTabla() solo ocultaba/mostraba <tr> ya
        //    presentes en el DOM de #tabla-recepcion/#tabla-ordenes-anteriores —
        //    con la paginación server-side (25 filas/página) agregada esta sesión,
        //    una orden que no estuviera en la página actualmente cargada "no se
        //    encontraba", aunque sí existiera.
        // Se reemplazan ambos por el mismo patrón ya usado en Médico
        // (handleSearchSelectMedico) y en el resto de RC (verSolicitudDigital):
        // abrir la solicitud real por folio vía GET /laesh/rc/api/orden — no
        // depende del DOM ni del estado de la orden.
        function handleSearchSelectAdmin(id, paciente, estudios, fecha, estado, folio) {
            const autoBox = document.getElementById('autocomplete-list');
            const inputBuscador = document.getElementById('input-buscador');
            if (autoBox) autoBox.style.display = 'none';

            const displayVal = folio || paciente || id;
            if (inputBuscador) inputBuscador.value = displayVal;

            const matchObj = window.__RC_SEARCH_RESULTS__ ? (window.__RC_SEARCH_RESULTS__[id] || window.__RC_SEARCH_RESULTS__[folio]) : null;
            const targetFolio = (matchObj && matchObj.folio) ? matchObj.folio : (folio || id);
            verSolicitudDigital(targetFolio);
        }

        async function filtrarEstadisticasAdmin() {
            const select = document.getElementById('filtro-periodo-admin');
            if (!select) return; // Salida segura si el panel de estadísticas no está presente en el DOM
            
            const val = select.value || 'mes';
            
            let lblText = val.toUpperCase();
            let inicio = '';
            let fin = '';
            
            if (val === 'fecha') {
                const inputInicio = document.getElementById('fecha-inicio-admin');
                const inputFin = document.getElementById('fecha-fin-admin');
                inicio = inputInicio ? inputInicio.value : '';
                fin = inputFin ? inputFin.value : '';
                
                if (!inicio || !fin) return; // Esperar a que ambas fechas estén seleccionadas
                
                const fInicio = inicio.split('-').reverse().join('/');
                const fFin = fin.split('-').reverse().join('/');
                lblText = `${fInicio} al ${fFin}`;
            }
            
            // Set loading states con guardas defensivas
            const statSolEl = document.getElementById('stat-solicitudes-admin');
            const statAtnEl = document.getElementById('stat-atencion-admin');
            const statLstEl = document.getElementById('stat-listos-admin');
            const statCerEl = document.getElementById('stat-cerradas-admin');
            const statCanEl = document.getElementById('stat-canceladas-admin');
            const lblSolEl  = document.getElementById('lbl-solicitudes-admin');
            
            if (statSolEl) statSolEl.innerText = '...';
            if (statAtnEl) statAtnEl.innerText = '...';
            if (statLstEl) statLstEl.innerText = '...';
            if (statCerEl) statCerEl.innerText = '...';
            if (statCanEl) statCanEl.innerText = '...';
            if (lblSolEl)  lblSolEl.innerText = `TOTAL SOLICITUDES (${lblText})`;
            
            const catContainer = document.getElementById('container-categorias-stats');
            const medContainer = document.getElementById('container-medicos-stats');
            
            if (catContainer) catContainer.innerHTML = '<div class="text-center txt-muted" style="padding:2rem;">Cargando categorías...</div>';
            if (medContainer) medContainer.innerHTML = '<div class="text-center txt-muted" style="padding:2rem;">Cargando médicos...</div>';
            
            try {
                const response = await fetch(`/laesh/rc/api/estadisticas?rango=${encodeURIComponent(val)}&inicio=${encodeURIComponent(inicio)}&fin=${encodeURIComponent(fin)}`);
                if (!response.ok) throw new Error('Error en API de estadísticas');
                
                const data = await response.json();
                if (!data.success) throw new Error(data.error || 'Error interno');
                
                // Totals
                if (statSolEl) statSolEl.innerText = (data.totales?.solicitudes ?? 0).toLocaleString();
                if (statAtnEl) statAtnEl.innerText = (data.totales?.atencion ?? 0).toLocaleString();
                if (statLstEl) statLstEl.innerText = (data.totales?.listos ?? 0).toLocaleString();
                if (statCerEl) statCerEl.innerText = (data.totales?.cerradas ?? 0).toLocaleString();
                if (statCanEl) statCanEl.innerText = (data.totales?.canceladas ?? 0).toLocaleString();

                // Categories
                if (catContainer) {
                    if (!data.categorias || data.categorias.length === 0) {
                        catContainer.innerHTML = '<div class="text-center txt-muted" style="padding:2rem;">No hay estudios en este periodo</div>';
                    } else {
                        let catHtml = '';
                        const catColors = ['bar-color-green', 'bar-color-blue', 'bar-color-amber'];
                        const totalCats = data.categorias.reduce((sum, c) => sum + parseInt(c.conteo, 10), 0) || 1;
                        
                        data.categorias.forEach((cat, idx) => {
                            const pct = Math.round((parseInt(cat.conteo, 10) / totalCats) * 100);
                            const color = catColors[idx % catColors.length];
                            catHtml += `
                            <div>
                                <div class="progress-label">
                                    <span>${cat.nombre}</span>
                                    <span>${pct}% (${cat.conteo} estudios)</span>
                                </div>
                                <div class="progress-track">
                                    <div class="bar-fill ${color}" style="width: ${pct}%;"></div>
                                </div>
                            </div>`;
                        });
                        catContainer.innerHTML = catHtml;
                    }
                }
                
                // Medicos
                if (medContainer) {
                    if (!data.medicos || data.medicos.length === 0) {
                        medContainer.innerHTML = '<div class="text-center txt-muted" style="padding:2rem;">No hay órdenes en este periodo</div>';
                    } else {
                        let medHtml = '';
                        const medColors = ['bar-color-green', 'bar-color-blue', 'bar-color-amber', 'bar-color-purple', 'bar-color-red'];
                        const totalMeds = data.medicos.reduce((sum, m) => sum + parseInt(m.conteo, 10), 0) || 1;
                        
                        data.medicos.forEach((med, idx) => {
                            const pct = Math.round((parseInt(med.conteo, 10) / totalMeds) * 100);
                            const color = medColors[idx % medColors.length];
                            medHtml += `
                            <div>
                                <div class="progress-label">
                                    <span>${med.nombre}</span>
                                    <span>${pct}% (${med.conteo} órdenes)</span>
                                </div>
                                <div class="progress-track">
                                    <div class="bar-fill ${color}" style="width: ${pct}%;"></div>
                                </div>
                            </div>`;
                        });
                        medContainer.innerHTML = medHtml;
                    }
                }
                
            } catch (err) {
                console.error('Error fetching estadísticas:', err);
                if (statSolEl) statSolEl.innerText = 'Error';
                if (statCanEl) statCanEl.innerText = 'Error';
                if (catContainer) catContainer.innerHTML = '<div class="text-center" style="color:var(--color-danger); padding:2rem;">Error al cargar</div>';
                if (medContainer) medContainer.innerHTML = '<div class="text-center" style="color:var(--color-danger); padding:2rem;">Error al cargar</div>';
            }
        }

        function manejarCambioFiltroAdmin() {
            const select = document.getElementById('filtro-periodo-admin');
            if (!select) return;
            const rangeContainer = document.getElementById('rango-fechas-admin');
            if (select.value === 'fecha') {
                if (rangeContainer) rangeContainer.style.display = 'inline-flex';
                const inputInicio = document.getElementById('fecha-inicio-admin');
                if (inputInicio) {
                    try {
                        inputInicio.showPicker();
                    } catch (e) {
                        inputInicio.click();
                    }
                }
            } else {
                if (rangeContainer) rangeContainer.style.display = 'none';
                filtrarEstadisticasAdmin();
            }
        }
        window.filtrarEstadisticasAdmin = filtrarEstadisticasAdmin;
        window.manejarCambioFiltroAdmin = manejarCambioFiltroAdmin;

        // GAP 3: abre solicitud_dac_impr.php en overlay iframe (centralizado en app.js)
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
        // GAP-RC-01 (cerrado 2026-09-21): la ventana de impresión ahora consulta la
        // orden real por folio vía GET /laesh/rc/api/orden (ver solicitud-dac.js) —
        // ya no hace falta reunir/pasar cada campo a mano. Esto cerró de raíz 4
        // bugs reales del mismo día (grilla rota, diagnóstico perdido, fecha
        // confundida con estudio, celular/edad/sexo faltantes), todos causados por
        // el mismo patrón: lógica duplicada entre este archivo y medicos.js +
        // datos sincronizados a mano sin ninguna alerta cuando algo faltaba.
        function verSolicitudDigital(id) {
            var p = new URLSearchParams();
            p.set('id', id || '1');
            p.set('portal', 'rc');
            _abrirSolOverlay('/laesh/rc/views/solicitud_dac_impr.php?' + p.toString());
        }


        // Cambiar Paneles / Tabs en Labadmin con actualización de Breadcrumb
        // FUENTE DE VERDAD: textos deben ser idénticos a los del menú lateral izquierdo
        const panelLabelsAdmin = {
            'panel-ordenes':            'Órdenes Hoy',
            'panel-ordenes-anteriores': 'Órdenes Anteriores',
            'panel-pacientes':          'Pacientes',
            'panel-medicos':            'Médicos',
            'panel-reportes':           'Reportes y Estadísticas',
            'panel-catalogos':          'Catálogos de Análisis'
        };

        function cambiarTabAdmin(panelId, el) {
            document.querySelectorAll('.sidebar .nav-item').forEach(i => i.classList.remove('active'));
            if (el) {
                el.classList.add('active');
            } else {
                const navItem = document.querySelector(`.sidebar .nav-item[data-panel="${panelId}"]`);
                if (navItem) navItem.classList.add('active');
            }
            document.querySelectorAll('.tab-panel').forEach(p => {
                p.style.display = 'none';
                p.classList.add('d-none');
            });
            const target = document.getElementById(panelId);
            if (target) {
                target.classList.remove('d-none');
                target.style.display = 'block';
            }

            const bc = document.getElementById('header-bc-current');
            if (bc && panelLabelsAdmin[panelId]) {
                bc.textContent = panelLabelsAdmin[panelId];
            }
            if (panelId === 'panel-catalogos') {
                if (typeof window.loadCatalogTree === 'function') {
                    window.loadCatalogTree();
                }
                const btnViewTable = document.getElementById('btn-view-table');
                if (btnViewTable) {
                    btnViewTable.click();
                }
            }
            if (panelId === 'panel-medicos') {
                var activeSubTab = document.querySelector('#toggle-medicos-view .cms-tab.active');
                var viewType = activeSubTab ? activeSubTab.getAttribute('data-view') : 'table';
                if (viewType === 'universidades' && typeof window.initUniversidadesFlatGrid === 'function') {
                    window.initUniversidadesFlatGrid();
                } else if (viewType === 'centros-trabajo' && typeof window.initCentrosTrabajoFlatGrid === 'function') {
                    window.initCentrosTrabajoFlatGrid();
                } else if (typeof window.initMedicosFlatGrid === 'function') {
                    window.initMedicosFlatGrid();
                }
            }
        }
        window.cambiarTabAdmin = cambiarTabAdmin;

        // Refrescar tablas, badge y silbato cuando médico u otro tab actualiza localStorage
        window.addEventListener('storage', function() {
            refreshData();                                                           // actualiza tabla-recepcion + badge-recepcion + silbato si hay nuevas órdenes
            if (typeof refreshHistorialAdmin === 'function') refreshHistorialAdmin(); // actualiza historial de Órdenes Anteriores
        });

        // A-01: activación por teclado (Enter/Espacio) para role="button" en nav-items
        // El listener de CLICK está en DOMContentLoaded (líneas P-LAESH-01) — no duplicar aquí.
        document.querySelectorAll('.sidebar .nav-item').forEach(function(item) {
            item.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    this.click();
                }
            });
        });

        
        function filtrarHistorialAdmin() {
            var el = document.getElementById('filtro-periodo-historial-admin');
            if (el) {
                console.log("Filtrando historial de recepción por periodo:", el.value);
            }
        }
        window.filtrarHistorialAdmin = filtrarHistorialAdmin;

        // ── Directorio de Pacientes ────────────────────────────────────────────
        function refreshPacientes() {
            // Renderizado mantenido server-side desde MariaDB en labadmin.php / HTMX
            return;
        }

        function refreshHistorialAdmin() {
            // Renderizado mantenido server-side desde MariaDB en labadmin.php / HTMX
            return;
        }

    
    // Las funciones de Tabla Plana (refreshCatalogRender, refreshCatalog, abrirModalEstudio, guardarEstudio, eliminarEstudio)
    // han sido depuradas y eliminadas.

    
        // Foco automático por default en el buscador de la recepción + Listeners HTMX Toast/Refresh
        document.addEventListener('DOMContentLoaded', function() {
            const inputBuscador = document.getElementById('input-buscador');
            if (inputBuscador) {
                setTimeout(function() {
                    inputBuscador.focus();
                    inputBuscador.select();
                }, 150);
            }

            document.body.addEventListener('mostrarToast', function(evt) {
                if (evt.detail && typeof window.showToast === 'function') {
                    window.showToast(evt.detail.mensaje, evt.detail.tipo || 'info');
                }
            });

            let lastActionOrdenId = null;

            // Rastrear el ID de orden cuando se dispara una acción en la columna Acción / PDF
            document.body.addEventListener('htmx:configRequest', function(evt) {
                if (evt.detail && evt.detail.parameters && evt.detail.parameters.orden_id) {
                    lastActionOrdenId = parseInt(evt.detail.parameters.orden_id, 10);
                } else if (evt.detail && evt.detail.elt) {
                    const row = evt.detail.elt.closest('tr[data-orden-id]');
                    if (row) {
                        lastActionOrdenId = parseInt(row.getAttribute('data-orden-id'), 10);
                    }
                }
            });

            document.body.addEventListener('ordenActualizada', function(evt) {
                let targetId = null;
                if (evt.detail) {
                    if (typeof evt.detail === 'object') {
                        targetId = evt.detail.ordenId || evt.detail.orden_id || evt.detail.value;
                    } else if (typeof evt.detail === 'number' || typeof evt.detail === 'string') {
                        targetId = parseInt(evt.detail, 10);
                    }
                }
                if (!targetId && lastActionOrdenId) {
                    targetId = lastActionOrdenId;
                }
                if (targetId) {
                    window._pendingHighlightOrdenId = parseInt(targetId, 10);
                }
            });

            // Al terminar el refresco de HTMX, mantener el foco y resaltar el renglón accionado por 10 segundos
            document.body.addEventListener('htmx:afterSettle', function(evt) {
                const targetId = window._pendingHighlightOrdenId;
                if (!targetId) return;
                window._pendingHighlightOrdenId = null; // Consumir inmediatamente para evitar loops

                setTimeout(function() {
                    const rows = document.querySelectorAll('tr[data-orden-id="' + targetId + '"]');
                    if (rows && rows.length > 0) {
                        rows.forEach(function(row) {
                            row.classList.remove('row-action-highlight');
                            void row.offsetWidth; // Forzar reflow para reiniciar animación
                            row.classList.add('row-action-highlight');
                            row.focus({ preventScroll: false });
                            row.scrollIntoView({ block: 'nearest', behavior: 'smooth' });

                            setTimeout(function() {
                                row.classList.remove('row-action-highlight');
                            }, 10500);
                        });
                    }
                }, 60);
            });
        });

        // ── Floating Search (SFS) — labadmin ────────────────────────────────────
        // Toggle rail extraído a sidebar-rail.js (compartido con medicos/gestion-web).
        // Este bloque maneja solo la búsqueda flotante específica del Portal Recepción.
        (function() {
            var floatEl  = document.getElementById('float-search-admin');
            var sfsInput = document.getElementById('sfs-input-admin');
            var sfsRes   = document.getElementById('sfs-results-admin');
            var lupita   = document.getElementById('sidebar-search-btn');

            function closeSFS() {
                if (!floatEl) return;
                floatEl.classList.remove('sfs-open');
                if (sfsRes) { sfsRes.classList.remove('sfs-r-open'); sfsRes.innerHTML = ''; }
                if (sfsInput) sfsInput.value = '';
            }

            // sidebar-rail.js emite este evento al expandir → cerrar SFS
            document.addEventListener('laesh:sidebarExpand', closeSFS);

            let sfsTimerAdmin = null;
            function renderSFS(query) {
                sfsRes.innerHTML = '';
                sfsRes.classList.remove('sfs-r-open');
                if (query.length < 1) return;
                if (sfsTimerAdmin) clearTimeout(sfsTimerAdmin);

                sfsTimerAdmin = setTimeout(function() {
                    fetch('/laesh/rc/api/buscar-ordenes?q=' + encodeURIComponent(query))
                        .then(res => res.json())
                        .then(data => {
                            sfsRes.innerHTML = '';
                            if (data.success && Array.isArray(data.ordenes) && data.ordenes.length > 0) {
                                window.__RC_SEARCH_RESULTS__ = window.__RC_SEARCH_RESULTS__ || {};
                                data.ordenes.forEach(function(m) {
                                    const folVal = m.folio || ('LSH-' + m.id);
                                    window.__RC_SEARCH_RESULTS__[folVal] = m;
                                    window.__RC_SEARCH_RESULTS__[m.id] = m;

                                    var div = document.createElement('div');
                                    div.className = 'sfs-item';
                                    div.innerHTML = '<strong>' + folVal + '</strong> &mdash; ' + m.paciente
                                        + ' <span class="sfs-estado">(' + (m.estado || 'Emitida') + ')</span>';
                                    div.addEventListener('mousedown', function(e) {
                                        e.preventDefault();
                                        closeSFS();
                                        handleSearchSelectAdmin(m.id, m.paciente, m.estudios, m.fecha, m.estado, folVal);
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
                            console.error("Error en sfs search:", err);
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


/* ── Bloque 2: Editar Perfil Admin ── */
    (function() {
        // ── Catálogos ────────────────────────────────────────────────
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
            // ── Oaxaca ──
            'UABJO — Universidad Autónoma Benito Juárez de Oaxaca',
            'Universidad Tecnológica de la Mixteca',
            'Universidad Tecnológica de Huajuapan de León',
            'Universidad del Papaloapan','Universidad del Istmo',
            'Universidad del Mar','Universidad del Pacífico Sur',
            'Universidad Sierra Juárez','Universidad de la Cañada',
            'Universidad Tecnológica de los Valles Centrales de Oaxaca',
            'Universidad Tecnológica de la Sierra Sur de Oaxaca',
            'Universidad Tecnológica de la Sierra Mazateca',
            'Universidad Tecnológica de Nochixtlán',
            'Universidad Tecnológica de la Sierra de Juárez',
            'Universidad Tecnológica de la Cuenca del Papaloapan',
            'Universidad Tecnológica de la Sierra de Flores Magón',
            // ── Puebla ──
            'BUAP — Benemérita Universidad Autónoma de Puebla',
            'UPAEP — Universidad Popular Autónoma del Estado de Puebla',
            'Universidad Tecnológica de Tehuacán',
            'Universidad Tecnológica de Izúcar de Matamoros',
            'Universidad Tecnológica de Cholula',
            'Universidad Tecnológica de Huejotzingo',
            'Universidad Tecnológica de San Martín Texmelucan',
            'Universidad Tecnológica de Atlixco',
            'Universidad Tecnológica de Xicotepec de Juárez',
            'Universidad Tecnológica de Chignahuapan',
            'Universidad Tecnológica de Teziutlán',
            // ── Ciudad de México ──
            'UNAM — Universidad Nacional Autónoma de México',
            'IPN — Instituto Politécnico Nacional',
            'UAM — Universidad Autónoma Metropolitana',
            'Universidad Autónoma de la Ciudad de México',
            'Universidad Anáhuac','Universidad Iberoamericana',
            'Tecnológico de Monterrey','Universidad La Salle',
            'Universidad del Valle de México',
            'Universidad del Claustro de Sor Juana'
        ];

        var lugaresLabora = [
            'Centro de Especialidades "Torre Azul"','Sanatorio Huajuapan',
            'Policlínica','Consultorio particular',
            'Hospital General de Huajuapan de León',
            'IMSS Huajuapan de León','ISSSTE Huajuapan de León',
            'Centro de Salud Juxtlahuaca',
            'Hospital Básico Comunitario Tamazulapan',
            'Clínica del ISSSTE Juxtlahuaca',
            'Centro Médico del Sur',
            'Hospital Regional de Alta Especialidad de Oaxaca',
            'Hospital Civil de Oaxaca',
            'Hospital General "Dr. Aurelio Valdivieso"'
        ];

        // ── Poblar un <select> con un array de strings ───────────────
        function poblarSelect(selectId, arr) {
            var sel = document.getElementById(selectId);
            if (!sel) return;
            // Conservar primer option (placeholder)
            var placeholder = sel.options[0];
            sel.innerHTML = '';
            sel.appendChild(placeholder);
            arr.forEach(function(item) {
                var opt = document.createElement('option');
                opt.value = item;
                opt.textContent = item;
                sel.appendChild(opt);
            });
        }

        // ── Abrir modal ──────────────────────────────────────────────
        window.abrirModalMedico = function() {
            window.lastActiveElementBeforeModal = document.activeElement;
            var m = document.getElementById('modal-medico');
            if (m) m.classList.add('show');
            document.body.style.overflow = 'hidden';
            var firstInput = document.getElementById('pm-nombre');
            if (firstInput) {
                setTimeout(function() { firstInput.focus(); }, 100);
            }
        };

        // ── Cerrar modal ─────────────────────────────────────────────
        window.cerrarModalMedico = function(skipRestoreFocus) {
            var m = document.getElementById('modal-medico');
            if (m) m.classList.remove('show');
            document.body.style.overflow = '';
            if (!skipRestoreFocus && window.lastActiveElementBeforeModal && typeof window.lastActiveElementBeforeModal.focus === 'function') {
                window.lastActiveElementBeforeModal.focus();
            }
        };

        // ── Limpiar formulario ───────────────────────────────────────
        window.limpiarFormMedico = function() {
            document.getElementById('form-perfil-medico').reset();
        };

        // ── Guardar/Editar perfil médico ──────────────────────────────
        var formMedico = document.getElementById('form-perfil-medico');
        if (formMedico) {
            formMedico.addEventListener('submit', function(e) {
                e.preventDefault();

                var userId   = (document.getElementById('pm-user-id') ? document.getElementById('pm-user-id').value : '').trim();
                var nombre   = (document.getElementById('pm-nombre').value || '').trim();
                var esp      = document.getElementById('pm-especialidad').value;
                var cedProf  = (document.getElementById('pm-cedula-profesional') ? document.getElementById('pm-cedula-profesional').value : '').trim();
                var cedEsp   = (document.getElementById('pm-cedula-especialidad') ? document.getElementById('pm-cedula-especialidad').value : '').trim();
                var celular  = (document.getElementById('pm-celular').value || '').trim();
                var univEl   = document.getElementById('pm-universidad');
                var lugarEl  = document.getElementById('pm-lugar');
                var univId   = univEl && univEl.value ? parseInt(univEl.value, 10) : null;
                var lugarId  = lugarEl && lugarEl.value ? parseInt(lugarEl.value, 10) : null;

                if (!nombre || !esp || !cedProf || !celular || !univId || !lugarId) {
                    alert('Por favor complete todos los campos requeridos (incluyendo Cédula Profesional, Universidad y Lugar donde labora).');
                    return;
                }
                if (!/^\d{10}$/.test(celular)) {
                    alert('El celular debe tener exactamente 10 dígitos.');
                    return;
                }

                var btnGuardar = document.getElementById('btn-guardar-medico');
                if (btnGuardar) {
                    btnGuardar.disabled = true;
                    btnGuardar.textContent = 'Guardando…';
                }

                var payloadItem = {
                    nombre_completo: nombre,
                    especialidad: esp,
                    cedula_profesional: cedProf,
                    cedula_especialidad: cedEsp,
                    celular: celular,
                    universidad_id: univId,
                    lugar_trabajo_id: lugarId
                };

                if (userId) {
                    payloadItem.user_id = parseInt(userId, 10);
                    payloadItem.is_modified = true;
                } else {
                    payloadItem.is_new = true;
                }

                fetch('/laesh/rc/api/medicos/sync', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ medicos: [payloadItem] })
                })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    if (btnGuardar) {
                        btnGuardar.disabled = false;
                        btnGuardar.textContent = userId ? 'Actualizar Perfil' : 'Guardar Perfil';
                    }
                    if (data && data.success) {
                        var savedUserId = data.user_id || (userId ? parseInt(userId, 10) : null);
                        if (typeof window.cerrarModalMedico === 'function') {
                            window.cerrarModalMedico(true); // skipRestoreFocus as fetchMedicosData will handle target row focus
                        }
                        formMedico.reset();
                        if (document.getElementById('pm-user-id')) {
                            document.getElementById('pm-user-id').value = '';
                        }
                        if (typeof window.showToast === 'function') {
                            window.showToast(data.mensaje || 'Perfil médico guardado correctamente.', 'success');
                        } else {
                            alert('✅ ' + (data.mensaje || 'Perfil médico guardado correctamente.'));
                        }
                        if (typeof fetchMedicosData === 'function') {
                            fetchMedicosData(savedUserId);
                        }
                    } else {
                        alert('⚠️ Error: ' + (data.error || 'No se pudo guardar el médico.'));
                    }
                })
                .catch(function(err) {
                    console.error('Error guardando médico:', err);
                    if (btnGuardar) {
                        btnGuardar.disabled = false;
                        btnGuardar.textContent = userId ? 'Actualizar Perfil' : 'Guardar Perfil';
                    }
                    alert('⚠️ Error de conexión al guardar médico.');
                });
            });
        }
    })();

/* ── P-LAESH-01 Phase3: event listeners (reemplaza onclick=/onchange= del HTML) ── */
document.addEventListener('DOMContentLoaded', function() {
    // Nav items → cambiarTabAdmin delegation
    document.querySelectorAll('.nav-item[data-panel]').forEach(function(item) {
        item.addEventListener('click', function() {
            if (typeof window.cambiarTabAdmin === 'function')
                window.cambiarTabAdmin(this.getAttribute('data-panel'), this);
        });
    });

    // Sidebar nav → gestion-web
    var navGestionWeb = document.getElementById('nav-gestion-web');
    if (navGestionWeb) navGestionWeb.addEventListener('click', function(e) {
        if (window.location.pathname.endsWith('.html') || window.location.protocol === 'file:' || window.location.pathname.includes('/uipv1a/')) {
            e.preventDefault();
            window.location.href = 'gestion-web.html';
        } else {
            window.location.href = '/laesh/adrc/';
        }
    });

    // Botón abrir modal médico
    var btnAbrirMedico = document.getElementById('btn-abrir-modal-medico');
    if (btnAbrirMedico) btnAbrirMedico.addEventListener('click', function() {
        if (typeof window.abrirModalMedico === 'function') window.abrirModalMedico();
    });

    // Botón agregar estudio
    var btnAgregarEstudio = document.getElementById('btn-agregar-estudio');
    if (btnAgregarEstudio) {
        btnAgregarEstudio.addEventListener('click', function() {
            if (window.showToast) showToast('Agregar Estudio desde el Constructor en proceso...', 'info');
        });
    } 
    
    // Filtros — IDs corregidos para coincidir con los elements reales del HTML
    var filtroSelects = [
        ['filtro-periodo-admin',           function() { if (typeof window.manejarCambioFiltroAdmin === 'function') window.manejarCambioFiltroAdmin(); }],
        ['filtro-periodo-historial-admin', function() { if (typeof window.filtrarHistorialAdmin === 'function') window.filtrarHistorialAdmin(); }]
    ];
    filtroSelects.forEach(function(pair) {
        var el = document.getElementById(pair[0]);
        if (el) el.addEventListener('change', pair[1]);
    });

    // Modal overlays (cerrar al click en backdrop — excluye modal-medico para requerir clic en cruz de cerrar)
    var modals = [];
    modals.forEach(function(pair) {
        var m = document.getElementById(pair[0]);
        if (m) m.addEventListener('click', function(e) {
            if (e.target === this && typeof window[pair[1]] === 'function') window[pair[1]]();
        });
    });

    // Close buttons
    var closeMap = [
        ['btn-cerrar-medico',          'cerrarModalMedico']
    ];
    closeMap.forEach(function(pair) {
        var btn = document.getElementById(pair[0]);
        if (btn) btn.addEventListener('click', function() {
            if (typeof window[pair[1]] === 'function') window[pair[1]]();
        });
    });

    // Form buttons médico
    var btnLimpiarMedico  = document.getElementById('btn-limpiar-medico');
    var btnGuardarMedico  = document.getElementById('btn-guardar-medico');
    if (btnLimpiarMedico)   btnLimpiarMedico.addEventListener('click',  function() { if (typeof window.limpiarFormMedico === 'function') window.limpiarFormMedico(); });
    if (btnGuardarMedico)   btnGuardarMedico.addEventListener('click',  function() { if (typeof window.guardarPerfilMedico === 'function') window.guardarPerfilMedico(); });

    // mob-user-chip class for CSS var background
    var chip = document.querySelector('.mob-user-chip__avatar--admin');
    // background set via CSS class .mob-user-chip__avatar--admin { background: var(--primary-green-dark); }

    /* ── Delegación CSP-safe: reemplaza onclick= en filas generadas vía innerHTML ── */
    function _orderAction(action, id, targetEl) {
        // GAP-RC-01 (cerrado 2026-09-21): 'ver-solicitud' ya solo necesita el
        // folio — la ventana de impresión consulta el resto directo a BD.
        // Auditoría de código muerto (mismo día): 'ver-resultados' se eliminó —
        // ningún elemento real en el DOM disparaba esta acción (el botón real
        // "Ver Resultados" usa un <a href="/laesh/rc/orden/pdf?id=..."> directo,
        // nunca data-action="ver-resultados"); verResultados()/cerrarModal()/
        // #modal-resultados y window.__RECEPCION_CACHE__ (nunca poblada) también
        // se eliminaron por ser inalcanzables.
        if (action === 'ver-solicitud') {
            verSolicitudDigital(id);
        }
    }

    // Delegación a nivel documento para clicks de acciones (folio, resultados, etc.) resistente a swaps HTMX
    document.addEventListener('click', function(e) {
        var el = e.target.closest('#tabla-recepcion [data-action], #tabla-recepcion-anteriores [data-action]');
        if (!el) return;
        var action = el.getAttribute('data-action');
        if (action === 'ver-solicitud' || action === 'ver-resultados') {
            e.preventDefault();
            _orderAction(action, el.getAttribute('data-id'), el);
        }
    });

    // Tabla Plana eliminada, no hay listener para tabla-catalogo-admin
    // Inicializar barras de reportes vía CSSOM (CSP-safe: evita inline style en HTML)
    if (typeof filtrarEstadisticasAdmin === 'function') filtrarEstadisticasAdmin();

    // autocomplete buscador admin (MariaDB SSOT)
    var autoBoxAdmin = document.getElementById('autocomplete-list');
    if (autoBoxAdmin) autoBoxAdmin.addEventListener('click', function(e) {
        var el = e.target.closest('[data-action="search-select-admin"]');
        if (!el) return;
        var mId = el.getAttribute('data-id');
        var order = window.__RC_SEARCH_RESULTS__ ? window.__RC_SEARCH_RESULTS__[mId] : null;
        if (order) {
            handleSearchSelectAdmin(order.id, order.paciente, order.estudios, order.fecha, order.estado, order.folio);
        } else {
            handleSearchSelectAdmin(mId, mId, '', '', 'Emitida', mId);
        }
    });

    // ─────────────────────────────────────────────────────────────
    // Operations Dropdown Menu in Doctors Table
    // ─────────────────────────────────────────────────────────────
    (function initDoctorsOperations() {
        var table = document.getElementById('tabla-medicos');
        if (!table) return;

        // Toggle dropdown on click/touch
        table.addEventListener('click', function(e) {
            var trigger = e.target.closest('.btn-ops-trigger');
            if (trigger) {
                e.stopPropagation();
                // Close other open menus
                document.querySelectorAll('.ops-dropdown-menu.open').forEach(function(m) {
                    if (m !== trigger.nextElementSibling) {
                        m.classList.remove('open');
                        m.previousElementSibling.setAttribute('aria-expanded', 'false');
                    }
                });

                var menu = trigger.nextElementSibling;
                var isOpen = menu.classList.contains('open');
                menu.classList.toggle('open', !isOpen);
                trigger.setAttribute('aria-expanded', String(!isOpen));
                return;
            }

            // Handle menu option selection
            var option = e.target.closest('.ops-menu-item');
            if (option) {
                e.stopPropagation();
                var action = option.getAttribute('data-action');
                var row = option.closest('tr');
                var docName = row ? row.cells[1].textContent.trim() : 'el médico';
                
                // Close menu
                var menu = option.closest('.ops-dropdown-menu');
                if (menu) {
                    menu.classList.remove('open');
                    menu.previousElementSibling.setAttribute('aria-expanded', 'false');
                }

                if (action === 'restablecer') {
                    if (confirm('¿Está seguro de que desea restablecer la contraseña para ' + docName + '?')) {
                        if (typeof window.showToast === 'function') {
                            window.showToast('Contraseña restablecida con éxito para ' + docName, 'success');
                        } else {
                            alert('Contraseña restablecida con éxito para ' + docName);
                        }
                    }
                } else if (action === 'pausar') {
                    var isPaused = option.textContent.trim().toLowerCase() === 'activar';
                    var confirmMsg = isPaused 
                        ? '¿Está seguro de que desea activar la cuenta de ' + docName + '?'
                        : '¿Está seguro de que desea pausar la cuenta de ' + docName + '?';
                    
                    if (confirm(confirmMsg)) {
                        if (isPaused) {
                            option.textContent = 'Pausar';
                            if (row) row.style.opacity = '1';
                            if (typeof window.showToast === 'function') {
                                window.showToast('Cuenta de ' + docName + ' activada', 'success');
                            }
                        } else {
                            option.textContent = 'Activar';
                            if (row) row.style.opacity = '0.5';
                            if (typeof window.showToast === 'function') {
                                window.showToast('Cuenta de ' + docName + ' pausada', 'warning');
                            }
                        }
                    }
                } else if (action === 'eliminar') {
                    if (confirm('¿Está seguro de que desea eliminar a ' + docName + '? Esta acción no se puede deshacer.')) {
                        if (row) {
                            row.style.transition = 'opacity 0.2s';
                            row.style.opacity = '0';
                            setTimeout(function() {
                                row.remove();
                            }, 200);
                        }
                        if (typeof window.showToast === 'function') {
                            window.showToast(docName + ' ha sido eliminado de la lista.', 'info');
                        }
                    }
                }
            }
        });

        // Close dropdown when clicking anywhere else
        document.addEventListener('click', function() {
            document.querySelectorAll('.ops-dropdown-menu.open').forEach(function(m) {
                m.classList.remove('open');
                m.previousElementSibling.setAttribute('aria-expanded', 'false');
            });
        });
    })();
});

/* ── MÓDULO GESTIÓN DE MÉDICOS (Grilla Plana SPA con Modales) ── */
var medicosCatalogData = [];
var medicosFilteredData = [];
var currentMedicosPage = 1;
var medicosItemsPerPage = 50;
var medicosSortCol = 'nombre_completo';
var medicosSortOrder = 'asc';

function initMedicosFlatGrid(forceFetch) {
    var table = document.getElementById('flat-medicos-table');
    if (!table) return;

    if (forceFetch || medicosCatalogData.length === 0) {
        fetchMedicosData();
    } else {
        renderMedicosFlatTable(currentMedicosPage);
    }
}
window.initMedicosFlatGrid = initMedicosFlatGrid;
window.fetchMedicosData = fetchMedicosData;

function fetchMedicosData(targetUserId) {
    var tbody = document.querySelector('#flat-medicos-table tbody');
    if (tbody) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center txt-muted py-4">⏳ Cargando catálogo de médicos...</td></tr>';
    }

    fetch('/laesh/rc/api/medicos')
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data && data.success && Array.isArray(data.data)) {
                medicosCatalogData = data.data;
                applyMedicosFilterAndSort();

                var targetPage = 1;
                if (targetUserId) {
                    var targetIdx = medicosFilteredData.findIndex(function(m) {
                        return String(m.user_id) === String(targetUserId);
                    });
                    if (targetIdx !== -1) {
                        targetPage = Math.floor(targetIdx / medicosItemsPerPage) + 1;
                    }
                }

                renderMedicosFlatTable(targetPage, targetUserId);
            } else {
                if (tbody) {
                    tbody.innerHTML = '<tr><td colspan="8" class="text-center txt-danger py-4">⚠️ Error al cargar médicos: ' + (data.error || 'Respuesta inválida') + '</td></tr>';
                }
            }
        })
        .catch(function(err) {
            console.error('Error fetching /api/medicos:', err);
            if (tbody) {
                tbody.innerHTML = '<tr><td colspan="8" class="text-center txt-danger py-4">⚠️ Error de conexión al cargar catálogo de médicos</td></tr>';
            }
        });
}

function updateMedicosSortIcons() {
    var headerNombre = document.getElementById('flat-medicos-sort-nombre');
    var headerCedula = document.getElementById('flat-medicos-sort-cedula');

    if (headerNombre) {
        var iconN = headerNombre.querySelector('.sort-icon');
        var isCurN = (medicosSortCol === 'nombre_completo');
        headerNombre.setAttribute('data-order', isCurN ? medicosSortOrder : 'none');
        if (iconN) iconN.textContent = isCurN ? (medicosSortOrder === 'asc' ? ' ▲' : ' ▼') : '';
    }
    if (headerCedula) {
        var iconC = headerCedula.querySelector('.sort-icon');
        var isCurC = (medicosSortCol === 'cedula_profesional');
        headerCedula.setAttribute('data-order', isCurC ? medicosSortOrder : 'none');
        if (iconC) iconC.textContent = isCurC ? (medicosSortOrder === 'asc' ? ' ▲' : ' ▼') : '';
    }
}

function applyMedicosFilterAndSort() {
    var searchInput = document.getElementById('flat-search-medicos-input');
    var query = searchInput ? searchInput.value.trim().toLowerCase() : '';

    medicosFilteredData = medicosCatalogData.filter(function(item) {
        if (!query) return true;
        var nom = (item.nombre_completo || '').toLowerCase();
        var ced = (item.cedula_profesional || '').toLowerCase();
        var esp = (item.especialidad || '').toLowerCase();
        var cel = (item.celular || '').toLowerCase();
        var uni = (item.universidad_nombre || '').toLowerCase();
        var lug = (item.lugar_trabajo_nombre || '').toLowerCase();
        return nom.includes(query) || ced.includes(query) || esp.includes(query) || cel.includes(query) || uni.includes(query) || lug.includes(query);
    });

    medicosFilteredData.sort(function(a, b) {
        var valA = (a[medicosSortCol] || '').toString().toLowerCase();
        var valB = (b[medicosSortCol] || '').toString().toLowerCase();
        if (valA < valB) return medicosSortOrder === 'asc' ? -1 : 1;
        if (valA > valB) return medicosSortOrder === 'asc' ? 1 : -1;
        return 0;
    });

    updateMedicosSortIcons();
}

function renderMedicosFlatTable(page, targetUserId) {
    currentMedicosPage = page || 1;
    var tbody = document.querySelector('#flat-medicos-table tbody');
    if (!tbody) return;

    var totalRecordsEl = document.getElementById('flat-medicos-total-records');
    if (totalRecordsEl) {
        totalRecordsEl.textContent = 'Total: ' + medicosFilteredData.length;
    }

    if (medicosFilteredData.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center txt-muted py-4">No se encontraron médicos.</td></tr>';
        renderMedicosPagination(0, 1);
        return;
    }

    var totalPages = Math.ceil(medicosFilteredData.length / medicosItemsPerPage);
    if (currentMedicosPage > totalPages) currentMedicosPage = totalPages;

    var startIdx = (currentMedicosPage - 1) * medicosItemsPerPage;
    var pageItems = medicosFilteredData.slice(startIdx, startIdx + medicosItemsPerPage);

    var html = '';
    pageItems.forEach(function(item, idx) {
        var rowNum = startIdx + idx + 1;
        var rowId = item.user_id ? item.user_id : (item._tempId || idx);
        var cedulaProf = item.cedula_profesional || '';
        var cedulaEsp = item.cedula_especialidad || '';
        var nombre = item.nombre_completo || '';
        var especialidad = item.especialidad || '';
        var universidad = item.universidad_nombre || '';
        var lugar = item.lugar_trabajo_nombre || '';
        var ordenes = item.total_ordenes || 0;

        var estadoId = parseInt(item.estado_id || 1, 10);
        var esPausado = (estadoId === 2);
        var pausarTitle = esPausado ? 'Reactivar' : 'Pausar';
        var pausarColor = esPausado ? '#16a34a' : '#d97706';
        var pausarSvg = esPausado 
            ? '<svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:middle;"><polygon points="5 3 19 12 5 21 5 3"/></svg>'
            : '<svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:middle;"><rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/></svg>';

        var accionesHtml = '<div style="display: inline-flex; align-items: center; justify-content: center; gap: 4px;">' +
            '<button type="button" class="btn-action-icon btn-medico-pausar" data-user-id="' + rowId + '" data-estado="' + estadoId + '" data-nombre="' + escapeAttrVal(nombre) + '" title="' + pausarTitle + '" style="background: transparent; border: none; cursor: pointer; padding: 4px 6px; border-radius: 4px; color: ' + pausarColor + '; display: inline-flex; align-items: center; justify-content: center; transition: transform 0.15s ease;" onmouseover="this.style.transform=\'scale(1.18)\'" onmouseout="this.style.transform=\'scale(1)\'">' +
                pausarSvg +
            '</button>' +
            '<span style="color: #cbd5e1; user-select: none; font-size: 0.9rem; font-weight: 300; margin: 0 2px;">|</span>' +
            '<button type="button" class="btn-action-icon btn-medico-password" data-user-id="' + rowId + '" data-nombre="' + escapeAttrVal(nombre) + '" data-celular="' + escapeAttrVal(item.celular || '') + '" title="Asignar contraseña" style="background: transparent; border: none; cursor: pointer; padding: 4px 6px; border-radius: 4px; color: #0284c7; display: inline-flex; align-items: center; justify-content: center; transition: transform 0.15s ease;" onmouseover="this.style.transform=\'scale(1.18)\'" onmouseout="this.style.transform=\'scale(1)\'">' +
                '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:middle;"><circle cx="7.5" cy="15.5" r="4.5"/><path d="m21 3-9.5 9.5"/><path d="m15.5 7.5 3 3"/><path d="m18 5 2 2"/></svg>' +
            '</button>' +
        '</div>';

        var rowStyle = esPausado ? 'background: #fafafa; opacity: 0.78;' : '';

        html += '<tr data-row-id="' + rowId + '" tabindex="0" style="cursor: pointer; ' + rowStyle + '" class="medico-row-item' + (esPausado ? ' medico-pausado' : '') + '">' +
            '<td style="text-align: center;">' +
                '<a href="#" class="med-link-edit" data-user-id="' + rowId + '" style="font-weight: 700; color: var(--primary); text-decoration: underline; font-size: 0.88rem;" onclick="event.preventDefault(); abrirEditarMedicoModal(' + rowId + ');">' + rowNum + '</a>' +
            '</td>' +
            '<td style="font-weight: 600; color: #475569;">' + escapeAttrVal(cedulaProf) + '</td>' +
            '<td style="color: #475569; font-size: 0.85rem;">' + escapeAttrVal(cedulaEsp) + '</td>' +
            '<td style="font-weight: 700; color: #1e293b;">' + escapeAttrVal(nombre) + (esPausado ? ' <span class="badge badge-subtle" style="background:#fef3c7; color:#92400e; font-size:0.7rem; font-weight:600; padding:1px 5px; margin-left:4px;">Pausado</span>' : '') + '</td>' +
            '<td>' + (especialidad ? '<span class="badge badge-subtle" style="background:#f1f5f9; color:#334155; font-weight:500;">' + escapeAttrVal(especialidad) + '</span>' : '') + '</td>' +
            '<td style="color: #475569; font-size: 0.85rem;">' + escapeAttrVal(universidad) + '</td>' +
            '<td style="color: #475569; font-size: 0.85rem;">' + escapeAttrVal(lugar) + '</td>' +
            '<td style="text-align: center;"><span class="badge badge-listos" style="font-size: 0.8rem; font-weight: 600;">' + ordenes + ' Órdenes</span></td>' +
            '<td style="text-align: center;">' + accionesHtml + '</td>' +
        '</tr>';
    });

    tbody.innerHTML = html;
    renderMedicosPagination(totalPages, currentMedicosPage);
    bindMedicosTableEvents();

    if (targetUserId) {
        setTimeout(function() {
            var targetRow = tbody.querySelector('tr[data-row-id="' + targetUserId + '"]');
            if (targetRow) {
                targetRow.classList.add('row-saved-highlight');
                targetRow.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
                var editLink = targetRow.querySelector('.med-link-edit');
                if (editLink) {
                    editLink.focus();
                } else {
                    targetRow.focus();
                }
            }
        }, 120);
    }
}

function escapeAttrVal(str) {
    if (!str) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

function bindMedicosTableEvents() {
    var tbody = document.querySelector('#flat-medicos-table tbody');
    if (!tbody) return;

    var editLinks = tbody.querySelectorAll('.med-link-edit');
    editLinks.forEach(function(link) {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var userId = this.getAttribute('data-user-id');
            abrirEditarMedicoModal(userId);
        });
    });

    // Eventos Botón Pausar
    var btnPausarList = tbody.querySelectorAll('.btn-medico-pausar');
    btnPausarList.forEach(function(btn) {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var userId = this.getAttribute('data-user-id');
            var estado = parseInt(this.getAttribute('data-estado') || 1, 10);
            var nombre = this.getAttribute('data-nombre') || 'el médico';
            cambiarEstadoMedicoAction(userId, estado, nombre);
        });
    });

    // Eventos Botón Asignar Contraseña
    var btnPassList = tbody.querySelectorAll('.btn-medico-password');
    btnPassList.forEach(function(btn) {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var userId = this.getAttribute('data-user-id');
            var nombre = this.getAttribute('data-nombre') || '';
            var celular = this.getAttribute('data-celular') || '';
            abrirModalAsignarPasswordMedico(userId, nombre, celular);
        });
    });

    var rows = tbody.querySelectorAll('.medico-row-item');
    rows.forEach(function(row) {
        row.addEventListener('dblclick', function() {
            var userId = this.getAttribute('data-row-id');
            abrirEditarMedicoModal(userId);
        });
    });
}

function abrirNuevoMedicoModal() {
    var form = document.getElementById('form-perfil-medico');
    if (form) form.reset();

    var userIdInput = document.getElementById('pm-user-id');
    if (userIdInput) userIdInput.value = '';

    var title = document.getElementById('modal-medico-title');
    if (title) title.textContent = 'Registro de Perfil Médico';

    var btnSave = document.getElementById('btn-guardar-medico');
    if (btnSave) btnSave.textContent = 'Guardar Perfil';

    if (typeof window.abrirModalMedico === 'function') {
        window.abrirModalMedico();
    } else {
        var m = document.getElementById('modal-medico');
        if (m) m.classList.add('show');
    }
}
window.abrirNuevoMedicoModal = abrirNuevoMedicoModal;

function abrirEditarMedicoModal(userId) {
    var item = medicosCatalogData.find(function(m) {
        return String(m.user_id) === String(userId);
    });

    if (!item) return;

    var userIdInput = document.getElementById('pm-user-id');
    if (userIdInput) userIdInput.value = item.user_id;

    var nombreInput = document.getElementById('pm-nombre');
    if (nombreInput) nombreInput.value = item.nombre_completo || '';

    var espSelect = document.getElementById('pm-especialidad');
    if (espSelect) {
        espSelect.value = item.especialidad || 'Medicina General';
        if (espSelect.selectedIndex === -1 && espSelect.options.length > 0) {
            espSelect.selectedIndex = 0;
        }
    }

    var cedProfInput = document.getElementById('pm-cedula-profesional');
    if (cedProfInput) cedProfInput.value = item.cedula_profesional || '';

    var cedEspInput = document.getElementById('pm-cedula-especialidad');
    if (cedEspInput) cedEspInput.value = item.cedula_especialidad || '';

    var celularInput = document.getElementById('pm-celular');
    if (celularInput) celularInput.value = item.celular || '';

    var univSelect = document.getElementById('pm-universidad');
    if (univSelect) {
        if (item.universidad_id) {
            univSelect.value = item.universidad_id;
        } else if (item.universidad_nombre) {
            for (var i = 0; i < univSelect.options.length; i++) {
                if (univSelect.options[i].text.trim() === item.universidad_nombre.trim()) {
                    univSelect.selectedIndex = i;
                    break;
                }
            }
        }
    }

    var lugarSelect = document.getElementById('pm-lugar');
    if (lugarSelect) {
        if (item.lugar_trabajo_id) {
            lugarSelect.value = item.lugar_trabajo_id;
        } else if (item.lugar_trabajo_nombre) {
            for (var j = 0; j < lugarSelect.options.length; j++) {
                if (lugarSelect.options[j].text.trim() === item.lugar_trabajo_nombre.trim()) {
                    lugarSelect.selectedIndex = j;
                    break;
                }
            }
        }
    }

    var title = document.getElementById('modal-medico-title');
    if (title) title.textContent = 'Editar Perfil Médico';

    var btnSave = document.getElementById('btn-guardar-medico');
    if (btnSave) btnSave.textContent = 'Actualizar Perfil';

    if (typeof window.abrirModalMedico === 'function') {
        window.abrirModalMedico();
    } else {
        var m = document.getElementById('modal-medico');
        if (m) m.classList.add('show');
    }
}
window.abrirEditarMedicoModal = abrirEditarMedicoModal;

function renderMedicosPagination(totalPages, currentPage) {
    var container = document.getElementById('flat-medicos-pagination');
    if (!container) return;

    if (totalPages <= 1) {
        container.innerHTML = '';
        return;
    }

    var html = '';
    for (var i = 1; i <= totalPages; i++) {
        var activeClass = i === currentPage ? 'btn-primary' : 'btn-secondary';
        html += '<button type="button" class="btn ' + activeClass + ' btn-sm med-page-btn" data-page="' + i + '" style="padding: 2px 8px; font-size: 0.8rem;">' + i + '</button>';
    }
    container.innerHTML = html;

    container.querySelectorAll('.med-page-btn').forEach(function(btn) {
        btn.addEventListener('click', function() {
            var page = parseInt(this.getAttribute('data-page'), 10);
            renderMedicosFlatTable(page);
        });
    });
}

/* ── ACCIONES EN TABLA DE MÉDICOS: PAUSAR Y ASIGNAR CONTRASEÑA ── */
function cambiarEstadoMedicoAction(userId, estadoActual, nombre) {
    var nuevoEstado = (estadoActual === 2) ? 1 : 2;
    var msg = (nuevoEstado === 1)
        ? '¿Deseas reactivar la cuenta del Dr(a). ' + (nombre || 'médico') + '?'
        : '¿Deseas pausar la cuenta del Dr(a). ' + (nombre || 'médico') + '?\n\nAl estar pausado, se revocarán sus sesiones activas y no podrá acceder al portal.';
    
    if (!window.confirm(msg)) return;

    var csrfToken = document.querySelector('input[name="csrf_token"]') ? document.querySelector('input[name="csrf_token"]').value : '';
    var params = new URLSearchParams();
    params.append('target_user_id', userId);
    params.append('nuevo_estado_id', nuevoEstado);
    params.append('csrf_token', csrfToken);

    fetch('/laesh/rc/api/medicos/cambiar-estado', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(function(res) { return res.json(); })
    .then(function(data) {
        if (data && data.success) {
            var tipoToast = (nuevoEstado === 2) ? 'warning' : 'success';
            if (typeof window.showToast === 'function') {
                window.showToast(data.mensaje || 'Estado del médico actualizado con éxito.', tipoToast);
            } else {
                alert('✅ ' + (data.mensaje || 'Estado actualizado con éxito.'));
            }
            fetchMedicosData(userId);
        } else {
            var errMsg = (data && data.error) ? data.error : 'No se pudo cambiar el estado del médico.';
            if (typeof window.showToast === 'function') {
                window.showToast('⚠️ ' + errMsg, 'error');
            } else {
                alert('⚠️ ' + errMsg);
            }
        }
    })
    .catch(function(err) {
        console.error('Error al cambiar estado médico:', err);
        if (typeof window.showToast === 'function') {
            window.showToast('⚠️ Error de conexión al actualizar estado del médico.', 'error');
        } else {
            alert('⚠️ Error de conexión al actualizar estado del médico.');
        }
    });
}
window.cambiarEstadoMedicoAction = cambiarEstadoMedicoAction;

function abrirModalAsignarPasswordMedico(userId, nombre, celular) {
    var modal = document.getElementById('modal-asignar-password-medico');
    if (!modal) return;

    var inpUserId = document.getElementById('pass-medico-user-id');
    if (inpUserId) inpUserId.value = userId;

    var elNombre = document.getElementById('pass-medico-nombre');
    if (elNombre) elNombre.textContent = nombre || 'Médico #' + userId;

    var elCelular = document.getElementById('pass-medico-celular');
    if (elCelular) elCelular.textContent = celular ? 'Tel / Usuario: ' + celular : 'Tel / Usuario: No registrado';

    var inpPass = document.getElementById('pass-medico-input');
    if (inpPass) {
        inpPass.value = '';
        inpPass.type = 'password';
    }

    var btnToggle = document.getElementById('btn-toggle-view-pass');
    if (btnToggle) btnToggle.textContent = '👁️';

    modal.classList.add('show');
    setTimeout(function() {
        if (inpPass) inpPass.focus();
    }, 150);
}
window.abrirModalAsignarPasswordMedico = abrirModalAsignarPasswordMedico;

function cerrarModalAsignarPasswordMedico() {
    var modal = document.getElementById('modal-asignar-password-medico');
    if (modal) modal.classList.remove('show');
}
window.cerrarModalAsignarPasswordMedico = cerrarModalAsignarPasswordMedico;

/* ── MÓDULO GESTIÓN DE UNIVERSIDADES ── */
var universidadesCatalogData = [];
var universidadesFilteredData = [];
var currentUniversidadesPage = 1;
var universidadesItemsPerPage = 50;
var universidadesSortCol = 'nombre';
var universidadesSortOrder = 'asc';

function initUniversidadesFlatGrid(forceFetch) {
    var table = document.getElementById('flat-universidades-table');
    if (!table) return;

    if (forceFetch || universidadesCatalogData.length === 0) {
        fetchUniversidadesData();
    } else {
        renderUniversidadesFlatTable(currentUniversidadesPage);
    }
}
window.initUniversidadesFlatGrid = initUniversidadesFlatGrid;
window.fetchUniversidadesData = fetchUniversidadesData;

function fetchUniversidadesData(targetId) {
    var tbody = document.querySelector('#flat-universidades-table tbody');
    if (tbody) {
        tbody.innerHTML = '<tr><td colspan="4" class="text-center txt-muted py-4">⏳ Cargando catálogo de universidades...</td></tr>';
    }

    fetch('/laesh/rc/api/universidades')
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data && data.success && Array.isArray(data.data)) {
                universidadesCatalogData = data.data;
                applyUniversidadesFilterAndSort();

                var targetPage = 1;
                if (targetId) {
                    var targetIdx = universidadesFilteredData.findIndex(function(u) {
                        return String(u.id) === String(targetId);
                    });
                    if (targetIdx !== -1) {
                        targetPage = Math.floor(targetIdx / universidadesItemsPerPage) + 1;
                    }
                }

                renderUniversidadesFlatTable(targetPage, targetId);
                sincronizarSelectUniversidadesUI(universidadesCatalogData);
            } else {
                if (tbody) {
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center txt-danger py-4">⚠️ Error al cargar universidades: ' + (data.error || 'Respuesta inválida') + '</td></tr>';
                }
            }
        })
        .catch(function(err) {
            console.error('Error fetching /api/universidades:', err);
            if (tbody) {
                tbody.innerHTML = '<tr><td colspan="4" class="text-center txt-danger py-4">⚠️ Error de conexión al cargar universidades</td></tr>';
            }
        });
}

function updateUniversidadesSortIcons() {
    var headerNombre = document.getElementById('flat-universidades-sort-nombre');
    if (headerNombre) {
        var iconN = headerNombre.querySelector('.sort-icon');
        var isCurN = (universidadesSortCol === 'nombre');
        headerNombre.setAttribute('data-order', isCurN ? universidadesSortOrder : 'none');
        if (iconN) iconN.textContent = isCurN ? (universidadesSortOrder === 'asc' ? ' ▲' : ' ▼') : '';
    }
}

function applyUniversidadesFilterAndSort() {
    var searchInput = document.getElementById('flat-search-universidades-input');
    var query = searchInput ? searchInput.value.trim().toLowerCase() : '';

    universidadesFilteredData = universidadesCatalogData.filter(function(item) {
        if (!query) return true;
        var nom = (item.nombre || item.valor || '').toLowerCase();
        var idStr = String(item.id || '');
        return nom.includes(query) || idStr.includes(query);
    });

    universidadesFilteredData.sort(function(a, b) {
        if (universidadesSortCol === 'id') {
            var numA = parseInt(a.id || 0, 10);
            var numB = parseInt(b.id || 0, 10);
            return universidadesSortOrder === 'asc' ? numA - numB : numB - numA;
        }
        var valA = (a[universidadesSortCol] || '').toString().toLowerCase();
        var valB = (b[universidadesSortCol] || '').toString().toLowerCase();
        if (valA < valB) return universidadesSortOrder === 'asc' ? -1 : 1;
        if (valA > valB) return universidadesSortOrder === 'asc' ? 1 : -1;
        return 0;
    });

    updateUniversidadesSortIcons();
}

function renderUniversidadesFlatTable(page, targetId) {
    currentUniversidadesPage = page || 1;
    var tbody = document.querySelector('#flat-universidades-table tbody');
    if (!tbody) return;

    var totalRecordsEl = document.getElementById('flat-universidades-total-records');
    if (totalRecordsEl) {
        totalRecordsEl.textContent = 'Total: ' + universidadesFilteredData.length;
    }

    if (universidadesFilteredData.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="text-center txt-muted py-4">No se encontraron universidades.</td></tr>';
        renderUniversidadesPagination(0, 1);
        return;
    }

    var totalPages = Math.ceil(universidadesFilteredData.length / universidadesItemsPerPage);
    if (currentUniversidadesPage > totalPages) currentUniversidadesPage = totalPages;

    var startIdx = (currentUniversidadesPage - 1) * universidadesItemsPerPage;
    var pageItems = universidadesFilteredData.slice(startIdx, startIdx + universidadesItemsPerPage);

    var html = '';
    pageItems.forEach(function(item, idx) {
        var rowNum = startIdx + idx + 1;
        var rowId = item.id;
        var nombre = item.nombre || item.valor || '';
        var totalMedicos = item.total_medicos || 0;

        html += '<tr data-row-id="' + rowId + '" tabindex="0" style="cursor: pointer;" class="universidad-row-item">' +
            '<td style="text-align: center;">' +
                '<a href="#" class="univ-link-edit" data-id="' + rowId + '" style="font-weight: 700; color: var(--primary); text-decoration: underline; font-size: 0.88rem;">' + rowNum + '</a>' +
            '</td>' +
            '<td style="text-align: center; color: #64748b; font-weight: 600;">' + rowId + '</td>' +
            '<td style="font-weight: 700; color: #1e293b;">' + escapeAttrVal(nombre) + '</td>' +
            '<td style="text-align: center;"><span class="badge badge-listos" style="font-size: 0.8rem; font-weight: 600;">' + totalMedicos + ' Médicos</span></td>' +
        '</tr>';
    });

    tbody.innerHTML = html;
    renderUniversidadesPagination(totalPages, currentUniversidadesPage);
    bindUniversidadesTableEvents();

    if (targetId) {
        setTimeout(function() {
            var targetRow = tbody.querySelector('tr[data-row-id="' + targetId + '"]');
            if (targetRow) {
                targetRow.classList.add('row-saved-highlight');
                targetRow.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
                var editLink = targetRow.querySelector('.univ-link-edit');
                if (editLink) editLink.focus();
            }
        }, 120);
    }
}

function renderUniversidadesPagination(totalPages, currentPage) {
    var container = document.getElementById('flat-universidades-pagination');
    if (!container) return;

    if (totalPages <= 1) {
        container.innerHTML = '';
        return;
    }

    var html = '';
    for (var i = 1; i <= totalPages; i++) {
        var activeClass = i === currentPage ? 'btn-primary' : 'btn-secondary';
        html += '<button type="button" class="btn ' + activeClass + ' btn-sm univ-page-btn" data-page="' + i + '" style="padding: 2px 8px; font-size: 0.8rem;">' + i + '</button>';
    }
    container.innerHTML = html;

    container.querySelectorAll('.univ-page-btn').forEach(function(btn) {
        btn.addEventListener('click', function() {
            var page = parseInt(this.getAttribute('data-page'), 10);
            renderUniversidadesFlatTable(page);
        });
    });
}

function bindUniversidadesTableEvents() {
    var tbody = document.querySelector('#flat-universidades-table tbody');
    if (!tbody) return;

    tbody.querySelectorAll('.univ-link-edit').forEach(function(el) {
        el.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var id = this.getAttribute('data-id');
            abrirEditarUniversidadModal(id);
        });
    });

    tbody.querySelectorAll('.universidad-row-item').forEach(function(row) {
        row.addEventListener('dblclick', function() {
            var id = this.getAttribute('data-row-id');
            abrirEditarUniversidadModal(id);
        });
    });
}

function abrirNuevaUniversidadModal() {
    var form = document.getElementById('form-universidad');
    if (form) form.reset();

    var idInput = document.getElementById('univ-id');
    if (idInput) idInput.value = '';

    var title = document.getElementById('modal-universidad-title');
    if (title) title.textContent = 'Registro de Universidad';

    var btnSave = document.getElementById('btn-guardar-universidad');
    if (btnSave) btnSave.textContent = 'Guardar Universidad';

    var m = document.getElementById('modal-universidad');
    if (m) m.classList.add('show');
    document.body.style.overflow = 'hidden';

    var firstInput = document.getElementById('univ-nombre');
    if (firstInput) setTimeout(function() { firstInput.focus(); }, 100);
}
window.abrirNuevaUniversidadModal = abrirNuevaUniversidadModal;

function abrirEditarUniversidadModal(id) {
    var item = universidadesCatalogData.find(function(u) {
        return String(u.id) === String(id);
    });
    if (!item) return;

    var idInput = document.getElementById('univ-id');
    if (idInput) idInput.value = item.id;

    var nombreInput = document.getElementById('univ-nombre');
    if (nombreInput) nombreInput.value = item.nombre || item.valor || '';

    var title = document.getElementById('modal-universidad-title');
    if (title) title.textContent = 'Editar Universidad';

    var btnSave = document.getElementById('btn-guardar-universidad');
    if (btnSave) btnSave.textContent = 'Actualizar Universidad';

    var m = document.getElementById('modal-universidad');
    if (m) m.classList.add('show');
    document.body.style.overflow = 'hidden';

    var firstInput = document.getElementById('univ-nombre');
    if (firstInput) setTimeout(function() { firstInput.focus(); }, 100);
}
window.abrirEditarUniversidadModal = abrirEditarUniversidadModal;

function cerrarModalUniversidad() {
    var m = document.getElementById('modal-universidad');
    if (m) m.classList.remove('show');
    document.body.style.overflow = '';
}
window.cerrarModalUniversidad = cerrarModalUniversidad;

function sincronizarSelectUniversidadesUI(universidadesList) {
    var select = document.getElementById('pm-universidad');
    if (!select) return;
    var currentVal = select.value;
    select.innerHTML = '<option value="" disabled selected>Seleccione una universidad</option>';
    universidadesList.forEach(function(u) {
        var opt = document.createElement('option');
        opt.value = u.id;
        opt.textContent = u.nombre || u.valor || '';
        if (String(u.id) === String(currentVal)) {
            opt.selected = true;
        }
        select.appendChild(opt);
    });
}


/* ── MÓDULO GESTIÓN DE CENTROS DE TRABAJO ── */
var centrosTrabajoCatalogData = [];
var centrosTrabajoFilteredData = [];
var currentCentrosPage = 1;
var centrosItemsPerPage = 50;
var centrosSortCol = 'nombre';
var centrosSortOrder = 'asc';

function initCentrosTrabajoFlatGrid(forceFetch) {
    var table = document.getElementById('flat-centros-table');
    if (!table) return;

    if (forceFetch || centrosTrabajoCatalogData.length === 0) {
        fetchCentrosTrabajoData();
    } else {
        renderCentrosFlatTable(currentCentrosPage);
    }
}
window.initCentrosTrabajoFlatGrid = initCentrosTrabajoFlatGrid;
window.fetchCentrosTrabajoData = fetchCentrosTrabajoData;

function fetchCentrosTrabajoData(targetId) {
    var tbody = document.querySelector('#flat-centros-table tbody');
    if (tbody) {
        tbody.innerHTML = '<tr><td colspan="4" class="text-center txt-muted py-4">⏳ Cargando centros de trabajo...</td></tr>';
    }

    fetch('/laesh/rc/api/centros-trabajo')
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data && data.success && Array.isArray(data.data)) {
                centrosTrabajoCatalogData = data.data;
                applyCentrosFilterAndSort();

                var targetPage = 1;
                if (targetId) {
                    var targetIdx = centrosTrabajoFilteredData.findIndex(function(c) {
                        return String(c.id) === String(targetId);
                    });
                    if (targetIdx !== -1) {
                        targetPage = Math.floor(targetIdx / centrosItemsPerPage) + 1;
                    }
                }

                renderCentrosFlatTable(targetPage, targetId);
                sincronizarSelectCentrosUI(centrosTrabajoCatalogData);
            } else {
                if (tbody) {
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center txt-danger py-4">⚠️ Error al cargar centros de trabajo: ' + (data.error || 'Respuesta inválida') + '</td></tr>';
                }
            }
        })
        .catch(function(err) {
            console.error('Error fetching /api/centros-trabajo:', err);
            if (tbody) {
                tbody.innerHTML = '<tr><td colspan="4" class="text-center txt-danger py-4">⚠️ Error de conexión al cargar centros de trabajo</td></tr>';
            }
        });
}

function updateCentrosSortIcons() {
    var headerNombre = document.getElementById('flat-centros-sort-nombre');
    if (headerNombre) {
        var iconN = headerNombre.querySelector('.sort-icon');
        var isCurN = (centrosSortCol === 'nombre');
        headerNombre.setAttribute('data-order', isCurN ? centrosSortOrder : 'none');
        if (iconN) iconN.textContent = isCurN ? (centrosSortOrder === 'asc' ? ' ▲' : ' ▼') : '';
    }
}

function applyCentrosFilterAndSort() {
    var searchInput = document.getElementById('flat-search-centros-input');
    var query = searchInput ? searchInput.value.trim().toLowerCase() : '';

    centrosTrabajoFilteredData = centrosTrabajoCatalogData.filter(function(item) {
        if (!query) return true;
        var nom = (item.nombre || item.valor || '').toLowerCase();
        var idStr = String(item.id || '');
        return nom.includes(query) || idStr.includes(query);
    });

    centrosTrabajoFilteredData.sort(function(a, b) {
        if (centrosSortCol === 'id') {
            var numA = parseInt(a.id || 0, 10);
            var numB = parseInt(b.id || 0, 10);
            return centrosSortOrder === 'asc' ? numA - numB : numB - numA;
        }
        var valA = (a[centrosSortCol] || '').toString().toLowerCase();
        var valB = (b[centrosSortCol] || '').toString().toLowerCase();
        if (valA < valB) return centrosSortOrder === 'asc' ? -1 : 1;
        if (valA > valB) return centrosSortOrder === 'asc' ? 1 : -1;
        return 0;
    });

    updateCentrosSortIcons();
}

function renderCentrosFlatTable(page, targetId) {
    currentCentrosPage = page || 1;
    var tbody = document.querySelector('#flat-centros-table tbody');
    if (!tbody) return;

    var totalRecordsEl = document.getElementById('flat-centros-total-records');
    if (totalRecordsEl) {
        totalRecordsEl.textContent = 'Total: ' + centrosTrabajoFilteredData.length;
    }

    if (centrosTrabajoFilteredData.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="text-center txt-muted py-4">No se encontraron centros de trabajo.</td></tr>';
        renderCentrosPagination(0, 1);
        return;
    }

    var totalPages = Math.ceil(centrosTrabajoFilteredData.length / centrosItemsPerPage);
    if (currentCentrosPage > totalPages) currentCentrosPage = totalPages;

    var startIdx = (currentCentrosPage - 1) * centrosItemsPerPage;
    var pageItems = centrosTrabajoFilteredData.slice(startIdx, startIdx + centrosItemsPerPage);

    var html = '';
    pageItems.forEach(function(item, idx) {
        var rowNum = startIdx + idx + 1;
        var rowId = item.id;
        var nombre = item.nombre || item.valor || '';
        var totalMedicos = item.total_medicos || 0;

        html += '<tr data-row-id="' + rowId + '" tabindex="0" style="cursor: pointer;" class="centro-row-item">' +
            '<td style="text-align: center;">' +
                '<a href="#" class="centro-link-edit" data-id="' + rowId + '" style="font-weight: 700; color: var(--primary); text-decoration: underline; font-size: 0.88rem;">' + rowNum + '</a>' +
            '</td>' +
            '<td style="text-align: center; color: #64748b; font-weight: 600;">' + rowId + '</td>' +
            '<td style="font-weight: 700; color: #1e293b;">' + escapeAttrVal(nombre) + '</td>' +
            '<td style="text-align: center;"><span class="badge badge-listos" style="font-size: 0.8rem; font-weight: 600;">' + totalMedicos + ' Médicos</span></td>' +
        '</tr>';
    });

    tbody.innerHTML = html;
    renderCentrosPagination(totalPages, currentCentrosPage);
    bindCentrosTableEvents();

    if (targetId) {
        setTimeout(function() {
            var targetRow = tbody.querySelector('tr[data-row-id="' + targetId + '"]');
            if (targetRow) {
                targetRow.classList.add('row-saved-highlight');
                targetRow.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
                var editLink = targetRow.querySelector('.centro-link-edit');
                if (editLink) editLink.focus();
            }
        }, 120);
    }
}

function renderCentrosPagination(totalPages, currentPage) {
    var container = document.getElementById('flat-centros-pagination');
    if (!container) return;

    if (totalPages <= 1) {
        container.innerHTML = '';
        return;
    }

    var html = '';
    for (var i = 1; i <= totalPages; i++) {
        var activeClass = i === currentPage ? 'btn-primary' : 'btn-secondary';
        html += '<button type="button" class="btn ' + activeClass + ' btn-sm centro-page-btn" data-page="' + i + '" style="padding: 2px 8px; font-size: 0.8rem;">' + i + '</button>';
    }
    container.innerHTML = html;

    container.querySelectorAll('.centro-page-btn').forEach(function(btn) {
        btn.addEventListener('click', function() {
            var page = parseInt(this.getAttribute('data-page'), 10);
            renderCentrosFlatTable(page);
        });
    });
}

function bindCentrosTableEvents() {
    var tbody = document.querySelector('#flat-centros-table tbody');
    if (!tbody) return;

    tbody.querySelectorAll('.centro-link-edit').forEach(function(el) {
        el.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var id = this.getAttribute('data-id');
            abrirEditarCentroModal(id);
        });
    });

    tbody.querySelectorAll('.centro-row-item').forEach(function(row) {
        row.addEventListener('dblclick', function() {
            var id = this.getAttribute('data-row-id');
            abrirEditarCentroModal(id);
        });
    });
}

function abrirNuevoCentroModal() {
    var form = document.getElementById('form-centro-trabajo');
    if (form) form.reset();

    var idInput = document.getElementById('centro-id');
    if (idInput) idInput.value = '';

    var title = document.getElementById('modal-centro-title');
    if (title) title.textContent = 'Registro de Centro de Trabajo';

    var btnSave = document.getElementById('btn-guardar-centro');
    if (btnSave) btnSave.textContent = 'Guardar Centro';

    var m = document.getElementById('modal-centro-trabajo');
    if (m) m.classList.add('show');
    document.body.style.overflow = 'hidden';

    var firstInput = document.getElementById('centro-nombre');
    if (firstInput) setTimeout(function() { firstInput.focus(); }, 100);
}
window.abrirNuevoCentroModal = abrirNuevoCentroModal;

function abrirEditarCentroModal(id) {
    var item = centrosTrabajoCatalogData.find(function(c) {
        return String(c.id) === String(id);
    });
    if (!item) return;

    var idInput = document.getElementById('centro-id');
    if (idInput) idInput.value = item.id;

    var nombreInput = document.getElementById('centro-nombre');
    if (nombreInput) nombreInput.value = item.nombre || item.valor || '';

    var title = document.getElementById('modal-centro-title');
    if (title) title.textContent = 'Editar Centro de Trabajo';

    var btnSave = document.getElementById('btn-guardar-centro');
    if (btnSave) btnSave.textContent = 'Actualizar Centro';

    var m = document.getElementById('modal-centro-trabajo');
    if (m) m.classList.add('show');
    document.body.style.overflow = 'hidden';

    var firstInput = document.getElementById('centro-nombre');
    if (firstInput) setTimeout(function() { firstInput.focus(); }, 100);
}
window.abrirEditarCentroModal = abrirEditarCentroModal;

function cerrarModalCentro() {
    var m = document.getElementById('modal-centro-trabajo');
    if (m) m.classList.remove('show');
    document.body.style.overflow = '';
}
window.cerrarModalCentro = cerrarModalCentro;

function sincronizarSelectCentrosUI(centrosList) {
    var select = document.getElementById('pm-lugar');
    if (!select) return;
    var currentVal = select.value;
    select.innerHTML = '<option value="" disabled selected>Seleccione un lugar de trabajo</option>';
    centrosList.forEach(function(c) {
        var opt = document.createElement('option');
        opt.value = c.id;
        opt.textContent = c.nombre || c.valor || '';
        if (String(c.id) === String(currentVal)) {
            opt.selected = true;
        }
        select.appendChild(opt);
    });
}


/* ── REGLAS DE COMPARACIÓN DE CADENAS Y PREVENCIÓN DE DUPLICADOS ── */
function calcularDistanciaLevenshtein(a, b) {
    if (a.length === 0) return b.length;
    if (b.length === 0) return a.length;
    var matrix = [];
    for (var i = 0; i <= b.length; i++) {
        matrix[i] = [i];
    }
    for (var j = 0; j <= a.length; j++) {
        matrix[0][j] = j;
    }
    for (var i = 1; i <= b.length; i++) {
        for (var j = 1; j <= a.length; j++) {
            if (b.charAt(i - 1) === a.charAt(j - 1)) {
                matrix[i][j] = matrix[i - 1][j - 1];
            } else {
                matrix[i][j] = Math.min(
                    matrix[i - 1][j - 1] + 1, // sustitución
                    matrix[i][j - 1] + 1,     // inserción
                    matrix[i - 1][j] + 1      // eliminación
                );
            }
        }
    }
    return matrix[b.length][a.length];
}

function normalizarTextoBusqueda(str) {
    if (!str) return '';
    return str.toString()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "") // quitar acentos
        .toLowerCase()
        .replace(/[^a-z0-9\s]/g, " ")     // quitar signos
        .replace(/\s+/g, " ")             // espacios únicos
        .trim();
}

function buscarPosibleDuplicado(textoIngresado, listaCatalogo, currentId) {
    var normInput = normalizarTextoBusqueda(textoIngresado);
    if (!normInput || normInput.length < 3) return null;

    for (var i = 0; i < listaCatalogo.length; i++) {
        var item = listaCatalogo[i];
        if (currentId && String(item.id) === String(currentId)) {
            continue; // Ignorar el mismo registro si estamos editando
        }
        var itemNom = item.nombre || item.valor || '';
        var normItem = normalizarTextoBusqueda(itemNom);
        if (!normItem) continue;

        // 1. Coincidencia idéntica normalizada
        if (normInput === normItem) {
            return { item: item, nombre: itemNom, similitud: 1.0, razon: 'Coincidencia idéntica' };
        }

        // 2. Subcadena contenida (longitud significativa >= 6)
        if ((normInput.length >= 6 && normItem.includes(normInput)) || 
            (normItem.length >= 6 && normInput.includes(normItem))) {
            return { item: item, nombre: itemNom, similitud: 0.9, razon: 'Nombre contenido en registro existente' };
        }

        // 3. Similitud por Levenshtein
        var dist = calcularDistanciaLevenshtein(normInput, normItem);
        var maxLen = Math.max(normInput.length, normItem.length);
        var similarity = 1 - (dist / maxLen);

        if (dist <= 3 || similarity >= 0.78) {
            return { item: item, nombre: itemNom, similitud: similarity, razon: 'Texto fonéticamente/visualmente muy similar' };
        }
    }
    return null;
}


/* ── DOMContentLoaded INICIALIZACIÓN GLOBAL DE SUBPESTAÑAS Y EVENTOS ── */
document.addEventListener('DOMContentLoaded', function() {
    // 1. Subpestañas en Médicos (Médicos / Universidades / Centros de Trabajo)
    var toggleMedicosView = document.getElementById('toggle-medicos-view');
    if (toggleMedicosView) {
        toggleMedicosView.querySelectorAll('.cms-tab').forEach(function(tabBtn) {
            tabBtn.addEventListener('click', function() {
                var view = this.getAttribute('data-view');
                toggleMedicosView.querySelectorAll('.cms-tab').forEach(function(b) { b.classList.remove('active'); });
                this.classList.add('active');

                var vMed = document.getElementById('view-medicos-table');
                var vUni = document.getElementById('view-universidades-table');
                var vCen = document.getElementById('view-centros-trabajo-table');

                if (vMed) vMed.classList.add('d-none');
                if (vUni) vUni.classList.add('d-none');
                if (vCen) vCen.classList.add('d-none');

                if (view === 'universidades') {
                    if (vUni) vUni.classList.remove('d-none');
                    initUniversidadesFlatGrid();
                } else if (view === 'centros-trabajo') {
                    if (vCen) vCen.classList.remove('d-none');
                    initCentrosTrabajoFlatGrid();
                } else {
                    if (vMed) vMed.classList.remove('d-none');
                    initMedicosFlatGrid();
                }
            });
        });
    }

    // 2. Buscadores y Ordenamientos Médicos
    var searchInputMed = document.getElementById('flat-search-medicos-input');
    if (searchInputMed) {
        searchInputMed.addEventListener('input', function() {
            applyMedicosFilterAndSort();
            renderMedicosFlatTable(1);
        });
    }

    var btnAddMed = document.getElementById('btn-add-medico-row');
    if (btnAddMed) {
        btnAddMed.addEventListener('click', abrirNuevoMedicoModal);
    }

    var sortCedula = document.getElementById('flat-medicos-sort-cedula');
    if (sortCedula) {
        sortCedula.addEventListener('click', function() {
            medicosSortCol = 'cedula_profesional';
            medicosSortOrder = (medicosSortOrder === 'asc') ? 'desc' : 'asc';
            applyMedicosFilterAndSort();
            renderMedicosFlatTable(1);
        });
    }

    var sortNombre = document.getElementById('flat-medicos-sort-nombre');
    if (sortNombre) {
        sortNombre.addEventListener('click', function() {
            medicosSortCol = 'nombre_completo';
            medicosSortOrder = (medicosSortOrder === 'asc') ? 'desc' : 'asc';
            applyMedicosFilterAndSort();
            renderMedicosFlatTable(1);
        });
    }

    // 3. Eventos Universidades
    var searchInputUni = document.getElementById('flat-search-universidades-input');
    if (searchInputUni) {
        searchInputUni.addEventListener('input', function() {
            applyUniversidadesFilterAndSort();
            renderUniversidadesFlatTable(1);
        });
    }

    var btnAddUni = document.getElementById('btn-add-universidad-row');
    if (btnAddUni) {
        btnAddUni.addEventListener('click', abrirNuevaUniversidadModal);
    }

    var sortUniNombre = document.getElementById('flat-universidades-sort-nombre');
    if (sortUniNombre) {
        sortUniNombre.addEventListener('click', function() {
            universidadesSortCol = 'nombre';
            universidadesSortOrder = (universidadesSortOrder === 'asc') ? 'desc' : 'asc';
            applyUniversidadesFilterAndSort();
            renderUniversidadesFlatTable(1);
        });
    }

    var btnCerrarUni = document.getElementById('btn-cerrar-universidad');
    if (btnCerrarUni) btnCerrarUni.addEventListener('click', cerrarModalUniversidad);
    var btnCancUni = document.getElementById('btn-cancelar-universidad');
    if (btnCancUni) btnCancUni.addEventListener('click', cerrarModalUniversidad);

    var formUni = document.getElementById('form-universidad');
    if (formUni) {
        formUni.addEventListener('submit', function(e) {
            e.preventDefault();
            var id = (document.getElementById('univ-id') ? document.getElementById('univ-id').value : '').trim();
            var nombre = (document.getElementById('univ-nombre') ? document.getElementById('univ-nombre').value : '').trim();

            if (!nombre) {
                alert('El nombre de la universidad es obligatorio.');
                return;
            }

            // Regla de comparación y detección de duplicados
            var posibleDuplicado = buscarPosibleDuplicado(nombre, universidadesCatalogData, id);
            if (posibleDuplicado) {
                var mensajeConfirm = '⚠️ ATENCIÓN: Se detectó un posible duplicado en el catálogo.\n\n' +
                                     'Ya existe una Universidad registrada con texto similar:\n' +
                                     '«' + posibleDuplicado.nombre + '»\n\n' +
                                     '¿Estás de acuerdo con guardar este registro?';
                if (!window.confirm(mensajeConfirm)) {
                    // El usuario canceló
                    var inputNom = document.getElementById('univ-nombre');
                    if (inputNom) inputNom.focus();
                    return;
                }
            }

            var btnSave = document.getElementById('btn-guardar-universidad');
            if (btnSave) {
                btnSave.disabled = true;
                btnSave.textContent = 'Guardando...';
            }

            var csrfTokenUni = document.querySelector('input[name="csrf_token"]') ? document.querySelector('input[name="csrf_token"]').value : '';

            fetch('/laesh/rc/api/universidades/guardar', {
                method: 'POST',
                headers: { 
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': csrfTokenUni
                },
                body: JSON.stringify({
                    id: id ? parseInt(id, 10) : null,
                    nombre: nombre,
                    orden: 0,
                    activo: 1,
                    csrf_token: csrfTokenUni
                })
            })
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (btnSave) {
                    btnSave.disabled = false;
                    btnSave.textContent = id ? 'Actualizar Universidad' : 'Guardar Universidad';
                }
                if (data && data.success) {
                    cerrarModalUniversidad();
                    if (typeof window.showToast === 'function') {
                        window.showToast(data.mensaje || 'Universidad guardada con éxito.', 'success');
                    } else {
                        alert('✅ ' + (data.mensaje || 'Universidad guardada con éxito.'));
                    }
                    fetchUniversidadesData(data.id || id);
                } else {
                    alert('⚠️ Error: ' + (data.error || 'No se pudo guardar la universidad.'));
                }
            })
            .catch(function(err) {
                console.error('Error guardando universidad:', err);
                if (btnSave) {
                    btnSave.disabled = false;
                    btnSave.textContent = id ? 'Actualizar Universidad' : 'Guardar Universidad';
                }
                alert('⚠️ Error de red al guardar la universidad.');
            });
        });
    }

    // 4. Eventos Centros de Trabajo
    var searchInputCen = document.getElementById('flat-search-centros-input');
    if (searchInputCen) {
        searchInputCen.addEventListener('input', function() {
            applyCentrosFilterAndSort();
            renderCentrosFlatTable(1);
        });
    }

    var btnAddCen = document.getElementById('btn-add-centro-row');
    if (btnAddCen) {
        btnAddCen.addEventListener('click', abrirNuevoCentroModal);
    }

    var sortCenNombre = document.getElementById('flat-centros-sort-nombre');
    if (sortCenNombre) {
        sortCenNombre.addEventListener('click', function() {
            centrosSortCol = 'nombre';
            centrosSortOrder = (centrosSortOrder === 'asc') ? 'desc' : 'asc';
            applyCentrosFilterAndSort();
            renderCentrosFlatTable(1);
        });
    }

    var btnCerrarCen = document.getElementById('btn-cerrar-centro');
    if (btnCerrarCen) btnCerrarCen.addEventListener('click', cerrarModalCentro);
    var btnCancCen = document.getElementById('btn-cancelar-centro');
    if (btnCancCen) btnCancCen.addEventListener('click', cerrarModalCentro);

    var formCen = document.getElementById('form-centro-trabajo');
    if (formCen) {
        formCen.addEventListener('submit', function(e) {
            e.preventDefault();
            var id = (document.getElementById('centro-id') ? document.getElementById('centro-id').value : '').trim();
            var nombre = (document.getElementById('centro-nombre') ? document.getElementById('centro-nombre').value : '').trim();

            if (!nombre) {
                alert('El nombre del centro de trabajo es obligatorio.');
                return;
            }

            // Regla de comparación y detección de duplicados
            var posibleDuplicado = buscarPosibleDuplicado(nombre, centrosTrabajoCatalogData, id);
            if (posibleDuplicado) {
                var mensajeConfirm = '⚠️ ATENCIÓN: Se detectó un posible duplicado en el catálogo.\n\n' +
                                     'Ya existe un Centro de Trabajo registrado con texto similar:\n' +
                                     '«' + posibleDuplicado.nombre + '»\n\n' +
                                     '¿Estás de acuerdo con guardar este registro?';
                if (!window.confirm(mensajeConfirm)) {
                    // El usuario canceló
                    var inputNom = document.getElementById('centro-nombre');
                    if (inputNom) inputNom.focus();
                    return;
                }
            }

            var btnSave = document.getElementById('btn-guardar-centro');
            if (btnSave) {
                btnSave.disabled = true;
                btnSave.textContent = 'Guardando...';
            }

            var csrfTokenCen = document.querySelector('input[name="csrf_token"]') ? document.querySelector('input[name="csrf_token"]').value : '';

            fetch('/laesh/rc/api/centros-trabajo/guardar', {
                method: 'POST',
                headers: { 
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': csrfTokenCen
                },
                body: JSON.stringify({
                    id: id ? parseInt(id, 10) : null,
                    nombre: nombre,
                    orden: 0,
                    activo: 1,
                    csrf_token: csrfTokenCen
                })
            })
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (btnSave) {
                    btnSave.disabled = false;
                    btnSave.textContent = id ? 'Actualizar Centro' : 'Guardar Centro';
                }
                if (data && data.success) {
                    cerrarModalCentro();
                    if (typeof window.showToast === 'function') {
                        window.showToast(data.mensaje || 'Centro de trabajo guardado con éxito.', 'success');
                    } else {
                        alert('✅ ' + (data.mensaje || 'Centro de trabajo guardado con éxito.'));
                    }
                    fetchCentrosTrabajoData(data.id || id);
                } else {
                    alert('⚠️ Error: ' + (data.error || 'No se pudo guardar el centro de trabajo.'));
                }
            })
            .catch(function(err) {
                console.error('Error guardando centro de trabajo:', err);
                if (btnSave) {
                    btnSave.disabled = false;
                    btnSave.textContent = id ? 'Actualizar Centro' : 'Guardar Centro';
                }
                alert('⚠️ Error de red al guardar el centro de trabajo.');
            });
        });
    }

    // 5. Eventos Modal Asignar Contraseña a Médico
    var btnCerrarPass = document.getElementById('btn-cerrar-pass-medico');
    if (btnCerrarPass) btnCerrarPass.addEventListener('click', cerrarModalAsignarPasswordMedico);

    var btnCancPass = document.getElementById('btn-cancelar-pass-medico');
    if (btnCancPass) btnCancPass.addEventListener('click', cerrarModalAsignarPasswordMedico);

    var btnToggleViewPass = document.getElementById('btn-toggle-view-pass');
    if (btnToggleViewPass) {
        btnToggleViewPass.addEventListener('click', function(e) {
            e.preventDefault();
            var inp = document.getElementById('pass-medico-input');
            if (!inp) return;
            if (inp.type === 'password') {
                inp.type = 'text';
                this.textContent = '🔒';
            } else {
                inp.type = 'password';
                this.textContent = '👁️';
            }
        });
    }

    var formPassMedico = document.getElementById('form-asignar-password-medico');
    if (formPassMedico) {
        formPassMedico.addEventListener('submit', function(e) {
            e.preventDefault();
            var targetUserId = (document.getElementById('pass-medico-user-id') ? document.getElementById('pass-medico-user-id').value : '').trim();
            var newPassword = (document.getElementById('pass-medico-input') ? document.getElementById('pass-medico-input').value : '').trim();

            if (!targetUserId) {
                alert('ID de médico inválido.');
                return;
            }
            if (!newPassword || newPassword.length < 8) {
                alert('La nueva contraseña debe contener al menos 8 caracteres.');
                var inp = document.getElementById('pass-medico-input');
                if (inp) inp.focus();
                return;
            }

            var btnSave = document.getElementById('btn-guardar-pass-medico');
            if (btnSave) {
                btnSave.disabled = true;
                btnSave.textContent = 'Guardando...';
            }

            var csrfToken = document.querySelector('input[name="csrf_token"]') ? document.querySelector('input[name="csrf_token"]').value : '';
            var params = new URLSearchParams();
            params.append('target_user_id', targetUserId);
            params.append('new_password', newPassword);
            params.append('csrf_token', csrfToken);

            fetch('/laesh/rc/api/medicos/asignar-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: params.toString()
            })
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (btnSave) {
                    btnSave.disabled = false;
                    btnSave.textContent = 'Guardar Contraseña';
                }
                if (data && data.success) {
                    cerrarModalAsignarPasswordMedico();
                    if (typeof window.showToast === 'function') {
                        window.showToast(data.mensaje || 'Contraseña asignada correctamente.', 'success');
                    } else {
                        alert('✅ ' + (data.mensaje || 'Contraseña asignada correctamente.'));
                    }
                    // Resaltar la fila modificada
                    var row = document.querySelector('#flat-medicos-table tr[data-row-id="' + targetUserId + '"]');
                    if (row) {
                        row.classList.add('row-saved-highlight');
                        row.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
                    }
                } else {
                    var errMsg = (data && data.error) ? data.error : 'No se pudo asignar la contraseña.';
                    if (typeof window.showToast === 'function') {
                        window.showToast('⚠️ ' + errMsg, 'error');
                    } else {
                        alert('⚠️ ' + errMsg);
                    }
                }
            })
            .catch(function(err) {
                console.error('Error asignando contraseña de médico:', err);
                if (btnSave) {
                    btnSave.disabled = false;
                    btnSave.textContent = 'Guardar Contraseña';
                }
                if (typeof window.showToast === 'function') {
                    window.showToast('⚠️ Error de red al asignar la contraseña.', 'error');
                } else {
                    alert('⚠️ Error de red al asignar la contraseña.');
                }
            });
        });
    }

    // 6. Inicialización si panel-medicos está abierto al cargar
    var panelMed = document.getElementById('panel-medicos');
    if (panelMed && window.getComputedStyle(panelMed).display !== 'none' && !panelMed.classList.contains('d-none')) {
        initMedicosFlatGrid();
    }
});


