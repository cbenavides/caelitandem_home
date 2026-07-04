<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>PWA Mesero - Notificaciones & Cierre</title>
    <link rel="stylesheet" href="web-assets/css/main.css">
    <script src="https://unpkg.com/lucide@latest"></script>
</head>
<body>
    <div class="app-container">
        <!-- Header con Menú Hamburguesa -->
        <header class="app-header">
            <div style="display: flex; align-items: center; gap: 1rem;">
                <button class="icon-btn" onclick="toggleMenu(event)">
                    <i data-lucide="menu"></i>
                </button>
                <div>
                    <h1 style="font-size: 1.25rem;">Mesas Activas</h1>
                </div>
            </div>
            <div style="position: relative;">
                <i data-lucide="bell" style="color: var(--text-secondary);"></i>
                <span style="position: absolute; top: -5px; right: -5px; background: var(--status-danger); width: 10px; height: 10px; border-radius: 50%;"></span>
            </div>
        </header>

        <!-- Side Menu -->
        <div class="side-menu-overlay" id="side-menu-overlay" onclick="toggleMenu(event)"></div>
        <aside class="side-menu" id="side-menu">
            <div class="menu-header">
                <h2 style="font-size: 1.25rem;">Caeli Tandem</h2>
                <button class="icon-btn" onclick="toggleMenu(event)">
                    <i data-lucide="x"></i>
                </button>
            </div>
            <nav class="menu-nav">
                <a href="pwa_mesero_comanda.php" class="menu-item">
                    <i data-lucide="mic"></i> Nueva Comanda
                </a>
                <a href="pwa_mesero_notificaciones.php" class="menu-item">
                    <i data-lucide="list"></i> Mis Mesas Activas
                </a>
                <hr style="border: 0; border-top: 1px solid var(--glass-border); margin: 1rem 0;">
                <a href="#" class="menu-item" onclick="toggleTheme(event)">
                    <i data-lucide="moon"></i> Alternar Tema Oscuro/Claro
                </a>
                <a href="#" class="menu-item danger" onclick="logout(event)" style="margin-top: auto;">
                    <i data-lucide="log-out"></i> Cerrar Sesión
                </a>
            </nav>
        </aside>

        <main class="app-content">
            <!-- Notification Inbox -->
            <section style="margin-bottom: 2rem;">
                <h3 style="margin-bottom: 1rem; font-size: 0.9rem;" class="text-secondary">Últimas Notificaciones (Cocina)</h3>
                
                <div class="glass-panel fade-in" style="padding: 1rem; border-left: 4px solid var(--status-success); margin-bottom: 0.75rem;">
                    <div style="display: flex; justify-content: space-between; margin-bottom: 0.25rem;">
                        <strong style="color: var(--status-success);">Orden Lista</strong>
                        <span class="text-secondary" style="font-size: 0.8rem;">Hace 2 min</span>
                    </div>
                    <p style="font-size: 0.95rem;">Mesa 5: Los tacos al pastor están listos para entregar.</p>
                </div>

                <div class="glass-panel fade-in" style="padding: 1rem; border-left: 4px solid var(--status-warning); animation-delay: 0.1s;">
                    <div style="display: flex; justify-content: space-between; margin-bottom: 0.25rem;">
                        <strong style="color: var(--status-warning);">Cancelación Aprobada</strong>
                        <span class="text-secondary" style="font-size: 0.8rem;">Hace 15 min</span>
                    </div>
                    <p style="font-size: 0.95rem;">Mesa 3: Se canceló 1 x Agua de Horchata.</p>
                </div>
            </section>

            <!-- Active Tables -->
            <section>
                <h3 style="margin-bottom: 1rem; font-size: 0.9rem;" class="text-secondary">Tus Mesas</h3>
                
                <div style="display: grid; gap: 1rem;">
                    <!-- Table Card -->
                    <div class="glass-panel" style="padding: 1rem; display: flex; align-items: center; justify-content: space-between;">
                        <div style="display: flex; align-items: center; gap: 1rem;">
                            <div style="background: rgba(128,128,128,0.1); border: 1px solid var(--glass-border); width: 48px; height: 48px; border-radius: 50%; display: flex; justify-content: center; align-items: center; font-weight: 700; font-size: 1.2rem;">
                                5
                            </div>
                            <div>
                                <div style="font-weight: 600;">Mesa 5</div>
                                <div class="text-secondary" style="font-size: 0.85rem;">3 Artículos • $ 145.00</div>
                            </div>
                        </div>
                        <button class="btn btn-primary" style="padding: 0.5rem 1rem; font-size: 0.9rem;">
                            Cerrar
                        </button>
                    </div>

                    <!-- Table Card -->
                    <div class="glass-panel" style="padding: 1rem; display: flex; align-items: center; justify-content: space-between;">
                        <div style="display: flex; align-items: center; gap: 1rem;">
                            <div style="background: rgba(128,128,128,0.1); border: 1px solid var(--glass-border); width: 48px; height: 48px; border-radius: 50%; display: flex; justify-content: center; align-items: center; font-weight: 700; font-size: 1.2rem;">
                                12
                            </div>
                            <div>
                                <div style="font-weight: 600;">Mesa 12</div>
                                <div class="text-secondary" style="font-size: 0.85rem;">1 Artículo • $ 40.00</div>
                            </div>
                        </div>
                        <button class="btn btn-primary" style="padding: 0.5rem 1rem; font-size: 0.9rem;">
                            Cerrar
                        </button>
                    </div>
                </div>
            </section>
        </main>
    </div>

    <script>
        lucide.createIcons();
    </script>
    <script src="web-assets/js/app.js"></script>
</body>
</html>
