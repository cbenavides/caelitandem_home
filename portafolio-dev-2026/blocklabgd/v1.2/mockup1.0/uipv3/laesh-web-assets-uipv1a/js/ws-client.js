/**
 * ws-client.js — Cliente WebSocket Swoole v6 + Fallback Polling para Notificaciones en Vivo (LAESH)
 * 
 * Funcionalidades:
 * 1. Agrupación en abanicos descendentes: "📅 Hoy" y "🕒 Ayer y Anteriores".
 * 2. Globito rojo visible (bell-badge con .show .pulse y opacity:1) y contador en título (N) Recepción.
 * 3. Supresión de advertencias Autoplay/AudioContext inicializando audio exclusivamente tras gesto de usuario.
 */
(function() {
    'use strict';

    var ws = null;
    var reconnectInterval = 3000;
    var maxReconnects = 3;
    var reconnectAttempts = 0;
    var pollingTimer = null;
    var lastTimestamp = 0;
    var seenNotifIds = {};
    var unreadCount = 0;
    var originalTitle = document.title;

    // Control de AudioContext seguro (cero advertencias Autoplay)
    var hasUserGesture = false;
    var sharedAudioCtx = null;

    function registerUserGesture() {
        if (hasUserGesture) return;
        hasUserGesture = true;
        try {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (AudioCtx && !sharedAudioCtx) {
                sharedAudioCtx = new AudioCtx();
            }
        } catch (e) {}
    }

    ['click', 'keydown', 'touchstart', 'pointerdown'].forEach(function(evtName) {
        document.addEventListener(evtName, registerUserGesture, { once: true, capture: true });
    });

    function getWsUrl() {
        var host = window.location.hostname || 'localhost';
        var protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        return protocol + '//' + host + (window.location.port ? ':' + window.location.port : '') + '/ws/';
    }

    function pollNotifications() {
        var baseDir = window.location.pathname.replace(/\/+$/, '');
        var endpoint = baseDir + '/api/notificaciones?since=' + lastTimestamp;
        fetch(endpoint, { cache: 'no-store' })
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (data && data.success && Array.isArray(data.notificaciones)) {
                    var newTs = data.timestamp || data.server_time;
                    if (newTs) lastTimestamp = newTs;

                    data.notificaciones.forEach(function(n) {
                        if (n.id && seenNotifIds[n.id]) return;
                        if (n.id) seenNotifIds[n.id] = true;

                        handleWsEvent({
                            event: n.tipo,
                            titulo: (n.tipo === 'nueva_orden') ? 'Nueva Solicitud Médica Digital (' + (n.folio_referencia || '') + ')' : 'Actualización de Solicitud',
                            mensaje: n.mensaje,
                            creado_en: n.creado_en
                        });
                    });
                }
            })
            .catch(function(err) {});
    }

    function startPollingFallback() {
        if (pollingTimer) return;
        console.info('[LAESH Notif] Swoole WS no disponible. Polling HTTP activo cada 4s (MariaDB)');
        pollingTimer = setInterval(pollNotifications, 4000);
        pollNotifications();
    }

    // Corrección 2026-09-22: bug real encontrado en producción (RC no recibía
    // notificaciones en vivo, requería refresh manual). El servidor cierra la
    // conexión de inmediato si falla la validación del JWT/JTI al abrir (ver
    // swoole_server.php on('open')) — pero onopen SIEMPRE se dispara primero
    // (el handshake WS ya se completó) y reseteaba reconnectAttempts a 0 antes
    // de que llegara el close casi instantáneo. Resultado: reconexión infinita
    // cada 3s sin jamás alcanzar maxReconnects, así que startPollingFallback()
    // nunca se activaba — cero actualizaciones en vivo ni por WS ni por polling.
    // Se distingue una conexión "flapping" (cerrada casi de inmediato) de una
    // estable: solo una conexión que duró >= MIN_STABLE_MS resetea el contador;
    // una que "flapea" activa el polling de inmediato (no espera a agotar
    // maxReconnects) mientras sigue reintentando WS en segundo plano.
    var MIN_STABLE_MS = 2000;
    var wsOpenedAt = 0;

    function initWebSocket() {
        if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
            return;
        }

        try {
            ws = new WebSocket(getWsUrl());

            ws.onopen = function() {
                wsOpenedAt = Date.now();
                reconnectAttempts = 0;
                if (pollingTimer) {
                    clearInterval(pollingTimer);
                    pollingTimer = null;
                }
                console.log('[LAESH WS] Conectado al servidor Swoole v6');
            };

            ws.onmessage = function(evt) {
                try {
                    var data = JSON.parse(evt.data);
                    // "ACK QoS Nivel 2" (auditoría 2026-09-20): eliminado — el servidor
                    // (swoole_server.php on('message')) nunca procesó este ack desde que
                    // se escribió; la condición para dispararlo tampoco se cumplía nunca
                    // hasta el fix de A5 (el payload no llevaba 'id'). Con A5 ya sí se
                    // cumpliría, pero el servidor lo seguiría descartando en silencio —
                    // tráfico sin ningún efecto. Implementar la confirmación real
                    // requeriría un puente HTTP inverso Swoole→PHP-FPM (Swoole no tiene
                    // conexión a BD por diseño, ver Notifier — comentarios Gap 6/§4.7 de
                    // Tecnica_Seguridad_Integral.html); eso es una feature nueva, no un
                    // fix de este código muerto. Se quita en vez de dejarlo a medias.
                    handleWsEvent(data);
                } catch (e) {
                    console.warn('[LAESH WS] Payload no JSON:', evt.data);
                }
            };

            ws.onerror = function() {
                startPollingFallback();
            };

            ws.onclose = function() {
                var wasStable = wsOpenedAt && (Date.now() - wsOpenedAt) >= MIN_STABLE_MS;
                wsOpenedAt = 0;
                if (!wasStable) {
                    // Conexión "flapping" — el servidor la cerró casi de inmediato
                    // (típicamente falla de autenticación WS). No cuenta como
                    // reintento sano; activa el respaldo de polling ya mismo.
                    startPollingFallback();
                }
                if (reconnectAttempts < maxReconnects) {
                    reconnectAttempts++;
                    setTimeout(initWebSocket, reconnectInterval);
                } else {
                    startPollingFallback();
                }
            };
        } catch (e) {
            startPollingFallback();
        }
    }

    function updateTitleCounter() {
        if (unreadCount > 0) {
            document.title = '(' + unreadCount + ') ' + originalTitle;
        } else {
            document.title = originalTitle;
        }
    }

    function resetNotifBadges() {
        unreadCount = 0;
        updateTitleCounter();
        var badges = document.querySelectorAll('#badge-recepcion, #badge-resultados, #badge-notif-cms, .bell-badge');
        badges.forEach(function(b) {
            b.textContent = '0';
            b.classList.remove('show', 'pulse');
            b.style.opacity = '0';
        });

        // Sincronización SSOT en MariaDB: marcar notificaciones pendientes como leídas
        var baseDir = window.location.pathname.replace(/\/+$/, '');
        fetch(baseDir + '/api/notificaciones/marcar-leida', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ all: 1 })
        }).catch(function() {});
    }

    // Asegurar estructura visual de abanicos en la barra lateral de notificaciones.
    // isMedico agrega un 3er abanico "Catálogo Actualizado" debajo de "Ayer y
    // Anteriores" — exclusivo del Portal Médico (2026-09-21, pedido del usuario):
    // catalogo_actualizado es ruido administrativo para el médico (no requiere
    // acción suya, a diferencia de nueva_orden/orden_actualizada/resultado_disponible),
    // así que se separa del flujo de Hoy/Ayer sin perder visibilidad. RC/Admin
    // conservan el comportamiento original (catalogo_actualizado dentro de Hoy/Ayer).
    function ensureAccordionStructure(container, isMedico) {
        if (container.querySelector('.notif-accordion-group')) return;

        var catalogoHtml = isMedico
            ? ('<!-- Abanico Catálogo Actualizado (solo Portal Médico) -->' +
               '<div class="notif-header-catalogo" style="display:flex; align-items:center; justify-content:space-between; cursor:pointer; background:#f8fafc; padding:8px 12px; border-radius:6px; border-left:4px solid #a855f7; margin-top:8px;">' +
                   '<span style="font-weight:600; font-size:0.85rem; color:#6b21a8;">🗂️ Catálogo Actualizado</span>' +
                   '<span class="badge-cnt-catalogo" style="background:#a855f7; color:#fff; font-size:0.75rem; padding:2px 8px; border-radius:12px; font-weight:600;">0</span>' +
               '</div>' +
               '<div class="notif-body-catalogo" style="display:none; flex-direction:column; gap:6px;"></div>')
            : '';

        container.innerHTML =
            '<div class="notif-accordion-group" style="display:flex; flex-direction:column; gap:8px;">' +
                '<!-- Abanico Hoy -->' +
                '<div class="notif-header-hoy" style="display:flex; align-items:center; justify-content:space-between; cursor:pointer; background:#eff6ff; padding:8px 12px; border-radius:6px; border-left:4px solid #0052b7;">' +
                    '<span style="font-weight:600; font-size:0.85rem; color:#1e3a8a;">📅 Hoy</span>' +
                    '<span class="badge-cnt-hoy" style="background:#0052b7; color:#fff; font-size:0.75rem; padding:2px 8px; border-radius:12px; font-weight:600;">0</span>' +
                '</div>' +
                '<div class="notif-body-hoy" style="display:flex; flex-direction:column; gap:6px;"></div>' +

                '<!-- Abanico Ayer y Anteriores -->' +
                '<div class="notif-header-anteriores" style="display:flex; align-items:center; justify-content:space-between; cursor:pointer; background:#f8fafc; padding:8px 12px; border-radius:6px; border-left:4px solid #64748b; margin-top:8px;">' +
                    '<span style="font-weight:600; font-size:0.85rem; color:#475569;">🕒 Ayer y Anteriores</span>' +
                    '<span class="badge-cnt-anteriores" style="background:#64748b; color:#fff; font-size:0.75rem; padding:2px 8px; border-radius:12px; font-weight:600;">0</span>' +
                '</div>' +
                '<div class="notif-body-anteriores" style="display:flex; flex-direction:column; gap:6px;"></div>' +

                catalogoHtml +
            '</div>';

        var headHoy = container.querySelector('.notif-header-hoy');
        var bodyHoy = container.querySelector('.notif-body-hoy');
        var headAnt = container.querySelector('.notif-header-anteriores');
        var bodyAnt = container.querySelector('.notif-body-anteriores');
        var headCat = container.querySelector('.notif-header-catalogo');
        var bodyCat = container.querySelector('.notif-body-catalogo');

        if (headHoy && bodyHoy) {
            headHoy.addEventListener('click', function() {
                bodyHoy.style.display = (bodyHoy.style.display === 'none') ? 'flex' : 'none';
            });
        }
        if (headAnt && bodyAnt) {
            headAnt.addEventListener('click', function() {
                bodyAnt.style.display = (bodyAnt.style.display === 'none') ? 'flex' : 'none';
            });
        }
        if (headCat && bodyCat) {
            headCat.addEventListener('click', function() {
                bodyCat.style.display = (bodyCat.style.display === 'none') ? 'flex' : 'none';
            });
        }
    }

    // 2026-09-21 (auditoría seguridad): titulo/mensaje llegan con texto de
    // usuario sin sanear desde el servidor (nombre de paciente, motivo de
    // cancelación, nombre de archivo PDF — ver commons/notifier.php callers).
    // CSP de producción permite 'unsafe-inline', así que un payload tipo
    // `<img src=x onerror=...>` en cualquiera de esos campos se ejecutaría sin
    // restricción si se concatena crudo en innerHTML. Único punto de
    // renderizado de estos campos — escapar aquí cubre WS en vivo y polling
    // fallback (ambos pasan por handleWsEvent).
    function escapeHtml(str) {
        var div = document.createElement('div');
        div.textContent = String(str == null ? '' : str);
        return div.innerHTML;
    }

    function isCreatedToday(dateStr) {
        if (!dateStr) return true; // notificaciones en vivo
        var notifDate = new Date(dateStr);
        if (isNaN(notifDate.getTime())) return true;
        var today = new Date();
        return notifDate.getFullYear() === today.getFullYear() &&
               notifDate.getMonth() === today.getMonth() &&
               notifDate.getDate() === today.getDate();
    }

    function handleWsEvent(data) {
        if (!data || !data.event) return;

        // 2026-09-21: detectado una sola vez aquí (mismo patrón ya usado en el
        // click handler más abajo) para enrutar catalogo_actualizado al abanico
        // dedicado en el Portal Médico, sin afectar a Recepción/Admin.
        var isMedicoPortal = !!document.getElementById('tabla-medico');
        var isCatalogoEvent = (data.event === 'catalogo_actualizado');

        // GAP-NOTIF-01 (2026-09-22): catalogo_actualizado es sincronización
        // administrativa en segundo plano ("no requiere acción suya", ver
        // comentario de ensureAccordionStructure) — se sigue registrando en
        // su propio abanico para trazabilidad, pero YA NO enciende la
        // campanita/globito rojo ni el contador de pestaña. Diagnóstico real
        // (2026-09-22): médicos/recepción reportaban una "alerta falsa" en
        // cada login — el badge se encendía por un catalogo_actualizado
        // genuinamente sin leer (acumulado de ediciones de catálogo de
        // otros usuarios), pero como cae en un abanico colapsado por
        // defecto y no en Hoy/Ayer (lo que el usuario revisa primero),
        // percibía la alerta como "sin mensajes". Ver también el fix de
        // actor_user_id en CatalogBuilder::build() — evita que Recepción/
        // Admin se autonotifique al editar el catálogo.
        if (!isCatalogoEvent) {
            // Incrementar contador de pestaña
            unreadCount++;
            updateTitleCounter();

            // Actualizar globitos rojos de notificación con animación
            var badges = document.querySelectorAll('#badge-recepcion, #badge-resultados, #badge-notif-cms, .bell-badge');
            badges.forEach(function(b) {
                var count = parseInt(b.textContent || '0', 10) + 1;
                b.textContent = count;
                b.classList.add('show', 'pulse');
                b.style.display = 'inline-flex';
                b.style.opacity = '1';
            });
        }

        // Inyectar ítem visual en los abanicos del panel lateral
        var notifLists = document.querySelectorAll('.sidebar-right-body, .sidebar-right .sidebar-right-body, .sidebar-right .modal-body, #sidebar-right .sidebar-right-body, #sidebar-right .modal-body');
        notifLists.forEach(function(container) {
            ensureAccordionStructure(container, isMedicoPortal);

            var isToday = isCreatedToday(data.creado_en);
            var targetBody, cntBadge;
            if (isMedicoPortal && isCatalogoEvent) {
                // Abanico dedicado — no entra a Hoy/Ayer y Anteriores en Médico.
                targetBody = container.querySelector('.notif-body-catalogo');
                cntBadge   = container.querySelector('.badge-cnt-catalogo');
            } else {
                targetBody = isToday ? container.querySelector('.notif-body-hoy') : container.querySelector('.notif-body-anteriores');
                cntBadge   = isToday ? container.querySelector('.badge-cnt-hoy') : container.querySelector('.badge-cnt-anteriores');
            }

            if (!targetBody) return;

            var item = document.createElement('div');
            item.className = 'card card-sm border-left-primary notif-item-clickable';
            item.style.padding = '8px 12px';
            item.style.fontSize = '0.82rem';
            item.style.background = isToday ? '#ffffff' : '#f8fafc';
            item.style.borderLeft = isToday ? '3px solid #0052b7' : '3px solid #94a3b8';
            item.style.borderRadius = '6px';
            item.style.boxShadow = '0 1px 3px rgba(0,0,0,0.05)';
            item.style.cursor = 'pointer';
            item.style.transition = 'transform 0.15s ease, box-shadow 0.15s ease';

            var folioRef = data.folio || data.folio_referencia || '';
            if (folioRef) {
                item.title = 'Haz clic para ir a la orden ' + folioRef;
            }

            var timeStr = data.creado_en ? new Date(data.creado_en).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            item.innerHTML = '<strong style="color: #0f172a;">' + escapeHtml(data.titulo || 'Nueva Notificación') + '</strong><br>' +
                             '<span class="txt-muted-sm" style="color: #475569; font-size: 0.78rem;">' + escapeHtml(data.mensaje || 'Se ha registrado una nueva actividad.') + '</span>' +
                             '<div style="font-size:0.7rem; color:#94a3b8; margin-top:2px;">' + timeStr + '</div>';

            // Hover UX
            item.addEventListener('mouseenter', function() {
                item.style.transform = 'translateY(-1px)';
                item.style.boxShadow = '0 3px 6px rgba(0,0,0,0.1)';
            });
            item.addEventListener('mouseleave', function() {
                item.style.transform = 'none';
                item.style.boxShadow = '0 1px 3px rgba(0,0,0,0.05)';
            });

            // Click Handler: Navegar a la pestaña (Hoy / Anteriores) y resaltar el renglón correspondiente.
            // Los ítems de catalogo_actualizado en el Portal Médico no tienen folio de
            // orden asociado — solo colapsan el panel, sin intentar navegar/resaltar.
            item.addEventListener('click', function() {
                // 2026-09-21 (corrección del usuario): el ítem NO se elimina del
                // abanico — se queda visible como historial, pero se marca "leído"
                // (visualmente atenuado) y deja de contar como no-leído. El contador
                // de la sección (Hoy / Ayer y Anteriores / Catálogo Actualizado) y el
                // globito de la campanita reflejan solo los no-leídos. Idempotente:
                // un segundo clic sobre el mismo ítem ya leído no vuelve a decrementar.
                if (!item.classList.contains('notif-leido')) {
                    item.classList.add('notif-leido');
                    item.style.opacity = '0.55';
                    item.title = (item.title || '') + ' (leído)';

                    if (cntBadge) {
                        cntBadge.textContent = Math.max(0, parseInt(cntBadge.textContent || '0', 10) - 1);
                    }

                    // catalogo_actualizado nunca incrementó unreadCount/campanita (ver
                    // GAP-NOTIF-01 arriba) — decrementarlos aquí restaría de cuenta
                    // real de otros eventos sí-contados. Solo el contador de sección
                    // (cntBadge, arriba) aplica para este tipo de ítem.
                    if (!isCatalogoEvent) {
                        unreadCount = Math.max(0, unreadCount - 1);
                        updateTitleCounter();

                        var bellBadges = document.querySelectorAll('#badge-recepcion, #badge-resultados, #badge-notif-cms, .bell-badge');
                        bellBadges.forEach(function(b) {
                            var nuevo = Math.max(0, parseInt(b.textContent || '0', 10) - 1);
                            b.textContent = nuevo;
                            if (nuevo === 0) {
                                b.classList.remove('show', 'pulse');
                                b.style.opacity = '0';
                            }
                        });
                    }
                }

                if (isMedicoPortal && isCatalogoEvent) {
                    var sidebarRightCat = document.querySelector('.sidebar-right, #sidebar-right');
                    if (sidebarRightCat) sidebarRightCat.classList.remove('active', 'show', 'open');
                    return;
                }

                var folioTarget  = folioRef;
                var isTodayNotif = isToday;

                // 1. Ocultar o colapsar el panel lateral de notificaciones
                var sidebarRight = document.querySelector('.sidebar-right, #sidebar-right');
                if (sidebarRight) {
                    sidebarRight.classList.remove('active', 'show', 'open');
                }

                // 2. Identificar si es Portal Médico o Recepción/Admin y cambiar de pestaña
                var isMedicoPortal   = !!document.getElementById('tabla-medico');
                var isRecepcionAdmin = !!document.getElementById('tabla-recepcion');

                var targetTableId = null;

                if (isMedicoPortal) {
                    if (isTodayNotif) {
                        if (typeof window.cambiarTabMedico === 'function') {
                            window.cambiarTabMedico('panel-nueva-orden');
                        }
                        if (typeof window.switchSubTab === 'function') {
                            window.switchSubTab('ordenes-hoy');
                        }
                        targetTableId = 'tabla-medico';
                    } else {
                        if (typeof window.cambiarTabMedico === 'function') {
                            window.cambiarTabMedico('panel-historial-medico');
                        }
                        targetTableId = 'tabla-historial-completo';
                    }
                } else if (isRecepcionAdmin) {
                    if (isTodayNotif) {
                        if (typeof window.cambiarTabAdmin === 'function') {
                            window.cambiarTabAdmin('panel-ordenes');
                        }
                        targetTableId = 'tabla-recepcion';
                    } else {
                        if (typeof window.cambiarTabAdmin === 'function') {
                            window.cambiarTabAdmin('panel-ordenes-anteriores');
                        }
                        targetTableId = 'tabla-recepcion-anteriores';
                    }
                }

                // 3. Buscar y resaltar el renglón correspondiente a la orden en la tabla
                if (targetTableId && folioTarget) {
                    var findAndHighlightRow = function() {
                        var table = document.getElementById(targetTableId);
                        if (!table) return;
                        var rows = table.querySelectorAll('tbody tr');
                        var foundRow = null;

                        rows.forEach(function(r) {
                            if (r.textContent.indexOf(folioTarget) !== -1) {
                                foundRow = r;
                            }
                        });

                        if (foundRow) {
                            foundRow.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            foundRow.classList.remove('row-notif-highlight');
                            void foundRow.offsetWidth; // Force CSS reflow to restart animation
                            foundRow.classList.add('row-notif-highlight');
                            setTimeout(function() {
                                foundRow.classList.remove('row-notif-highlight');
                            }, 3000);
                        }
                    };

                    findAndHighlightRow();
                    setTimeout(findAndHighlightRow, 250);
                }
            });

            // Inserción en orden descendente (más nueva arriba)
            targetBody.insertBefore(item, targetBody.firstChild);

            // El badge de sección cuenta NO-LEÍDOS, no el total de ítems del
            // historial — se incrementa desde su valor actual, no se recalcula
            // desde targetBody.children.length (eso incluiría los ya leídos).
            if (cntBadge) {
                cntBadge.textContent = parseInt(cntBadge.textContent || '0', 10) + 1;
            }
        });

        // Refrescar el catálogo compilado en memoria (catalog-compiled.js) cuando el Admin / Recepción modifica MariaDB
        if (data.event === 'catalogo_actualizado') {
            var oldScript = document.getElementById('script-catalog-compiled');
            if (oldScript) oldScript.remove();
            var s = document.createElement('script');
            s.id = 'script-catalog-compiled';
            s.src = '/laesh-web-assets-uipv1a/js/catalog-compiled.js?v=' + Date.now();
            s.onload = function() {
                // Portal Médico: re-poblar grilla "20 Est.Med" con los datos frescos
                if (typeof window.populateMandatoryGrid === 'function') window.populateMandatoryGrid();
            };
            document.head.appendChild(s);
            console.info('[LAESH Notif] Catálogo compilado sincronizado en memoria (catalog-compiled.js)');
        }

        // Refrescar automáticamente la tabla de recepción o médicos (Hoy y Anteriores)
        // Gap 4 (auditoría 2026-09-18): 'resultados_listos' es el nombre real del `tipo`
        // en BD (commons/notifier.php) — cuando la notificación llega vía polling fallback
        // (no WS en vivo), n.tipo trae ese valor, no 'resultado_disponible'. Sin esta rama,
        // el badge/panel sí aparecía pero la tabla de resultados no se refrescaba sola.
        if (data.event === 'nueva_orden' || data.event === 'orden_actualizada' || data.event === 'resultado_disponible' || data.event === 'resultados_listos') {
            var tablaRecepcion           = document.getElementById('tabla-recepcion');
            var tablaRecepcionAnteriores = document.getElementById('tabla-recepcion-anteriores');
            var tablaMedico              = document.getElementById('tabla-medico');
            var tablaHistorialMedico     = document.getElementById('tabla-historial-completo');

            if (typeof htmx !== 'undefined') {
                if (tablaRecepcion)           htmx.trigger(tablaRecepcion, 'refresh');
                if (tablaRecepcionAnteriores) htmx.trigger(tablaRecepcionAnteriores, 'refresh');
            } else if (tablaRecepcion) {
                var btnRefreshR = document.getElementById('btn-refrescar-tabla');
                if (btnRefreshR) btnRefreshR.click();
            }

            // FIX-SPASM: Si el médico tiene foco en el form de nueva orden,
            // diferir el swap de tablas del médico para no robar el cursor del input activo.
            if (tablaMedico || tablaHistorialMedico) {
                var formOrden = document.getElementById('form-orden');
                var activeEl  = document.activeElement;
                var userIsTyping = formOrden && activeEl &&
                    (activeEl.tagName === 'INPUT' || activeEl.tagName === 'TEXTAREA') &&
                    formOrden.contains(activeEl);

                var doRefreshMedico = function() {
                    if (typeof htmx !== 'undefined') {
                        if (tablaMedico)          htmx.trigger(tablaMedico, 'refresh');
                        if (tablaHistorialMedico) htmx.trigger(tablaHistorialMedico, 'refresh');
                    } else {
                        var btnRefreshM = document.getElementById('btn-refrescar-tabla');
                        if (btnRefreshM) btnRefreshM.click();
                    }
                };

                if (userIsTyping) {
                    if (!activeEl._hasPendingRefresh) {
                        activeEl._hasPendingRefresh = true;
                        var _onBlur = function() {
                            activeEl._hasPendingRefresh = false;
                            activeEl.removeEventListener('blur', _onBlur);
                            doRefreshMedico();
                        };
                        activeEl.addEventListener('blur', _onBlur);
                    }
                } else {
                    doRefreshMedico();
                }
            }
        }

        // Feedback auditivo (solo si ya existió interacción de usuario) —
        // catalogo_actualizado no suena, mismo criterio que el badge arriba.
        if (!isCatalogoEvent) playChime();
    }

    function playChime() {
        if (!hasUserGesture || !sharedAudioCtx) return;
        try {
            if (sharedAudioCtx.state === 'suspended') {
                var p = sharedAudioCtx.resume();
                if (p && typeof p.then === 'function') {
                    p.then(function() { triggerTone(sharedAudioCtx); }).catch(function() {});
                }
            } else {
                triggerTone(sharedAudioCtx);
            }
        } catch (e) {}
    }

    function triggerTone(audioCtx) {
        try {
            var osc = audioCtx.createOscillator();
            var gain = audioCtx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(587.33, audioCtx.currentTime);
            gain.gain.setValueAtTime(0.05, audioCtx.currentTime);
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.start();
            osc.stop(audioCtx.currentTime + 0.15);
        } catch (e) {}
    }

    document.addEventListener('DOMContentLoaded', function() {
        pollNotifications();
        initWebSocket();

        // Resetear globitos rojos y contador de pestaña al interactuar con el panel lateral
        var toggleBtns = document.querySelectorAll('#bell-wrap-notif, #sidebar-right-toggle, .bell-wrap');
        toggleBtns.forEach(function(btn) {
            btn.addEventListener('click', resetNotifBadges);
        });
    });
})();
