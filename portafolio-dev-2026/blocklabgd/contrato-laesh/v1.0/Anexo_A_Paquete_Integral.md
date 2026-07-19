# ANEXO A — ALCANCE DEL PROYECTO (PAQUETE INTEGRAL)
## Proyecto: Bloc Digital de Solicitudes Clínicas + Sitio Web y Portal de Resultados Automatizado

Este anexo forma parte integrante del Contrato de Prestación de Servicios Profesionales celebrado entre "EL PRESTADOR" y "EL CLIENTE". Ampara legalmente la ejecución de la **Opción 4 (Paquete Integral Automatizado)**.

**1. Descripción general del sistema**
"EL SISTEMA" es una solución completa que integra una página web, un portal para descargar resultados y el Bloc Digital para que los médicos tratantes creen solicitudes médicas. Todo está conectado para enviar notificaciones automáticas por WhatsApp a los pacientes.

**2. Fases incluidas (Cronología del Proyecto)**
1. Análisis de requerimientos, diseño UI/UX unificado y modelado de base de datos.
2. Desarrollo del código e integraciones conforme a las funcionalidades de la sección 3.
3. Despliegue de "EL SISTEMA" en el servidor de producción.
4. **Periodo de Estabilización de 15 días naturales** (Pruebas en vivo, corrección de bugs iniciales y capacitación del personal).
5. **Firma del Acta de Aceptación** (Hito formal que detona el pago final).
6. **Periodo de Garantía Total de 45 días naturales**, el cual arranca exclusivamente tras la firma del Acta de Aceptación y la liquidación del pago final.

**3. Módulos y funcionalidades incluidas (Tabla de Alcance Exacto)**

| Módulo del Sistema | Descripción de la Funcionalidad (Alcance Exacto) |
| :--- | :--- |
| **Sitio Web** | Página sencilla de 5 secciones (Inicio, Nosotros, Estudios, Contacto con mapa, Privacidad). Adaptable a celulares, optimizada para Google y con botón directo de WhatsApp. |
| **Portal de Pacientes** | Área web para que los pacientes descarguen sus resultados en PDF (últimos 90 días). Acceso mediante Teléfono + Folio. |
| **Catálogo de Estudios** | Pantalla para agregar o editar estudios médicos y precios. Incluye una carga masiva inicial (desde Excel). |
| **Portal Médico (Captura)** | Pantalla para que el médico tratante cree una solicitud médica. Le avisa inmediatamente al paciente por WhatsApp. |
| **Portal de Médicos (Seguimiento)** | Pantalla privada donde el médico tratante puede ver si los pacientes que mandó ya fueron atendidos en el laboratorio. |
| **Portal Interno (Recepción)** | Pantalla para la recepcionista. Muestra solicitudes entrantes y permite marcar el estatus "En Atención". |
| **Módulo de Reportes** | Pantalla con estadísticas básicas del laboratorio. *No incluye módulos financieros, calculadoras de comisiones ni monederos.* |
| **Automatización WhatsApp (Resultados)** | El personal deposita los PDFs diarios en una carpeta local; el servidor los asocia al paciente, los convierte a imagen (JPG/PNG) y los envía por WhatsApp automáticamente. (Aplica universalmente a pacientes referidos y de mostrador). |
| **Prueba de Concepto y Contingencia** | Previo a la salida, se realizará una prueba técnica para intentar extraer el `#Folio` o teléfono directamente del texto interior del PDF. De resultar inviable/inestable por el formato nativo del laboratorio, se aplicará invariablemente la regla de contingencia: el personal deberá renombrar manualmente cada archivo con su `#Folio`. |
| **Controles y Caducidad** | Caducidad a 30 días si el paciente no asiste a la clínica. "WhatsApp Stopper" de seguridad limitando a $6,000 MXN mensuales el consumo en la API de Meta. |

**4. Políticas de Uso de la Bandeja Omnicanal (Regla 24h)**
Para cumplir con las políticas anti-spam de Meta (WhatsApp) y garantizar la operatividad de la línea, aplican las siguientes reglas de comunicación:
*   **Apertura de Ventana (24h):** El sistema puede notificar resultados automáticamente en cualquier momento. Sin embargo, para que el personal de recepción (humano) pueda enviar mensajes de *texto libre* al paciente (seguimiento, indicaciones), el paciente debe iniciar la interacción primero (Ej. escribiendo una duda o presionando el botón `[Ver Horarios y Ubicación]` incluido en las notificaciones).
*   **Restricción de Marketing:** Si el laboratorio utiliza el canal automatizado para enviar campañas comerciales masivas, realizar ventas en frío o contactar pacientes fuera de la ventana de 24 horas, Meta suspenderá permanentemente la línea. Las llamadas telefónicas (celulares o de voz por la app) no abren la ventana de 24 horas.

**5. Fuera de Alcance y Responsabilidades de Terceros**
Queda fuera de alcance el control financiero, facturación electrónica (CFDI), creación de buzones de correo corporativo para empleados, chatbots para atención al cliente, y la redacción/asesoría legal del Aviso de Privacidad (cumplimiento INAI para datos en salud). La solución requiere que "EL CLIENTE" mantenga una conexión a internet estable en sus sucursales, provea y mantenga al corriente de pago un servidor **(Plan KVM 4 de Hostinger)**, la renovación de sus dominios, un **Nuevo Número Telefónico Dedicado Móvil (Chip SIM)**, el consumo en Meta Platforms, y que asuma la **Titularidad y Verificación Empresarial ante Meta** (aportando su Constancia Fiscal y Comprobante de Domicilio para asegurar la propiedad legal del canal de comunicación).

**6. Calendario y Plazo de Entrega**
El ecosistema tendrá un plazo máximo de desarrollo de **4 Meses (120 días naturales)** contados a partir de que "EL CLIENTE" entregue toda la información requerida (textos, logotipos, accesos).

**7. Precio, Desglose de Pagos y Facturación**
El precio total del Paquete Integral es de **$80,000.00 MXN (Netos)**, pagadero bajo el siguiente esquema:

| Hito de Facturación | Porcentaje | Monto a Pagar | Condición de Entrega / Cobro |
| :--- | :---: | :--- | :--- |
| **Pago 1: Anticipo** | 30% | $24,000.00 MXN (Netos) | A la firma del presente anexo (Arranque). |
| **Pago 2: Despliegue** | 30% | $24,000.00 MXN (Netos) | Tras liberar el sistema funcional al entorno de producción (Día 1 de Estabilización). |
| **Pago 3: Pago Final** | 40% | $32,000.00 MXN (Netos) | Contra la firma del **Acta de Aceptación** (Fin de Estabilización, Día 15). |
| **TOTAL** | **100%** | **$80,000.00 MXN (Netos)** | |

_______________________________
**FIRMA DE CONFORMIDAD - EL CLIENTE**
