# migrations/ — Migraciones Incrementales de Schema

Migraciones SQL idempotentes para actualizar esquemas de producción **sin DROP**.
Se aplican cuando la BD ya existe y solo faltan columnas, índices o cambios menores.

---

## ¿Cuándo usar?

| Situación | Acción |
|-----------|--------|
| Primer deploy o reset completo | `setup_hostinger.sh --drop` — ejecuta los 10 scripts SQL completos. Las migrations son innecesarias (el schema ya incluye todo). |
| BD existente en producción que necesita columnas/índices nuevos | Aplicar la migration correspondiente con `mariadb ... < migrations/mXXX_...sql` |
| Re-deploy sin DROP (`setup_hostinger.sh` sin flags) | **Paso 2b** aplica automáticamente todos los `m*.sql` en orden. Idempotente — `IF NOT EXISTS` garantiza que no falla si ya fue aplicada. |

---

## Convención de nombres

```
m<NNN>_<descripcion_corta>.sql
```

- `NNN` — número secuencial de 3 dígitos (`001`, `002`…)
- `descripcion_corta` — snake_case, máx 40 chars
- Siempre idempotente: usar `ALTER TABLE … ADD COLUMN IF NOT EXISTS`, `ADD INDEX IF NOT EXISTS`

---

## Inventario

| Archivo | Fecha | Tablas | Cambios | Estado |
|---------|-------|--------|---------|--------|
| `m001_sys_logs_traceability.sql` | 2026-09-06 | `sys_logs` | +`request_id` CHAR(16), +`url` VARCHAR(500), +`metodo` VARCHAR(10), +`session_id` CHAR(26), +`KEY idx_request_id` | ✅ Aplicado KVM2 |

---

## Cómo aplicar manualmente en KVM2

```bash
# Una migration específica:
sudo mariadb -u root -p'comite_2026' laesh_db \
    < /home/sysadmin/laesh-src/setup/bds/laesh/migrations/m001_sys_logs_traceability.sql

# Todas las migrations en orden (mismo comportamiento que Paso 2b de setup_hostinger.sh):
for f in $(ls /home/sysadmin/laesh-src/setup/bds/laesh/migrations/m*.sql | sort); do
    echo "→ $f"
    sudo mariadb -u root -p'comite_2026' laesh_db < "$f"
done
```

---

## Relación con `setup_hostinger.sh`

El **Paso 2b** en `setup_hostinger.sh` ejecuta automáticamente todos los archivos `migrations/m*.sql`
en orden lexicográfico después de los 10 scripts SQL base. Es idempotente:
- En un deploy con `--drop`: las columnas ya existen en el schema → `IF NOT EXISTS` → no-op.
- En un upgrade sin `--drop`: aplica solo lo que falta.
