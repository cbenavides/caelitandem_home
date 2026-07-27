# RESUMEN DE LA OFERTA DE SERVICIOS
**Proyecto:** Laboratorio Clínico LAESH - Digitalización

Este documento presenta las dos modalidades de contratación disponibles. Las propuestas están diseñadas para permitir a "EL CLIENTE" elegir el alcance tecnológico y funcional que mejor se adapte a su presupuesto y urgencia operativa.

*(Nota: Toda propuesta se instrumenta bajo un **Contrato Base Modular** — ver sección **Estructura Documental**).* 

---

### Proyecto 1: Sitio Web (Básico)

*   **Inversión Total:** $10,000.00 MXN
*   **Esquema de Pago (2 Hitos):** 30% Anticipo ($3,000) / 70% Firma de Aceptación ($7,000).
*   **Tiempo de Entrega:** 1 Mes (30 días naturales).
*   **Garantía:** 15 días naturales (Inicia a partir de la firma de Aceptación).
*   **Alcance Funcional:** Página web sencilla (5 secciones). Incluye Inicio, Nosotros (Cédulas), Catálogo de Estudios y Precios, Contacto (con link de Google Maps y botón directo a WhatsApp), y Aviso de Privacidad. Es la solución ideal para tener una presencia profesional en internet. *(Incluye periodo de Estabilización de 15 días y capacitación; ver Condiciones Generales).*
*   **Alcance Tecnológico:** Incluye optimización básica para posicionamiento en buscadores (Google) y adaptabilidad para celulares y tablets.

---

### Proyecto 2: Bloc Digital sin WhatsApp

*   **Inversión Total:** $25,000.00 MXN
*   **Esquema de Pago (2 Hitos):** 30% Anticipo ($7,500) / 70% Firma de Aceptación ($17,500).
*   **Tiempo de Entrega:** 2 Meses (60 días naturales).
*   **Garantía:** 30 días naturales (Inicia a partir de la firma de Aceptación).
*   **Alcance Funcional:** Automatización para crear y rastrear las órdenes de laboratorio en un ecosistema web 100% privado:
    1. **Generación de Orden (`Remitido`):** El médico tratante crea la solicitud digital desde su portal (`laesh.mx/medicos`). El sistema genera una **hoja impresa (formato LAESH)** con un `#folio` único y código de barras simple. Esta orden queda asociada al registro del paciente y **disponible de forma inmediata para su descarga en PDF desde el portal de recepción (`laesh.mx/labadmin`)**, permitiendo al personal de la clínica re-imprimirla si el paciente acude sin ella.
    2. **Recepción del Paciente (`En Atención`):** El paciente acude a la clínica con su hoja (o dictando su nombre). La recepcionista lo localiza mediante un **buscador unificado e inteligente** (autocompletado a partir de 5 caracteres por folio o nombre en una misma barra de búsqueda) y cambia el estado a **En Atención**.
    3. **Carga de Resultados y Notificación al Médico (`Resultados Listos`):** Cuando el examen clínico se realiza en LAESH, el personal sube el PDF de resultados mediante un botón/modal de **Carga Manual (Upload)** en `laesh.mx/labadmin`. Al subir el archivo, el sistema **actualiza automáticamente el estado a `Resultados Listos`** y dispara de forma inmediata una notificación en tiempo real (globito contador y detalle) al portal del médico (`laesh.mx/medicos`). En el mensaje de la notificación **se incluye un enlace directo para descargar el PDF de resultados**.
    4. **Cierre de Solicitud (`Cerrada`):** El paciente recibe sus resultados impresos en ventanilla de forma tradicional, marcándose la orden como **Cerrada** (o cerrándose automáticamente tras 30 días sin presentarse).
*   **Consideración Operativa:** Los resultados de laboratorio se entregan al paciente de forma **tradicional (en papel por ventanilla)**. El ecosistema es 100% web y privado, sin depender de redes sociales (WhatsApp) ni generar costos recurrentes de comunicación.
*   **Alcance Tecnológico:** Sistema web en la nube, perfiles de usuario, roles de seguridad (Recepción, Médico, Administrador), módulo de carga manual de PDF (Upload), buscador unificado por autocompletado y notificaciones en tiempo real con enlace directo a descarga utilizando tecnología open-source de **Node.js/Swoole (WebSockets)**.

---

## Cuadro Comparativo (Inversión vs. Valor Funcional)
Para facilitar la toma de decisiones, la siguiente tabla resume las funcionalidades, ventajas y limitantes de cada propuesta tecnológica ofertada, permitiendo visualizar rápidamente el costo-beneficio.

| Característica | Proyecto 1: Sitio Web | Proyecto 2: Bloc Digital sin WhatsApp |
| :--- | :--- | :--- |
| **--- 1. CONDICIONES COMERCIALES ---** | | |
| **Objetivo Principal** | Presencia Pública | Digitalización de Órdenes y Control Interno |
| **Inversión Desarrollo** | $10,000 MXN | $25,000 MXN |
| **Tiempo de Entrega** | 1 Mes | 2 Meses |
| **Esquema de Pago** | 2 Hitos (30% Anticipo / 70% Aceptación) | 2 Hitos (30% Anticipo / 70% Aceptación) |
| **Esquema Fiscal (Facturación)** | Montos netos (RESICO a Persona Moral) | Montos netos (RESICO a Persona Moral) |
| **--- 2. PORTALES Y PRESENCIA WEB ---** | | |
| **Sitio Web Público** (`laesh.mx`) | ✅ 5 secciones (Inicio, Nosotros, Servicios, Indicaciones, Contacto) | No aplica (Es un sistema interno) |
| **Portal Médico Responsive (Celular/Tablet)** (`laesh.mx/medicos`) | No aplica | ✅ Generación de órdenes, alertas en vivo y descarga directa de PDF de resultados |
| **Portal de Recepción** (`laesh.mx/labadmin`) | No aplica | ✅ Recepción de pacientes, descarga de orden en PDF, gestión de estados y carga de PDF de resultados |
| **--- 3. OPERACIÓN Y FUNCIONALIDADES CLAVE ---** | | |
| **Generación de Hoja Impresa y Descarga PDF** | No aplica | ✅ Formato LAESH con `#folio` único y código de barras. Descargable en PDF por recepción |
| **Buscador Inteligente (Recepción)** | No aplica | ✅ Input unificado: Autocompletado (min. 5 caracteres) por nombre de paciente o folio |
| **Workflow de Estados (Remitido ➔ Atención ➔ Listos ➔ Cerrada)** | No aplica | ✅ Control de flujo operativo y actualización automática de estado al cargar resultados |
| **Carga Manual de Resultados (Upload PDF)** | No aplica | ✅ Módulo para subir el PDF de resultados, cambiando automáticamente el estado a *Resultados Listos* |
| **Notificación al Médico con Link Directo** | No aplica | ✅ Alerta WebSocket en vivo ("globito") al médico con enlace directo para descargar el PDF de resultados |
| **Flujo de Entrega al Paciente** | No aplica | Tradicional (Impreso en ventanilla de la clínica) |
| **Módulo de Reportes y Estadísticas** | No aplica | ✅ Básicas por médico, paciente y para el laboratorio |
| **--- 4. RESPALDO, GARANTÍA Y FUTURO ---** | | |
| **Fase de Capacitación y Estabilización** | No aplica | ✅ 15 Días presencial al momento de requerirse |
| **Garantía Post-Entrega** | 15 días | 30 días |
| **Seguridad y Respaldos** | ✅ (Vía Póliza Anual de Servidor) | ✅ (Vía Póliza Anual de Servidor) |
| **Licenciamiento** | Perpetua (Sin rentas mensuales de software) | Perpetua (Sin rentas mensuales de software) |
| **--- RESUMEN FINAL ---** | | |
| **Pros (Ventajas)** | Económico y rápido de implementar. Atrae pacientes nuevos vía Google. | Elimina errores por mala letra en recetas. Recepción puede descargar/imprimir la orden si el paciente la extravió. Notificación inmediata al médico con link directo al PDF de resultados. Sin costos de WhatsApp API. |
| **Contras (Limitantes)** | No resuelve problemas operativos internos. | No digitaliza la entrega de resultados al paciente (se mantiene en papel). No incluye página web pública (solo portales privados). |

---

# SECCIÓN DE ANEXOS Y CONSIDERACIONES DETALLADAS
*La siguiente sección profundiza en las normativas, riesgos, garantías y estructura legal que amparan la ejecución de cualquiera de las propuestas listadas en el Resumen Ejecutivo superior.*

---

## Condiciones y Requisitos Generales (Aplicables a todos los proyectos)
*   **Modelo de Entrega y Estabilización:** Independientemente del proyecto elegido, se incluye una fase de **15 días naturales de Estabilización** (pruebas en vivo y capacitación) posterior al despliegue. Al concluir estos 15 días se firma el Acta de Aceptación, liquidando el 70% final y arrancando la Garantía correspondiente.
*   **Presupuesto para Proveedores de Terceros (Infraestructura):** Al ser un ecosistema 100% en la Nube (Cloud), el sistema operará en servidores contratados a nombre de "EL CLIENTE". Los costos estimados son:

    | Concepto Externo (Proveedor) | Frecuencia | Inversión Estimada | Aplica para | Observaciones Operativas |
    | :--- | :---: | :--- | :---: | :--- |
    | **Hosting Básico (Hostinger)** | Anual | ~$500 MXN | Proyecto 1 | Plan de hosting compartido básico, suficiente para una página web estática. |
    | **Servidor en la Nube VPS (Hostinger)** | Anual | ~$1,500 a ~$2,000 MXN | Proyecto 2 | Plan optimizado VPS KVM 2, ideal para soportar el ecosistema web y las alertas en tiempo real. |
    | **Dominio de Internet (.mx)** | Anual | ~$600 MXN | Todos | Nombre público e institucional de su página web (Ej. `laesh.mx`). |

> **Seguridad y Privacidad de Datos:** El sistema usa protocolos de seguridad modernos: toda la información viaja encriptada por internet (candado verde HTTPS), y las contraseñas se guardan cifradas.
>
> **Propiedad de Datos e Historial Clínico (5 años):** "EL CLIENTE" será siempre el dueño absoluto y exclusivo de toda su información procesada. La base de datos está diseñada para retener el historial operativo del laboratorio hasta por **5 años**.
>
> **Licenciamiento Tecnológico:** La clínica adquiere una **licencia de uso perpetua**; jamás pagará "rentas" por el derecho de usar el software.

### Funcionalidades Fuera de Alcance
A fin de mantener un ecosistema eficiente y sin ambigüedades, queda expresamente fuera de las propuestas planteadas el desarrollo de:

| Concepto Excluido | Detalle y Razón Operativa |
| :--- | :--- |
| **Notificaciones vía Redes Sociales** | El sistema no emplea WhatsApp, SMS, ni Meta Cloud API. Toda notificación es web (in-app). |
| **Bandeja Omnicanal y Chatbots** | Todo el ecosistema opera de manera 100% web en portales. No se incluye Chatwoot ni chatbots para responder dudas médicas. |
| **Aplicaciones Móviles Nativas** | Todo el ecosistema opera de manera 100% web. No se desarrollarán ni publicarán apps instalables en tiendas (App Store / Google Play). |
| **Punto de Venta / Pasarelas** | Quedan excluidas las terminales de pago, pasarelas para cobro con tarjeta en línea y módulos de control de caja. |
| **Módulos Financieros Avanzados** | Queda fuera la Facturación Electrónica (CFDI) y el cálculo de honorarios de médicos referidores. |
| **Cuentas de Correo Corporativo** | No incluye creación ni alojamiento de buzones para empleados. |

---

## Servicios Post-Salida (Sugeridos para el Año 1)
Una vez concluidos los periodos de garantía gratuitos, se sugieren las siguientes pólizas de mantenimiento:

| Póliza Sugerida | Inversión Anual | Cobertura Principal | Aplica para |
| :--- | :--- | :--- | :---: |
| **1. Soporte a Producción (Mantenimiento)** | $8,000 MXN | Bolsa de 12 horas mensuales para cambios o resolución rápida de incidentes. | Todos |
| **2. Administración de Servidor / Hosting** | $4,000 MXN | Mano de obra técnica (Respaldos automáticos, parches de seguridad de la nube). | Proyecto 2 |

---

## Riesgos y Mitigaciones Operativas

| Riesgo Identificado | Impacto Potencial | Estrategia de Mitigación |
| :--- | :--- | :--- |
| **Caídas de Infraestructura de Terceros** | Interrupciones por mantenimiento o caídas globales del proveedor de hosting (Hostinger). | Contratación de la *Póliza de Administración de Servidor* para copias de seguridad continuas y reactivación ágil (SLA de 2 horas). |
| **Fallas en Impresión de Hojas** | El paciente podría llegar sin hoja impresa si la impresora del médico tratante falla. | La recepcionista puede buscar al paciente por autocompletado en `labadmin` y descargar/imprimir directamente el PDF de la orden médica. |

---

## Consideraciones Fiscales y Administrativas
*   **Aceptación y Liberación de Pagos:** El cobro del 100% del proyecto se rige por el esquema de 2 hitos (30% Anticipo / 70% Firma del Acta de Aceptación).
*   **Montos Libres:** Todas las cantidades listadas en esta propuesta son **montos netos (libres de impuestos)** a favor del Prestador.
*   **Cálculo Inverso:** (RESICO) El Cliente (Persona Moral) es responsable de realizar el cálculo a la inversa (de neto a bruto) al momento de la facturación.

---

## Estructura Documental
Para garantizar total transparencia técnica y comercial, este proyecto se rige por un conjunto de documentos modulares complementarios.

| Archivo Legal / Técnico | Abstracto del Contenido |
| :--- | :--- |
| **1. Carta_Presentacion.md** | Carta ejecutiva de introducción al proyecto, contexto de la oferta y próximos pasos. |
| **2. Resumen_Oferta_Servicios.md** | Documento rector (el actual) que compara propuestas, costos, infraestructura y responsabilidades. |
| **3. Contrato_Base_Desarrollo.md** | Marco legal que establece hitos de pago, confidencialidad y límites de responsabilidad. |
| **4. Anexo_A_Sitio_Web.md** | Especificación técnica para el Proyecto 1. |
| **5. Anexo_A_Bloc_Digital.md** | Especificación técnica exclusiva para el Proyecto 2 (Reglas del portal médico, buscadores, workflow de estados, descarga de orden PDF, carga de resultados y notificaciones con link directo). |
| **6. Contrato_Administracion_Servidor.md** | Póliza (opcional) para respaldos automáticos y monitoreo de la nube. |
| **7. Anexo_B_Soporte_Produccion.md** | Póliza (opcional) de mantenimiento y corrección de bugs post-garantía. |
