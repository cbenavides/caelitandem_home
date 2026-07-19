# ANEXO A — ALCANCE DEL PROYECTO
## Proyecto: Bloc Digital de Solicitudes de Análisis Clínicos

Este anexo forma parte integrante del Contrato de Prestación de Servicios Profesionales celebrado entre "EL PRESTADOR" y "EL CLIENTE".

**1. Descripción general del sistema**
"EL SISTEMA" es una aplicación web que sustituye las libretas y recetas de papel usadas por los médicos y el laboratorio. Permite crear, consultar y dar seguimiento a las órdenes de estudios de manera 100% digital.

**2. Fases incluidas**
1. Análisis de requerimientos y del flujo de trabajo actual (levantamiento con el personal médico/laboratorio).
2. Diseño de la solución (experiencia de usuario, interfaz y modelo de base de datos).
3. Desarrollo del sistema conforme a los módulos y funcionalidades descritos en la sección 3.
4. Pruebas (funcionales y de aceptación) previas a la puesta en producción.
5. Despliegue en el entorno de producción de "EL CLIENTE" (el servidor debe ser proveído por "EL CLIENTE" o administrado mediante el Contrato Independiente de Servicios Recurrentes).
6. **Periodo de Estabilización de 15 días naturales** (Fase de pruebas en vivo y correcciones iniciales). *(Nota: Durante esta fase se elaborará y entregará formalmente la documentación técnica y el manual de usuario del sistema).*
7. **Firma del Acta de Aceptación** (Hito formal que detona el pago final).
8. **Periodo de Garantía Total de 30 días naturales**, el cual arranca exclusivamente tras la firma del Acta de Aceptación y la liquidación del pago final. *(Nota: Durante la estabilización previa, se incluye la capacitación al personal y el acompañamiento en sitio).*

**3. Módulos y funcionalidades incluidas**
*   **Módulo de Captura:** Captura digital de solicitud de análisis clínicos por parte del personal autorizado.
*   **Módulo de Catálogo:** Catálogo administrable de estudios/análisis clínicos disponibles.
*   **Módulo de Consulta:** Consulta, búsqueda y seguimiento de estatus de solicitudes.
*   **Módulo de Exportación:** Generación de solicitud en formato PDF optimizado para impresión o envío.
*   **Módulo de Reportes:** Generación de estadísticas operativas e indicadores clave del laboratorio.
*   **Módulo de Seguridad:** Gestión de usuarios, roles (médico, laboratorio, administrador) y permisos de acceso.

**3.1. Tabla de Alcance Funcional Exacto**
A continuación se detalla el comportamiento del sistema para evitar ambigüedades técnicas:

| Módulo del Sistema | Descripción de la Funcionalidad (Alcance Exacto) |
| :--- | :--- |
| **Catálogo de Estudios** | Administración para agregar o editar estudios médicos y precios. Incluye una carga masiva inicial por parte de "EL PRESTADOR" mediante un archivo Excel provisto por "EL CLIENTE". |
| **Portal Médico (Captura)** | Pantalla para que el doctor cree una solicitud médica (Nombre, teléfono, estudios). |
| **Notificación Inmediata** | Al guardar la orden, el sistema le envía inmediatamente la solicitud en imagen al WhatsApp del paciente. |
| **Portal de Seguimiento** | Pantalla segura donde el doctor consulta si los pacientes que mandó al laboratorio ya fueron atendidos. |
| **Portal Interno (Clínica)** | Pantalla para la recepcionista. Muestra notificaciones de nuevas solicitudes, permite buscar pacientes y marcar su estatus como "En Atención" cuando el paciente llega a pagar. |
| **Módulo de Reportes** | Pantalla con estadísticas básicas (ej. cantidad de solicitudes creadas por doctor). *No incluye cálculos financieros, comisiones ni gestión de honorarios.* |
| **Caducidad Automática** | Regla de negocio en el servidor que cierra/caduca automáticamente las solicitudes médicas si el paciente no acude a la clínica en un plazo de 30 días (configurable). |
| **Compatibilidad de Dispositivos** | El **Portal Médico** cuenta con adaptabilidad para celulares, tablets y computadoras. El resto de portales (incluyendo la Recepción Clínica) están diseñados para computadoras de escritorio (Windows 10/11 o macOS) usando Google Chrome o Apple Safari. |

**4. Integración con Plataforma Oficial WhatsApp y Control Presupuestal**
El sistema incluirá un módulo especializado para la notificación automática a los pacientes vía WhatsApp ("Mensajes de Utilidad"), con las siguientes características y controles desarrollados por "EL PRESTADOR":
*   **Garantía de Control Presupuestal (Stopper):** Dado que Meta no ofrece bloqueos nativos, el sistema fijará un límite máximo de **$6,000.00 MXN mensuales** de consumo.
*   **Alertas Tempranas:** Envío automático de correos a "EL CLIENTE" al alcanzar el 90% ($5,400 MXN) del presupuesto mensual.
*   **Bloqueo Automático:** Al llegar al límite, la aplicación congelará las peticiones de salida a WhatsApp para evitar sobrecostos, reactivando el servicio el primer día del siguiente mes o por ampliación presupuestal.
*   **Contingencia en Interfaz Médica:** Al activarse el bloqueo, se mostrará al médico el aviso *"Canal de WhatsApp fuera de servicio temporalmente por límite mensual"*. El botón de envío se deshabilitará y la aplicación forzará el guardado e impresión física (PDF) para garantizar la continuidad del laboratorio.
*   **Reglas de Interacción y Continuidad:** El envío automatizado se limita al **envío de la solicitud médica digital** al paciente. Chatwoot gestionará única y exclusivamente esta NUEVA línea, donde convivirán el bot automatizado y la recepcionista humana atendiendo este canal. **Los números actuales de la clínica NO se conectan al sistema**; el personal los operará de forma paralela y separada mediante su WhatsApp Web tradicional (requiriendo operar a dos pestañas en su navegador: Chatwoot + WhatsApp Web).
*   **Requisito de Verificación (Landing Page):** Dado que Meta exige tener un sitio web público para verificar empresas, en caso de que "EL CLIENTE" no disponga de uno, se le instalará temporalmente una página de aterrizaje (Landing Page) básica con sus datos de contacto sin costo extra, exclusivamente para cumplir el trámite.

**5. Fuera de alcance**
Quedan excluidas de este proyecto las siguientes funcionalidades para evitar ambigüedad:
*   Captura y entrega de resultados de laboratorio (el sistema se limita a la solicitud/orden de estudio).
*   Chatbots o respuestas automatizadas a las preguntas de los pacientes en WhatsApp.
*   Punto de venta, pasarelas de pago, control de caja o facturación (CFDI).
*   **Gestión financiera de referidores:** Cálculo de honorarios, comisiones, bonos o "monederos" para pagarle a los médicos por los pacientes referidos.
*   **Aspectos Legales (INAI) y Buzones Email:** Queda excluida la creación de cuentas de correo corporativo para empleados y la asesoría/redacción jurídica del Aviso de Privacidad para el envío de datos de salud por WhatsApp (responsabilidad de la clínica).
*   Aplicación móvil nativa (iOS/Android).
*   Desarrollo de página web institucional o de presentación (cubierto en contrato separado).

**6. Tecnología y entorno**
*   **Stack Tecnológico:** PHP, MySQL, HTML/JS/CSS, frameworks PHP MVC, Plataforma de WhatsApp, Linux Ubuntu 24.x, Tareas programadas en servidor, etc.
*   **Infraestructura:** La aplicación requiere un servidor en la nube que cumpla con los requisitos del plan **KVM 4 de Hostinger (mínimo 4 vCPU, 16 GB de RAM y 200 GB de almacenamiento NVMe)** y un **NUEVO Número Telefónico Dedicado Móvil (Chip SIM)** para la API de WhatsApp. Al operar en la Nube, "EL CLIENTE" debe garantizar una conexión a internet estable en sus instalaciones. *El costo de renta de los servicios externos es responsabilidad directa de "EL CLIENTE" con sus proveedores.* Adicionalmente, por normativas de privacidad de datos, el cliente asumirá la **Titularidad y Verificación Empresarial ante Meta** (aportando su Constancia de Situación Fiscal y Comprobante de Domicilio) garantizando así que la clínica es la dueña legal de la línea oficial.

**7. Calendario de entregas**
El sistema tendrá un plazo máximo de desarrollo y entrega de **[PLAZO_DE_ENTREGA]** contados a partir de la firma del presente anexo.
*   **Hito 1 — Análisis y diseño:** [MES_O_SEMANA_CORRESPONDIENTE]
*   **Hito 2 — Desarrollo:** [MES_O_SEMANA_CORRESPONDIENTE]
*   **Hito 3 — Despliegue (Inicio de Estabilización de 15 días):** Al término de [PLAZO_DE_ENTREGA]
*   **Fin de Estabilización:** Día de firma del Acta de Aceptación y detonante para facturar el último pago.
*   **Periodo de Garantía Total ([DIAS_GARANTIA] naturales):** Arranca posterior al pago final.

**8. Precio, Desglose de Pagos y Facturación**
El precio total de este proyecto es de **$[PRECIO_TOTAL_MXN] MXN (Netos)**, pagadero conforme al siguiente esquema de hitos:

| Hito de Facturación | Porcentaje | Monto a Pagar | Condición de Entrega |
| :--- | :---: | :--- | :--- |
| **Pago 1: Anticipo** | 30% | $[MONTO_PAGO_1] MXN (Netos) | A la firma del presente contrato / anexo, previo al inicio del desarrollo. |
| **Pago 2: Despliegue** | 30% | $[MONTO_PAGO_2] MXN (Netos) | Tras liberar el sistema al entorno de producción (Inicio de Estabilización). |
| **Pago 3: Pago Final** | 40% | $[MONTO_PAGO_3] MXN (Netos) | Contra la firma del Acta de Aceptación (Fin de Estabilización, Día 15). |
| **TOTAL** | **100%** | **$[PRECIO_TOTAL_MXN] MXN (Netos)** | |

**9. Criterios de aceptación**
*   La aplicación permite crear y guardar una solicitud y exportarla a PDF sin errores.
*   La aplicación es accesible vía web con credenciales seguras.
*   Los tiempos de respuesta de la interfaz son aceptables y opera fluidamente en navegadores de escritorio (Chrome/Safari), cumpliendo la adaptabilidad móvil de forma exclusiva para el Portal Médico.

_______________________________
**FIRMA DE CONFORMIDAD - EL CLIENTE**
