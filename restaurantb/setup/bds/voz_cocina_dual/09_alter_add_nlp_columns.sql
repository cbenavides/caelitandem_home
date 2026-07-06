USE `vcd01`;

-- Nuevas columnas para soporte avanzado de NLP (VOSK/Levenshtein) y metadatos de precios
ALTER TABLE `productos`
  ADD COLUMN IF NOT EXISTS `precio_orden`    decimal(10,2)          DEFAULT NULL AFTER `precio`,
  ADD COLUMN IF NOT EXISTS `cantidad_orden`  tinyint(3) unsigned    DEFAULT NULL AFTER `precio_orden`,
  ADD COLUMN IF NOT EXISTS `sinonimos_json`  text                   DEFAULT NULL AFTER `palabras_clave`,
  ADD COLUMN IF NOT EXISTS `image_emoji`     varchar(10)            DEFAULT '🍽️' AFTER `sinonimos_json`;
