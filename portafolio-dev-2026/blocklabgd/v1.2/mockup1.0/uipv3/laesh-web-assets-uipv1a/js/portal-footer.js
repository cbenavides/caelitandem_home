/**
 * portal-footer.js — LAESH Portal Footer (Single Source)
 * Inyecta el footer común al final de .main-content en todos los portales.
 * Ningún HTML repite la estructura; este archivo es la única fuente.
 *
 * Dependencia: cargarse con defer DESPUÉS de app.js y sidebar-rail.js
 */
(function () {
  'use strict';

  const year = new Date().getFullYear();

  const footer = document.createElement('footer');
  footer.className = 'portal-footer';
  footer.setAttribute('role', 'contentinfo');
  footer.innerHTML = `
    <div class="portal-footer-inner">
      <div class="portal-footer-row portal-footer-row--1">
        <span class="portal-footer-brand">LAESH</span>
        <span class="portal-footer-sep" aria-hidden="true">·</span>
        <span class="portal-footer-tagline">Resultados que dan confianza, decisiones que cuidan</span>
      </div>
      <span class="portal-footer-rows-sep" aria-hidden="true">·</span>
      <div class="portal-footer-row portal-footer-row--2">
        <span class="portal-footer-copy">© ${year} Todos los derechos reservados</span>
      </div>
    </div>
  `;

  function positionFooter() {
    const mainContent = document.querySelector('.main-content');
    const appLayout = document.querySelector('.app-layout');
    if (!mainContent) {
      if (!footer.parentElement) document.body.appendChild(footer);
      return;
    }
    if (window.innerWidth <= 767 && appLayout) {
      if (footer.parentElement !== appLayout || appLayout.lastElementChild !== footer) {
        appLayout.appendChild(footer);
      }
    } else {
      if (footer.parentElement !== mainContent || mainContent.lastElementChild !== footer) {
        mainContent.appendChild(footer);
      }
    }
  }

  positionFooter();
  window.addEventListener('resize', positionFooter, { passive: true });
})();
