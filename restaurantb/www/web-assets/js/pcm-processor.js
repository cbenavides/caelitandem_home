class PCMProcessor extends AudioWorkletProcessor {
    constructor() {
        super();
        this.bufferSize = 4096;
        this.buffer = new Float32Array(this.bufferSize);
        this.bufferIndex = 0;
    }

    process(inputs, outputs, parameters) {
        const input = inputs[0];
        if (input && input[0]) {
            const channelData = input[0];
            const length = channelData.length;
            
            // Acumular muestras hasta llenar el tamaño de bloque adecuado para Vosk (4096 samples ~ 256ms)
            for (let i = 0; i < length; i++) {
                this.buffer[this.bufferIndex++] = channelData[i];
                if (this.bufferIndex >= this.bufferSize) {
                    // Enviamos una copia limpia de las 4096 muestras acumuladas
                    this.port.postMessage(this.buffer.slice(0));
                    this.bufferIndex = 0;
                }
            }
        }
        return true;
    }
}

registerProcessor('pcm-processor', PCMProcessor);
