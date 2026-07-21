# ESPECIFICACIÓN FUNCIONAL Y TÉCNICA
**Proyecto:** Laboratorios Clínicos LAESH (Paquete Integral Automatizado)
**Componentes:** Bloc Digital de Solicitudes + Portal de Resultados Automatizado

Este documento define el alcance técnico y funcional exacto del sistema a desarrollar. Forma la base técnica que regirá el desarrollo del proyecto y sirve como anexo descriptivo para el contrato comercial.

---

## 1. MÓDULO BLOC DIGITAL (Portal de Médicos y Clínica)

### 1.1 Catálogo de Estudios
*   **Funcionalidad:** El sistema permitirá administrar (CRUD) los estudios y sus precios.
*   **Carga Inicial:** Se incluirá una funcionalidad de carga masiva inicial mediante un archivo estándar (Excel/CSV).
*   **Gestión Continua:** Pantallas básicas administrativas para que el personal de la clínica pueda agregar o modificar el precio y nombre de los estudios de forma individual.

### 1.2 Captura de la Solicitud / Orden (Médicos)
*   **Funcionalidad:** Interfaz ágil (UI eficiente) para que un médico remita a un paciente al laboratorio.
*   **Registro de Médico:** Los médicos deben registrarse previamente (nombre, teléfono, cédula opcional).
*   **Datos de Captura:** Nombre del paciente, Teléfono (clave para WhatsApp), Edad, Sexo, y un seleccionador de la lista de estudios del catálogo.
*   **Confirmación:** Pantalla previa de confirmación antes del envío final a la base de datos.
*   **Notificación Inmediata al Paciente:** Al guardarse la orden, el servidor generará una imagen (ticket/formato ligero) y enviará automáticamente un mensaje parametrizado vía WhatsApp Cloud API al celular del paciente, indicando que el médico "X" lo ha remitido a LAESH.

### 1.3 Portal del Médico (Seguimiento)
*   **Funcionalidad:** Tablero donde el médico consulta el estatus de los pacientes que ha remitido.
*   **Filtros y Vistas:** Búsqueda abierta (nombre, teléfono) y filtros por fecha (año, mes, día).
*   **Indicadores Visuales:** Semáforo de estatus para saber de un vistazo si el paciente ya acudió a la clínica y si el estudio fue concluido (Cerrado).

### 1.4 Portal Administrativo de la Clínica
*   **Notificaciones:** Alerta visual y/o refresco del listado (vía AJAX/Polling) cuando un médico envía una nueva solicitud.
*   **Listado de Recepción:** Tabla con encabezado fijo y numeración. Muestra el historial completo (con retención de hasta 5 años). 
*   **Filtros:** Búsqueda por nombre de paciente, doctor, teléfono y fecha. 
*   **Recepción del Paciente:** Cuando el paciente acude físicamente a pagar, el personal de la clínica busca su folio o nombre en el portal, lo selecciona y cambia su estatus de *"Remitido"* a *"En Atención"*.

---

## 2. MÓDULO DE RESULTADOS Y CARGA DE ARCHIVOS

### 2.1 Flujo de Subida de Resultados (Laboratorista)
El envío de los resultados al sistema web se realizará mediante un canal seguro de sincronización (SFTP/Rsync/Pool) configurado en la computadora Windows 10/11 de la clínica.
*   **Automatización Local:** Un script local (PowerShell/Bat) creará carpetas diarias (ej. `YYYY/MM/DD`). El operador únicamente guardará los PDFs terminados en esta carpeta.
*   **Sincronización:** El sistema enviará automáticamente los archivos de la carpeta local al servidor web.

### 2.2 Asociación de PDFs y Alerta de WhatsApp (Prueba de Concepto y Contingencia)
Una vez que el PDF llega al servidor, el sistema debe asociarlo a una orden y avisarle al paciente que está listo.
*   **Fase 1 (Prueba de Concepto - PoC):** Al inicio del proyecto, se intentará programar un módulo que lea y extraiga el texto del PDF generado por las máquinas del laboratorio para detectar el nombre o teléfono del paciente de forma automatizada.
*   **Regla de Contingencia (Renombrado por Folio):** Si la PoC demuestra que la extracción de texto es inviable, frágil o inestable (debido al formato de las máquinas del laboratorio), se implementará el flujo oficial seguro: **El operador de la clínica deberá guardar o renombrar el archivo PDF utilizando el `#Folio` generado por el Bloc Digital (Ejemplo: `Folio10452.pdf`)**. 
*   **Disparo Automático:** Al leer el nombre del archivo, el servidor lo asociará a la base de datos, cambiará el estatus a *"Resultados Listos"*, convertirá el archivo a formato de imagen (JPG/PNG) y lo enviará directamente al WhatsApp del paciente (evitando incompatibilidades de visores de PDF).
*   **Cobertura Integral (Ventaja Operativa):** Este módulo de envío automatizado aplica para **absolutamente todos los pacientes** (tanto los remitidos digitalmente por un médico como los pacientes directos de mostrador), dotando a la clínica de una solución integral de entrega de resultados sin importar el origen del paciente.

---

## 3. PORTAL DEL PACIENTE

### 3.1 Consulta y Descarga
*   **Funcionalidad:** Portal de acceso para que el paciente pueda ver y descargar sus estudios.
*   **Vista:** Listado de los últimos 90 días (asociado a su número). Muestra el nombre del doctor que remitió, la fecha, la hora y el link de descarga directa del estudio (PDF).

---

## 4. ESQUEMA DE SEGURIDAD, ESTADOS Y CADUCIDAD

### 4.1 Privacidad y Protección de Datos
Para tranquilidad de la clínica y los pacientes, se integran protocolos de seguridad modernos:
*   **Tránsito de Datos:** Se usa el protocolo de seguridad HTTPS (Candado Verde) para que la información viaje encriptada por internet.
*   **Cifrado de Contraseñas:** Las contraseñas de los usuarios se protegen con algoritmos de cifrado (como Bcrypt). Nadie en la clínica ni los desarrolladores pueden leerlas o recuperarlas.
*   **Seguridad de Servidor:** El servidor provisto por Hostinger cuenta con estándares de protección mundial.
*   **Manejo de Tarjetas de Crédito:** Los pagos de consumos para WhatsApp o Servidores se hacen directamente en las plataformas seguras de Meta y Hostinger. El sistema de la clínica jamás pide, ve ni almacena datos bancarios.

### 4.2 Autenticación a los Portales
*   **Paciente:** Acceso mediante **Número de Teléfono** + **Folio de la Orden**. (Doble factor de acceso para privacidad del expediente).
*   **Médico:** Acceso mediante **Número de Teléfono** (Username) + **Fecha de Nacimiento** `DD/MM/YYYY` (Password).

### 4.3 Estados de Vida de la Solicitud (Workflow)
1.  **Remitido:** Orden creada por el médico.
2.  **En Atención:** El paciente llegó a la clínica, pagó y está en proceso.
3.  **Resultados Listos:** El archivo se sincronizó con éxito y se envió la imagen al paciente.
4.  **Cerrada:** Estado final (Terminado con éxito, o caducado).

### 4.4 Caducidad Automática (Cronjob)
*   Las solicitudes solo pueden permanecer en estado *"Remitido"* durante **1 mes**.
*   Una rutina automatizada del servidor (Cronjob) evaluará diariamente la base de datos. Si un paciente no asiste en el plazo de 1 mes, la solicitud pasará a estado *"Cerrada"* (o "Caducada").
*   Este parámetro (30 días) será configurable en una pantalla de la clínica para evitar dejar la regla quemada en código (hardcode).

### 4.5 Compatibilidad de Pantallas y Dispositivos
Para asegurar el correcto funcionamiento y tiempos de entrega, la compatibilidad de los sistemas queda definida de la siguiente manera:
*   **Portal del Médico:** Adaptabilidad total para celulares, tablets y computadoras de escritorio (Responsive Design).
*   **Portal Interno (Recepción Clínica):** Diseñado exclusivamente para resoluciones de computadora de escritorio (Desktop).
*   **Compatibilidad General:** Todas las interfaces web (incluyendo el portal del médico) están optimizadas para operar fluidamente en computadoras de escritorio con sistemas operativos **Windows 10 / Windows 11** y **macOS**, utilizando navegadores modernos como **Google Chrome** y **Apple Safari**.

---

### 4.6 Requerimientos de Infraestructura y Reglas de Interacción (WhatsApp)
El laboratorio deberá proveer un **Número Telefónico Dedicado (Celular o Fijo)** que fungirá como remitente oficial del *Sistema Bloc Digital*.
*   **Reglas de Interacción Automatizada:** El sistema iniciará contacto automatizado con el paciente única y exclusivamente en dos (2) ocasiones:
    1. Envío inicial de la Solicitud Digital de estudios.
    2. Envío final de los Resultados en formato de imagen (JPG/PNG).
*   **Atención Humana (WhatsApp Web):** Este mismo número será operado simultáneamente por la recepcionista o personal de atención vía **WhatsApp Web**. Esto permite aprovechar el hilo de conversación abierto por el sistema para interactuar manualmente con el paciente y dar continuidad al servicio (ej. agendar citas, aclarar precios, informar sobre pagos o resolver dudas).

---

## 5. FUERA DE ALCANCE (No Incluye)
Con el fin de garantizar el tiempo de entrega y delimitar la frontera del sistema, se excluye explícitamente:
*   **Aplicaciones móviles nativas** instalables (App Store/Google Play). Todo el sistema opera exclusivamente vía web.
*   Conversaciones automatizadas de atención al cliente (Chatbots) vía WhatsApp para cotizar, agendar citas, consultar requisitos, etc.
*   Control financiero, punto de venta o administración de ingresos (El sistema no es una caja registradora, no controla cobros, cortes de caja ni facturación electrónica).
*   **Esquema de Comisiones u Honorarios por Referencia:** El sistema contabiliza cuántas solicitudes cerró cada médico para fines estadísticos, pero NO incluye un módulo de "monedero", cuentas por pagar, ni cálculos financieros para gestionar el pago de comisiones o bonos hacia los médicos tratantes.
*   *(Nota comercial: Se entiende por "Portal" cualquier página que requiera autenticación, separada del "Sitio Web Institucional" público).*

---

## 6. ACTORES Y ROLES DEL SISTEMA
Para la correcta interpretación de los flujos operativos (ver documento independiente *Anexo_Visual_Flujos_Operativos*), se definen los siguientes roles y responsabilidades que interactúan con el ecosistema:

*   **Médico Tratante:** Profesional de la salud registrado en la plataforma que origina la *Solicitud Médica Digital* desde su consultorio (Portal Médico).
*   **Paciente:** Usuario final que asiste a la clínica y recibe de manera automatizada tanto sus solicitudes como sus resultados en su celular personal (vía WhatsApp).
*   **Recepcionista:** Personal administrativo en el mostrador del laboratorio. Gestiona la llegada del paciente, actualiza el estatus a *"En Atención"* en el Portal Interno, y opera simultáneamente la línea telefónica (vía WhatsApp Web) para dar seguimiento humano.
*   **Químico (Laboratorio):** Personal técnico-operativo de la clínica. Procesa las muestras, utiliza el *Sistema Admin. Existente* para exportar el PDF, y lo deposita en la carpeta de sincronización local.
*   **Sistema Bloc Digital (Internet):** El servidor inteligente en la nube provisto por "EL PRESTADOR". Orquesta las bases de datos, despliega los portales y detona los envíos automatizados a Meta/WhatsApp.
*   **Sistema Admin. Existente:** El software interno actual de la clínica (LIS) que utilizan para el procesamiento de muestras, el cual queda fuera del alcance de este desarrollo más allá de la exportación de PDFs.
