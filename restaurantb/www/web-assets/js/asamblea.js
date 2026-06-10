/**
 * SADM Tlapa - Asamblea Microwebapp Interaction Helpers
 */

let asamblea_activa = null;
let lista_asambleas_cache = [];

$(document).ready(function() {
    // Vista inicial: Administración
    switchView('admin');
    $('#buscador').keypress(function(e) { if (e.which == 13) buscar(); });
});

function switchView(view) {
    $('.view-item').hide();
    $(`#view-${view}`).fadeIn();
    if (view === 'registro') {
        cargarInfoAsamblea();
        setTimeout(() => $('#buscador').focus(), 300);
    } else {
        cargarAsambleasAdmin();
        cargarMultaDefault();
    }
}

// --- CARGA DE MULTA DESDE BD ---

function cargarMultaDefault() {
    $.getJSON('index.php?action=peticion&metodo=multa_default', function(data) {
        if (data && data.multa !== null && data.multa !== undefined) {
            $('#lbl-multa-valor').text('$ ' + parseFloat(data.multa).toFixed(2));
            $('#new-multa').val(data.multa);
        } else {
            $('#lbl-multa-valor').text('$ 150.00 (valor predeterminado)');
            $('#new-multa').val(150);
        }
    }).fail(function() {
        $('#lbl-multa-valor').text('$ 150.00 (valor predeterminado)');
        $('#new-multa').val(150);
    });
}

// --- LÓGICA DE REGISTRO ---

function cargarInfoAsamblea() {
    $('#msg-lock').remove();
    $.getJSON('index.php?action=peticion&metodo=info_asamblea', function(data) {
        if (!data) {
            $('#asamblea-info-header').text('No hay asambleas registradas.');
            $('#id-cont-reg').hide();
            return;
        }
        asamblea_activa = data;
        $('#asamblea-info-header').text(data.nombre || 'Asamblea sin nombre');
        $('#asamblea-notas-header').text('FECHA: ' + data.fecha);
        
        const estados = { 
            0: { txt: 'CREADA (ESPERA)', clr: '#888' },
            1: { txt: 'ABIERTA', clr: '#28a745' },
            2: { txt: 'PAUSADA', clr: '#ffc107' },
            3: { txt: 'CERRADA', clr: '#dc3545' }
        };
        const est = estados[data.estado];
        $('#status-indicator').html(`<span style="background:${est.clr}; color:white; padding:3px 10px; border-radius:10px; font-size:10px; font-weight:bold;">${est.txt}</span>`);
        
        if (data.estado == 1) {
            $('#id-cont-reg').show();
        } else {
            $('#id-cont-reg').hide();
            $('#id-cont-reg').after(`<div id="msg-lock" style="padding:15px; color:#721c24; background:#f8d7da; border:1px solid #f5c6cb; border-radius:5px; font-weight:bold; text-align:center; margin-top:10px;">El registro está cerrado o aún no ha iniciado.<br><small>Vaya a "Administración" para iniciar la sesión.</small></div>`);
        }
        
        cargarListaAsistentes();
        actualizarStats();
    });
}

function buscar() {
    const q = $('#buscador').val();
    if (q.length < 1) return;

    $.post('index.php?action=peticion', { metodo: 'buscar', q: q }, function(data) {
        const results = data; // jQuery parses JSON automatically with header
        const tbody = $('#lista-resultados');
        const container = $('#resultados-busqueda');
        tbody.empty();
        
        if (results.length > 0) {
            container.show();
            results.forEach(item => {
                const isBaja = item.todos_baja;
                const tr = $(`<tr class="renglon ${isBaja ? '' : 'clicable'}"></tr>`);
                
                // Format contracts badges
                let contratosHtml = item.contratos.map(c => {
                    return `<span style="background:${c.is_baja ? '#eee' : '#e0f0ff'}; color:${c.is_baja ? '#999' : '#0056b3'}; padding: 2px 5px; border-radius: 3px; border: 1px solid ${c.is_baja ? '#ddd' : '#b8daff'}; margin-right: 3px; display: inline-block;">
                        ${c.numcontrato} ${c.is_baja ? '<small>(Baja)</small>' : ''}
                    </span>`;
                }).join(' ');

                tr.append(`<td style="padding: 5px;">${contratosHtml}</td>`);
                tr.append(`<td style="padding: 5px; font-size:10px; ${isBaja ? 'color:#999;' : ''}" class="mayusculas">${item.nombre} ${isBaja ? '<br><span style="color:red; font-weight:bold;">[BAJA DEFINITIVA GLOBAL]</span>' : ''}<br><span style="font-size:9px; color:#666;">${item.domicilio_base || ''}</span></td>`);
                
                if (isBaja) {
                    tr.append(`<td style="padding: 5px; text-align:center;"><span title="El usuario no tiene contratos activos." style="cursor:help;">🚫</span></td>`);
                } else {
                    tr.append(`<td style="padding: 5px;"><input type="button" value="OK" style="font-size: 9px; padding: 2px 5px;" onclick="registrarAsistencia('${item.numcontrato_base}');"></td>`);
                }
                tbody.append(tr);
            });
        } else {
            container.hide();
            alert('No se encontraron contratos con esa búsqueda.');
        }
    });
}

function registrarAsistencia(numcontrato) {
    const nota = $('#reg-nota').val();
    $.post('index.php?action=peticion', { 
        metodo: 'asistir', 
        id_asamblea: asamblea_activa.id, 
        numcontrato: numcontrato,
        nota: nota
    }, function(resp) {
        const data = resp; // jQuery parses JSON automatically
        if (data.status === 'success') {
            $('#resultados-busqueda').hide();
            $('#buscador').val('');
            $('#reg-nota').val('');
            cargarListaAsistentes();
            actualizarStats();
            generarYMostrarTicket(numcontrato, data.contratos, data.nombre_usuario);
        } else {
            alert(data.message);
        }
    });
}

function cargarListaAsistentes() {
    $.getJSON(`index.php?action=peticion&metodo=lista&id_asamblea=${asamblea_activa.id}`, function(data) {
        const tbody = $('#lista-asistentes');
        tbody.empty();
        data.forEach(item => {
            const tr = $('<tr class="renglon"></tr>');
            
            // Formatear la lista de contratos registrados
            const ctosHTML = item.contratos_agrupados.split(', ').map(c => 
                `<span style="background:#e0f0ff; color:#0056b3; padding: 2px 4px; border-radius: 3px; border: 1px solid #b8daff; margin-right: 2px; font-size: 9px;">${c}</span>`
            ).join(' ');

            tr.append(`<td style="padding: 5px;">${ctosHTML}</td>`);
            tr.append(`<td style="padding: 5px; font-size: 10px;" class="mayusculas">${item.nombre}</td>`);
            tr.append(`<td style="padding: 5px; font-size: 9px; color: #555;" class="mayusculas">${item.domicilio || ''}</td>`);
            tr.append(`<td style="padding: 5px; font-size: 10px; color: #666; text-align: center;">${item.entrada.split(' ')[1]}</td>`);
            
            // El link de reinprimir envia todos los contratos en su formato json nativo
            tr.append(`<td style="padding: 5px; text-align: center;"><a href="#" onclick='generarYMostrarTicket("${item.id_contrato_main}", ${item.contratos_json}, "${item.nombre.replace(/'/g, "\\'")}"); return false;' title="Reimprimir">📄</a></td>`);
            tbody.append(tr);
        });
    });
}

function actualizarStats() {
    $.getJSON(`index.php?action=peticion&metodo=stats&id_asamblea=${asamblea_activa.id}`, function(data) {
        if(!data.asistencia) return;
        const uPct = ((data.asistencia.usr / data.padron.t_usr) * 100).toFixed(1);
        const cPct = ((data.asistencia.ctos / data.padron.t_ctos) * 100).toFixed(1);
        
        $('#stat-usr-pct').text(uPct + '%');
        $('#stat-usr-count').text(data.asistencia.usr);
        $('#stat-cto-pct').text(cPct + '%');
        $('#stat-cto-count').text(data.asistencia.ctos);
        $('#stat-padron-usr').text(data.padron.t_usr);
        $('#stat-padron-ctos').text(data.padron.t_ctos);
    });
}

// --- LÓGICA DE ADMINISTRACIÓN ---

function cargarAsambleasAdmin() {
    $.getJSON('index.php?action=peticion&metodo=listar_asambleas', function(data) {
        lista_asambleas_cache = data;
        const tbody = $('#lista-asambleas-admin');
        tbody.empty();
        data.forEach(as => {
            const tr = $('<tr class="renglon"></tr>');
            const estadosIcon = { 0: '⚪', 1: '🟢', 2: '🟡', 3: '🔴' };
            const estadosTxt = { 0: 'Creada / En Espera', 1: 'Abierta / En Pase', 2: 'Pausada temporalmente', 3: 'Asamblea finalizada' };
            
            tr.append(`<td style="text-align:center; cursor:help;" title="${estadosTxt[as.estado]}">${estadosIcon[as.estado]}</td>`);
            tr.append(`<td style="font-weight:bold; font-size:10px;">${as.nombre || '<em style="color:#999;">Sin nombre</em>'}</td>`);
            tr.append(`<td style="font-size:10px;">${as.fecha}</td>`);
            tr.append(`<td>$${as.multa}</td>`);
            
            let actions = '';
            // Obtenemos la fecha de hoy "YYYY-MM-DD" local
            const tzOffset = (new Date()).getTimezoneOffset() * 60000; 
            const hoy = (new Date(Date.now() - tzOffset)).toISOString().split('T')[0];

            const btnStyle = "text-decoration:none; font-size:10px; font-weight:bold; padding:2px 5px;";

            if (as.estado == 0) {
                // Estado CREADA: puede Iniciar
                actions += `<a style="${btnStyle} color:#0056b3;" href="#" onclick="actualizarEstado(${as.id}, 1); return false;">▶ Iniciar Pase</a>`;
            } else if (as.estado == 1) {
                // Estado ABIERTA: puede Cerrar, y navegar a Registro
                actions += `<a style="${btnStyle} color:#dc3545;" href="#" onclick="actualizarEstado(${as.id}, 3); return false;">⏹ Cerrar</a>`;
                actions += ` &nbsp;|&nbsp; <a style="${btnStyle} color:#0674B7;" href="#" onclick="irAPaseAsamblea(${as.id}); return false;">Ir a Registro</a>`;
            } else if (as.estado == 2) {
                // Estado PAUSADA: puede Cerrar
                actions += `<a style="${btnStyle} color:#dc3545;" href="#" onclick="actualizarEstado(${as.id}, 3); return false;">⏹ Cerrar</a>`;
            } else if (as.estado == 3) {
                // Estado CERRADA: puede Descargar y Reabrir
                actions += `<a style="${btnStyle} color:#28a745;" href="index.php?action=peticion&metodo=descargar&id_asamblea=${as.id}">Descargar TXT</a>`;
                
                // Cálculo de fecha límite: 7 días después de la asamblea
                const fAsamblea = new Date(as.fecha + 'T00:00:00');
                const fLimite = new Date(fAsamblea);
                fLimite.setDate(fLimite.getDate() + 7);
                const fLimiteStr = fLimite.toISOString().split('T')[0];

                // Permitir REABRIR si estamos dentro de los 7 días de gracia
                if (hoy <= fLimiteStr) {
                    actions += ` &nbsp;|&nbsp; <a style="${btnStyle} color:#666;" href="#" onclick="actualizarEstado(${as.id}, 1); return false;">↺ Reabrir</a>`;
                }
            }
            
            tr.append(`<td style="text-align:center;">${actions}</td>`);
            tbody.append(tr);
        });
    });
}

/**
 * Navega a la vista de Registro para una asamblea específica
 */
function irAPaseAsamblea(id) {
    // Cargar la info de esta asamblea específica y cambiar a vista de registro
    $.getJSON('index.php?action=peticion&metodo=info_asamblea&id=' + id, function(data) {
        if (data) {
            asamblea_activa = data;
            switchView('registro');
        }
    });
}

function actualizarEstado(id, est) {
    const as = lista_asambleas_cache.find(a => a.id == id);
    if (!as) return;

    let msg = "¿Seguro que desea cambiar el estado de la asamblea?";
    
    if (est == 3) {
        msg = "¡ATENCIÓN! Va a CERRAR la asamblea. Ya no se podrán registrar más asistentes.\n\n¿Desea continuar y cerrarla?";
    } else if (est == 1 && as.estado == 3) {
        msg = "ATENCIÓN: Está a punto de REABRIR una asamblea que ya había sido cerrada.\n\n¿Está seguro de continuar?";
    } else if (est == 1 && as.estado == 0) {
        msg = "Va a iniciar el pase de lista para: " + as.nombre + ".\n¿Proceder?";
    } else if (est == 2) {
        msg = "Va a PAUSAR el registro. Nadie podrá pasar lista hasta que se reanude.\n¿Proceder?";
    }
    
    if (!confirm(msg)) return;
    
    $.post('index.php?action=peticion', { metodo: 'cambiar_estado', id: id, estado: est }, function() {
        cargarAsambleasAdmin();
        if(est == 1) {
            if (confirm("La asamblea está abierta.\n¿Desea ir a la pantalla de Registro en este momento?")) {
                irAPaseAsamblea(id);
            }
        } else if (est == 3) {
            alert("Asamblea cerrada correctamente. Ya puede descargar el reporte TXT desde la tabla.");
        }
    });
}

function crearAsamblea(e) {
    e.preventDefault();
    const nombre = $('#new-nombre').val();
    const fecha = $('#new-fecha').val();
    const multa = $('#new-multa').val();
    
    if (nombre && nombre.trim().length > 0 && (nombre.trim().length < 8 || nombre.trim().length > 50)) return alert('Si proporciona un nombre, debe tener entre 8 y 50 caracteres.');
    if (!fecha) return alert('Seleccione una fecha.');

    $.post('index.php?action=peticion', { metodo: 'crear_asamblea', nombre: nombre, fecha: fecha, multa: multa }, function(data) {
        if(data.status === 'success') {
            alert('Asamblea creada correctamente.');
            $('#form-nueva-asamblea')[0].reset();
            cargarAsambleasAdmin();
        } else {
            alert('Error: ' + data.message);
        }
    });
}

// --- UTILIDADES ---

function generarYMostrarTicket(contrato_main, contratos_all, nombre_persona) {
    if(!asamblea_activa) return;
    
    // Formato de fecha de asamblea en letra
    const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    const fParts = asamblea_activa.fecha.split('-');
    const fechaEnLetra = parseInt(fParts[2]) + ' de ' + meses[parseInt(fParts[1]) - 1] + ' de ' + fParts[0];

    // Formato de registro actual
    const now = new Date();
    const registroStr = now.getFullYear() + "-" + 
                    String(now.getMonth() + 1).padStart(2, '0') + "-" + 
                    String(now.getDate()).padStart(2, '0') + " " + 
                    now.toLocaleTimeString('en-GB');

    const html = `
        <div style="text-align: left; font-family: 'Courier New', Courier, monospace; color: black; line-height: 1.0; width: 100%;">
            <h2 style="margin: 0; font-size: 20px; text-transform: uppercase; border-bottom: 1px solid black; padding-bottom: 1px;">RECIBO DE ASISTENCIA</h2>
            <p style="margin: 2px 0 0 0; font-size: 15px; font-weight: bold;">Asamblea del ${fechaEnLetra}</p>
            <div style="margin: 8px 0;">
                <b style="font-size: 19px; text-transform: uppercase;">${nombre_persona || ''}</b>
            </div>
            <div style="font-size: 18px; margin: 5px 0; font-weight: bold;">
                Contratos: ${contratos_all.join(', ')}
            </div>
            <p style="font-size: 17px; margin: 5px 0; font-weight: bold; white-space: nowrap;">Registro: ${registroStr}</p>
            <hr style="border: 0; border-top: 1px dashed #000; margin: 8px 0;">
            <p style="font-size: 13px; text-align: left; margin: 0; text-transform: uppercase; line-height: 1.1; font-weight: bold;">
                Dirección de Agua Potable y Alcantarillado ${now.getFullYear()}<br>Tlapa de Comonfort
            </p>
            <div style="height: 10px;"></div>
        </div>
    `;
    mostrarTicket(html);
}

function descargarTxt() {
    if (!asamblea_activa) return;
    window.location.href = `index.php?action=peticion&metodo=descargar&id_asamblea=${asamblea_activa.id}`;
}
