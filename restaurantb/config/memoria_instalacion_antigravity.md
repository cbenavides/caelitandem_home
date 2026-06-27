# Memoria de Instalación: Google Antigravity 2.x y Antigravity IDE 2.x en Ubuntu 24.04 LTS (VM)

Este documento detalla el procedimiento técnico para la instalación, depuración, configuración y optimización de **Google Antigravity 2.0** y **Antigravity IDE 2.x** sobre una máquina virtual (VM) con **Ubuntu 24.04 LTS (Noble Numbat)** ejecutándose en un hipervisor **VirtualBox 7** hospedado en una laptop **Dell Inspiron 15 Gaming 7567** (bajo entorno de ventana X11).

Se incluyen los scripts necesarios para automatizar y reproducir este despliegue de forma manual.

---

## 🖥️ 1. Especificaciones del Entorno y Hardware

- **Host (Físico):** Dell Inspiron 15 Gaming 7567 (CPU Intel Core i7-7700HQ, GPU NVIDIA GTX 1050 Ti).
- **Hipervisor:** VirtualBox 7.x.
- **Invitado (VM):** Ubuntu 24.04 LTS x86_64 (X11 Display Server).
- **Usuario Invitado:** `ub24` / Contraseña: `veureka1234`
- **Ubicación de los Recursos Originales en la VM:** `/home/ub24/wkwip-2026/ga2x/`
  - `Antigravity.tar.gz` (App Antigravity 2.0, Electron bundle)
  - `Antigravity IDE.tar.gz` (IDE Antigravity, Electron bundle)

---

## ⚙️ 2. Preparación y Optimización del Hipervisor (VirtualBox)

Antes del arranque de la VM, se requiere optimizar la configuración de VirtualBox en el Host para dar soporte adecuado a aplicaciones Electron con aceleración por hardware:

```bash
# Asignar mínimo 2 CPUs a la VM para evitar cuellos de botella en la compilación/renderizado
VBoxManage modifyvm "ubuntu24lt" --cpus 2

# Habilitar virtualización anidada (Nested Hardware Virtualization)
VBoxManage modifyvm "ubuntu24lt" --nested-hw-virt on
```

---

## 🛠️ 3. Proceso de Limpieza y Depuración Preventiva

Para evitar colisiones de dependencias, permisos rotos o configuraciones corruptas de instalaciones previas de Google Antigravity, ejecute lo siguiente:

```bash
#!/bin/bash
# Limpieza de directorios antiguos en /opt/
sudo rm -rf /opt/Antigravity* /opt/google-antigravity-*

# Eliminar accesos directos antiguos del escritorio
rm -f /home/ub24/Desktop/Antigravity*.desktop
rm -f /home/ub24/Escritorio/Antigravity*.desktop
```

---

## 📂 4. Instalación de Componentes

### 4.1 Extracción de Binarios
Ambas herramientas vienen empaquetadas como aplicaciones Electron precompiladas. Se deben extraer directamente en el directorio de sistema `/opt/` (directorio estándar para software opcional de terceros).

```bash
# Extraer la aplicación Antigravity 2.0 (App)
sudo tar -xzf /home/ub24/wkwip-2026/ga2x/Antigravity.tar.gz -C /opt/

# Extraer Antigravity IDE (IDE)
sudo tar -xzf "/home/ub24/wkwip-2026/ga2x/Antigravity IDE.tar.gz" -C /opt/
```

### 4.2 Resolución del Conflicto de Espacios en Directorios (Poka-Yoke)
Para evitar problemas futuros con scripts bash internos, resolutores de rutas de Node.js o el valor de la variable `$PATH`, la carpeta extraída `"Antigravity IDE"` se renombra quitando el espacio:

```bash
# Renombrar para eliminar el espacio del nombre del directorio
if [ -d "/opt/Antigravity IDE" ]; then
    sudo mv "/opt/Antigravity IDE" /opt/AntigravityIDE
fi
```

Tras esto, las rutas definitivas de ejecución son:
- **App Antigravity:** `/opt/Antigravity-x64/antigravity`
- **Antigravity IDE:** `/opt/AntigravityIDE/antigravity-ide`

---

## 🔒 5. Optimización del Sistema Operativo (Ubuntu 24.04 LTS)

Ubuntu 24.04 introduce cambios estrictos de seguridad que bloquean la ejecución por defecto de sandbox en navegadores basados en Chromium/Electron. Se aplicaron los siguientes ajustes de optimización:

### 5.1 Permisos del Chrome Sandbox
Es imperativo configurar el ejecutable `chrome-sandbox` de Electron con permisos root y el bit SUID activo para que el motor Chromium pueda aislar procesos de forma segura:

```bash
# Permisos SUID para la aplicación principal
sudo chown root:root /opt/Antigravity-x64/chrome-sandbox
sudo chmod 4755 /opt/Antigravity-x64/chrome-sandbox

# Permisos SUID para el IDE
sudo chown root:root /opt/AntigravityIDE/chrome-sandbox
sudo chmod 4755 /opt/AntigravityIDE/chrome-sandbox
```

### 5.2 Deshabilitar la restricción de User Namespaces de AppArmor (Ubuntu 24.04)
Ubuntu 24.04 bloquea por defecto la clonación de namespaces de usuario sin privilegios. Esto causa un fallo inmediato (*crash*) en aplicaciones Electron. Para resolver esto permanentemente:

```bash
# Aplicar cambio en caliente en el kernel
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0

# Persistir la configuración tras reiniciar
sudo sh -c 'echo "kernel.apparmor_restrict_unprivileged_userns=0" > /etc/sysctl.d/60-apparmor-namespace.conf'
```

### 5.3 Optimización de Inotify Watchers (Límite de Monitoreo de Archivos)
El IDE requiere observar miles de archivos en tiempo real para el autocompletado y recarga en caliente. Por defecto, el límite de watchers en Ubuntu es insuficiente (`8192`), lo que ocasiona bloqueos. Lo incrementamos a `524288`:

```bash
# Aplicar cambio en caliente
sudo sysctl -w fs.inotify.max_user_watches=524288

# Registrar cambio persistente
sudo sh -c 'echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf'
```

---

## 🖥️ 6. Creación de Accesos Directos en Escritorio

Para que las aplicaciones estén integradas al entorno gráfico (GNOME/X11), se generan archivos `.desktop` autoejecutables en el Escritorio del usuario.

### Script Bash para Generar Accesos Directos

El siguiente script detecta el directorio del Escritorio (soporta variantes en inglés/español) y crea los lanzadores:

```bash
#!/bin/bash
# 1. Identificar el Escritorio del usuario
DESKTOP="/home/ub24/Desktop"
if [ ! -d "$DESKTOP" ]; then
    DESKTOP="/home/ub24/Escritorio"
fi
if [ ! -d "$DESKTOP" ]; then
    mkdir -p "/home/ub24/Desktop"
    DESKTOP="/home/ub24/Desktop"
fi

# 2. Generar Lanzador para Antigravity 2.0 (App)
cat <<EOF > "$DESKTOP/Antigravity.desktop"
[Desktop Entry]
Name=Antigravity 2.0
Exec=/opt/Antigravity-x64/antigravity --no-sandbox
Terminal=false
Type=Application
Icon=/opt/Antigravity-x64/resources/app/icon.png
Categories=Development;
EOF

# 3. Generar Lanzador para Antigravity IDE
cat <<EOF > "$DESKTOP/AntigravityIDE.desktop"
[Desktop Entry]
Name=Antigravity IDE
Exec=/opt/AntigravityIDE/antigravity-ide --no-sandbox
Terminal=false
Type=Application
Icon=/opt/AntigravityIDE/resources/app/icon.png
Categories=Development;
EOF

# 4. Asignar permisos y propietario
chmod +x "$DESKTOP/Antigravity.desktop" "$DESKTOP/AntigravityIDE.desktop"
chown ub24:ub24 "$DESKTOP/Antigravity.desktop" "$DESKTOP/AntigravityIDE.desktop"
```

> [!NOTE]
> Se ha incluido el flag `--no-sandbox` en el comando de ejecución (`Exec`) como una segunda capa de protección para garantizar el arranque gráfico en entornos X11 virtualizados.

---

## ⚡ 7. Script Único de Despliegue Automatizado (Full Setup)

Para realizar una instalación limpia desde cero en cualquier VM homóloga con Ubuntu 24.04 LTS, copie y ejecute el siguiente script integral como el usuario `ub24`:

```bash
#!/bin/bash
set -e

echo "=== INICIANDO INSTALACIÓN DE GOOGLE ANTIGRAVITY EN UBUNTU 24.04 ==="

# 1. Limpieza preliminar
echo "[1/6] Depurando instalaciones previas..."
sudo rm -rf /opt/Antigravity* /opt/google-antigravity-*
rm -f /home/ub24/Desktop/Antigravity*.desktop
rm -f /home/ub24/Escritorio/Antigravity*.desktop

# 2. Extracción de archivos
echo "[2/6] Extrayendo paquetes en /opt/..."
sudo tar -xzf /home/ub24/wkwip-2026/ga2x/Antigravity.tar.gz -C /opt/
sudo tar -xzf "/home/ub24/wkwip-2026/ga2x/Antigravity IDE.tar.gz" -C /opt/

# 3. Aplicar Poka-Yoke de nombres
echo "[3/6] Normalizando directorios..."
if [ -d "/opt/Antigravity IDE" ]; then
    sudo mv "/opt/Antigravity IDE" /opt/AntigravityIDE
fi

# 4. Configurar permisos SUID de Chrome Sandbox
echo "[4/6] Configurando permisos SUID..."
sudo chown root:root /opt/Antigravity-x64/chrome-sandbox
sudo chmod 4755 /opt/Antigravity-x64/chrome-sandbox
sudo chown root:root /opt/AntigravityIDE/chrome-sandbox
sudo chmod 4755 /opt/AntigravityIDE/chrome-sandbox

# 5. Aplicar optimizaciones del kernel (AppArmor y Watchers)
echo "[5/6] Optimizando kernel del sistema operativo..."
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
sudo sh -c 'echo "kernel.apparmor_restrict_unprivileged_userns=0" > /etc/sysctl.d/60-apparmor-namespace.conf'
sudo sysctl -w fs.inotify.max_user_watches=524288
sudo sh -c 'echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf'

# 6. Crear accesos directos
echo "[6/6] Creando lanzadores en el escritorio..."
DESKTOP="/home/ub24/Desktop"
[ ! -d "$DESKTOP" ] && DESKTOP="/home/ub24/Escritorio"
[ ! -d "$DESKTOP" ] && mkdir -p "/home/ub24/Desktop" && DESKTOP="/home/ub24/Desktop"

cat <<EOF > "$DESKTOP/Antigravity.desktop"
[Desktop Entry]
Name=Antigravity 2.0
Exec=/opt/Antigravity-x64/antigravity --no-sandbox
Terminal=false
Type=Application
Icon=/opt/Antigravity-x64/resources/app/icon.png
Categories=Development;
EOF

cat <<EOF > "$DESKTOP/AntigravityIDE.desktop"
[Desktop Entry]
Name=Antigravity IDE
Exec=/opt/AntigravityIDE/antigravity-ide --no-sandbox
Terminal=false
Type=Application
Icon=/opt/AntigravityIDE/resources/app/icon.png
Categories=Development;
EOF

chmod +x "$DESKTOP/Antigravity.desktop" "$DESKTOP/AntigravityIDE.desktop"
chown ub24:ub24 "$DESKTOP/Antigravity.desktop" "$DESKTOP/AntigravityIDE.desktop"

echo "=== INSTALACIÓN Y OPTIMIZACIÓN COMPLETADA CON ÉXITO ==="
echo "Nota: Si los accesos directos no muestran su icono nativo de inmediato,"
echo "cierra tu sesión gráfica actual y vuelve a ingresar."
```
