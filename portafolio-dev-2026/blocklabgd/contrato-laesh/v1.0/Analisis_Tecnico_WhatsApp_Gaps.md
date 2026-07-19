# Análisis Técnico y Resolución de Gaps: WhatsApp Cloud API & Meta Business

Este documento sirve como bitácora interna y *runbook* técnico para el desarrollador respecto a la integración de la API Oficial de WhatsApp (Meta) con el ecosistema de LAESH. Documenta los hallazgos, bloqueos potenciales y resoluciones arquitectónicas/legales definidos durante la estructuración contractual.

---

## 1. Verificación de Dominio en Meta (Sin depender de correos corporativos)

**El Gap:** Meta exige comprobar la propiedad del dominio web de la clínica (`laesh.mx`) para habilitar la API de WhatsApp. Típicamente, esto se hace recibiendo un PIN en un correo del mismo dominio (ej. `admin@laesh.mx`), lo cual obligaría al desarrollador a montar o contratar un servidor de correos solo para este trámite.

**La Solución (Vía DNS):**
Se elimina la necesidad de buzones de correo utilizando la verificación por **Registro TXT**.
*   **Procedimiento:** Dentro del *Meta Business Manager*, al agregar el dominio de la clínica, se seleccionará la opción de "Actualizar el registro TXT del DNS". Meta generará un código único.
*   **Ejecución:** El desarrollador ingresará al panel de DNS en **Hostinger** y creará un registro tipo `TXT` en la raíz del dominio con el código de Meta.
*   **Ventaja:** Verificación instantánea sin costo extra, alineándose con la cláusula contractual que excluye la provisión de cuentas de correo a empleados.

---

## 2. Restricción de Titularidad (Por qué evitar el "Whitelabel" en Meta)

**El Gap:** El cliente puede mostrar resistencia a involucrarse administrativamente y solicitar que el desarrollador registre la API de WhatsApp bajo el nombre y tarjeta de crédito de la agencia de software ("Marca Blanca" o "Whitelabel").

**El Bloqueo (Políticas de Meta):**
Meta aplica políticas estrictas contra la suplantación de identidad (Impersonation). El **Display Name** (Nombre visible en WhatsApp) debe coincidir obligatoriamente con la entidad legal verificada en el Business Manager. Si la cuenta se verifica con el RFC/Constancia de la agencia de software, Meta rechazará el nombre "Laboratorios LAESH". Un rechazo repetido por esta discrepancia puede llevar al baneo permanente del número telefónico.

**La Solución Legal/Operativa:**
*   La cuenta de Meta Business, la línea telefónica oficial y el método de pago deben registrarse obligatoriamente con la **Constancia de Situación Fiscal de LAESH**.
*   **Argumento de Venta (Privacidad):** Se debe argumentar al cliente que, por regulaciones del INAI (manejo de datos sensibles de salud), la clínica debe ser la dueña legal y exclusiva del canal por donde transitan los resultados médicos para protegerse de responsabilidades.
*   *Upsell Opcional:* El desarrollador puede fungir como "Gestor" (maniobrar la plataforma a nombre del cliente cobrando un honorario), pero usando los documentos del cliente.

---

## 3. Validez de Certificados SSL (Let's Encrypt vs. Comercial)

**El Gap:** Duda sobre si usar certificados SSL gratuitos de Let's Encrypt en el VPS de Hostinger representa un riesgo de rechazo por parte de los crawlers de Meta durante la validación del negocio.

**La Resolución:**
*   Meta y Google no discriminan el origen comercial de un certificado SSL. Su único requisito es que la conexión esté cifrada de extremo a extremo (HTTPS) y no presente advertencias de navegador.
*   **Let's Encrypt** es el estándar global aceptado. La configuración automatizada mediante `Certbot` en el servidor (renovación cada 90 días) es completamente válida y segura.
*   No es necesario que el cliente adquiera un certificado de validación extendida (EV) o de paga.

---

## 4. Requisito de "Landing Page" para Aprobación en Meta

**El Gap:** Si el cliente opta por adquirir únicamente el "Bloc Digital" (Opción 3), no se contempla el desarrollo de un sitio web público. Sin embargo, Meta exige que toda empresa verificada tenga un sitio web en vivo que demuestre su existencia comercial para aprobar el uso de la API de WhatsApp.

**La Solución (Contingencia Técnica):**
*   Si el dominio no tiene contenido público, el desarrollador deberá levantar una **Landing Page temporal/básica** en la raíz del dominio (`https://laesh.mx`) que contenga mínimamente: el logotipo de LAESH, el nombre comercial exacto, dirección física, y métodos de contacto.
*   Esta página no tiene costo adicional, pero es un **bloqueador crítico**; sin ella, Meta denegará el Business Manager. (Este punto ya quedó debidamente acotado en los contratos para proteger los tiempos de entrega).

---

## 5. Aislamiento de Números (API Oficial vs Uso Diario)

**El Gap:** El cliente frecuentemente solicita que el bot/sistema se conecte a los números de WhatsApp que la clínica "ya usa" para no perder a sus contactos. 

**El Riesgo Operativo:**
Migrar un número actual a la API Oficial de Meta **borra irreversiblemente todo el historial de chats** y desactiva el uso de la aplicación móvil (WhatsApp Business) en el teléfono físico. Si se opta por no usar la API Oficial y conectar el número actual a Chatwoot vía un puente no oficial (ej. escanear código QR con *Evolution API*), el desarrollador asume un riesgo inmenso de desconexiones constantes, fallas de sincronización y baneos masivos, esclavizándose a dar soporte técnico gratuito.

**La Regla Arquitectónica:**
*   Chatwoot operará **única y exclusivamente con un NUEVO número de teléfono** (chip dedicado) mediante la API Oficial de Meta. Este será el "Canal de Resultados Automatizados".
*   Las recepcionistas seguirán operando los números actuales de la clínica directamente desde sus celulares o en la pestaña de WhatsApp Web tradicional.
*   **Modus Operandi Híbrido:** La recepcionista abrirá dos pestañas en su PC: 1) Su WhatsApp Web tradicional (para platicar como siempre) y 2) La bandeja de Chatwoot (para interactuar en el nuevo canal donde el bot manda los folios).

---
*Documento generado como Anexo Técnico Interno para el despliegue.*
