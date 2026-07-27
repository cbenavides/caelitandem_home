/**
 * AudioDirector: Secuenciador principal de la presentación comercial.
 */

class AudioDirector {
    constructor() {
        this.synth = window.speechSynthesis;
        this.voice = null;
        this.teleprompter = document.getElementById('teleprompter');
        this.isSpeaking = false;
        
        this.initVoice();
    }

    initVoice() {
        const loadVoices = () => {
            const voices = this.synth.getVoices();
            this.voice = voices.find(v => v.lang === 'es-MX') || voices.find(v => v.lang.startsWith('es-')) || voices[0];
        };
        
        loadVoices();
        if (speechSynthesis.onvoiceschanged !== undefined) {
            speechSynthesis.onvoiceschanged = loadVoices;
        }
    }

    speak(text, onStartCallback = null, onEndCallback = null) {
        this.cancel(); // Detener cualquier audio previo
        
        const utterance = new SpeechSynthesisUtterance(text);
        if (this.voice) utterance.voice = this.voice;
        utterance.rate = 0.95;
        utterance.pitch = 1.0;

        utterance.onstart = () => {
            this.isSpeaking = true;
            this.teleprompter.textContent = `"${text}"`;
            this.teleprompter.style.opacity = 1;
            if (onStartCallback) onStartCallback();
        };

        utterance.onend = () => {
            this.isSpeaking = false;
            if (onEndCallback) onEndCallback();
        };

        this.synth.speak(utterance);
    }
    
    cancel() {
        this.synth.cancel();
        this.isSpeaking = false;
        this.teleprompter.style.opacity = 0;
    }
}

const director = new AudioDirector();

// ==========================================
// CORE SECUENCIADOR Y ANIMACIONES
// ==========================================

const btnStart = document.getElementById('btn-start');
const overlay = document.getElementById('start-overlay');
let currentSceneIndex = 0;
let sceneTimeouts = []; // Para poder cancelar animaciones si saltamos de escena

btnStart.addEventListener('click', () => {
    overlay.style.opacity = 0;
    setTimeout(() => {
        overlay.style.display = 'none';
        playScene(0);
    }, 500);
});

// Lógica de Barra de Progreso
const segments = document.querySelectorAll('.progress-segment');
const indexItems = document.querySelectorAll('.index-item');
const fillBar = document.getElementById('progress-fill');

segments.forEach(seg => {
    seg.addEventListener('click', (e) => {
        const targetScene = parseInt(e.target.getAttribute('data-scene'));
        playScene(targetScene);
    });
});

indexItems.forEach(item => {
    item.addEventListener('click', (e) => {
        const targetScene = parseInt(e.target.getAttribute('data-scene'));
        playScene(targetScene);
    });
});

function updateProgressBar(index) {
    const percentage = ((index + 1) / 5) * 100;
    fillBar.style.width = `${percentage}%`;
    
    // Actualizar Índice Lateral
    indexItems.forEach(item => item.classList.remove('active'));
    document.querySelector(`.index-item[data-scene="${index}"]`).classList.add('active');
}

// Limpiar todas las escenas y timeouts
function resetAllScenes() {
    director.cancel();
    sceneTimeouts.forEach(t => clearTimeout(t));
    sceneTimeouts = [];
    
    document.querySelectorAll('.scene').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.actor, .tier-card, .paper, .clock').forEach(el => {
        el.classList.remove('visible', 'animate-paper-1', 'animate-paper-2', 'animate-paper-3', 'animate-clock', 'clear-chaos', 'pulse-gold');
        el.style.opacity = '';
    });
    document.querySelectorAll('.flow-particle').forEach(el => el.style.opacity = 0);
}

// Envolver setTimeout para poder cancelarlo
function schedule(fn, delay) {
    const t = setTimeout(fn, delay);
    sceneTimeouts.push(t);
}

function animateFlow(elementId, fromId, toId, durationMs) {
    const el = document.getElementById(elementId);
    const fromEl = document.getElementById(fromId);
    const toEl = document.getElementById(toId);
    
    if(!el || !fromEl || !toEl) return;
    
    const fromRect = fromEl.getBoundingClientRect();
    const toRect = toEl.getBoundingClientRect();
    const containerRect = document.getElementById('presentation-container').getBoundingClientRect();
    
    const startX = fromRect.left - containerRect.left + (fromRect.width / 2);
    const startY = fromRect.top - containerRect.top + (fromRect.height / 2);
    const endX = toRect.left - containerRect.left + (toRect.width / 2);
    const endY = toRect.top - containerRect.top + (toRect.height / 2);
    
    el.style.left = `${startX}px`;
    el.style.top = `${startY}px`;
    el.style.opacity = 1;
    el.style.transition = `all ${durationMs}ms ease-in-out`;
    
    void el.offsetWidth; 
    
    el.style.left = `${endX}px`;
    el.style.top = `${endY}px`;
    
    schedule(() => { el.style.opacity = 0; }, durationMs);
}

// ==========================================
// RUTEADOR DE ESCENAS
// ==========================================

function playScene(index) {
    resetAllScenes();
    currentSceneIndex = index;
    updateProgressBar(index);
    
    const scene = document.getElementById(`scene-${index}`);
    if(scene) scene.classList.add('active');

    if (index === 0) runScene0();
    else if (index === 1) runScene1();
    else if (index === 2) runScene2();
    else if (index === 3) runScene3();
    else if (index === 4) runScene4();
}

function runScene0() {
    schedule(() => document.getElementById('paper-1').classList.add('animate-paper-1'), 500);
    schedule(() => document.getElementById('paper-2').classList.add('animate-paper-2'), 1500);
    schedule(() => document.getElementById('paper-3').classList.add('animate-paper-3'), 2500);
    schedule(() => document.getElementById('clock').classList.add('animate-clock'), 2000);

    const txt = "En un laboratorio en crecimiento, el papel y la mala letra saturan a su personal. Retrasos, llamadas y molestia de pacientes. Es hora de evolucionar.";
    director.speak(txt, null, () => {
        schedule(() => playScene(1), 1000);
    });
}

function runScene1() {
    schedule(() => document.getElementById('s2-doc').classList.add('visible'), 500);
    schedule(() => document.getElementById('s2-server').classList.add('visible'), 1000);
    schedule(() => document.getElementById('s2-patient').classList.add('visible'), 1500);
    schedule(() => document.getElementById('s2-reception').classList.add('visible'), 2000);

    const txt = "Flujo uno: El médico genera la orden. El servidor notifica al instante al paciente por WhatsApp, atrayéndolo a su clínica. Al terminar, el resultado llega a su celular. Sin filas, sin imprimir.";
    
    director.speak(txt, () => {
        schedule(() => animateFlow('flow-order', 's2-doc', 's2-server', 1000), 2000);
        schedule(() => animateFlow('flow-whatsapp-1', 's2-server', 's2-patient', 1000), 5000);
        schedule(() => animateFlow('flow-order', 's2-patient', 's2-reception', 1500), 9000);
        schedule(() => animateFlow('flow-whatsapp-2', 's2-server', 's2-patient', 1000), 12000);
    }, () => {
        schedule(() => playScene(2), 2000);
    });
}

function runScene2() {
    schedule(() => document.getElementById('s3-patient').classList.add('visible'), 500);
    schedule(() => document.getElementById('s3-chatwoot').classList.add('visible'), 1000);
    schedule(() => document.getElementById('s3-reception').classList.add('visible'), 1500);

    const txt = "Flujo dos: Omnicanalidad. Si el paciente tiene dudas sobre una preparación, envía un WhatsApp. Chatwoot lo recibe y su recepcionista contesta desde la computadora. Atención inmediata, todo centralizado.";
    
    director.speak(txt, () => {
        schedule(() => animateFlow('flow-chat-1', 's3-patient', 's3-chatwoot', 1000), 4000);
        schedule(() => animateFlow('flow-chat-1', 's3-chatwoot', 's3-reception', 1000), 5500);
        schedule(() => animateFlow('flow-chat-2', 's3-reception', 's3-chatwoot', 1000), 8000);
        schedule(() => animateFlow('flow-chat-2', 's3-chatwoot', 's3-patient', 1000), 9500);
    }, () => {
        schedule(() => playScene(3), 2000);
    });
}

function runScene3() {
    schedule(() => document.getElementById('s4-patient').classList.add('visible'), 500);
    schedule(() => document.getElementById('s4-portal').classList.add('visible'), 1000);

    const txt = "Flujo tres: Portal de Pacientes. Su cliente ingresa al portal web con su teléfono y folio. Descarga al instante su historial en PDF de los últimos 90 días. Autonomía total, evitando que su recepcionista pierda tiempo en re-impresiones.";
    
    director.speak(txt, () => {
        schedule(() => animateFlow('flow-login', 's4-patient', 's4-portal', 1000), 5000);
        schedule(() => animateFlow('flow-pdf', 's4-portal', 's4-patient', 1000), 10000);
    }, () => {
        schedule(() => playScene(4), 2000);
    });
}

function runScene4() {
    schedule(() => document.getElementById('tier-1').classList.add('visible'), 500);
    schedule(() => document.getElementById('tier-2').classList.add('visible'), 1000);
    schedule(() => document.getElementById('tier-3').classList.add('visible'), 1500);

    const txt = "Para lograr esta transformación tecnológica, hemos diseñado opciones escalables. Sin embargo, la Opción 4 Integral es su única ruta lógica. Por 80 mil pesos en un solo pago, obtendrá la convergencia omnicanal y el ecosistema completo. Analice nuestra propuesta y digitalicemos LAESH.";
    
    director.speak(txt, () => {
        schedule(() => {
            document.getElementById('tier-4').classList.add('visible');
            document.getElementById('tier-4').classList.add('pulse-gold');
        }, 6000);
    }, () => {
        schedule(() => {
            document.getElementById('teleprompter').textContent = "Presentación finalizada. Cierre la ventana o de clic a un segmento para repetir.";
            document.getElementById('teleprompter').style.opacity = 1;
        }, 1000);
    });
}
