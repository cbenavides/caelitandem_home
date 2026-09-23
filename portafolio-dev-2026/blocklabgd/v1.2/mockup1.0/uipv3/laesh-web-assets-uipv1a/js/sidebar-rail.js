/**
 * sidebar-rail.js — LAESH Portal
 * Funcionalidades compartidas del sidebar colapsable en desktop (≥1025px):
 *
 *  1. syncPad  — mantiene .app-layout alineado bajo .portal-access-header fijo.
 *               (app.js hace lo mismo para medicos/labadmin; para gestion-web.html
 *               este script es el único que lo compensa.)
 *
 *  2. Rail toggle — botón #sidebar-rail-toggle que colapsa (65px) / expande (260px)
 *               el sidebar; persiste en localStorage['laesh_sidebar_expanded'].
 *               Al expandir, emite el evento 'laesh:sidebarExpand' para que el SFS
 *               de cada página sepa que debe cerrarse.
 *
 * Uso: <script src="/laesh-web-assets/js/sidebar-rail.js"></script>
 *       Incluir DESPUÉS de app.js (cuando aplique) y justo antes de </body>.
 *
 * API pública: window.laeshSidebarRail = { isExpanded, setExpanded }
 */
(function () {
    'use strict';

    /* ── 1. syncPad ────────────────────────────────────────────────────────── */
    /* Mide el portal-access-header y escribe paddingTop en .app-layout.
       En medicos/labadmin app.js ya hace esto; la segunda llamada es inocua
       (mismo valor). En gestion-web.html este bloque es el único que lo hace. */
    var hdr = document.querySelector('.portal-access-header');
    var lay = document.querySelector('.app-layout');

    if (hdr && lay) {
        function syncPad() {
            if (window.innerWidth >= 1025) {
                lay.style.paddingTop = hdr.getBoundingClientRect().height + 'px';
            }
            /* En tablet/móvil app.js ya gestiona el offset — no sobreescribir. */
        }
        requestAnimationFrame(syncPad);
        window.addEventListener('resize', syncPad);
    }

    /* ── 2. Sidebar Rail toggle ────────────────────────────────────────────── */
    var LS_KEY    = 'laesh_sidebar_expanded';
    var sidebar   = document.querySelector('.app-layout > .sidebar');
    var toggleBtn = document.getElementById('sidebar-rail-toggle');

    /* Si la página no tiene rail (sin botón o sin sidebar) → salir sin error */
    if (!sidebar || !toggleBtn) return;

    var SVG_RIGHT = '<polyline points="9 18 15 12 9 6"/>';  /* › expandir  */
    var SVG_LEFT  = '<polyline points="15 18 9 12 15 6"/>'; /* ‹ colapsar  */
    var SVG_WRAP  = 'width="14" height="14" viewBox="0 0 24 24" fill="none" '
                  + 'stroke="currentColor" stroke-width="2.5" '
                  + 'stroke-linecap="round" stroke-linejoin="round"';

    function isExpanded() {
        return sidebar.classList.contains('sidebar-expanded');
    }

    function setExpanded(exp) {
        if (exp) {
            sidebar.classList.add('sidebar-expanded');
            toggleBtn.innerHTML = '<svg ' + SVG_WRAP + '>' + SVG_LEFT + '</svg>';
            try { sessionStorage.setItem(LS_KEY, '1'); } catch(e){}
            /* Notificar a los SFS inline de cada página para que se cierren */
            document.dispatchEvent(new CustomEvent('laesh:sidebarExpand'));
        } else {
            sidebar.classList.remove('sidebar-expanded');
            toggleBtn.innerHTML = '<svg ' + SVG_WRAP + '>' + SVG_RIGHT + '</svg>';
            try { sessionStorage.setItem(LS_KEY, '0'); } catch(e){}
        }
    }

    /* Restaurar preferencia guardada (colapsado por defecto si no hay registro) */
    var savedLeft = '0';
    try { savedLeft = sessionStorage.getItem(LS_KEY); } catch(e){}
    setExpanded(savedLeft === '1');

    toggleBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        setExpanded(!isExpanded());
    });

    /* ── 3. Sidebar Right Rail toggle ────────────────────────────────────────── */
    var LS_KEY_RIGHT   = 'laesh_sidebar_right_expanded';
    var sidebarRight   = document.getElementById('sidebar-right');
    var toggleRightBtn = document.getElementById('sidebar-right-toggle');

    if (sidebarRight && toggleRightBtn) {
        var SVG_RIGHT_ARR = '<polyline points="9 18 15 12 9 6"/>';  /* › colapsar  */
        var SVG_LEFT_ARR  = '<polyline points="15 18 9 12 15 6"/>'; /* ‹ expandir  */
        var SVG_WRAP_ARR  = 'width="14" height="14" viewBox="0 0 24 24" fill="none" '
                          + 'stroke="currentColor" stroke-width="2.5" '
                          + 'stroke-linecap="round" stroke-linejoin="round"';

        function isRightExpanded() {
            return sidebarRight.classList.contains('sidebar-right-expanded');
        }

        function setRightExpanded(exp) {
            var content = sidebarRight.querySelector('.sidebar-right-content');
            if (exp) {
                sidebarRight.classList.add('sidebar-right-expanded');
                if (content) content.style.display = 'block';
                toggleRightBtn.innerHTML = '<svg ' + SVG_WRAP_ARR + '>' + SVG_RIGHT_ARR + '</svg>';
                try { sessionStorage.setItem(LS_KEY_RIGHT, '1'); } catch(e){}
            } else {
                sidebarRight.classList.remove('sidebar-right-expanded');
                if (content) content.style.display = 'none';
                toggleRightBtn.innerHTML = '<svg ' + SVG_WRAP_ARR + '>' + SVG_LEFT_ARR + '</svg>';
                try { sessionStorage.setItem(LS_KEY_RIGHT, '0'); } catch(e){}
            }
        }

        // Restore preference (collapsed by default to preserve workspace width)
        var savedRight = '0';
        try { savedRight = sessionStorage.getItem(LS_KEY_RIGHT); } catch(e){}
        setRightExpanded(savedRight === '1');

        toggleRightBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            setRightExpanded(!isRightExpanded());
        });
    }

    /* Exponer API para que el SFS inline de cada página consulte el estado */
    window.laeshSidebarRail = { 
        isExpanded: isExpanded, 
        setExpanded: setExpanded,
        isRightExpanded: typeof isRightExpanded === 'function' ? isRightExpanded : null,
        setRightExpanded: typeof setRightExpanded === 'function' ? setRightExpanded : null
    };

})();
