# RESUMEN DE LA OFERTA DE SERVICIOS
**Proyecto:** Laboratorio Clínico LAESH - Digitalización

Este documento presenta dos propuestas tecnológicas independientes y **100% complementarias**. Las soluciones están diseñadas para ejecutarse de manera individual o combinada de forma coordinada: mientras el **Proyecto 1** establece la presencia web pública profesional para la captación de nuevos pacientes, el **Proyecto 2** automatiza la emisión digital de órdenes de laboratorio y el control operativo interno entre médicos tratantes y recepción. "EL CLIENTE" puede contratar cualquiera de los dos proyectos según su prioridad inmediata o combinarlos para obtener un ecosistema tecnológico completo.

*(Nota: Toda propuesta se instrumenta bajo un **Contrato Base Modular** — ver sección **Estructura Documental**).* 

---

### Proyecto 1: Sitio Web (Básico)

*   **Inversión Total:** $10,000.00 MXN
*   **Esquema de Pago (2 Hitos):** 50% Anticipo ($5,000) / 50% Firma de Aceptación ($5,000).
*   **Tiempo de Entrega:** 1 Mes (30 días naturales).
*   **Garantía:** 10 días naturales (Inicia a partir de la firma de Aceptación).
*   **Alcance Funcional:** Página web sencilla (5 secciones). Incluye Inicio, Nosotros (Cédulas), Catálogo de Estudios y Precios, Contacto (con enlace a Google Maps y botón directo a WhatsApp), y Aviso de Privacidad. Es la solución ideal para tener una presencia profesional en internet. *(Incluye periodo de Estabilización de 10 días y capacitación; ver Condiciones Generales).*
*   **Alcance Tecnológico:** Incluye optimización básica para posicionamiento en buscadores (Google) y adaptabilidad para celulares y tablets.

---

### Proyecto 2: Bloc Digital via Internet

*   **Inversión Total:** $25,000.00 MXN
*   **Esquema de Pago (2 Hitos):** 40% Anticipo ($10,000) / 60% Firma de Aceptación ($15,000).
*   **Tiempo de Entrega:** 2 Meses (60 días naturales). *(Nota: Si se contratan ambos proyectos en conjunto, el tiempo máximo de entrega para la solución integral será de hasta 2.5 meses).*
*   **Garantía:** 20 días naturales (Inicia a partir de la firma de Aceptación).
*   **Alcance Funcional:** Automatización para crear y rastrear las solicitudes de estudio de laboratorio en un ecosistema web 100% privado:
    1. **Generación de Orden Digital (`Remitido`):** El médico tratante crea la solicitud digital desde su portal (`laesh.mx/medicos`). El sistema genera una **hoja impresa (formato LAESH)** con un `#folio` único y código de barras simple. Esta orden digital queda asociada al expediente del paciente y **disponible de forma inmediata para su descarga en PDF desde el portal de recepción (`laesh.mx/labadmin`)**. Al crearse la orden digital, **se dispara automáticamente una notificación instantánea (globito contador con pitido de sonido silbato exclusivo y panel de detalles) al portal de recepción; al abrir el detalle de la notificación, la recepcionista cuenta con un enlace directo al registro del paciente** para consultar o re-imprimir el PDF si el paciente acude sin él.
    2. **Recepción del Paciente (`En Atención`):** El paciente acude a la clínica con su hoja (o dictando su nombre). La recepcionista lo localiza mediante la notificación o usando un **buscador unificado e inteligente** (autocompletado a partir de 5 caracteres por folio o nombre en una misma barra de búsqueda) y cambia el estado a **En Atención**.
    3. **Carga de Resultados y Notificación al Médico (`Resultados Listos`):** Cuando el examen clínico se realiza en LAESH, el personal sube el PDF de resultados mediante un botón/modal de **Carga Manual (Subida de PDF)** en `laesh.mx/labadmin`. Al subir el archivo, el sistema **actualiza automáticamente el estado a `Resultados Listos`** y dispara de forma inmediata una **notificación instantánea (globito contador silencioso y panel de detalles) al portal del médico (`laesh.mx/medicos`)**. En el mensaje de la notificación **se incluye un enlace directo para descargar el PDF de resultados**.
    4. **Cierre de Solicitud (`Cerrada`):** El paciente recibe sus resultados impresos en ventanilla de forma tradicional, marcándose la orden digital como **Cerrada** (o cerrándose automáticamente tras 30 días sin presentarse).
*   **Consideración Operativa:** Los resultados de laboratorio se entregan al paciente de forma **tradicional (en papel por ventanilla)**. El ecosistema es 100% web y privado, sin depender de redes sociales (WhatsApp) ni generar costos recurrentes de comunicación.
*   **Alcance Tecnológico:** Sistema web en la nube, perfiles de usuario, roles de seguridad (Recepción, Médico, Administrador), módulo de carga manual de resultados (Subida de PDF), buscador unificado por autocompletado y notificaciones instantáneas bidireccionales (con sonido de silbato exclusivo para la recepción) con enlaces directos a expedientes y descargas de PDF utilizando tecnología open-source de **Node.js/Swoole (WebSockets)**.

---
<br>

## <font size="+3">Cuadro Comparativo (Inversión vs. Valor Funcional)</font>
Para facilitar la toma de decisiones, la siguiente tabla resume las funcionalidades de ambas propuestas tecnológicas ofertadas (las cuales pueden contratarse de forma independiente o como soluciones complementarias), permitiendo visualizar rápidamente su costo-beneficio.

| # | Característica | Proyecto 1: Sitio Web | Proyecto 2: Bloc Digital via Internet | Actores (Proyecto 2) |
| :---: | :--- | :--- | :--- | :--- |
| | **--- 1. CONDICIONES COMERCIALES ---** | | | |
| | **Objetivo Principal** | Presencia pública profesional en internet (5 secciones) diseñada para captar nuevos pacientes en búsquedas de Google. *(Enfocado en presencia externa; el control operativo interno es competencia del Proyecto 2).* | Emisión digital de solicitudes de laboratorio y control operativo interno. Elimina errores por mala letra en recetas, notificaciones instantáneas a recepción (con sonido silbato y enlace a expediente) y al médico (con enlace a PDF). Roles incluidos: Médico, Recepcionista y Administrador (gestión de usuarios y catálogo de estudios). *(Sin costos de WhatsApp API; la entrega de la solicitud digitalizada y resultados (en ventanilla) al paciente se mantiene en papel).* | Médico, Recepcionista, Paciente, Administrador, Sistema Bloc Digital |
| | **Inversión Desarrollo** | $10,000 MXN | $25,000 MXN | N/A |
| | **Tiempo de Entrega** | 1 Mes | 2 Meses.<br>*(Nota: Si eligen ambos proyectos el tiempo máximo de entrega para la solución conjunta será de hasta 2.5 meses).* | N/A |
| | **Esquema de Pago** | 2 Hitos (50% Anticipo / 50% Aceptación) | 2 Hitos (40% Anticipo / 60% Aceptación) | N/A |
| | **Esquema Fiscal (Facturación)** | Montos netos (RESICO a Persona Moral). *(El cálculo de neto a bruto corresponde al Cliente Persona Moral)* | Montos netos (RESICO a Persona Moral). *(El cálculo de neto a bruto corresponde al Cliente Persona Moral)* | N/A |
| | **--- 2. PORTALES Y PRESENCIA WEB ---** | | | |
| 1 | **Sitio Web Público** (`laesh.mx`) | ✅ 5 secciones (Inicio, Nosotros, Servicios, Indicaciones, Contacto).<br>*Se le presentarán 2 opciones de diseño visual para su sitio y la que elijan quedará implementada.* | El dominio `laesh.mx` es compartido entre ambos proyectos: aloja el sitio público (Proyecto 1) y los portales privados de médicos (`laesh.mx/medicos`) y recepción (`laesh.mx/labadmin`) del Proyecto 2. | LAESH, Público en general |
| 2 | **Portal Médico Adaptable (Celular/Tablet)** (`laesh.mx/medicos`) | No aplica | ✅ Generación de órdenes digitales *(El médico entrega impresa la orden digital al paciente)*, notificaciones instantáneas y descarga directa de PDF de resultados | Médico, Paciente |
| 3 | **Portal de Recepción** (`laesh.mx/labadmin`) | No aplica | ✅ Notificaciones instantáneas (con pitido de sonido silbato) con enlace a expediente, búsqueda avanzada, gestión de estados y carga de PDF de resultados | Recepcionista, Paciente (indirecto) |
| | **--- 3. OPERACIÓN Y FUNCIONALIDADES CLAVE ---** | | | |
| 4 | **Generación de Hoja Impresa y Descarga PDF** | No aplica | ✅ Formato LAESH con `#folio` único y código de barras. Descargable en PDF por recepción | Médico, Recepcionista, Paciente, Sistema Bloc Digital |
| 5 | **Buscador Inteligente (Recepción)** | No aplica | ✅ Campo unificado: Autocompletado (min. 5 caracteres) por nombre de paciente o por `#folio` exacto | Recepcionista |
| 6 | **Estados de la orden digital (<span style="background-color: #EBF8FF; color: #2B6CB0; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 0.85em;">Remitido</span> ➔ <span style="background-color: #FEEBC8; color: #C05621; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 0.85em;">En Atención</span> ➔ <span style="background-color: #C6F6D5; color: #22543D; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 0.85em;">Resultados Listos</span> ➔ <span style="background-color: #EDF2F7; color: #4A5568; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 0.85em;">Cerrada</span>)** | No aplica | ✅ Control de flujo operativo y actualización automática de estado al cargar resultados | Sistema Bloc Digital, Recepcionista |
| 7 | **Carga Manual de Resultados (Subida de PDF)** | No aplica | ✅ Módulo para subir el PDF de resultados, cambiando automáticamente el estado a *Resultados Listos* | Recepcionista |
| 8 | **🔔 Notificación Instantánea a Recepción (con Audio y Enlace Directo)** | No aplica | ✅ Globito contador con pitido de sonido silbato en `labadmin` al crearse una orden digital, con enlace directo al expediente del paciente | Sistema Bloc Digital, Recepcionista |
| 9 | **🔕 Notificación Instantánea al Médico (Silenciosa y con Enlace Directo)** | No aplica | ✅ Globito contador (silencioso) en `medicos` al estar listos los resultados, con enlace directo para descargar el PDF de resultados | Sistema Bloc Digital, Médico |
| 10 | **Flujo de Entrega al Paciente** | No aplica | ✅ Diseñado así: entrega física de resultados en ventanilla (sin WhatsApp ni app). El paciente los recibe directamente en mano. | Paciente, Recepcionista |
| 11 | **Módulo de Reportes y Estadísticas** | No aplica | ✅ Conteos de pacientes por estado de la orden digital (Remitido, En Atención, Resultados Listos, Cerrada), consultables por día, semana, mes y año (hasta 5 años de historial). *No incluye cálculos financieros ni gestión de honorarios.* | Recepcionista, Médico |
| | **--- 4. GARANTÍA, SOPORTE, RENTA SERVIDOR, DOMINIO ---** | | | |
| 12 | **Fase de Capacitación y Estabilización** | ✅ 10 Días (capacitación en administración de contenidos del sitio; principalmente remota) | ✅ 10 Días presencial al momento de requerirse | Médico, Recepcionista |
| 13 | **Garantía Post-Entrega** | 10 días | 20 días | LAESH (contratante) |
| 14 | **Seguridad y Respaldos** | ✅ Certificado SSL/HTTPS básico del hosting estático | ✅ SSL/HTTPS y Respaldos Automáticos continuos (gestionados vía Póliza de Servidor Mantenimiento, sugerida Año 1 / opcional post-garantía) | LAESH / Administrador |
| 15 | **Licenciamiento** | ✅ **Pago único por desarrollo — sin rentas mensuales.** Licencia de uso perpetua; sin suscripciones obligatorias ni cuotas por usuario o uso de software. | ✅ **Pago único por desarrollo — sin rentas mensuales.** Licencia de uso perpetua; sin suscripciones obligatorias ni cuotas por usuario o uso de software. | LAESH (contratante) |
| 16 | **Inversiones Externas (Infraestructura)** | Hosting Básico Hostinger (~$500 MXN/año) + Dominio .mx (~$600 MXN/año)<br><strong>Suma aprox: ~$1,100 MXN/año</strong> | Servidor VPS KVM 2 Hostinger (~$1,500 a $2,000 MXN/año) + Dominio .mx / DNS (~$600 MXN/año)<br><strong>Suma aprox: ~$2,100 a $2,600 MXN/año</strong>.<br>*(Nota: El Dominio .mx ($600 MXN/año) es único y compartido entre ambos proyectos. Si contrata ambos proyectos, el VPS KVM 2 aloja y cubre ambos sistemas, eliminando la necesidad del Hosting Básico de $500 MXN/año)* | LAESH (contratante) |
| 17 | **Servicios Anuales de Póliza (Sugeridos Año 1)** | Póliza de Soporte a Producción (Aplicación Web): $4,000 MXN/año (sugerida Año 1 / opcional post-garantía).<br>*(La gestión y ajuste de campañas Google Ads post-entrega no está incluida; se atiende por evento bajo demanda.)*<br><strong>Total: $4,000 MXN/año</strong> | 1) Póliza de Soporte a Producción (Aplicación Web): $4,000 MXN/año<br>2) Póliza de Servidor Mantenimiento: $4,000 MXN/año<br><strong>Total Pólizas Sugeridas: $8,000 MXN/año</strong> (sugeridas Año 1 / opcionales post-garantía).<br>*(Nota: Si se contratan ambos proyectos, las pólizas del Proyecto 2 por $8,000 MXN/año cubren de forma integral ambas aplicaciones, evitando pagar $12,000 MXN/año)* | LAESH (contratante) |
| 18 | **Presupuesto de Anuncios en Buscador (Google Ads)** *(cargo directo con Google)* | ✅ Incluido en desarrollo: configuración inicial de 1 campaña de búsqueda + capacitación para gestionar el panel (pausar, activar o cancelar). El costo de cada clic lo cobra Google directamente al titular de la cuenta (tarjeta del cliente).<br>*Costo sugerido para iniciar: **$500 a $1,500 MXN/mes** (~$17 a $50 MXN/día). Cada vez que alguien busca "laboratorio clínico" en Google y hace clic en su anuncio, se descuenta ese monto. Usted controla el límite de gasto diario y puede pausar o cancelar en cualquier momento desde el panel.*<br>*(Gestión y optimización de campañas post-entrega: por evento bajo demanda, no incluida en póliza).* | No aplica | LAESH (contratante directo a Google) |

---

# SECCIÓN DE ANEXOS Y CONSIDERACIONES DETALLADAS
*La siguiente sección profundiza en las normativas, riesgos, garantías y estructura legal que amparan la ejecución de cualquiera de las propuestas listadas en el Resumen Ejecutivo superior.*

---

## Condiciones y Requisitos Generales (Aplicables a todos los proyectos)
*   **Modelo de Entrega y Estabilización:** Independientemente del proyecto elegido, se incluye una fase de **10 días naturales de Estabilización** (pruebas en vivo y capacitación) posterior al despliegue. Al concluir estos 10 días se firma el Acta de Aceptación, liquidando el hito final de pago y arrancando la Garantía correspondiente.
*   **Presupuesto para Proveedores de Terceros (Infraestructura de Servidor y Dominio DNS):** Al ser un ecosistema 100% en la Nube (Cloud), el sistema operará en servidores contratados a nombre de "EL CLIENTE", garantizándole total independencia. **Como parte de esta oferta de servicios, mi función es apoyarle como guía consultor paso a paso para realizar estas compras con los proveedores correspondientes.** Es obligación de "EL CLIENTE" garantizar una conexión a internet estable en sus instalaciones. Los costos estimados de infraestructura (pagos directos al proveedor mediante domiciliación bancaria) se resumen a continuación:

    | Concepto Externo (Proveedor) | Frecuencia | Inversión Estimada | Aplica para | Observaciones Operativas |
    | :--- | :---: | :--- | :---: | :--- |
    | **Hosting Básico (Hostinger)** | Anual | ~$500 MXN | Proyecto 1 | Plan de hosting compartido básico, suficiente para una página web estática. |
    | **Servidor en la Nube VPS (Hostinger)** | Anual | ~$1,500 a ~$2,000 MXN | Proyecto 2 | Plan optimizado VPS KVM 2, ideal para soportar el ecosistema web y las notificaciones instantáneas. *(Nota: Si se contratan ambos proyectos, este servidor aloja ambos sistemas, omitiendo el Hosting Básico).* |
    | **Dominio de Internet (.mx) / Registros DNS** | Anual | ~$600 MXN | Todos | Nombre público e institucional de su página web y configuración de registros DNS en Hostinger (Ej. `laesh.mx`). |

> **Seguridad y Privacidad de Datos:** El sistema usa protocolos de seguridad modernos: toda la información viaja encriptada por internet (candado verde HTTPS), y las contraseñas se guardan cifradas.
>
> **Propiedad de Datos e Historial Clínico (5 años):** "EL CLIENTE" será siempre el dueño absoluto y exclusivo de toda su información procesada (pacientes, resultados, logotipos). Para brindar máxima tranquilidad y cumplir con estándares de salud, la base de datos está diseñada para retener el historial operativo del laboratorio hasta por **5 años**.
>
> **Licenciamiento Tecnológico:** La clínica adquiere una **licencia de uso perpetua**; es decir, jamás pagará "rentas" por el derecho de usar el software.

---

## Servicios Post-Salida (Las 2 Pólizas Anuales Sugeridas para el Año 1 / Opcionales Post-Garantía)
Una vez concluidos los periodos de garantía gratuitos de cualquiera de las opciones anteriores (10 días para Proyecto 1 y 20 días para Proyecto 2), se sugieren las siguientes **dos pólizas anuales de servicio** para asegurar que el sistema opere continuamente en óptimas condiciones:

| Póliza Anual Sugerida | Inversión Anual | Cobertura Principal | Aplica para | Carácter Operativo |
| :--- | :--- | :--- | :---: | :--- |
| **1. Póliza de Soporte a Producción (Aplicación Web)** | $4,000 MXN | Bolsa de 12 horas mensuales para soporte técnico, ajustes menores, actualización de contenidos y resolución prioritaria de incidentes. *No incluye gestión, ajuste de pujas ni optimización de campañas Google Ads; dicho servicio se cotiza por evento.* | Todos | **Sugerida Año 1** (Opcional por evento post-garantía) |
| **2. Póliza de Servidor Mantenimiento** | $4,000 MXN | Mano de obra técnica especializada: respaldos automáticos continuos (backups), renovación de certificados SSL/HTTPS, monitoreo 24/7 y parches de seguridad en la nube Hostinger. *(El alquiler del hardware se paga directo a Hostinger)*. | Proyecto 2 | **Sugerida Año 1** (Opcional por evento post-garantía) |

> **Flexibilidad y Ahorro por Contratación Conjunta:** Ambas pólizas son **sugeridas durante el Año 1** para brindar total tranquilidad técnica al laboratorio. Si se contratan ambos proyectos de forma combinada, el costo total por las dos pólizas es de **$8,000 MXN / año** (absorbiendo de forma integral el soporte y mantenimiento de ambos proyectos, evitando pagar $12,000 MXN por separado). Al concluir el Año 1, "EL CLIENTE" podrá decidir libremente si desea renovarlas, cambiarlas a un esquema mensual o contratarlas bajo demanda ("por evento").

---

## Riesgos y Mitigaciones Operativas

| Riesgo Identificado | Impacto Potencial | Estrategia de Mitigación |
| :--- | :--- | :--- |
| **Caídas de Infraestructura de Terceros** | Interrupciones por mantenimiento o caídas globales del proveedor de hosting (Hostinger). | Contratación de la *Póliza de Servidor Mantenimiento* para copias de seguridad continuas y reactivación ágil (SLA de 2 horas). |
| **Fallas en Impresión de Hojas** | El paciente podría llegar sin hoja impresa si la impresora del médico tratante falla. | La recepcionista recibe una notificación instantánea con sonido de silbato y enlace directo al expediente del paciente en `labadmin`, desde donde puede descargar/imprimir directamente el PDF de la orden digital. |

---

## Consideraciones Fiscales y Administrativas
*   **Aceptación y Liberación de Pagos:** El cobro del 100% del proyecto se rige por el esquema de 2 hitos (Proyecto 1: 50/50, Proyecto 2: 40/60).
*   **Montos Libres:** Todas las cantidades listadas en esta propuesta son **montos netos (libres de impuestos)** a favor del Prestador.
*   **Cálculo Inverso:** (RESICO) El Cliente (Persona Moral) es responsable de realizar el cálculo a la inversa (de neto a bruto) al momento de la facturación.
