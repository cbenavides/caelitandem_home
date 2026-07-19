# Diagramas de Secuencia (Monitos y Homologación de Términos)

### Diagrama 1: Emisión de la Orden y Atracción
```mermaid
sequenceDiagram
    autonumber
    actor Medico as Médico Tratante
    participant PC as Computadora oficina / Celular
    participant Nube as Sistema Bloc Digital
    participant Impresora as Impresora
    participant WA as WhatsApp
    actor Paciente as Paciente

    Medico->>PC: Selecciona estudios y datos
    PC->>Nube: Transmite información
    Nube-->>Nube: Genera #Folio Interno
    Nube-->>PC: Confirmación en pantalla
    Nube->>WA: Envía Solicitud Digital
    WA->>Paciente: Recibe (Imagen + Texto)
    Medico-->>Impresora: [Opcional/Contingencia] Imprime Orden
```

### Diagrama 2: Operación en Recepción (Cero errores)
```mermaid
sequenceDiagram
    autonumber
    actor Paciente as Paciente
    participant WA as WhatsApp
    actor Recepcion as Recepcionista
    participant Sistema as Sistema Bloc Digital
    actor Quimico as Químico (Laboratorio)

    Paciente->>WA: Muestra Folio digital
    WA->>Recepcion: Dicta Folio o Nombre
    Recepcion->>Sistema: Localiza orden pre-cargada
    Sistema-->>Recepcion: Muestra información
    Recepcion->>Sistema: Da clic en "En Atención"
    Sistema->>Quimico: Libera lista de pruebas a realizar
```

### Diagrama 3: Automatización y Entrega de Resultados
```mermaid
sequenceDiagram
    autonumber
    actor Quimico as Químico (Laboratorio)
    participant LIS as Sistema Admin. Existente
    participant Sync as Carpeta Segura (Local)
    participant Sistema as Sistema Bloc Digital
    participant WA as WhatsApp
    actor Paciente as Paciente

    Quimico->>LIS: Procesa y genera resultados
    LIS-->>Quimico: Exporta archivo PDF
    Quimico->>Sync: Deposita PDF de Resultados
    Sync->>Sistema: Carga y lee #Folio del archivo
    Sistema->>Sistema: Vincula PDF a Expediente
    Sistema->>Sistema: Publica para descarga web (Portal)
    Sistema->>WA: Dispara Imagen (JPG/PNG) directamente
    Sistema->>Paciente: [Web] Descarga de Histórico (PDF)
    WA->>Paciente: Recibe Imagen en su celular
```
