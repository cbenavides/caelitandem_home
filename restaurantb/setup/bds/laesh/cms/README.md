# Módulo de Sincronización CMS: KVM2 (Producción) → BD Local

## 1. Análisis de Factibilidad

### ¿Es factible jalar todos los contenidos del sitio web index gestionados vía CMS desde KVM2 a la BD local?
**Sí, es 100% factible, seguro y reproducible**, sin romper la integridad operativa ni colisionar con datos de pacientes u órdenes.

### Justificación Técnica
1. **Modelo de Datos Desacoplado**:
   - El contenido editorial del sitio web y del CMS reside en la tabla `web_contenidos`, indexada con una clave única compuesta `UNIQUE KEY (seccion, subseccion, clave)`.
   - Las promociones semanales residen en `catalogo_promociones` (7 filas fijas con clave primaria `id` del 1 al 7).
   - Los parámetros globales de contacto y redes del sitio web residen en `configuraciones` (clave primaria `clave`).
   - Ninguna de estas tres tablas tiene dependencias de clave foránea (`FOREIGN KEY`) estrictas que bloqueen un `REPLACE INTO` o `INSERT ... ON DUPLICATE KEY UPDATE`.
2. **Permisos y Seguridad en KVM2**:
   - El usuario canónico `laesh_app` (con contraseña `laesh_2026_dev` sobre `laesh_db`) tiene permisos suficientes de lectura transaccional (`SELECT`) en KVM2.
   - Ejecutando `mariadb-dump` con `--single-transaction --skip-lock-tables` se extraen los volcados sin requerir privilegios de `LOCK TABLES` ni acceso `root`/`sudo`.
3. **Dependencia de Activos Físicos (Imágenes CMS)**:
   - Las imágenes subidas por el CMS (slides del hero, croquis, logos, fondos de promociones, tarjetas de áreas) se almacenan físicamente como archivos `.webp` con hash y timestamp en `/opt/laesh/assets/laesh-web-assets-uipv1a/cms/` en KVM2.
   - En la BD solo se almacenan las rutas relativas canónicas `/laesh-web-assets-uipv1a/cms/{archivo}.webp`.
   - Por tanto, la factibilidad completa requería también sincronizar las imágenes físicas hacia `restaurantb/www/laesh-web-assets-uipv1a/cms/` para evitar enlaces rotos (error 404 en imágenes).

---

## 2. Inventario de Componentes Gestionados

| Componente | Tabla / Directorio | Filas KVM2 | Filas Local Original | Filas Local Sincronizado | Propósito |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Contenido Editorial** | `web_contenidos` | **134** | 106 | **134** | Hero (slides, taglines), Quiénes Somos, Especialidades, Calidad, Ubicación, Footer, SEO, Aviso Privacidad, Video. |
| **Promociones Semanales** | `catalogo_promociones` | **7** | 7 (incompletas) | **7** (completas) | Días Lunes a Domingo con fondos WebP y estados activos. |
| **Parámetros Web** | `configuraciones` | 25 claves web | 25 claves web | 25 claves web | Teléfonos, WhatsApp, horarios, dirección, mapa, cédulas del responsable, redes. *(Excluye rutas de servidor como `cms_upload_dir`)*. |
| **Imágenes Físicas** | `laesh-web-assets-uipv1a/cms/` | 27 archivos | 16 archivos | **27 archivos** | Imágenes WebP reales subidas por los operadores en producción. |

---

## 3. Scripts Desarrollados (en `setup/bds/laesh/cms/`)

Todos los scripts y volcados residen exclusivamente en esta carpeta para proteger el SSOT y los scripts base de instalación:

### A. `pull_cms_kvm2.sh`
- Conecta a KVM2 vía SSH (`laesh-kvm2`).
- Descarga `kvm2_web_contenidos.sql`, `kvm2_catalogo_promociones.sql` y `kvm2_configuraciones_web.sql`.
- Genera el paquete unificado `kvm2_cms_full_sync.sql`.
- Sincroniza vía `rsync` los archivos `.webp` faltantes desde `/opt/laesh/assets/laesh-web-assets-uipv1a/cms/` hacia el directorio local de assets.
- **Uso**:
  ```bash
  bash setup/bds/laesh/cms/pull_cms_kvm2.sh
  # o si se desea omitir la descarga de imágenes:
  bash setup/bds/laesh/cms/pull_cms_kvm2.sh --skip-images
  ```

### B. `import_cms_local.sh`
- Detecta automáticamente el entorno local (contenedor Docker `restaurantb_db` o MariaDB TCP directo en localhost).
- Utiliza las credenciales estándar:
  - `user`: `laesh_app` (o variable `LAESH_DB_USER`)
  - `pass`: `laesh_2026_dev` (o variable `LAESH_DB_PASS`)
  - `name`: `laesh_db` (o variable `LAESH_DB_NAME`)
- Ejecuta el volcado `kvm2_cms_full_sync.sql`.
- Invalida y limpia la caché L2 de la webapp (`www/laesh-swbldi/cache/*.cache.php`).
- Muestra el reporte comparativo antes y después.
- **Uso**:
  ```bash
  bash setup/bds/laesh/cms/import_cms_local.sh
  ```

---

## 4. Archivos Generados en este Directorio

```
setup/bds/laesh/cms/
├── pull_cms_kvm2.sh                 # Script extractor KVM2 → Local
├── import_cms_local.sh               # Script aplicador a BD local
├── kvm2_web_contenidos.sql           # Dump individual de web_contenidos
├── kvm2_catalogo_promociones.sql     # Dump individual de catalogo_promociones
├── kvm2_configuraciones_web.sql      # Dump individual de configuraciones web
├── kvm2_cms_full_sync.sql            # Bundle consolidado completo
└── README.md                         # Este documento de análisis y protocolo
```

---

## 5. Garantía de Aislamiento
- **Cero modificaciones en `setup/bds/laesh/bash/`**: los flujos existentes (`04_export_cms_seed.sh`, `05_import_cms_seed_kvm2.sh`) permanecen intactos.
- **Cero modificaciones en SQL SSOT**: `07_seed_catalogs.sql`, `02_core_schema.sql` y el resto de esquemas no sufrieron cambios.
- **Cero alteración de datos operativos**: las tablas `ordenes`, `pacientes`, `perfiles_medicos`, `empleados` y `users` no son tocadas.
