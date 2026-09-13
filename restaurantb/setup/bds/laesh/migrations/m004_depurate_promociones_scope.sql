-- Migration m004: Depurate Promociones Scope (Paso 1)
-- Elimina columnas y llaves de contenido obsoletas para la sección Promociones.
-- Mantiene solo: id (1-7), dia_semana, imagen_fondo, activa.

-- 1. Eliminar entradas obsoletas de web_contenidos asociadas a promociones
DELETE FROM web_contenidos 
WHERE seccion = 'promociones' 
  AND (
       subseccion LIKE 'promo%_nombre' 
    OR subseccion LIKE 'promo%_subtitulo' 
    OR subseccion LIKE 'promo%_ayuno' 
    OR subseccion LIKE 'promo%_tiempo' 
    OR subseccion LIKE 'promo%_desc' 
    OR subseccion LIKE 'muestra%'
  );

-- 2. Depurar estructura de catalogo_promociones eliminando columnas de detalles de estudio/precios descontinuados
ALTER TABLE catalogo_promociones 
  DROP COLUMN IF EXISTS estudio_id,
  DROP COLUMN IF EXISTS descripcion,
  DROP COLUMN IF EXISTS precio_regular,
  DROP COLUMN IF EXISTS precio_oferta;
