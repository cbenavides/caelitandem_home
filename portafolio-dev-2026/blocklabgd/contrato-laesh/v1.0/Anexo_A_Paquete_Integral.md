# ANEXO A — ALCANCE DEL PROYECTO (PAQUETE INTEGRAL)
## Proyecto: Bloc Digital + Sitio Web y Portal de Resultados Automatizado

Este anexo forma parte integrante del Contrato de Prestación de Servicios Profesionales celebrado entre "EL PRESTADOR" y "EL CLIENTE". Ampara legalmente la ejecución de la **Opción 4 (Paquete Integral Automatizado)**.

**1. Descripción general del sistema**
"EL SISTEMA" consiste en un ecosistema digital completo que unifica la presencia web institucional de "EL CLIENTE", un portal para descarga automatizada de resultados, y el Bloc Digital para la captura y emisión de solicitudes médicas por parte del personal autorizado. Todo integrado mediante notificaciones automatizadas vía la Plataforma Oficial de WhatsApp.

**2. Fases incluidas (Cronología del Proyecto)**
1. Análisis de requerimientos, diseño UI/UX unificado y modelado de base de datos.
2. Desarrollo del código e integraciones conforme a las funcionalidades de la sección 3.
3. Despliegue de "EL SISTEMA" en el servidor de producción.
4. **Periodo de Estabilización de 15 días naturales** (Pruebas en vivo, corrección de bugs iniciales y capacitación del personal).
5. **Firma del Acta de Aceptación Definitiva** (Hito formal que detona el pago final).
6. **Periodo de Garantía Total de 45 días naturales**, el cual arranca exclusivamente tras la firma del Acta de Aceptación y la liquidación del pago final.

**3. Módulos y funcionalidades incluidas (Tabla de Alcance Exacto)**

| Módulo del Sistema | Descripción de la Funcionalidad (Alcance Exacto) |
| :--- | :--- |
| **Sitio Web Presencial** | Estructura pública de 5 páginas (Inicio, Nosotros, Estudios, Contacto, Privacidad). Optimización básica para Google y adaptabilidad para celulares. |
| **Portal de Pacientes** | Área segura donde los pacientes descargan su historial en PDF (últimos 90 días). Acceso con doble factor: Teléfono + Folio. |
| **Catálogo de Estudios** | Administración de estudios médicos y precios. Incluye una carga masiva inicial provista en Excel. |
| **Portal Médico (Captura)** | Interfaz para que el médico registrado levante una solicitud digital. Notifica inmediatamente al paciente por WhatsApp (Ticket ligero). |
| **Portal de Seguimiento (Médicos)** | Tablero privado donde el médico consulta el estatus de sus pacientes remitidos (Visualización por semáforo de estatus). |
| **Portal Interno (Recepción)** | Pantalla para la recepcionista. Muestra solicitudes entrantes y permite marcar el estatus "En Atención". |
| **Módulo de Reportes** | Pantalla administrativa con indicadores de volumen operativo. *No incluye módulos financieros para cálculo de comisiones, honorarios ni monederos electrónicos.* |
| **Automatización WhatsApp (Resultados)** | El personal deposita los PDFs diarios en una carpeta local; el servidor los asocia mediante el `#Folio` en el nombre, los convierte a imagen (JPG/PNG) y los envía al WhatsApp del paciente automáticamente. (Aplica universalmente a pacientes referidos y directos de mostrador). |
| **Controles y Caducidad** | Caducidad a 30 días si el paciente no asiste a la clínica. "WhatsApp Stopper" de seguridad limitando a $6,000 MXN mensuales el consumo en la API de Meta. |

**4. Fuera de Alcance y Responsabilidades de Terceros**
Queda fuera de alcance el control financiero, facturación electrónica (CFDI) y chatbots conversacionales para atención al cliente. La solución requiere que "EL CLIENTE" provea y mantenga al corriente de pago un servidor **(Plan KVM 4 de Hostinger)**, la renovación de sus dominios web, una **Línea Telefónica Dedicada**, y el consumo publicitario en Meta Platforms Inc.

**5. Calendario y Plazo de Entrega**
El ecosistema tendrá un plazo máximo de desarrollo de **3 Meses (90 días naturales)** contados a partir de que "EL CLIENTE" entregue toda la información requerida (textos, logotipos, accesos).

**6. Precio, Desglose de Pagos y Facturación**
El precio total del Paquete Integral es de **$80,000.00 MXN (Netos)**, pagadero bajo el siguiente esquema:

| Hito de Facturación | Porcentaje | Monto a Pagar | Condición de Entrega / Cobro |
| :--- | :---: | :--- | :--- |
| **Pago 1: Anticipo** | 30% | $24,000.00 MXN (Netos) | A la firma del presente anexo (Arranque). |
| **Pago 2: Despliegue** | 30% | $24,000.00 MXN (Netos) | Tras liberar el sistema funcional al entorno de producción (Día 1 de Estabilización). |
| **Pago 3: Pago Final** | 40% | $32,000.00 MXN (Netos) | Contra la firma del **Acta de Aceptación Definitiva** (Fin de Estabilización, Día 15). |
| **TOTAL** | **100%** | **$80,000.00 MXN (Netos)** | |

_______________________________
**FIRMA DE CONFORMIDAD - EL CLIENTE**
