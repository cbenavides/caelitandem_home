// Helper para manejar LocalStorage
const STORAGE_KEY = 'laesh_mock_orders';

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

function createOrder(paciente, estudios) {
    const orders = getOrders();
    const newOrder = {
        id: 'LSH-' + Math.floor(Math.random() * 10000).toString().padStart(4, '0'),
        paciente: paciente,
        estudios: estudios,
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
    createOrder('Ana Gómez', 'Química Sanguínea de 6 Elementos');
    updateOrderStatus(getOrders()[0].id, 'En Atención');
}

// Escuchar cambios en LocalStorage (simula WebSockets/Notificaciones)
window.addEventListener('storage', () => {
    if (typeof refreshData === 'function') {
        refreshData();
    }
});
