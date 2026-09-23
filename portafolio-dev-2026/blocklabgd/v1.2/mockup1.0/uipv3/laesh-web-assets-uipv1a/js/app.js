// Audio helper de notificaciones (Web Audio API oscillator)
function playWhistle() {
    try {
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioCtx.createOscillator();
        const gainNode = audioCtx.createGain();
        oscillator.connect(gainNode);
        gainNode.connect(audioCtx.destination);
        oscillator.type = 'sine';
        oscillator.frequency.setValueAtTime(1200, audioCtx.currentTime);
        oscillator.frequency.exponentialRampToValueAtTime(800, audioCtx.currentTime + 0.3);
        gainNode.gain.setValueAtTime(0.5, audioCtx.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.3);
        oscillator.start();
        oscillator.stop(audioCtx.currentTime + 0.3);
    } catch(e) {
        console.log("Audio no soportado");
    }
}

// Overlay iframe compartido para visualización/impresión de Solicitud DAC
function _abrirSolOverlay(url) {
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
}
window._abrirSolOverlay = _abrirSolOverlay;

// ─────────────────────────────────────────────────────────────
// Portal Header + Nav‑Strip — labadmin.html, medicos.html
//
// En tablet/móvil (≤1024px) el header y la tira de iconos son
// position:fixed, por eso el app-layout necesita padding-top igual
// a la suma de ambas alturas. app.js mide y publica dos CSS vars:
//   --portal-header-h        → altura real del nav header
//   --portal-content-offset  → header + tira (padding-top del layout)
//
// En móvil (≤767px) aparece el hamburger (CSS display:flex).
// Al pulsarlo se muestra .sidebar-mobile-only como mini-panel
// anclado a la derecha del viewport (usuario + Cerrar Sesión).
// ─────────────────────────────────────────────────────────────
(function initPortalHamburger() {
    var header    = document.querySelector('.portal-access-header');
    var sidebar   = document.querySelector('.app-layout > .sidebar');
    var appLayout = document.querySelector('.app-layout');
    if (!header || !sidebar) return;

    var btn = null;

    // Medir y publicar alturas; ajustar padding-top del layout.
    // portal-access-header es position:fixed en TODOS los viewports →
    // siempre se necesita al menos headerH de padding-top en app-layout.
    // En tablet/móvil (≤1024px) la tira de iconos también es fixed →
    // se suma sidebarH adicionalmente.
    function syncHeights() {
        var headerH  = header.getBoundingClientRect().height;
        var sidebarH = (window.innerWidth <= 1024)
                       ? sidebar.getBoundingClientRect().height
                       : 0;
        var offset = headerH + sidebarH;
        document.documentElement.style.setProperty('--portal-header-h',       headerH + 'px');
        document.documentElement.style.setProperty('--portal-content-offset', offset  + 'px');
        if (appLayout) appLayout.style.paddingTop = offset + 'px';
    }

    // Primera medición tras render de la tira
    requestAnimationFrame(syncHeights);
    window.addEventListener('resize', function() {
        syncHeights();
        // Cerrar mini-panel si se cambia el tamaño
        if (header.classList.contains('portal-user-open') && btn) {
            header.classList.remove('portal-user-open');
            btn.classList.remove('open');
            btn.setAttribute('aria-expanded', 'false');
        }
    });

    // Inyectar hamburger en el header.
    // CSS lo hace visible solo en ≤767px (.portal-access-header .nav-hamburger { display:flex })
    btn = document.createElement('button');
    btn.className = 'nav-hamburger';
    btn.setAttribute('aria-label', 'Menú usuario');
    btn.setAttribute('aria-expanded', 'false');
    btn.innerHTML = '<span></span><span></span><span></span>';
    header.appendChild(btn);

    function closeUserMenu() {
        header.classList.remove('portal-user-open');
        btn.classList.remove('open');
        btn.setAttribute('aria-expanded', 'false');
    }
    function openUserMenu() {
        syncHeights();
        header.classList.add('portal-user-open');
        btn.classList.add('open');
        btn.setAttribute('aria-expanded', 'true');
    }

    btn.addEventListener('click', function(e) {
        e.stopPropagation();
        header.classList.contains('portal-user-open') ? closeUserMenu() : openUserMenu();
    });
    // Cerrar al hacer clic fuera del header
    document.addEventListener('click', function(e) {
        if (!header.contains(e.target)) closeUserMenu();
    });
})();

// ── Portal Search Toggle — lupita en tira tablet/móvil ────────
// Alterna .sidebar-search-open en .app-layout para mostrar el
// panel de búsqueda fijo debajo de la tira de iconos.
// ─────────────────────────────────────────────────────────────
(function initPortalSearch() {
    var searchBtn = document.getElementById('sidebar-search-btn');
    var appLayout = document.querySelector('.app-layout');
    if (!searchBtn || !appLayout) return;

    var inputEl = document.querySelector('.sidebar-search-wrap input');

    function closeSearch() {
        appLayout.classList.remove('sidebar-search-open');
        searchBtn.classList.remove('active');
        searchBtn.setAttribute('aria-expanded', 'false');
    }
    function openSearch() {
        appLayout.classList.add('sidebar-search-open');
        searchBtn.classList.add('active');
        searchBtn.setAttribute('aria-expanded', 'true');
        if (inputEl) { setTimeout(function() { inputEl.focus(); }, 50); }
    }

    searchBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        appLayout.classList.contains('sidebar-search-open') ? closeSearch() : openSearch();
    });

    // Cerrar con Escape o clic fuera del panel y del botón
    document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeSearch(); });
    document.addEventListener('click', function(e) {
        var wrap = document.querySelector('.sidebar-search-wrap');
        if (!wrap) return;
        if (!wrap.contains(e.target) && !searchBtn.contains(e.target)) closeSearch();
    });
})();

// ── Ventanas emergentes LAESH — Drag + Resize ─────────────────
// Hace que TODAS las .modal sean movibles (arrastrar cabecera)
// y redimensionables (resize nativo CSS en esquina inf. derecha).
// Compatible con cualquier HTML que use .modal > .modal-content > .modal-header.
// ─────────────────────────────────────────────────────────────
(function initModalDrag() {
    'use strict';

    function enableDrag(modal) {
        var content = modal.querySelector('.modal-content');
        var header  = modal.querySelector('.modal-header');
        if (!content || !header) return;

        var dragging = false, ox = 0, oy = 0;

        function getCX(ev) { return ev.touches ? ev.touches[0].clientX : ev.clientX; }
        function getCY(ev) { return ev.touches ? ev.touches[0].clientY : ev.clientY; }

        function onStart(e) {
            if (e.target.closest('button, a, input, select, textarea')) return;
            var rect = content.getBoundingClientRect();
            content.style.position = 'fixed';
            content.style.left     = rect.left + 'px';
            content.style.top      = rect.top  + 'px';
            content.style.margin   = '0';
            content.style.transform = 'none';
            modal.style.alignItems     = 'flex-start';
            modal.style.justifyContent = 'flex-start';
            dragging = true;
            ox = getCX(e) - rect.left;
            oy = getCY(e) - rect.top;
            header.style.cursor = 'grabbing';
            document.body.style.userSelect = 'none';
            if (e.type === 'mousedown') e.preventDefault();
        }

        function onMove(e) {
            if (!dragging) return;
            var cx = getCX(e), cy = getCY(e);
            var nl = Math.max(0, Math.min(window.innerWidth  - content.offsetWidth,  cx - ox));
            var nt = Math.max(0, Math.min(window.innerHeight - content.offsetHeight, cy - oy));
            content.style.left = nl + 'px';
            content.style.top  = nt + 'px';
            if (e.type === 'touchmove') e.preventDefault();
        }

        function onEnd() {
            if (!dragging) return;
            dragging = false;
            header.style.cursor = 'grab';
            document.body.style.userSelect = '';
        }

        header.addEventListener('mousedown', onStart);
        header.addEventListener('touchstart', onStart, {passive: false});
        document.addEventListener('mousemove', onMove);
        document.addEventListener('touchmove', onMove, {passive: false});
        document.addEventListener('mouseup', onEnd);
        document.addEventListener('touchend', onEnd);

        /* Restablecer posición cuando el modal se cierra */
        var obs = new MutationObserver(function() {
            if (!modal.classList.contains('show')) {
                content.style.position  = '';
                content.style.left      = '';
                content.style.top       = '';
                content.style.margin    = '';
                content.style.transform = '';
                modal.style.alignItems     = '';
                modal.style.justifyContent = '';
            }
        });
        obs.observe(modal, { attributes: true, attributeFilter: ['class'] });
    }

    /* Esperar al DOM y aplicar a todos los .modal presentes */
    function run() { document.querySelectorAll('.modal').forEach(enableDrag); }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', run);
    } else {
        run();
    }
})();

// ── Portal Médico — Acordeón "Generar Orden Digital" ─────────
// Igual que "Mis Órdenes de Hoy" (collapsible-header / collapsible-content)
(function initOrdenAccordion() {
    var ordenHeader  = document.getElementById('orden-digital-header');
    var ordenContent = document.getElementById('orden-digital-content');
    var ordenArrow   = document.getElementById('orden-digital-arrow');
    if (!ordenHeader || !ordenContent) return;

    ordenHeader.addEventListener('click', function() {
        var isOpen = ordenContent.style.maxHeight !== '0px';
        ordenContent.style.maxHeight = isOpen ? '0px' : '2000px';
        if (ordenArrow) ordenArrow.style.transform = isOpen ? 'rotate(-90deg)' : 'rotate(0deg)';
    });
})();

// ── Sistema de Notificaciones Toast (Reemplazo de alert) ─────────
// Cumple con WCAG 4.1.3 Status Messages (aria-live)
(function initToastSystem() {
    var container = document.getElementById('toast-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toast-container';
        container.setAttribute('aria-live', 'polite');
        container.setAttribute('aria-atomic', 'true');
        // Estilos base para el contenedor (fijo en la esquina inferior derecha o arriba)
        Object.assign(container.style, {
            position: 'fixed',
            bottom: '20px',
            right: '20px',
            zIndex: '9999',
            display: 'flex',
            flexDirection: 'column',
            gap: '10px',
            pointerEvents: 'none'
        });
        document.body.appendChild(container);
    }

    window.showToast = function(message, type = 'info', duration = 4000) {
        var toast = document.createElement('div');
        toast.className = 'laesh-toast laesh-toast-' + type;
        toast.textContent = message;
        
        // Estilos del toast
        Object.assign(toast.style, {
            background: type === 'error' ? '#ef4444' : (type === 'success' ? '#10b981' : '#334155'),
            color: '#ffffff',
            padding: '12px 20px',
            borderRadius: '8px',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
            fontFamily: 'inherit',
            fontSize: '0.9rem',
            fontWeight: '500',
            opacity: '0',
            transform: 'translateY(20px)',
            transition: 'opacity 0.3s ease, transform 0.3s ease',
            pointerEvents: 'auto'
        });

        container.appendChild(toast);

        // Animación de entrada
        requestAnimationFrame(function() {
            toast.style.opacity = '1';
            toast.style.transform = 'translateY(0)';
        });

        // Animación de salida y remoción
        setTimeout(function() {
            toast.style.opacity = '0';
            toast.style.transform = 'translateY(10px)';
            toast.addEventListener('transitionend', function() {
                if (toast.parentNode) toast.parentNode.removeChild(toast);
            });
        }, duration);
    };
})();

// ── G-2 y G-7: Modal Accessibility (Focus Trap, Escape Key, ARIA Roles) ──
(function initModalAccessibility() {
    // 1. Inyectar ARIA roles a todos los modales existentes
    document.querySelectorAll('.modal').forEach(function(modal) {
        if (!modal.hasAttribute('role')) modal.setAttribute('role', 'dialog');
        if (!modal.hasAttribute('aria-modal')) modal.setAttribute('aria-modal', 'true');
    });

    // 2. Manejo global de teclado para modales activos
    document.addEventListener('keydown', function(e) {
        var activeModal = document.querySelector('.modal.show');
        if (!activeModal) return;

        // Escape para cerrar
        if (e.key === 'Escape') {
            var closeBtn = activeModal.querySelector('.close-modal') || activeModal.querySelector('.btn-overlay-sm');
            if (closeBtn) {
                closeBtn.click();
            } else {
                activeModal.classList.remove('show');
                document.body.classList.remove('modal-open');
            }
            return;
        }

        // Focus Trap con Tab
        if (e.key === 'Tab') {
            // Buscar elementos enfocables dentro del modal
            var focusableElements = activeModal.querySelectorAll(
                'a[href], button:not([disabled]), textarea:not([disabled]), input[type="text"]:not([disabled]), ' +
                'input[type="radio"]:not([disabled]), input[type="checkbox"]:not([disabled]), select:not([disabled]), ' +
                '[tabindex]:not([tabindex="-1"])'
            );
            if (focusableElements.length === 0) {
                e.preventDefault();
                return;
            }
            var firstElement = focusableElements[0];
            var lastElement = focusableElements[focusableElements.length - 1];

            if (e.shiftKey) { // Shift + Tab
                if (document.activeElement === firstElement) {
                    if (lastElement) lastElement.focus();
                    e.preventDefault();
                }
            } else { // Solo Tab
                if (document.activeElement === lastElement) {
                    if (firstElement) firstElement.focus();
                    e.preventDefault();
                }
            }
        }
    });
})();

// ── G-6: Atributos aria-label automáticos ──
(function initAccessibilityAttributes() {
    document.querySelectorAll('input[placeholder]:not([aria-label])').forEach(function(el) {
        el.setAttribute('aria-label', el.getAttribute('placeholder'));
    });
    document.querySelectorAll('button[title]:not([aria-label])').forEach(function(el) {
        el.setAttribute('aria-label', el.getAttribute('title'));
    });
})();

// ── Dropdown Draggable ──
(function initFichaDropdownDrag() {
    'use strict';
    function enableDrag(dropdown) {
        var header = dropdown.querySelector('.ficha-dropdown__hdr');
        if (!header) return;
        var dragging = false, ox = 0, oy = 0;
        function getCX(ev) { return ev.touches ? ev.touches[0].clientX : ev.clientX; }
        function getCY(ev) { return ev.touches ? ev.touches[0].clientY : ev.clientY; }

        function onStart(e) {
            if (e.target.closest('button, a, input, select, textarea')) return;
            var rect = dropdown.getBoundingClientRect();
            dropdown.style.position = 'fixed';
            dropdown.style.left     = rect.left + 'px';
            dropdown.style.top      = rect.top  + 'px';
            dropdown.style.margin   = '0';
            dropdown.style.transform = 'none';
            dragging = true;
            ox = getCX(e) - rect.left;
            oy = getCY(e) - rect.top;
            header.style.cursor = 'grabbing';
            document.body.style.userSelect = 'none';
            if (e.type === 'mousedown') e.preventDefault();
        }

        function onMove(e) {
            if (!dragging) return;
            var cx = getCX(e), cy = getCY(e);
            var nl = Math.max(0, Math.min(window.innerWidth  - dropdown.offsetWidth,  cx - ox));
            var nt = Math.max(0, Math.min(window.innerHeight - dropdown.offsetHeight, cy - oy));
            dropdown.style.left = nl + 'px';
            dropdown.style.top  = nt + 'px';
            if (e.type === 'touchmove') e.preventDefault();
        }

        function onEnd() {
            if (!dragging) return;
            dragging = false;
            header.style.cursor = 'grab';
            document.body.style.userSelect = '';
        }

        header.addEventListener('mousedown', onStart);
        header.addEventListener('touchstart', onStart, {passive: false});
        document.addEventListener('mousemove', onMove);
        document.addEventListener('touchmove', onMove, {passive: false});
        document.addEventListener('mouseup', onEnd);
        document.addEventListener('touchend', onEnd);
        var obs = new MutationObserver(function() {
            if (!dropdown.classList.contains('open')) {
                dropdown.style.position  = '';
                dropdown.style.left      = '';
                dropdown.style.top       = '';
                dropdown.style.margin    = '';
                dropdown.style.transform = '';
            }
        });
        obs.observe(dropdown, { attributes: true, attributeFilter: ['class'] });
    }
    function hideDecorativeSVGs() {
        document.querySelectorAll('svg').forEach(function (svg) {
            if (!svg.getAttribute('aria-label') && 
                !svg.getAttribute('aria-labelledby') && 
                !svg.getAttribute('title') && 
                svg.getAttribute('role') !== 'img') {
                svg.setAttribute('aria-hidden', 'true');
                svg.setAttribute('focusable', 'false');
            }
        });
    }
    function run() { 
        document.querySelectorAll('.ficha-dropdown').forEach(enableDrag); 
        hideDecorativeSVGs();
    }
    if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', run); } else { run(); }
})();

// ── Connection Status Indicator (online / offline) ────────────────
(function () {
    'use strict';
    function updateConnectionStatus() {
        var isOnline = navigator.onLine;
        document.querySelectorAll('.status-dot').forEach(function(dot) {
            if (isOnline) {
                dot.className = 'status-dot online';
                dot.parentElement.title = 'Conexión: En Línea';
            } else {
                dot.className = 'status-dot offline';
                dot.parentElement.title = 'Conexión: Fuera de Línea';
            }
        });
    }

    function initConnectionStatus() {
        var headerRight = document.querySelector('.portal-header-right');
        var userBadge = document.querySelector('.user-badge-portal');
        if (headerRight && userBadge && !document.getElementById('conn-status-desktop')) {
            var connDiv = document.createElement('div');
            connDiv.className = 'connection-status';
            connDiv.id = 'conn-status-desktop';
            connDiv.innerHTML = '<span class="status-dot"></span>';
            headerRight.insertBefore(connDiv, userBadge);
        }

        var initialsMob = document.querySelector('.portal-initials-mob');
        var header = document.querySelector('.portal-access-header');
        if (initialsMob && header && !document.getElementById('conn-status-mob')) {
            var connDivMob = document.createElement('div');
            connDivMob.className = 'connection-status-mob';
            connDivMob.id = 'conn-status-mob';
            connDivMob.innerHTML = '<span class="status-dot"></span>';
            header.insertBefore(connDivMob, initialsMob);
        }

        /* Mobile Notification Bell Icon next to online status dot */
        if (initialsMob && header && !document.getElementById('bell-wrap-mob')) {
            var bellMob = document.createElement('div');
            bellMob.className = 'bell-wrap-mob';
            bellMob.id = 'bell-wrap-mob';
            bellMob.title = 'Ver Notificaciones';
            bellMob.setAttribute('role', 'button');
            bellMob.setAttribute('tabindex', '0');
            bellMob.setAttribute('aria-label', 'Ver Notificaciones');
            bellMob.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg><span class="bell-badge" id="badge-notif-mob">0</span>';

            var connMob = document.getElementById('conn-status-mob');
            if (connMob) {
                header.insertBefore(bellMob, connMob);
            } else {
                header.insertBefore(bellMob, initialsMob);
            }

            var isScrolling = false;
            function scrollToNotif(e) {
                if (isScrolling) return;
                isScrolling = true;
                e.preventDefault();
                var targetNotif = document.getElementById('sidebar-right') || document.querySelector('.sidebar-right');
                if (targetNotif) {
                    targetNotif.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
                setTimeout(function() { isScrolling = false; }, 400);
            }

            bellMob.addEventListener('click', scrollToNotif);
            bellMob.addEventListener('touchend', scrollToNotif);

            /* Sync notification badge count */
            var existingBadge = document.getElementById('badge-resultados') || document.getElementById('badge-recepcion') || document.getElementById('badge-notif-cms');
            var mobBadge = document.getElementById('badge-notif-mob');
            if (existingBadge && mobBadge) {
                mobBadge.textContent = existingBadge.textContent;
                if (window.MutationObserver) {
                    var observer = new MutationObserver(function() {
                        mobBadge.textContent = existingBadge.textContent;
                    });
                    observer.observe(existingBadge, { childList: true, characterData: true, subtree: true });
                }
            }
        }

        updateConnectionStatus();
    }

    window.addEventListener('online', updateConnectionStatus);
    window.addEventListener('offline', updateConnectionStatus);

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initConnectionStatus);
    } else {
        initConnectionStatus();
    }
})();

// ── Generic Modal Observer (Autofocus) ──────
(function () {
    'use strict';
    var modalObserver = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            if (mutation.attributeName === 'class') {
                var target = mutation.target;
                if (target.classList.contains('show')) {
                    var firstInput = target.querySelector('input, select, textarea, button');
                    if (firstInput) {
                        setTimeout(function() { firstInput.focus(); }, 100);
                    }
                }
            }
        });
    });

    // Observer starts after page loads
    function runObserver() {
        document.querySelectorAll('.modal').forEach(function (modal) {
            modalObserver.observe(modal, { attributes: true, attributeFilter: ['class'] });
        });
    }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', runObserver);
    } else {
        runObserver();
    }

    // Manejador global estandarizado para apertura del Logo LAESH en nueva pestaña
    document.addEventListener('click', function(e) {
        var a = e.target.closest('a.logo, a.portal-access-link');
        if (a && a.getAttribute('target') === '_blank') {
            e.stopPropagation();
        }
    }, true);
})();

// ─────────────────────────────────────────────────────────────
// Guard de navegación — atrapa el botón "Atrás" del sistema (gap crítico
// 2026-09-22): los portales (Médico/Recepción/Admin) cambian de panel
// solo con JS (clases .active/.d-none), sin history.pushState por panel,
// así que el navegador solo tiene UNA entrada de historial para la
// página del portal. Un solo toque en "Atrás" del teléfono saltaba
// directo a lo que hubiera antes (login o el website público), sacando
// al usuario de una sesión autenticada en pleno uso — la única forma de
// volver era autenticarse de nuevo. Se re-arma el mismo estado en cada
// "popstate" para neutralizar ese salto; la salida real sigue siendo el
// enlace explícito "Cerrar Sesión" del menú, que no pasa por aquí (es
// una navegación normal a /laesh/login/logout.php, no back-navigation).
// app.js solo se carga en los 3 portales autenticados (md/rc/admrc), NO
// en el website público ni en /login/ — ahí "Atrás" funciona normal.
(function initBackButtonGuard() {
    if (!window.history || typeof window.history.pushState !== 'function') return;
    var warned = false;
    history.pushState({ laeshGuard: true }, '', location.href);
    window.addEventListener('popstate', function() {
        history.pushState({ laeshGuard: true }, '', location.href);
        if (!warned) {
            warned = true;
            if (typeof window.showToast === 'function') {
                showToast('Usa "Cerrar Sesión" en el menú para salir del portal.', 'info', 3500);
            }
        }
    });
})();

