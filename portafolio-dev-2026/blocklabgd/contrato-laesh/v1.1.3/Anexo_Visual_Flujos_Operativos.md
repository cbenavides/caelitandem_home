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
  max-height: 85vh;
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
.nota-contractual {
  margin: 10px 0 20px 0;
  padding: 10px 15px;
  background-color: #e3f2fd;
  border-left: 4px solid #1e88e5;
  text-align: left;
  font-family: Arial, sans-serif;
  font-size: 13px;
  border-radius: 4px;
}
</style>

<div class="diagram-wrapper">
  <h1>ANEXO VISUAL: Flujo Operativo y Secuencia — Proyecto 2: Bloc Digital via Internet</h1>

  <div class="nota-contractual">
    <strong>📌 Nota de Aplicabilidad:</strong> Los flujos descritos en este documento corresponden íntegramente al <strong>Proyecto 2 — Bloc Digital via Internet</strong>. Este ecosistema opera de forma 100% web y privada a través de los dominios correspondientes, garantizando la interacción interna directa entre el Médico Tratante y Recepción mediante notificaciones nativas en navegador, sin dependencias de servicios externos ni mensajería de terceros.
  </div>

  <h3>Diagrama de Flujo Operativo y Ciclo de Vida de la Orden</h3>
  <img src="./diagramas/Diagrama_7_Flujo_Operativo_HD.png" alt="Diagrama de Flujo Operativo - Proyecto 2" />
  
  <br><br>
  <div style="page-break-before: always; margin-top: 10px; padding: 15px; text-align: left; background-color: #f9f9f9; border-radius: 8px;">
    <p style="margin-bottom: 15px; font-family: Arial, sans-serif;"><strong>Contexto:</strong> Este diagrama representa de forma sencilla y secuencial los numerales de la sección 3 (Flujo Operativo) del Resumen de la Oferta. Ilustra las interacciones de los actores (Médico Tratante, Paciente, Recepcionista), los portales web utilizados y las transiciones del estado de la orden digital desde su captura hasta el cierre final.</p>
    <table style="width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; font-size: 14px;">
      <tr>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>📖 Instrucciones de Lectura</strong><br><br>
          • Siga el flujo numerado (1 al 13) para recorrer cronológicamente el ciclo de vida de una orden digital.<br>
          • Las líneas sólidas representan acciones e interacciones directas de los actores.<br>
          • Las líneas punteadas representan notificaciones automáticas y alertas enviadas por el sistema.<br>
          • Los recuadros amarillos representan los 4 estados oficiales del expediente en la base de datos.
        </td>
        <td style="width: 50%; vertical-align: top; padding: 10px; border: 1px solid #ddd;">
          <strong>💎 Puntos de Valor de la Solución</strong><br><br>
          • <strong>Prevención de Errores:</strong> Captura legible y directa de estudios por el médico tratante (1).<br>
          • <strong>Atención Agilizada:</strong> Recepción recibe notificaciones en tiempo real con sonido de silbato y enlace al expediente (4), localizando al paciente en mostrador al instante por folio o autocompletado (6).<br>
          • <strong>Seguimiento Transparente:</strong> El médico es notificado silenciosamente en su portal cuando los resultados en PDF están disponibles (10), permitiendo su descarga inmediata (11).
        </td>
      </tr>
    </table>
  </div>

</div>
