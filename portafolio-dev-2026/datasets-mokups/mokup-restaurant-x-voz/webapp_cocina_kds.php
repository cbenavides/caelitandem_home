<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WebApp Cocina - KDS Banner</title>
    <link rel="stylesheet" href="web-assets/css/main.css">
    <script src="https://unpkg.com/lucide@latest"></script>
    <style>
        /* KDS specific overrides for larger screens */
        body { overflow: hidden; }
    </style>
</head>
<body>
    <div class="kds-container">
        <!-- Banner Header -->
        <header class="app-header glass-panel" style="margin-bottom: 0; border-radius: 16px;">
            <div style="display: flex; align-items: center; gap: 1.5rem;">
                <h1 style="font-size: 2rem;">Caeli Tandem - Cocina</h1>
                <div style="background: rgba(16, 185, 129, 0.2); color: var(--status-success); padding: 0.5rem 1rem; border-radius: 99px; font-weight: 600;">
                    VOSK Escuchando
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 2rem;">
                <div style="text-align: right;">
                    <div class="text-secondary" style="font-size: 1.2rem;">Órdenes Pendientes</div>
                    <div style="font-size: 2rem; font-weight: 700; color: var(--accent-primary);">4</div>
                </div>
                <div style="font-size: 3rem; font-weight: 300; font-family: monospace;">15:42</div>
            </div>
        </header>

        <!-- KDS Grid -->
        <main class="kds-grid">
            
            <!-- Card: Warning Time -->
            <article class="kds-card glass-panel warning fade-in">
                <div class="kds-card-header">
                    <div>
                        <div class="text-secondary" style="font-size: 1rem;">MESA</div>
                        <div class="table-number">12</div>
                    </div>
                    <div style="text-align: right;">
                        <div class="text-secondary" style="font-size: 0.9rem;">15:28 • Juan</div>
                        <div class="kds-timer" style="font-size: 1.5rem; font-weight: 600; color: var(--status-warning);">14:05</div>
                    </div>
                </div>
                <div class="kds-card-body">
                    <div class="order-item">
                        <span class="item-qty">4</span>
                        <span style="flex: 1;">Huaraches Sencillos</span>
                    </div>
                    <div class="order-item">
                        <span class="item-qty">2</span>
                        <span style="flex: 1;">Sopes de Pollo</span>
                    </div>
                </div>
                <div style="padding: 1rem; background: rgba(0,0,0,0.2); text-align: center; color: var(--status-warning); font-weight: 600; text-transform: uppercase; letter-spacing: 2px;">
                    En Preparación
                </div>
            </article>

            <!-- Card: Danger Time -->
            <article class="kds-card glass-panel danger fade-in" style="animation-delay: 0.1s;">
                <div class="kds-card-header">
                    <div>
                        <div class="text-secondary" style="font-size: 1rem;">MESA</div>
                        <div class="table-number">3</div>
                    </div>
                    <div style="text-align: right;">
                        <div class="text-secondary" style="font-size: 0.9rem;">15:20 • Pedro</div>
                        <div class="kds-timer" style="font-size: 1.5rem; font-weight: 600; color: var(--status-danger);">22:15</div>
                    </div>
                </div>
                <div class="kds-card-body">
                    <div class="order-item">
                        <span class="item-qty">1</span>
                        <span style="flex: 1;">Pechuga Asada</span>
                        <span class="text-secondary" style="font-size: 0.9rem; margin-left: 1rem;">(Sin cebolla)</span>
                    </div>
                </div>
                <div style="padding: 1rem; background: rgba(239, 68, 68, 0.2); text-align: center; color: var(--text-primary); font-weight: 600; text-transform: uppercase; letter-spacing: 2px;">
                    Urgente
                </div>
            </article>

            <!-- Card: Normal / New -->
            <article class="kds-card glass-panel fade-in" style="animation-delay: 0.2s;">
                <div class="kds-card-header">
                    <div>
                        <div class="text-secondary" style="font-size: 1rem;">MESA</div>
                        <div class="table-number">5</div>
                    </div>
                    <div style="text-align: right;">
                        <div class="text-secondary" style="font-size: 0.9rem;">15:41 • Juan</div>
                        <div class="kds-timer" style="font-size: 1.5rem; font-weight: 600; color: var(--status-success);">00:45</div>
                    </div>
                </div>
                <div class="kds-card-body">
                    <div class="order-item">
                        <span class="item-qty">2</span>
                        <span style="flex: 1;">Tacos al Pastor</span>
                    </div>
                    <div class="order-item">
                        <span class="item-qty">1</span>
                        <span style="flex: 1;">Agua de Horchata</span>
                    </div>
                </div>
                <div style="padding: 1rem; background: rgba(255,255,255,0.05); text-align: center; color: var(--text-secondary); font-weight: 600; text-transform: uppercase; letter-spacing: 2px;">
                    Pendiente
                </div>
            </article>

        </main>
    </div>

    <script src="web-assets/js/app.js"></script>
</body>
</html>
