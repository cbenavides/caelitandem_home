import re

file_path = "/home/carlos/GitHub/caelitandem_home/restaurantb/www/laesh-web-assets-uipv1a/js/catalog-builder.js"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# PATCH 1: DELETE ROW
delete_search = """            var btnDelete = target.closest('.btn-delete-row');
            if (btnDelete) {
                var row = btnDelete.closest('.row-item');
                var nombre = row.querySelector('.row-name') ? row.querySelector('.row-name').textContent : 'este registro';
                if (confirm('¿Estás seguro de que deseas eliminar ' + nombre + '?')) {
                    var isIGab = !!row.closest('#settings-igabinetes-view');
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
                }
            }"""

delete_replace = """            var btnDelete = target.closest('.btn-delete-row');
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
            }"""
content = content.replace(delete_search, delete_replace)

# PATCH 2: EDIT ROW
edit_search = """                var saveEditFn = function() {
                    var val = input.value.trim();
                    if (val === '') {
                        closeEditFn();
                        return;
                    }
                    spanName.textContent = val;
                    var chk = row.querySelector('.chk-activar-paneles') || row.querySelector('.chk-activar-ipaneles');
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
                };"""

edit_replace = """                var saveEditFn = function() {
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
                };"""
content = content.replace(edit_search, edit_replace)

# PATCH 3: ADD ROW
add_search = """                    var saveFn = function() {
                        var val = input.value.trim();
                        if (val === '') {
                            newRow.remove();
                            return;
                        }
                        
                        var checkboxHTML = '';
                        if (isIGabinete) {
                            checkboxHTML = `<input type="checkbox" class="chk-activar-ipaneles" data-tipo="I. Gabinete" data-nombre="${val}" style="cursor: pointer; transform: scale(1.2);">`;
                        } else {
                            checkboxHTML = `<input type="checkbox" class="chk-activar-paneles" data-tipo="${isGabinete ? 'Gabinete' : 'Sub Gabinete'}" data-nombre="${val}" style="cursor: pointer; transform: scale(1.2);">`;
                        }

                        newRow.innerHTML = `
                            <span class="row-name" style="font-weight: 500;">${val}</span>
                            <div style="display: flex; gap: 0.5rem; align-items: center;">
                                <span class="action-icon btn-edit-row" style="cursor: pointer; color: var(--primary);" title="Editar">✏️</span>
                                <span class="action-icon btn-delete-row" style="cursor: pointer; color: #ef4444;" title="Eliminar">❌</span>
                                ${isGabinete ? '<span class="action-icon btn-ver-subgabinetes" style="cursor: pointer; color: var(--primary-dark);" title="Ver Subgabinetes">📋</span>' : ''}
                                ${checkboxHTML}
                            </div>
                        `;
                        
                        if (isIGabinete && typeof window.bindIGabineteCheckbox === 'function') {
                            var newChk = newRow.querySelector('.chk-activar-ipaneles');
                            if (newChk) window.bindIGabineteCheckbox(newChk);
                        }
                    };"""

add_replace = """                    var saveFn = function() {
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
                    };"""
content = content.replace(add_search, add_replace)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("JS file patched.")
