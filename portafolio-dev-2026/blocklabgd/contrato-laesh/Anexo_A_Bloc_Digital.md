# ANEXO A — ALCANCE DEL PROYECTO
## Proyecto: Bloc Digital de Solicitudes de Análisis Clínicos

Este anexo forma parte integrante del Contrato de Prestación de Servicios Profesionales celebrado entre "EL PRESTADOR" y "EL CLIENTE".

**1. Descripción general del sistema**
"EL SISTEMA" consiste en un bloc digital de solicitudes de análisis clínicos: una aplicación web que sustituye el formato en papel utilizado por el personal médico y de laboratorio para generar, capturar, consultar y dar seguimiento a solicitudes de estudios clínicos, conforme al flujo de trabajo de "EL CLIENTE".

**2. Fases incluidas**
1. Análisis de requerimientos y del flujo de trabajo actual (levantamiento con el personal médico/laboratorio).
2. Diseño de la solución (experiencia de usuario, interfaz y modelo de base de datos).
3. Desarrollo del sistema conforme a los módulos y funcionalidades descritos en la sección 3.
4. Pruebas (funcionales y de aceptación) previas a la puesta en producción.
5. Despliegue en el entorno de producción de "EL CLIENTE" (el servidor debe ser proveído por "EL CLIENTE" o administrado mediante el Contrato Independiente de Servicios Recurrentes).
6. Estabilización, conforme a la Cláusula Séptima Bis (**Fase 1 de la Garantía: primeros 30 días**). *(Nota: Durante esta fase se elaborará y entregará formalmente la documentación técnica y el manual de usuario del sistema).*
7. Garantía total de **45 días naturales (1 mes y medio)**, conforme a la Cláusula Séptima. *(Nota: Como parte de la entrega y estabilización, se incluye la capacitación al personal operativo y el acompañamiento en el despliegue a producción en sitio).*

**3. Módulos y funcionalidades incluidas**
*   **Módulo de Captura:** Captura digital de solicitud de análisis clínicos por parte del personal autorizado.
*   **Módulo de Catálogo:** Catálogo administrable de estudios/análisis clínicos disponibles.
*   **Módulo de Consulta:** Consulta, búsqueda y seguimiento de estatus de solicitudes.
*   **Módulo de Exportación:** Generación de solicitud en formato PDF optimizado para impresión o envío.
*   **Módulo de Seguridad:** Gestión de usuarios, roles (médico, laboratorio, administrador) y permisos de acceso.
*(Nota: Alcance funcional detallado pendiente por definir).*

**4. Integración WhatsApp Cloud API y Control Presupuestal**
El sistema incluirá un módulo especializado para la notificación automática a los pacientes vía WhatsApp ("Mensajes de Utilidad"), con las siguientes características y controles desarrollados por "EL PRESTADOR":
*   **Garantía de Control Presupuestal (Stopper):** Dado que Meta no ofrece bloqueos nativos, el sistema fijará un límite máximo de **$6,000.00 MXN mensuales** de consumo.
*   **Alertas Tempranas:** Envío automático de correos a "EL CLIENTE" al alcanzar el 70% ($4,200 MXN) y el 90% ($5,400 MXN) del presupuesto mensual.
*   **Bloqueo Automático:** Al llegar al límite, la aplicación congelará las peticiones de salida a WhatsApp para evitar sobrecostos, reactivando el servicio el primer día del siguiente mes o por ampliación presupuestal.
*   **Contingencia en Interfaz Médica:** Al activarse el bloqueo, se mostrará al médico el aviso *"Canal de WhatsApp fuera de servicio temporalmente por límite mensual"*. El botón de envío se deshabilitará y la aplicación forzará el guardado e impresión física (PDF) para garantizar la continuidad del laboratorio.

**5. Fuera de alcance**
Quedan excluidas de este proyecto las siguientes funcionalidades para evitar ambigüedad:
*   Integración automatizada con equipos físicos de laboratorio (LIS/HIS).
*   Facturación electrónica.
*   Captura y entrega de resultados de laboratorio (el sistema se limita a la solicitud/orden de estudio).
*   Aplicación móvil nativa (iOS/Android).
*   Desarrollo de página web institucional/landing page (cubierto en contrato separado).

**6. Tecnología y entorno**
*   **Stack Tecnológico:** PHP, MySQL, HTML/JS/CSS, frameworks PHP MVC, API WhatsApp Cloud, Linux Ubuntu 24.x, Workers, Webhooks, etc.
*   **Infraestructura:** La aplicación requiere un servidor VPS/Hosting que cumpla con los requisitos del plan **KVM 4 de Hostinger (mínimo 4 vCPU, 16 GB de RAM y 200 GB de almacenamiento NVMe)**. *El costo de renta de dicho servidor no forma parte de este anexo y es responsabilidad directa de "EL CLIENTE" con su proveedor de hosting (ej. Hostinger).*

**7. Calendario de entregas**
El sistema tendrá un plazo máximo de desarrollo y entrega de **tres (3) meses (90 días naturales)** contados a partir de la fecha de inicio del proyecto. La entrega final en producción marcará el inicio simultáneo del Periodo de Garantía para este proyecto y para el Sitio Web.
*   **Hito 1 — Análisis y diseño:** Durante el primer mes
*   **Hito 2 — Desarrollo:** Durante el segundo mes
*   **Hito 3 — Pruebas y despliegue (Inicio de Fase 1: Estabilización de 30 días):** Al término del tercer mes (Día 90 máximo)
*   **Fin del Periodo de Garantía Total (45 días naturales tras entrega):** Día de liberación para facturar el último pago.

**8. Precio, Desglose de Pagos y Facturación**
El precio total de este proyecto es de **$65,000.00 MXN (Netos)**, pagadero conforme al siguiente esquema de hitos:

| Hito de Pago | Porcentaje | Monto a Facturar | Condición de Cobro |
| :--- | :--- | :--- | :--- |
| **Pago 1: Anticipo** | 30% | $19,500.00 MXN (Netos) | A la firma del presente contrato / anexo, previo al inicio del desarrollo. |
| **Pago 2: Avance Intermedio** | 30% | $19,500.00 MXN (Netos) | Una vez superadas las pruebas de aceptación y después del despliegue a producción. |
| **Pago 3: Pago Final** | 40% | $26,000.00 MXN (Netos) | Al concluir satisfactoriamente el periodo de Garantía Total (45 días tras la entrega en producción). |
| **TOTAL** | **100%** | **$65,000.00 MXN (Netos)** | |

**9. Criterios de aceptación**
*   La aplicación permite crear y guardar una solicitud y exportarla a PDF sin errores.
*   La aplicación es accesible vía web con credenciales seguras.
*   Los tiempos de respuesta de la interfaz son aceptables y se visualiza correctamente en pantallas de escritorio y tablets estándar.

_______________________________
**FIRMA DE CONFORMIDAD - EL CLIENTE**
