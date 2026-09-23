/**
 * solicitud-dac.js — Ventana de impresión de Solicitud Digital de Análisis Clínicos
 *
 * GAP-RC-01 (cerrado 2026-09-21): antes, cada portal (Médico/Recepción)
 * reconstruía manualmente los ~14 campos de la orden y los empujaba por
 * querystring — mecanismo frágil que causó 4 bugs reales el mismo día
 * (grilla de estudios rota, diagnóstico perdido, fecha confundida con un
 * estudio, celular/edad/sexo faltantes), todos por el mismo patrón: lógica
 * duplicada entre medicos.js/labadmin.js + datos sincronizados a mano en
 * varios archivos sin ninguna alerta cuando algo se quedaba fuera.
 *
 * Ahora esta ventana solo recibe `id` (folio) y `portal` (rc|md) por URL, y
 * consulta la orden real directamente a BD vía GET /laesh/{portal}/api/orden
 * — fuente única de verdad. Ver RC\Negocio\Ordenes::obtenerOrdenPorFolio().
 */
(function() {
    var p = new URLSearchParams(window.location.search);
    var id = p.get('id') || '';
    var portal = (p.get('portal') === 'md') ? 'md' : 'rc';

    var set = function(elId, val) {
        var el = document.getElementById(elId);
        if (el) el.textContent = val || '';
    };

    function formatFechaDDMMYYYY(fechaStr) {
        if (!fechaStr) {
            var now = new Date();
            var dd = String(now.getDate()).padStart(2, '0');
            var mm = String(now.getMonth() + 1).padStart(2, '0');
            var yyyy = now.getFullYear();
            return dd + ' - ' + mm + ' - ' + yyyy;
        }
        var str = fechaStr.toString().trim();
        var meses = {
            'enero': '01', 'febrero': '02', 'marzo': '03', 'abril': '04',
            'mayo': '05', 'junio': '06', 'julio': '07', 'agosto': '08',
            'septiembre': '09', 'octubre': '10', 'noviembre': '11', 'diciembre': '12'
        };
        var textMatch = str.match(/^(\d{1,2})\s+de\s+([a-z]+)\s+de\s+(\d{4})/i);
        if (textMatch) {
            var d = textMatch[1].padStart(2, '0');
            var m = meses[textMatch[2].toLowerCase()] || '01';
            var y = textMatch[3];
            return d + ' - ' + m + ' - ' + y;
        }
        // hora_captura de MariaDB llega como "YYYY-MM-DD HH:MM:SS"
        var isoMatch = str.match(/^(\d{4})[-/](\d{1,2})[-/](\d{1,2})/);
        if (isoMatch) {
            return isoMatch[3].padStart(2, '0') + ' - ' + isoMatch[2].padStart(2, '0') + ' - ' + isoMatch[1];
        }
        var dmyMatch = str.match(/^(\d{1,2})[-/](\d{1,2})[-/](\d{4})/);
        if (dmyMatch) {
            return dmyMatch[1].padStart(2, '0') + ' - ' + dmyMatch[2].padStart(2, '0') + ' - ' + dmyMatch[3];
        }
        return str;
    }

    function mostrarError(mensaje) {
        set('dac-paciente', '—');
        set('dac-celular', '—');
        set('dac-edad', '—');
        set('dac-sexo', '—');
        set('dac-folio', id || '—');
        set('dac-fecha', formatFechaDDMMYYYY(null));
        set('dac-diagnostico', mensaje || 'No se pudo cargar la solicitud.');
        var ol = document.getElementById('dac-estudios-list');
        if (ol) {
            ol.innerHTML = '';
            var li = document.createElement('li');
            li.textContent = mensaje || 'No se pudo cargar la solicitud.';
            ol.appendChild(li);
        }
    }

    function poblarDocumento(orden) {
        var paciente = orden.paciente || '—';
        var celular = orden.celular || '—';
        var diagnostico = orden.diagnostico || '';

        var estudiosArr = [];
        try {
            estudiosArr = JSON.parse(orden.estudios || '[]');
            if (!Array.isArray(estudiosArr)) estudiosArr = [];
        } catch (e) { estudiosArr = []; }
        if (orden.otros_estudios) estudiosArr.push('Otros estudios: ' + orden.otros_estudios);

        var medico = (orden.medico || 'Médico General').toString();
        // Sanitizar cualquier duplicación de "Dr(a). Dr(a)." o "Dr. Dr."
        medico = medico.replace(/^(Dr\(a\)\.|\bDr\.\b|\bDra\.\b|\bDr\b)\s*(?:Dr\(a\)\.|\bDr\.\b|\bDra\.\b|\bDr\b\s*)*/gi, 'Dr. ').trim();

        var folio = orden.folio || id || '1';

        // Construir nombre sugerido para PDF: sd-laesh-#folio-nombre-completo-persona.pdf
        var folioSanit = folio.toString().trim().replace(/[^a-zA-Z0-9]/g, '');
        var pacienteSanit = paciente.toString().trim().toLowerCase()
            .normalize("NFD").replace(/[̀-ͯ]/g, "") // remover acentos
            .replace(/[^a-z0-9]/g, '-')                     // guiones para espacios/especiales
            .replace(/-+/g, '-')                            // evitar guiones dobles
            .replace(/^-|-$/g, '');                         // quitar guiones bordes

        var suggestedPdfName = 'sd-laesh-' + (folioSanit || '0') + (pacienteSanit ? '-' + pacienteSanit : '');
        document.title = suggestedPdfName;

        set('tb-folio', folio);
        set('tb-paciente', paciente);

        // Normalizar valor de Sexo a Masculino o Femenino
        var sexoFormatted = (orden.sexo || '').toString().trim();
        if (/^masc|^homb|^h$/i.test(sexoFormatted)) sexoFormatted = 'Masculino';
        else if (/^fem|^muj|^m$/i.test(sexoFormatted)) sexoFormatted = 'Femenino';

        // Formatear Edad
        var edadFormatted = (orden.edad === null || orden.edad === undefined) ? '' : orden.edad.toString().trim();
        if (edadFormatted && !/año|ano/i.test(edadFormatted) && /^\d+$/.test(edadFormatted)) {
            edadFormatted += ' años';
        }

        var fechaFormatted = formatFechaDDMMYYYY(orden.fecha);

        set('dac-paciente', paciente);
        set('dac-celular', celular);
        set('dac-edad', edadFormatted || '—');
        set('dac-sexo', sexoFormatted || '—');
        set('dac-folio', folio);
        set('dac-fecha', fechaFormatted);
        set('dac-diagnostico', diagnostico || 'Sin diagnóstico especificado.');
        set('dac-medico-nombre', medico);
        set('dac-medico-especialidad', orden.especialidad || 'Medicina General');
        set('dac-medico-cedula', orden.cedula || 'CED-N/A');
        set('dac-medico-universidad', orden.universidad || '');
        set('dac-medico-lugar', orden.lugar || '');

        var ol = document.getElementById('dac-estudios-list');
        if (ol) {
            ol.innerHTML = '';
            if (estudiosArr.length === 0) {
                var li = document.createElement('li');
                li.textContent = 'Sin estudios especificados.';
                ol.appendChild(li);
            } else {
                estudiosArr.forEach(function(e) {
                    var liE = document.createElement('li');
                    liE.textContent = e;
                    ol.appendChild(liE);
                });
            }
        }
    }

    // Limpiar query-params de la barra de direcciones (popup queda limpio)
    try { history.replaceState({}, '', window.location.pathname); } catch (e) {}

    if (!id) {
        mostrarError('Folio no especificado.');
    } else {
        fetch('/laesh/' + portal + '/api/orden?folio=' + encodeURIComponent(id), { credentials: 'same-origin' })
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (data && data.success && data.orden) {
                    poblarDocumento(data.orden);
                } else {
                    mostrarError((data && data.error) || 'Orden no encontrada.');
                }
            })
            .catch(function() {
                mostrarError('Error de conexión al cargar la solicitud.');
            });
    }

    // Auto-ajustar ventana si se abre como popup
    function ajustarVentana() {
        try {
            var docH = document.documentElement.scrollHeight;
            var chrome = window.outerHeight - window.innerHeight;
            window.resizeTo(window.outerWidth, docH + chrome + 8);
        } catch (e) {}
    }
    window.addEventListener('load', function() {
        ajustarVentana();
        setTimeout(ajustarVentana, 300);
    });
})();

/* U-01: Botones de acción del toolbar — sin onclick inline */
document.addEventListener('DOMContentLoaded', function() {
    var btnPrint = document.getElementById('btn-dac-print');
    var btnClose = document.getElementById('btn-dac-close');
    if (btnPrint) btnPrint.addEventListener('click', function() { window.print(); });
    if (btnClose) btnClose.addEventListener('click', function() {
        /* Si estamos dentro de un overlay iframe → cerrar el overlay en la ventana padre */
        if (window.parent !== window) {
            try {
                var overlay = window.parent.document.getElementById('sol-overlay');
                if (overlay) { overlay.remove(); return; }
            } catch(e) {}
        }
        /* Fallback: navegación directa o popup clásico */
        if (window.history.length > 1) { window.history.back(); }
        else { window.close(); }
    });
});
