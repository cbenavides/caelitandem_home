/* ── MÓDULO CONSTRUCTOR DE CATÁLOGOS (Abanicos Jerárquicos) ── */
document.addEventListener('DOMContentLoaded', function() {

    var btnViewTable = document.getElementById('btn-view-table');
    var btnViewSettings = document.getElementById('btn-view-settings');
    var viewSettings = document.getElementById('view-catalog-settings');
    var viewTable = document.getElementById('view-catalog-table');

    // Panel base
    var panelCatalogos = document.getElementById('panel-catalogos');
    if (!viewTable && !panelCatalogos) return;

    var flatSearchContainer = document.getElementById('flat-search-container');
    var settingsMenuContainer = document.getElementById('settings-menu-container');
    var flatPagination = document.getElementById('flat-pagination');

    function resetActiveButtons() {
        if (btnViewTable) btnViewTable.classList.remove('active');
        if (btnViewSettings) btnViewSettings.classList.remove('active');
        if (menuGabinetes) menuGabinetes.classList.remove('active');
        if (menuIGabinetes) menuIGabinetes.classList.remove('active');
        if (menu20EstMed) menu20EstMed.classList.remove('active');
    }

    function hideAllViews() {
        if (viewTable) viewTable.classList.add('d-none');
        if (viewSettings) viewSettings.classList.add('d-none');

        if (flatSearchContainer) flatSearchContainer.style.display = 'none';
        if (settingsMenuContainer) settingsMenuContainer.style.display = 'none';
        if (flatPagination) flatPagination.style.display = 'none';
        var flatPagWrap = document.getElementById('flat-pagination-wrap');
        if (flatPagWrap) flatPagWrap.style.display = 'none';
    }

    if (btnViewTable) {
        btnViewTable.addEventListener('click', function() {
            hideAllViews();
            resetActiveButtons();
            if (viewTable) viewTable.classList.remove('d-none');
            btnViewTable.classList.add('active');

            if (flatSearchContainer) flatSearchContainer.style.display = 'flex';
            var flatPagWrap = document.getElementById('flat-pagination-wrap');
            if (flatPagWrap) flatPagWrap.style.display = 'flex';

            if (flatPagination && flatCatalog.length > 0 && Math.ceil(flatCatalog.length / flatItemsPerPage) > 1) {
                flatPagination.style.display = 'flex';
            }
            var flatActions = document.getElementById('flat-table-actions');
            if (flatActions) flatActions.style.display = 'flex';
            if (flatCatalog.length === 0 && catalogTree.length > 0) {
                flattenCatalogTree();
            }
            if (typeof renderFlatTable === 'function') {
                renderFlatTable(currentFlatPage || 1);
            }
        });
    }

    // --- Navigation Settings Submenu ---
    var menu20EstMed = document.getElementById('menu-20estmed');
    var menuGabinetes = document.getElementById('menu-gabinetes');
    var menuIGabinetes = document.getElementById('menu-igabinetes');
    var view20EstMed = document.getElementById('settings-20estmed-view');
    var viewGabinetes = document.getElementById('settings-gabinetes-view');
    var viewIGabinetes = document.getElementById('settings-igabinetes-view');

    function resetSettingsMenu() {
        if(view20EstMed) view20EstMed.style.display = 'none';
        if(viewGabinetes) viewGabinetes.style.display = 'none';
        if(viewIGabinetes) viewIGabinetes.style.display = 'none';
    }

    /* ── Lectura EN VIVO para las 3 pestañas de config admin (2026-09-18) ──────
       Corrección de raíz: estas pestañas editan sobre MariaDB (Tabla 11), por lo
       que su LECTURA inicial también debe ser en vivo, no desde catalog-compiled.js
       (artefacto de publicación pensado para Médicos). Se asigna la respuesta a las
       mismas variables window.laesh* que ya consume el árbol de render existente,
       para no tocar renderGabinetesList()/renderIGabinetesList()/populate20EstMedTags(). */
    function fetchLiveAndRender(url, assign, renderFn) {
        fetch(url, { credentials: 'same-origin' })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data && data.success) assign(data);
                if (typeof renderFn === 'function') renderFn();
            })
            .catch(function() {
                // Fallback: si el endpoint live falla (red, 5xx), pintar con lo que
                // ya haya en memoria (window.laesh* del último catalog-compiled.js)
                // en vez de dejar la pestaña vacía.
                if (typeof renderFn === 'function') renderFn();
            });
    }

    if (menu20EstMed) {
        menu20EstMed.addEventListener('click', function(e) {
            e.preventDefault();
            hideAllViews();
            resetActiveButtons();
            resetSettingsMenu();
            if (viewSettings) viewSettings.classList.remove('d-none');
            menu20EstMed.classList.add('active');
            if(view20EstMed) view20EstMed.style.display = 'flex';
            fetchLiveAndRender('/laesh/rc/api/catalog/top20', function(data) {
                window.laeshTop20EstMed = data.top20 || [];
            }, populate20EstMedTags);
        });
    }

    if (menuGabinetes) {
        menuGabinetes.addEventListener('click', function(e) {
            e.preventDefault();
            hideAllViews();
            resetActiveButtons();
            resetSettingsMenu();
            if (viewSettings) viewSettings.classList.remove('d-none');
            menuGabinetes.classList.add('active');
            if(viewGabinetes) viewGabinetes.style.display = 'grid';
            fetchLiveAndRender('/laesh/rc/api/catalog/gabinetes', function(data) {
                window.laeshGabinetes = data.gabinetes || [];
                window.laeshSubgabinetes = data.subgabinetes || [];
                window.laeshEstudioGabinete = data.estudioGabinete || [];
            }, renderGabinetesList);
        });
    }

    if (menuIGabinetes) {
        menuIGabinetes.addEventListener('click', function(e) {
            e.preventDefault();
            hideAllViews();
            resetActiveButtons();
            resetSettingsMenu();
            if (viewSettings) viewSettings.classList.remove('d-none');
            menuIGabinetes.classList.add('active');
            if(viewIGabinetes) viewIGabinetes.style.display = 'grid';
            fetchLiveAndRender('/laesh/rc/api/catalog/igabinetes', function(data) {
                window.laeshIGabinetes = data.igabinetes || [];
                window.laeshIGabineteVinculos = data.vinculos || [];
            }, renderIGabinetesList);
        });
    }

    if (btnViewSettings) {
        btnViewSettings.addEventListener('click', function() {
            hideAllViews();
            resetActiveButtons();
            if (viewSettings) viewSettings.classList.remove('d-none');
            btnViewSettings.classList.add('active');
            
            if (settingsMenuContainer) settingsMenuContainer.style.display = 'flex';
            
            // Force Gabinetes as default tab
            if (menuGabinetes) menuGabinetes.click();
            
            // Reset Gabinetes UI state when entering settings
            var panelB = document.getElementById('panel-gabinetes-b');
            var panelCD = document.getElementById('panel-cd-container');
            if (panelB) panelB.style.display = 'none';
            if (panelCD) panelCD.style.display = 'none';
            
            var allCheckboxes = document.querySelectorAll('.chk-activar-paneles');
            allCheckboxes.forEach(function(chk) { chk.checked = false; });
            
            // Si el flatCatalog no está inicializado, aplanarlo
            if (!flatCatalog || flatCatalog.length === 0) {
                if (catalogTree && catalogTree.length > 0) flattenCatalogTree();
            }
            
            var allIcons = document.querySelectorAll('.action-icon');
            allIcons.forEach(function(icon) { icon.classList.remove('active'); });
        });
    }

    var catalogTree = [];
    // Flat Table variables
    var flatCatalog = [];
    var currentFlatPage = 1;
    var flatItemsPerPage = 100;
    var flatOriginalCells = new Map();
    var flatAddedRows = new Set();
    
    var isFlatTableEditMode = false;
    function updateUndoRedoUI() {}
    
    function updateFlatModifiedUI() {
        var modSep = document.getElementById('flat-separator');
        var btnSave = document.getElementById('btn-save-flat-table');
        
        var modifiedRows = new Set(flatAddedRows);
        flatOriginalCells.forEach(function(origVal, key) {
            var parts = key.split(':');
            var rowId = parts[0];
            var col = parts[1];
            var itemIndex = flatCatalog.findIndex(function(c, idx) { return String(c.id || (c.clave + '-' + idx)) === String(rowId); });
            if (itemIndex > -1) {
                var currentVal = flatCatalog[itemIndex][col] || '';
                if (currentVal !== origVal) {
                    modifiedRows.add(rowId);
                }
            }
        });
        
        var totalMods = modifiedRows.size;
        
        if (modSep) modSep.style.display = totalMods > 0 ? 'inline' : 'none';
        if (btnSave) btnSave.style.display = (totalMods > 0 || isFlatTableEditMode) ? 'inline-block' : 'none';
    }

    window.loadCatalogTree = function() {
        // Ruta rápida: catalog-compiled.js (generado por CatalogBuilder::build(),
        // cargado antes que este script) ya deja window.laeshCatalogData/
        // laeshFlatCatalog listos en memoria — evita un round-trip de red.
        if (typeof window.laeshCatalogData !== 'undefined' && Array.isArray(window.laeshCatalogData) && window.laeshCatalogData.length > 0) {
            catalogTree = window.laeshCatalogData;
            if (typeof window.laeshFlatCatalog !== 'undefined' && Array.isArray(window.laeshFlatCatalog) && window.laeshFlatCatalog.length > 0) {
                flatCatalog = window.laeshFlatCatalog;
            } else {
                flattenCatalogTree();
            }
            window.catalogTreeLoaded = true;
            if (typeof renderFlatTable === 'function') {
                renderFlatTable(1);
            }
            if (typeof window.location !== 'undefined' && window.location.hash === '#tabla' && btnViewTable) {
                setTimeout(function() { btnViewTable.click(); }, 50);
            }
            return;
        }

        fetch('/laesh/rc/api/catalogos', {
            headers: { 'Accept': 'application/json' }
        })
        .then(res => res.json())
        .then(data => {
            catalogTree = data;
            window.catalogTreeLoaded = true;
            flattenCatalogTree();
            if (typeof renderFlatTable === 'function') {
                renderFlatTable(1);
            }
            if (typeof window.location !== 'undefined' && window.location.hash === '#tabla' && btnViewTable) {
                setTimeout(function() { btnViewTable.click(); }, 50);
            }
        })
        .catch(err => {
            console.error('Error cargando catálogo jerárquico:', err);
            if(window.showToast) showToast('Error cargando catálogo', 'error');
        });
    }

    // Cargar el catálogo (jerárquico → aplanado) al entrar al panel
    if (!window.catalogTreeLoaded) {
        window.loadCatalogTree();
    }

    // ==========================================
    // FLAT TABLE LOGIC
    // ==========================================
    var currentSortCol = 'nombre';
    var currentSortDir = 'asc';

    function flattenCatalogTree() {
        flatCatalog = [];
        catalogTree.forEach(function(grupo, gIdx) {
            if (!grupo.categorias) return;
            grupo.categorias.forEach(function(cat, cIdx) {
                if (!cat.estudios) return;
                cat.estudios.forEach(function(item, eIdx) {
                    flatCatalog.push({
                        ...item,
                        grupoNombre: grupo.titulo,
                        categoriaNombre: cat.nombre,
                        gIdx: gIdx,
                        cIdx: cIdx,
                        eIdx: eIdx
                    });
                });
            });
        });
        sortFlatCatalog();
    }

    function sortFlatCatalog() {
        flatCatalog.sort(function(a, b) {
            var valA = String(a[currentSortCol] || '');
            var valB = String(b[currentSortCol] || '');
            var cmp = valA.localeCompare(valB, undefined, { numeric: true, sensitivity: 'base' });
            return currentSortDir === 'asc' ? cmp : -cmp;
        });
        updateSortIcons();
    }

    function updateSortIcons() {
        var elSortClave = document.getElementById('flat-sort-clave');
        var elSortNombre = document.getElementById('flat-sort-nombre');
        var elSortGrupo = document.getElementById('flat-sort-grupo');
        if (elSortClave) {
            var iconC = elSortClave.querySelector('.sort-icon');
            var isCurC = (currentSortCol === 'clave');
            elSortClave.setAttribute('data-order', isCurC ? currentSortDir : 'none');
            if (iconC) iconC.textContent = isCurC ? (currentSortDir === 'asc' ? ' ▲' : ' ▼') : '';
        }
        if (elSortNombre) {
            var iconN = elSortNombre.querySelector('.sort-icon');
            var isCurN = (currentSortCol === 'nombre');
            elSortNombre.setAttribute('data-order', isCurN ? currentSortDir : 'none');
            if (iconN) iconN.textContent = isCurN ? (currentSortDir === 'asc' ? ' ▲' : ' ▼') : '';
        }
        if (elSortGrupo) {
            var iconG = elSortGrupo.querySelector('.sort-icon');
            var isCurG = (currentSortCol === 'categoriaNombre');
            elSortGrupo.setAttribute('data-order', isCurG ? currentSortDir : 'none');
            if (iconG) iconG.textContent = isCurG ? (currentSortDir === 'asc' ? ' ▲' : ' ▼') : '';
        }
    }

    var btnSortClave = document.getElementById('flat-sort-clave');
    if (btnSortClave) {
        btnSortClave.addEventListener('click', function() {
            if (currentSortCol === 'clave') {
                currentSortDir = currentSortDir === 'asc' ? 'desc' : 'asc';
            } else {
                currentSortCol = 'clave';
                currentSortDir = 'asc';
            }
            sortFlatCatalog();
            renderFlatTable(1);
        });
    }

    var btnSortNombre = document.getElementById('flat-sort-nombre');
    if (btnSortNombre) {
        btnSortNombre.addEventListener('click', function() {
            if (currentSortCol === 'nombre') {
                currentSortDir = currentSortDir === 'asc' ? 'desc' : 'asc';
            } else {
                currentSortCol = 'nombre';
                currentSortDir = 'asc';
            }
            sortFlatCatalog();
            renderFlatTable(1);
        });
    }

    var btnSortGrupo = document.getElementById('flat-sort-grupo');
    if (btnSortGrupo) {
        btnSortGrupo.addEventListener('click', function() {
            if (currentSortCol === 'categoriaNombre') {
                currentSortDir = currentSortDir === 'asc' ? 'desc' : 'asc';
            } else {
                currentSortCol = 'categoriaNombre';
                currentSortDir = 'asc';
            }
            sortFlatCatalog();
            renderFlatTable(1);
        });
    }

    function openEditEstudioModal(study) {
        var modal = document.getElementById('modal-estudio');
        if (!modal) return;
        
        var isNewRow = !study || !study.id || (typeof flatAddedRows !== 'undefined' && (flatAddedRows.has(study.id) || flatAddedRows.has(String(study.id)) || flatAddedRows.has(Number(study.id)))) || String(study ? study.id : '').startsWith('new-');
        var isExistingStudy = !isNewRow;
        
        var title = document.getElementById('modal-estudio-titulo');
        if (title) title.textContent = isExistingStudy ? 'Editar Estudio Clínico' : 'Nuevo Estudio Clínico';
        
        var idOrig = document.getElementById('estudio-id-original');
        if (idOrig) idOrig.value = study ? (study.id || '') : '';
        
        var clave = document.getElementById('estudio-clave');
        if (clave) {
            clave.value = study ? (study.clave || '') : '';
            clave.style.borderColor = '';
            if (isExistingStudy) {
                clave.readOnly = true;
                clave.style.backgroundColor = 'var(--bg-card, #f1f5f9)';
                clave.style.cursor = 'not-allowed';
            } else {
                clave.readOnly = false;
                clave.style.backgroundColor = '';
                clave.style.cursor = '';
            }
        }

        var nombre = document.getElementById('estudio-nombre');
        if (nombre) nombre.value = study ? (study.nombre || '') : '';

        var muestra = document.getElementById('estudio-muestra');
        if (muestra) muestra.value = study ? (study.muestra || '') : '';

        var contenedor = document.getElementById('estudio-contenedor');
        if (contenedor) contenedor.value = study ? (study.contenedor || '') : '';

        var tiempo = document.getElementById('estudio-tiempo');
        if (tiempo) tiempo.value = study ? (study.tiempo || '') : '';

        var catSelect = document.getElementById('estudio-categoria');
        if (catSelect) {
            catSelect.innerHTML = '';
            var catSet = new Set();

            if (Array.isArray(window.laeshCatalogData) && window.laeshCatalogData[0] && Array.isArray(window.laeshCatalogData[0].categorias)) {
                window.laeshCatalogData[0].categorias.forEach(function(c) {
                    if (c && c.nombre) catSet.add(String(c.nombre).trim());
                });
            }

            if (Array.isArray(catalogTree)) {
                catalogTree.forEach(function(c) {
                    if (c && c.nombre) catSet.add(String(c.nombre).trim());
                    if (c && Array.isArray(c.categorias)) {
                        c.categorias.forEach(function(subC) {
                            if (subC && subC.nombre) catSet.add(String(subC.nombre).trim());
                        });
                    }
                });
            }

            if (Array.isArray(flatCatalog)) {
                flatCatalog.forEach(function(item) {
                    if (item && item.categoriaNombre) catSet.add(String(item.categoriaNombre).trim());
                });
            }

            var categories = Array.from(catSet).filter(Boolean);
            var targetCat = study ? String(study.categoriaNombre || study.grupoNombre || '').trim() : '';
            if (targetCat && !categories.some(function(c) { return String(c || '').toLowerCase() === targetCat.toLowerCase(); })) {
                categories.push(targetCat);
            }

            var defaultOpt = document.createElement('option');
            defaultOpt.value = '';
            defaultOpt.textContent = '-- Seleccionar grupo o área --';
            defaultOpt.disabled = true;
            if (!targetCat) {
                defaultOpt.selected = true;
            }
            catSelect.appendChild(defaultOpt);

            categories.forEach(function(catName) {
                var opt = document.createElement('option');
                opt.value = catName;
                opt.textContent = catName;
                if (targetCat && String(catName || '').toLowerCase() === targetCat.toLowerCase()) {
                    opt.selected = true;
                }
                catSelect.appendChild(opt);
            });

            if (!targetCat) {
                catSelect.value = '';
            } else {
                for (var i = 0; i < catSelect.options.length; i++) {
                    if (String(catSelect.options[i].value || '').toLowerCase() === targetCat.toLowerCase()) {
                        catSelect.selectedIndex = i;
                        break;
                    }
                }
            }
        }

        var prep = document.getElementById('estudio-preparacion');
        if (prep) prep.value = study ? (typeof study.preparacion === 'string' ? study.preparacion : '') : '';

        var pruebas = document.getElementById('estudio-pruebas-incluidas');
        if (pruebas) {
            if (study && Array.isArray(study.pruebas_incluidas)) {
                pruebas.value = study.pruebas_incluidas.join('\n');
            } else if (study && typeof study.pruebas_incluidas === 'string') {
                pruebas.value = study.pruebas_incluidas;
            } else {
                pruebas.value = '';
            }
        }



        modal.style.display = 'block';
    }

    var btnCerrarEstudio = document.getElementById('btn-cerrar-estudio');
    var btnCancelarEstudio = document.getElementById('btn-cancelar-estudio');
    if (btnCerrarEstudio) btnCerrarEstudio.addEventListener('click', function() {
        var modal = document.getElementById('modal-estudio');
        if (modal) modal.style.display = 'none';
    });
    if (btnCancelarEstudio) btnCancelarEstudio.addEventListener('click', function() {
        var modal = document.getElementById('modal-estudio');
        if (modal) modal.style.display = 'none';
    });

    var formEstudio = document.getElementById('form-estudio');
    if (formEstudio) {
        formEstudio.addEventListener('submit', function(e) {
            e.preventDefault();
            var origId = document.getElementById('estudio-id-original').value;
            var claveVal = (document.getElementById('estudio-clave').value || '').trim();
            var nombreVal = (document.getElementById('estudio-nombre').value || '').trim();
            var muestraVal = (document.getElementById('estudio-muestra').value || '').trim();
            var contenedorVal = document.getElementById('estudio-contenedor') ? (document.getElementById('estudio-contenedor').value || '').trim() : '';
            var tiempoVal = (document.getElementById('estudio-tiempo').value || '').trim();
            var catVal = document.getElementById('estudio-categoria').value;
            var prepVal = (document.getElementById('estudio-preparacion').value || '').trim();
            var pruebasRaw = document.getElementById('estudio-pruebas-incluidas') ? (document.getElementById('estudio-pruebas-incluidas').value || '').trim() : '';
            var pruebasArr = pruebasRaw ? pruebasRaw.split('\n').map(s => s.trim()).filter(s => s !== '') : [];

            // 1. Prevenir duplicado de Clave (case-insensitive check en todo flatCatalog)
            if (claveVal) {
                var duplicate = flatCatalog.find(function(item) {
                    if (!item || !item.clave) return false;
                    var sameClave = String(item.clave).trim().toLowerCase() === claveVal.toLowerCase();
                    var isSelf = (origId && String(item.id) === String(origId));
                    return sameClave && !isSelf;
                });
                if (duplicate) {
                    var claveInput = document.getElementById('estudio-clave');
                    if (claveInput) {
                        claveInput.focus();
                        claveInput.style.borderColor = '#ef4444';
                    }
                    var dupMsg = 'La Clave de Estudio "' + claveVal + '" ya existe para "' + (duplicate.nombre || 'otro estudio') + '". Por favor ingresa una clave única.';
                    if (window.showToast) showToast(dupMsg, 'warn');
                    else alert(dupMsg);
                    return;
                }
            }

            var isTempRow = !origId || String(origId).startsWith('new-') || (typeof flatAddedRows !== 'undefined' && (flatAddedRows.has(origId) || flatAddedRows.has(String(origId)) || flatAddedRows.has(Number(origId))));
            var targetRowId = origId;
            var payload = null;

            if (isTempRow) {
                // Caso A: Renglón nuevo o temporal en flatAddedRows
                var itemToSync = null;
                if (origId) {
                    var item = flatCatalog.find(function(c) { return String(c.id) === String(origId); });
                    if (item) {
                        item.clave = claveVal;
                        item.nombre = nombreVal;
                        item.muestra = muestraVal;
                        item.contenedor = contenedorVal;
                        item.tiempo = tiempoVal;
                        item.preparacion = prepVal;
                        item.pruebas_incluidas = pruebasArr;
                        item.categoriaNombre = catVal;
                        itemToSync = item;
                    }
                    flatAddedRows.add(origId);
                } else {
                    var newId = 'new-' + Date.now();
                    targetRowId = newId;
                    var newItem = {
                        id: newId,
                        clave: claveVal,
                        nombre: nombreVal,
                        categoriaNombre: catVal,
                        tiempo: tiempoVal,
                        muestra: muestraVal,
                        contenedor: contenedorVal,
                        preparacion: prepVal,
                        pruebas_incluidas: pruebasArr
                    };
                    flatCatalog.push(newItem);
                    flatAddedRows.add(newId);
                    itemToSync = newItem;
                }
                
                if (itemToSync) {
                    payload = { adds: [itemToSync] };
                }
                updateFlatModifiedUI();
            } else {
                // Caso B: Estudio persistido previamente en MariaDB
                var item = flatCatalog.find(function(c) { return String(c.id) === String(origId); });
                if (item) {
                    var fieldsToUpdate = {
                        clave: claveVal,
                        nombre: nombreVal,
                        muestra: muestraVal,
                        contenedor: contenedorVal,
                        tiempo: tiempoVal,
                        preparacion: prepVal,
                        pruebas_incluidas: pruebasArr,
                        categoriaNombre: catVal
                    };
                    Object.keys(fieldsToUpdate).forEach(function(c) {
                        var key = origId + ':' + c;
                        if (!flatOriginalCells.has(key)) {
                            flatOriginalCells.set(key, item[c] || '');
                        }
                        item[c] = fieldsToUpdate[c];
                    });

                    updateFlatModifiedUI();

                    payload = {
                        updates: [
                            { id: origId, col: 'clave', val: claveVal },
                            { id: origId, col: 'nombre', val: nombreVal },
                            { id: origId, col: 'muestra', val: muestraVal },
                            { id: origId, col: 'contenedor', val: contenedorVal },
                            { id: origId, col: 'tiempo', val: tiempoVal },
                            { id: origId, col: 'categoriaNombre', val: catVal },
                            { id: origId, col: 'preparacion', val: prepVal },
                            { id: origId, col: 'pruebas_incluidas', val: pruebasRaw }
                        ]
                    };
                }
            }

            var modal = document.getElementById('modal-estudio');
            if (modal) modal.style.display = 'none';

            if (payload) {
                syncCatalogPart('/api/catalog/sync', payload)
                    .then(function() {
                        if (isTempRow) {
                            if (targetRowId) flatAddedRows.delete(targetRowId);
                        } else {
                            // Limpiar tracking de modificaciones para este registro
                            Object.keys(fieldsToUpdate).forEach(function(c) {
                                flatOriginalCells.delete(origId + ':' + c);
                            });
                        }
                        updateFlatModifiedUI();
                        if (window.showToast) showToast('Estudio guardado exitosamente.', 'success');
                        
                        // Recargar la tabla si era nuevo para obtener el ID real de la BD
                        if (isTempRow) {
                            loadCatalogTree(); 
                        }
                    })
                    .catch(function(err) { 
                        console.error('Error al sincronizar estudio:', err); 
                        // Si falla, revertimos el estado de "limpieza" para que el usuario pueda reintentar con el botón global
                        if (isTempRow && targetRowId) flatAddedRows.add(targetRowId);
                        updateFlatModifiedUI();
                    });
            }

            if (isTempRow) {
                var targetPage = Math.ceil(flatCatalog.length / flatItemsPerPage) || 1;
                renderFlatTable(targetPage);

                setTimeout(function() {
                    var tbody = document.querySelector('#flat-catalog-table tbody');
                    if (tbody) {
                        var newRow = tbody.querySelector('tr[data-id="' + targetRowId + '"]');
                        if (!newRow) {
                            var rows = tbody.querySelectorAll('tr');
                            if (rows.length > 0) newRow = rows[rows.length - 1];
                        }
                        if (newRow) {
                            newRow.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            var btnEditRow = newRow.querySelector('.btn-edit-row-modal') || newRow.querySelector('.editable-cell') || newRow;
                            if (btnEditRow && typeof btnEditRow.focus === 'function') {
                                btnEditRow.focus();
                            }
                        }
                    }
                }, 120);
            } else {
                renderFlatTable(currentFlatPage || 1);
            }
        });
    }

    function renderFlatTable(page) {
        currentFlatPage = page;
        var tbody = document.querySelector('#flat-catalog-table tbody');
        if (!tbody) return;
        tbody.innerHTML = '';
        
        var total = flatCatalog.length;
        var totalLabel = document.getElementById('flat-total-records');
        if (totalLabel) totalLabel.textContent = 'Total: ' + total;
        
        var start = (page - 1) * flatItemsPerPage;
        var end = Math.min(start + flatItemsPerPage, total);
        
        for (var i = start; i < end; i++) {
            var item = flatCatalog[i];
            var tr = document.createElement('tr');
            var rowId = String(item.id || (item.clave + '-' + i));
            tr.setAttribute('data-id', rowId);
            
            var rowBg = (i % 2 === 0) ? '#ffffff' : '#f8fafc';
            tr.style.backgroundColor = rowBg;
            
            var pruebasListStr = '';
            if (Array.isArray(item.pruebas_incluidas)) {
                pruebasListStr = item.pruebas_incluidas.join('\n');
            } else if (typeof item.pruebas_incluidas === 'string') {
                pruebasListStr = item.pruebas_incluidas.trim();
            }

            var reqPruebas = '<span style="color:#999; font-style:italic; pointer-events:none;">Consultar en LAESH</span>';
            if (pruebasListStr !== '') {
                var pruebasItems = pruebasListStr.split(/[\n,]+/).map(s => s.trim()).filter(s => s !== '');
                reqPruebas = '<ul style="margin:0; padding-left:1.2rem; font-size:0.9em; pointer-events:none;">' + pruebasItems.map(s => '<li>' + s + '</li>').join('') + '</ul>';
            }
            var reqPrep = (typeof item.preparacion === 'string' && item.preparacion.trim() !== '') ? item.preparacion.trim() : '<span style="color:#999; font-style:italic;">Consultar en LAESH</span>';
            var reqMuestra = (typeof item.muestra === 'string' && item.muestra.trim() !== '') ? item.muestra.trim() : '<span style="color:#999; font-style:italic;">Consultar en LAESH</span>';
            var reqContenedor = (typeof item.contenedor === 'string' && item.contenedor.trim() !== '') ? item.contenedor.trim() : '<span style="color:#999; font-style:italic;">Consultar en LAESH</span>';
            var reqTiempo = (item.tiempo !== null && item.tiempo !== undefined && String(item.tiempo).trim() !== '') ? String(item.tiempo).trim().replace(/\.0$/, '') : '<span style="color:#999; font-style:italic;">Consultar en LAESH</span>';
            var reqClave = (item.clave !== null && item.clave !== undefined && String(item.clave).trim() !== '') ? String(item.clave).trim().replace(/\.0$/, '') : '';
            
            tr.innerHTML = `
                <td><a href="#" class="btn-edit-row-modal" data-id="${rowId}" title="Editar estudio en modal" style="color: var(--primary); font-weight: bold; text-decoration: underline; cursor: pointer;">${i + 1}</a></td>
                <td data-col="clave">${reqClave}</td>
                <td data-col="nombre" style="white-space: normal; min-width: 250px;"><strong>${item.nombre || ''}</strong></td>
                <td data-col="muestra">${reqMuestra}</td>
                <td data-col="contenedor">${reqContenedor}</td>
                <td data-col="tiempo">${reqTiempo}</td>
                <td data-col="categoriaNombre" style="white-space: normal; min-width: 200px;">${item.categoriaNombre || ''}</td>
                <td data-col="preparacion" style="white-space: normal; min-width: 200px;">${reqPrep}</td>
                <td data-col="pruebas_incluidas" style="white-space: normal; min-width: 300px;"><div class="pruebas-wrapper" style="max-height:80px; overflow-y:auto; font-size:0.85em;">${reqPruebas}</div></td>
            `;
            
            var pruebasTd = tr.querySelector('.pruebas-cell');
            if (pruebasTd) pruebasTd.dataset.raw = pruebasListStr;

            var isAdded = flatAddedRows.has(rowId);
            var cols = ['clave', 'nombre', 'muestra', 'contenedor', 'tiempo', 'categoriaNombre', 'preparacion', 'pruebas_incluidas'];
            cols.forEach(function(c) {
                var td = tr.querySelector('td[data-col="' + c + '"]');
                if (td) {
                    var key = rowId + ':' + c;
                    var origVal = flatOriginalCells.has(key) ? flatOriginalCells.get(key) : null;
                    var currentVal = item[c] || '';
                    var isModified = isAdded || (origVal !== null && origVal !== currentVal);
                    if (isModified) {
                        td.style.background = '#ecfdf5';
                        td.style.borderLeft = '3px solid #10b981';
                    }
                }
            });

            var btnEditModal = tr.querySelector('.btn-edit-row-modal');
            if (btnEditModal) {
                (function(currentStudy) {
                    btnEditModal.addEventListener('click', function(e) {
                        e.preventDefault();
                        openEditEstudioModal(currentStudy);
                    });
                })(item);
            }

            tbody.appendChild(tr);
        }
        
        renderFlatPagination(total, page);
        updateSortIcons();
    }

    function renderFlatPagination(total, currentPage) {
        var pag = document.getElementById('flat-pagination');
        if (!pag) return;
        pag.innerHTML = '';
        var totalPages = Math.ceil(total / flatItemsPerPage);
        
        if (totalPages <= 1) {
            pag.style.display = 'none';
            return;
        }
        pag.style.display = 'flex';
        
        var maxButtons = 5;
        var startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
        var endPage = Math.min(totalPages, startPage + maxButtons - 1);
        
        if (endPage - startPage + 1 < maxButtons) {
            startPage = Math.max(1, endPage - maxButtons + 1);
        }
        
        var baseStyle = "background: transparent; border: none; color: #666; cursor: pointer; padding: 0.25rem 0.5rem; font-size: 0.9rem;";
        var activeStyle = "background: transparent; border: none; color: #000; font-weight: bold; cursor: pointer; padding: 0.25rem 0.5rem; font-size: 1rem;";

        if (currentPage > 1) {
            var btnPrev = document.createElement('button');
            btnPrev.type = 'button';
            btnPrev.style = baseStyle;
            btnPrev.textContent = '<<';
            btnPrev.onclick = function() { renderFlatTable(Math.max(1, currentPage - 5)); };
            pag.appendChild(btnPrev);
        }
        
        for (var i = startPage; i <= endPage; i++) {
            var btn = document.createElement('button');
            btn.type = 'button';
            btn.style = i === currentPage ? activeStyle : baseStyle;
            btn.textContent = i;
            (function(p) {
                btn.onclick = function() { renderFlatTable(p); };
            })(i);
            pag.appendChild(btn);
        }
        
        if (currentPage < totalPages) {
            var btnNext = document.createElement('button');
            btnNext.type = 'button';
            btnNext.style = baseStyle;
            btnNext.textContent = '>>';
            btnNext.onclick = function() { renderFlatTable(Math.min(totalPages, currentPage + 5)); };
            pag.appendChild(btnNext);
        }
    }

    // Flat Table Events (Editing & Tracking)
    var flatTableBody = document.querySelector('#flat-catalog-table tbody');
    if (flatTableBody) {
        flatTableBody.addEventListener('focusin', function(e) {
            if (!isFlatTableEditMode) return;
            if (e.target.classList.contains('editable-cell')) {
                var raw = '';
                if (e.target.classList.contains('pruebas-cell')) {
                    raw = e.target.dataset.raw || '';
                    e.target.innerHTML = raw; // Show comma-separated text
                } else {
                    var clone = e.target.cloneNode(true);
                    if (clone.querySelector('span') && clone.textContent.includes('Consultar en LAESH')) clone.innerHTML = '';
                    raw = clone.textContent.trim();
                }
                e.target.dataset.prevval = raw;
                
                var tr = e.target.closest('tr');
                if (tr) {
                    var rowId = tr.getAttribute('data-id');
                    var col = e.target.getAttribute('data-col');
                    var key = rowId + ':' + col;
                    if (!flatOriginalCells.has(key) && !flatAddedRows.has(rowId)) {
                        flatOriginalCells.set(key, raw);
                    }
                }
            }
        });
        
        flatTableBody.addEventListener('focusout', function(e) {
            if (!isFlatTableEditMode) return;
            if (e.target.classList.contains('editable-cell')) {
                var prevVal = e.target.dataset.prevval || '';
                var newVal = '';
                var col = e.target.getAttribute('data-col');
                
                if (e.target.classList.contains('pruebas-cell')) {
                    newVal = e.target.textContent.trim();
                    e.target.dataset.raw = newVal;
                    var html = '<span style="color:#999; font-style:italic; pointer-events:none;">Consultar en LAESH</span>';
                    if (newVal !== '') {
                        var items = newVal.split(/[\n,]+/).map(s => s.trim()).filter(s => s !== '');
                        html = '<ul style="margin:0; padding-left:1.2rem; font-size:0.9em; pointer-events:none;">' + items.map(s => '<li>' + s + '</li>').join('') + '</ul>';
                    }
                    e.target.innerHTML = `<div class="pruebas-wrapper" style="max-height:80px; overflow-y:auto; font-size:0.85em; pointer-events:none;">${html}</div>`;
                } else {
                    var clone = e.target.cloneNode(true);
                    if (clone.querySelector('span') && clone.textContent.includes('Consultar en LAESH')) clone.innerHTML = '';
                    newVal = clone.textContent.trim();
                }

                if (prevVal !== newVal) {
                    var tr = e.target.closest('tr');
                    if (tr) {
                        var rowId = tr.getAttribute('data-id');
                        flatUndoStack.push({
                            type: 'edit',
                            id: rowId,
                            col: col,
                            prevVal: prevVal,
                            newVal: newVal
                        });
                        flatRedoStack = []; // Clear redo stack on new action
                        updateUndoRedoUI();
                    }
                }
            }
        });

        flatTableBody.addEventListener('input', function(e) {
            if (e.target.classList.contains('editable-cell')) {
                var tr = e.target.closest('tr');
                if (tr) {
                    var rowId = tr.getAttribute('data-id');
                    var col = e.target.getAttribute('data-col');
                    
                    var currentVal = e.target.textContent.trim();
                    if (e.target.classList.contains('pruebas-cell')) {
                        currentVal = currentVal; 
                    } else {
                        var clone = e.target.cloneNode(true);
                        if (clone.querySelector('span') && clone.textContent.includes('Consultar en LAESH')) clone.innerHTML = '';
                        currentVal = clone.textContent.trim();
                    }

                    // Update data model immediately
                    var itemIndex = flatCatalog.findIndex(function(c, idx) { return (c.id || (c.clave + '-' + idx)) === rowId; });
                    if (itemIndex > -1) {
                        flatCatalog[itemIndex][col] = currentVal;
                        if (col === 'pruebas_incluidas') {
                            e.target.dataset.raw = currentVal;
                        }
                    }
                    
                    // Colorear celda inmediatamente basada en estado
                    var key = rowId + ':' + col;
                    var origVal = flatOriginalCells.has(key) ? flatOriginalCells.get(key) : null;
                    var isModified = flatAddedRows.has(rowId) || (origVal !== null && origVal !== currentVal);
                    
                    if (isModified) {
                        e.target.style.outline = '2px solid #10b981';
                        e.target.style.background = '#ecfdf5';
                    } else {
                        e.target.style.outline = 'none';
                        e.target.style.background = 'transparent';
                    }
                    
                    updateFlatModifiedUI();
                }
            }
        });
    }

    // Buttons Add Row / Save Table
    var btnEditFlatTable = document.getElementById('btn-edit-flat-table');
    var btnAddFlatRow = document.getElementById('btn-add-flat-row');
    var btnSaveFlatTable = document.getElementById('btn-save-flat-table');
    
    if (btnEditFlatTable) {
        btnEditFlatTable.addEventListener('click', function() {
            isFlatTableEditMode = true;
            btnEditFlatTable.style.display = 'none';
            if (btnAddFlatRow) btnAddFlatRow.style.display = 'inline-block';
            if (btnSaveFlatTable) btnSaveFlatTable.style.display = 'inline-block';
            updateUndoRedoUI();
            updateFlatModifiedUI();
            renderFlatTable(currentFlatPage || 1);
        });
    }

    if (btnAddFlatRow) {
        btnAddFlatRow.addEventListener('click', function() {
            var newId = 'new-' + Date.now();
            var newItem = {
                id: newId, clave: '', nombre: 'NUEVO ESTUDIO', muestra: '', contenedor: '',
                tiempo: '', categoriaNombre: '', preparacion: '', pruebas_incluidas: ''
            };
            flatCatalog.push(newItem);
            flatAddedRows.add(newId);
            
            var total = flatCatalog.length;
            var totalPages = Math.ceil(total / flatItemsPerPage);
            
            renderFlatTable(totalPages);
            updateFlatModifiedUI();
            
            // Abrir el modal de edición para el nuevo renglón de inmediato
            openEditEstudioModal(newItem);
        });
    }

    if (btnSaveFlatTable) {
        btnSaveFlatTable.addEventListener('click', function() {
            var payload = { action: 'update_studies', updates: [], adds: [] };

            // Recolectar deltas
            flatOriginalCells.forEach(function(origVal, key) {
                var parts = key.split('-');
                if (parts.length < 2) return;
                var col = parts.pop();
                var rowId = parts.join('-');
                // Si la fila fue agregada nueva, la ignoramos de 'updates'
                if (flatAddedRows.has(rowId)) return;
                
                var rowObj = flatCatalog.find(function(c, idx) { return (c.id || (c.clave + '-' + idx)) === rowId; });
                if (rowObj) {
                    payload.updates.push({
                        id: rowObj.id,
                        col: col,
                        val: rowObj[col]
                    });
                }
            });

            flatAddedRows.forEach(function(rowId) {
                var rowObj = flatCatalog.find(function(c, idx) { return (c.id || (c.clave + '-' + idx)) === rowId; });
                if (rowObj) payload.adds.push(rowObj);
            });

            if (payload.updates.length === 0 && payload.adds.length === 0) {
                alert('No hay cambios para guardar.');
                return;
            }

            var originalHtml = btnSaveFlatTable.innerHTML;
            btnSaveFlatTable.innerHTML = `⏳ Guardando...`;
            btnSaveFlatTable.disabled = true;

            syncCatalogPart('/api/catalog/sync', payload)
                .then(function() {
                    // Exito
                    var tbody = document.querySelector('#flat-catalog-table tbody');
                    if(tbody) {
                        tbody.querySelectorAll('.editable-cell').forEach(function(c) {
                            c.style.outline = 'none';
                            c.style.background = 'transparent';
                        });
                    }
                    flatOriginalCells.clear();
                    flatAddedRows.clear();
                    isFlatTableEditMode = false;
                    flatUndoStack = [];
                    flatRedoStack = [];
                    updateUndoRedoUI();
                    
                    if (btnEditFlatTable) btnEditFlatTable.style.display = 'inline-block';
                    if (btnAddFlatRow) btnAddFlatRow.style.display = 'none';
                    updateFlatModifiedUI();
                    renderFlatTable(currentFlatPage);
                    
                    if(window.showToast) showToast('Datos guardados en BD exitosamente.', 'success');
                })
                .finally(function() {
                    btnSaveFlatTable.innerHTML = originalHtml;
                    btnSaveFlatTable.disabled = false;
                    btnSaveFlatTable.style.display = (flatOriginalCells.size > 0 && isFlatTableEditMode) ? 'inline-block' : 'none';
                });
        });
    }



    // Flat Autocomplete
    var searchNombre = document.getElementById('flat-search-nombre');
    var flatResults = document.getElementById('flat-autocomplete-results');
    
    function handleFlatSearch() {
        if (!searchNombre || !flatResults) return;
        var nTerm = searchNombre.value.trim().toLowerCase();
        
        if (nTerm.length < 1) {
            flatResults.style.display = 'none';
            return;
        }
        
        // Optimización: Índice precalculado multi-dispositivo
        if (!window._laeshFlatSearchIndex) {
            window._laeshFlatSearchIndex = flatCatalog.map(function(e) {
                var n = e.nombre || '';
                var c = e.clave || '';
                return {
                    ref: e,
                    searchStr: (n + ' ' + c).toLowerCase()
                };
            });
        }

        // Filtrado ultra rápido
        var maxRes = 25;
        var matches = [];
        for (var i = 0; i < window._laeshFlatSearchIndex.length; i++) {
            var estIdx = window._laeshFlatSearchIndex[i];
            if (estIdx.searchStr.includes(nTerm)) {
                matches.push(estIdx.ref);
                if (matches.length >= maxRes) break;
            }
        }
        
        if (matches.length === 0) {
            flatResults.innerHTML = '<div style="padding: 0.5rem; color: #666;">Sin resultados</div>';
            flatResults.style.display = 'block';
            return;
        }
        
        flatResults.innerHTML = '';
        matches.forEach(function(m) {
            var div = document.createElement('div');
            div.style.padding = '0.5rem';
            div.style.borderBottom = '1px solid var(--border)';
            div.style.cursor = 'pointer';
            var catLabel = m.categoriaNombre || m.grupoNombre || 'General';
            var clavePrefix = m.clave ? `<strong>${m.clave}</strong> - ` : '';
            div.innerHTML = `${clavePrefix}<strong>${m.nombre}</strong> <span style="color:#666; font-size:0.85em;">- ${catLabel}</span>`;
            
            div.addEventListener('mouseenter', function() { div.style.backgroundColor = '#f1f5f9'; });
            div.addEventListener('mouseleave', function() { div.style.backgroundColor = 'transparent'; });
            
            div.addEventListener('click', function() {
                var uniqueId = String(m.id || (m.clave + '-' + flatCatalog.indexOf(m)));
                var globalIndex = flatCatalog.findIndex(x => String(x.id || (x.clave + '-' + flatCatalog.indexOf(x))) === uniqueId);
                if (globalIndex !== -1) {
                    var targetPage = Math.floor(globalIndex / flatItemsPerPage) + 1;
                    renderFlatTable(targetPage);
                    setTimeout(function() {
                        var tr = document.querySelector('#flat-catalog-table tbody tr[data-id="' + uniqueId + '"]');
                        if (tr) {
                            tr.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            tr.classList.add('highlight-flash');
                            setTimeout(function() { tr.classList.remove('highlight-flash'); }, 3000);
                        }
                    }, 100);
                }
                flatResults.style.display = 'none';
                if (searchNombre) searchNombre.value = '';
            });
            flatResults.appendChild(div);
        });
        flatResults.style.display = 'block';
    }
    
    var debounceFlatTimer;
    function debouncedFlatSearch() {
        clearTimeout(debounceFlatTimer);
        debounceFlatTimer = setTimeout(handleFlatSearch, 150);
    }
    
    if (searchNombre) {
        searchNombre.addEventListener('input', debouncedFlatSearch);
        searchNombre.addEventListener('keyup', debouncedFlatSearch);
    }
    
    document.addEventListener('click', function(e) {
        if (flatResults && searchNombre) {
            if (!searchNombre.contains(e.target) && !flatResults.contains(e.target)) {
                flatResults.style.display = 'none';
            }
        }
    });

    // Deep link: ?view=catalogos-builder (vista de Constructor de Abanicos
    // eliminada — auditoría de accesibilidad 2026-09-21; cae a la Tabla)
    var urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('view') === 'catalogos-builder') {
        if (typeof window.cambiarTabAdmin === 'function') {
            window.cambiarTabAdmin('panel-catalogos');
        }
        if (btnViewTable) {
            btnViewTable.click();
        }
    }

    /* ── LÓGICA VISTA CONFIGURACIONES (SSOT MARIADB) ── */
    var settingsGabinetesView = document.getElementById('settings-gabinetes-view');
    var panelB = document.getElementById('panel-gabinetes-b');
    var panelCDContainer = document.getElementById('panel-cd-container');
    var panelCDTitle = document.getElementById('panel-cd-title');
    var isPanelDDirty = false; // Flag para rastrear cambios en Panel D
    var activeGabineteId = null;
    var activeSubgabineteId = null;

    function getGabinetesData() {
        return (typeof window.laeshGabinetes !== 'undefined' && Array.isArray(window.laeshGabinetes)) ? window.laeshGabinetes : [];
    }
    function getSubgabinetesData() {
        return (typeof window.laeshSubgabinetes !== 'undefined' && Array.isArray(window.laeshSubgabinetes)) ? window.laeshSubgabinetes : [];
    }
    function getIGabinetesData() {
        return (typeof window.laeshIGabinetes !== 'undefined' && Array.isArray(window.laeshIGabinetes)) ? window.laeshIGabinetes : [];
    }
    function getEstudioGabineteRel() {
        return (typeof window.laeshEstudioGabinete !== 'undefined' && Array.isArray(window.laeshEstudioGabinete)) ? window.laeshEstudioGabinete : [];
    }
    function getIGabineteVinculosRel() {
        return (typeof window.laeshIGabineteVinculos !== 'undefined' && Array.isArray(window.laeshIGabineteVinculos)) ? window.laeshIGabineteVinculos : [];
    }

    function renderGabinetesList() {
        var container = document.getElementById('list-gabinetes');
        if (!container) return;
        container.innerHTML = '';

        var gabinetes = getGabinetesData();
        if (gabinetes.length === 0) {
            container.innerHTML = '<div style="padding:10px; color:#94a3b8; font-style:italic;">No hay areas registradas.</div>';
            return;
        }

        gabinetes.forEach(function(g) {
            var div = document.createElement('div');
            div.className = 'row-item';
            div.innerHTML = `
                <span class="row-name" style="font-weight: 500;">${g.nombre}</span>
                <div style="display: flex; gap: 0.5rem; align-items: center;">
                    <span class="action-icon btn-edit-row" style="cursor: pointer; color: var(--primary);" title="Editar">✏️</span>
                    <span class="action-icon btn-delete-row" style="cursor: pointer; color: #ef4444;" title="Eliminar">❌</span>
                    <span class="action-icon btn-ver-subgabinetes" data-gabinete-id="${g.id}" style="cursor: pointer; color: var(--primary-dark);" title="Ver Perfil/Especialidades">📋</span>
                    <input type="checkbox" class="chk-activar-paneles" data-tipo="Gabinete" data-id="${g.id}" data-nombre="${(g.nombre || '').replace(/"/g, '&quot;')}" style="cursor: pointer; transform: scale(1.2);">
                </div>
            `;
            container.appendChild(div);
        });
    }

    function renderSubgabinetesList(gabineteId) {
        var container = document.getElementById('list-subgabinetes');
        if (!container) return;
        container.innerHTML = '';

        var subgabinetes = getSubgabinetesData().filter(function(sg) {
            return String(sg.gabinete_id) === String(gabineteId);
        });

        if (subgabinetes.length === 0) {
            container.innerHTML = '<div style="padding:10px; color:#94a3b8; font-style:italic;">No hay perfil/especialidades registrados para esta area.</div>';
            return;
        }

        subgabinetes.forEach(function(sg) {
            var div = document.createElement('div');
            div.className = 'row-item';
            div.innerHTML = `
                <span class="row-name" style="font-weight: 500;">${sg.nombre}</span>
                <div style="display: flex; gap: 0.5rem; align-items: center;">
                    <span class="action-icon btn-edit-row" style="cursor: pointer; color: var(--primary);" title="Editar">✏️</span>
                    <span class="action-icon btn-delete-row" style="cursor: pointer; color: #ef4444;" title="Eliminar">❌</span>
                    <input type="checkbox" class="chk-activar-paneles" data-tipo="Sub Gabinete" data-id="${sg.id}" data-gabinete-id="${gabineteId}" data-nombre="${(sg.nombre || '').replace(/"/g, '&quot;')}" style="cursor: pointer; transform: scale(1.2);">
                </div>
            `;
            container.appendChild(div);
        });
    }

    function updateSaveButtonState() {
        var btnSave = document.getElementById('btn-save-vinculaciones');
        if (!btnSave) return;
        if (isPanelDDirty) {
            btnSave.disabled = false;
            btnSave.style.background = '#10b981';
            btnSave.style.color = '#ffffff';
            btnSave.style.cursor = 'pointer';
            btnSave.style.boxShadow = '0 4px 6px -1px rgba(16, 185, 129, 0.2)';
            btnSave.innerHTML = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path><polyline points="17 21 17 13 7 13 7 21"></polyline><polyline points="7 3 7 8 15 8"></polyline></svg> Guardar Vinculaciones`;
        } else {
            btnSave.disabled = true;
            btnSave.style.background = '#e2e8f0';
            btnSave.style.color = '#94a3b8';
            btnSave.style.cursor = 'not-allowed';
            btnSave.style.boxShadow = 'none';
        }
    }

    function checkPanelesCD() {
        var allCheckboxes = Array.from(document.querySelectorAll('.chk-activar-paneles'));
        var checkedBoxes = allCheckboxes.filter(chk => chk.checked);
        
        document.querySelectorAll('.row-item').forEach(function(row) {
            row.classList.remove('row-active');
        });
        
        if (checkedBoxes.length > 0) {
            if (panelCDContainer) {
                panelCDContainer.style.display = 'block';
                panelCDContainer.style.borderColor = '#10b981';
            }
            
            var firstChecked = checkedBoxes[0];
            var tipo = firstChecked.getAttribute('data-tipo');
            var nombre = firstChecked.getAttribute('data-nombre');
            var gId = firstChecked.getAttribute('data-id');
            var parentGId = firstChecked.getAttribute('data-gabinete-id');
            var parentName = '';
            
            if (tipo === 'Sub Gabinete') {
                activeGabineteId = parentGId ? parseInt(parentGId) : null;
                activeSubgabineteId = gId ? parseInt(gId) : null;
                
                var activeListBtn = document.querySelector('.btn-ver-subgabinetes.active');
                if (activeListBtn) {
                    var parentRow = activeListBtn.closest('.row-item');
                    if (parentRow) {
                        parentRow.classList.add('row-active');
                        var spanName = parentRow.querySelector('.row-name');
                        if (spanName) parentName = spanName.textContent;
                    }
                }
            } else {
                activeGabineteId = gId ? parseInt(gId) : null;
                activeSubgabineteId = null;
            }
            
            if (panelCDTitle) {
                if (tipo === 'Sub Gabinete' && parentName) {
                    panelCDTitle.innerHTML = `Vinculando a <span style="opacity:0.6; font-weight:400;">${parentName} &gt;</span> ${nombre}`;
                } else {
                    panelCDTitle.textContent = 'Vinculando a ' + tipo + ': ' + nombre;
                }
                panelCDTitle.style.color = '#10b981';
                panelCDTitle.style.borderBottomColor = '#10b981';
            }
            
            var activeRow = firstChecked.closest('.row-item');
            if (activeRow) activeRow.classList.add('row-active');

            loadGabineteVinculos(activeGabineteId, activeSubgabineteId);
        } else {
            activeGabineteId = null;
            activeSubgabineteId = null;
            if (panelCDContainer) {
                panelCDContainer.style.display = 'none';
                panelCDContainer.style.borderColor = 'var(--border)';
            }
        }
    }

    function loadGabineteVinculos(gId, sId) {
        var tagsContainer = document.getElementById('settings-selected-tags');
        var tagsEmpty = document.getElementById('settings-tags-empty');
        if (!tagsContainer) return;

        tagsContainer.innerHTML = '';

        var rels = getEstudioGabineteRel().filter(function(r) {
            if (sId) {
                return String(r.gabinete_id) === String(gId) && String(r.subgabinete_id) === String(sId);
            } else {
                return String(r.gabinete_id) === String(gId) && (!r.subgabinete_id || r.subgabinete_id === null);
            }
        });

        isPanelDDirty = false;
        updateSaveButtonState();

        if (rels.length === 0) {
            if (tagsEmpty) {
                tagsContainer.appendChild(tagsEmpty);
                tagsEmpty.style.display = 'block';
                tagsEmpty.classList.remove('d-none');
            }
            return;
        }

        if (tagsEmpty) tagsEmpty.style.display = 'none';

        rels.forEach(function(r) {
            var est = flatCatalog.find(function(c) { return String(c.id) === String(r.estudio_id); });
            if (est) {
                addStudyTag(est, false);
            }
        });
    }

    if (settingsGabinetesView) {
        settingsGabinetesView.addEventListener('click', function(e) {
            var btnSave = e.target.closest('#btn-save-vinculaciones');
            if (btnSave && !btnSave.disabled) {
                if (!activeGabineteId && !activeSubgabineteId) return;

                var vinculos = [];
                var tags = document.querySelectorAll('#settings-selected-tags .badge-estudio');
                tags.forEach(function(t) {
                    var estId = t.getAttribute('data-id');
                    var clave = t.getAttribute('data-clave');
                    var estObj = null;
                    if (estId) {
                        estObj = flatCatalog.find(function(c) { return String(c.id) === String(estId); });
                    }
                    if (!estObj && clave) {
                        estObj = flatCatalog.find(function(c) { return String(c.clave) === String(clave); });
                    }
                    if (estObj && estObj.id) {
                        vinculos.push(estObj.id);
                    }
                });

                var payload = { action: 'sync_gabinetes', gabinete_id: activeGabineteId, subgabinete_id: activeSubgabineteId, vinculos: vinculos };

                var originalHtml = btnSave.innerHTML;
                btnSave.innerHTML = `⏳ Guardando...`;
                btnSave.disabled = true;

                syncCatalogPart('/api/catalog/sync_gabinetes', payload)
                    .then(function() {
                        btnSave.innerHTML = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg> ¡Guardado!`;
                        btnSave.style.background = '#059669'; 
                        isPanelDDirty = false;

                        // Actualizar variable SSOT local en memoria
                        if (typeof window.laeshEstudioGabinete !== 'undefined') {
                            window.laeshEstudioGabinete = getEstudioGabineteRel().filter(function(r) {
                                if (activeSubgabineteId) {
                                    return !(String(r.gabinete_id) === String(activeGabineteId) && String(r.subgabinete_id) === String(activeSubgabineteId));
                                } else {
                                    return !(String(r.gabinete_id) === String(activeGabineteId) && (!r.subgabinete_id || r.subgabinete_id === null));
                                }
                            });
                            vinculos.forEach(function(estId) {
                                window.laeshEstudioGabinete.push({
                                    estudio_id: estId,
                                    gabinete_id: activeGabineteId,
                                    subgabinete_id: activeSubgabineteId
                                });
                            });
                        }

                        setTimeout(function() {
                            updateSaveButtonState();
                            btnSave.innerHTML = originalHtml;
                        }, 1500);
                    })
                    .catch(function() {
                        btnSave.innerHTML = originalHtml;
                        btnSave.disabled = false;
                    });
            }
        });

        settingsGabinetesView.addEventListener('change', function(e) {
            if (e.target.classList.contains('chk-activar-paneles')) {
                if (isPanelDDirty) {
                    if (!confirm("Hay cambios sin guardar en los estudios vinculados (Panel D). ¿Deseas descartar estos cambios y continuar?")) {
                        e.target.checked = !e.target.checked;
                        return;
                    }
                    isPanelDDirty = false;
                    updateSaveButtonState();
                }

                if (e.target.checked) {
                    var currentChk = e.target;
                    document.querySelectorAll('.chk-activar-paneles').forEach(function(chk) {
                        if (chk !== currentChk) chk.checked = false;
                    });
                }
                checkPanelesCD();
            }
        });

        function handleRowActions(e) {
            var target = e.target;
            
            var actionIcon = target.closest('.action-icon:not(.btn-ver-subgabinetes)');
            if (actionIcon) {
                actionIcon.classList.add('active');
                setTimeout(function() { actionIcon.classList.remove('active'); }, 200);
            }
            
            var btnVer = target.closest('.btn-ver-subgabinetes');
            if (btnVer) {
                var isActive = btnVer.classList.contains('active');
                document.querySelectorAll('.btn-ver-subgabinetes').forEach(b => b.classList.remove('active'));
                
                if (isActive) {
                    if (panelB) {
                        panelB.style.display = 'none';
                        panelB.querySelectorAll('.chk-activar-paneles').forEach(chk => chk.checked = false);
                        checkPanelesCD();
                    }
                } else {
                    btnVer.classList.add('active');
                    var gId = btnVer.getAttribute('data-gabinete-id');
                    renderSubgabinetesList(gId);
                    if (panelB) panelB.style.display = 'flex';
                }
            }
            
            var btnDelete = target.closest('.btn-delete-row');
            if (btnDelete) {
                var row = btnDelete.closest('.row-item');
                var nombre = row.querySelector('.row-name') ? row.querySelector('.row-name').textContent : 'este registro';
                if (confirm('¿Estás seguro de que deseas eliminar ' + nombre + '?')) {
                    var chk = row.querySelector('.chk-activar-paneles') || row.querySelector('.chk-activar-ipaneles');
                    var rowId = chk ? chk.getAttribute('data-id') : null;
                    var tipo = chk ? chk.getAttribute('data-tipo') : '';
                    var isIGab = !!row.closest('#settings-igabinetes-view');
                    if (!tipo && isIGab) tipo = 'I. Gabinete';
                    
                    var finalizeDelete = function() {
                        row.remove();
                        if (isIGab) {
                            if (typeof currentSelectedIGabinete !== 'undefined' && currentSelectedIGabinete === nombre) {
                                currentSelectedIGabinete = null;
                                if (document.getElementById('panel-igabinetes-cd-container')) {
                                    document.getElementById('panel-igabinetes-cd-container').style.display = 'none';
                                }
                            }
                        } else {
                            checkPanelesCD();
                        }
                    };

                    if (!rowId) {
                        finalizeDelete();
                    } else {
                        var payload = { action: 'delete', tipo: tipo, id: rowId };
                        syncCatalogPart('/api/catalog/crud_categorias', payload)
                            .then(function(res) {
                                if (window.showToast) window.showToast('Eliminado exitosamente', 'success');
                                finalizeDelete();
                            })
                            .catch(function(err) {
                                if (window.showToast) window.showToast('Error al eliminar', 'error');
                            });
                    }
                }
            }

            var btnEdit = target.closest('.btn-edit-row');
            if (btnEdit) {
                var row = btnEdit.closest('.row-item');
                var isIGab = !!row.closest('#settings-igabinetes-view');
                var spanName = row.querySelector('.row-name');
                var actionsDiv = row.querySelector('div');
                var currentName = spanName.textContent;
                
                spanName.style.display = 'none';
                actionsDiv.style.display = 'none';
                
                var editUi = document.createElement('div');
                editUi.className = 'edit-ui';
                editUi.style = 'display: flex; width: 100%; justify-content: space-between; align-items: center;';
                editUi.innerHTML = `
                    <input type="text" class="form-input form-input--bg edit-row-input" value="${currentName}" style="width: 200px; padding: 4px 8px; font-size: 0.95rem;">
                    <div style="display: flex; gap: 0.5rem; align-items: center;">
                        <span class="action-icon btn-save-edit" style="cursor: pointer; color: #10b981;" title="Guardar">✔️</span>
                        <span class="action-icon btn-cancel-edit" style="cursor: pointer; color: #ef4444;" title="Cancelar">❌</span>
                    </div>
                `;
                
                row.insertBefore(editUi, row.firstChild);
                var input = editUi.querySelector('.edit-row-input');
                input.focus();
                
                var closeEditFn = function() {
                    editUi.remove();
                    spanName.style.display = '';
                    actionsDiv.style.display = 'flex';
                };
                
                var saveEditFn = function() {
                    var val = input.value.trim();
                    if (val === '') {
                        closeEditFn();
                        return;
                    }
                    var chk = row.querySelector('.chk-activar-paneles') || row.querySelector('.chk-activar-ipaneles');
                    var rowId = chk ? chk.getAttribute('data-id') : null;
                    var tipo = chk ? chk.getAttribute('data-tipo') : '';
                    if (!tipo && isIGab) tipo = 'I. Gabinete';

                    var finalizeEdit = function() {
                        spanName.textContent = val;
                        if (chk) chk.setAttribute('data-nombre', val);
                        closeEditFn();
                        
                        if (isIGab) {
                            if (typeof currentSelectedIGabinete !== 'undefined' && currentSelectedIGabinete === currentName) {
                                currentSelectedIGabinete = val;
                                var titleCDIGab = document.getElementById('panel-igabinetes-cd-title');
                                if (titleCDIGab) titleCDIGab.textContent = "Vinculando a " + currentSelectedIGabinete;
                            }
                        } else {
                            checkPanelesCD();
                        }
                    };

                    if (!rowId) {
                        finalizeEdit();
                    } else {
                        var payload = { action: 'edit', tipo: tipo, id: rowId, nombre: val };
                        syncCatalogPart('/api/catalog/crud_categorias', payload)
                            .then(function(res) {
                                if (window.showToast) window.showToast('Nombre actualizado', 'success');
                                finalizeEdit();
                            })
                            .catch(function(err) {
                                if (window.showToast) window.showToast('Error al actualizar', 'error');
                            });
                    }
                };
                
                editUi.querySelector('.btn-save-edit').addEventListener('click', saveEditFn);
                editUi.querySelector('.btn-cancel-edit').addEventListener('click', closeEditFn);
                input.addEventListener('keypress', function(ev) { if (ev.key === 'Enter') saveEditFn(); });
            }
            
            var btnAdd = target.closest('.btn-add-row');
            if (btnAdd) {
                var listId = btnAdd.getAttribute('data-target');
                var container = document.getElementById(listId);
                if (container) {
                    var isGabinete = listId === 'list-gabinetes';
                    var isIGabinete = listId === 'list-igabinetes';
                    var newRow = document.createElement('div');
                    newRow.className = 'row-item';
                    if (isIGabinete) {
                        newRow.setAttribute('draggable', 'true');
                        newRow.style.cursor = 'move';
                    }
                    newRow.innerHTML = `
                        <input type="text" class="form-input form-input--bg new-row-input" placeholder="Nombre..." style="width: 200px; padding: 4px 8px; font-size: 0.95rem;">
                        <div style="display: flex; gap: 0.5rem; align-items: center;">
                            <span class="action-icon btn-save-row" style="cursor: pointer; color: #10b981;" title="Guardar">✔️</span>
                            <span class="action-icon btn-cancel-row" style="cursor: pointer; color: #ef4444;" title="Cancelar">❌</span>
                        </div>
                    `;
                    container.appendChild(newRow);
                    var input = newRow.querySelector('.new-row-input');
                    input.focus();
                    
                    var saveFn = function() {
                        var val = input.value.trim();
                        if (val === '') {
                            newRow.remove();
                            return;
                        }
                        
                        var tipoStr = isIGabinete ? 'I. Gabinete' : (isGabinete ? 'Gabinete' : 'Sub Gabinete');
                        var parentId = null;
                        if (!isIGabinete && !isGabinete) {
                            // find parent
                            var btnVer = document.querySelector('.btn-ver-subgabinetes.active');
                            if (btnVer) parentId = btnVer.getAttribute('data-gabinete-id');
                        }

                        var payload = { action: 'add', tipo: tipoStr, nombre: val, parent_id: parentId };
                        syncCatalogPart('/api/catalog/crud_categorias', payload)
                            .then(function(res) {
                                if (window.showToast) window.showToast('Agregado exitosamente', 'success');
                                var newId = res.new_id || '';
                                var checkboxHTML = '';
                                if (isIGabinete) {
                                    checkboxHTML = `<input type="checkbox" class="chk-activar-ipaneles" data-tipo="I. Gabinete" data-id="${newId}" data-nombre="${val}" style="cursor: pointer; transform: scale(1.2);">`;
                                } else {
                                    checkboxHTML = `<input type="checkbox" class="chk-activar-paneles" data-tipo="${isGabinete ? 'Gabinete' : 'Sub Gabinete'}" data-id="${newId}" data-nombre="${val}" style="cursor: pointer; transform: scale(1.2);">`;
                                }

                                newRow.innerHTML = `
                                    <span class="row-name" style="font-weight: 500;">${val}</span>
                                    <div style="display: flex; gap: 0.5rem; align-items: center;">
                                        <span class="action-icon btn-edit-row" style="cursor: pointer; color: var(--primary);" title="Editar">✏️</span>
                                        <span class="action-icon btn-delete-row" style="cursor: pointer; color: #ef4444;" title="Eliminar">❌</span>
                                        ${isGabinete ? '<span class="action-icon btn-ver-subgabinetes" style="cursor: pointer; color: var(--primary-dark);" title="Ver Subgabinetes" data-gabinete-id="' + newId + '">📋</span>' : ''}
                                        ${checkboxHTML}
                                    </div>
                                `;
                                
                                if (isIGabinete && typeof window.bindIGabineteCheckbox === 'function') {
                                    var newChk = newRow.querySelector('.chk-activar-ipaneles');
                                    if (newChk) window.bindIGabineteCheckbox(newChk);
                                }
                            })
                            .catch(function(err) {
                                if (window.showToast) window.showToast('Error al agregar', 'error');
                                newRow.remove();
                            });
                    };
                    
                    newRow.querySelector('.btn-save-row').addEventListener('click', saveFn);
                    newRow.querySelector('.btn-cancel-row').addEventListener('click', function() { newRow.remove(); });
                    input.addEventListener('keypress', function(ev) { if (ev.key === 'Enter') saveFn(); });
                }
            }
        }

        if (settingsGabinetesView) {
            settingsGabinetesView.addEventListener('click', handleRowActions);
        }
        var viewIGabinetes = document.getElementById('settings-igabinetes-view');
        if (viewIGabinetes) {
            viewIGabinetes.addEventListener('click', handleRowActions);
        }
    }

    var settingsSearchNombre = document.getElementById('settings-search-nombre');
    var settingsSearchGrupo = document.getElementById('settings-search-grupo');
    var settingsResults = document.getElementById('settings-autocomplete-results');
    var settingsSelectedTags = document.getElementById('settings-selected-tags');
    var settingsTagsEmpty = document.getElementById('settings-tags-empty');

    function renderSettingsAutocomplete(results) {
        if (!settingsResults) return;
        settingsResults.innerHTML = '';
        if (results.length === 0) {
            settingsResults.style.display = 'none';
            return;
        }
        
        var ul = document.createElement('ul');
        ul.style.listStyle = 'none';
        ul.style.margin = '0';
        ul.style.padding = '0';
        
        var max = Math.min(results.length, 50);
        for(var i=0; i<max; i++) {
            var item = results[i];
            var li = document.createElement('li');
            li.style.padding = '8px 12px';
            li.style.borderBottom = '1px solid #f1f5f9';
            li.style.cursor = 'pointer';
            li.style.fontSize = '0.9rem';
            li.innerHTML = `<strong>${item.nombre}</strong> <span style="color:#64748b; font-size:0.8rem;">(${item.clave})</span>`;
            
            li.addEventListener('mouseenter', function(e) { e.target.style.background = '#f8fafc'; });
            li.addEventListener('mouseleave', function(e) { e.target.style.background = 'transparent'; });
            
            (function(study) {
                li.addEventListener('click', function() {
                    addStudyTag(study, true);
                    settingsResults.style.display = 'none';
                    if (settingsSearchNombre) settingsSearchNombre.value = '';
                    if (settingsSearchGrupo) settingsSearchGrupo.value = '';
                });
            })(item);
            
            ul.appendChild(li);
        }
        
        settingsResults.appendChild(ul);
        settingsResults.style.display = 'block';
    }

    function doSettingsSearch() {
        if (!flatCatalog || flatCatalog.length === 0) {
            if (catalogTree && catalogTree.length > 0) flattenCatalogTree();
        }
        if (!flatCatalog) return;

        var qN = (settingsSearchNombre && settingsSearchNombre.value) ? settingsSearchNombre.value.toLowerCase() : '';
        var qG = (settingsSearchGrupo && settingsSearchGrupo.value) ? settingsSearchGrupo.value.toLowerCase() : '';
        
        if (qN.length < 2 && qG.length < 2) {
            if(settingsResults) settingsResults.style.display = 'none';
            return;
        }
        
        var results = flatCatalog.filter(function(item) {
            var matchN = true, matchG = true;
            if (qN) {
                matchN = (item.nombre && item.nombre.toLowerCase().includes(qN)) ||
                         (item.clave && item.clave.toLowerCase().includes(qN));
            }
            if (qG) {
                matchG = (item.categoriaNombre && item.categoriaNombre.toLowerCase().includes(qG)) ||
                         (item.grupoNombre && item.grupoNombre.toLowerCase().includes(qG));
            }
            return matchN && matchG;
        });
        
        renderSettingsAutocomplete(results);
    }

    if (settingsSearchNombre) {
        settingsSearchNombre.addEventListener('input', doSettingsSearch);
        settingsSearchNombre.addEventListener('focus', doSettingsSearch);
    }
    if (settingsSearchGrupo) {
        settingsSearchGrupo.addEventListener('input', doSettingsSearch);
        settingsSearchGrupo.addEventListener('focus', doSettingsSearch);
    }
    
    document.addEventListener('click', function(e) {
        if (settingsResults && !settingsResults.contains(e.target) &&
            settingsSearchNombre && !settingsSearchNombre.contains(e.target) &&
            settingsSearchGrupo && !settingsSearchGrupo.contains(e.target)) {
            settingsResults.style.display = 'none';
        }
    });

    function addStudyTag(study, isDirty = true) {
        if (!settingsSelectedTags) return;
        
        if (settingsTagsEmpty && !settingsTagsEmpty.classList.contains('d-none')) {
            settingsTagsEmpty.classList.add('d-none');
            settingsTagsEmpty.style.display = 'none';
        }
        
        var existing = settingsSelectedTags.querySelector(`[data-clave="${study.clave}"]`);
        if (existing) return;
        
        if (isDirty) {
            isPanelDDirty = true;
            updateSaveButtonState();
        }
        
        var tag = document.createElement('div');
        tag.className = 'badge-estudio';
        tag.setAttribute('data-clave', study.clave);
        tag.setAttribute('data-id', study.id || '');
        tag.style.display = 'inline-flex';
        tag.style.alignItems = 'center';
        tag.style.background = '#e0f2fe';
        tag.style.color = '#0369a1';
        tag.style.padding = '4px 10px';
        tag.style.borderRadius = '16px';
        tag.style.fontSize = '0.85rem';
        tag.style.fontWeight = '500';
        tag.style.border = '1px solid #bae6fd';
        tag.style.gap = '6px';
        
        tag.innerHTML = `
            <span>${study.nombre} <small style="opacity:0.7">(${study.clave})</small></span>
            <span class="remove-tag" style="cursor:pointer; font-weight:bold; font-size:1rem; line-height:1;">&times;</span>
        `;
        
        tag.querySelector('.remove-tag').addEventListener('click', function() {
            tag.remove();
            isPanelDDirty = true;
            updateSaveButtonState();
            if (settingsSelectedTags.querySelectorAll('.badge-estudio').length === 0) {
                if (settingsTagsEmpty) {
                    settingsTagsEmpty.classList.remove('d-none');
                    settingsTagsEmpty.style.display = 'block';
                }
            }
        });
        
        settingsSelectedTags.appendChild(tag);
    }

    /* ── LÓGICA VISTA 20 EST.MED (SSOT MARIADB) ── */
    var search20EstMed = document.getElementById('settings-20estmed-search');
    var results20EstMed = document.getElementById('settings-20estmed-results');
    var tags20EstMed = document.getElementById('settings-20estmed-tags');
    var btnSave20EstMed = document.getElementById('btn-save-20estmed');
    var is20EstMedDirty = false;
    var draggedTag = null;

    function populate20EstMedTags() {
        if (!tags20EstMed) return;
        tags20EstMed.innerHTML = '';
        var top20Data = (typeof window.laeshTop20EstMed !== 'undefined' && Array.isArray(window.laeshTop20EstMed)) ? window.laeshTop20EstMed : [];

        for (var i = 1; i <= 20; i++) {
            var slot = document.createElement('div');
            slot.className = 'dnd-slot';
            slot.setAttribute('data-index', i);
            
            slot.addEventListener('dragover', function(e) {
                e.preventDefault();
                if (!this.classList.contains('drag-over')) this.classList.add('drag-over');
            });
            slot.addEventListener('dragleave', function() {
                this.classList.remove('drag-over');
            });
            slot.addEventListener('drop', function(e) {
                e.preventDefault();
                this.classList.remove('drag-over');
                if (!draggedTag) return;

                var sourceSlot = draggedTag.parentNode;
                var targetSlot = this;

                if (targetSlot !== sourceSlot) {
                    if (targetSlot.children.length > 0) {
                        var existingTag = targetSlot.children[0];
                        sourceSlot.appendChild(existingTag);
                    }
                    targetSlot.appendChild(draggedTag);
                    is20EstMedDirty = true;
                    update20EstMedSaveButton();
                }
            });

            var topItem = top20Data[i - 1];
            if (topItem) {
                var estObj = flatCatalog.find(function(c) { return String(c.id) === String(topItem.id) || c.clave === topItem.clave; }) || topItem;
                create20EstMedTagElement(slot, estObj);
            }

            tags20EstMed.appendChild(slot);
        }
        is20EstMedDirty = false;
        update20EstMedSaveButton();
    }

    function create20EstMedTagElement(slot, study) {
        var tag = document.createElement('div');
        tag.className = 'badge-estudio';
        tag.setAttribute('data-clave', study.clave || '');
        tag.setAttribute('data-id', study.id || '');
        tag.setAttribute('draggable', 'true');
        tag.style.display = 'inline-flex';
        tag.style.alignItems = 'center';
        tag.style.background = '#e0f2fe';
        tag.style.color = '#0369a1';
        tag.style.padding = '4px 10px';
        tag.style.borderRadius = '16px';
        tag.style.fontSize = '0.85rem';
        tag.style.fontWeight = '500';
        tag.style.border = '1px solid #bae6fd';
        tag.style.gap = '6px';
        tag.style.cursor = 'grab';
        tag.style.width = '100%';
        tag.style.boxSizing = 'border-box';

        tag.innerHTML = `
            <span style="flex-grow:1; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;" title="${study.nombre}">${study.nombre}</span>
            <span class="remove-tag" style="cursor:pointer; font-weight:bold; font-size:1rem; line-height:1; flex-shrink:0;">&times;</span>
        `;

        tag.addEventListener('dragstart', function(e) {
            draggedTag = this;
            setTimeout(function() { tag.classList.add('dragging'); }, 0);
            e.dataTransfer.effectAllowed = 'move';
        });
        
        tag.addEventListener('dragend', function() {
            this.classList.remove('dragging');
            draggedTag = null;
        });

        tag.querySelector('.remove-tag').addEventListener('click', function() {
            tag.remove();
            is20EstMedDirty = true;
            update20EstMedSaveButton();
        });

        slot.appendChild(tag);
    }

    function update20EstMedSaveButton() {
        if (!btnSave20EstMed) return;
        if (is20EstMedDirty) {
            btnSave20EstMed.disabled = false;
            btnSave20EstMed.style.background = '#10b981';
            btnSave20EstMed.style.color = '#ffffff';
            btnSave20EstMed.style.cursor = 'pointer';
            btnSave20EstMed.style.boxShadow = '0 4px 6px -1px rgba(16, 185, 129, 0.2)';
            btnSave20EstMed.innerHTML = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path><polyline points="17 21 17 13 7 13 7 21"></polyline><polyline points="7 3 7 8 15 8"></polyline></svg> Guardar Top 20`;
        } else {
            btnSave20EstMed.disabled = true;
            btnSave20EstMed.style.background = '#e2e8f0';
            btnSave20EstMed.style.color = '#94a3b8';
            btnSave20EstMed.style.cursor = 'not-allowed';
            btnSave20EstMed.style.boxShadow = 'none';
        }
    }

    function do20EstMedSearch() {
        if (!flatCatalog || flatCatalog.length === 0) {
            if (catalogTree && catalogTree.length > 0) flattenCatalogTree();
        }
        if (!flatCatalog) return;

        var q = (search20EstMed && search20EstMed.value) ? search20EstMed.value.toLowerCase() : '';
        if (q.length < 2) {
            if (results20EstMed) results20EstMed.style.display = 'none';
            return;
        }

        var results = flatCatalog.filter(function(item) {
            return (item.nombre && item.nombre.toLowerCase().includes(q)) || (item.clave && item.clave.toLowerCase().includes(q));
        });

        render20EstMedAutocomplete(results);
    }

    function render20EstMedAutocomplete(results) {
        if (!results20EstMed) return;
        results20EstMed.innerHTML = '';
        if (results.length === 0) {
            results20EstMed.innerHTML = '<div style="padding:10px; color:#94a3b8;">No se encontraron estudios.</div>';
            results20EstMed.style.display = 'block';
            return;
        }

        var frag = document.createDocumentFragment();
        var limit = Math.min(results.length, 50);
        for (var i = 0; i < limit; i++) {
            var item = results[i];
            var div = document.createElement('div');
            div.style.padding = '8px 12px';
            div.style.borderBottom = '1px solid #f1f5f9';
            div.style.cursor = 'pointer';
            div.style.fontSize = '0.9rem';
            div.innerHTML = `<strong>${item.clave}</strong> - ${item.nombre}`;
            
            div.addEventListener('mouseenter', function() { this.style.backgroundColor = '#f8fafc'; });
            div.addEventListener('mouseleave', function() { this.style.backgroundColor = 'transparent'; });
            
            div.addEventListener('click', (function(study) {
                return function() {
                    add20EstMedTag(study);
                    results20EstMed.style.display = 'none';
                    if (search20EstMed) { search20EstMed.value = ''; search20EstMed.focus(); }
                };
            })(item));
            
            frag.appendChild(div);
        }
        results20EstMed.appendChild(frag);
        results20EstMed.style.display = 'block';
    }

    function add20EstMedTag(study) {
        if (!tags20EstMed) return;
        
        var existing = tags20EstMed.querySelector(`[data-clave="${study.clave}"]`);
        if (existing) {
            alert("Este estudio ya está en la lista.");
            return;
        }

        var emptySlot = Array.from(tags20EstMed.children).find(function(slot) {
            return slot.children.length === 0;
        });

        if (!emptySlot) {
            alert("Límite de 20 estudios alcanzado.");
            return;
        }

        is20EstMedDirty = true;
        update20EstMedSaveButton();
        create20EstMedTagElement(emptySlot, study);
    }

    if (search20EstMed) {
        search20EstMed.addEventListener('input', do20EstMedSearch);
        document.addEventListener('click', function(e) {
            if (results20EstMed && !results20EstMed.contains(e.target) && e.target !== search20EstMed) {
                results20EstMed.style.display = 'none';
            }
        });
    }

    if (btnSave20EstMed) {
        btnSave20EstMed.addEventListener('click', function() {
            if (btnSave20EstMed.disabled) return;
            
            var top20Ids = [];
            var slots = tags20EstMed.querySelectorAll('.dnd-slot');
            slots.forEach(function(slot) {
                var badge = slot.querySelector('.badge-estudio');
                if (badge) {
                    var clave = badge.getAttribute('data-clave');
                    var est = flatCatalog.find(function(c) { return c.clave === clave; });
                    if (est && est.id) {
                        top20Ids.push(est.id);
                    }
                }
            });

            var payload = { action: 'update_top20', top20: top20Ids };

            var originalHtml = btnSave20EstMed.innerHTML;
            btnSave20EstMed.innerHTML = `⏳ Guardando...`;
            btnSave20EstMed.disabled = true;

            syncCatalogPart('/api/catalog/sync', payload)
                .then(function() {
                    btnSave20EstMed.innerHTML = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg> ¡Guardado!`;
                    btnSave20EstMed.style.background = '#059669';
                    is20EstMedDirty = false;

                    // Update SSOT memory variable
                    window.laeshTop20EstMed = [];
                    top20Ids.forEach(function(id) {
                        var est = flatCatalog.find(function(c) { return c.id === id; });
                        if (est) {
                            window.laeshTop20EstMed.push({ id: est.id, clave: est.clave, nombre: est.nombre, categoria: est.categoriaNombre || '' });
                        }
                    });

                    setTimeout(function() {
                        update20EstMedSaveButton();
                        btnSave20EstMed.innerHTML = originalHtml;
                    }, 1500);
                })
                .catch(function() {
                    btnSave20EstMed.innerHTML = originalHtml;
                    btnSave20EstMed.disabled = false;
                });
        });
    }

    /* ── LÓGICA VISTA I. GABINETES (SSOT MARIADB) ── */
    var isIGabinetesDirty = false;
    var activeIGabineteId = null;
    var currentSelectedIGabinete = null;
    var currentIGabinetesLinked = [];

    var btnSaveIGab = document.getElementById('btn-save-ivinculaciones');
    var containerCDIGab = document.getElementById('panel-igabinetes-cd-container');
    var titleCDIGab = document.getElementById('panel-igabinetes-cd-title');
    var searchIGab = document.getElementById('settings-isearch-input');
    var autocompleteIGab = document.getElementById('settings-iautocomplete-results');
    var tagsContainerIGab = document.getElementById('settings-iselected-tags');
    var tagsEmptyIGab = document.getElementById('settings-itags-empty');

    window.bindIGabineteCheckbox = function(chk) {
        if (!chk || chk.dataset.bound) return;
        chk.dataset.bound = 'true';
        chk.addEventListener('change', function() {
            if (isIGabinetesDirty) {
                var confirmChange = confirm("Tienes cambios sin guardar. ¿Deseas descartarlos y cambiar de I. Gabinete?");
                if (!confirmChange) {
                    this.checked = !this.checked;
                    return;
                }
            }

            var wasChecked = this.checked;
            
            document.querySelectorAll('.chk-activar-ipaneles').forEach(function(c) {
                c.checked = false;
                var row = c.closest('.row-item');
                if(row) {
                    row.style.background = '';
                    row.style.borderColor = 'var(--border)';
                }
            });

            if (wasChecked) {
                this.checked = true;
                activeIGabineteId = parseInt(this.getAttribute('data-id'));
                currentSelectedIGabinete = this.getAttribute('data-nombre');
                
                var parentRow = this.closest('.row-item');
                if(parentRow) {
                    parentRow.style.background = '#f0fdf4';
                    parentRow.style.borderColor = '#10b981';
                }

                var titleElem = document.getElementById('panel-igabinetes-cd-title');
                if (titleElem) {
                    titleElem.textContent = "Vinculando a " + currentSelectedIGabinete;
                }
                
                loadIGabineteVinculos(activeIGabineteId);
                
                var contElem = document.getElementById('panel-igabinetes-cd-container');
                if (contElem) contElem.style.display = 'block';
            } else {
                activeIGabineteId = null;
                currentSelectedIGabinete = null;
                isIGabinetesDirty = false;
                var contElem = document.getElementById('panel-igabinetes-cd-container');
                if (contElem) contElem.style.display = 'none';
            }
        });
    };

    function renderIGabinetesList() {
        var container = document.getElementById('list-igabinetes');
        if (!container) return;
        container.innerHTML = '';

        var igabinetes = getIGabinetesData();
        if (igabinetes.length === 0) {
            container.innerHTML = '<div style="padding:10px; color:#94a3b8; font-style:italic;">No hay I.Areas registradas.</div>';
            return;
        }

        igabinetes.forEach(function(ig) {
            var div = document.createElement('div');
            div.className = 'row-item';
            div.setAttribute('draggable', 'true');
            div.style.cursor = 'move';
            div.innerHTML = `
                <span class="row-name" style="font-weight: 500;">${ig.nombre}</span>
                <div style="display: flex; gap: 0.5rem; align-items: center;">
                    <span class="action-icon btn-edit-row" style="cursor: pointer; color: var(--primary);" title="Editar">✏️</span>
                    <span class="action-icon btn-delete-row" style="cursor: pointer; color: #ef4444;" title="Eliminar">❌</span>
                    <input type="checkbox" class="chk-activar-ipaneles" data-tipo="I. Gabinete" data-id="${ig.id}" data-nombre="${(ig.nombre || '').replace(/"/g, '&quot;')}" style="cursor: pointer; transform: scale(1.2);">
                </div>
            `;
            container.appendChild(div);
        });

        document.querySelectorAll('.chk-activar-ipaneles').forEach(function(chk) {
            if (typeof window.bindIGabineteCheckbox === 'function') window.bindIGabineteCheckbox(chk);
        });
    }

    function updateIGabSaveBtn() {
        if (!btnSaveIGab) return;
        if (isIGabinetesDirty) {
            btnSaveIGab.disabled = false;
            btnSaveIGab.style.background = '#10b981';
            btnSaveIGab.style.color = '#fff';
            btnSaveIGab.style.cursor = 'pointer';
        } else {
            btnSaveIGab.disabled = true;
            btnSaveIGab.style.background = '#e2e8f0';
            btnSaveIGab.style.color = '#94a3b8';
            btnSaveIGab.style.cursor = 'not-allowed';
        }
    }

    function renderIGabTags() {
        if (!tagsContainerIGab) return;
        
        var tagsHtml = '';
        currentIGabinetesLinked.forEach(function(item) {
            var colorBorder = item.tipo === 'Gabinete' ? '#3b82f6' : '#10b981';
            var colorBg = item.tipo === 'Gabinete' ? '#eff6ff' : '#ecfdf5';
            tagsHtml += `
                <div class="linked-tag" style="display: flex; align-items: center; gap: 0.5rem; background: ${colorBg}; border: 1px solid ${colorBorder}; padding: 4px 8px; border-radius: 4px;">
                    <div style="font-size: 0.9rem; font-weight: 500; color: #334155;">${item.nombre}</div>
                    <span class="btn-remove-itag" data-id="${item.id}" data-tipo="${item.tipo}" style="cursor: pointer; color: #ef4444; font-weight: bold; margin-left: 5px;">×</span>
                </div>
            `;
        });
        
        tagsContainerIGab.innerHTML = tagsHtml;
        if (currentIGabinetesLinked.length === 0) {
            if (tagsEmptyIGab) {
                tagsContainerIGab.appendChild(tagsEmptyIGab);
                tagsEmptyIGab.style.display = 'block';
            }
        } else if (tagsEmptyIGab) {
            tagsEmptyIGab.style.display = 'none';
        }

        document.querySelectorAll('.btn-remove-itag').forEach(function(btn) {
            btn.addEventListener('click', function() {
                var id = parseInt(this.getAttribute('data-id'), 10);
                var tipo = this.getAttribute('data-tipo');
                currentIGabinetesLinked = currentIGabinetesLinked.filter(i => !(i.id === id && i.tipo === tipo));
                isIGabinetesDirty = true;
                renderIGabTags();
                updateIGabSaveBtn();
            });
        });
    }

    function loadIGabineteVinculos(igId) {
        if (!tagsContainerIGab) return;
        tagsContainerIGab.innerHTML = '';
        currentIGabinetesLinked = [];

        var vinculos = getIGabineteVinculosRel().filter(function(r) {
            return String(r.igabinete_id) === String(igId);
        });

        vinculos.forEach(function(v) {
            if (v.subgabinete_id) {
                var sg = getSubgabinetesData().find(function(s) { return String(s.id) === String(v.subgabinete_id); });
                if (sg) {
                    currentIGabinetesLinked.push({ id: sg.id, tipo: 'Sub Gabinete', gabinete_id: sg.gabinete_id, subgabinete_id: sg.id, nombre: sg.nombre });
                }
            } else if (v.gabinete_id) {
                var g = getGabinetesData().find(function(item) { return String(item.id) === String(v.gabinete_id); });
                if (g) {
                    currentIGabinetesLinked.push({ id: g.id, tipo: 'Gabinete', gabinete_id: g.id, subgabinete_id: null, nombre: g.nombre });
                }
            }
        });

        renderIGabTags();
        isIGabinetesDirty = false;
        updateIGabSaveBtn();
    }

    if (searchIGab) {
        searchIGab.addEventListener('input', function() {
            var term = this.value.toLowerCase().trim();
            if (term.length < 2) {
                if (autocompleteIGab) autocompleteIGab.style.display = 'none';
                return;
            }

            var allOptions = [];
            getGabinetesData().forEach(function(g) {
                allOptions.push({ id: g.id, tipo: 'Gabinete', gabinete_id: g.id, subgabinete_id: null, nombre: g.nombre });
            });
            getSubgabinetesData().forEach(function(sg) {
                allOptions.push({ id: sg.id, tipo: 'Sub Gabinete', gabinete_id: sg.gabinete_id, subgabinete_id: sg.id, nombre: sg.nombre });
            });

            var results = allOptions.filter(function(item) {
                return item.nombre.toLowerCase().includes(term) && !currentIGabinetesLinked.some(l => l.id === item.id && l.tipo === item.tipo);
            });

            if (results.length > 0) {
                var html = results.map(function(item) {
                    var color = item.tipo === 'Gabinete' ? '#3b82f6' : '#10b981';
                    return `
                        <div class="iautocomplete-item" data-id="${item.id}" data-tipo="${item.tipo}" style="padding: 10px 14px; cursor: pointer; border-bottom: 1px solid #f1f5f9; display: flex; align-items: center; justify-content: space-between;">
                            <span style="font-weight: 500; color: #1e293b;">${item.nombre}</span>
                            <span style="font-size: 0.75rem; background: ${color}20; color: ${color}; padding: 2px 6px; border-radius: 4px; font-weight: bold;">${item.tipo}</span>
                        </div>
                    `;
                }).join('');
                autocompleteIGab.innerHTML = html;
                autocompleteIGab.style.display = 'block';

                document.querySelectorAll('.iautocomplete-item').forEach(function(el) {
                    el.addEventListener('click', function() {
                        var id = parseInt(this.getAttribute('data-id'), 10);
                        var tipo = this.getAttribute('data-tipo');
                        var itemToAdd = allOptions.find(i => i.id === id && i.tipo === tipo);
                        if (itemToAdd) {
                            currentIGabinetesLinked.push(itemToAdd);
                            isIGabinetesDirty = true;
                            renderIGabTags();
                            updateIGabSaveBtn();
                        }
                        searchIGab.value = '';
                        autocompleteIGab.style.display = 'none';
                    });
                });
            } else {
                autocompleteIGab.innerHTML = '<div style="padding: 10px 14px; color: #94a3b8; font-style: italic;">No se encontraron gabinetes/subgabinetes.</div>';
                autocompleteIGab.style.display = 'block';
            }
        });

        document.addEventListener('click', function(e) {
            if (autocompleteIGab && !autocompleteIGab.contains(e.target) && e.target !== searchIGab) {
                autocompleteIGab.style.display = 'none';
            }
        });
    }

    if (btnSaveIGab) {
        btnSaveIGab.addEventListener('click', function() {
            if (btnSaveIGab.disabled || !activeIGabineteId) return;

            var vinculos = currentIGabinetesLinked.map(function(item) {
                var isSub = item.tipo === 'Sub Gabinete';
                return {
                    gabinete_id: isSub ? item.gabinete_id : item.id,
                    subgabinete_id: isSub ? item.id : null
                };
            });

            var payload = { action: 'sync_igabinetes', igabinete_id: activeIGabineteId, vinculos: vinculos };

            var originalHtml = btnSaveIGab.innerHTML;
            btnSaveIGab.innerHTML = `⏳ Guardando...`;
            btnSaveIGab.disabled = true;

            syncCatalogPart('/api/catalog/sync_igabinetes', payload)
                .then(function() {
                    btnSaveIGab.innerHTML = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg> ¡Guardado!`;
                    btnSaveIGab.style.background = '#059669';
                    isIGabinetesDirty = false;

                    // Update SSOT memory variable
                    if (typeof window.laeshIGabineteVinculos !== 'undefined') {
                        window.laeshIGabineteVinculos = getIGabineteVinculosRel().filter(function(r) {
                            return String(r.igabinete_id) !== String(activeIGabineteId);
                        });
                        vinculos.forEach(function(v) {
                            window.laeshIGabineteVinculos.push({
                                igabinete_id: activeIGabineteId,
                                gabinete_id: v.gabinete_id,
                                subgabinete_id: v.subgabinete_id
                            });
                        });
                    }

                    setTimeout(function() {
                        updateIGabSaveBtn();
                        btnSaveIGab.innerHTML = originalHtml;
                    }, 1500);
                })
                .catch(function() {
                    btnSaveIGab.innerHTML = originalHtml;
                    btnSaveIGab.disabled = false;
                });
        });
    }

    var listIGabinetes = document.getElementById('list-igabinetes');
    if (listIGabinetes) {
        var dragIGabEl = null;
        listIGabinetes.addEventListener('dragstart', function(e) {
            if (e.target.classList && e.target.classList.contains('row-item')) {
                dragIGabEl = e.target;
                e.dataTransfer.effectAllowed = 'move';
                e.dataTransfer.setData('text/html', e.target.innerHTML);
                e.target.style.opacity = '0.4';
            }
        });
        listIGabinetes.addEventListener('dragover', function(e) {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
            var target = e.target.closest('.row-item');
            if (target && target !== dragIGabEl) {
                target.style.borderTop = '3px solid var(--primary)';
            }
            return false;
        });
        listIGabinetes.addEventListener('dragleave', function(e) {
            var target = e.target.closest('.row-item');
            if (target && target !== dragIGabEl) {
                target.style.borderTop = 'none';
            }
        });
        listIGabinetes.addEventListener('drop', function(e) {
            e.stopPropagation();
            var target = e.target.closest('.row-item');
            if (target && dragIGabEl && target !== dragIGabEl) {
                target.style.borderTop = 'none';
                var targetRect = target.getBoundingClientRect();
                if (e.clientY < targetRect.top + targetRect.height / 2) {
                    listIGabinetes.insertBefore(dragIGabEl, target);
                } else {
                    listIGabinetes.insertBefore(dragIGabEl, target.nextSibling);
                }
            }
            return false;
        });
        listIGabinetes.addEventListener('dragend', function(e) {
            if (e.target.classList && e.target.classList.contains('row-item')) {
                e.target.style.opacity = '1';
                listIGabinetes.querySelectorAll('.row-item').forEach(r => r.style.borderTop = 'none');
            }
        });
    }


    // ==========================================
    // DATA LOSS PREVENTION (BEFOREUNLOAD GUARD)
    // ==========================================
    
    // Interceptar F5 o cierre de pestaña
    window.addEventListener('beforeunload', function(e) {
        var hasChanges = (typeof isPanelDDirty !== 'undefined' && isPanelDDirty) ||
                         (typeof is20EstMedDirty !== 'undefined' && is20EstMedDirty) || 
                         (typeof isIGabinetesDirty !== 'undefined' && isIGabinetesDirty) || 
                         (typeof flatOriginalCells !== 'undefined' && flatOriginalCells.size > 0) ||
                         (typeof flatAddedRows !== 'undefined' && flatAddedRows.size > 0);
                         
        if (hasChanges) {
            e.preventDefault();
            e.returnValue = 'Tienes cambios sin guardar. Si sales de esta página, los cambios se perderán.';
        }
    });

    // ==========================================
    // LÓGICA DE SINCRONIZACIÓN AJAX (FASE 3)
    // ==========================================
    
    // Inject Spinner Overlay and Auth Modal
    if (document.body) {
        document.body.insertAdjacentHTML('beforeend', `
        <div id="catalog-spinner-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.8); z-index:9999; flex-direction:column; justify-content:center; align-items:center; backdrop-filter:blur(2px);">
            <div style="width:50px; height:50px; border:4px solid #f3f3f3; border-top:4px solid var(--primary); border-radius:50%; animation:spin 1s linear infinite;"></div>
            <p style="margin-top:1rem; font-weight:bold; color:var(--primary-dark);">Sincronizando Catálogo...</p>
        </div>
        <dialog id="catalog-auth-modal" style="border:none; border-radius:8px; padding:2rem; box-shadow:0 10px 25px rgba(0,0,0,0.2); max-width:400px; width:90%;">
            <form onsubmit="return false;">
                <h3 style="margin-top:0; color:#ef4444;">Sesión Expirada</h3>
                <p style="color:#64748b; font-size:0.9rem; margin-bottom:1.5rem;">Tu sesión ha expirado por inactividad. Para no perder tus cambios, ingresa tu contraseña nuevamente.</p>
                <input type="password" id="catalog-auth-password" class="form-input" autocomplete="current-password" placeholder="Tu Contraseña" style="width:100%; margin-bottom:1rem;">
                <div style="display:flex; justify-content:flex-end; gap:0.5rem;">
                    <button type="button" class="btn btn-secondary" onclick="document.getElementById('catalog-auth-modal').close()">Cancelar Cambios</button>
                    <button type="button" class="btn btn-primary" id="btn-catalog-reauth">Re-autenticar y Guardar</button>
                </div>
            </form>
            <style>@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }</style>
        </dialog>
    `);
    }

    /**
     * Envia datos al backend, interceptando errores 401 para re-autenticar en memoria.
     * @param {string} endpoint - Ruta del API
     * @param {object} payload - Datos JSON a enviar
     * @returns {Promise}
     */
    window.syncCatalogPart = function(endpoint, payload) {
        return new Promise((resolve, reject) => {
            var overlay = document.getElementById('catalog-spinner-overlay');
            var authModal = document.getElementById('catalog-auth-modal');
            var pwdInput = document.getElementById('catalog-auth-password');
            var btnReauth = document.getElementById('btn-catalog-reauth');
            
            if (overlay) overlay.style.display = 'flex';

            function doFetch() {
                var csrfToken = document.querySelector('meta[name="csrf-token"]') 
                    ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') 
                    : '';

                var targetUrl = endpoint;
                if (!targetUrl.startsWith('/laesh/rc') && targetUrl.startsWith('/api/')) {
                    targetUrl = '/laesh/rc' + targetUrl;
                }

                fetch(targetUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': csrfToken
                    },
                    body: JSON.stringify(payload)
                })
                .then(res => {
                    if (res.status === 401) {
                        if (overlay) overlay.style.display = 'none';
                        if (authModal && authModal.showModal) authModal.showModal();
                        
                        if (btnReauth) {
                            btnReauth.onclick = function() {
                                var pwd = pwdInput ? pwdInput.value : '';
                                if (!pwd) { alert('Ingresa tu contraseña'); return; }
                                
                                btnReauth.textContent = 'Autenticando...';
                                btnReauth.disabled = true;
                                
                                // Reautenticar (Delight Auth)
                                var fd = new FormData();
                                fd.append('password', pwd);
                                
                                fetch('/laesh/rc/api/auth/login-inplace', {
                                    method: 'POST',
                                    headers: { 'X-CSRF-TOKEN': csrfToken },
                                    body: fd
                                })
                                .then(authRes => authRes.json())
                                .then(authData => {
                                    btnReauth.textContent = 'Re-autenticar y Guardar';
                                    btnReauth.disabled = false;
                                    
                                    if (authData.success) {
                                        if (authModal && authModal.close) authModal.close();
                                        if (pwdInput) pwdInput.value = '';
                                        if (overlay) overlay.style.display = 'flex';
                                        doFetch(); 
                                    } else {
                                        alert('Contraseña incorrecta');
                                    }
                                })
                                .catch(err => {
                                    btnReauth.textContent = 'Re-autenticar y Guardar';
                                    btnReauth.disabled = false;
                                    alert('Error de conexión');
                                });
                            };
                        }
                        return Promise.reject('REQUIRES_AUTH');
                    }
                    if (!res.ok) throw new Error('HTTP ' + res.status);
                    return res.json();
                })
                .then(data => {
                    if (overlay) overlay.style.display = 'none';
                    if (data && data.success) {
                        window._lastLocalCatalogSaveTime = Date.now();
                        resolve(data);
                    } else {
                        var errStr = (data && data.error) ? data.error : 'Error desconocido';
                        alert('Error al guardar: ' + errStr);
                        reject(errStr);
                    }
                })
                .catch(err => {
                    if (err !== 'REQUIRES_AUTH') {
                        if (overlay) overlay.style.display = 'none';
                        console.error('Fetch error:', err);
                        alert('Fallo la conexión con el servidor.');
                        reject(err);
                    }
                });
            }
            
            doFetch();
        });
    };

});
