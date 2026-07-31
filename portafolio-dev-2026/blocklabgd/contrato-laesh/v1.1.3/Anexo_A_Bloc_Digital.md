# ANEXO A — ALCANCE DEL PROYECTO
## Proyecto 2: Bloc Digital via Internet

Parte integrante del Contrato de Prestación de Servicios Profesionales.

**1. Descripción y Fases del Sistema**
"EL SISTEMA" es una aplicación web privada en `laesh.mx` que digitaliza la emisión, seguimiento y entrega de solicitudes de estudio de laboratorio, optimizando la operación sin depender de redes sociales. 
El proyecto contempla las fases de: Análisis, Diseño, Desarrollo, Pruebas, Despliegue, Estabilización, y Firma de Acta de Aceptación (los plazos y periodos de garantía se definen en la Sección 4).

**2. Módulos y Flujo Operativo (Alcance Exacto)**
*   **Gestión de Sesiones:** Inicio y cierre de sesión (login/logout) para médicos y recepción. Incluye cambio de contraseña (requiriendo contraseña actual y doble verificación de la nueva). *Fuera de alcance:* Recuperación automatizada ("olvidé mi contraseña"); en su lugar, se incluye el reseteo manual de contraseñas de médicos por parte del perfil Recepción/Administrador.
*   **Catálogo de Estudios:** Administrable (alta/edición). Incluye carga inicial vía archivo de hoja de cálculo (Excel) provisto por LAESH.
*   **Configuraciones Globales:** Pantalla para el Administrador que permite parametrizar hasta 6 valores generales del sistema (por ejemplo, extender/reducir el tiempo de caducidad/rotación de 30 días de las solicitudes que no avanzaron).
*   **Portal Médico (Captura):** El médico crea órdenes digitales desde `laesh.mx/medicos`. Se genera e imprime una hoja PDF (con formato(s) que se diseñen en la colaboración entre el cliente y el prestador; pudiendo incluir: Logotipo de LAESH, `#folio` único, etc.). La orden inicia en estado **Remitido**.
*   **Notificación a Recepción (Audio y Enlace):** Al crear la orden, el portal `laesh.mx/labadmin` recibe una burbuja de aviso ("globito") instantánea con **pitido de silbato exclusivo** y enlace directo para consultar o descargar el archivo de la orden.
*   **Recepción y Búsqueda:** Recepción puede localizar pacientes por folio o nombre (autocompletado min. 5 caracteres) y actualizar el estado a **En Atención**. Permite además la búsqueda retroactiva para consultar y re-imprimir folios u órdenes pasadas, sin importar si su estado ya fue "Cerrado".
*   **Carga de Resultados (Cambio Automático de Estado):** Al realizar los estudios, recepción sube el archivo de resultados en el sistema, lo cual actualiza automáticamente el estado a **Resultados Listos**.
*   **Notificación al Médico (Silenciosa):** Al estar listos, el médico recibe un aviso silencioso con enlace para descargar los resultados.
*   **Entrega y Cierre:** El paciente recibe sus resultados impresos en ventanilla. El estado pasa a **Cerrada** (manualmente o por caducidad/rotación automática).
*   **Disponibilidad Permanente de Documentos:** Todos los documentos de la solicitud, de principio a fin del flujo, estarán disponibles permanentemente como PDF para su descarga tanto por el perfil de Recepción como por el Médico.
*   **Módulo de Reportes:** Estadísticas operativas básicas (sin cálculos financieros o de honorarios).
*   **Gestión de Usuarios y Panel del Sitio Web:** Perfiles de seguridad definidos (Médico, Recepción, Administrador). Incluye la creación y eliminación de usuarios. El médico puede actualizar su propio perfil, pero no tiene permisos para borrarlo. Desde el portal de recepción se actualizan de manera instantánea las Promociones, Consultas, Banner y Membresías del sitio público `laesh.mx` *(Esta funcionalidad pertenece al alcance del Proyecto 1)*.

**3. Tecnología, Infraestructura y Exclusiones**
*   **Tecnología:** Lenguajes web y bases de datos estándar con servidor de notificaciones instantáneas. Ecosistema 100% web, privado.
*   **Infraestructura:** Requiere un Servidor Privado Virtual (VPS) y Dominio `.mx` bajo gestión del cliente (los pagos a terceros aplican conforme al Contrato Marco). Incluye retención de historial operativo de 5 años.
*   **Adaptabilidad:** Interfaces optimizadas y 100% responsivas para computadoras (Portal de Recepción) y teléfonos móviles (Portal Médico), sujetas a las especificaciones de resolución (1280px a 4K) y restricciones tecnológicas (sin soporte a tabletas ni Apps/PWAs) definidas en la Cláusula Segunda del Contrato Marco.
*   **Fuera de Alcance:** Envíos automáticos por aplicaciones de mensajería (WhatsApp/SMS) y módulo de punto de venta (las exclusiones financieras y fiscales aplican conforme al Contrato Marco).

**4. Calendario, Garantía y Presupuesto**
*   **Plazo de Entrega:** **2 meses (60 días naturales)** para el despliegue e inicio de estabilización.
*   **Estabilización y Capacitación:** **10 días naturales** (que comprende el uso de todas las funcionalidades para el personal de recepción y administrador de LAESH, y acompañamiento para el despliegue en producción).
*   **Garantía:** **20 días naturales** para correcciones (efectivo tras liquidar el pago final).
*   **Inversión Total:** **$33,000.00 MXN (Netos)**.

| Hito de Facturación | Porcentaje | Monto a Pagar | Condición |
| :--- | :---: | :--- | :--- |
| **Pago 1: Anticipo** | 40% | $13,200.00 MXN (Netos) | A la firma del anexo, previo inicio. |
| **Pago 2: Pago Final** | 60% | $19,800.00 MXN (Netos) | Contra firma de Acta de Aceptación (Fin Estabilización). |

_______________________________
**FIRMA DE CONFORMIDAD - EL CLIENTE**
