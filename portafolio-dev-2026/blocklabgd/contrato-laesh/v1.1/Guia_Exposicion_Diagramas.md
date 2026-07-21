# Guía de Exposición: Flujos Operativos LAESH
**Proyecto: Laboratorio Clínico LAESH - Digitalización**

---

### 1. Diagrama 1: Emisión de la Orden y Atracción (Flujo Inicial)

**Contexto:** Ilustra cómo el **Médico Tratante** emite la orden de estudios desde su PC o celular. El **Sistema Bloc Digital** la procesa en la nube generando un Folio único, y notifica al **Paciente** su Orden clínica digital en imagen vía **WhatsApp API Cloud**, atrayéndolo hacia el laboratorio.

| 📖 Instrucciones de Lectura | 💎 Puntos de Valor del Flujo |
| :--- | :--- |
| • Se lee de arriba hacia abajo, siguiendo la numeración.<br>• Las líneas sólidas representan envíos de datos directos.<br>• Las líneas punteadas representan confirmaciones del Notificador Automatizado. | • **Menos Errores:** Evita la mala letra de recetas en papel; el médico captura directamente.<br>• **Atracción:** El paciente recibe la orden formal con marca del laboratorio en su WhatsApp.<br>• **Trazabilidad:** Genera un Folio único que vincula al Médico, Paciente y estudios. |

---

### 2. Diagrama 3: Automatización y Entrega de Resultados (Cierre de Ciclo)

**Contexto:** El Químico deposita el PDF de resultados en una carpeta segura. El **Sistema Bloc Digital** lo detecta, lo vincula al expediente por Folio, lo convierte a imagen y lo envía al Paciente vía **WhatsApp API Cloud**. La Recepcionista atiende dudas en tiempo real desde **Chatwoot** sin interrumpir el proceso de envío. El **WhatsApp Stopper** monitorea el consumo financiero.

| 📖 Instrucciones de Lectura | 💎 Puntos de Valor del Flujo |
| :--- | :--- |
| • Siga los pasos numerados de arriba hacia abajo.<br>• El Sistema Bloc Digital actúa como orquestador central (pasos 4 al 7).<br>• Identifique al actor "Recepcionista (Chatwoot)" resolviendo dudas en tiempo real. | • **Automatización Total:** Recepción ya no adjunta PDFs ni envía mensajes; el Notificador Automatizado lo hace en segundos.<br>• **Modelo Híbrido:** Si el paciente responde, se atiende en Chatwoot manteniendo la calidez humana.<br>• **Accesibilidad:** Portal histórico de resultados 24/7. |
