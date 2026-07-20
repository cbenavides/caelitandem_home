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

**El Gap:** El cliente frecuentemente solicita que el sistema automatizado se conecte a los números de WhatsApp que la clínica "ya usa" para no perder a sus contactos. 

**El Riesgo Operativo:**
Migrar un número actual a la API Oficial de Meta **borra irreversiblemente todo el historial de chats** y desactiva el uso de la aplicación móvil (WhatsApp Business) en el teléfono físico. Si se opta por no usar la API Oficial y conectar el número actual a Chatwoot vía un puente no oficial (ej. escanear código QR con *Evolution API*), el desarrollador asume un riesgo inmenso de desconexiones constantes, fallas de sincronización y baneos masivos, esclavizándose a dar soporte técnico gratuito.

**La Regla Arquitectónica:**
*   Chatwoot operará **única y exclusivamente con un NUEVO número de teléfono** (chip dedicado) mediante la API Oficial de Meta. Este será el "Canal de Resultados Automatizados".
*   Las recepcionistas seguirán operando los números actuales de la clínica directamente desde sus celulares o en la pestaña de WhatsApp Web tradicional.
*   **Modus Operandi Híbrido:** La recepcionista abrirá dos pestañas en su PC: 1) Su WhatsApp Web tradicional (para platicar como siempre) y 2) La bandeja de Chatwoot (para interactuar en el nuevo canal donde el Notificador automatizado para WhatsApp envía las órdenes).

---

## 6. Análisis del Flujo Propuesto (Regla de 24 horas)

**Escenario de prueba:**
1. **El sistema envía imagen/orden (Plantilla VIP):** ¡Éxito! Llega perfecto al celular del paciente.
2. **El paciente NO contesta nada:** (El reloj de atención al cliente de 24 horas NUNCA se activa para la recepcionista).
3. **El recepcionista REQUIERE enviarle mensajes de horarios/indicaciones:** **¡BLOQUEADA! ❌** La recepcionista entra a Chatwoot, intenta teclear "Hola, recuerde venir en ayunas", da clic en enviar, y Chatwoot arroja un error: *"Fuera de la ventana de 24 horas"*. No puede enviarlo.
4. **El paciente nunca contesta el chat.**
5. **El paciente llama por Telcel o llamada de WhatsApp para aclarar dudas:** Las llamadas (celulares o de voz por la app) **NO** le avisan a Meta. Para Meta, el chat sigue muerto.
   * *¿Podrá el recepcionista enviar mensajes de texto tras la llamada?* **¡NO! ❌ Sigue bloqueada en Chatwoot.** Como no hubo un mensaje escrito/audio/sticker del paciente directo en el chat, Meta no abre la ventana.
6. **El paciente llega, hace estudios, paga:** (Físicamente en sucursal).
7. **El sistema envía resultados (Plantilla VIP):** ¡Éxito! Llega perfecto al mismo chat, porque el sistema sí tiene permisos VIP para saltar la regla de 24 hrs.

### ¿Cómo solucionar el Paso 3 (cuando la recepcionista a fuerza necesita escribirle)?
Si el paciente no escribe, la recepcionista tiene dos opciones operativas en la vida real:
*   **Opción A (El Puente Tradicional):** Agarra su WhatsApp Web viejo (el de los números actuales de la clínica, donde no hay reglas de 24 hrs ni API) y le escribe por ahí: *"Hola Juan, vimos que le mandaron su orden, recuerde venir en ayunas"*.
*   **Opción B (La Plantilla Manual):** En Chatwoot, en lugar de teclear texto libre, la recepcionista selecciona una **Plantilla pre-aprobada** (ej. una plantilla llamada `recordatorio_ayuno`). Eso sí la dejaría enviarlo desde el número nuevo automatizado, pero le costaría otros ~$0.15 MXN a la clínica por ser catalogado como mensaje de Utilidad Proactivo.

---

## 7. Otras Combinaciones Posibles (¿Cuándo SÍ puede hablar la recepcionista?)

**Combinación A: El paciente curioso (Flujo ideal)**
1. El sistema dispara la orden digital (Lunes 8:00 AM).
2. El paciente recibe la orden y escribe: *"¿A qué hora abren mañana?"* (Lunes 8:05 AM).
3. **¡BUM! VENTANA ABIERTA 🟢.** La recepcionista en Chatwoot tiene hasta el Martes a las 8:05 AM para escribirle **todo el texto libre que quiera**.
4. La recepcionista le manda audios, textos, indicaciones de ayuno, PDFs de promociones sin costo adicional.
5. Pasa 1 semana. El sistema dispara los resultados (El sistema siempre puede).

**Combinación B: El Botón Mágico (El truco ninja)**
1. El sistema dispara la orden, pero en el diseño del mensaje de WhatsApp (Template) le ponemos un botón interactivo abajo que diga: `[Ver Horarios y Requisitos]`.
2. El paciente, por simple curiosidad, **toca el botón**.
3. **¡BUM! VENTANA ABIERTA 🟢.** Tocar un botón cuenta para Meta como un mensaje enviado por el usuario. La recepcionista ya puede escribirle libremente en Chatwoot por 24 horas, aunque el paciente no haya tecleado ni una sola palabra.

**Combinación C: El paciente que reclama el resultado**
1. El paciente se hizo los estudios.
2. Pasan 3 días y el químico no ha subido el resultado (el sistema no ha mandado nada).
3. El paciente se desespera y escribe al chat: *"Oiga, ¿ya están mis estudios?"*.
4. **¡BUM! VENTANA ABIERTA 🟢.** La recepcionista en Chatwoot le contesta libremente: *"Una disculpa, en 1 hora quedan"*. 
5. Pasa 1 hora, el químico sube el PDF, y el sistema lo envía automáticamente (Template).

### Conclusión para el Cliente (Modelo Híbrido)
El número automatizado (API) es excelente para que el Laboratorio **notifique** (órdenes/resultados) y para que el paciente **pregunte**. Pero **NO SIRVE** para que la recepcionista ande persiguiendo o enviando mensajes proactivos de "texto libre" a pacientes mudos. Para perseguir pacientes o hacer labor de venta en frío, tendrán que seguir usando su WhatsApp tradicional en la pestaña independiente.

---

## 8. Riesgos y Gaps Operativos Estructurales (Gotchas)

La API Oficial de Meta es un ecosistema estrictamente controlado. Más allá de la ventana de 24 horas, se deben contemplar los siguientes 4 bloqueos sistémicos:

**Gap 1: El límite de envíos diarios (El "Tier 1" de Meta)**
*   **El Problema:** Un número nuevo en la API **no verificado comercialmente** solo tiene permiso de iniciar **250 conversaciones proactivas por día**. Si el laboratorio atiende a 300 pacientes un lunes, el paciente número 251 ya no va a recibir su orden ni su resultado ese día; el sistema fallará en silencio.
*   **La Solución:** Exigir la Constancia Fiscal de inmediato. Al verificar el negocio (Business Verification), Meta sube el límite a **1,000 mensajes diarios**, luego a 10,000 y así sucesivamente.

**Gap 2: El Riesgo de Baneo por "Calidad de Cuenta" (Anti-Spam de Usuario)**
*   **El Problema:** Si la clínica decide empezar a mandar publicidad agresiva o mensajes que el paciente no solicitó mediante plantillas manuales, los pacientes oprimirán el botón de **"Bloquear y Reportar"** en su celular.
*   **Consecuencia:** Meta mide la "Calidad del Número" (Verde, Amarillo, Rojo). Si muchos pacientes bloquean el número, Meta lo pone en Rojo y reduce tu límite de envíos, o en el peor escenario, **suspende el número permanentemente**.
*   **La Solución:** Asegurarle al cliente que el canal es *estrictamente transaccional* y de servicio. No debe usarse para marketing invasivo en frío.

**Gap 3: Las Plantillas deben ser Aprobadas (El Tono)**
*   **El Problema:** No se puede programar el sistema para que mande el texto que la clínica quiera inventar en ese instante. El texto base que acompaña a la imagen del resultado (Ej. *"Hola {{1}}, adjunto tus resultados del folio {{2}}."*) debe enviarse a Meta para su revisión y aprobación.
*   **Consecuencia:** Si la clínica pide cambiar la plantilla para que diga *"Hola, aquí están tus resultados. ¡Aprovecha 20% de descuento en Rayos X!"*, Meta la reclasificará de "Utilidad" a "Marketing". Las plantillas de Marketing cuestan casi el triple (~$0.80 MXN) que las de utilidad, y si se abusa o no se solicitan los *opt-in* (permisos), Meta las rechaza.

**Gap 4: El "Agujero Negro" de los Archivos Multimedia**
*   **El Problema:** Al enviar una imagen o PDF mediante la API, Meta impone límites estrictos de peso (usualmente 5MB para imágenes y 100MB para documentos de texto plano, pero procesar multimedia muy pesada alenta la API).
*   **Consecuencia:** Si el químico genera un PDF escaneado a máxima resolución que pesa 12MB y el backend intenta convertirlo a imagen o enviarlo crudo sin optimización, la API de Meta rebotará el payload (TimeOut o Entity Too Large) y el paciente nunca se enterará de que sus resultados estaban listos.
*   **La Solución:** El backend debe comprimir y sanitizar (reducir DPIs) los archivos fuertemente antes de inyectarlos a los servidores de Meta.

### Resumen de Robustez Obligatoria (Para el Backend)
Ante todos estos bloqueos invisibles, el sistema backend debe ser extremadamente robusto. Debe guardar un "Log" (bitácora) interno de cada intento de envío. Si Meta devuelve un error diciendo *"Usuario fuera de ventana"*, *"Límite diario excedido"*, o *"Plantilla rechazada"*, tu sistema deberá capturar ese webhook y **avisarle a la recepcionista en una pantalla/dashboard interno**: *"⚠️ El resultado del paciente Juan Pérez NO se pudo entregar por WhatsApp"*, para que ella se entere y proceda a resolverlo "a la antigua" enviándolo manualmente desde el teléfono tradicional.

---

## 9. Resolviendo Dudas Estratégicas y Operativas (FAQ Cliente)

A continuación, se documentan las respuestas oficiales a las inquietudes más comunes respecto a la transición hacia el nuevo modelo automatizado:

**1. Para los pacientes (referidos y NO referidos), ¿los resultados serán enviados con el nuevo número?**
**Sí, es correcto.** Si el cliente opta por el Paquete Integral (Opción 4), el Sistema Bloc Digital procesará *todos* los PDFs que genere el laboratorio. No hará distinción si el paciente llegó por un médico tratante del Bloc Digital o si llegó directamente caminando al mostrador; el sistema leerá el PDF, lo convertirá a imagen y lo enviará por el **nuevo número automatizado** a todos por igual.

**2. ¿Gradualmente los clientes actuales irán haciendo contacto/conversación con el nuevo número?**
**Sí, es el efecto natural.** Como el paciente va a recibir su orden médica inicial y sus resultados finales desde este nuevo número, es altamente probable que si tiene una duda (ej. *"¿tengo que ir en ayunas?"* o *"¿me pueden explicar este valor del estudio?"*), responda directamente ahí. Orgánicamente, el nuevo número se irá convirtiendo en el canal principal de atención de la clínica.

**3. ¿Qué va a pasar si el paciente envía un mensaje mucho tiempo después? ¿Hay gaps?**
**No hay gaps, funciona a favor de la clínica.** Si un paciente escribe 3 meses después diciendo *"Hola, ¿a qué hora abren mañana?"*, ese mensaje es **iniciado por el usuario (Inbound)**. En el instante en que el paciente manda ese mensaje, Meta **abre automáticamente una Ventana de Servicio de 24 horas**. Durante esas 24 horas, la recepcionista (desde Chatwoot) podrá contestarle de forma libre, sin plantillas y sin bloqueos. El único bloqueo de Meta ocurre cuando *la clínica* quiere iniciar la conversación de la nada después de 24 horas de inactividad.

**4. Con el tiempo, ¿se va a llegar a usar más Chatwoot con los números nuevos que el WhatsApp Web actual?**
**Definitivamente sí.** Al estar automatizado, el volumen de mensajes salientes (órdenes y resultados) por el nuevo número será masivo. La atención al cliente migrará naturalmente a Chatwoot.
*Nota de arquitectura:* No es posible conectar sus números "viejos/actuales" a Chatwoot a menos que también los migren a la API oficial (lo cual borraría todo su historial y grupos, algo que no recomendamos). Por lo tanto, mantendrán el WhatsApp Web viejo para doctores o proveedores antiguos, pero el Chatwoot (nuevo número) absorberá el 90% del tráfico de pacientes.

**5. ¿Los nuevos SIMs pueden ser de prepago o exigen plan forzoso?**
**Pueden ser de prepago (Ej. un chip Telcel/Movistar de $50 pesos de la tienda).** Meta no exige planes de datos. La API de WhatsApp solo necesita que el número físico exista y pueda **recibir un SMS o llamada de voz una sola vez** para ingresar el código de verificación de 6 dígitos. Una vez verificado y conectado al servidor, el chip físico lo pueden guardar en un cajón. 
*(Recomendación:* Solo deben hacerle una recarga de $50 pesos cada 3 o 4 meses para que la telefónica no dé de baja la línea por inactividad).

**6. Sobre la cuenta de Facebook y la contratación de Meta API.**
Un perfil personal estándar de Facebook no puede contratar la API de forma directa. El procedimiento normado es:
1. Usar el perfil personal del dueño para crear una **Página de Empresa (Fanpage)** para el laboratorio (si es que aún no la tienen).
2. Crear un **Meta Business Manager** (Administrador Comercial) a nombre del laboratorio, designando al perfil del dueño como administrador.
3. Vincular el **nuevo chip de prepago** a ese Business Manager. 

**Lo más adecuado y seguro:** **NUNCA usar el número actual de la clínica para la API.** Si migran el número actual a la API Cloud, se cerrará su aplicación normal de WhatsApp Business, perderán todo el historial de chats con médicos y se saldrán automáticamente de todos los grupos. **Siempre debe usarse un chip nuevo y exclusivo para el Bloc Digital.**

---
*Documento generado como Anexo Técnico Interno para el despliegue y análisis continuo de la API Oficial de Meta.*
