# RESUMEN DE LA OFERTA DE SERVICIOS
**Proyecto:** Laboratorio Clínico LAESH - Digitalización

Este documento presenta las dos modalidades de contratación disponibles. Las propuestas están diseñadas para permitir a "EL CLIENTE" elegir el alcance tecnológico y funcional que mejor se adapte a su presupuesto y urgencia operativa.

*(Nota: Toda opción se instrumenta bajo un **Contrato Base Modular** — ver sección **Estructura Documental**).* 

---

### Opción 1: Sitio Web (Básico)

*   **Inversión Total:** $10,000.00 MXN
*   **Esquema de Pago (2 Hitos):** 50% Anticipo ($5,000) / 50% Firma de Aceptación ($5,000).
*   **Tiempo de Entrega:** 1 Mes (30 días naturales).
*   **Garantía:** 15 días naturales (Inicia a partir de la firma de Aceptación).
*   **Alcance Funcional:** Página web sencilla (5 secciones). Incluye Inicio, Nosotros (Cédulas), Catálogo de Estudios y Precios, Contacto (con link de Google Maps y botón directo a WhatsApp), y Aviso de Privacidad. Es la solución ideal para tener una presencia profesional en internet. *(Incluye periodo de Estabilización de 15 días y capacitación; ver Condiciones Generales).*
*   **Alcance Tecnológico:** Incluye optimización básica para posicionamiento en buscadores (Google) y adaptabilidad para celulares y tablets.

---

### Opción 2: Bloc Digital de Solicitudes Clínicas

*   **Inversión Total:** $25,000.00 MXN
*   **Esquema de Pago (3 Hitos):** 30% Anticipo ($7,500) / 30% Despliegue a Producción ($7,500) / 40% Firma de Aceptación ($10,000).
*   **Tiempo de Entrega:** 2 Meses (60 días naturales).
*   **Garantía:** 30 días naturales (Inicia a partir de la firma de Aceptación).
*   **Alcance Funcional:** Automatización para crear y rastrear las órdenes de laboratorio. El médico tratante genera la orden clínica digital desde su portal (celular o tablet). El paciente recibe una **hoja impresa (formato LAESH)** generada por el sistema con un `#folio` único y un código de barras simple. El paciente acude a la clínica con esta hoja (o indicando su nombre). La recepción busca la orden usando un buscador unificado (autocompletado a partir de 5 caracteres, permitiendo buscar por nombre o folio en el mismo input). Adicionalmente, el sistema notifica en tiempo real (globito contador y panel de detalles) a los portales web de Laboratorio (`laesh.mx/labadmin`) y Médicos (`laesh.mx/medicos`) sobre el estatus de las solicitudes. 
*   **Consideración Operativa:** Los resultados de laboratorio se siguen entregando de forma **tradicional (en papel por ventanilla)**. El ecosistema es 100% web y privado, sin depender de redes sociales externas (como WhatsApp) para la transmisión de órdenes ni resultados.
*   **Alcance Tecnológico:** Sistema web en la nube, perfiles de usuario, roles de seguridad (Recepción, Médico, Administrador), generación dinámica de PDFs (hoja de paciente), motor de búsqueda por autocompletado y notificaciones en tiempo real utilizando tecnología open-source de **Node.js/Swoole**.

---

## Cuadro Comparativo (Inversión vs. Valor Funcional)
Para facilitar la toma de decisiones, la siguiente tabla resume las funcionalidades, ventajas y limitantes de cada opción tecnológica ofertada, permitiendo visualizar rápidamente el costo-beneficio.

| Característica | Opción 1: Sitio Web | Opción 2: Bloc Digital |
| :--- | :--- | :--- |
| **--- 1. CONDICIONES COMERCIALES ---** | | |
| **Objetivo Principal** | Presencia Pública | Digitalización de Órdenes y Control Interno |
| **Inversión Desarrollo** | $10,000 MXN | $25,000 MXN |
| **Tiempo de Entrega** | 1 Mes | 2 Meses |
| **Esquema de Pago** | 2 Hitos (50/50) | 3 Hitos (30/30/40) |
| **Esquema Fiscal (Facturación)** | Montos netos (RESICO a Persona Moral) | Montos netos (RESICO a Persona Moral) |
| **--- 2. PORTALES Y PRESENCIA WEB ---** | | |
| **Sitio Web Público** (`laesh.mx`) | ✅ 5 secciones (Inicio, Nosotros, Servicios, Indicaciones, Contacto) | ❌ No aplica (Es un sistema interno) |
| **Portal Médico Responsive (Celular/Tablet)** (`laesh.mx/medicos`) | ❌ | ✅ Generación de órdenes y monitoreo de pacientes referidos en tiempo real |
| **Portal de Recepción** (`laesh.mx/labadmin`) | ❌ | ✅ Recepción de pacientes, búsqueda avanzada y actualización de estatus |
| **--- 3. OPERACIÓN Y FUNCIONALIDADES CLAVE ---** | | |
| **Generación de Hoja Impresa** | ❌ | ✅ Formato institucional LAESH con `#folio` único y código de barras simple para el paciente |
| **Buscador Inteligente (Recepción)** | ❌ | ✅ Input unificado: Autocompletado (min. 5 caracteres) por nombre de paciente o folio |
| **Notificaciones en Tiempo Real (Globito)** | ❌ | ✅ Alertas en vivo para recepcionistas y médicos (Motor Node.js/Swoole) |
| **Flujo de Resultados** | ❌ | Tradicional (Impreso en ventanilla de la clínica) |
| **Módulo de Reportes y Estadísticas** | ❌ | ✅ Básicas por médico, paciente y para el laboratorio |
| **--- 4. RESPALDO, GARANTÍA Y FUTURO ---** | | |
| **Fase de Capacitación y Estabilización** | ❌ | ✅ 15 Días presencial al momento de requerirse |
| **Garantía Post-Entrega** | 15 días | 30 días |
| **Seguridad y Respaldos** | ✅ (Vía Póliza Anual de Servidor) | ✅ (Vía Póliza Anual de Servidor) |
| **Licenciamiento** | Perpetua (Sin rentas mensuales de software) | Perpetua (Sin rentas mensuales de software) |
| **--- RESUMEN FINAL ---** | | |
| **Pros (Ventajas)** | Económico y rápido de implementar. Atrae pacientes nuevos vía Google. | Elimina errores por mala letra en recetas. Profesionaliza la relación con el médico tratante. Buscador ágil en recepción que reduce tiempos de espera. Notificaciones en vivo. Sin costos recurrentes de terceros (Meta). |
| **Contras (Limitantes)** | No resuelve problemas operativos internos. | No digitaliza la entrega de resultados al paciente (se mantiene en papel). No incluye página web pública (solo los portales privados). |

---

# SECCIÓN DE ANEXOS Y CONSIDERACIONES DETALLADAS
*La siguiente sección profundiza en las normativas, riesgos, garantías y estructura legal que amparan la ejecución de cualquiera de las opciones listadas en el Resumen Ejecutivo superior.*

---

## Condiciones y Requisitos Generales (Aplicables a todos los proyectos)
*   **Modelo de Entrega y Estabilización:** Independientemente de la opción elegida, los proyectos incluyen una fase de **15 días naturales de Estabilización** (pruebas en vivo y capacitación) que corre posterior al despliegue. Por regla general, al concluir estos 15 días se firma el Acta de Aceptación, liquidando el pago final y arrancando la Garantía correspondiente.
*   **Presupuesto para Proveedores de Terceros (Infraestructura):** Al ser un ecosistema 100% en la Nube (Cloud), el sistema operará en servidores contratados a su nombre. Los costos estimados (pagos directos al proveedor mediante domiciliación bancaria) se resumen a continuación:

    | Concepto Externo (Proveedor) | Frecuencia | Inversión Estimada | Aplica para | Observaciones Operativas |
    | :--- | :---: | :--- | :---: | :--- |
    | **Hosting Básico (Hostinger)** | Anual | ~$500 MXN | Opción 1 | Plan de hosting compartido básico, suficiente para una página web estática. |
    | **Servidor en la Nube VPS (Hostinger)** | Anual | ~$1,500 a ~$2,000 MXN | Opción 2 | Plan optimizado VPS KVM 2, ideal para soportar el ecosistema web y las alertas en tiempo real. |
    | **Dominio de Internet (.mx)** | Anual | ~$600 MXN | Todas | Nombre público e institucional de su página web (Ej. `laesh.mx`). |

> **Seguridad y Privacidad de Datos:** Para tranquilidad del laboratorio y de los pacientes, el sistema usa protocolos de seguridad modernos: toda la información viaja encriptada por internet (candado verde HTTPS), y las contraseñas se guardan cifradas. El servidor provisto por Hostinger cuenta con protecciones mundiales.
>
> **Propiedad de Datos e Historial Clínico (5 años):** "EL CLIENTE" será siempre el dueño absoluto y exclusivo de toda su información procesada. La base de datos está diseñada para retener el historial operativo del laboratorio hasta por **5 años**.
>
> **Licenciamiento Tecnológico:** La clínica adquiere una **licencia de uso perpetua**; es decir, jamás pagará "rentas" por el derecho de usar el software.

### Funcionalidades Fuera de Alcance
A fin de mantener un ecosistema eficiente y sin ambigüedades, queda expresamente fuera de todas las opciones planteadas el desarrollo de:

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
| **1. Soporte a Producción (Mantenimiento)** | $8,000 MXN | Bolsa de 12 horas mensuales para cambios o resolución rápida de incidentes. | Todas |
| **2. Administración de Servidor / Hosting** | $4,000 MXN | Mano de obra técnica (Respaldos automáticos, parches de seguridad de la nube). | Opción 2 |

---

## Riesgos y Mitigaciones Operativas

| Riesgo Identificado | Impacto Potencial | Estrategia de Mitigación |
| :--- | :--- | :--- |
| **Caídas de Infraestructura de Terceros** | Interrupciones por mantenimiento o caídas globales del proveedor de hosting (Hostinger). | Contratación de la *Póliza de Administración de Servidor* para copias de seguridad continuas y reactivación ágil (SLA de 2 horas). |
| **Fallas en Impresión de Hojas** | El paciente podría llegar sin hoja impresa si la impresora del médico tratante falla. | El buscador unificado en recepción con autocompletado por nombre mitiga este impacto, permitiendo localizar al paciente rápidamente. |

---

## Consideraciones Fiscales y Administrativas
*   **Aceptación y Liberación de Pagos:** El cobro del 100% del proyecto se rige por la firma del **Acta de Aceptación de Proyecto Tecnológico**.
*   **Montos Libres:** Todas las cantidades listadas en esta propuesta son **montos netos (libres de impuestos)** a favor del Prestador.
*   **Cálculo Inverso:** (RESICO) El Cliente (Persona Moral) es responsable de realizar el cálculo a la inversa (de neto a bruto) al momento de la facturación.

---

## Estructura Documental
Para garantizar total transparencia técnica y comercial, este proyecto se rige por un conjunto de documentos modulares complementarios.

| Archivo Legal / Técnico | Abstracto del Contenido |
| :--- | :--- |
| **1. Carta_Presentacion.md** | Carta ejecutiva de introducción al proyecto, contexto de la oferta y próximos pasos. |
| **2. Resumen_Oferta_Servicios.md** | Documento rector (el actual) que compara opciones, costos, infraestructura y responsabilidades. |
| **3. Contrato_Base_Desarrollo.md** | Marco legal que establece hitos de pago, confidencialidad y límites de responsabilidad. |
| **4. Anexo_A_Sitio_Web.md** | Especificación técnica para la Opción 1. |
| **5. Anexo_A_Bloc_Digital.md** | Especificación técnica exclusiva para la Opción 2 (Reglas del portal médico, buscadores y notificaciones). |
| **6. Contrato_Administracion_Servidor.md** | Póliza (opcional) para respaldos automáticos y monitoreo de la nube. |
| **7. Anexo_B_Soporte_Produccion.md** | Póliza (opcional) de mantenimiento y corrección de bugs post-garantía. |
