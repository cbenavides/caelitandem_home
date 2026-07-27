# ANEXO A — ALCANCE DEL PROYECTO
## Proyecto 2: Bloc Digital sin WhatsApp

Este anexo forma parte integrante del Contrato de Prestación de Servicios Profesionales celebrado entre "EL PRESTADOR" y "EL CLIENTE".

**1. Descripción general del sistema**
"EL SISTEMA" es una aplicación web privada que sustituye las libretas y recetas de papel usadas por los médicos y el laboratorio. Permite crear, consultar y dar seguimiento a las órdenes de estudios de manera 100% digital, optimizando la interacción interna sin dependencias de redes sociales externas.

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
*   **Módulo de Captura (Portal Médico):** Captura digital de solicitud de análisis clínicos por parte del médico tratante. Genera una hoja impresa con formato LAESH con `#folio` único y código de barras simple.
*   **Módulo de Recepción y Búsqueda:** Herramienta unificada de autocompletado inteligente para ubicar pacientes (por folio o nombre con un mínimo de 5 caracteres).
*   **Módulo de Carga Manual de Resultados (Upload PDF):** Interfaz para que el personal del laboratorio suba el archivo PDF de resultados y lo vincule digitalmente al registro del paciente.
*   **Módulo de Catálogo:** Catálogo administrable de estudios/análisis clínicos disponibles.
*   **Módulo de Notificaciones en Vivo:** Alertas en tiempo real (estilo "globito" con contador y detalles) para médicos y laboratorio, construidas sobre WebSockets.
*   **Módulo de Reportes:** Generación de estadísticas operativas e indicadores clave.
*   **Módulo de Seguridad:** Gestión de usuarios, roles (Médico, Recepción, Administrador) y permisos de acceso.

**3.1. Tabla de Alcance Funcional Exacto**
A continuación se detalla el comportamiento del sistema para evitar ambigüedades técnicas:

| Módulo del Sistema | Descripción de la Funcionalidad (Alcance Exacto) |
| :--- | :--- |
| **Catálogo de Estudios** | Administración para agregar o editar estudios médicos y precios. Incluye una carga masiva inicial mediante un archivo Excel provisto por "EL CLIENTE". |
| **Portal Médico (Captura)** | Pantalla para que el médico tratante cree una solicitud médica (Nombre, estudios). El sistema asigna el estado **Remitido** e imprime una hoja con formato institucional LAESH que incluye un `#folio` único bajo un código de barras simple. |
| **Buscador Inteligente (Recepción)** | Input de texto único en el portal de `labadmin`. Permite buscar por `#folio` exacto o por nombre del paciente (activando autocompletado a partir de 5 caracteres), mostrando 1 o varios resultados según precisión. |
| **Gestión de Estados Operativos** | La recepcionista actualiza el estado de la solicitud en pantalla a **En Atención** cuando el paciente se presenta en ventanilla. |
| **Carga Manual de Resultados (Upload PDF)** | Modal/Botón en el portal `labadmin` para cargar el archivo PDF de resultados y vincularlo al paciente. Al completar la carga, el estado cambia automáticamente a **Resultados Listos**. |
| **Notificaciones en Tiempo Real** | Globito contador (con panel de detalle al hacer clic) que actualiza los estatus en las pantallas web del laboratorio y del médico vía WebSockets cuando los resultados están listos o el paciente es atendido. |
| **Portal de Seguimiento (Médico)** | Pantalla segura donde el médico tratante consulta en tiempo real si los pacientes que mandó al laboratorio ya fueron atendidos o si sus resultados ya están listos. |
| **Entrega al Paciente y Cierre** | El paciente recibe sus resultados impresos en ventanilla (operación tradicional). La recepcionista marca el estado como **Cerrada** (o se cierra automáticamente tras 30 días de caducidad). |
| **Módulo de Reportes** | Pantalla con estadísticas operativas básicas (por médico tratante, paciente y para el laboratorio). *No incluye cálculos financieros, comisiones ni gestión de honorarios.* |
| **Caducidad Automática** | Regla de negocio en el servidor que cierra/caduca automáticamente las solicitudes médicas si el paciente no acude a la clínica en un plazo de 30 días (configurable). |
| **Compatibilidad de Dispositivos** | El **Portal Médico** cuenta con adaptabilidad para celulares, tablets y computadoras. El portal de la clínica está diseñado para computadoras de escritorio (Windows/macOS) usando Google Chrome o Safari. |

**4. Arquitectura y Mecanismos de Sincronización**
El sistema se basará en una arquitectura orientada a la velocidad y confiabilidad local:
*   **Generación de Hoja Impresa:** Al finalizar la captura de la orden, el sistema produce un documento PDF optimizado, pre-configurado con los logotipos y formato de LAESH. El código de barras impreso corresponde unívocamente al `#folio` interno generado por el sistema, facilitando una búsqueda ágil.
*   **Workflow de Estados y Carga Manual (Upload):** 
    1. `Remitido`: Creado por médico.
    2. `En Atención`: Confirmado por recepción al llegar el paciente.
    3. `Resultados Listos`: Activado al subir (upload) el PDF de resultados y vincularlo al registro del paciente.
    4. `Cerrada`: Al entregar el resultado físico o por caducidad automática de 30 días.
*   **WebSockets (Swoole / Node.js):** Toda alerta (Ej. "Resultados Listos" o "Paciente Atendido") es propagada instantáneamente del backend a todos los clientes (navegadores) conectados. Esto elimina la necesidad de refrescar la pantalla manualmente.
*   **Ausencia Total de Meta/WhatsApp:** El flujo no depende de la autorización, verificación ni servidores de Meta (WhatsApp). No requiere de pagos por conversación ni de una infraestructura de chat omnicanal (Chatwoot). Todo el proceso de información ocurre en un ecosistema web 100% privado y controlado.

**5. Fuera de alcance**
Quedan excluidas de este proyecto las siguientes funcionalidades para evitar ambigüedad:
*   Notificaciones automatizadas de resultados de laboratorio al paciente por WhatsApp o redes sociales. El laboratorio entregará el resultado final en papel en la clínica.
*   Redes Sociales: Uso de WhatsApp (Business o API), Facebook Messenger, SMS o Chatbots conversacionales.
*   Bandeja Omnicanal y Chatwoot.
*   Punto de venta, pasarelas de pago, control de caja o facturación (CFDI).
*   **Gestión financiera de referidores:** Cálculo de honorarios, comisiones, bonos o "monederos" para médicos por referidos.
*   **Buzones Email:** Creación de cuentas de correo corporativo para empleados.
*   Aplicación móvil nativa (iOS/Android).

**6. Tecnología y entorno**
*   **Stack Tecnológico:** PHP, MySQL, HTML/JS/CSS, Node.js / Swoole (versiones open-source estables para el servidor WebSocket de notificaciones), framework PHP MVC, Linux Ubuntu 24.x.
*   **Infraestructura:** La aplicación requiere un servidor en la nube que cumpla con los requisitos del plan **VPS KVM 2 de Hostinger**. Al operar en la Nube, "EL CLIENTE" debe garantizar una conexión a internet estable en sus instalaciones y una impresora configurada correctamente para la emisión de las hojas de solicitud en el lado médico. *El costo de renta de los servicios externos es responsabilidad directa de "EL CLIENTE" con sus proveedores.*
*   **Retención de Datos:** La base de datos está diseñada para retener el historial operativo del laboratorio hasta por **5 años**. 

**7. Calendario de entregas**
El sistema tendrá un plazo máximo de desarrollo y entrega de **2 meses (60 días naturales)** contados a partir de la firma del presente anexo.
*   **Hito 1 — Análisis, diseño y desarrollo temprano:** Mes 1.
*   **Hito 2 — Despliegue (Inicio de Estabilización de 15 días):** Mes 2 (Día 60).
*   **Fin de Estabilización:** Día de firma del Acta de Aceptación y detonante para facturar el último pago.
*   **Periodo de Garantía Total (30 días naturales):** Arranca posterior al pago final.

**8. Precio, Desglose de Pagos y Facturación**
El precio total de este proyecto es de **$25,000.00 MXN (Netos)**, pagadero conforme al siguiente esquema de 2 hitos:

| Hito de Facturación | Porcentaje | Monto a Pagar | Condición de Entrega |
| :--- | :---: | :--- | :--- |
| **Pago 1: Anticipo** | 30% | $7,500.00 MXN (Netos) | A la firma del presente contrato / anexo, previo al inicio del desarrollo. |
| **Pago 2: Firma de Aceptación** | 70% | $17,500.00 MXN (Netos) | Contra la firma del Acta de Aceptación (Fin de Estabilización, Día 15). |
| **TOTAL** | **100%** | **$25,000.00 MXN (Netos)** | |

**9. Criterios de aceptación**
*   La aplicación permite crear y guardar una solicitud y exportar/imprimir la hoja LAESH con código de barras y folio generado por el sistema sin errores.
*   El buscador en el portal `labadmin` permite localizar pacientes por folio o por nombre (activando autocompletado con un mínimo de 5 caracteres de precisión).
*   El portal `labadmin` permite actualizar el estado a `En Atención`, subir el archivo PDF de resultados mediante carga manual (upload) vinculándolo a la orden (`Resultados Listos`), y cerrar la solicitud (`Cerrada`).
*   Las notificaciones en tiempo real ("globito") se disparan exitosamente vía WebSockets cuando un estatus cambia, sin necesidad de recarga manual del navegador.
*   Los tiempos de respuesta de la interfaz son aceptables y opera fluidamente en navegadores de escritorio (Chrome/Safari), cumpliendo la adaptabilidad móvil de forma exclusiva para el Portal Médico.

_______________________________
**FIRMA DE CONFORMIDAD - EL CLIENTE**
