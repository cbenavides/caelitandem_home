/*M!999999\- enable the sandbox mode */ 
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `catalogo_promociones` (`id`, `dia_semana`, `imagen_fondo`, `activo`, `orden`, `creado_en`, `actualizado_en`) VALUES (1,'<p>Lunes</p>','/laesh-web-assets-uipv1a/cms/promo-1-20260925-9b69baeb.webp',1,1,'2026-09-17 21:55:05','2026-09-25 23:57:26'),
(2,'<p>Martes</p>','/laesh-web-assets-uipv1a/cms/promo-2-20260925-f5e395fb.webp',1,2,'2026-09-17 21:55:05','2026-09-25 23:57:26'),
(3,'<p>Miercoles</p>','/laesh-web-assets-uipv1a/cms/promo-3-20260925-9687ecec.webp',1,3,'2026-09-17 21:55:05','2026-09-25 23:57:26'),
(4,'<p>Jueves</p>','/laesh-web-assets-uipv1a/cms/promo-4-20260925-df907bc0.webp',1,4,'2026-09-17 21:55:05','2026-09-25 23:57:26'),
(5,'<p>Viernes</p>','/laesh-web-assets-uipv1a/cms/promo-5-20260925-425956c4.webp',1,5,'2026-09-17 21:55:05','2026-09-25 23:57:26'),
(6,'<p>Sabado</p>','/laesh-web-assets-uipv1a/cms/promo-6-20260925-ffd85727.webp',1,6,'2026-09-17 21:55:05','2026-09-25 23:57:26'),
(7,'<p>Domingo</p>','/laesh-web-assets-uipv1a/cms/promo-7-20260925-b19074a7.webp',1,7,'2026-09-17 21:55:05','2026-09-25 23:57:26');
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
