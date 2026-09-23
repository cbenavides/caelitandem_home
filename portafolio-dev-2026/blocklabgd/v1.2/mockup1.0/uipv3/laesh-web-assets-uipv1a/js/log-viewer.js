/**
 * log-viewer.js — Interactividad del visor de logs LAESH Admin
 * Funcionalidades:
 *   - Auto-refresh configurable
 *   - Descarga del contenido visible como .txt
 *   - Highlight de términos de búsqueda
 */
(function () {
    'use strict';

    // ── Auto-refresh ─────────────────────────────────────────────────────
    let refreshTimer = null;

    function startAutoRefresh(seconds) {
        stopAutoRefresh();
        if (seconds > 0) {
            refreshTimer = setInterval(() => window.location.reload(), seconds * 1000);
        }
    }

    function stopAutoRefresh() {
        if (refreshTimer) { clearInterval(refreshTimer); refreshTimer = null; }
    }

    // ── Descarga del log visible ──────────────────────────────────────────
    window.downloadLog = function () {
        const table = document.getElementById('log-main-table');
        const fileOut = document.getElementById('log-file-output');
        let text = '';

        if (table) {
            const rows = table.querySelectorAll('tr');
            rows.forEach(r => {
                text += Array.from(r.querySelectorAll('th,td'))
                    .map(c => c.textContent.trim())
                    .join(' | ') + '\n';
            });
        } else if (fileOut) {
            text = Array.from(fileOut.querySelectorAll('.log-line'))
                .map(l => l.textContent)
                .join('\n');
        }

        if (!text) { alert('No hay contenido para descargar.'); return; }

        const tab   = new URLSearchParams(window.location.search).get('tab') || 'log';
        const fname = `laesh-${tab}-${new Date().toISOString().slice(0,10)}.txt`;
        const blob  = new Blob([text], { type: 'text/plain' });
        const a     = Object.assign(document.createElement('a'), {
            href: URL.createObjectURL(blob), download: fname
        });
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(a.href);
    };

    // ── Highlight de búsqueda en archivo plano ────────────────────────────
    function highlightSearch() {
        const q = (new URLSearchParams(window.location.search).get('q') || '').trim();
        if (!q) return;
        const lines = document.querySelectorAll('.log-line');
        const re    = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');
        lines.forEach(el => {
            el.innerHTML = el.textContent.replace(re,
                m => `<mark style="background:#fde68a;color:#78350f;border-radius:2px">${m}</mark>`
            );
        });
    }

    // ── Auto-scroll al final del log de archivo plano ─────────────────────
    function scrollToBottom() {
        const wrap = document.querySelector('.log-file-wrap');
        // En archivo plano las líneas más recientes están al inicio (array_reverse en PHP)
        // no hacer scroll
        if (wrap) wrap.scrollTop = 0;
    }

    document.addEventListener('DOMContentLoaded', function () {
        highlightSearch();
        scrollToBottom();

        // Ctrl+F interceptado: enfocar el campo de búsqueda interno
        document.addEventListener('keydown', function (e) {
            if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
                const inp = document.getElementById('log-search-input');
                if (inp) { e.preventDefault(); inp.focus(); inp.select(); }
            }
        });
    });

}());
