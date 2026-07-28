# ANEXO A — ALCANCE DEL PROYECTO
## Proyecto 2: Bloc Digital via Internet

Este anexo forma parte integrante del Contrato de Prestación de Servicios Profesionales celebrado entre "EL PRESTADOR" y "EL CLIENTE".

**1. Descripción general del sistema**
"EL SISTEMA" es una aplicación web privada accesible vía Internet a través de `laesh.mx` que sustituye las libretas y recetas de papel usadas por los médicos y el laboratorio. Permite crear, consultar y dar seguimiento a las solicitudes de estudio de manera 100% digital, optimizando la interacción interna sin dependencias de redes sociales externas.

**2. Fases incluidas**
1. Análisis de requerimientos y del flujo de trabajo actual (levantamiento con el personal médico/laboratorio).
2. Diseño de la solución (experiencia de usuario, interfaz y modelo de base de datos).
3. Desarrollo del sistema conforme a los módulos y funcionalidades descritos en la sección 3.
4. Pruebas (funcionales y de aceptación) previas a la puesta en producción.
5. Despliegue en el entorno de producción de "EL CLIENTE" (el servidor debe ser proveído por "EL CLIENTE" o administrado mediante el Contrato Independiente de Servicios Recurrentes).
6. **Periodo de Estabilización de 10 días naturales** (Fase de pruebas en vivo y correcciones iniciales). *(Nota: Durante esta fase se elaborará y entregará formalmente la documentación técnica y el manual de usuario del sistema).*
7. **Firma del Acta de Aceptación** (Hito formal que detona el pago final).
8. **Periodo de Garantía Total de 20 días naturales**, el cual arranca exclusivamente tras la firma del Acta de Aceptación y la liquidación del pago final. *(Nota: Durante la estabilización previa, se incluye la capacitación al personal y el acompañamiento en sitio).*

**3. Módulos y funcionalidades incluidas**
*   **Módulo de Captura (Portal Médico):** Captura digital de solicitud de análisis clínicos por parte del médico tratante desde `laesh.mx/medicos`. Genera una hoja impresa con formato LAESH con `#folio` único y código de barras simple.
*   **Módulo de Recepción, Notificación y Descarga de Orden Digital:** Notificación instantánea (globito contador acompañado de un **pitido de sonido silbato exclusivo para recepción**) al portal `laesh.mx/labadmin` al crearse una orden digital, con **enlace directo al registro del paciente** para consultar datos o descargar la orden digital en PDF. Incluye herramienta unificada de autocompletado inteligente (mínimo 5 caracteres por folio o nombre).
*   **Módulo de Carga Manual de Resultados (Subida de PDF):** Interfaz para que el personal del laboratorio suba el archivo PDF de resultados y lo vincule digitalmente al registro del paciente. Al cargar el archivo, el sistema **actualiza automáticamente el estado a `Resultados Listos`**.
*   **Módulo de Catálogo:** Catálogo administrable de estudios/análisis clínicos disponibles.
*   **Módulo de Notificaciones Instantáneas:** Notificaciones instantáneas (estilo "globito" con contador y mensaje de detalle) para médicos y laboratorio vía WebSockets. Para el recepcionista, la notificación incluye sonido auditivo de silbato; para el médico, la notificación de resultados es silenciosa e incluye un **enlace directo de descarga al PDF de resultados**.
*   **Módulo de Reportes:** Generación de estadísticas operativas e indicadores clave.
*   **Módulo de Seguridad:** Gestión de usuarios, roles (Médico, Recepción, Administrador) y permisos de acceso.

**3.1. Tabla de Alcance Funcional Exacto**
A continuación se detalla el comportamiento del sistema para evitar ambigüedades técnicas:

| Módulo del Sistema | Descripción de la Funcionalidad (Alcance Exacto) |
| :--- | :--- |
| **Catálogo de Estudios** | Administración para agregar o editar estudios médicos y precios. Incluye una carga masiva inicial mediante un archivo Excel provisto por "EL CLIENTE". |
| **Portal Médico (Captura)** | Pantalla para que el médico tratante cree una orden digital (Nombre, estudios). El sistema asigna el estado **Remitido** e imprime una hoja con formato institucional LAESH que incluye un `#folio` único bajo un código de barras simple. |
| **Buscador Inteligente (Recepción)** | Input de texto único en el portal `laesh.mx/labadmin`. Permite buscar por `#folio` exacto o por nombre del paciente (autocompletado min. 5 caracteres) y ofrece un botón de **Descargar Orden Digital (PDF)**. |
| **Estados de la orden digital** | Control de flujo operativo en 4 fases (<span style="background-color: #EBF8FF; color: #2B6CB0; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 0.85em;">Remitido</span> ➔ <span style="background-color: #FEEBC8; color: #C05621; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 0.85em;">En Atención</span> ➔ <span style="background-color: #C6F6D5; color: #22543D; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 0.85em;">Resultados Listos</span> ➔ <span style="background-color: #EDF2F7; color: #4A5568; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 0.85em;">Cerrada</span>) y actualización automática de estado al cargar el PDF de resultados. |
| **Carga de Resultados y Cambio Automático de Estado** | Modal/Botón en el portal `labadmin` para cargar el archivo PDF de resultados y vincularlo al paciente. Al completar la carga, el sistema **actualiza automáticamente el estado a `Resultados Listos`**. |
| **Notificación Instantánea a Recepción (con Audio y Link Directo)** | Al crearse la orden digital por parte del médico, el portal `laesh.mx/labadmin` recibe una notificación instantánea ("globito contador" **acompañada de un pitido de sonido silbato exclusivo para recepción**); al hacer clic en el detalle, muestra un **enlace directo al registro del paciente** para consultar su expediente y descargar/imprimir la orden digital en PDF. |
| **Notificación Instantánea al Médico (Silenciosa y con Link Directo)** | Al cambiar el estado a *Resultados Listos*, el sistema dispara una notificación instantánea ("globito contador" silencioso) al portal `laesh.mx/medicos` con un mensaje que contiene un **enlace directo para descargar el PDF de resultados**. |
| **Portal de Seguimiento (Médico)** | Pantalla segura donde el médico tratante consulta instantáneamente el estatus de sus pacientes referidos y descarga sus PDFs de resultados directamente. |
| **Entrega al Paciente y Cierre** | El paciente recibe sus resultados impresos en ventanilla (operación tradicional). La recepcionista marca el estado como **Cerrada** (o se cierra automáticamente tras 30 días de caducidad). |
| **Módulo de Reportes** | Pantalla con estadísticas operativas básicas (por médico tratante, paciente y para el laboratorio). *No incluye cálculos financieros, comisiones ni gestión de honorarios.* |
| **Caducidad Automática** | Regla de negocio en el servidor que cierra/caduca automáticamente las solicitudes médicas si el paciente no acude a la clínica en un plazo de 30 días (configurable). |
| **Compatibilidad de Dispositivos** | El **Portal Médico** cuenta con adaptabilidad para celulares, tablets y computadoras. El portal de la clínica está diseñado para computadoras de escritorio (Windows/macOS) usando Google Chrome o Safari. |

**4. Arquitectura y Mecanismos de Sincronización**
El sistema se basará en una arquitectura orientada a la velocidad y confiabilidad local:
*   **Generación, Disponibilidad y Notificación de Hoja Impresa:** Al finalizar la captura de la orden digital por el médico, el sistema produce un documento PDF optimizado con los logotipos de LAESH. La orden digital queda registrada en la base de datos y **disponible para su descarga en PDF desde `laesh.mx/labadmin`**. Al mismo tiempo, el servidor dispara una **notificación instantánea a la recepcionista (con pitido de sonido silbato) con un enlace directo al registro del paciente**.
*   **Estados de la orden digital y Carga Manual de Resultados (Subida de PDF):** 
    1. `Remitido`: Creado por médico (notificado instantáneamente a recepción con sonido de silbato, enlace a expediente y orden digital descargable en PDF).
    2. `En Atención`: Confirmado por recepción al llegar el paciente.
    3. `Resultados Listos`: Activado automáticamente al subir el PDF de resultados y vincularlo al registro del paciente.
    4. `Cerrada`: Al entregar el resultado físico en ventanilla o por caducidad de 30 días.
*   **Notificaciones Instantáneas Bidireccionales (Swoole / Node.js):** 
    - Médico ➔ Recepción: Notificación instantánea en `labadmin` con sonido de silbato y enlace al expediente del paciente al crearse una orden digital.
    - Recepción ➔ Médico: Notificación instantánea en `medicos` (silenciosa) con enlace directo de descarga al PDF de resultados al subirse los análisis.
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
*   **Stack Tecnológico:** PHP, MySQL, HTML/JS/CSS, Node.js / Swoole (versiones open-source estables para el servidor de notificaciones instantáneas), framework PHP MVC, Linux Ubuntu 24.x.
*   **Infraestructura:** La aplicación requiere un servidor en la nube que cumpla con los requisitos del plan **VPS KVM 2 de Hostinger** (~$1,500 a ~$2,000 MXN/año) y el registro del **Dominio de Internet (.mx) / DNS** (~$600 MXN/año). Al operar en la Nube, "EL CLIENTE" debe garantizar una conexión a internet estable en sus instalaciones y una impresora configurada correctamente para la emisión de las hojas de solicitud en el lado médico. *El costo de renta de los servicios externos es responsabilidad directa de "EL CLIENTE" con sus proveedores.*
*   **Retención de Datos:** La base de datos está diseñada para retener el historial operativo del laboratorio hasta por **5 años**. 

**7. Calendario de entregas**
El sistema tendrá un plazo máximo de desarrollo y entrega de **2 meses (60 días naturales)** contados a partir de la firma del presente anexo.
*   **Hito 1 — Análisis, diseño y desarrollo temprano:** Mes 1.
*   **Hito 2 — Despliegue (Inicio de Estabilización de 10 días):** Mes 2 (Día 60).
*   **Fin de Estabilización y Aceptación:** Finalizados los 10 días de estabilización, se firma el Acta de Aceptación de Proyecto Tecnológico. La firma de este hito formal certifica la recepción de conformidad del sistema, dando paso a la liberación y liquidación del pago final (60%).
*   **Periodo de Garantía Total (20 días naturales):** Arranca exclusivamente a partir del día siguiente a la firma del Acta de Aceptación y una vez liquidado el pago final al 100%.

**8. Precio, Desglose de Pagos y Facturación**
El precio total de este proyecto es de **$30,000.00 MXN (Netos)**, pagadero conforme al siguiente esquema de 2 hitos:

| Hito de Facturación | Porcentaje | Monto a Pagar | Condición de Entrega |
| :--- | :---: | :--- | :--- |
| **Pago 1: Anticipo** | 40% | $12,000.00 MXN (Netos) | A la firma del presente contrato / anexo, previo al inicio del desarrollo. |
| **Pago 2: Firma de Aceptación** | 60% | $18,000.00 MXN (Netos) | Contra la firma del Acta de Aceptación (Fin de Estabilización, Día 10). |
| **TOTAL** | **100%** | **$30,000.00 MXN (Netos)** | |

**9. Criterios de aceptación**
*   La aplicación permite crear y guardar una solicitud y exportar/imprimir la hoja LAESH con código de barras y folio generado por el sistema sin errores.
*   El portal `laesh.mx/labadmin` recibe una notificación instantánea ("globito" con pitido de silbato) al crearse una orden digital, con un enlace directo al registro del paciente para consultar datos o descargar la orden digital en PDF.
*   El buscador en el portal `labadmin` permite localizar pacientes por folio o por nombre (activando autocompletado con un mínimo de 5 caracteres de precisión).
*   El portal `labadmin` permite actualizar el estado a `En Atención`, subir el archivo PDF de resultados mediante carga manual (subida de PDF), cambiando automáticamente el estado a `Resultados Listos`, y cerrar la solicitud (`Cerrada`).
*   Las notificaciones instantáneas ("globito" silencioso) se disparan exitosamente cuando los resultados están listos, incluyendo un enlace directo para descargar el PDF de resultados desde el portal del médico.
*   Los tiempos de respuesta de la interfaz son aceptables y opera fluidamente en navegadores de escritorio (Chrome/Safari), cumpliendo la adaptabilidad móvil de forma exclusiva para el Portal Médico.

_______________________________
**FIRMA DE CONFORMIDAD - EL CLIENTE**
