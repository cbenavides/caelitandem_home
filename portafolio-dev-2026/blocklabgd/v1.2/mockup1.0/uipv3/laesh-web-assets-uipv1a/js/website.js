/**
 * website.js — Lógica de UI del Sitio Web Público LAESH
 * Laboratorio de Especialidades Hematológicas (LAESH)
 *
 * Módulos incluidos:
 *  1. Intersection Observer — Animaciones al hacer scroll
 *  2. Resaltado activo del menú por posición de scroll
 *  3. Carrusel Hero (autoplay 5s)
 *  4. Menú Hamburguesa para móvil (≤768px)
 *  5. Modal SPA Aviso de Privacidad
 *  6. Pestañas del Mapa (Croquis / Mapa Interactivo / Abrir en Maps)
 *  7. Carrusel Horizontal de Especialidades
 *  8. Carrusel con Fade de Calidad (autoplay 4s)
 *
 * Dependencias: Ninguna (vanilla JS puro)
 * Ruta: /laesh-web-assets/js/website.js
 */

document.addEventListener("DOMContentLoaded", function() {
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
    hideDecorativeSVGs();

    // ─────────────────────────────────────────────────────────────
    // 1. Intersection Observer — Animaciones tipo Synlab al Scroll
    //    Observa el viewport del navegador real (root: null)
    //
    //    Fix C1/C3: el observer ahora se registra inline en index.php
    //    (window._laeshObserver) para activarse sin esperar este archivo.
    //    Solo registramos aquí si el inline no corrió (fallback defensivo).
    //    rootMargin corregido a '0px' (era "-50px" — retrasaba la activación).
    // ─────────────────────────────────────────────────────────────
    if (!window._laeshObserver) {
        const observerOptions = {
            root: null,
            threshold: 0.05,
            rootMargin: "0px"
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('visible');
                }
            });
        }, observerOptions);

        document.querySelectorAll('.animate-on-scroll').forEach(el => {
            observer.observe(el);
        });
        window._laeshObserver = observer;
    }


    // ─────────────────────────────────────────────────────────────
    // 2. Resaltado activo dinámico del menú por posición de scroll
    //    Compensa altura de browser-header + navbar (~120px)
    // ─────────────────────────────────────────────────────────────
    const sections  = document.querySelectorAll('section, .hero-premium');
    const navLinks  = document.querySelectorAll('.navbar-sticky .nav-links a');

    window.addEventListener('scroll', () => {
        let current = '';
        const scrollPos = window.scrollY;

        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            if (scrollPos >= (sectionTop - 150)) {
                current = section.getAttribute('id') || '';
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            const href = link.getAttribute('href').substring(1);
            if (href === current) {
                link.classList.add('active');
            }
        });
    });


    // ─────────────────────────────────────────────────────────────
    // 3. Carrusel Hero — Slideshow automático; intervalo desde data-autoplay (seg)
    // ─────────────────────────────────────────────────────────────
    const slides = document.querySelectorAll('.hero-slide');
    let currentSlide = 0;

    // Garantizar que el primer slide (BIENVENIDO) sea siempre el activo al inicio
    if (slides.length > 0) {
        slides.forEach(function(s) { s.classList.remove('active'); });
        slides[0].classList.add('active');
    }

    /* NA-01: Actualizar dots de paginación */
    var heroDots = document.querySelectorAll('.hero-dot');
    function updateHeroDots(index) {
        heroDots.forEach(function(d, i) {
            var active = i === index;
            d.classList.toggle('active', active);
            d.setAttribute('aria-pressed', String(active));
        });
    }
    updateHeroDots(0);
    /* NA-01: click en dot → saltar a slide */
    heroDots.forEach(function(dot) {
        dot.addEventListener('click', function() {
            var target = parseInt(this.getAttribute('data-slide'), 10);
            if (isNaN(target)) return;
            slides[currentSlide].classList.remove('active');
            currentSlide = target;
            slides[currentSlide].classList.add('active');
            updateHeroDots(currentSlide);
            stopHeroAutoplay();
            if (!heroPaused) startHeroAutoplay();
        });
    });

    function nextSlide() {
        slides[currentSlide].classList.remove('active');
        currentSlide = (currentSlide + 1) % slides.length;
        slides[currentSlide].classList.add('active');
        updateHeroDots(currentSlide);
        /* GM-03: actualizar label pausa */
        /* WCAG-3: Anunciar cambio de slide a lectores de pantalla */
        var heroAnnouncer = document.getElementById('hero-announcer');
        if (heroAnnouncer) {
            var heading = slides[currentSlide].querySelector('h1, h2');
            heroAnnouncer.textContent = heading ? heading.textContent : 'Diapositiva ' + (currentSlide + 1) + ' de ' + slides.length;
        }
    }

    /* W4: Respetar prefers-reduced-motion — sin autoplay si el usuario lo prefiere */
    /* A7-fix: Botón pausa/reanudar — WCAG 2.2.2 (Pause, Stop, Hide) */
    var heroInterval = null;
    var heroPaused   = false;

    // Leer intervalo desde data-autoplay del contenedor; 0 = pausa fija, 1-90s = autoplay, defecto 5s
    var heroSlidesEl   = document.querySelector('.hero-slides');
    var autoplaySecs   = heroSlidesEl ? parseInt(heroSlidesEl.getAttribute('data-autoplay'), 10) : NaN;
    var heroPausedFixed = (!isNaN(autoplaySecs) && autoplaySecs === 0); // 0 = pausa indefinida
    var heroDelay      = (!isNaN(autoplaySecs) && autoplaySecs >= 1)
                            ? Math.min(autoplaySecs, 90) * 1000
                            : 5000;

    function startHeroAutoplay() {
        if (heroInterval || heroPausedFixed) return;
        heroInterval = setInterval(nextSlide, heroDelay);
    }
    function stopHeroAutoplay() {
        clearInterval(heroInterval);
        heroInterval = null;
    }

    if (slides.length > 1 && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        startHeroAutoplay();

        var pauseBtn      = document.getElementById('hero-pause-btn');
        var iconPause     = document.getElementById('hero-icon-pause');
        var iconPlay      = document.getElementById('hero-icon-play');

        // Ocultar botón pausa si el autoplay está desactivado (0)
        if (pauseBtn && heroPausedFixed) { pauseBtn.style.display = 'none'; }

        if (pauseBtn && !heroPausedFixed) {
            pauseBtn.addEventListener('click', function() {
                heroPaused = !heroPaused;
                pauseBtn.setAttribute('aria-pressed', heroPaused ? 'true' : 'false');
                pauseBtn.setAttribute('aria-label',   heroPaused ? 'Reanudar presentación' : 'Pausar presentación');
                if (iconPause) iconPause.classList.toggle('d-none', heroPaused);
                if (iconPlay)  iconPlay.classList.toggle('d-none', !heroPaused);
                heroPaused ? stopHeroAutoplay() : startHeroAutoplay();
            });
        }
    }

    /* NA-02: Navegación del hero con teclado (← →) */
    document.addEventListener('keydown', function(e) {
        if (slides.length < 2) return;
        if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
            var direction = e.key === 'ArrowLeft' ? -1 : 1;
            slides[currentSlide].classList.remove('active');
            currentSlide = (currentSlide + direction + slides.length) % slides.length;
            slides[currentSlide].classList.add('active');
            updateHeroDots(currentSlide);
            stopHeroAutoplay();
            if (!heroPaused) startHeroAutoplay();
            var heroAnnouncer2 = document.getElementById('hero-announcer');
            if (heroAnnouncer2) {
                var h2 = slides[currentSlide].querySelector('h1, h2');
                heroAnnouncer2.textContent = h2 ? h2.textContent : 'Diapositiva ' + (currentSlide + 1) + ' de ' + slides.length;
            }
        }
    });


    // ─────────────────────────────────────────────────────────────
    // 4. Menú Hamburguesa — Móvil ≤768px
    //    Crea el botón dinámicamente si no existe en el DOM
    // ─────────────────────────────────────────────────────────────
    const navbar     = document.querySelector('.navbar-sticky');
    const navLinksEl = document.querySelector('.navbar-sticky .nav-links');

    if (navbar && navLinksEl) {
        // Reusar .nav-hamburger ya presente en el HTML (evita botón doble)
        const existingBtn = navbar.querySelector('.nav-hamburger');
        const activeBtn   = existingBtn || (!document.querySelector('.hamburger-btn')
            ? (() => {
                const b = document.createElement('button');
                b.className = 'hamburger-btn';
                b.setAttribute('aria-label', 'Abrir menú');
                b.innerHTML = '<span></span><span></span><span></span>';
                navbar.insertBefore(b, navLinksEl);
                return b;
              })()
            : null);

        if (activeBtn) {
            activeBtn.addEventListener('click', () => {
                const isOpen = navLinksEl.classList.toggle('mobile-open');
                activeBtn.setAttribute('aria-expanded', String(isOpen));
            });
            navLinksEl.querySelectorAll('a').forEach(link => {
                link.addEventListener('click', () => {
                    navLinksEl.classList.remove('mobile-open');
                    activeBtn.setAttribute('aria-expanded', 'false');
                });
            });
        }
    }


    // ─────────────────────────────────────────────────────────────
    // 5. Modal Aviso de Privacidad — misma arquitectura que portales
    // ─────────────────────────────────────────────────────────────
    (function initPrivacyModal() {
        var modal   = document.getElementById('modal-privacidad');
        if (!modal) return;

        var content = modal.querySelector('.modal-content');
        var header  = modal.querySelector('.modal-header');
        var closes  = modal.querySelectorAll('.close-modal');

        // Abrir — todos los links que deben abrir el modal de privacidad
        var triggerIds = ['link-privacy', 'link-policy-footer'];
        triggerIds.forEach(function(id) {
            var el = document.getElementById(id);
            if (!el) return;
            el.addEventListener('click', function(e) {
                e.preventDefault();
                modal.classList.add('show');
                document.body.classList.add('modal-open'); /* CTA-03: ocultar botones flotantes */
            });
        });

        // Auto-abrir modal si la URL contiene el hash #privacidad o #modal-privacidad (ej. Vista Previa desde CMS)
        if (window.location.hash === '#privacidad' || window.location.hash === '#modal-privacidad') {
            modal.classList.add('show');
            document.body.classList.add('modal-open');
        }

        // CTA-03: helper para quitar modal-open del body
        function closePrivacyModal() {
            modal.classList.remove('show');
            document.body.classList.remove('modal-open');
        }

        // Cerrar — botón(es) y clic en backdrop
        closes.forEach(function(btn) {
            btn.addEventListener('click', closePrivacyModal);
        });
        modal.addEventListener('click', function(e) {
            if (e.target === modal) closePrivacyModal();
        });

        // Drag — idéntico a initModalDrag de app.js
        if (content && header) {
            var dragging = false, ox = 0, oy = 0;
            header.addEventListener('mousedown', function(e) {
                if (e.target.closest('button, a, input, select, textarea')) return;
                var rect = content.getBoundingClientRect();
                content.style.position  = 'fixed';
                content.style.left      = rect.left + 'px';
                content.style.top       = rect.top  + 'px';
                content.style.margin    = '0';
                content.style.transform = 'none';
                modal.style.alignItems     = 'flex-start';
                modal.style.justifyContent = 'flex-start';
                dragging = true;
                ox = e.clientX - rect.left;
                oy = e.clientY - rect.top;
                header.style.cursor = 'grabbing';
                document.body.style.userSelect = 'none';
                e.preventDefault();
            });
            document.addEventListener('mousemove', function(e) {
                if (!dragging) return;
                var nl = Math.max(0, Math.min(window.innerWidth  - content.offsetWidth,  e.clientX - ox));
                var nt = Math.max(0, Math.min(window.innerHeight - content.offsetHeight, e.clientY - oy));
                content.style.left = nl + 'px';
                content.style.top  = nt + 'px';
            });
            document.addEventListener('mouseup', function() {
                if (!dragging) return;
                dragging = false;
                header.style.cursor = 'grab';
                document.body.style.userSelect = '';
            });
            // Reset al cerrar
            new MutationObserver(function() {
                if (!modal.classList.contains('show')) {
                    content.style.position = content.style.left = content.style.top =
                    content.style.margin   = content.style.transform = '';
                    modal.style.alignItems = modal.style.justifyContent = '';
                }
            }).observe(modal, { attributes: true, attributeFilter: ['class'] });
        }
    })();

    // ─────────────────────────────────────────────────────────────
    // Helper para abrir la ruta en Google Maps utilizando 'Tu ubicación' (My Location)
    // Destino: Laboratorio de Especialidades Hematológicas S.C.
    window.openGoogleMapsRoute = function() {
        var destination = "Laboratorio de Especialidades Hematológicas S.C., Calle Azucenas #8, Jardines del Sur, 69007 Heroica Cdad. de Huajuapan de León, Oax.";
        // URL universal de Google Maps: al omitir origin, Google Maps selecciona "Tu ubicación" en tiempo real desde el dispositivo (GPS nativo)
        var routeUrl = 'https://www.google.com/maps/dir/?api=1&destination=' + encodeURIComponent(destination);
        window.open(routeUrl, '_blank', 'noopener,noreferrer');
    };

    // ─────────────────────────────────────────────────────────────
    // 7. Carrusel Horizontal de Especialidades
    //    Scroll snap por ancho de tarjeta + gap computado
    // ─────────────────────────────────────────────────────────────
    window.slideSpecialties = function(direction) {
        const track = document.getElementById('specialties-track');
        if (!track) return;

        const card = track.querySelector('.carousel-card');
        if (!card) return;

        const cardWidth = card.getBoundingClientRect().width;
        const gap       = parseFloat(window.getComputedStyle(track).gap) || 0;
        track.scrollBy({ left: direction * (cardWidth + gap), behavior: 'smooth' });
    };

    // ─────────────────────────────────────────────────────────────
    // UX3: Paginación por puntitos (dots) del carrusel de especialidades
    // ─────────────────────────────────────────────────────────────
    (function initSpecialtiesDots() {
        var track = document.getElementById('specialties-track');
        var dotsContainer = document.getElementById('specialties-dots');
        if (!track || !dotsContainer) return;

        // Filtro defensivo: omitir cualquier tarjeta que contenga la palabra ESTABLECER
        var initialCards = track.querySelectorAll('.carousel-card');
        initialCards.forEach(function(card) {
            var txt = card.innerText || '';
            var img = card.querySelector('img');
            var altTxt = img ? (img.alt || '') : '';
            if (/ESTABLECER/i.test(txt) || /ESTABLECER/i.test(altTxt)) {
                card.remove();
            }
        });

        var cards = track.querySelectorAll('.carousel-card');
        if (cards.length === 0) return;

        function buildDots() {
            dotsContainer.innerHTML = '';
            var maxScroll = track.scrollWidth - track.clientWidth;
            if (maxScroll <= 0) {
                dotsContainer.style.display = 'none';
                return;
            } else {
                dotsContainer.style.display = 'flex';
            }

            for (var i = 0; i < cards.length; i++) {
                (function(index) {
                    var btn = document.createElement('button');
                    btn.type = 'button';
                    btn.className = 'hero-dot' + (index === 0 ? ' active' : '');
                    btn.setAttribute('aria-label', 'Diapositiva de estudio ' + (index + 1) + ' de ' + cards.length);
                    btn.setAttribute('aria-pressed', index === 0 ? 'true' : 'false');
                    btn.addEventListener('click', function() {
                        var targetCard = cards[index];
                        if (targetCard) {
                            var targetLeft = targetCard.offsetLeft - track.offsetLeft;
                            track.scrollTo({ left: targetLeft, behavior: 'smooth' });
                        }
                    });
                    dotsContainer.appendChild(btn);
                })(i);
            }
            updateActiveDot();
        }

        function updateActiveDot() {
            var dots = dotsContainer.querySelectorAll('.hero-dot');
            if (dots.length === 0) return;
            var scrollLeft = track.scrollLeft;
            var cardWidth = cards[0].getBoundingClientRect().width;
            var gap = parseFloat(window.getComputedStyle(track).gap) || 0;
            var step = cardWidth + gap;

            var activeIndex = Math.round(scrollLeft / (step > 0 ? step : 1));
            if (activeIndex < 0) activeIndex = 0;
            if (activeIndex >= cards.length) activeIndex = cards.length - 1;

            dots.forEach(function(dot, idx) {
                var isActive = idx === activeIndex;
                dot.classList.toggle('active', isActive);
                dot.setAttribute('aria-pressed', isActive ? 'true' : 'false');
            });
        }

        track.addEventListener('scroll', updateActiveDot, { passive: true });
        window.addEventListener('resize', buildDots, { passive: true });
        buildDots();
    })();


    // ─────────────────────────────────────────────────────────────
    // 8. Carrusel de Calidad — Fade + autoplay 4s
    // Carousel especialidades
    var btnCarouselPrev = document.getElementById('btn-carousel-prev');
    var btnCarouselNext = document.getElementById('btn-carousel-next');
    if (btnCarouselPrev) btnCarouselPrev.addEventListener('click', function() { slideSpecialties(-1); });
    if (btnCarouselNext) btnCarouselNext.addEventListener('click', function() { slideSpecialties(1); });

    // Map tabs / Direct external map trigger
    var btnMapInteractive = document.getElementById('btn-map-interactive');
    if (btnMapInteractive) {
        btnMapInteractive.addEventListener('click', function(e) {
            e.preventDefault();
            openGoogleMapsRoute();
        });
    }

    // ─────────────────────────────────────────────────────────────
    // CAT-ACC: Accordion del catálogo de estudios
    // Alterna clase 'collapsed' en el body y rota el chevron del header.
    // HTML: button[data-acc="cg1"] → #cg1 (body) · #arr-cg1 (chevron SVG)
    // CSS:  .orden-acc-body.collapsed { max-height: 0 }
    //       .chevron-open            { transform: rotate(-180deg) }
    // ─────────────────────────────────────────────────────────────
    function toggleCatAcc(id) {
        var body    = document.getElementById(id);
        var chevron = document.getElementById('arr-' + id);
        if (!body) return;
        var isCollapsed = body.classList.toggle('collapsed');
        if (chevron) {
            chevron.classList.toggle('chevron-open', !isCollapsed);
        }
    }

    // Accordion catálogo — delegación por data-acc
    document.querySelectorAll('[data-acc]').forEach(function(btn) {
        btn.addEventListener('click', function() {
            toggleCatAcc(this.getAttribute('data-acc'));
        });
    });

    // ─────────────────────────────────────────────────────────────
    // TU-02: Banner de cookies (LFPDPPP)
    // ─────────────────────────────────────────────────────────────
    (function initCookieBanner() {
        var banner    = document.getElementById('cookie-banner');
        var acceptBtn = document.getElementById('cookie-accept');
        if (!banner) return;

        var COOKIE_KEY = 'laesh_cookies_accepted';
        if (localStorage.getItem(COOKIE_KEY)) {
            banner.style.display = 'none';
            return;
        }
        banner.classList.add('visible');

        /* helper: marcar aceptado y ocultar banner */
        function acceptCookies() {
            clearTimeout(autoTimer);
            localStorage.setItem(COOKIE_KEY, '1');
            banner.classList.remove('visible');
            setTimeout(function() { banner.style.display = 'none'; }, 400);
        }

        /* "Ver Aviso de Privacidad" → abre modal de privacidad en lugar de navegar */
        var privacyLink = document.getElementById('cookie-privacy-link');
        if (privacyLink) {
            privacyLink.addEventListener('click', function(e) {
                e.preventDefault();
                var modal = document.getElementById('modal-privacidad');
                if (modal) {
                    modal.classList.add('show');
                    document.body.classList.add('modal-open');
                }
            });
        }

        /* Auto-aceptar después de 2 minutos sin interacción */
        var autoTimer = setTimeout(acceptCookies, 120000);

        if (acceptBtn) {
            acceptBtn.addEventListener('click', acceptCookies);
        }
    })();

    // ─────────────────────────────────────────────────────────────
    // 9a. HTMX — Permitir swap de fragmentos .flash en respuestas 4xx/5xx
    //     (HTMX v1.x por defecto solo hace swap en 2xx; Response::htmxError()
    //      usa 200, pero este listener es la segunda línea de defensa.)
    // ─────────────────────────────────────────────────────────────
    document.body.addEventListener('htmx:beforeSwap', function(evt) {
        var status = evt.detail.xhr ? evt.detail.xhr.status : 0;
        if (status >= 400 && status < 600) {
            // Forzar swap aunque sea respuesta de error — el fragmento lleva .flash
            evt.detail.shouldSwap = true;
            evt.detail.isError = false;
        }
    });

    // ─────────────────────────────────────────────────────────────
    // 9b. Login Modal — HTMX + csrf.php (R15: vinculado a login.php)
    // ─────────────────────────────────────────────────────────────
    (function initLoginModal() {
        var modal = document.getElementById('modal-login');
        if (!modal) return;

        var titleEl    = document.getElementById('modal-login-title');
        var targetInput = document.getElementById('login-redirect-target');
        var portalInput = document.getElementById('login-portal-name');
        var csrfInput   = document.getElementById('login-csrf-token');
        var form        = document.getElementById('form-login-portal');
        var errorEl     = document.getElementById('login-error-msg');
        var phoneInput  = document.getElementById('login-phone');
        var passInput   = document.getElementById('login-pass');
        var submitBtn   = document.getElementById('btn-login-submit');
        var closes      = modal.querySelectorAll('.close-modal');

        // URL del endpoint de autenticación — Alias Apache: /laesh/uipv1/ → laesh-swbldi/website/uipv1/
        var LOGIN_URL = '/laesh/login/login.php';
        var CSRF_URL  = '/laesh/login/csrf.php';

        // Mapa data-target → nombre de portal para login.php
        // El backend (login.php + RBAC) decide el destino final según el rol:
        //   medico   → MEDICO    → /laesh/md/
        //   laesh    → RECEPCION → /laesh/rc/   | ADMIN → /laesh/adrc/
        var portalMap = {
            'medicos.html': 'medico',
            'laesh.html':   'laesh'
        };

        // ── Obtener token CSRF desde el servidor (con Fallback Estático para OCI VM uipv1a) ─
        function fetchCsrfToken(callback) {
            fetch(CSRF_URL, { credentials: 'same-origin' })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.csrf_token) {
                        csrfInput.value = data.csrf_token;
                        if (callback) callback();
                    }
                })
                .catch(function() {
                    /*
                     * CHECKPOINT REFERENCE / FALLBACK MODO ESTÁTICO (OCI VM uipv1a):
                     * Si se sirve en un entorno HTTP puramente estático sin backend PHP (csrf.php),
                     * se asigna un token sintético local para no bloquear la interacción de UI.
                     */
                    csrfInput.value = 'static_fallback_token_uipv1a';
                    if (callback) callback();
                });
        }

        // ── Redirección de Respaldo a HTMLs Estáticos (Fallback Cliente OCI VM) ─────────
        /*
         * CHECKPOINT REFERENCE (19/Ago/2026):
         * Esta función provee la fallback de cliente (Opción B) cuando la aplicación corre
         * en un servidor de maquetación/demo estático sin PHP ni MariaDB (ej. OCI VM uipv1a).
         * Si login.php no responde (404/500/Error de Red), redirige al mockup HTML correspondiente.
         */
        function redirectToStaticPortalFallback() {
            var target = (targetInput ? targetInput.value : '') || (portalInput ? portalInput.value : 'medico');
            var staticMap = {
                'medicos.html': 'medicos.html',
                'laesh.html':   'labadmin.html',
                'medico':       'medicos.html',
                'laesh':        'labadmin.html',
                'admin':        'gestion-web.html'
            };
            var destHtml = staticMap[target] || 'medicos.html';
            window.location.href = destHtml;
        }

        // ── Mostrar error estándar (fragmento .flash o texto plano) ──────────
        function showError(html) {
            // Acepta HTML fragment de Response::htmxError() o texto plano
            if (typeof html === 'string' && html.trim().startsWith('<')) {
                errorEl.innerHTML = html;
            } else {
                errorEl.innerHTML = '<span class="flash flash--error" role="alert">'
                    + String(html).replace(/</g, '&lt;') + '</span>';
            }
            errorEl.style.display = 'block'; // revelar — CSS base es display:none (R-CSS-02)
        }

        function clearError() { errorEl.innerHTML = ''; errorEl.style.display = 'none'; }

        // ── Abrir modal ───────────────────────────────────────────────────────
        function openLogin(title, dataTarget) {
            titleEl.textContent = title;
            var portal = portalMap[dataTarget] || 'medico';
            targetInput.value = dataTarget;
            portalInput.value = portal;
            clearError();
            form.reset();
            // Limpiar explícitamente — form.reset() no bloquea el autofill
            // del browser que puede dispararse después de que el modal es visible.
            phoneInput.value = '';
            passInput.value  = '';
            // Restaurar estado del botón
            submitBtn.disabled = false;
            submitBtn.textContent = 'Ingresar';
            modal.classList.add('show');
            document.body.classList.add('modal-open');
            // Segundo pase: Chrome/Firefox autofill puede llegar con retraso
            // de hasta ~80 ms tras hacer visible el modal. Lo neutralizamos.
            setTimeout(function() {
                phoneInput.value = '';
                passInput.value  = '';
            }, 80);
            // Obtener CSRF token fresco al abrir el modal
            fetchCsrfToken(function() { phoneInput.focus(); });
        }

        function closeLogin() {
            modal.classList.remove('show');
            document.body.classList.remove('modal-open');
            clearError();
        }

        // ── Listeners de apertura/cierre ──────────────────────────────────────
        document.querySelectorAll('.login-trigger').forEach(function(link) {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                openLogin(
                    this.getAttribute('data-title'),
                    this.getAttribute('data-target')
                );
            });
        });

        closes.forEach(function(btn) { btn.addEventListener('click', closeLogin); });
        // El modal solo se cierra con X (btn-cerrar-login) o login exitoso.
        // Clic en el backdrop (fondo) NO cierra — evita cierres accidentales.

        // ── Submit: validación JS + fetch() / Fallback 1-Click HTML ──────────
        if (form) {
            form.addEventListener('submit', function(e) {
                e.preventDefault();
                clearError();

                var phoneVal = phoneInput.value.replace(/\D/g, '');
                var passVal  = passInput.value;

                // Validación cliente — campos requeridos y formato
                if (!phoneVal) {
                    showError('Ingresa tu número de teléfono de 10 dígitos.');
                    phoneInput.focus();
                    return;
                }
                if (!/^\d{10}$/.test(phoneVal)) {
                    showError('El número de teléfono debe tener exactamente 10 dígitos (ej. 9990000001).');
                    phoneInput.focus();
                    return;
                }
                if (!passVal) {
                    showError('Ingresa tu contraseña.');
                    passInput.focus();
                    return;
                }

                // Verificar que tenemos token CSRF (o token sintético estático)
                if (!csrfInput.value) {
                    csrfInput.value = 'static_fallback_token_uipv1a';
                }

                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span style="display:inline-block;width:13px;height:13px;border:2px solid currentColor;border-right-color:transparent;border-radius:50%;animation:spin 0.7s linear infinite;vertical-align:middle;margin-right:6px;"></span>Verificando...';

                var body = new URLSearchParams({
                    csrf_token: csrfInput.value,
                    telefono:   phoneVal,
                    password:   passVal,
                    portal:     portalInput.value
                });

                fetch(LOGIN_URL, {
                    method:      'POST',
                    credentials: 'same-origin',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'HX-Request':   'true'   // activa Response::isHtmx() en login.php
                    },
                    body: body.toString()
                })
                .then(function(resp) {
                    if (!resp.ok) {
                        throw new Error('ServerError:' + resp.status);
                    }
                    return resp.text();
                })
                .then(function(html) {
                    var tmp = document.createElement('div');
                    tmp.innerHTML = html;
                    var successEl = tmp.querySelector('[data-portal-url]');

                    if (successEl) {
                        // ── Auth exitosa (Stack PHP activo): Navegar en la MISMA pestaña ──
                        var portalUrl = successEl.getAttribute('data-portal-url');
                        window.location.href = portalUrl;
                    } else {
                        // ── Error de autenticación devuelto por login.php ──
                        errorEl.innerHTML = html;              // fragmento .flash--error
                        errorEl.style.display = 'block';      // revelar — CSS base es display:none (R-CSS-02)
                        submitBtn.disabled = false;
                        submitBtn.textContent = 'Ingresar';
                        fetchCsrfToken(null);                  // renovar CSRF
                    }
                })
                .catch(function(err) {
                    console.warn('[LAESH UI] Error en login fetch:', err);
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Ingresar';
                    showError('Error de conexión con el servidor. Verifica tu red e intenta de nuevo.');
                    fetchCsrfToken(null); // renovar CSRF tras error
                });
            });
        }
        
        // Modal Dragging (same drag logic as privacy modal, with touch support)
        var content = modal.querySelector('.modal-content');
        var header = modal.querySelector('.modal-header');
        if (content && header) {
            var dragging = false, ox = 0, oy = 0;
            header.addEventListener('mousedown', function(e) {
                if (e.target.closest('button, a, input, select, textarea')) return;
                var rect = content.getBoundingClientRect();
                content.style.position = 'fixed';
                content.style.left = rect.left + 'px';
                content.style.top = rect.top + 'px';
                content.style.margin = '0';
                content.style.transform = 'none';
                modal.style.alignItems = 'flex-start';
                modal.style.justifyContent = 'flex-start';
                dragging = true;
                ox = e.clientX - rect.left;
                oy = e.clientY - rect.top;
                header.style.cursor = 'grabbing';
                document.body.style.userSelect = 'none';
                e.preventDefault();
            });
            document.addEventListener('mousemove', function(e) {
                if (!dragging) return;
                var nl = Math.max(0, Math.min(window.innerWidth - content.offsetWidth, e.clientX - ox));
                var nt = Math.max(0, Math.min(window.innerHeight - content.offsetHeight, e.clientY - oy));
                content.style.left = nl + 'px';
                content.style.top = nt + 'px';
            });
            document.addEventListener('mouseup', function() {
                if (!dragging) return;
                dragging = false;
                header.style.cursor = 'grab';
                document.body.style.userSelect = '';
            });

            // Touch support for dragging
            header.addEventListener('touchstart', function(e) {
                if (e.target.closest('button, a, input, select, textarea')) return;
                var touch = e.touches[0];
                var rect = content.getBoundingClientRect();
                content.style.position = 'fixed';
                content.style.left = rect.left + 'px';
                content.style.top = rect.top + 'px';
                content.style.margin = '0';
                content.style.transform = 'none';
                modal.style.alignItems = 'flex-start';
                modal.style.justifyContent = 'flex-start';
                dragging = true;
                ox = touch.clientX - rect.left;
                oy = touch.clientY - rect.top;
                document.body.style.userSelect = 'none';
            });
            document.addEventListener('touchmove', function(e) {
                if (!dragging) return;
                var touch = e.touches[0];
                var nl = Math.max(0, Math.min(window.innerWidth - content.offsetWidth, touch.clientX - ox));
                var nt = Math.max(0, Math.min(window.innerHeight - content.offsetHeight, touch.clientY - oy));
                content.style.left = nl + 'px';
                content.style.top = nt + 'px';
            });
            document.addEventListener('touchend', function() {
                if (!dragging) return;
                dragging = false;
                document.body.style.userSelect = '';
            });

            new MutationObserver(function() {
                if (!modal.classList.contains('show')) {
                    content.style.position = content.style.left = content.style.top =
                    content.style.margin = content.style.transform = '';
                    modal.style.alignItems = modal.style.justifyContent = '';
                }
            }).observe(modal, { attributes: true, attributeFilter: ['class'] });
        }
    })();

    // ── Generic Modal Accessibility (Focus Trap & Escape Close) ──────
    document.addEventListener('keydown', function (e) {
        var activeModal = document.querySelector('.modal.show');
        if (!activeModal) return;

        if (e.key === 'Escape') {
            var closeBtn = activeModal.querySelector('.close-modal');
            if (closeBtn) {
                closeBtn.click();
            } else {
                activeModal.classList.remove('show');
                document.body.classList.remove('modal-open');
            }
            return;
        }

        if (e.key === 'Tab') {
            var focusables = activeModal.querySelectorAll('button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])');
            if (focusables.length === 0) {
                e.preventDefault();
                return;
            }
            var first = focusables[0];
            var last = focusables[focusables.length - 1];

            if (e.shiftKey) { // Shift + Tab
                if (document.activeElement === first) {
                    last.focus();
                    e.preventDefault();
                }
            } else { // Tab
                if (document.activeElement === last) {
                    first.focus();
                    e.preventDefault();
                }
            }
        }
    });

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
    document.querySelectorAll('.modal').forEach(function (modal) {
        modalObserver.observe(modal, { attributes: true, attributeFilter: ['class'] });
    });

    // Delegación global de clics y eventos táctiles para capturar cualquier tarjeta o imagen de promoción
    function handlePromoCardInteraction(e) {
        var btn = e.target.closest('.catalog-card-btn') || e.target.closest('.catalog-card-btn-overlay') || e.target.closest('a');
        if (btn) return; // Permitir interacción normal en botones

        var card = e.target.closest('.catalog-card') || e.target.closest('[data-promo-img]');
        if (!card) return;

        var imgSrc = card.getAttribute('data-promo-img');
        if (!imgSrc || imgSrc.trim() === '') {
            var imgEl = card.querySelector('.catalog-card-img') || card.querySelector('img');
            if (imgEl) imgSrc = imgEl.getAttribute('src');
        }
        if (!imgSrc || imgSrc.trim() === '') return;

        var title = card.getAttribute('data-promo-title') || 'Promoción — Imagen Completa';
        if (typeof window.openPromoModal === 'function') {
            window.openPromoModal(imgSrc, title);
        }
    }

    document.addEventListener('click', handlePromoCardInteraction);

    // Cierre al presionar la tecla Escape en cualquier dispositivo con teclado
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' || e.keyCode === 27) {
            window.closePromoModal();
        }
    });

    var promoModal = document.getElementById('modal-img-promo');
    if (promoModal) {
        var closeBtn = promoModal.querySelector('.close-modal');
        if (closeBtn) {
            closeBtn.addEventListener('click', window.closePromoModal);
        }
        promoModal.addEventListener('click', function(e) {
            if (e.target === promoModal) {
                window.closePromoModal();
            }
        });
    }

    /* ── §9 CAT-INFO: Botón "+" + tooltip de detalles por estudio ── */
    (function initCatInfo() {
        // ── Tooltip singleton ─────────────────────────────────────────────────
        var tip = document.createElement('div');
        tip.className = 'precio-info-tooltip';
        tip.setAttribute('role', 'tooltip');
        tip.innerHTML =
            '<div class="pit-hdr">' +
                '<span class="pit-nombre"></span>' +
                '<button type="button" class="pit-close" aria-label="Cerrar">×</button>' +
            '</div>' +
            '<div class="pit-body">' +
                '<div class="pit-sec pit-sec-pruebas">' +
                    '<div class="pit-sec-title">➤ Pruebas incluidas</div>' +
                    '<div class="pit-sec-box pit-pruebas"></div>' +
                '</div>' +
                '<div class="pit-sec pit-sec-prep">' +
                    '<div class="pit-sec-title">➤ Indicaciones</div>' +
                    '<div class="pit-sec-box pit-prep"></div>' +
                '</div>' +
                '<div class="pit-sec pit-sec-muestra">' +
                    '<div class="pit-sec-title">➤ Tipo de muestra</div>' +
                    '<div class="pit-sec-box pit-muestra"></div>' +
                '</div>' +
                '<div class="pit-sec pit-sec-contenedor">' +
                    '<div class="pit-sec-title">➤ Contenedor</div>' +
                    '<div class="pit-sec-box pit-contenedor"></div>' +
                '</div>' +
                '<div class="pit-sec pit-sec-tiempo">' +
                    '<div class="pit-sec-title">➤ Tiempo de entrega de resultados</div>' +
                    '<div class="pit-sec-box pit-tiempo"></div>' +
                '</div>' +
                '<div class="pit-sec pit-sec-clave">' +
                    '<div class="pit-sec-title">➤ Clave</div>' +
                    '<div class="pit-sec-box pit-clave"></div>' +
                '</div>' +
                '<div class="pit-sec pit-sec-cat">' +
                    '<div class="pit-sec-title">➤ Área de proceso</div>' +
                    '<div class="pit-sec-box pit-cat"></div>' +
                '</div>' +
            '</div>';
        document.body.appendChild(tip);

        // ── Timer compartido de cierre ─────────────────────────────────────────
        var closeTimer  = null;
        var CLOSE_DELAY = 280;

        var lastTouchMs = 0;
        document.addEventListener('touchstart', function() { lastTouchMs = Date.now(); }, { passive: true });
        function isRealMouse() { return (Date.now() - lastTouchMs) > 400; }

        function cancelClose() { clearTimeout(closeTimer); }
        function scheduleClose() { cancelClose(); closeTimer = setTimeout(hideTip, CLOSE_DELAY); }

        function hideTip() {
            cancelClose();
            tip.classList.remove('pit-visible');
            tip._activeBtn = null;
        }

        function posTip(btn) {
            var r   = btn.getBoundingClientRect();
            var tw  = tip.offsetWidth  || 300;
            var th  = tip.offsetHeight || 250;
            var vw  = window.innerWidth;
            var vh  = window.innerHeight;
            var top = (r.bottom + th + 8 < vh) ? r.bottom + 8 : Math.max(8, r.top - th - 8);
            var lft = Math.min(Math.max(r.left, 12), vw - tw - 12);
            tip.style.top  = top + 'px';
            tip.style.left = lft + 'px';
        }

        function showTip(btn, nombre, categoria, d) {
            cancelClose();
            tip.querySelector('.pit-nombre').textContent = nombre;

            var renderBoxValue = function(val) {
                var cleanVal = (val || '').toString().trim();
                if (!cleanVal || cleanVal === '—') cleanVal = 'Consultar en LAESH';
                return '<div class="pit-prueba-item">' + cleanVal + '</div>';
            };

            // 1. Pruebas Incluidas
            var pruebas = d ? d[5] : '';
            var pruebasEl = tip.querySelector('.pit-pruebas');
            var pruebasSec = tip.querySelector('.pit-sec-pruebas');
            if (pruebas && pruebas.trim() !== '') {
                var items = pruebas.split(/[,;\n]+/).map(p => p.trim()).filter(p => p);
                if (items.length > 0) {
                    pruebasEl.innerHTML = items.map(p => '<div class="pit-prueba-item">' + p + '</div>').join('');
                } else {
                    pruebasEl.innerHTML = renderBoxValue(pruebas);
                }
                if (pruebasSec) pruebasSec.style.display = 'flex';
            } else {
                pruebasEl.innerHTML = renderBoxValue('Consultar en LAESH');
                if (pruebasSec) pruebasSec.style.display = 'flex';
            }

            // 2. Indicaciones (Preparación)
            tip.querySelector('.pit-prep').innerHTML       = renderBoxValue(d ? d[3] : '');

            // 3. Tipo de Muestra
            tip.querySelector('.pit-muestra').innerHTML    = renderBoxValue(d ? d[2] : '');

            // 4. Contenedor
            tip.querySelector('.pit-contenedor').innerHTML = renderBoxValue(d ? d[4] : '');

            // 5. Tiempo de Entrega
            tip.querySelector('.pit-tiempo').innerHTML     = renderBoxValue(d ? d[1] : '');

            // 6. Clave
            tip.querySelector('.pit-clave').innerHTML      = renderBoxValue(d ? d[0] : '');

            // 7. Área de Proceso (Categoría)
            tip.querySelector('.pit-cat').innerHTML        = renderBoxValue(categoria);

            tip._activeBtn = btn;
            tip.classList.add('pit-visible');
            requestAnimationFrame(function() { posTip(btn); });
        }

        // ── Eventos del tooltip ───────────────────────────────────────────────
        tip.querySelector('.pit-close').addEventListener('click', function(e) {
            e.stopPropagation();
            hideTip();
        });
        // Desktop: mantener abierto mientras el cursor esté sobre el tooltip
        // (antes faltaba mouseenter → el tooltip se cerraba al entrar en él)
        tip.addEventListener('mouseenter', function() { if (isRealMouse()) cancelClose(); });
        tip.addEventListener('mouseleave', function() { if (isRealMouse()) scheduleClose(); });

        // Cerrar al tocar/hacer clic fuera (desktop y mobile)
        document.addEventListener('click', function(e) {
            if (tip.classList.contains('pit-visible') &&
                !tip.contains(e.target) &&
                !e.target.closest('.precio-info-btn')) {
                hideTip();
            }
        });

        // ── Inyectar botones "+" en cada renglón de catálogo ──────────────────
        document.querySelectorAll('.precio-cat-item').forEach(function(item) {
            var nombreEl = item.querySelector('.precio-cat-nombre');
            if (!nombreEl) return;
            var nombre   = nombreEl.textContent.trim();

            var d = [
                item.getAttribute('data-clave') || '—',
                item.getAttribute('data-tiempo') || 'Consultar en LAESH',
                item.getAttribute('data-muestra') || 'Consultar en LAESH',
                item.getAttribute('data-preparacion') || 'Consultar en LAESH',
                item.getAttribute('data-contenedor') || '',
                item.getAttribute('data-pruebas') || ''
            ];

            // Categoría: encabezado .orden-cat-hdr más cercano
            var catEl    = item.closest('.orden-cat');
            var categoria = catEl ? catEl.querySelector('.orden-cat-hdr').textContent.trim() : '—';

            var btn = document.createElement('button');
            btn.type      = 'button';
            btn.className = 'precio-info-btn';
            btn.setAttribute('aria-label', 'Detalles: ' + nombre);
            btn.innerHTML =
                '<svg width="10" height="10" viewBox="0 0 10 10" fill="none" aria-hidden="true">' +
                    '<line x1="5" y1="1" x2="5" y2="9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>' +
                    '<line x1="1" y1="5" x2="9" y2="5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>' +
                '</svg>';
            item.appendChild(btn);

            // Desktop (mouse real): hover abre/cierra con margen de tiempo
            btn.addEventListener('mouseenter', function() {
                if (!isRealMouse()) return;
                showTip(btn, nombre, categoria, d);
            });
            btn.addEventListener('mouseleave', function() {
                if (!isRealMouse()) return;
                scheduleClose();   // da 280 ms para cruzar el gap hacia el tooltip
            });

            // Mobile y teclado: tap-to-toggle
            // e.stopPropagation() evita que el document-click-listener lo cierre
            // isRealMouse() distingue tap (false) de clic de ratón (true) para no
            // duplicar la acción con el mouseenter que ya la gestionó en desktop.
            btn.addEventListener('click', function(e) {
                e.stopPropagation();
                if (isRealMouse()) return;   // desktop: mouseenter ya lo manejó
                if (tip.classList.contains('pit-visible') && tip._activeBtn === btn) {
                    hideTip();
                } else {
                    showTip(btn, nombre, categoria, d);
                }
            });
        });
    })();
});


// ── Descripción expandible en tarjetas de promoción (Mejora C 2026-09-08) ──
(function () {
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('.btn-rte-expand');
        if (!btn) return;
        var desc = btn.previousElementSibling;
        if (!desc || !desc.classList.contains('rte-desc--expandable')) return;
        var expanded = desc.classList.toggle('is-expanded');
        btn.setAttribute('aria-expanded', expanded);
        btn.textContent = expanded ? 'Ver menos ↑' : 'Ver más ↓';
    });
}());


