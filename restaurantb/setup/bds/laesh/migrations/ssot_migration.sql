USE laesh_db;

-- 1. Añadir columnas a catalogo_estudios si no existen
SET @dbname = DATABASE();
SET @tablename = 'catalogo_estudios';
SET @columnname1 = 'contenedor';
SET @columnname2 = 'pruebas_incluidas';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname1)
  ) > 0,
  "SELECT 1",
  "ALTER TABLE catalogo_estudios ADD COLUMN contenedor VARCHAR(255) DEFAULT '';"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

SET @preparedStatement2 = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname2)
  ) > 0,
  "SELECT 1",
  "ALTER TABLE catalogo_estudios ADD COLUMN pruebas_incluidas TEXT;"
));
PREPARE alterIfNotExists2 FROM @preparedStatement2;
EXECUTE alterIfNotExists2;
DEALLOCATE PREPARE alterIfNotExists2;

-- 2. Limpieza de tablas (SSOT reset)
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE catalogo_estudios;
TRUNCATE TABLE catalogo_categorias;
TRUNCATE TABLE catalogo_grupos;
SET FOREIGN_KEY_CHECKS = 1;
