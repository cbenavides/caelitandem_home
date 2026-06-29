// Archivo: db.js
// Esquema de Base de Datos PWA Offline-First (Dexie.js)
// Basado en Especificación: Tecnica_Modelo_Datos_Comandas_VOSK.html

import Dexie from 'dexie';

// 1. Inicialización de la BD Local
export const db = new Dexie('RestaurantComandasDB');

// 2. Declaración de Esquema y Versiones
// NOTA: En Dexie.js solo se declaran las llaves primarias (PK) e índices (IDX).
// Los datos sin indexar se almacenan dinámicamente dentro de los objetos.
db.version(1).stores({
    // Transaccional: Cola de comandas capturadas sin internet
    comandas_offline: '++id, mesa_id, estado, creado_en',
    
    // Catálogos (Caché local con sincronización Delta Hash)
    productos_cache: 'id, categoria_id, nombre',
    mesas_cache: 'id, numero, activa',
    
    // Observabilidad y Trazabilidad Local
    logs_telemetria: '++id, timestamp, level',
    
    // Configuración General (Delta Hash, Device Fingerprint)
    app_config: 'key'
});

/**
 * Descripción de las estructuras esperadas por tienda (Stores):
 * 
 * [comandas_offline]
 * { id: auto, mesa_id: int, mesero_id: int, estado: 'pendiente_envio', texto_transcrito: string, productos: Array, creado_en: timestamp, duracion_offline_ms: int }
 * 
 * [productos_cache]
 * { id: int, categoria_id: int, nombre: string, precio: float, palabras_clave: string }
 * 
 * [mesas_cache]
 * { id: int, numero: int, activa: boolean }
 * 
 * [logs_telemetria]
 * { id: auto, level: 'INFO'|'ERROR', message: string, correlation_id: string, timestamp: string }
 * 
 * [app_config]
 * { key: 'hash_catalogo' | 'device_id', value: string }
 */
