# Análisis Técnico y Limitantes Operativas: WhatsApp Cloud API

Este documento consolida el análisis de flujos de interacción, bloqueos de ventanas de servicio y riesgos operativos ("gaps") detectados al utilizar la API Oficial de WhatsApp Cloud en conjunción con agentes humanos (Chatwoot) y envíos automatizados para el entorno clínico.

---

## 1. Análisis del Flujo Propuesto (Caso Crítico)

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

## 2. Otras Combinaciones Posibles (¿Cuándo SÍ puede hablar la recepcionista?)

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

## 3. Riesgos y Gaps Operativos Estructurales (Gotchas)

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
