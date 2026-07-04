<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WebApp Admin - Tablero Principal</title>
    <link rel="stylesheet" href="web-assets/css/main.css">
    <script src="https://unpkg.com/lucide@latest"></script>
</head>
<body>
    <div class="admin-container">
        
        <!-- Sidebar -->
        <aside class="sidebar glass-panel" style="border-radius: 0;">
            <div style="padding: 0 1rem; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h1 style="color: var(--accent-primary); font-size: 1.5rem;">Caeli Admin</h1>
                    <div class="text-secondary" style="font-size: 0.8rem; margin-top: 0.5rem;">Panel de Control</div>
                </div>
            </div>
            
            <nav style="display: flex; flex-direction: column; gap: 0.5rem; margin-top: 2rem; flex: 1;">
                <a href="#" class="nav-item active">
                    <i data-lucide="layout-dashboard"></i> Tablero Principal
                </a>
                <a href="#" class="nav-item">
                    <i data-lucide="file-text"></i> Tickets y Ventas
                </a>
                <a href="#" class="nav-item">
                    <i data-lucide="utensils"></i> Catálogo de Menú
                </a>
                <a href="#" class="nav-item">
                    <i data-lucide="users"></i> Usuarios y Diademas
                </a>
                <a href="#" class="nav-item">
                    <i data-lucide="settings"></i> Configuración General
                </a>
            </nav>

            <div style="display: flex; flex-direction: column; gap: 0.5rem;">
                <button class="btn glass-panel" style="width: 100%; font-size: 0.9rem;" onclick="toggleTheme(event)">
                    <i data-lucide="moon"></i> Alternar Tema
                </button>
                <button class="btn btn-danger" style="width: 100%; font-size: 0.9rem;" onclick="logout(event)">
                    <i data-lucide="log-out"></i> Cerrar Sesión
                </button>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="dashboard-content">
            <header style="margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center;">
                <h2>Resumen de Hoy</h2>
                <div class="text-secondary">11 de Junio, 2026</div>
            </header>

            <!-- Stats Grid -->
            <div class="stats-grid">
                <div class="stat-card glass-panel fade-in">
                    <div class="text-secondary" style="display: flex; justify-content: space-between;">
                        Ventas Totales
                        <i data-lucide="trending-up" style="color: var(--status-success);"></i>
                    </div>
                    <div class="stat-value">$ 12,450.00</div>
                    <div class="text-secondary" style="font-size: 0.85rem;">+15% vs ayer</div>
                </div>

                <div class="stat-card glass-panel fade-in" style="animation-delay: 0.1s;">
                    <div class="text-secondary" style="display: flex; justify-content: space-between;">
                        Tickets Cerrados
                        <i data-lucide="receipt"></i>
                    </div>
                    <div class="stat-value">42</div>
                    <div class="text-secondary" style="font-size: 0.85rem;">Promedio: $296.00</div>
                </div>

                <div class="stat-card glass-panel fade-in" style="animation-delay: 0.2s;">
                    <div class="text-secondary" style="display: flex; justify-content: space-between;">
                        Tiempo Prom. Preparación
                        <i data-lucide="clock"></i>
                    </div>
                    <div class="stat-value">14m 20s</div>
                    <div class="text-secondary" style="font-size: 0.85rem; color: var(--status-warning);">+2m vs meta</div>
                </div>
            </div>

            <!-- Recent Activity Table -->
            <div class="glass-panel" style="padding: 1.5rem;">
                <h3 style="margin-bottom: 1.5rem;">Últimas Cancelaciones</h3>
                
                <table style="width: 100%; border-collapse: collapse; text-align: left;">
                    <thead>
                        <tr style="border-bottom: 1px solid var(--glass-border); color: var(--text-secondary);">
                            <th style="padding: 1rem 0;">Hora</th>
                            <th>Mesa</th>
                            <th>Producto</th>
                            <th>Mesero</th>
                            <th>Autorizó</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr style="border-bottom: 1px solid rgba(128,128,128,0.1);">
                            <td style="padding: 1rem 0;">15:30</td>
                            <td>Mesa 3</td>
                            <td>1 x Agua de Horchata</td>
                            <td>Juan Pérez</td>
                            <td>Cocina 1</td>
                        </tr>
                        <tr>
                            <td style="padding: 1rem 0;">14:15</td>
                            <td>Mesa 8</td>
                            <td>2 x Sopes</td>
                            <td>Ana López</td>
                            <td>Cocina 2</td>
                        </tr>
                    </tbody>
                </table>
            </div>

        </main>
    </div>

    <script>
        lucide.createIcons();
    </script>
    <script src="web-assets/js/app.js"></script>
</body>
</html>
