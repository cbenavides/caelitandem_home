// Helper para manejar LocalStorage
const STORAGE_KEY = 'laesh_mock_orders';
const CATALOG_KEY = 'laesh_mock_catalog';

// Base64 Silbato (corto pitido)
const WHISTLE_AUDIO = "data:audio/wav;base64,UklGRl9vT19XQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YU"+'A'.repeat(500); // Dummy fallback if audio play fails, but we'll use a standard web audio oscillator for a real beep.

function playWhistle() {
    try {
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioCtx.createOscillator();
        const gainNode = audioCtx.createGain();
        oscillator.connect(gainNode);
        gainNode.connect(audioCtx.destination);
        oscillator.type = 'sine';
        oscillator.frequency.setValueAtTime(1200, audioCtx.currentTime); // High pitch whistle
        oscillator.frequency.exponentialRampToValueAtTime(800, audioCtx.currentTime + 0.3);
        gainNode.gain.setValueAtTime(0.5, audioCtx.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.3);
        oscillator.start();
        oscillator.stop(audioCtx.currentTime + 0.3);
    } catch(e) {
        console.log("Audio no soportado");
    }
}

function getOrders() {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : [];
}

function saveOrders(orders) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(orders));
    // Disparar evento para otras pestañas
    window.dispatchEvent(new Event('storage'));
}

const DEFAULT_CATALOG = [
    { clave: 'HEM-01', nombre: 'Biometría Hemática Completa', categoria: 'Hematología', tiempo: '4 Horas', muestra: 'Sangre total (Tubo Lila)', preparacion: 'No requiere ayuno estricto (ideal 4 hrs)' },
    { clave: 'BIO-06', nombre: 'Química Sanguínea (6 Elementos)', categoria: 'Bioquímica', tiempo: '6 Horas', muestra: 'Suero (Tubo Rojo)', preparacion: 'Ayuno de 8 a 12 horas (solamente agua)' },
    { clave: 'URO-01', nombre: 'Examen General de Orina (EGO)', categoria: 'Uroanálisis', tiempo: '3 Horas', muestra: 'Frasco Estéril Orina', preparacion: 'Primer orina de la mañana' },
    { clave: 'HEM-04', nombre: 'Tiempos de Coagulación (TP/TTPA)', categoria: 'Hematología', tiempo: '4 Horas', muestra: 'Plasma (Tubo Azul)', preparacion: 'No requiere ayuno especial' }
];

function getCatalog() {
    const data = localStorage.getItem(CATALOG_KEY);
    if (!data) {
        localStorage.setItem(CATALOG_KEY, JSON.stringify(DEFAULT_CATALOG));
        return DEFAULT_CATALOG;
    }
    return JSON.parse(data);
}

function saveCatalog(catalog) {
    localStorage.setItem(CATALOG_KEY, JSON.stringify(catalog));
    window.dispatchEvent(new Event('storage'));
}

function createOrder(paciente, estudios, medico) {
    const orders = getOrders();
    const newOrder = {
        id: 'LSH-' + Math.floor(Math.random() * 10000).toString().padStart(4, '0'),
        paciente: paciente,
        estudios: estudios,
        medico: medico || 'Dr. Roberto Mendoza',
        estado: 'Remitido',
        fecha: new Date().toLocaleString()
    };
    orders.push(newOrder);
    saveOrders(orders);
    return newOrder;
}

function updateOrderStatus(id, newStatus) {
    const orders = getOrders();
    const order = orders.find(o => o.id === id);
    if (order) {
        order.estado = newStatus;
        saveOrders(orders);
    }
}

// Inicializar Mock Data si está vacío
if (getOrders().length === 0) {
    createOrder('Ana Gómez', 'Química Sanguínea de 6 Elementos', 'Dr. Roberto Mendoza');
    updateOrderStatus(getOrders()[0].id, 'En Atención');
}

// Escuchar cambios en LocalStorage (simula WebSockets/Notificaciones)
window.addEventListener('storage', () => {
    if (typeof refreshData === 'function') {
        refreshData();
    }
    if (typeof refreshCatalog === 'function') {
        refreshCatalog();
    }
});
