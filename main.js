/* =========================================================
   CaeliTandem Sistemas — main.js
   ========================================================= */

'use strict';

/* --- Hero-band: reduce on scroll --- */
(function () {
    const band = document.getElementById('hero-band');
    if (!band) return;

    window.addEventListener('scroll', function () {
        if (window.scrollY > 40) {
            band.classList.add('band-compact');
        } else {
            band.classList.remove('band-compact');
        }
    }, { passive: true });
})();

/* --- Contact form submit handler --- */
(function () {
    const form = document.getElementById('contact-form');
    if (!form) return;

    form.addEventListener('submit', function (e) {
        e.preventDefault();
        const btn = form.querySelector('.btn-submit');
        const original = btn.textContent;
        btn.textContent = 'Enviando…';
        btn.disabled = true;

        /* Simulate async send – replace with real fetch if backend is added */
        setTimeout(function () {
            btn.textContent = '✓ Mensaje enviado';
            btn.style.background = 'linear-gradient(135deg,#22c55e,#16a34a)';
            form.reset();
            setTimeout(function () {
                btn.textContent = original;
                btn.style.background = '';
                btn.disabled = false;
            }, 4000);
        }, 800);
    });
})();

/* --- Accordion: close others when one opens --- */
(function () {
    const items = document.querySelectorAll('.ref-accordion-item');
    items.forEach(item => {
        item.addEventListener('toggle', function () {
            if (this.open) {
                items.forEach(other => {
                    if (other !== this && other.open) {
                        other.open = false;
                    }
                });
            }
        });
    });
})();
