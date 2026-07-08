# Plan de Estabilizacion PWA Comandas VOSK

Fecha base: 2026-07-07

## Objetivo

Estabilizar la PWA de comandas con captura por voz usando VOSK, priorizando operacion confiable en restaurante: instalacion PWA consistente, funcionamiento offline controlado, reconocimiento de voz robusto, persistencia local segura, sincronizacion con servidor y una experiencia clara para meseros/cocina.

## Alcance

- Auditoria tecnica de la PWA actual.
- Correccion de manifest, service worker, cache y actualizaciones.
- Estabilizacion del flujo de comandas.
- Integracion y endurecimiento de captura por voz con VOSK.
- Persistencia local para trabajo intermitente/offline.
- Sincronizacion idempotente con backend.
- Estados visibles de red, microfono, permisos y sincronizacion.
- Pruebas manuales y automatizables para escenarios criticos.
- Documentacion operativa para despliegue y soporte.

## No Alcance Inicial

- Redisenar todo el sistema de restaurante.
- Cambiar stack principal sin necesidad tecnica.
- Implementar analitica avanzada.
- Sustituir VOSK por otro motor salvo bloqueo probado.

## Principios De Construccion

- Primero estabilizar el camino feliz de una comanda completa.
- Cada cambio debe poder probarse en local.
- El modo offline debe ser explicito: no prometer envio si no hay confirmacion del servidor.
- Las comandas deben tener identificadores locales y remotos para evitar duplicados.
- Los errores deben mostrarse con acciones recuperables.
- La voz complementa la captura manual; no debe bloquearla.

## Fase 0 - Inventario Y Linea Base

1. Identificar estructura del proyecto, rutas publicas, assets, backend y vistas.
2. Ubicar manifest, service worker, scripts de PWA, scripts de voz y endpoints de comandas.
3. Documentar flujo actual:
   - Abrir PWA.
   - Crear comanda.
   - Capturar productos manualmente.
   - Capturar productos por voz.
   - Guardar/enviar.
   - Ver estado en cocina o panel correspondiente.
4. Ejecutar la app localmente y anotar errores de consola/red.
5. Definir navegadores objetivo:
   - Chrome/Android como principal.
   - Desktop Chromium para pruebas.

Entregables:

- Mapa de archivos relevantes.
- Lista priorizada de fallos observados.
- Primer checklist de smoke test.

## Fase 1 - PWA Basica Confiable

1. Revisar `manifest.webmanifest` o equivalente:
   - `name`, `short_name`, `start_url`, `scope`.
   - `display` recomendado: `standalone`.
   - `theme_color`, `background_color`.
   - Iconos validos en 192x192 y 512x512.
2. Revisar registro del service worker:
   - Registro solo si el navegador lo soporta.
   - Manejo visible de errores de registro.
   - Evitar multiples registros conflictivos.
3. Revisar estrategia de cache:
   - App shell cacheado.
   - Assets estaticos con version.
   - APIs no cacheadas de forma peligrosa.
   - Fallback offline controlado.
4. Agregar versionado de cache:
   - Nombre de cache con version.
   - Limpieza de caches viejos en `activate`.
5. Controlar actualizaciones:
   - Detectar nueva version.
   - Mostrar accion de recargar cuando aplique.

Entregables:

- Manifest valido.
- Service worker estable.
- PWA instalable.
- Cache sin respuestas obsoletas para comandas.

## Fase 2 - Modelo De Comanda Y Persistencia Local

1. Definir contrato minimo de comanda local:
   - `local_id`.
   - `remote_id`.
   - `mesa` o identificador de servicio.
   - `items`.
   - `notas`.
   - `estado`.
   - `created_at`, `updated_at`.
   - `sync_status`: `draft`, `pending`, `syncing`, `synced`, `error`.
2. Elegir persistencia local:
   - Preferente: IndexedDB si ya existe o si el volumen lo justifica.
   - Alternativa temporal: localStorage solo para prototipo de bajo riesgo.
3. Guardar borradores automaticamente.
4. Mantener cola de envio para comandas pendientes.
5. Evitar duplicados:
   - Enviar `local_id` al backend.
   - Backend debe responder de forma idempotente si recibe el mismo `local_id`.

Entregables:

- Comanda no se pierde al recargar.
- Cola local visible.
- Reintento seguro sin duplicar.

## Fase 3 - Captura Por Voz Con VOSK

1. Ubicar implementacion actual de VOSK:
   - Carga de modelo.
   - Worker o proceso de reconocimiento.
   - Captura de microfono.
   - Parser de texto a items.
2. Endurecer permisos de microfono:
   - Estado inicial claro.
   - Solicitud activada por gesto de usuario.
   - Mensaje si el permiso fue denegado.
3. Controlar estados del motor:
   - `idle`.
   - `loading_model`.
   - `ready`.
   - `listening`.
   - `processing`.
   - `error`.
4. Optimizar carga del modelo:
   - Cachear assets necesarios.
   - Mostrar progreso si el modelo es pesado.
   - Evitar recargas repetidas.
5. Normalizar texto reconocido:
   - Minusculas.
   - Quitar acentos si ayuda al matching.
   - Limpiar ruido comun.
6. Parser de comandas:
   - Cantidades: "uno", "dos", "3".
   - Productos con sinonimos.
   - Notas: "sin cebolla", "para llevar", "bien cocido".
   - Confirmacion visual antes de enviar.
7. Fallback manual siempre disponible.

Entregables:

- Voz inicializa de forma predecible.
- Estados y errores visibles.
- Texto reconocido se puede convertir a items editables.
- Captura manual no depende de VOSK.

## Fase 4 - Sincronizacion Y Backend

1. Identificar endpoints actuales de comandas.
2. Documentar request/response real.
3. Validar datos en cliente antes de enviar.
4. Implementar envio idempotente:
   - `local_id` obligatorio.
   - Respuesta con `remote_id`.
   - Reintentos con backoff simple.
5. Manejar errores:
   - Sin red.
   - Timeout.
   - Error 4xx validable por usuario.
   - Error 5xx reintentable.
6. Mostrar estado de sincronizacion por comanda.
7. Crear accion "reintentar pendientes".

Entregables:

- Comandas pendientes se envian al recuperar red.
- Errores no destruyen datos locales.
- El usuario sabe que paso con cada comanda.

## Fase 5 - Experiencia De Usuario Operativa

1. Pantalla principal enfocada en captura de comanda.
2. Indicadores discretos pero claros:
   - Online/offline.
   - Microfono.
   - VOSK listo/escuchando.
   - Pendientes por sincronizar.
3. Acciones principales:
   - Nueva comanda.
   - Escuchar/detener.
   - Agregar item manual.
   - Guardar borrador.
   - Enviar comanda.
4. Estados vacios y de error:
   - Sin productos.
   - Sin microfono.
   - Sin red.
   - Modelo no disponible.
5. Confirmacion antes de envio si la comanda vino por voz.

Entregables:

- Flujo usable en pantalla tactil.
- No hay bloqueos silenciosos.
- Se puede operar aunque falle voz o red.

## Fase 6 - Pruebas

Smoke test minimo:

1. Abrir app limpia.
2. Verificar manifest y registro del service worker.
3. Instalar PWA.
4. Crear comanda manual.
5. Recargar antes de enviar y confirmar que el borrador sigue.
6. Enviar online y confirmar estado `synced`.
7. Crear comanda offline.
8. Recuperar red y sincronizar.
9. Activar microfono.
10. Capturar texto de voz y convertirlo a item editable.
11. Denegar microfono y confirmar mensaje recuperable.
12. Actualizar version de service worker y confirmar recarga controlada.

Pruebas tecnicas sugeridas:

- Unitarias para normalizador/parser de voz.
- Integracion para cola de sincronizacion.
- E2E con Playwright para flujo manual y estados offline/online.
- Validacion Lighthouse/PWA cuando el entorno lo permita.

Entregables:

- Checklist ejecutado.
- Bugs corregidos o registrados.
- Pruebas automatizadas donde exista infraestructura.

## Fase 7 - Documentacion Y Despliegue

1. Documentar como levantar el proyecto localmente.
2. Documentar rutas/archivos PWA.
3. Documentar modelos VOSK:
   - Ubicacion.
   - Tamano.
   - Como actualizar.
4. Documentar checklist pre-produccion.
5. Documentar procedimiento de rollback:
   - Version de cache.
   - Assets.
   - Backend.

Entregables:

- Guia tecnica breve.
- Checklist de despliegue.
- Notas de soporte para fallos comunes.

## Orden De Construccion Inicial

1. Inventario del repo y ubicacion de PWA/VOSK.
2. Arreglar manifest y service worker.
3. Proteger flujo manual de comanda.
4. Agregar persistencia local.
5. Agregar cola de sincronizacion.
6. Estabilizar VOSK y parser.
7. Cubrir pruebas criticas.
8. Documentar despliegue.

## Riesgos

- VOSK puede requerir assets pesados que compliquen instalacion/offline.
- iOS/Safari puede limitar service workers, audio o almacenamiento.
- Si el backend no soporta idempotencia, los reintentos pueden duplicar comandas.
- Cachear respuestas de API sin cuidado puede mostrar comandas obsoletas.
- Permisos de microfono pueden quedar bloqueados por decisiones previas del usuario.

## Criterios De Aceptacion

- La PWA se instala y abre desde icono.
- La app funciona en modo standalone sin rutas rotas.
- Una comanda no se pierde al recargar.
- Una comanda creada offline se sincroniza al volver la red.
- Reintentar no duplica comandas.
- VOSK puede fallar sin impedir captura manual.
- Los estados de red, voz y sincronizacion son visibles.
- Hay checklist de pruebas ejecutable por soporte/desarrollo.

## Notas De Construccion

- 2026-07-07: Se confirma que la PWA objetivo vive en `www/web-assets/` y las vistas en `www/restaurant/`.
- 2026-07-07: `v-ospv/vozweb.php` queda identificado como POC y fuera del alcance de implementacion.
- 2026-07-07: Primera estabilizacion PWA aplicada: manifest con scope/id, fallback offline, service worker sin cache de APIs y aviso de actualizacion.
- 2026-07-07: Se agrega idempotencia de reintentos offline con `uuid_local` en cliente y `client_uuid` unico en backend.

- 2026-07-07: Se recrea `vcd01` con `setup.sh`; se verifica `client_uuid` e indice unico, y pasan 24/24 pruebas funcionales PHP.

## Registro De Avance

- [x] Inventario tecnico completado.
- [x] PWA basica estabilizada.
- [ ] Persistencia local implementada.
- [x] Cola de sincronizacion implementada.
- [ ] Captura VOSK estabilizada.
- [ ] Parser de voz cubierto.
- [x] Pruebas criticas ejecutadas.
- [ ] Documentacion de despliegue completada.
