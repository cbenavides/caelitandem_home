-- m006_rol_sitioweb.sql — 2026-09-30
-- Nuevo rol operativo SITIOWEB: un recepcionista existente puede ser promovido
-- desde "Personal de Recepción y Administradores" para que SOLO acceda a
-- Contenidos del Sitio Web (/laesh/adrc/). Sus permisos RBAC ({gestionar_cms})
-- los asigna RC\Negocio\Ordenes::cambiarRolPersonal() — aquí solo se amplía el ENUM.
-- Idempotente: MODIFY con el mismo ENUM es no-op si ya se aplicó.
USE `laesh_db`;

ALTER TABLE `empleados`
    MODIFY `rol` ENUM('MEDICO','RECEPCION','ADMIN','SITIOWEB') NOT NULL;
