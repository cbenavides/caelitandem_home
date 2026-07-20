<style>
@page {
  size: legal landscape;
  margin: 15mm;
}
@media print {
  body { text-align: center; margin: 0; padding: 0; }
  img { max-height: 80vh !important; }
}
body { 
  text-align: center; 
}
img { 
  max-width: 100%; 
  max-height: 85vh; /* Ajustado para que la imagen se vea mucho más grande */
  height: auto; 
  margin: 0 auto; 
  display: block; 
}
h1, h3 { 
  text-align: center; 
  margin-top: 0;
  margin-bottom: 10px;
  font-family: Arial, sans-serif;
  page-break-after: avoid;
}
.diagram-wrapper {
  page-break-inside: avoid;
  padding-bottom: 20px;
}
</style>

<div class="diagram-wrapper">
  <h1>ANEXO VISUAL: Flujo Operativo y Secuencia (Opción 4)</h1>
  <h3>Diagrama 1: Emisión de la Orden y Atracción</h3>
  <img src="./diagramas1.0/Diagrama_1_Emision_HD.png" alt="Diagrama 1" />
  
  <br><br><br>
  <div style="margin-top: 30px; padding: 15px; text-align: left; background-color: #f9f9f9; border-radius: 8px;">
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este diagrama expresa el flujo inicial de captación. Ilustra cómo el Médico Tratante emite la orden de estudios y cómo interactúa el sistema en la nube para procesarla y hacerle llegar al Paciente su Orden clínica digital en imagen por WhatsApp, atrayéndolo hacia el laboratorio.</p>
    <table style="width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; font-size: 14px;">
      <tr>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>📖 Instrucciones de Lectura</strong><br><br>
          • El diagrama se lee cronológicamente de arriba hacia abajo, siguiendo los pasos numerados (1, 2, 3...).<br>
          • Las líneas sólidas representan envíos de información.<br>
          • Las líneas punteadas representan confirmaciones del sistema.
        </td>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>💎 Puntos de Valor del Flujo</strong><br><br>
          • <strong>Menos Errores:</strong> Mitiga la mala letra en recetas de papel.<br>
          • <strong>Atracción:</strong> El paciente recibe una solicitud formal con la marca del laboratorio en su celular.<br>
          • <strong>Trazabilidad:</strong> Genera un Folio único desde el primer instante.
        </td>
      </tr>
    </table>
  </div>

</div>

<div style="page-break-before: always; clear: both;"></div>

<div class="diagram-wrapper">
  <h3>Diagrama 2: Operación en Recepción</h3>
  <img src="./diagramas1.0/Diagrama_2_Recepcion_HD.png" alt="Diagrama 2" />
  
  <br><br><br>
  <div style="margin-top: 30px; padding: 15px; text-align: left; background-color: #f9f9f9; border-radius: 8px;">
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este diagrama muestra la llegada del paciente a la clínica y la interacción física en mostrador. Describe cómo el personal de Recepción localiza la orden (previamente capturada por el médico tratante) para agilizar la toma de muestras y el cobro.</p>
    <table style="width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; font-size: 14px;">
      <tr>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>📖 Instrucciones de Lectura</strong><br><br>
          • Siga la numeración del 1 al 4, de arriba hacia abajo.<br>
          • Identifique al Paciente entregando la solicitud y a la Recepcionista validando el Folio en el sistema.<br>
          • Observe cómo Recepción hace el puente de datos hacia el Laboratorio.
        </td>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>💎 Puntos de Valor del Flujo</strong><br><br>
          • <strong>Velocidad en Mostrador:</strong> Evita volver a teclear todos los estudios del paciente; todo ya viene pre-cargado.<br>
          • <strong>Fluidez Operativa:</strong> Transición transparente hacia su software de caja/LIS existente.<br>
          • <strong>Información al Médico:</strong> El médico tratante sabe al instante que su paciente ya llegó a la clínica.
        </td>
      </tr>
    </table>
  </div>

</div>

<div style="page-break-before: always; clear: both;"></div>

<div class="diagram-wrapper" style="margin-top: -100px;">
  <h3 style="margin-top: 0; padding-top: 0;">Diagrama 3: Automatización y Entrega de Resultados</h3>
  <img src="./diagramas1.0/Diagrama_3_Resultados_HD.png" alt="Diagrama 3" style="margin-top: 20px;" />
  <br><br>
  <div style="margin-top: 0; padding: 15px; text-align: left; background-color: #f9f9f9; border-radius: 8px;">
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este diagrama ilustra el potente ciclo de salida de los resultados y el modelo omnicanal híbrido. Expone cómo el Químico deposita el PDF final y cómo el Notificador automatizado para WhatsApp lo lee y distribuye instantáneamente al portal web y al celular del paciente.</p>
    <table style="width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; font-size: 14px;">
      <tr>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>📖 Instrucciones de Lectura</strong><br><br>
          • Siga los pasos numerados de arriba hacia abajo y de izquierda a derecha.<br>
          • Note cómo el Sistema Bloc Digital funge como orquestador central (pasos 4, 5, 6 y 7).<br>
          • Observe al actor "Recepcionista (Chatwoot / WhatsApp Web)" atendiendo las respuestas manuales.
        </td>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>💎 Puntos de Valor del Flujo</strong><br><br>
          • <strong>Automatización Total:</strong> La recepcionista ya no necesita adjuntar manualmente PDFs ni enviar mensajes a los pacientes.<br>
          • <strong>Omnicanalidad:</strong> Si el paciente tiene una duda, responde al mismo chat y la recepcionista le atiende con el calor humano de siempre.<br>
          • <strong>Accesibilidad Remota:</strong> Portal histórico disponible 24/7.
        </td>
      </tr>
    </table>
  </div>

</div>

<div style="page-break-before: always; clear: both;"></div>

<div class="diagram-wrapper">
  <h1>ANEXO VISUAL: Casos de Uso de la Bandeja Omnicanal (Reglas de Meta)</h1>
  <p style="text-align: left; font-family: Arial, sans-serif; font-size: 14px; margin-bottom: 20px;">
    Los siguientes diagramas ilustran cómo operan las políticas Anti-Spam de Meta (Regla de la Ventana de 24 horas). El Notificador automatizado para WhatsApp puede enviar <strong>notificaciones (plantillas)</strong> en cualquier momento, pero el personal humano (Recepción) solo puede responder con <strong>texto libre</strong> si el paciente realiza una interacción (abre la ventana).
  </p>
</div>

<div style="page-break-before: always; clear: both;"></div>
<div class="diagram-wrapper">
  <h3>Flujo 1: Interacción por Consulta Directa</h3>
  <img src="./diagramas1.0/Diagrama_4_Flujo1_HD.png" alt="Flujo 1" />
  
  <div style="margin-top: 15px; padding: 15px; text-align: left; background-color: #f9f9f9; border-radius: 8px;">
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este diagrama ilustra cómo el paciente, al tener una duda, inicia de forma orgánica una conversación, lo que permite a Recepción atenderle libremente gracias a la apertura de la ventana de 24 horas.</p>
    <table style="width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; font-size: 14px;">
      <tr>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>📖 Instrucciones de Lectura</strong><br><br>
          • Siga la cronología de arriba hacia abajo (pasos 1 a 4).<br>
          • La nota verde (🟢) indica el momento exacto en que las reglas de Meta permiten el texto libre.<br>
          • Observe cómo la recepcionista puede enviar promociones y audios solo después de esa apertura.
        </td>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>💎 Puntos de Valor del Flujo</strong><br><br>
          • <strong>Atención Orgánica:</strong> El paciente no percibe un bot rígido; recibe ayuda humana cuando la necesita.<br>
          • <strong>Ventana Extendida:</strong> Se cuenta con 24 horas para resolver cualquier incidencia sin costo adicional en envíos.
        </td>
      </tr>
    </table>
  </div>
</div>

<div style="page-break-before: always; clear: both;"></div>
<div class="diagram-wrapper">
  <h3>Flujo 2: Interacción por Botón de Acción (Mitigación)</h3>
  <img src="./diagramas1.0/Diagrama_5_Flujo2_HD.png" alt="Flujo 2" />
  
  <div style="margin-top: 15px; padding: 15px; text-align: left; background-color: #f9f9f9; border-radius: 8px;">
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Ante las políticas anti-spam, este diagrama muestra una táctica de mitigación usando un "Botón Mágico" en la plantilla. Si el paciente toca el botón por curiosidad, Meta lo registra como interacción, liberando el chat.</p>
    <table style="width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; font-size: 14px;">
      <tr>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>📖 Instrucciones de Lectura</strong><br><br>
          • Identifique el primer envío (1) que contiene el botón.<br>
          • Vea el paso (2) donde la simple acción de oprimir el botón detona la nota verde (🟢).<br>
          • Esto habilita el paso (3) para atención humana.
        </td>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>💎 Puntos de Valor del Flujo</strong><br><br>
          • <strong>Desbloqueo Estratégico:</strong> Permite "enganchar" al paciente para que inicie la conversación.<br>
          • <strong>Protección:</strong> Previene que la clínica intente enviar texto libre y sea bloqueada por el sistema.
        </td>
      </tr>
    </table>
  </div>
</div>

<div style="page-break-before: always; clear: both;"></div>
<div class="diagram-wrapper">
  <h3>Flujo 3: Interacción por Seguimiento (Paciente Inicia)</h3>
  <img src="./diagramas1.0/Diagrama_6_Flujo3_HD.png" alt="Flujo 3" />
  
  <div style="margin-top: 15px; padding: 15px; text-align: left; background-color: #f9f9f9; border-radius: 8px;">
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este caso de uso refleja a un paciente que, días o incluso meses después de haber asistido a la clínica (y con la ventana ya cerrada), escribe por iniciativa propia para reclamar o preguntar. Esta acción revive la conversación y permite a la recepcionista atenderle desde Chatwoot.</p>
    <table style="width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; font-size: 14px;">
      <tr>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>📖 Instrucciones de Lectura</strong><br><br>
          • Observe el paso (1) donde el paciente rompe el silencio tras días o meses.<br>
          • Esto abre inmediatamente la ventana de servicio (🟢) para que la recepcionista opere desde Chatwoot.<br>
          • Note que el Notificador automatizado (paso 3) puede enviar la plantilla oficial independiente del estado de la ventana.
        </td>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>💎 Puntos de Valor del Flujo</strong><br><br>
          • <strong>Flexibilidad Asíncrona:</strong> El paciente siempre tiene la línea abierta para hacer exigencias.<br>
          • <strong>Sin Fricción:</strong> Las respuestas de Recepción (2) se intercalan perfectamente con las notificaciones del Sistema (3).
        </td>
      </tr>
    </table>
  </div>
</div>
