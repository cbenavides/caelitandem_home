# ANEXO A — ALCANCE DEL PROYECTO
## Proyecto: Sitio Web Corporativo / Página de Presentación

> **NOTA DE APLICABILIDAD:** Este anexo aplica **únicamente** para las Opciones **1 (Sitio Web Básico)** o **2 (Sitio Web PLUS)** contratadas de forma individual. Si "EL CLIENTE" contrató la **Opción 4 (Paquete Integral Automatizado)**, el alcance del sitio web ya está íntegramente amparado en el `Anexo A — Paquete Integral` y **este documento NO debe firmarse de forma independiente**.

Este anexo forma parte integrante del Contrato de Prestación de Servicios Profesionales celebrado entre "EL PRESTADOR" y "EL CLIENTE".

**1. Descripción general del proyecto**
El proyecto consiste en crear una página web sencilla para el laboratorio, con el objetivo de tener una presencia profesional en internet, informar sobre los estudios disponibles y facilitar el contacto con los pacientes.

**2. Alcance y entregables (Tabla de Funcionalidades)**
A continuación se detalla el alcance exacto del desarrollo. Los módulos marcados como "PLUS" únicamente aplican y tienen validez técnica si "EL CLIENTE" contrató explícitamente dicha modalidad comercial.

| Componente | Descripción de la Funcionalidad (Alcance Exacto) |
| :--- | :--- |
| **Sitio Web** | Página de 5 secciones (Inicio, Nosotros, Estudios, Contacto, Privacidad). Adaptable a celulares y optimizada para aparecer en Google. Botón flotante de WhatsApp. |
| **Portal de Pacientes (Modalidad PLUS)** | Área segura donde los pacientes pueden descargar su historial de resultados en formato PDF (últimos 90 días). Acceso validado mediante **Teléfono + Folio**. |
| **Subida de Resultados (Modalidad PLUS)** | Canal seguro (Carpeta de sincronización local) donde el personal de laboratorio deposita los PDFs diarios. El servidor los procesa y asocia automáticamente apoyándose en el `#Folio` contenido en el nombre del archivo. |
| **Automatización WhatsApp (Modalidad PLUS)** | Una vez procesado el archivo PDF, el sistema lo convierte a imagen (JPG/PNG) y lo envía directamente al WhatsApp del paciente para asegurar su visualización fácil en su celular. **Esto aplica para TODOS los pacientes del laboratorio (tanto referidos por médicos como directos de mostrador)**, ahorrando mucho tiempo en recepción. Requiere la asignación de un **NUEVO Número Telefónico Dedicado (Chip SIM)**, el cual la recepcionista podrá operar vía **Bandeja de Atención Centralizada (Chatwoot)** para atender a los pacientes. |
| **Prueba de Concepto y Contingencia (PLUS)** | Previo a la salida, se realizará una prueba técnica para intentar extraer el teléfono del paciente leyendo el texto interior del PDF. De resultar inviable/inestable por el formato del laboratorio, se aplicará invariablemente la regla de contingencia: renombrar el archivo por `#Folio`. |

**3. Fuera de alcance (No incluye)**
*   Creación, redacción de contenido (textos) o producción multimedia (fotografías, videos); estos elementos deberán ser proporcionados por "EL CLIENTE".
*   Gestor de Contenidos (CMS) completo para la edición autónoma de la estructura y textos estáticos de la página por parte de "EL CLIENTE".
*   **Asesoría Legal (INAI) y Buzones de Correo:** La redacción jurídica del Aviso de Privacidad y el cumplimiento de la ley de protección de datos personales son responsabilidad de "EL CLIENTE". Así mismo, el proyecto no incluye la creación de buzones de correo corporativo para empleados.
*   Gestión de campañas de publicidad, posicionamiento pagado (SEM) o administración de redes sociales.
*   Servicios de hosting, compra de dominios, certificados SSL y el consumo por API en Meta Platforms Inc., los cuales son pagos que asume directamente "EL CLIENTE". Así mismo, para la Modalidad PLUS, el cliente asume la **Titularidad y Verificación Empresarial ante Meta** (proveyendo su Constancia Fiscal y Comprobante de Domicilio para asegurar la propiedad legal del canal por normativas de privacidad), proveer un **NUEVO Número Telefónico Exclusivo (Chip SIM)** y garantizar una conexión a internet estable en su sucursal. **RESTRICCIÓN CRÍTICA:** Queda estrictamente prohibido migrar el número actual de la clínica a la API Cloud de Meta, ya que ocasionaría la clausura de su app normal y la pérdida total del historial de chats con médicos y grupos.

**3.1 Políticas de Uso de la Bandeja Omnicanal (Modalidad PLUS)**
Para cumplir con las políticas anti-spam de Meta (WhatsApp) y garantizar la operatividad de la línea, aplican las siguientes reglas de comunicación:
*   **Apertura de Ventana (24h):** El sistema puede notificar resultados en cualquier momento. Si un paciente escribe o responde (incluso meses después), ese mensaje es **iniciado por el usuario (Inbound)**. En el instante en que manda ese mensaje, Meta abre automáticamente una Ventana de 24 horas, permitiendo a la recepcionista (desde Chatwoot) contestarle de forma libre y sin bloqueos *(Ver Flujo 3 del Anexo Visual)*.
*   **Restricción de Marketing:** Si el laboratorio utiliza el canal automatizado para enviar campañas comerciales masivas, realizar ventas en frío o contactar pacientes fuera de la ventana de 24 horas, Meta suspenderá permanentemente la línea. Las llamadas telefónicas (celulares o de voz por la app) no abren la ventana de 24 horas.

**4. Obligaciones específicas del cliente**
Para un flujo de trabajo óptimo, "EL CLIENTE" se compromete a entregar todo el material gráfico (logotipos en alta resolución, manual de marca si existe) y textos definitivos en un plazo sugerido de **7 días naturales** posteriores a la firma. Cualquier retraso en la entrega de este material o en las aprobaciones de diseño será tolerado por "EL PRESTADOR" sin penalizaciones, siempre y cuando no comprometa la fecha máxima de entrega estipulada en la cláusula 5.

**5. Calendario y Plazo de entrega**
El sitio web será entregado (desplegado a producción) en un plazo máximo e improrrogable de **[PLAZO_DE_ENTREGA]** contados a partir de la firma del presente anexo. Tras el despliegue, iniciará el **Periodo de Estabilización de 15 días naturales**, al término del cual se procederá a la firma del Acta de Aceptación.

*Cláusula de Protección de Tiempos:* Si al llegar la fecha límite "EL CLIENTE" aún no ha entregado la totalidad del contenido (textos e imágenes), "EL PRESTADOR" publicará el sitio con la estructura funcional terminada y contenido de relleno para cumplir contractualmente con los tiempos y detonar el inicio de la Estabilización. "EL PRESTADOR" sustituirá el relleno por el contenido definitivo sin costo, siempre y cuando ocurra dentro del periodo de garantía.

**6. Garantía ([DIAS_GARANTIA])**
La garantía para corrección de defectos visuales, funcionales o enlaces rotos atribuibles al desarrollo será de **[DIAS_GARANTIA] naturales**, los cuales comenzarán a correr exclusivamente a partir del día siguiente a la firma del Acta de Aceptación y una vez liquidado el pago final. Durante la fase de estabilización previa, se incluye la capacitación al personal.

**7. Precio, Desglose de Pagos y Facturación**
El precio total de este proyecto es de **$[PRECIO_TOTAL_MXN] MXN (Netos)**, pagadero bajo el siguiente esquema:

| Hito de Pago | Porcentaje | Monto a Facturar | Condición de Cobro |
| :--- | :--- | :--- | :--- |
| **Pago 1: Anticipo** | 50% | $[MONTO_PAGO_1] MXN (Netos) | A la firma de este anexo y entrega de todos los recursos. |
| **Pago 2: Pago Final** | 50% | $[MONTO_PAGO_2] MXN (Netos) | A la firma del Acta de Aceptación (Fin de Estabilización, Día 15). |
| **TOTAL** | **100%** | **$[PRECIO_TOTAL_MXN] MXN (Netos)** | |

*(Nota: Los porcentajes de anticipo para el Sitio Web varían respecto a la Cláusula Tercera del Contrato Base, prevaleciendo este Anexo)*.

_______________________________
**FIRMA DE CONFORMIDAD - EL CLIENTE**
