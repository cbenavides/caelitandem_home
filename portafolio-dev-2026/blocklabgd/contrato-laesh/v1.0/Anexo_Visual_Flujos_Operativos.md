<style>
@media print {
  @page { size: legal landscape; margin: 20mm; }
  body { text-align: center; margin: 0; padding: 0; }
}
body { 
  text-align: center; 
}
img { 
  max-width: 100%; 
  max-height: 70vh; /* Se asegura de que la imagen quepa junto con los textos */
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
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este diagrama expresa el flujo inicial de captación. Ilustra cómo el Médico Tratante emite la orden de estudios y cómo interactúa el sistema en la nube para procesarla y hacerle llegar al Paciente su solicitud digital por WhatsApp, atrayéndolo hacia el laboratorio.</p>
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
          • <strong>Cero Errores:</strong> Elimina la mala letra en recetas de papel.<br>
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
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este diagrama muestra la llegada del paciente a la clínica y la interacción física en mostrador. Describe cómo el personal de Recepción localiza la orden (previamente capturada por el doctor) para agilizar la toma de muestras y el cobro.</p>
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
          • <strong>Información al Médico:</strong> El doctor sabe al instante que su paciente ya llegó a la clínica.
        </td>
      </tr>
    </table>
  </div>

</div>

<div style="page-break-before: always; clear: both;"></div>

<div class="diagram-wrapper">
  <h3>Diagrama 3: Automatización y Entrega de Resultados</h3>
  <img src="./diagramas1.0/Diagrama_3_Resultados_HD.png" alt="Diagrama 3" />
  
  <br><br><br>
  <div style="margin-top: 30px; padding: 15px; text-align: left; background-color: #f9f9f9; border-radius: 8px;">
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este diagrama ilustra el potente ciclo de salida de los resultados y el modelo omnicanal híbrido. Expone cómo el Químico deposita el PDF final y cómo el ecosistema automatizado lo lee y distribuye instantáneamente al portal web y al WhatsApp del paciente.</p>
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
