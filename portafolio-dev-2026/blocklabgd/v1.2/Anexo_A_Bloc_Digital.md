# ANEXO A — ALCANCE DEL PROYECTO
## Proyecto 2: Bloc Digital via Internet

Parte integrante del Contrato de Prestación de Servicios Profesionales.

**1. Descripción y Fases del Sistema**

"EL SISTEMA" es una aplicación web privada hospedada en `laesh.mx` que digitaliza la emisión, seguimiento y entrega de solicitudes de estudio de laboratorio clínico, optimizando la operación diaria sin depender de redes sociales. 

El proyecto contempla las siguientes fases de desarrollo: Análisis, Diseño de Interfaces, Desarrollo, Pruebas Integrales, Despliegue en Servidor, Estabilización en Vivo, y Firma de Acta de Aceptación (los plazos correspondientes y los periodos de garantía se definen en la Sección 4).

**2. Módulos y Flujo Operativo (Alcance Exacto)**

*   **Gestión de Sesiones y Seguridad:** Inicio y cierre de sesión (login/logout) exclusivo para médicos y personal de recepción. Incluye la opción de cambio de contraseña (requiriendo la contraseña actual y doble verificación de la nueva contraseña).  
    *Fuera de alcance:* Se excluye la recuperación automatizada de contraseña ("olvidé mi contraseña"). En su lugar, se implementará el reseteo manual de contraseñas de médicos por parte del perfil de Recepción/Administrador.

*   **Catálogo de Estudios:** Panel administrable que permite el alta, edición e inactivación de estudios de laboratorio clínico. Incluye la carga inicial de datos vía un archivo de hoja de cálculo (Excel) provisto por LAESH.

*   **Configuraciones Globales:** Pantalla especial para el Administrador que permite parametrizar hasta 6 valores generales del comportamiento del sistema (por ejemplo, el tiempo de caducidad/rotación automática de las solicitudes inactivas, configurado por defecto a 30 días).

*   **Portal Médico (Captura de Órdenes):** Permite al médico crear órdenes digitales desde la dirección web `laesh.mx/medicos`. Al crearse, la orden inicia en estado **Remitido**.  
    El sistema permite generar e imprimir una hoja PDF con el formato que se diseñe en colaboración entre el cliente y el prestador. Este documento podrá incluir el logotipo de LAESH, el número de folio único asignado por el sistema, entre otros datos.

*   **Notificación a Recepción (Audio y Enlace):** Al momento exacto en que un médico crea una orden, la interfaz de recepción `laesh.mx/labadmin` recibe una burbuja de aviso ("globito") visual instantánea, acompañada de un **pitido de silbato exclusivo** y un enlace de acceso directo para consultar o descargar el archivo de la orden.

*   **Recepción y Búsqueda de Pacientes:** El personal de recepción podrá buscar y localizar pacientes por folio o nombre (mediante autocompletado con un mínimo de 5 caracteres de precisión) para actualizar su estado a **En Atención**.  
    Se incluye también una opción de búsqueda histórica y retroactiva que permite consultar y re-imprimir cualquier folio u orden generada en el pasado, independientemente de que ya se encuentre en estado "Cerrado".

*   **Carga de Resultados (Cambio Automático de Estado):** Al concluir los estudios correspondientes, el personal de recepción carga el archivo de resultados clínicos en formato PDF en el sistema, lo cual cambia de manera automática el estado de la solicitud a **Resultados Listos**.

*   **Notificación al Médico (Silenciosa):** Al cambiar la orden al estado de resultados listos, el médico emisor recibe una notificación visual silenciosa en su panel con un enlace de descarga directa de los resultados adjuntos.

*   **Entrega de Resultados y Cierre:** Impresión y entrega física de los resultados al paciente en la ventanilla de recepción. El estado de la orden cambia a **Cerrada** (ya sea manualmente por el operador o mediante el proceso automático de caducidad y rotación del sistema).

*   **Disponibilidad Permanente de Documentos:** Todos los documentos vinculados a la solicitud (orden médica original y resultados clínicos adjuntos) estarán disponibles permanentemente como PDF para su consulta y descarga tanto por el médico emisor como por el personal de recepción.

*   **Módulo de Reportes Operativos:** Reporte de estadísticas operativas básicas del flujo de órdenes (cantidad de órdenes emitidas, tiempos promedio de atención, estados de folios), sin incluir cálculos financieros, costos, ni administración de honorarios médicos.

*   **Gestión de Usuarios y Panel del Sitio Web:** Perfiles de seguridad definidos (Médico, Recepción, Administrador) con capacidad de creación y eliminación de usuarios. El médico puede actualizar sus datos de perfil, mas no auto-eliminarse.  
    Desde el portal de recepción se actualizan de manera instantánea las secciones del sitio público `laesh.mx` (Promociones, Consultas, Banner y Membresías). *Nota: Esta última funcionalidad de actualización web pertenece técnicamente al alcance del Proyecto 1.*

**3. Tecnología, Infraestructura y Exclusiones**

*   **Tecnología de Desarrollo:** Lenguajes web y bases de datos relacionales estándar con un servidor dedicado de notificaciones instantáneas (websockets/polling de alta respuesta). Entorno 100% web privado e independiente.

*   **Infraestructura Requerida:** Requiere la contratación de un Servidor Privado Virtual (VPS) y un Nombre de Dominio `.mx` bajo la administración y costo de "EL CLIENTE" (los pagos a terceros aplican conforme al Contrato Marco). Incluye la retención del historial operativo en base de datos por un periodo de 5 años.

*   **Adaptabilidad de Pantallas:** Interfaces optimizadas y 100% responsivas para computadoras de escritorio (Portal de Recepción) y teléfonos móviles (Portal Médico), sujetas a las especificaciones de resolución (1280px a 4K) y restricciones tecnológicas (sin soporte a tabletas ni Apps/PWAs) definidas en la Cláusula Segunda del Contrato Marco.

*   **Fuera de Alcance:** Envíos automatizados por aplicaciones de mensajería (WhatsApp/SMS) y módulo de punto de venta de caja (las exclusiones financieras, pasarelas de pago y obligaciones fiscales aplican conforme al Contrato Marco).

**4. Calendario, Garantía y Presupuesto**

*   **Plazo de Entrega y Despliegue:** Se establece un periodo de **2 meses (60 días naturales)** para el desarrollo, despliegue en servidor de producción e inicio del Periodo de Estabilización.

*   **Estabilización y Capacitación:** Un periodo de **10 días naturales** para el entrenamiento del personal de recepción y administración de LAESH en el uso diario de la plataforma, así como el acompañamiento técnico continuo durante el despliegue inicial.

*   **Periodo de Garantía:** Un plazo de **20 días naturales** para reportes y correcciones de defectos de programación, entrando en vigor inmediatamente tras la firma del Acta de Aceptación y una vez liquidado el saldo final del proyecto.

*   **Inversión Total del Proyecto:** El costo total del desarrollo es de **$33,000.00 MXN (Netos)**.

| Hito de Facturación | Porcentaje | Monto a Pagar | Condición |
| :--- | :---: | :--- | :--- |
| **Pago 1: Anticipo** | 40% | $13,200.00 MXN (Netos) | A la firma del anexo, previo inicio de actividades. |
| **Pago 2: Pago Final** | 60% | $19,800.00 MXN (Netos) | Contra firma de Acta de Aceptación (Fin Estabilización). |

<br>

_______________________________
**EL PRESTADOR** — CARLOS MARCELO BENAVIDES MARTÍNEZ

_______________________________
**EL CLIENTE** — [NOMBRE O RAZÓN SOCIAL]  
**Firma del Representante Legal:** [NOMBRE DEL REPRESENTANTE LEGAL]
