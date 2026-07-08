USE `vcd01`;

-- Idempotencia para reintentos offline de PWA.
-- Cada comanda creada en IndexedDB viaja con uuid_local y se persiste aqui como client_uuid.
ALTER TABLE `comandas`
ADD COLUMN IF NOT EXISTS `client_uuid` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `id`;

CREATE UNIQUE INDEX IF NOT EXISTS `uk_comandas_client_uuid` ON `comandas` (`client_uuid`);
