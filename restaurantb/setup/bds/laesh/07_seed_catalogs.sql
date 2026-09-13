-- Deshabilitar modo estricto para este seed (MariaDB 11.8 rechaza truncaciones
-- que versiones anteriores solo advertían). Se restaura al final de la sesión.
SET SESSION sql_mode = '';

-- =============================================================================
-- LAESH Bloc Digital — Script 07: Datos Semilla de Catálogos
-- Fuentes: medicos.html (estudios checkboxes), labadmin.html (select#estudio-categoria)
--          gestion-web.html (valores de nombre/texto de paneles)
-- Idempotente: INSERT IGNORE (no duplica si ya existe).
--
-- SSOT Refactor (2026-08-22):
--   • estudios = fuente de verdad de todo dato clínico (nombre, precio, ayuno, tiempo, clave, muestra)
--   • configuraciones = singletons institucionales (dirección, teléfono, email, horarios, responsable, Schema)
--   • web_contenidos = solo contenido editorial que NO se puede derivar de entidades
--   Principio: si un dato aparece en más de una sección, vive en configuraciones o estudios, NO en web_contenidos.
-- =============================================================================

USE `laesh_db`;

-- ---------------------------------------------------------------------------
-- CAT_ESTADOS_MEDICO — Semilla
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `cat_estados_medico` (`id`, `nombre`, `descripcion`) VALUES
    (1, 'Activo',  'El médico puede crear y consultar órdenes'),
    (2, 'Pausado', 'El médico no puede crear órdenes; su historial se conserva');

-- ---------------------------------------------------------------------------
-- CATALOGO_ESTADOS — Semilla (estados de orden)
-- Redesign v2: campo 'valor' (era 'nombre'); 4 estados alineados con medicos.js y ET
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `catalogo_estados` (`id`, `valor`, `descripcion`, `color_hex`) VALUES
    (1, 'Remitido',          'Orden creada por el médico, en espera de atención en recepción', '#F59E0B'),
    (2, 'En Atención',       'Paciente recibido en recepción, muestras en proceso',            '#3B82F6'),
    (3, 'Resultados Listos', 'PDF de resultados cargado, disponible para el médico',           '#10B981'),
    (4, 'Cerrada',           'Orden finalizada y entregada',                                   '#6B7280');

-- ---------------------------------------------------------------------------
-- FOLIOS_CONTROL — Serie inicial LAESH (orden_laboratorio)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `folios_control` (`tipo_documento`, `prefijo`, `longitud`, `ultimo_folio`) VALUES
    ('orden_laboratorio', 'LAESH', 5, 0);

-- ---------------------------------------------------------------------------
-- RBAC_PERMISOS — Permisos del sistema
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `rbac_permisos` (`nombre`, `descripcion`) VALUES
    ('ver_ordenes_propias',  'Médico: consultar y crear sus propias órdenes'),
    ('ver_solicitud_digital','Médico: ver PDF de solicitud digital'),
    ('gestionar_ordenes',    'Recepción: procesar órdenes, cambiar estados, subir PDFs'),
    ('gestionar_medicos',    'Recepción/Admin: alta, edición y pausa de médicos'),
    ('gestionar_cms',        'Admin: editar contenidos del sitio web (CMS)'),
    ('gestionar_estudios',   'Admin: alta y edición del catálogo de estudios'),
    ('ver_reportes',         'Admin/Recepción: acceso a reportes de actividad');

-- ---------------------------------------------------------------------------
-- CONFIGURACIONES — Singletons globales de instancia (clave → valor)
-- SSOT: datos que aparecen en >1 sección del sitio viven AQUÍ.
-- Panel CMS: Ubicación y Contacto es el editor master de estas claves.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `configuraciones` (`clave`, `valor`, `descripcion`) VALUES
    -- Identidad institucional
    ('nombre_laboratorio',      'Laboratorio de Especialidades Hematológicas',
                                 'Nombre oficial del laboratorio'),
    ('nombre_corto',            'LAESH',
                                 'Nombre corto / marca'),
    -- Contacto y ubicación
    ('direccion_calle',         'Azucenas #8, Fraccionamiento Jardines del Sur',
                                 'Calle y colonia de la dirección física'),
    ('ciudad',                  'Huajuapan de León',
                                 'Ciudad / Municipio — reutilizado en Ubicación, SEO y Schema.org'),
    ('estado',                  'Oaxaca',
                                 'Estado federativo'),
    ('cp',                      '69007',
                                 'Código postal — Schema.org postalCode'),
    ('telefono',                '953 688 7694',
                                 'Teléfono directo — reutilizado en Ubicación, Footer y Schema.org'),
    ('email_contacto',          'lab_laesh@hotmail.com',
                                 'Correo de contacto público — reutilizado en Ubicación y Footer'),
    ('whatsapp_numero',         '953 119 0074',
                                 'Número WhatsApp formato display (sin código de país) — Footer, Ubicación'),
    -- Horarios
    ('horario_semana',          'Lunes a sábado: 7:00 a.m. – 9:00 p.m.',
                                 'Horario días hábiles — Footer, Ubicación, Schema.org'),
    ('horario_domingo',         'Domingo: 7:00 a.m. – 3:00 p.m.',
                                 'Horario domingo — Footer, Ubicación, Schema.org'),
    ('hrs_open',                '07:00',
                                 'Apertura Lun–Sáb HH:MM 24h — Schema.org openingHoursSpecification'),
    ('hrs_close',               '21:00',
                                 'Cierre Lun–Sáb HH:MM 24h — Schema.org openingHoursSpecification'),
    ('dom_open',                '07:00',
                                 'Apertura domingo HH:MM 24h — Schema.org openingHoursSpecification'),
    ('dom_close',               '15:00',
                                 'Cierre domingo HH:MM 24h — Schema.org openingHoursSpecification'),
    -- Responsable sanitario (campos individuales — para Footer, SEO y Quiénes Somos)
    ('responsable_nombre',      'Q.F.B. y E.H.D.L. Jacob Santiago Blanco',
                                 'Nombre completo con grado del responsable sanitario'),
    ('responsable_cedula_prof', '3609293',
                                 'Cédula profesional del responsable sanitario'),
    ('responsable_cedula_esp',  '8935780',
                                 'Cédula de especialidad del responsable sanitario'),
    -- Redes sociales y mapas
    ('facebook_url',            'https://www.facebook.com/profile.php?id=100072263716098',
                                 'URL de la página oficial de Facebook del laboratorio'),
    ('maps_url',                'https://www.google.com/maps/dir/?api=1&destination=Laboratorio+de+Especialidades+Hematol%C3%B3gicas+S.C.,+Calle+Azucenas+%238,+Jardines+del+Sur,+69007+Heroica+Cdad.+de+Huajuapan+de+Le%C3%B3n,+Oax.',
                                 'URL directa a la ubicación en Google Maps (Cómo llegar)'),
    ('wa_texto_agendar',        'Hola LAESH, me interesa agendar el estudio de {estudio}',
                                 'Texto pre-llenado de WhatsApp al agendar en Promociones'),
    ('wa_texto_info',           'Hola LAESH, necesito información',
                                 'Texto pre-llenado de WhatsApp para consultas generales'),
    -- Operaciones internas y P2 Bloc Digital
    ('tiempo_rotacion_dias',    '90',
                                 'Días de validez antes de solicitar cambio de contraseña (admin policy)'),
    ('tiempo_depuracion_pdf_meses', '12',
                                 'Meses de retención de archivos PDF generados antes de la depuración automática'),
    ('ruta_almacenamiento_pdf', '/var/www/html/laesh-bloc-assets/pdf/',
                                 'Ruta física de almacenamiento seguro de PDFs de recibos'),
    ('anios_experiencia',       '25',
                                 'Años de experiencia — usado en mensajes del sitio web'),
    -- Sesión PHP
    ('session_lifetime',        '518400',
                                 'Duración de sesión PHP en segundos. 86400=24h · 518400=6 días. Se aplica en commons.php al iniciar sesión. Requiere recargar la página para que el nuevo valor tenga efecto.')
ON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`), `descripcion` = VALUES(`descripcion`);

-- ---------------------------------------------------------------------------
-- CATALOGOS_UI — Universidades y Lugares de Trabajo
-- ---------------------------------------------------------------------------
-- Universidades (tipo=universidad)
INSERT IGNORE INTO `catalogos_ui` (`tipo`, `valor`, `orden`, `activo`) VALUES
    ('universidad', 'Universidad Nacional Autónoma de México (UNAM)',    1, 1),
    ('universidad', 'Universidad Autónoma Benito Juárez de Oaxaca',      2, 1),
    ('universidad', 'Universidad Autónoma Metropolitana (UAM)',           3, 1),
    ('universidad', 'Instituto Politécnico Nacional (IPN)',               4, 1),
    ('universidad', 'Universidad Autónoma de Guadalajara',               5, 1),
    ('universidad', 'Universidad Autónoma de Puebla (BUAP)',             6, 1),
    ('universidad', 'Universidad Veracruzana',                           7, 1),
    ('universidad', 'Universidad Autónoma del Estado de México',         8, 1),
    ('universidad', 'Otra universidad',                                  99, 1);

-- Lugares de trabajo (tipo=lugar_trabajo)
INSERT IGNORE INTO `catalogos_ui` (`tipo`, `valor`, `orden`, `activo`) VALUES
    ('lugar_trabajo', 'Consultorio particular',                          1, 1),
    ('lugar_trabajo', 'Hospital General de Huajuapan',                   2, 1),
    ('lugar_trabajo', 'IMSS — Delegación Oaxaca',                        3, 1),
    ('lugar_trabajo', 'ISSSTE — Unidad Huajuapan',                       4, 1),
    ('lugar_trabajo', 'Clínica privada',                                  5, 1),
    ('lugar_trabajo', 'Hospital Regional de la Mixteca',                  6, 1),
    ('lugar_trabajo', 'Otro',                                            99, 1);

-- ---------------------------------------------------------------------------
-- CATALOGOS RELACIONALES — Datos extraídos de la base de datos viva
-- ---------------------------------------------------------------------------
LOCK TABLES `catalogo_grupos` WRITE;
INSERT IGNORE INTO `catalogo_grupos` VALUES (1,'cg1','Rutina General — Hematología, Química Clínica, Electrolitos, Uroanálisis, CoagulaciónTT',1),(2,'cg2','Función de Órganos — Hepática, Tiroidea, Pancreática, Renal, Cardiaca, GasometríaYY',2),(3,'cg3','Hormonas, Diabetes e Inmunología — Perfil Ginecológico, Masculino, Diabetes, Inmunología, Reumatología',3),(4,'cg4','Bacteriología, Marcadores Tumorales, Parasitología, Citroquímicos, Biología Molecular, Fertilidad',4);
UNLOCK TABLES;
LOCK TABLES `catalogo_categorias` WRITE;
INSERT IGNORE INTO `catalogo_categorias` VALUES (1,1,'Hematología',1),(2,1,'Química Clínica',2),(3,1,'Electrolitos Séricos',3),(4,1,'Uroanálisis',4),(5,1,'Coagulación',5),(6,1,'Lípidos',6),(7,2,'Función Hepática',1),(8,2,'Función Tiroidea',2),(9,2,'Función Pancreática',3),(10,2,'Función Renal',4),(11,2,'Función Cardiaca',5),(12,2,'Gasometría',6),(13,3,'Hormonas',1),(14,3,'Diabetes',2),(15,3,'Inmunología',3),(16,3,'Reumatología',4),(17,3,'Diversos',5),(18,4,'Bacteriología',1),(19,4,'Marcadores Tumorales',2),(20,4,'Parasitología',3),(21,4,'Citroquímicos',4),(22,4,'Biología Molecular',5),(23,4,'Fertilidad',6);
UNLOCK TABLES;
LOCK TABLES `catalogo_estudios` WRITE;
INSERT IGNORE INTO `catalogo_estudios` VALUES (1,1,'HEM-01','BHC','4 Horas','Sangre total (Tubo Lila/EDTA)','Sin ayuno estricto (ideal 4 hrs)',NULL,0.00,1),(2,1,'HEM-02','GRUPO SANGUINEO y FACTOR Rh','2 Horas','Sangre total (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(3,1,'HEM-03','Plaquetas','4 Horas','Sangre total (Tubo Lila/EDTA)','Sin ayuno',NULL,0.00,1),(4,1,'GEN-6552','VSG','','','',NULL,0.00,1),(5,1,'HEM-05','Reticulocitos','6 Horas','Sangre total (Tubo Lila/EDTA)','Sin ayuno',NULL,0.00,1),(6,1,'GEN-8794','Perfil de Hierro','','','',NULL,0.00,1),(7,2,'GEN-8558','QS3','','','',NULL,0.00,1),(8,2,'GEN-1807','QS7','','','',NULL,0.00,1),(9,2,'GEN-7978','Perfil Bioquímico 15/24/30/35/45','','','',NULL,0.00,1),(10,2,'GEN-1927','Glucosa','','','',NULL,0.00,1),(11,2,'GEN-6331','Creatinina','','','',NULL,0.00,1),(12,2,'GEN-1746','Colesterol','','','',NULL,0.00,1),(13,2,'QUI-11','Triglicéridos','2 Horas','Suero (Tubo Rojo)','9–12 hrs de ayuno',NULL,0.00,1),(14,3,'GEN-1844','ES 3/4/Completos','','','',NULL,0.00,1),(15,3,'GEN-9574','Calcio','','','',NULL,0.00,1),(16,3,'GEN-2936','Fósforo','','','',NULL,0.00,1),(17,3,'GEN-9539','Magnesio','','','',NULL,0.00,1),(18,3,'GEN-6777','Bicarbonato CO2','','','',NULL,0.00,1),(19,4,'URO-01','EXAMEN GENERAL DE ORINA CUANTITATIVO','4 Horas','Orina de primer chorro (frasco limpio)','Sin ayuno; orina matutina preferida',NULL,0.00,1),(20,4,'GEN-7280','EGO Especializado','','','',NULL,0.00,1),(21,4,'GEN-3945','Antidoping 5/12 elem.','','','',NULL,0.00,1),(22,5,'GEN-7159','Perfil de Coagulación','','','',NULL,0.00,1),(23,5,'GEN-2337','TP/INR','','','',NULL,0.00,1),(24,5,'GEN-3713','TTPa','','','',NULL,0.00,1),(25,5,'COA-05','Fibrinógeno','4 Horas','Plasma (Tubo Azul citrato)','Sin ayuno',NULL,0.00,1),(26,5,'COA-06','Dímero D','4 Horas','Plasma (Tubo Azul citrato)','Sin ayuno',NULL,0.00,1),(27,5,'GEN-8787','T. Sangrado','','','',NULL,0.00,1),(28,6,'GEN-1869','Perfil de Lípidos I','','','',NULL,0.00,1),(29,6,'GEN-3650','II','','','',NULL,0.00,1),(30,6,'GEN-7130','Perfil Aterogénico','','','',NULL,0.00,1),(31,7,'GEN-2807','PFH Básico','','','',NULL,0.00,1),(32,7,'GEN-1460','PFH Completo','','','',NULL,0.00,1),(33,7,'GEN-7111','Transaminasas','','','',NULL,0.00,1),(34,7,'GEN-7275','GGT','','','',NULL,0.00,1),(35,7,'GEN-9831','Proteínas Totales','','','',NULL,0.00,1),(36,7,'GEN-9313','Albumina','','','',NULL,0.00,1),(37,8,'GEN-2914','Perfil Tiroideo I-IV','','','',NULL,0.00,1),(38,8,'GEN-8400','TSH','','','',NULL,0.00,1),(39,8,'GEN-3254','Ac. Anti Tiroideos I-II','','','',NULL,0.00,1),(40,8,'GEN-6247','Ac. Anti Receptor TSH','','','',NULL,0.00,1),(41,8,'GEN-9679','Tiroglobulina','','','',NULL,0.00,1),(42,9,'PAN-01','Amilasa sérica','2 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(43,9,'PAN-02','Lipasa sérica','2 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(44,10,'REN-01','Cistatina C','24 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(45,10,'GEN-4480','Depuración creatinina','','','',NULL,0.00,1),(46,10,'GEN-2858','Proteínas orina','','','',NULL,0.00,1),(47,10,'REN-04','Microalbuminuria','4 Horas','Orina de primer chorro o 24 h','Sin ayuno; orina matutina preferida',NULL,0.00,1),(48,11,'GEN-8934','Triage cardiaco','','','',NULL,0.00,1),(49,11,'GEN-6200','Perfil cardiaco completo','','','',NULL,0.00,1),(50,11,'CAR-03','Troponina I','1 Hora','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(51,11,'CAR-04','Troponina T','1 Hora','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(52,11,'GEN-1322','NT-pro BNP','','','',NULL,0.00,1),(53,11,'CAR-07','Mioglobina','1 Hora','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(54,12,'GAS-01','GASOMETRIA ARTERIAL COMPLETA','1 Hora','Sangre arterial (jeringa heparinizada)','Sin ayuno; urgencia; procesamiento inmediato (<15 min)',NULL,0.00,1),(55,12,'GAS-02','Gasometría Venosa Completa','1 Hora','Sangre venosa (jeringa heparinizada)','Sin ayuno; procesamiento inmediato (<15 min)',NULL,0.00,1),(56,13,'GEN-1406','Perfil Ginecológico I-II','','','',NULL,0.00,1),(57,13,'GEN-4207','Perfil Hormonal Masculino','','','',NULL,0.00,1),(58,13,'GEN-6206','FSH','','','',NULL,0.00,1),(59,13,'GEN-1645','LH','','','',NULL,0.00,1),(60,13,'GEN-7406','PRL','','','',NULL,0.00,1),(61,13,'GEN-4307','PROG','','','',NULL,0.00,1),(62,13,'GEN-7092','TESTOSTERONA Total/Libre','','','',NULL,0.00,1),(63,13,'GEN-6345','DHEA-S','','','',NULL,0.00,1),(64,13,'HOR-12','Cortisol','24 Horas','Suero (Tubo Rojo)','Sin ayuno; muestra matutina (8–9 am); sin estrés previo',NULL,0.00,1),(65,13,'GEN-8913','AMH','','','',NULL,0.00,1),(66,13,'GEN-2442','PTH-i','','','',NULL,0.00,1),(67,14,'GEN-8561','HbA1c','','','',NULL,0.00,1),(68,14,'DIA-02','Insulina','4 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(69,14,'GEN-2486','HOMA-IR','','','',NULL,0.00,1),(70,14,'DIA-04','Péptido C','24 Horas','Suero (Tubo Rojo)','8 hrs de ayuno',NULL,0.00,1),(71,14,'GEN-9787','Prueba de Tolerancia Glucosa','','','',NULL,0.00,1),(72,14,'GEN-7428','Test O\'Sullivan','','','',NULL,0.00,1),(73,15,'GEN-2743','HIV 1/2','','','',NULL,0.00,1),(74,15,'GEN-6197','V.D.R.L.','','','',NULL,0.00,1),(75,15,'INM-03','Reacciones Febriles','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(76,15,'GEN-1076','Hepatitis A-B-C','','','',NULL,0.00,1),(77,15,'GEN-5580','Dengue','','','',NULL,0.00,1),(78,15,'GEN-8487','COVID-19','','','',NULL,0.00,1),(79,15,'GEN-5761','Coombs','','','',NULL,0.00,1),(80,15,'INM-15','Procalcitonina','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(81,16,'GEN-6885','Perfil Reumático','','','',NULL,0.00,1),(82,16,'GEN-9635','PCR','','','',NULL,0.00,1),(83,16,'GEN-9830','Factor Reumatoide','','','',NULL,0.00,1),(84,16,'GEN-8074','CCP','','','',NULL,0.00,1),(85,16,'GEN-5186','ANA','','','',NULL,0.00,1),(86,16,'GEN-9904','Anti DNA','','','',NULL,0.00,1),(87,16,'GEN-6329','Complementos C3/C4','','','',NULL,0.00,1),(88,17,'GEN-8910','Vitamina D','','','',NULL,0.00,1),(89,17,'GEN-5010','Inmunoglobulina E','','','',NULL,0.00,1),(90,17,'GEN-5032','Somatomedina C','','','',NULL,0.00,1),(91,17,'GEN-6913','Papanicolaou','','','',NULL,0.00,1),(92,18,'GEN-3694','Cultivo de orina MIC','','','',NULL,0.00,1),(93,18,'GEN-6253','Ex. Faríngeo MIC','','','',NULL,0.00,1),(94,18,'GEN-5756','Ex. Vaginal MIC','','','',NULL,0.00,1),(95,18,'GEN-8973','Uretral MIC','','','',NULL,0.00,1),(96,18,'GEN-3626','Heces MIC','','','',NULL,0.00,1),(97,18,'GEN-2059','Lesión MIC','','','',NULL,0.00,1),(98,18,'GEN-4065','Expectoración MIC','','','',NULL,0.00,1),(99,18,'GEN-6380','Hemocultivo MIC','','','',NULL,0.00,1),(100,18,'BAC-09','Cultivo Micológico','21 Días','Muestra según sitio (raspado, hisopo, biopsia)','Suspender antifúngicos tópicos y sistémicos 7 días antes',NULL,0.00,1),(101,19,'GEN-3483','PSA Total','','','',NULL,0.00,1),(102,19,'GEN-3504','PSA Libre','','','',NULL,0.00,1),(103,19,'GEN-4416','CEA','','','',NULL,0.00,1),(104,19,'GEN-3002','AFP','','','',NULL,0.00,1),(105,19,'GEN-7655','CA-125','','','',NULL,0.00,1),(106,19,'GEN-8602','CA-15-3','','','',NULL,0.00,1),(107,19,'GEN-1102','CA-19-9','','','',NULL,0.00,1),(108,19,'GEN-4885','Perfil Tumoral Femenino/Masculino','','','',NULL,0.00,1),(109,20,'PAR-01','Coproparasitoscópico 3 muestras','24 Horas','Heces (3 muestras en frasco LAESH)','Muestras en días alternos; sin bario, bismuto ni antiparasitarios 3 días antes',NULL,0.00,1),(110,20,'GEN-4725','Coprológico completo/especial','','','',NULL,0.00,1),(111,20,'GEN-1815','Sangre Oculta','','','',NULL,0.00,1),(112,20,'GEN-7333','H. Pylori','','','',NULL,0.00,1),(113,20,'GEN-9700','Calprotectina','','','',NULL,0.00,1),(114,20,'GEN-4095','Lactoferrina','','','',NULL,0.00,1),(115,20,'GEN-9252','Clostridium difficile','','','',NULL,0.00,1),(116,21,'GEN-4856','LCR','','','',NULL,0.00,1),(117,21,'GEN-6279','Sinovial','','','',NULL,0.00,1),(118,21,'GEN-1077','Pleural','','','',NULL,0.00,1),(119,21,'GEN-4103','Ascitis','','','',NULL,0.00,1),(120,21,'GEN-2696','Diálisis','','','',NULL,0.00,1),(121,21,'GEN-3510','Bronquial','','','',NULL,0.00,1),(122,21,'LIQ-07','Pericárdico','','','',NULL,0.00,1),(123,22,'GEN-6241','PCR VPH','','','',NULL,0.00,1),(124,22,'GEN-2374','PCR Mycobacterium','','','',NULL,0.00,1),(125,22,'GEN-9525','PCR Patógenos respiratorios','','','',NULL,0.00,1),(126,22,'GEN-3235','PCR Meningitis viral','','','',NULL,0.00,1),(127,22,'GEN-6541','PCR SARS-CoV-2','','','',NULL,0.00,1),(128,23,'GEN-4575','Espermatobioscopia directa','','','',NULL,0.00,1),(129,2,'QUI-02','QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)','4 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(130,14,'DIA-01','HEMOGLOBINA GLICADA (Hb A1c)','4 Horas','Sangre total (Tubo Lila/EDTA)','Sin ayuno',NULL,0.00,1),(131,2,'QUI-01','QUIMICA SANGUINEA ( 3 ELEMENTOS)','4 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(132,3,'ELE-03','ELECTROLITOS SERICOS COMPLETOS','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(133,5,'COA-01','PERFIL DE COAGULACION 1 (TP, INR, TTP)','4 Horas','Plasma (Tubo Azul citrato)','Sin ayuno; no suspender anticoagulantes sin indicación médica',NULL,0.00,1),(134,7,'HEP-01','PERFIL HEPATICO (PFH)','4 Horas','Suero (Tubo Rojo)','8 hrs de ayuno (preferible)',NULL,0.00,1),(135,8,'TIR-01','PERFIL TIROIDEO 1','24 Horas','Suero (Tubo Rojo)','Sin ayuno; tomar muestra antes del medicamento tiroideo',NULL,0.00,1),(136,3,'ELE-02','ELECTROLITOS SERICOS (Na, K, Cl, Ca)','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(137,14,'DIA-03','RESISTENCIA A LAINSULINA (HOMA-IR, %8, %S).','4 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(138,7,'HEP-02','PERFIL HEPATICO 2 (PFH 2)','8 Horas','Suero + Plasma (Tubo Rojo y Azul)','8 hrs de ayuno',NULL,0.00,1),(139,6,'LIP-01','PERFIL DE LIPIDOS','4 Horas','Suero (Tubo Rojo)','9–12 hrs de ayuno',NULL,0.00,1),(140,8,'TIR-02','PERFIL TIROIDEO 2','24 Horas','Suero (Tubo Rojo)','Sin ayuno; tomar muestra antes del medicamento tiroideo',NULL,0.00,1),(141,3,'ELE-01','ELECTROLITOS SERICOS (Na, K, Cl)','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(142,2,'QUI-03','PERFIL BIOQUIMICO 15 ELEMENTOS','24 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(143,4,'URO-02','EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)','4 Horas','Orina de primer chorro (frasco limpio)','Sin ayuno; orina matutina preferida',NULL,0.00,1),(144,15,'INM-13','AC. ANTI DENGUE (NS1, IgM, IgG)','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1);
UNLOCK TABLES;

-- ---------------------------------------------------------------------------
-- SSOT: descripcion_breve + detalle + campos operativos para los 144 estudios
-- Folded from m002_ssot_content_population.sql (2026-09-13)
-- Idempotente: UPDATE con valores finales. Los INSERT IGNORE anteriores dejan
-- tiempo_procesamiento/muestra_requerida/preparacion vacíos para estudios GEN-XXXX;
-- estos UPDATE los populan en una sola pasada post-insert.
-- ---------------------------------------------------------------------------

-- Bloque B1: descripcion_breve + detalle IDs 1–50
UPDATE `catalogo_estudios` SET
  descripcion_breve = CASE id
    WHEN 1   THEN 'Análisis completo de células sanguíneas: eritrocitos, leucocitos y plaquetas'
    WHEN 2   THEN 'Determinación de grupo ABO y factor Rh'
    WHEN 3   THEN 'Conteo cuantitativo de plaquetas circulantes'
    WHEN 4   THEN 'Velocidad de sedimentación eritrocítica: marcador de inflamación'
    WHEN 5   THEN 'Porcentaje de eritrocitos inmaduros en sangre periférica'
    WHEN 6   THEN 'Hierro sérico, ferritina, TIBC y transferrina'
    WHEN 7   THEN 'Glucosa, urea y creatinina sérica'
    WHEN 8   THEN 'Glucosa, urea, creatinina, ácido úrico, colesterol, triglicéridos y BUN'
    WHEN 9   THEN 'Panel bioquímico de 15 a 45 parámetros metabólicos'
    WHEN 10  THEN 'Determinación de glucosa sérica en ayunas o posprandial'
    WHEN 11  THEN 'Marcador de filtración glomerular y función renal'
    WHEN 12  THEN 'Colesterol total sérico: riesgo cardiovascular'
    WHEN 13  THEN 'Grasas neutras séricas: riesgo metabólico y cardiovascular'
    WHEN 14  THEN 'Sodio, potasio, cloro y otros iones séricos'
    WHEN 15  THEN 'Calcio sérico total: función neuromuscular y ósea'
    WHEN 16  THEN 'Fósforo inorgánico sérico: metabolismo mineral'
    WHEN 17  THEN 'Magnesio sérico: metabolismo neuromuscular y cardíaco'
    WHEN 18  THEN 'Bicarbonato sérico: equilibrio ácido-base'
    WHEN 19  THEN 'Análisis fisicoquímico y microscópico cuantitativo de orina'
    WHEN 20  THEN 'EGO avanzado con sedimento urinario especializado'
    WHEN 21  THEN 'Tamizaje de sustancias psicoactivas en orina'
    WHEN 22  THEN 'TP, TTPa, fibrinógeno y tiempo de sangrado'
    WHEN 23  THEN 'Tiempo de protrombina con índice internacional normalizado'
    WHEN 24  THEN 'Tiempo de tromboplastina parcial activada'
    WHEN 25  THEN 'Proteína de la coagulación: red de fibrina'
    WHEN 26  THEN 'Marcador de trombosis activa y trombolisis'
    WHEN 27  THEN 'Tiempo de sangrado: función plaquetaria primaria'
    WHEN 28  THEN 'Colesterol total, HDL, LDL y triglicéridos'
    WHEN 29  THEN 'Perfil lipídico con colesterol no-HDL y partículas LDL'
    WHEN 30  THEN 'Perfil lipídico con índices de riesgo cardiovascular calculados'
    WHEN 31  THEN 'TGO, TGP, fosfatasa alcalina y bilirrubinas'
    WHEN 32  THEN 'PFH básico más GGT, proteínas totales y albúmina'
    WHEN 33  THEN 'Aminotransferasas hepáticas: daño hepatocelular'
    WHEN 34  THEN 'Gamma-glutamil transferasa: daño hepático por alcohol o fármacos'
    WHEN 35  THEN 'Proteínas totales séricas: estado nutricional y función hepática'
    WHEN 36  THEN 'Albúmina sérica: marcador de función hepática y estado nutricional'
    WHEN 37  THEN 'Perfiles tiroideos I a IV según indicación clínica'
    WHEN 38  THEN 'Hormona estimulante del tiroides: tamizaje y control tiroideo'
    WHEN 39  THEN 'Anti-TPO y anti-tiroglobulina: autoinmunidad tiroidea'
    WHEN 40  THEN 'Anticuerpos bloqueadores del receptor de TSH (TRAb)'
    WHEN 41  THEN 'Marcador de seguimiento en cáncer diferenciado de tiroides'
    WHEN 42  THEN 'Enzima pancreática exocrina sérica: pancreatitis aguda'
    WHEN 43  THEN 'Marcador pancreático más específico que amilasa'
    WHEN 44  THEN 'Biomarcador endógeno de TFG libre de dieta y masa muscular'
    WHEN 45  THEN 'Aclaramiento renal de creatinina en orina de 24 horas'
    WHEN 46  THEN 'Proteinuria de 24 horas: daño glomerular o tubular'
    WHEN 47  THEN 'Albuminuria de baja concentración: nefropatía temprana'
    WHEN 48  THEN 'Troponina, CK-MB y mioglobina para síndrome coronario'
    WHEN 49  THEN 'Panel cardíaco completo con marcadores de daño y función'
    WHEN 50  THEN 'Marcador de necrosis miocárdica: infarto agudo'
    ELSE descripcion_breve
  END,
  detalle = CASE id
    WHEN 1   THEN '<p>La Biometría Hemática Completa (BHC) cuantifica los tres linajes celulares sanguíneos: eritrocitos (con hemoglobina, hematocrito, VCM, HCM, CHCM y ADE), leucocitos totales con fórmula diferencial de 5 partes, y plaquetas (con VPM). Es el estudio de tamizaje más solicitado en medicina: detecta anemia, infecciones, leucemias, trombocitopenias y estados inflamatorios crónicos.</p>'
    WHEN 2   THEN '<p>Determina el grupo sanguíneo ABO mediante prueba directa (antígenos en glóbulos rojos) e inversa (anticuerpos en suero), y clasifica el factor Rh como positivo o negativo. Indispensable para transfusiones, trasplantes, embarazo y compatibilidad neonatal.</p>'
    WHEN 3   THEN '<p>Cuenta el número de plaquetas circulantes por microlitro de sangre. Valores por debajo de 150,000/µL (trombocitopenia) pueden causar sangrado espontáneo; valores superiores a 450,000/µL (trombocitosis) aumentan el riesgo trombótico. Indicado en púrpura, coagulopatías y seguimiento de quimioterapia.</p>'
    WHEN 4   THEN '<p>Mide la velocidad a la que los eritrocitos sedimentan en una hora. Es un marcador inespecífico de inflamación sistémica: elevado en infecciones crónicas, enfermedades autoinmunes, neoplasias y embarazo. Se interpreta siempre junto con la PCR para diferenciar inflamación aguda de crónica.</p>'
    WHEN 5   THEN '<p>Los reticulocitos son eritrocitos inmaduros con ARN residual. Su porcentaje refleja la actividad eritropoyética medular: elevado en anemias hemolíticas y post-hemorragia; disminuido en aplasia medular. El índice de reticulocitos corregido diferencia anemias hiperregenerativas de hiporregenerativas.</p>'
    WHEN 6   THEN '<p>Evalúa el metabolismo del hierro midiendo: hierro sérico (disponible), ferritina (reservas tisulares), TIBC (capacidad de unión) y transferrina (proteína transportadora). Permite diferenciar anemia ferropénica (ferritina baja, TIBC alta) de anemia de enfermedad crónica (ferritina normal o alta, TIBC baja).</p>'
    WHEN 7   THEN '<p>Determina glucosa, urea y creatinina sérica. Perfil básico para la valoración del metabolismo de carbohidratos y la función renal. Indicado como tamizaje en chequeos preventivos y seguimiento de pacientes con diabetes o insuficiencia renal.</p>'
    WHEN 8   THEN '<p>Mide simultáneamente glucosa, urea, creatinina, ácido úrico, colesterol, triglicéridos y nitrógeno ureico en sangre (BUN). Proporciona una visión integral del metabolismo de carbohidratos, lípidos y proteínas, así como de la función renal. Es el perfil metabólico más completo de primera línea.</p>'
    WHEN 9   THEN '<p>Panel metabólico ampliado que combina bioquímica hepática, renal y lipídica en una sola muestra. Dependiendo del número de parámetros elegido (15, 24, 30, 35 o 45), puede incluir glucosa, urea, creatinina, ácido úrico, lípidos, enzimas hepáticas, proteínas, bilirrubinas y electrolitos.</p>'
    WHEN 10  THEN '<p>La glucosa sérica en ayunas es el parámetro estándar para el diagnóstico de diabetes mellitus (mayor o igual a 126 mg/dL en dos ocasiones) y prediabetes (100–125 mg/dL). La glucosa posprandial a 2 horas (mayor o igual a 200 mg/dL) también es diagnóstica. Se recomienda monitoreo periódico en pacientes con factores de riesgo metabólico.</p>'
    WHEN 11  THEN '<p>La creatinina es el producto de degradación de la fosfocreatina muscular, filtrada libremente por el glomérulo y no reabsorbida. Su elevación indica reducción de la tasa de filtración glomerular (TFG). Se interpreta junto con la ecuación CKD-EPI para estimar la TFG según edad, sexo y raza.</p>'
    WHEN 12  THEN '<p>El colesterol total es la suma de las fracciones LDL, HDL y VLDL. Valores superiores a 200 mg/dL (hipercolesterolemia) aumentan el riesgo aterosclerótico. Su interpretación es más útil en el contexto del perfil lipídico completo, considerando el cociente CT/HDL como índice de riesgo cardiovascular.</p>'
    WHEN 13  THEN '<p>Los triglicéridos son lípidos neutros almacenados en tejido adiposo y circulantes en quilomicrones y VLDL. Niveles superiores a 150 mg/dL se asocian con síndrome metabólico; mayores a 500 mg/dL aumentan el riesgo de pancreatitis aguda. Se determinan en ayunas de 9–12 horas para evitar interferencias postprandiales.</p>'
    WHEN 14  THEN '<p>Mide los principales iones séricos: sodio (osmorregulación), potasio (función neuromuscular y cardíaca), cloro, calcio, magnesio y fósforo. Su alteración provoca manifestaciones neuromusculares, arritmias y trastornos del equilibrio ácido-base. Indicado en pacientes hospitalizados, usuarios de diuréticos y con enfermedades renales o endocrinas.</p>'
    WHEN 15  THEN '<p>El calcio sérico total refleja la suma del calcio ionizado (biológicamente activo, 50%), el unido a proteínas (albúmina, 40%) y el complejado con aniones (10%). La hipocalcemia causa tetania y convulsiones; la hipercalcemia provoca poliuria, nefrolitiasis y depresión. Se corrige según albúmina: Ca corregido = Ca medido + 0.8 × (4 – albúmina).</p>'
    WHEN 16  THEN '<p>El fósforo inorgánico sérico participa en el metabolismo energético (ATP), el equilibrio ácido-base y la mineralización ósea. La hiperfosfatemia es característica de la insuficiencia renal crónica; la hipofosfatemia ocurre en malnutrición y síndrome de realimentación.</p>'
    WHEN 17  THEN '<p>El magnesio es el segundo catión intracelular más abundante; actúa como cofactor de más de 300 enzimas. La hipomagnesemia causa arritmias, espasmos musculares e hipopotasemia refractaria. Frecuente en alcoholismo, uso de diuréticos de asa, diabetes y malabsorción intestinal.</p>'
    WHEN 18  THEN '<p>El bicarbonato sérico total (CO2 total) es el principal amortiguador del equilibrio ácido-base extracelular. Su disminución indica acidosis metabólica (diabetes, insuficiencia renal); su elevación indica alcalosis metabólica (vómitos, uso de diuréticos). Se interpreta junto con el pH arterial y la PCO2.</p>'
    WHEN 19  THEN '<p>El examen general de orina cuantitativo evalúa: caracteres físicos (color, aspecto, densidad), análisis químico por tira reactiva (pH, glucosa, proteínas, cetonas, sangre, bilirrubina, urobilinógeno, nitritos, esterasa leucocitaria) y sedimento urinario microscópico (leucocitos, eritrocitos, cilindros, bacterias, cristales). Es el tamizaje renal y metabólico estándar.</p>'
    WHEN 20  THEN '<p>Complementa el EGO convencional con técnicas de concentración y coloración especiales que mejoran la detección de cilindros, células epiteliales atípicas y microorganismos. Indicado en proteinuria, hematuria de origen incierto y seguimiento de glomerulopatías.</p>'
    WHEN 21  THEN '<p>Detecta la presencia de sustancias psicoactivas en orina mediante inmunocromatografía. El panel de 5 elementos incluye mariguana, cocaína, anfetaminas, opiáceos y benzodiacepinas; el panel de 12 elementos agrega metanfetaminas, barbitúricos, PCP, MDMA, oxicodona, propoxifeno y buprenorfina. Se utiliza en medicina del trabajo, clínica de adicciones y medicina forense.</p>'
    WHEN 22  THEN '<p>Perfil hemostático completo que incluye: tiempo de protrombina con INR (vía extrínseca), tiempo de tromboplastina parcial activada (vía intrínseca), fibrinógeno (cuantificación de la proteína clave de la red de fibrina) y tiempo de sangrado (función plaquetaria primaria). Indica en preoperatorios, sospecha de coagulopatía y monitoreo de anticoagulantes.</p>'
    WHEN 23  THEN '<p>El tiempo de protrombina (TP) evalúa la vía extrínseca de la coagulación (factores VII, X, V, II y I). El INR estandariza el resultado para el monitoreo de anticoagulantes cumarínicos (warfarina). Un INR terapéutico para fibrilación auricular o trombosis venosa es de 2.0–3.0.</p>'
    WHEN 24  THEN '<p>El TTPa evalúa la vía intrínseca de la coagulación (factores XII, XI, IX, VIII, X, V, II y I). Es el parámetro guía para el monitoreo de heparina no fraccionada (rango terapéutico: 1.5–2.5 veces el valor de referencia) y para el diagnóstico de hemofilia A y B.</p>'
    WHEN 25  THEN '<p>El fibrinógeno es el precursor soluble de la fibrina, sintetizado en el hígado. Su reducción (hipofibrinogenemia) ocurre en CID, enfermedad hepática grave y fibrinólisis primaria. Niveles elevados son un factor de riesgo cardiovascular independiente. Esencial en el diagnóstico de coagulopatías de consumo.</p>'
    WHEN 26  THEN '<p>El Dímero D es el producto de degradación de la fibrina entrecruzada. Un resultado negativo tiene alto valor predictivo negativo para excluir tromboembolismo venoso (TEP, TVP) con baja probabilidad pretest. Un resultado positivo no es específico y requiere imagen confirmatoria.</p>'
    WHEN 27  THEN '<p>El tiempo de sangrado mide la función hemostática primaria: la interacción entre plaquetas, factor von Willebrand y subendotelio vascular. Prolongado en trombocitopenia, enfermedad de von Willebrand, aspirina y uremia. Ha sido reemplazado en gran parte por la agregometría plaquetaria y el PFA-100 en laboratorios modernos.</p>'
    WHEN 28  THEN '<p>El perfil de lípidos básico (Perfil I) incluye colesterol total, HDL, LDL y triglicéridos. Permite calcular el colesterol no-HDL y el cociente CT/HDL como índices de riesgo cardiovascular. Es la prueba de tamizaje estándar recomendada en adultos mayores de 20 años según las guías ACC/AHA 2018.</p>'
    WHEN 29  THEN '<p>El Perfil de Lípidos II amplía el panel básico con determinaciones adicionales que mejoran la estratificación del riesgo cardiovascular residual, como colesterol no-HDL, partículas de LDL pequeñas y densas, apolipoproteína B o lipoproteína (a) según el laboratorio.</p>'
    WHEN 30  THEN '<p>Incluye todos los parámetros del perfil lipídico estándar más el cálculo de índices aterogénicos: cociente CT/HDL (índice de Castelli I), LDL/HDL (índice de Castelli II) y triglicéridos/HDL (índice aterogénico del plasma). Permite identificar la dislipidemia aterogénica característica del síndrome metabólico.</p>'
    WHEN 31  THEN '<p>El Perfil de Función Hepática Básico (PFH) incluye: TGO (ALT) y TGP (AST) para daño hepatocelular, fosfatasa alcalina para colestasis, y bilirrubina total, directa e indirecta para valorar el metabolismo de pigmentos biliares. Permite diferenciar hepatitis, colestasis y esteatosis hepática.</p>'
    WHEN 32  THEN '<p>El PFH Completo incluye todos los parámetros del básico más GGT (marcador de alcoholismo y colestasis), proteínas totales, albúmina (síntesis hepática) y globulinas (diferencia entre proteínas totales y albúmina). Proporciona una evaluación integral de la función hepática en hepatopatías moderadas a severas.</p>'
    WHEN 33  THEN '<p>Las aminotransferasas (TGP o ALT, TGO o AST) son enzimas intracelulares liberadas al torrente sanguíneo cuando hay daño hepatocelular. La TGP es más específica para el hígado; la TGO también se eleva en daño muscular cardíaco y esquelético. Un cociente AST/ALT mayor a 2 sugiere daño hepático alcohólico.</p>'
    WHEN 34  THEN '<p>La GGT es un marcador sensible de colestasis, daño hepático por alcohol o fármacos inductores enzimáticos. Se eleva antes que otras enzimas hepáticas. Su elevación aislada (sin otras enzimas) es frecuente en consumidores de alcohol. También es un marcador de riesgo metabólico en síndrome metabólico.</p>'
    WHEN 35  THEN '<p>Las proteínas totales séricas incluyen albúmina y globulinas. Su reducción (hipoproteinemia) ocurre en desnutrición, síndrome nefrótico y enfermedad hepática. El cociente albúmina/globulina (A/G) ayuda a diferenciar gammapatías monoclonales, cirrosis y enfermedades inflamatorias crónicas.</p>'
    WHEN 36  THEN '<p>La albúmina es la proteína sérica más abundante, sintetizada exclusivamente en el hígado. Tiene vida media de 20 días, por lo que refleja el estado nutricional y la función sintética hepática a mediano plazo. Su reducción (menor a 3.5 g/dL) es un marcador de mal pronóstico en enfermedad hepática crónica.</p>'
    WHEN 37  THEN '<p>Los perfiles tiroideos I a IV ofrecen distintos niveles de profundidad en el estudio tiroideo: desde el tamizaje básico (TSH + T4 libre) hasta el perfil avanzado (TSH, T3L, T4L, T3 total, T4 total) para el diagnóstico diferencial de hipotiroidismo, hipertiroidismo y síndrome del eutiroideo enfermo.</p>'
    WHEN 38  THEN '<p>La TSH es el regulador principal de la síntesis y secreción de hormonas tiroideas. Es el mejor parámetro inicial para el diagnóstico de hipotiroidismo (TSH elevada) e hipertiroidismo (TSH suprimida). Con alta sensibilidad (0.01 mUI/L), detecta alteraciones subclínicas antes de que se afecten T3 y T4.</p>'
    WHEN 39  THEN '<p>Los anticuerpos anti-peroxidasa tiroidea (anti-TPO) son el marcador más sensible de tiroiditis autoinmune (Hashimoto). Los anti-tiroglobulina (anti-Tg) se elevan en Hashimoto y tiroiditis de Graves. Su determinación conjunta mejora la sensibilidad diagnóstica en el estudio de hipotiroidismo autoinmune.</p>'
    WHEN 40  THEN '<p>Los anticuerpos TRAb (anti-receptor de TSH) son los marcadores más específicos de enfermedad de Graves-Basedow: estimulan el receptor de TSH mimificando la acción de la hormona. Útiles para predecir la remisión tras tratamiento con antitiroideos y para evaluar el riesgo de hipertiroidismo neonatal en embarazadas con Graves.</p>'
    WHEN 41  THEN '<p>La tiroglobulina (Tg) es producida exclusivamente por las células foliculares tiroideas. Es el marcador tumoral de seguimiento estándar tras tiroidectomía total + ablación con I-131 en cáncer diferenciado de tiroides. Un ascenso progresivo indica recidiva. Debe determinarse junto con anticuerpos anti-Tg para validar el resultado.</p>'
    WHEN 42  THEN '<p>La amilasa sérica se eleva en las primeras 6–12 horas de pancreatitis aguda (3–5 veces el valor normal) y retorna a la normalidad en 3–5 días. También puede elevarse en patología parotídea, obstrucción intestinal y úlcera perforada. La lipasa tiene mayor especificidad pancreática.</p>'
    WHEN 43  THEN '<p>La lipasa pancreática es más específica y sensible que la amilasa para el diagnóstico de pancreatitis aguda: se eleva más precozmente y permanece elevada hasta 14 días. Su determinación conjunta con la amilasa es el gold standard bioquímico inicial ante dolor abdominal agudo con sospecha de pancreatitis.</p>'
    WHEN 44  THEN '<p>La cistatina C es un inhibidor de cisteína-proteasas producido a tasa constante por todas las células nucleadas, filtrado y reabsorbido completamente por el glomérulo. A diferencia de la creatinina, no se afecta por la masa muscular, sexo ni dieta. Es el biomarcador más fidedigno de TFG en rangos moderados de insuficiencia renal.</p>'
    WHEN 45  THEN '<p>La depuración de creatinina en orina de 24 horas mide la cantidad de creatinina aclarada por los riñones en un día, permitiendo estimar la TFG real. Aunque ha sido desplazada parcialmente por las ecuaciones MDRD y CKD-EPI, sigue siendo útil en casos extremos de masa muscular o cuando se requiere cuantificación exacta.</p>'
    WHEN 46  THEN '<p>La proteinuria de 24 horas cuantifica la pérdida total de proteínas urinarias en un día. Valores mayores a 150 mg/24h son patológicos; mayores a 3.5 g/24h indican síndrome nefrótico. Es el gold standard para cuantificar la proteinuria en glomerulopatías y para monitorear la progresión del daño renal crónico.</p>'
    WHEN 47  THEN '<p>La microalbuminuria (excreción de 30–300 mg/día) es el marcador más precoz de nefropatía diabética e hipertensiva, con valor predictivo para eventos cardiovasculares. La primera orina de la mañana permite calcular el cociente albúmina/creatinina, que equivale a la excreción diaria y facilita la estandarización de la muestra.</p>'
    WHEN 48  THEN '<p>El triage cardíaco es un panel rápido de 3 biomarcadores para el diagnóstico diferencial del síndrome coronario agudo en urgencias: troponina I (necrosis miocárdica), CK-MB (daño muscular cardíaco) y mioglobina (marcador precoz pero inespecífico). Permite estratificar el riesgo y acelerar la decisión terapéutica.</p>'
    WHEN 49  THEN '<p>Panel ampliado de biomarcadores cardíacos que puede incluir troponina T de alta sensibilidad, NT-pro BNP (falla cardíaca), LDH, CK total, CK-MB y mioglobina. Ofrece una evaluación integral del daño miocárdico, la función ventricular y el riesgo cardiovascular en pacientes con dolor torácico o disnea.</p>'
    WHEN 50  THEN '<p>La troponina I cardíaca es el biomarcador de elección para el diagnóstico de infarto agudo de miocardio. Indetectable en sujetos sanos, se eleva 3–4 horas tras el daño y permanece elevada 7–10 días. La troponina I de alta sensibilidad permite el diagnóstico diferencial en urgencias mediante algoritmos de 0/1h o 0/2h.</p>'
    ELSE detalle
  END
WHERE id BETWEEN 1 AND 50;

-- Bloque B2: descripcion_breve + detalle IDs 51–144
UPDATE `catalogo_estudios` SET
  descripcion_breve = CASE id
    WHEN 51  THEN 'Biomarcador cardíaco de alta sensibilidad'
    WHEN 52  THEN 'Marcador de disfunción ventricular y falla cardíaca'
    WHEN 53  THEN 'Equilibrio ácido-base y gases sanguíneos arteriales'
    WHEN 54  THEN 'Gases venosos y equilibrio ácido-base sistémico'
    WHEN 55  THEN 'Hormonas reproductivas femeninas escalonadas'
    WHEN 56  THEN 'Hormonas reproductivas masculinas integradas'
    WHEN 57  THEN 'Hormona foliculoestimulante hipofisaria'
    WHEN 58  THEN 'Hormona luteinizante: ovulación y testosterona'
    WHEN 59  THEN 'Prolactina: galactorrea e infertilidad'
    WHEN 60  THEN 'Hormona lútea de implantación y embarazo'
    WHEN 61  THEN 'Andrógeno principal masculino y femenino'
    WHEN 62  THEN 'Andrógeno suprarrenal de depósito'
    WHEN 63  THEN 'Hormona del estrés: eje hipotálamo-hipófisis-suprarrenal'
    WHEN 64  THEN 'Hormona del estrés: eje hipotálamo-hipófisis-suprarrenal'
    WHEN 65  THEN 'Reserva ovárica y diagnóstico de SOP'
    WHEN 66  THEN 'Parathormona: metabolismo calcio-fósforo'
    WHEN 67  THEN 'Hemoglobina glicada: control glucémico de 3 meses'
    WHEN 68  THEN 'Hormona pancreática reguladora de la glucosa'
    WHEN 69  THEN 'Índice de resistencia insulínica'
    WHEN 70  THEN 'Marcador de secreción endógena de insulina'
    WHEN 71  THEN 'CTOG: diagnóstico de diabetes y prediabetes'
    WHEN 72  THEN 'Tamizaje de diabetes gestacional'
    WHEN 73  THEN 'Diagnóstico serológico de infección por VIH'
    WHEN 74  THEN 'Tamizaje serológico de sífilis'
    WHEN 75  THEN 'Aglutininas febriles para enfermedades tropicales'
    WHEN 76  THEN 'Panel serológico de hepatitis virales A, B y C'
    WHEN 77  THEN 'Detección de NS1 e inmunoglobulinas dengue'
    WHEN 78  THEN 'Diagnóstico de infección por SARS-CoV-2'
    WHEN 79  THEN 'Detección de anticuerpos anti-eritrocitarios'
    WHEN 80  THEN 'Marcador de sepsis bacteriana sistémica'
    WHEN 81  THEN 'Panel básico de reumatología y autoinmunidad'
    WHEN 82  THEN 'Marcador cuantitativo de inflamación aguda'
    WHEN 83  THEN 'Autoanticuerpo IgM anti-IgG en artritis reumatoide'
    WHEN 84  THEN 'Anti-CCP: marcador específico de artritis reumatoide'
    WHEN 85  THEN 'Anticuerpos antinucleares: tamizaje autoinmune'
    WHEN 86  THEN 'Anti-dsDNA: marcador específico de lupus eritematoso'
    WHEN 87  THEN 'Consumo complemento en enfermedades autoinmunes'
    WHEN 88  THEN '25-OH vitamina D: estado de reserva corporal'
    WHEN 89  THEN 'IgE total: alergias y parasitosis'
    WHEN 90  THEN 'IGF-1: marcador de hormona de crecimiento'
    WHEN 91  THEN 'Citología cervical para detección de cáncer'
    WHEN 92  THEN 'Urocultivo con antibiograma'
    WHEN 93  THEN 'Cultivo faríngeo con antibiograma'
    WHEN 94  THEN 'Cultivo vaginal y antibiograma'
    WHEN 95  THEN 'Cultivo uretral para ETS y uretritis'
    WHEN 96  THEN 'Coprocultivo con antibiograma entérico'
    WHEN 97  THEN 'Cultivo de herida o lesión con antibiograma'
    WHEN 98  THEN 'Cultivo de esputo con antibiograma'
    WHEN 99  THEN 'Cultivo de sangre para bacteriemia y sepsis'
    WHEN 100 THEN 'Aislamiento e identificación de hongos patógenos'
    WHEN 101 THEN 'Antígeno prostático específico total'
    WHEN 102 THEN 'Fracción libre de PSA: diferenciación de cáncer'
    WHEN 103 THEN 'Antígeno carcinoembrionario: seguimiento oncológico'
    WHEN 104 THEN 'Alfafetoproteína: hepatocarcinoma y teratoma'
    WHEN 105 THEN 'Marcador de cáncer de ovario epitelial'
    WHEN 106 THEN 'Marcador de seguimiento en cáncer de mama'
    WHEN 107 THEN 'Marcador de neoplasias pancreáticas y biliares'
    WHEN 108 THEN 'Panel integrado de marcadores oncológicos por sexo'
    WHEN 109 THEN 'Estudio parasitológico de heces en 3 muestras'
    WHEN 110 THEN 'Análisis integral de heces: físico, químico y micro'
    WHEN 111 THEN 'Detección de sangrado gastrointestinal oculto'
    WHEN 112 THEN 'Detección de Helicobacter pylori'
    WHEN 113 THEN 'Marcador de inflamación intestinal activa'
    WHEN 114 THEN 'Proteína neutrofílica: inflamación intestinal'
    WHEN 115 THEN 'Toxinas A y B de C. difficile en heces diarreicas'
    WHEN 116 THEN 'Análisis fisicoquímico y citológico de LCR'
    WHEN 117 THEN 'Análisis de líquido articular'
    WHEN 118 THEN 'Análisis de líquido pleural: trasudado vs exudado'
    WHEN 119 THEN 'Análisis de líquido ascítico: etiología y celularidad'
    WHEN 120 THEN 'Análisis de líquido de diálisis peritoneal'
    WHEN 121 THEN 'Análisis de lavado broncoalveolar'
    WHEN 122 THEN 'Análisis de líquido pericárdico'
    WHEN 123 THEN 'Detección molecular de VPH de alto riesgo oncogénico'
    WHEN 124 THEN 'Diagnóstico molecular de tuberculosis y micobacterias'
    WHEN 125 THEN 'Panel molecular de virus y bacterias respiratorias'
    WHEN 126 THEN 'Panel molecular de agentes de encefalitis y meningitis'
    WHEN 127 THEN 'Diagnóstico molecular de COVID-19 por RT-PCR'
    WHEN 128 THEN 'Espermograma: análisis seminal completo'
    WHEN 129 THEN 'Glucosa, urea, creatinina, ácido úrico, colesterol, triglicéridos y BUN'
    WHEN 130 THEN 'Hemoglobina glicada: control glucémico de 3 meses'
    WHEN 131 THEN 'Química sanguínea básica de 3 parámetros'
    WHEN 132 THEN 'Na, K, Cl, Ca, Mg, P séricos completos'
    WHEN 133 THEN 'TP, INR y TTPa: vías extrínseca e intrínseca de coagulación'
    WHEN 134 THEN 'TGO, TGP, FA, bilirrubinas, proteínas y albúmina'
    WHEN 135 THEN 'TSH, T3 y T4 en suero: función tiroidea completa'
    WHEN 136 THEN 'Electrolitos séricos básicos: 4 parámetros'
    WHEN 137 THEN 'Evaluación integral de resistencia a la insulina'
    WHEN 138 THEN 'Perfil hepático ampliado con coagulación'
    WHEN 139 THEN 'Perfil lipídico completo con fracciones calculadas'
    WHEN 140 THEN 'Panel tiroideo avanzado con T3 y T4 libres'
    WHEN 141 THEN 'Electrolitos básicos: sodio, potasio y cloro'
    WHEN 142 THEN 'Perfil bioquímico integral de 15 parámetros'
    WHEN 143 THEN 'EGO avanzado con cociente albúmina/creatinina'
    WHEN 144 THEN 'Detección de NS1 e inmunoglobulinas IgM e IgG anti-dengue'
    ELSE descripcion_breve
  END,
  detalle = CASE id
    WHEN 51  THEN '<p>La troponina T de alta sensibilidad (hs-TnT) permite detectar lesión miocárdica mínima con mayor precocidad que los métodos convencionales. Con un algoritmo de 0/1h o 0/2h, permite el diagnóstico o exclusión rápida del infarto en urgencias, acortando el tiempo de decisión clínica.</p>'
    WHEN 52  THEN '<p>El NT-pro BNP se libera en respuesta al estrés miocárdico por sobrecarga de volumen o presión. Es el marcador más útil para el diagnóstico y seguimiento de la insuficiencia cardíaca, estratificación del riesgo y monitoreo de la respuesta al tratamiento.</p>'
    WHEN 53  THEN '<p>Analiza pH, PaCO2, PaO2, HCO3, saturación de oxígeno y exceso de base en sangre arterial. Indispensable para el manejo de insuficiencia respiratoria, cetoacidosis, intoxicaciones y ventilación mecánica. Requiere procesamiento inmediato para evitar errores analíticos.</p>'
    WHEN 54  THEN '<p>Evalúa el equilibrio ácido-base y la oxigenación tisular a través de sangre venosa periférica o central. Menos invasiva que la gasometría arterial; útil para monitoreo metabólico, ventilación mecánica y evaluación de la perfusión tisular en pacientes críticos.</p>'
    WHEN 55  THEN '<p>Perfiles escalonados que incluyen FSH, LH, estradiol, progesterona, prolactina y testosterona libre. Permiten el estudio de infertilidad, irregularidades menstruales, menopausia, síndrome de ovario poliquístico y seguimiento de estimulación ovárica.</p>'
    WHEN 56  THEN '<p>Incluye testosterona total y libre, FSH, LH, DHEA-S y prolactina. Indicado en el estudio de hipogonadismo, infertilidad masculina, disfunción eréctil y déficit androgénico relacionado con la edad.</p>'
    WHEN 57  THEN '<p>La FSH estimula el desarrollo folicular ovárico y la espermatogénesis testicular. Su determinación es clave para el diagnóstico de insuficiencia ovárica prematura (FSH elevada), síndrome de ovario poliquístico, hipogonadismo hipogonadotrópico y seguimiento de FIV.</p>'
    WHEN 58  THEN '<p>La LH desencadena la ovulación y estimula la producción de progesterona y testosterona. Su determinación junto con FSH permite clasificar el hipogonadismo como primario (gonadal) o secundario (hipotalámico-hipofisario).</p>'
    WHEN 59  THEN '<p>La prolactina regula la lactancia y, cuando está elevada (hiperprolactinemia), inhibe el eje gonadal causando amenorrea, galactorrea e infertilidad. Causas frecuentes: prolactinoma hipofisario, hipotiroidismo y fármacos antidopaminérgicos. Debe medirse en ayunas y en reposo.</p>'
    WHEN 60  THEN '<p>La progesterona prepara el endometrio para la implantación y mantiene el embarazo temprano. Su determinación en fase lútea media (día 21) confirma la ovulación (más de 3 ng/mL). En el primer trimestre, niveles bajos pueden indicar amenaza de aborto o embarazo ectópico.</p>'
    WHEN 61  THEN '<p>La testosterona total mide toda la testosterona circulante; la libre (fracción activa) es la más biológicamente disponible. Su determinación es clave en el diagnóstico de hipogonadismo masculino, virilización femenina, síndrome de ovario poliquístico y seguimiento de terapia de reemplazo androgénico.</p>'
    WHEN 62  THEN '<p>La DHEA-S es el andrógeno suprarrenal más abundante en suero, con vida media larga y escasa variación circadiana. Su elevación sugiere origen suprarrenal en casos de hiperandrogenismo. Útil también para evaluar la función adrenal y detectar tumores suprarrenales productores de andrógenos.</p>'
    WHEN 63  THEN '<p>El cortisol regula el metabolismo de glucosa, la respuesta inmune y la presión arterial. Su medición matutina sirve para el diagnóstico de hipercortisolismo (síndrome de Cushing) o insuficiencia suprarrenal (Addison). La supresión con dexametasona confirma el diagnóstico de Cushing.</p>'
    WHEN 64  THEN '<p>El cortisol regula el metabolismo de glucosa, la respuesta inmune y la presión arterial. Su medición matutina sirve para el diagnóstico de hipercortisolismo (síndrome de Cushing) o insuficiencia suprarrenal (Addison). La supresión con dexametasona confirma el diagnóstico de Cushing.</p>'
    WHEN 65  THEN '<p>La Hormona Antimülleriana (AMH) refleja directamente la reserva folicular ovárica: su reducción indica baja reserva ovárica, mientras que valores muy elevados son característicos del síndrome de ovario poliquístico (SOP). Es el marcador más estable durante el ciclo menstrual y fundamental en el estudio de fertilidad.</p>'
    WHEN 66  THEN '<p>La PTH intacta regula la homeostasis del calcio y el fósforo actuando sobre riñón, hueso e intestino. Su determinación es esencial para el diagnóstico de hiperparatiroidismo primario, secundario (nefropatía crónica) y para la evaluación de la osteodistrofia renal.</p>'
    WHEN 67  THEN '<p>Refleja la glucemia media de los últimos 90 días al medir la fracción de hemoglobina ligada irreversiblemente a glucosa. Es el parámetro de referencia para el diagnóstico de diabetes (igual o mayor a 6.5%) y el seguimiento del control glucémico. No requiere ayuno y tiene baja variabilidad diurna.</p>'
    WHEN 68  THEN '<p>La insulina es la hormona anabólica principal del metabolismo energético. Su determinación basal es clave para calcular el índice HOMA-IR (resistencia a insulina), diagnosticar insulinoma y evaluar la función de células beta en diabetes tipo 1 y LADA.</p>'
    WHEN 69  THEN '<p>El HOMA-IR calcula la resistencia a la insulina a partir de glucosa e insulina en ayunas: HOMA-IR = glucosa (mg/dL) x insulina (uUI/mL) / 405. Valores mayores a 2.5 indican resistencia insulínica asociada a síndrome metabólico y riesgo de diabetes tipo 2.</p>'
    WHEN 70  THEN '<p>El péptido C se secreta en cantidades equimolares con la insulina pero no se metaboliza en el hígado, por lo que refleja mejor la producción pancreática real. Es útil para diferenciar diabetes tipo 1 de tipo 2, evaluar la reserva pancreática residual y detectar hipoglucemia facticia por insulina exógena.</p>'
    WHEN 71  THEN '<p>La Curva de Tolerancia Oral a la Glucosa (CTOG) mide la respuesta glucémica tras la ingesta de 75 g de glucosa oral, con determinaciones a los 0, 60 y 120 minutos. Es el estándar de referencia para el diagnóstico de diabetes gestacional y prediabetes cuando la glucosa en ayunas es límite.</p>'
    WHEN 72  THEN '<p>El Test de O\'Sullivan es la prueba de tamizaje universal para diabetes gestacional: se administran 50 g de glucosa oral sin ayuno previo y se mide la glucemia a la hora. Si el resultado supera 140 mg/dL, se confirma con la CTOG de 3 horas con 100 g de glucosa.</p>'
    WHEN 73  THEN '<p>Prueba de cuarta generación que detecta simultáneamente anticuerpos anti-VIH 1 y 2 y el antígeno p24. Permite el diagnóstico desde las 2-4 semanas post-exposición. Un resultado reactivo requiere confirmación con Western Blot o prueba de discriminación VIH-1/VIH-2.</p>'
    WHEN 74  THEN '<p>El VDRL es una prueba no treponémica de tamizaje para sífilis que detecta anticuerpos anticardiolipina. Un resultado reactivo debe confirmarse con pruebas treponémicas (FTA-ABS, TP-PA). Se utiliza también para monitorear la respuesta al tratamiento antibiótico.</p>'
    WHEN 75  THEN '<p>Detecta anticuerpos aglutinantes contra Salmonella (fiebre tifoidea: antígenos O y H), Brucella y Proteus (Weil-Felix). Útil en el diagnóstico diferencial de síndrome febril prolongado en zonas endémicas. Un resultado positivo a títulos mayores o iguales a 1:80 es clínicamente significativo.</p>'
    WHEN 76  THEN '<p>Panel que detecta: anti-VHA IgM (hepatitis A aguda), HBsAg (hepatitis B activa) y anti-HCV (hepatitis C). Permite el diagnóstico diferencial en pacientes con ictericia o elevación de transaminasas. Un resultado positivo de HCV requiere confirmación con carga viral (ARN-HCV).</p>'
    WHEN 77  THEN '<p>Panel para diagnóstico de dengue que incluye antígeno NS1 (detectable desde el día 1 de fiebre), IgM (infección reciente) e IgG (infección previa o secundaria). El NS1 es el marcador más útil en fase aguda temprana (días 1-5), mientras que las IgM positivan a partir del día 4-5.</p>'
    WHEN 78  THEN '<p>Incluye la prueba de antígeno (detección rápida de proteína N) y/o PCR (detección molecular de ARN viral). La PCR es el gold standard con mayor sensibilidad y especificidad. La serología (IgM/IgG) sirve para diagnóstico tardío y estudios de seroprevalencia.</p>'
    WHEN 79  THEN '<p>La Prueba de Coombs directa detecta anticuerpos o complemento unidos a eritrocitos del paciente (anemia hemolítica autoinmune); la indirecta detecta anticuerpos libres en suero (crossmatch transfusional). Esencial en el estudio de anemias hemolíticas y hemolítica neonatal.</p>'
    WHEN 80  THEN '<p>La procalcitonina (PCT) se eleva en respuesta a infecciones bacterianas sistémicas graves pero permanece baja en infecciones virales y estados inflamatorios no infecciosos. Es el biomarcador guía más útil para el diagnóstico de sepsis y para orientar la duración de la antibioticoterapia.</p>'
    WHEN 81  THEN '<p>Incluye PCR, Factor Reumatoide, VSG y ácido úrico como perfil inicial de tamizaje para artritis reumatoide, gota y enfermedades autoinmunes articulares. Una segunda fase puede incluir ANA, anti-CCP y complementos según la orientación clínica.</p>'
    WHEN 82  THEN '<p>La PCR es un reactante de fase aguda producido por el hígado en respuesta a infecciones, inflamación o daño tisular. Se eleva en 6-12 horas y retorna a la normalidad rápidamente. La PCR ultrasensible (PCR-us) es un marcador de riesgo cardiovascular independiente a niveles más bajos.</p>'
    WHEN 83  THEN '<p>El factor reumatoide (FR) es un autoanticuerpo dirigido contra la fracción Fc de la IgG. Positivo en 70-80% de pacientes con artritis reumatoide. También elevado en síndrome de Sjögren, LES y hepatitis crónica. Su negatividad no excluye el diagnóstico (AR seronegativa).</p>'
    WHEN 84  THEN '<p>Los anticuerpos anti-péptido cíclico citrulinado (anti-CCP) tienen mayor especificidad (más del 95%) que el Factor Reumatoide para artritis reumatoide y pueden aparecer años antes de los síntomas. Positivos en artritis reumatoide seronegativa para FR y útiles para predecir la progresión erosiva.</p>'
    WHEN 85  THEN '<p>Los ANA son el tamizaje de elección para enfermedades autoinmunes sistémicas. Un ANA positivo (mayor o igual a 1:80 por IF) requiere confirmación con anticuerpos específicos (anti-dsDNA, anti-Sm, anti-SSA/SSB, anti-Scl70) para caracterizar la enfermedad: LES, síndrome de Sjögren, esclerodermia u otros.</p>'
    WHEN 86  THEN '<p>Los anticuerpos anti-DNA de doble cadena (anti-dsDNA) son altamente específicos para LES (Lupus Eritematoso Sistémico) y son uno de los criterios del ACR/EULAR para su diagnóstico. Sus niveles correlacionan con la actividad de la enfermedad, especialmente con la nefritis lúpica.</p>'
    WHEN 87  THEN '<p>Los niveles séricos de C3 y C4 reflejan el consumo de complemento por inmunocomplejos circulantes. Disminuidos en LES activo (especialmente nefritis lúpica), crioglobulinemia y hepatitis C. Su monitoreo seriado es útil para evaluar la actividad de la enfermedad y la respuesta al tratamiento inmunosupresor.</p>'
    WHEN 88  THEN '<p>La 25-hidroxivitamina D (25-OH-D3) es el mejor indicador del estado de vitamina D en el organismo. Niveles menores a 20 ng/mL indican deficiencia; 20-30 ng/mL insuficiencia; mayores a 30 ng/mL suficiencia. Su deficiencia se relaciona con osteoporosis, enfermedades autoinmunes y mayor riesgo de infecciones.</p>'
    WHEN 89  THEN '<p>La IgE total sérica es el marcador de atopia y respuesta alérgica mediada por IgE. Elevada en asma alérgica, rinitis, dermatitis atópica, urticaria crónica y parasitosis helmínticas. Para el diagnóstico de alergias específicas, se complementa con IgE específicas para alérgenos (RAST).</p>'
    WHEN 90  THEN '<p>La Somatomedina C (IGF-1) refleja la producción hepática de GH con menor variabilidad que la GH basal. Es el marcador de elección para el diagnóstico y seguimiento de la acromegalia y del déficit de hormona de crecimiento en adultos y niños.</p>'
    WHEN 91  THEN '<p>La citología exfoliativa cervical (Papanicolaou) permite detectar lesiones precancerosas (LSIL, HSIL) y carcinoma cervical antes de que se vuelvan invasoras. Junto con la prueba de VPH de alto riesgo, es el cotamizaje más sensible para la prevención del cáncer cervicouterino según las guías internacionales y NOM-014.</p>'
    WHEN 92  THEN '<p>Permite la identificación del microorganismo causante de infección de vías urinarias (IVU) y determina su perfil de susceptibilidad antibiótica (antibiograma). Esencial para el tratamiento dirigido de IVU complicadas, recurrentes o resistentes a antibióticos de primera línea.</p>'
    WHEN 93  THEN '<p>Permite identificar el agente bacteriano en faringoamigdalitis (Streptococcus pyogenes, otros) y orientar el tratamiento antibiótico específico. Indicado cuando la clínica orienta a infección bacteriana o en casos recurrentes para descartar portación o resistencia.</p>'
    WHEN 94  THEN '<p>Identifica el agente causal de vaginitis o cervicitis (Candida, Gardnerella, Trichomonas, Neisseria gonorrhoeae) con pruebas de susceptibilidad. Indicado en flujo vaginal anormal, vaginosis bacteriana recurrente o sospecha de ETS con cultivo específico.</p>'
    WHEN 95  THEN '<p>Identifica agentes de uretritis (Neisseria gonorrhoeae, Mycoplasma genitalium, otros) con antibiograma. Indicado en uretritis sintomática, secreción uretral o como tamizaje en pacientes con factores de riesgo para ETS. Los casos de gonococo requieren notificación obligatoria.</p>'
    WHEN 96  THEN '<p>Identifica bacterias patógenas entéricas (Salmonella, Shigella, Campylobacter, E. coli patogénica, entre otros) en heces diarreicas con perfil de susceptibilidad. Indicado en diarrea moderada-grave, con sangre o moco, diarrea del viajero y en pacientes inmunocomprometidos.</p>'
    WHEN 97  THEN '<p>Permite el aislamiento e identificación de microorganismos en heridas crónicas, úlceras, abscesos y lesiones cutáneas infectadas, con antibiograma para orientar el tratamiento. Fundamental en el manejo de pie diabético y heridas quirúrgicas infectadas.</p>'
    WHEN 98  THEN '<p>Identifica el agente causal de neumonía bacteriana, bronquitis crónica infectada o exacerbación de EPOC con determinación de sensibilidad antibiótica. Requiere una muestra de esputo de tos profunda de buena calidad: más de 25 PMN y menos de 10 células epiteliales por campo.</p>'
    WHEN 99  THEN '<p>Gold standard para el diagnóstico de bacteriemia y fungemia. Se incuban en frascos aerobio y anaerobio a 37°C durante hasta 5 días. Una vez positivo (alarma automática), se procede con tinción de Gram, subcultivos e identificación con antibiograma. La toma ideal es en el pico febril antes del inicio de antibióticos.</p>'
    WHEN 100 THEN '<p>Permite el aislamiento e identificación de dermatofitos (tiña), levaduras (Candida) y hongos filamentosos en muestras de piel, uñas, cabello o mucosas. Requiere hasta 21 días de incubación. Se complementa con pruebas de sensibilidad a antifúngicos.</p>'
    WHEN 101 THEN '<p>El PSA total es una glucoproteína producida por las células epiteliales prostáticas. Su elevación (más de 4 ng/mL) puede indicar hiperplasia benigna, prostatitis o carcinoma prostático. Se interpreta en conjunto con el PSA libre y la velocidad de PSA para mejorar la especificidad diagnóstica.</p>'
    WHEN 102 THEN '<p>El cociente PSA libre/PSA total ayuda a diferenciar hiperplasia benigna prostática (cociente alto, mayor al 25%) de carcinoma (cociente bajo, menor al 15%) en pacientes con PSA total entre 4-10 ng/mL (zona gris). Permite reducir biopsias innecesarias sin perder diagnósticos de cáncer clínicamente significativo.</p>'
    WHEN 103 THEN '<p>El CEA es útil principalmente para el seguimiento de carcinoma colorrectal, pero también elevado en cáncer de pulmón, mama, páncreas y ovario. No se usa para diagnóstico inicial sino para monitorear la respuesta al tratamiento y detectar recidivas. El tabaquismo eleva ligeramente los niveles basales.</p>'
    WHEN 104 THEN '<p>La AFP se eleva en carcinoma hepatocelular (AFP mayor a 400 ng/mL tiene alta especificidad), tumores de células germinales testiculares/ováricos y en hepatitis viral activa con regeneración hepática intensa. También es marcador de tamizaje prenatal para defectos del tubo neural.</p>'
    WHEN 105 THEN '<p>El CA-125 es el marcador tumoral más utilizado en el seguimiento de cáncer de ovario epitelial. Elevado también en endometriosis, fibromas y enfermedades inflamatorias pélvicas. Su principal utilidad es monitorear la respuesta al tratamiento y detectar recidivas post-quirúrgicas.</p>'
    WHEN 106 THEN '<p>El CA 15-3 es el marcador tumoral de elección para el seguimiento de cáncer de mama metastásico y monitoreo de la respuesta al tratamiento. No se recomienda para diagnóstico primario por baja sensibilidad en estadios tempranos. Puede elevarse también en enfermedades hepáticas y pulmonares.</p>'
    WHEN 107 THEN '<p>El CA 19-9 es el marcador más utilizado para el seguimiento de cáncer pancreático y colangiocarcinoma. Su elevación con ictericia obstructiva y masa pancreática tiene alta especificidad. También puede elevarse en pancreatitis y colangitis. No tiene valor en pacientes Lewis negativo.</p>'
    WHEN 108 THEN '<p>Perfiles diseñados por sexo que combinan los marcadores tumorales más relevantes: en mujeres incluye CA-125, CA-15-3, CEA y AFP; en hombres incluye PSA total, PSA libre, CEA y AFP. Útil como tamizaje oncológico en chequeos ejecutivos o vigilancia en pacientes con antecedentes familiares de cáncer.</p>'
    WHEN 109 THEN '<p>Examen microscópico de 3 muestras fecales en días alternos para detectar parásitos intestinales (protozoarios y helmintos) en sus formas de trofozoíto, quiste, huevo o larva. La toma en múltiples muestras aumenta la sensibilidad hasta el 85-90% para la mayoría de parásitos.</p>'
    WHEN 110 THEN '<p>Examen completo de heces que incluye características físicas (color, consistencia, moco), análisis químico (pH, sangre oculta, grasa fecal) y estudio microscópico de leucocitos, eritrocitos, cristales y levaduras. Indicado en diarrea crónica, síndrome de malabsorción y estudio integral de la función digestiva.</p>'
    WHEN 111 THEN '<p>La prueba de sangre oculta en heces (PSOH) detecta hemoglobina en heces mediante inmunocromatografía o guayaco. Es el tamizaje de primera línea para cáncer colorrectal en personas mayores de 45 años asintomáticas. Un resultado positivo requiere colonoscopía diagnóstica.</p>'
    WHEN 112 THEN '<p>Permite detectar infección activa por H. pylori mediante prueba de antígeno en heces (sensibilidad mayor al 90%) o anticuerpos séricos. La prueba de antígeno fecal es la más recomendada para diagnóstico y confirmación de erradicación 4 semanas post-tratamiento.</p>'
    WHEN 113 THEN '<p>La calprotectina fecal es una proteína liberada por neutrófilos en la mucosa intestinal inflamada. Permite diferenciar enfermedad inflamatoria intestinal (EII: Crohn, CU) de síndrome de intestino irritable (SII) sin necesidad de endoscopía. También útil para monitorear la actividad de la EII y la respuesta al tratamiento biológico.</p>'
    WHEN 114 THEN '<p>La lactoferrina fecal es una proteína de los gránulos de neutrófilos que se eleva en inflamación activa de la mucosa intestinal. Alternativa o complemento a la calprotectina para diferenciar patología inflamatoria intestinal de trastornos funcionales y monitorear la actividad de enfermedad de Crohn y colitis ulcerosa.</p>'
    WHEN 115 THEN '<p>Detecta las toxinas A y B de Clostridioides difficile en heces diarreicas mediante inmunoensayo (ELISA) o PCR. Es el agente causal más común de diarrea nosocomial y diarrea asociada a antibióticos. Un resultado positivo requiere suspensión del antibiótico causante e inicio de metronidazol o vancomicina oral.</p>'
    WHEN 116 THEN '<p>El análisis de LCR incluye glucosa, proteínas, presión de apertura, citometría, tinción de Gram, cultivo y pruebas específicas (látex para Criptococo, VDRL). Es el gold standard para el diagnóstico de meningitis bacteriana, viral, tuberculosa y encefalitis, así como para detección de sangrado subaracnoideo.</p>'
    WHEN 117 THEN '<p>El análisis de líquido sinovial permite clasificar las artropatías: normal (menos de 200 céls), inflamatorio (200-50,000 céls), infeccioso (más de 50,000 céls con PMN dominantes) y hemorrágico. Incluye conteo celular, cristales (urato, pirofosfato), cultivo y tinción de Gram para artritis séptica.</p>'
    WHEN 118 THEN '<p>Permite clasificar el derrame pleural mediante los Criterios de Light, diferenciando trasudados (falla cardíaca, cirrosis) de exudados (infección, neoplasia, autoinmune). Incluye citología para células malignas, cultivos y determinaciones específicas según la sospecha clínica.</p>'
    WHEN 119 THEN '<p>El análisis de líquido ascítico incluye proteínas, albúmina (para calcular el SAAG), celularidad, glucosa, LDH, cultivo y citología. El gradiente sero-ascítico de albúmina (SAAG mayor o igual a 1.1 g/dL) distingue ascitis por hipertensión portal de las de etiología no portal (tuberculosis, neoplasia).</p>'
    WHEN 120 THEN '<p>Análisis del efluente de diálisis peritoneal para detectar peritonitis infecciosa: conteo de leucocitos (más de 100 células/uL con más del 50% PMN es diagnóstico), tinción de Gram y cultivo con antibiograma. La peritonitis es la complicación más frecuente y grave de la diálisis peritoneal ambulatoria continua (CAPD).</p>'
    WHEN 121 THEN '<p>El lavado broncoalveolar (LBA) permite el análisis citológico, microbiológico (bacterias, hongos, micobacterias, virus) y la detección de macrófagos con hemosiderina en hemorragia alveolar. Indispensable en el diagnóstico de neumonías en huéspedes inmunocomprometidos.</p>'
    WHEN 122 THEN '<p>El análisis del líquido pericárdico incluye citología, proteínas, LDH, glucosa, cultivo bacteriano y fúngico, y adenosina deaminasa (ADA para tuberculosis). Permite distinguir derrames inflamatorios, infecciosos, neoplásicos y hemorrágicos en el diagnóstico de pericarditis y taponamiento cardíaco.</p>'
    WHEN 123 THEN '<p>La prueba de PCR para VPH detecta y genotipifica los genotipos de alto riesgo oncogénico (VPH 16, 18 y otros tipos de alto riesgo). Junto con la citología cervical, forma el cotamizaje más sensible para la prevención del cáncer cervicouterino. Un VPH 16/18 positivo con citología normal requiere colposcopía directa.</p>'
    WHEN 124 THEN '<p>La PCR para Mycobacterium tuberculosis detecta ADN de M. tuberculosis y mutaciones de resistencia a rifampicina en menos de 2 horas. Supera en sensibilidad a la baciloscopia en casos paucibacilares. Indicado en sospecha de TB pulmonar, extrapulmonar y en pacientes VIH positivos.</p>'
    WHEN 125 THEN '<p>Panel de PCR múltiple que detecta simultáneamente los principales agentes de infección respiratoria aguda: influenza A/B, SARS-CoV-2, VRS, adenovirus, parainfluenza, Mycoplasma pneumoniae y Chlamydophila pneumoniae, entre otros. Permite el diagnóstico etiológico preciso para optimizar el tratamiento.</p>'
    WHEN 126 THEN '<p>Detecta por PCR los principales virus neurotropos en LCR: enterovirus, herpes simple (VHS-1/2), varicela-zóster, CMV, EBV y VHH-6. Permite el diagnóstico rápido y diferencial de meningitis viral aséptica, encefalitis herpética y meningoencefalitis en pacientes inmunocomprometidos.</p>'
    WHEN 127 THEN '<p>La RT-PCR para SARS-CoV-2 es el gold standard para el diagnóstico de COVID-19: detecta ARN viral en hisopo nasofaríngeo con alta sensibilidad y especificidad. Un resultado negativo en los primeros días no descarta infección; en casos de alta sospecha, repetir la muestra a las 24-48 horas o complementar con antígeno y serología.</p>'
    WHEN 128 THEN '<p>La espermatobioscopia directa (espermograma) analiza el volumen, pH, concentración espermática, motilidad progresiva, morfología (criterios Kruger estrictos) y vitalidad del eyaculado según los criterios OMS 2021. Es la prueba inicial para el estudio de infertilidad masculina y la primera indicada antes de cualquier técnica de reproducción asistida.</p>'
    WHEN 129 THEN '<p>Mide glucosa, urea, creatinina, ácido úrico, colesterol, triglicéridos y nitrógeno ureico en sangre (BUN). Proporciona una visión integral del metabolismo de carbohidratos, lípidos y proteínas, así como de la función renal. Es el perfil metabólico más completo de primera línea para diagnóstico preventivo.</p>'
    WHEN 130 THEN '<p>Refleja la glucemia media de los últimos 90 días al medir la fracción de hemoglobina ligada irreversiblemente a glucosa. Es el parámetro de referencia para el diagnóstico de diabetes (igual o mayor a 6.5%) y el seguimiento del control glucémico. No requiere ayuno y tiene baja variabilidad diurna.</p>'
    WHEN 131 THEN '<p>Determina glucosa, urea y creatinina sérica. Perfil básico para la valoración del metabolismo de carbohidratos y la función renal. Indicado como tamizaje en chequeos preventivos y seguimiento de pacientes con diabetes o insuficiencia renal.</p>'
    WHEN 132 THEN '<p>Perfil electrolítico completo que incluye sodio, potasio, cloro, calcio, magnesio y fósforo. Proporciona una visión integral del equilibrio hidroelectrolítico e iónico del paciente. Indicado en trastornos neuromusculares, arritmias, manejo de pacientes en UCI y vigilancia de terapia con diuréticos.</p>'
    WHEN 133 THEN '<p>Perfil hemostático que evalúa la vía extrínseca e intrínseca de la coagulación: TP (vía extrínseca), INR (estandarizado para anticoagulantes) y TTPa (vía intrínseca). Es el perfil preoperatorio estándar y el de monitoreo para pacientes con anticoagulantes orales e heparina.</p>'
    WHEN 134 THEN '<p>El Perfil de Función Hepática incluye TGO, TGP, fosfatasa alcalina, bilirrubina total, directa e indirecta, proteínas totales y albúmina. Permite una evaluación integral del daño hepatocelular, la colestasis y la capacidad sintética del hígado. Es el estudio hepático de primera línea.</p>'
    WHEN 135 THEN '<p>El Perfil Tiroideo 1 incluye TSH ultrasensible (2ª o 3ª generación), T3 total y T4 total. Permite el diagnóstico de hipo e hipertiroidismo clínico. La TSH es el marcador inicial de elección; T3 y T4 complementan la caracterización del patrón de disfunción tiroidea.</p>'
    WHEN 136 THEN '<p>Determina sodio, potasio, cloro y calcio sérico en muestra única. Panel electrolítico estándar para la valoración del equilibrio iónico en pacientes con hipertensión, insuficiencia cardíaca, diabetes o uso de diuréticos y medicamentos que afectan los electrolitos.</p>'
    WHEN 137 THEN '<p>Calcula el HOMA-IR, el porcentaje de sensibilidad (%S) y el porcentaje de función beta (%B) a partir de glucosa e insulina en ayunas. Permite caracterizar con mayor detalle el tipo y grado de resistencia a la insulina, orientando la intervención terapéutica en pacientes con síndrome metabólico, SOP y prediabetes.</p>'
    WHEN 138 THEN '<p>Perfil hepático de segunda línea que integra las determinaciones del PFH básico con marcadores de síntesis como el tiempo de protrombina/INR y fibrinógeno. Proporciona una evaluación completa de la capacidad funcional y sintética del hígado en hepatopatías moderadas a severas.</p>'
    WHEN 139 THEN '<p>Incluye colesterol total, HDL, LDL (directo o calculado por Friedewald), VLDL y triglicéridos, junto con el cálculo de índices de riesgo cardiovascular (CT/HDL, LDL/HDL). Es el perfil estándar para estratificación de riesgo cardiovascular aterosclerótico según ACC/AHA 2019 y guías ESC 2021.</p>'
    WHEN 140 THEN '<p>Perfil tiroideo ampliado que incluye TSH, T3 total, T4 total, T3 libre (T3L) y T4 libre (T4L). Las fracciones libres reflejan mejor la actividad hormonal real. Indicado en el seguimiento de hipotiroidismo en tratamiento, estudio de hipertiroidismo subclínico y evaluación tiroidea en el embarazo.</p>'
    WHEN 141 THEN '<p>Determina los tres electrolitos principales del compartimento extracelular: sodio (osmorregulación), potasio (excitabilidad neuromuscular) y cloro (equilibrio ácido-base). Es el panel electrolítico mínimo indicado en urgencias, pre-operatorios, monitoreo de diuréticos y evaluación de desequilibrios hídricos básicos.</p>'
    WHEN 142 THEN '<p>Incluye glucosa, urea, creatinina, ácido úrico, colesterol, triglicéridos, TGO, TGP, bilirrubina total, fosfatasa alcalina, GGT, proteínas totales, albúmina, calcio y fósforo. Proporciona una evaluación metabólica, hepática y renal completa en una sola muestra. Indicado en chequeos ejecutivos y evaluación preventiva integral.</p>'
    WHEN 143 THEN '<p>Combina el examen general de orina cuantitativo con el cociente albúmina/creatinina urinario (ACR). Permite tamizar y estadificar el daño renal temprano en pacientes diabéticos e hipertensos de forma más precisa que el EGO convencional. Un ACR mayor a 30 mg/g indica microalbuminuria significativa.</p>'
    WHEN 144 THEN '<p>Panel diagnóstico de dengue de segunda generación que detecta simultáneamente el antígeno NS1 (detectable desde el día 1 de fiebre, alta sensibilidad en fase virémica), IgM (marcador de infección primaria reciente, positiva a partir del día 4-5) e IgG (infección secundaria o previa). Permite clasificar el caso como primario o secundario y orientar el manejo clínico.</p>'
    ELSE detalle
  END
WHERE id BETWEEN 51 AND 144;

-- Bloque E: Poblar campos operativos (tiempo, muestra, preparacion) para estudios GEN-XXXX
-- Solo actualiza donde el campo esté vacío (idempotente: no sobreescribe datos ya corregidos)
UPDATE `catalogo_estudios` SET
  tiempo_procesamiento = CASE id
    WHEN 6   THEN '4 Horas'   WHEN 7   THEN '4 Horas'   WHEN 8   THEN '4 Horas'
    WHEN 9   THEN '24 Horas'  WHEN 10  THEN '2 Horas'   WHEN 11  THEN '2 Horas'
    WHEN 12  THEN '2 Horas'   WHEN 14  THEN '4 Horas'   WHEN 15  THEN '4 Horas'
    WHEN 16  THEN '4 Horas'   WHEN 17  THEN '4 Horas'   WHEN 18  THEN '2 Horas'
    WHEN 20  THEN '4 Horas'   WHEN 21  THEN '24 Horas'  WHEN 22  THEN '4 Horas'
    WHEN 23  THEN '4 Horas'   WHEN 24  THEN '4 Horas'   WHEN 27  THEN '2 Horas'
    WHEN 28  THEN '4 Horas'   WHEN 29  THEN '4 Horas'   WHEN 30  THEN '4 Horas'
    WHEN 31  THEN '4 Horas'   WHEN 32  THEN '4 Horas'   WHEN 33  THEN '4 Horas'
    WHEN 34  THEN '4 Horas'   WHEN 35  THEN '2 Horas'   WHEN 36  THEN '2 Horas'
    WHEN 37  THEN '24 Horas'  WHEN 38  THEN '24 Horas'  WHEN 39  THEN '24 Horas'
    WHEN 40  THEN '24 Horas'  WHEN 41  THEN '24 Horas'  WHEN 45  THEN '24 Horas'
    WHEN 46  THEN '24 Horas'  WHEN 48  THEN '1 Hora'    WHEN 49  THEN '4 Horas'
    WHEN 52  THEN '24 Horas'  WHEN 56  THEN '24 Horas'  WHEN 57  THEN '24 Horas'
    WHEN 58  THEN '24 Horas'  WHEN 59  THEN '24 Horas'  WHEN 60  THEN '24 Horas'
    WHEN 61  THEN '24 Horas'  WHEN 62  THEN '24 Horas'  WHEN 65  THEN '24 Horas'
    WHEN 66  THEN '24 Horas'  WHEN 67  THEN '4 Horas'   WHEN 69  THEN '4 Horas'
    WHEN 71  THEN '4 Horas'   WHEN 72  THEN '4 Horas'   WHEN 73  THEN '24 Horas'
    WHEN 74  THEN '4 Horas'   WHEN 76  THEN '24 Horas'  WHEN 77  THEN '4 Horas'
    WHEN 78  THEN '4 Horas'   WHEN 79  THEN '4 Horas'   WHEN 81  THEN '24 Horas'
    WHEN 82  THEN '4 Horas'   WHEN 83  THEN '24 Horas'  WHEN 84  THEN '24 Horas'
    WHEN 85  THEN '24 Horas'  WHEN 86  THEN '24 Horas'  WHEN 87  THEN '24 Horas'
    WHEN 88  THEN '24 Horas'  WHEN 89  THEN '24 Horas'  WHEN 90  THEN '24 Horas'
    WHEN 91  THEN '24 Horas'  WHEN 92  THEN '48 Horas'  WHEN 93  THEN '48 Horas'
    WHEN 94  THEN '48 Horas'  WHEN 95  THEN '48 Horas'  WHEN 96  THEN '48 Horas'
    WHEN 97  THEN '48 Horas'  WHEN 98  THEN '48 Horas'  WHEN 101 THEN '24 Horas'
    WHEN 102 THEN '24 Horas'  WHEN 103 THEN '24 Horas'  WHEN 104 THEN '24 Horas'
    WHEN 105 THEN '24 Horas'  WHEN 106 THEN '24 Horas'  WHEN 107 THEN '24 Horas'
    WHEN 108 THEN '24 Horas'  WHEN 110 THEN '24 Horas'  WHEN 111 THEN '24 Horas'
    WHEN 112 THEN '4 Horas'   WHEN 113 THEN '48 Horas'  WHEN 114 THEN '48 Horas'
    WHEN 115 THEN '4 Horas'   WHEN 116 THEN '24 Horas'  WHEN 117 THEN '4 Horas'
    WHEN 118 THEN '24 Horas'  WHEN 119 THEN '24 Horas'  WHEN 120 THEN '4 Horas'
    WHEN 121 THEN '24 Horas'  WHEN 122 THEN '24 Horas'  WHEN 123 THEN '24 Horas'
    WHEN 124 THEN '4 Horas'   WHEN 125 THEN '4 Horas'   WHEN 126 THEN '4 Horas'
    WHEN 127 THEN '4 Horas'   WHEN 128 THEN '48 Horas'
    ELSE tiempo_procesamiento
  END,
  muestra_requerida = CASE id
    WHEN 6   THEN 'Suero (Tubo Rojo)'
    WHEN 7   THEN 'Suero (Tubo Rojo)'
    WHEN 8   THEN 'Suero (Tubo Rojo)'
    WHEN 9   THEN 'Suero (Tubo Rojo)'
    WHEN 10  THEN 'Suero (Tubo Rojo)'
    WHEN 11  THEN 'Suero (Tubo Rojo)'
    WHEN 12  THEN 'Suero (Tubo Rojo)'
    WHEN 14  THEN 'Suero (Tubo Rojo)'
    WHEN 15  THEN 'Suero (Tubo Rojo)'
    WHEN 16  THEN 'Suero (Tubo Rojo)'
    WHEN 17  THEN 'Suero (Tubo Rojo)'
    WHEN 18  THEN 'Suero (Tubo Rojo)'
    WHEN 20  THEN 'Orina de primer chorro (frasco limpio)'
    WHEN 21  THEN 'Orina de primer chorro (frasco limpio)'
    WHEN 22  THEN 'Plasma (Tubo Azul citrato)'
    WHEN 23  THEN 'Plasma (Tubo Azul citrato)'
    WHEN 24  THEN 'Plasma (Tubo Azul citrato)'
    WHEN 27  THEN 'Punción cutánea con lanceta'
    WHEN 28  THEN 'Suero (Tubo Rojo)'
    WHEN 29  THEN 'Suero (Tubo Rojo)'
    WHEN 30  THEN 'Suero (Tubo Rojo)'
    WHEN 31  THEN 'Suero (Tubo Rojo)'
    WHEN 32  THEN 'Suero (Tubo Rojo)'
    WHEN 33  THEN 'Suero (Tubo Rojo)'
    WHEN 34  THEN 'Suero (Tubo Rojo)'
    WHEN 35  THEN 'Suero (Tubo Rojo)'
    WHEN 36  THEN 'Suero (Tubo Rojo)'
    WHEN 37  THEN 'Suero (Tubo Rojo)'
    WHEN 38  THEN 'Suero (Tubo Rojo)'
    WHEN 39  THEN 'Suero (Tubo Rojo)'
    WHEN 40  THEN 'Suero (Tubo Rojo)'
    WHEN 41  THEN 'Suero (Tubo Rojo)'
    WHEN 45  THEN 'Orina de 24 horas (frasco LAESH)'
    WHEN 46  THEN 'Orina de 24 horas (frasco LAESH)'
    WHEN 48  THEN 'Suero (Tubo Rojo)'
    WHEN 49  THEN 'Suero (Tubo Rojo)'
    WHEN 52  THEN 'Plasma EDTA (Tubo Lila) o Suero (Tubo Rojo)'
    WHEN 56  THEN 'Suero (Tubo Rojo)'
    WHEN 57  THEN 'Suero (Tubo Rojo)'
    WHEN 58  THEN 'Suero (Tubo Rojo)'
    WHEN 59  THEN 'Suero (Tubo Rojo)'
    WHEN 60  THEN 'Suero (Tubo Rojo)'
    WHEN 61  THEN 'Suero (Tubo Rojo)'
    WHEN 62  THEN 'Suero (Tubo Rojo)'
    WHEN 65  THEN 'Suero (Tubo Rojo)'
    WHEN 66  THEN 'Suero (Tubo Rojo)'
    WHEN 67  THEN 'Sangre total (Tubo Lila/EDTA)'
    WHEN 69  THEN 'Suero (Tubo Rojo)'
    WHEN 71  THEN 'Suero (Tubo Rojo)'
    WHEN 72  THEN 'Suero (Tubo Rojo)'
    WHEN 73  THEN 'Suero (Tubo Rojo)'
    WHEN 74  THEN 'Suero (Tubo Rojo)'
    WHEN 76  THEN 'Suero (Tubo Rojo)'
    WHEN 77  THEN 'Suero (Tubo Rojo)'
    WHEN 78  THEN 'Hisopo nasofaríngeo o suero según prueba'
    WHEN 79  THEN 'Sangre total (Tubo Lila/EDTA)'
    WHEN 81  THEN 'Suero (Tubo Rojo)'
    WHEN 82  THEN 'Suero (Tubo Rojo)'
    WHEN 83  THEN 'Suero (Tubo Rojo)'
    WHEN 84  THEN 'Suero (Tubo Rojo)'
    WHEN 85  THEN 'Suero (Tubo Rojo)'
    WHEN 86  THEN 'Suero (Tubo Rojo)'
    WHEN 87  THEN 'Suero (Tubo Rojo)'
    WHEN 88  THEN 'Suero (Tubo Rojo)'
    WHEN 89  THEN 'Suero (Tubo Rojo)'
    WHEN 90  THEN 'Suero (Tubo Rojo)'
    WHEN 91  THEN 'Raspado cervical (Espátula de Ayre + hisopo endocervical)'
    WHEN 92  THEN 'Orina de chorro medio (frasco estéril)'
    WHEN 93  THEN 'Hisopo faríngeo (frasco con medio de transporte)'
    WHEN 94  THEN 'Hisopo vaginal (frasco con medio de transporte)'
    WHEN 95  THEN 'Hisopo uretral (frasco con medio de transporte)'
    WHEN 96  THEN 'Heces frescas (frasco limpio con tapa)'
    WHEN 97  THEN 'Hisopo o muestra de tejido de lesión (frasco con medio)'
    WHEN 98  THEN 'Esputo de tos profunda (frasco estéril)'
    WHEN 101 THEN 'Suero (Tubo Rojo)'
    WHEN 102 THEN 'Suero (Tubo Rojo)'
    WHEN 103 THEN 'Suero (Tubo Rojo)'
    WHEN 104 THEN 'Suero (Tubo Rojo)'
    WHEN 105 THEN 'Suero (Tubo Rojo)'
    WHEN 106 THEN 'Suero (Tubo Rojo)'
    WHEN 107 THEN 'Suero (Tubo Rojo)'
    WHEN 108 THEN 'Suero (Tubo Rojo)'
    WHEN 110 THEN 'Heces frescas (frasco limpio con tapa)'
    WHEN 111 THEN 'Heces frescas (frasco limpio con tapa)'
    WHEN 112 THEN 'Heces frescas o suero según método'
    WHEN 113 THEN 'Heces frescas (frasco limpio, congelada a -20°C)'
    WHEN 114 THEN 'Heces frescas (frasco limpio, congelada a -20°C)'
    WHEN 115 THEN 'Heces diarreicas frescas (frasco limpio)'
    WHEN 116 THEN 'Líquido cefalorraquídeo (punción lumbar en tubo seco)'
    WHEN 117 THEN 'Líquido sinovial (artrocentesis en tubo con EDTA)'
    WHEN 118 THEN 'Líquido pleural (toracocentesis en tubo seco)'
    WHEN 119 THEN 'Líquido ascítico (paracentesis en tubo seco)'
    WHEN 120 THEN 'Efluente peritoneal (frasco estéril)'
    WHEN 121 THEN 'Lavado broncoalveolar (frasco estéril)'
    WHEN 122 THEN 'Líquido pericárdico (frasco estéril)'
    WHEN 123 THEN 'Raspado cervical (medio de transporte para PCR)'
    WHEN 124 THEN 'Esputo, lavado bronquial o tejido (frasco estéril)'
    WHEN 125 THEN 'Hisopo nasofaríngeo (medio de transporte viral)'
    WHEN 126 THEN 'Líquido cefalorraquídeo (tubo seco estéril)'
    WHEN 127 THEN 'Hisopo nasofaríngeo (medio de transporte viral)'
    WHEN 128 THEN 'Semen fresco (frasco estéril de boca ancha)'
    ELSE muestra_requerida
  END,
  preparacion = CASE id
    WHEN 6   THEN '8 hrs de ayuno'
    WHEN 7   THEN '8–12 hrs de ayuno'
    WHEN 8   THEN '8–12 hrs de ayuno'
    WHEN 9   THEN '8–12 hrs de ayuno'
    WHEN 10  THEN '8–12 hrs de ayuno'
    WHEN 11  THEN 'Sin ayuno'
    WHEN 12  THEN '8–12 hrs de ayuno'
    WHEN 14  THEN 'Sin ayuno'
    WHEN 15  THEN 'Sin ayuno'
    WHEN 16  THEN 'Sin ayuno'
    WHEN 17  THEN 'Sin ayuno'
    WHEN 18  THEN 'Sin ayuno'
    WHEN 20  THEN 'Sin ayuno; orina matutina preferida'
    WHEN 21  THEN 'Sin ayuno; primera orina de la mañana'
    WHEN 22  THEN 'Sin ayuno; no suspender anticoagulantes'
    WHEN 23  THEN 'Sin ayuno; no suspender anticoagulantes'
    WHEN 24  THEN 'Sin ayuno; no suspender anticoagulantes'
    WHEN 27  THEN 'Sin ayuno'
    WHEN 28  THEN '9–12 hrs de ayuno'
    WHEN 29  THEN '9–12 hrs de ayuno'
    WHEN 30  THEN '9–12 hrs de ayuno'
    WHEN 31  THEN '8 hrs de ayuno (preferible)'
    WHEN 32  THEN '8 hrs de ayuno (preferible)'
    WHEN 33  THEN '8 hrs de ayuno (preferible)'
    WHEN 34  THEN 'Sin ayuno estricto'
    WHEN 35  THEN 'Sin ayuno'
    WHEN 36  THEN 'Sin ayuno'
    WHEN 37  THEN 'Sin ayuno; tomar muestra antes del medicamento tiroideo'
    WHEN 38  THEN 'Sin ayuno; tomar muestra antes del medicamento tiroideo'
    WHEN 39  THEN 'Sin ayuno'
    WHEN 40  THEN 'Sin ayuno'
    WHEN 41  THEN 'Sin ayuno; suspender biotina (vitamina B7) 48 hrs antes'
    WHEN 45  THEN 'Recolección completa de 24 horas; sin ayuno'
    WHEN 46  THEN 'Recolección completa de 24 horas; sin ayuno'
    WHEN 48  THEN 'Sin ayuno; urgencia'
    WHEN 49  THEN 'Sin ayuno'
    WHEN 52  THEN 'Sin ayuno'
    WHEN 56  THEN 'Sin ayuno; muestra en días 2–4 del ciclo (si aplica)'
    WHEN 57  THEN 'Sin ayuno; muestra en días 2–4 del ciclo (si aplica)'
    WHEN 58  THEN 'Sin ayuno; muestra en días 2–4 del ciclo (si aplica)'
    WHEN 59  THEN 'Sin ayuno; muestra matutina en reposo'
    WHEN 60  THEN 'Sin ayuno; muestra en día 21 del ciclo para confirmar ovulación'
    WHEN 61  THEN 'Sin ayuno; muestra matutina (pico de testosterona 8–10 am)'
    WHEN 62  THEN 'Sin ayuno'
    WHEN 65  THEN 'Sin ayuno; puede tomarse en cualquier día del ciclo'
    WHEN 66  THEN 'Sin ayuno'
    WHEN 67  THEN 'Sin ayuno'
    WHEN 69  THEN '8–12 hrs de ayuno'
    WHEN 71  THEN '12 hrs de ayuno; sin fumar el día del estudio'
    WHEN 72  THEN 'Sin ayuno previo; estado aleatorio'
    WHEN 73  THEN 'Sin ayuno'
    WHEN 74  THEN 'Sin ayuno'
    WHEN 76  THEN 'Sin ayuno'
    WHEN 77  THEN 'Sin ayuno'
    WHEN 78  THEN 'Sin ayuno'
    WHEN 79  THEN 'Sin ayuno'
    WHEN 81  THEN 'Sin ayuno'
    WHEN 82  THEN 'Sin ayuno'
    WHEN 83  THEN 'Sin ayuno'
    WHEN 84  THEN 'Sin ayuno'
    WHEN 85  THEN 'Sin ayuno'
    WHEN 86  THEN 'Sin ayuno'
    WHEN 87  THEN 'Sin ayuno'
    WHEN 88  THEN 'Sin ayuno'
    WHEN 89  THEN 'Sin ayuno'
    WHEN 90  THEN 'Sin ayuno; muestra matutina'
    WHEN 91  THEN 'Sin menstruación activa; abstinencia sexual 48 hrs'
    WHEN 92  THEN 'Sin antibióticos 3 días antes; limpieza genital previa'
    WHEN 93  THEN 'Sin antibióticos 3 días antes; no enjuague bucal'
    WHEN 94  THEN 'Sin antibióticos ni óvulos 3 días antes'
    WHEN 95  THEN 'Sin antibióticos 3 días antes'
    WHEN 96  THEN 'Sin antibióticos 3 días antes; sin laxantes ni bario'
    WHEN 97  THEN 'Sin antibióticos tópicos o sistémicos 3 días antes'
    WHEN 98  THEN 'Sin antibióticos 3 días antes; muestra de tos profunda'
    WHEN 101 THEN 'Sin eyaculación 48 hrs antes; sin tacto rectal previo'
    WHEN 102 THEN 'Sin eyaculación 48 hrs antes; sin tacto rectal previo'
    WHEN 103 THEN 'Sin ayuno'
    WHEN 104 THEN 'Sin ayuno'
    WHEN 105 THEN 'Sin ayuno'
    WHEN 106 THEN 'Sin ayuno'
    WHEN 107 THEN 'Sin ayuno'
    WHEN 108 THEN 'Sin ayuno'
    WHEN 110 THEN 'Sin laxantes, bario ni bismuto 3 días antes'
    WHEN 111 THEN 'Sin carne roja ni vitamina C 3 días antes (método guayaco)'
    WHEN 112 THEN 'Sin antibióticos 4 semanas antes; sin IBP 2 semanas antes'
    WHEN 113 THEN 'Sin antibióticos 4 semanas antes'
    WHEN 114 THEN 'Sin antibióticos 4 semanas antes'
    WHEN 115 THEN 'Sin antibióticos actuales si es posible; muestra fresca'
    WHEN 116 THEN 'Punción lumbar por médico especialista; tubo seco estéril'
    WHEN 117 THEN 'Artrocentesis por médico especialista'
    WHEN 118 THEN 'Toracocentesis por médico especialista'
    WHEN 119 THEN 'Paracentesis por médico especialista'
    WHEN 120 THEN 'Recolección estéril durante recambio de diálisis'
    WHEN 121 THEN 'Broncoscopía por neumólogo; frasco estéril'
    WHEN 122 THEN 'Pericardiocentesis por médico especialista'
    WHEN 123 THEN 'Sin menstruación activa; abstinencia sexual 48 hrs'
    WHEN 124 THEN 'Muestra de esputo de madrugada, antes del desayuno'
    WHEN 125 THEN 'Sin ayuno; muestra en los primeros 3 días de síntomas'
    WHEN 126 THEN 'Punción lumbar por médico especialista; tubo seco estéril'
    WHEN 127 THEN 'Sin ayuno; muestra en los primeros 5 días de síntomas'
    WHEN 128 THEN 'Abstinencia sexual 2–5 días; no más de 7 días; muestra fresca (menos de 1 hora)'
    ELSE preparacion
  END
WHERE id IN (4,6,7,8,9,10,11,12,14,15,16,17,18,20,21,22,23,24,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,45,46,48,49,52,56,57,58,59,60,61,62,63,65,66,67,69,71,72,73,74,76,77,78,79,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,101,102,103,104,105,106,107,108,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128)
  AND (tiempo_procesamiento = '' OR muestra_requerida = '' OR preparacion = '' OR tiempo_procesamiento IS NULL OR muestra_requerida IS NULL OR preparacion IS NULL);

-- ---------------------------------------------------------------------------


-- PROMOCIONES
INSERT IGNORE INTO `catalogo_promociones`
(`id`, `dia_semana`, `imagen_fondo`, `activo`, `orden`) 
VALUES
(1, 'Lunes', '/laesh-web-assets-uipv1a/cms/promo-lunes-bhc.webp', 1, 1),
(2, 'Martes', '/laesh-web-assets-uipv1a/cms/promo-martes-qs7.webp', 1, 2),
(3, 'Miércoles', '/laesh-web-assets-uipv1a/cms/promo-miercoles-ego.webp', 1, 3),
(4, 'Jueves', '/laesh-web-assets-uipv1a/cms/promo-jueves-hba1c.webp', 1, 4),
(5, 'Viernes', '/laesh-web-assets-uipv1a/img/lunes.webp', 1, 5),
(6, 'Sábado', '/laesh-web-assets-uipv1a/cms/promo-sabado-pfh.webp', 1, 6),
(7, 'Domingo', NULL, 1, 7);

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Contenido editorial (seed fidedigno desde local BD)
-- SSOT: exportado de laesh_db local 2026-08-25
-- Estrategia: INSERT IGNORE — si la fila ya existe (misma clave única seccion+subseccion+clave),
--             se preserva el valor editado en el CMS y no se sobreescribe.
--             Solo inserta filas nuevas que no existan aún.
--             NUNCA usar REPLACE INTO en producción: destruye los datos CMS editados.
-- Clave única: (seccion, subseccion, clave)
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('aviso-privacidad', 'contenido', 'cuerpo_html', '<p class=\"modal-p\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 1rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><strong style=\"box-sizing:border-box;margin:0px;padding:0px;\">LABORATORIO </strong><span style=\"color:#71CA11;\"><strong style=\"box-sizing:border-box;margin:0px;padding:0px;\">LAESH</strong></span>, con domicilio en Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.2, es responsable del tratamiento, uso, protección y resguardo de los datos personales que recaba de sus pacientes, usuarios y personas que solicitan nuestros servicios.</p><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">1. Datos personales que recabamos</h4><ul class=\"aviso-list\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.75rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Nombre completo.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Fecha de nacimiento y edad.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Sexo.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Datos de contacto, como teléfono, correo electrónico y domicilio.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Datos relacionados con la atención y solicitud de estudios de laboratorio.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Información necesaria para la identificación y entrega de resultados.</li></ul><p class=\"modal-p--main\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><strong>Datos personales sensibles</strong></p><p class=\"aviso-p aviso-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Por la naturaleza de nuestros servicios, podremos tratar datos personales sensibles relacionados con el estado de salud. Estos datos serán tratados con medidas de seguridad y confidencialidad.</p><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">2. Finalidades del tratamiento</h4><ol class=\"aviso-list\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.75rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Identificar y registrar al paciente.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Solicitar, procesar y entregar estudios de laboratorio.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Elaborar y conservar los resultados correspondientes.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Dar seguimiento a los servicios solicitados.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Atender dudas, aclaraciones o solicitudes relacionadas con sus resultados.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Cumplir con las obligaciones legales y sanitarias aplicables.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Mantener registros administrativos, contables y relacionados con la prestación del servicio.</li></ol><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">3. Protección y confidencialidad</h4><p class=\"aviso-p aviso-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Laboratorio LAESH implementa medidas administrativas, técnicas y físicas destinadas a proteger los datos personales contra daño, pérdida, alteración, destrucción, acceso o tratamiento no autorizado.</p><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">4. Derechos ARCO</h4><p class=\"aviso-p aviso-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Usted tiene derecho a Acceder, Rectificar, Cancelar u Oponerse al tratamiento de sus datos personales. Para ejercer estos derechos contáctenos por:</p><ul class=\"aviso-list aviso-list--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.5rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Correo: <a class=\"txt-primary-c\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;\" href=\"mailto:11lab_laesh@hotmail.com\">11lab_laesh@hotmail.com</a></li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Teléfono: <strong style=\"box-sizing:border-box;margin:0px;padding:0px;\">953 688 769410</strong></li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Domicilio: Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.2</li></ul><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">5. Modificaciones</h4><p class=\"aviso-p aviso-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Laboratorio LAESH podrá modificar este Aviso cuando resulte necesario. Las modificaciones estarán disponibles en nuestro sitio web.</p><p class=\"modal-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.8rem;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0px 0px 1rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><i>Última actualización: agosto de 2026</i></p><div class=\"highlight-block\" style=\"-webkit-text-stroke-width:0px;background-color:rgba(113, 202, 17, 0.06);border-left:3px solid rgb(113, 202, 17);border-radius:0px 6px 6px 0px;box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0.5rem 0px 0px;orphans:2;padding:0.85rem 1rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><p class=\"modal-p--pgd\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.88rem;margin:0px 0px 0.35rem;padding:0px;\"><strong>Consentimiento</strong></p><p class=\"modal-p--tail\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.7;margin:0px;padding:0px;\">Declaro que he leído y comprendido el presente Aviso de Privacidad y manifiesto mi consentimiento para el tratamiento de mis datos personales para las finalidades señaladas.</p></div>', 'html'),
    ('calidad', 'gallery1', 'descripcion', 'Análisis de biometría hemática y células sanguíneas con rigor científico y alta precisión.', 'texto'),
    ('calidad', 'gallery1', 'titulo', 'Área de Hematología', 'texto'),
    ('calidad', 'gallery2', 'descripcion', 'Determinación automatizada de metabolitos, perfil lipídico y enzimas específicas.', 'texto'),
    ('calidad', 'gallery2', 'titulo', 'Química Clínica', 'texto'),
    ('calidad', 'gallery3', 'descripcion', 'Aislamiento, tinción de Gram y pruebas de susceptibilidad a antimicrobianos.', 'texto'),
    ('calidad', 'gallery3', 'titulo', 'Microbiología y Cultivos', 'texto'),
    ('calidad', 'seccion', 'h2', 'Calidad e Instalaciones', 'texto'),
    ('calidad', 'seccion', 'subtitulo', 'Conoce nuestras instalaciones equipadas con tecnología de vanguardia y un equipo comprometido con la excelencia diagnóstica.', 'texto'),
    ('especialidades', 'carousel1', 'texto', '<h3>Hematología Especializada</h3><p>Análisis morfológico de frotis sanguíneo y pruebas hematológicas de alta complejidad.</p>', 'html'),
    ('especialidades', 'carousel10', 'texto', '<h3>Toma Pediátrica</h3><p>Espacio amigable y personal capacitado para el cuidado y tranquilidad de los niños.</p>', 'html'),
    ('especialidades', 'carousel11', 'texto', '<h3>Toma de Cultivos</h3><p>Zonas aisladas y estériles para la toma de exudados y cultivos microbiológicos.</p>', 'html'),
    ('especialidades', 'carousel12', 'texto', '<h3>Recepción Técnica</h3><p>Recepción técnica de muestras e indicaciones pre-analíticas detalladas.</p>', 'html'),
    ('especialidades', 'carousel13', 'texto', '', 'html'),
    ('especialidades', 'carousel14', 'texto', '', 'html'),
    ('especialidades', 'carousel15', 'texto', '', 'html'),
    ('especialidades', 'carousel16', 'texto', '', 'html'),
    ('especialidades', 'carousel2', 'texto', '<h3>Química Clínica Avanzada</h3><p>Determinación automatizada de electrolitos, proteínas y enzimas específicas.</p>', 'html'),
    ('especialidades', 'carousel3', 'texto', '<h3>Microbiología y Cultivos</h3><p>Identificación microscópica y pruebas de susceptibilidad a antimicrobianos.</p>', 'html'),
    ('especialidades', 'carousel4', 'texto', '<h3>Uroanálisis y Sedimentos</h3><p>Examen de orina, química y microscopía para detección precoz de patologías renales.</p>', 'html'),
    ('especialidades', 'carousel5', 'texto', '<h3>Hemostasia y Coagulación</h3><p>Estudios de tiempos de protrombina (TP) y tromboplastina parcial activada (TTPa).</p>', 'html'),
    ('especialidades', 'carousel6', 'texto', '<h3>Pruebas Especiales</h3><p>Hormonas, anticuerpos específicos, pruebas inmunológicas y marcadores tumorales.</p>', 'html'),
    ('especialidades', 'carousel7', 'texto', '<h3>Pre-analítica</h3><p>Separación de suero y plasma con control estricto de tiempos y temperaturas.</p>', 'html'),
    ('especialidades', 'carousel8', 'texto', '<h3>Toma de Muestras I</h3><p>Áreas higiénicas equipadas para la extracción sanguínea convencional.</p>', 'html'),
    ('especialidades', 'carousel9', 'texto', '<h3>Toma de Muestras II</h3><p>Módulos individuales y confortables que aseguran una atención rápida y sin molestias.</p>', 'html'),
    ('especialidades', 'catalogo', 'nota_pie', 'Listas de Estudios disponibles 2026 · Haz clic en cada grupo para expandir', 'texto'),
    ('especialidades', 'cg1', 'fichas', '[Hematología] Citometría Hemática, Grupo y RH, Plaquetas, VSG, Reticulocitos, Perfil de Hierro,
[Química Clínica] QS3, QS7, Perfil Bioquímico 15/24/30/35/45, Glucosa, Creatinina, Colesterol, Triglicéridos,
[Electrolitos Séricos] ES 3/4/Completos, Calcio, Fósforo, Magnesio, Bicarbonato CO2,
[Uroanálisis] EGO + Radio Prot/Crea, EGO Especializado, Antidoping 5/12 elem.,
[Coagulación] Perfil de Coagulación, TP/INR, TTPa, Fibrinógeno, Dímero D, T. Sangrado,
[Lípidos] Perfil de Lípidos I, II, Perfil Aterogénico', 'texto'),
    ('especialidades', 'cg1', 'titulo', 'Rutina General — Hematología, Química Clínica, Electrolitos, Uroanálisis, Coagulación', 'texto'),
    ('especialidades', 'cg2', 'fichas', '[Función Hepática] PFH Básico, PFH Completo, Transaminasas, GGT, Proteínas Totales, Albumina,
[Función Tiroidea] Perfil Tiroideo I-IV, TSH, Ac. Anti Tiroideos I-II, Ac. Anti Receptor TSH, Tiroglobulina,
[Función Pancreática] Amilasa sérica, Lipasa sérica,
[Función Renal] Cistatina C, Depuración creatinina, Proteínas orina, Microalbuminuria,
[Función Cardiaca] Triage cardiaco, Perfil cardiaco completo, Troponina I, Troponina T, NT-pro BNP, Mioglobina,
[Gasometría] Gasometría Arterial Completa, Gasometría Venosa Completa', 'texto'),
    ('especialidades', 'cg2', 'titulo', 'Función de Órganos — Hepática, Tiroidea, Pancreática, Renal, Cardiaca, Gasometría', 'texto'),
    ('especialidades', 'cg3', 'fichas', '[Hormonas] Perfil Ginecológico I-II, Perfil Hormonal Masculino, FSH, LH, PRL, PROG, TESTOSTERONA Total/Libre, DHEA-S, Cortisol, AMH, PTH-i,
[Diabetes] HbA1c, Insulina, HOMA-IR, Péptido C, Prueba de Tolerancia Glucosa, Test O\'Sullivan,
[Inmunología] HIV 1/2, V.D.R.L., Reacciones Febriles, Hepatitis A-B-C, Dengue, COVID-19, Coombs, Procalcitonina,
[Reumatología] Perfil Reumático, PCR, Factor Reumatoide, CCP, ANA, Anti DNA, Complementos C3/C4,
[Diversos] Vitamina D, Inmunoglobulina E, Somatomedina C, Papanicolaou', 'texto'),
    ('especialidades', 'cg3', 'titulo', 'Hormonas, Diabetes e Inmunología — Perfil Ginecológico, Masculino, Diabetes, Inmunología, Reumatología', 'texto'),
    ('especialidades', 'cg4', 'fichas', '[Bacteriología] Cultivo de orina MIC, Ex. Faríngeo MIC, Ex. Vaginal MIC, Uretral MIC, Heces MIC, Lesión MIC, Expectoración MIC, Hemocultivo MIC, Cultivo Micológico,
[Marcadores Tumorales] PSA Total, PSA Libre, CEA, AFP, CA-125, CA-15-3, CA-19-9, Perfil Tumoral Femenino/Masculino,
[Parasitología] Coproparasitoscópico 3 muestras, Coprológico completo/especial, Sangre Oculta, H. Pylori, Calprotectina, Lactoferrina, Clostridium difficile,
[Citroquímicos] LCR, Sinovial, Pleural, Ascitis, Diálisis, Bronquial, Pericárdico,
[Biología Molecular] PCR VPH, PCR Mycobacterium, PCR Patógenos respiratorios, PCR Meningitis viral, PCR SARS-CoV-2,
[Fertilidad] Espermatobioscopia directa', 'texto'),
    ('especialidades', 'cg4', 'titulo', 'Bacteriología, Marcadores Tumorales, Parasitología, Citroquímicos, Biología Molecular, Fertilidad', 'texto'),
    ('especialidades', 'seccion', 'h2', 'Estudios de Rutina y Especialidades', 'texto'),
    ('especialidades', 'seccion', 'subtitulo', 'Servicios clínicos diseñados con rigor científico para garantizar la máxima confiabilidad en el diagnóstico médico.', 'texto'),
    ('footer', 'contenido', 'cuerpo_html', '<div class=\"footer-info\">
    <img src=\"/laesh-web-assets-uipv1a/img/logo-laesh.webp\" alt=\"LAESH Laboratorio de Especialidades Hematológicas\" class=\"footer-logo-img\" style=\"max-height: 40px; width: auto;\" decoding=\"async\" loading=\"lazy\">
    <p class=\"footer-text\">
        <strong>Laboratorio de Especialidades Hematológicas S.C.</strong> &nbsp;|&nbsp; Azucenas No. 8, Col. Jardines del Sur, Huajuapan de León, Oax. &nbsp;|&nbsp; Tel: <a href=\"tel:9535320268\">953 532 0268</a> &nbsp;|&nbsp; WhatsApp: <a href=\"https://wa.me/529531190074\" target=\"_blank\" rel=\"noopener noreferrer\">953 119 0074</a>
    </p>
    <p class=\"footer-text\">
        Lunes a Sábado 7:00 a 20:00 hrs &nbsp;·&nbsp; Domingo 8:00 a 14:00 hrs &nbsp;|&nbsp; <a href=\"#\" id=\"link-privacy\">Aviso de Privacidad</a> &nbsp;|&nbsp; © 2026 LAESH. Todos los derechos reservados.
    </p>
</div>', 'html'),
    ('footer', 'estilo', 'bg_color', '#0f172a', 'texto'),
    ('hero', 'config', 'transition_time', '5', 'texto'),
    ('hero', 'navbar', 'tagline_l1', 'Diagnósticos deB', 'texto'),
    ('hero', 'navbar', 'tagline_l2', 'Confianza y Calidad', 'texto'),
    ('hero', 'slide1', 'cta_href', '#especialidades', 'texto'),
    ('hero', 'slide1', 'cta_texto', 'Conoce los Servicios', 'texto'),
    ('hero', 'slide1', 'descripcion', 'Ofrecemos servicios integrales de análisis clínicos especializados con precisión científica y calidez humana.', 'texto'),
    ('hero', 'slide1', 'etiqueta', 'Un laboratorio seguro con Resultados ConfiablesB', 'texto'),
    ('hero', 'slide1', 'imagen_url', '/laesh-web-assets-uipv1a/img/recepcion-de-pacientes.webp', 'imagen_url'),
    ('hero', 'slide1', 'titulo', 'Laboratorio de Especialidades Hematológicas', 'texto'),
    ('hero', 'slide2', 'cta_href', '#especialidades', 'texto'),
    ('hero', 'slide2', 'cta_texto', 'Ver Especialidades', 'texto'),
    ('hero', 'slide2', 'descripcion', 'Detrás de cada resultado hay una decisión. Por eso, en LAESH® la calidad no es una opción: es nuestro compromiso.', 'texto'),
    ('hero', 'slide2', 'etiqueta', '25 Años de Experiencia Clínica', 'texto'),
    ('hero', 'slide2', 'imagen_url', '/laesh-web-assets-uipv1a/img/recepcion.webp', 'imagen_url'),
    ('hero', 'slide2', 'titulo', 'Un laboratorio seguro con Resultados Confiables', 'texto'),
    ('hero', 'slide3', 'cta_href', '#calidad', 'texto'),
    ('hero', 'slide3', 'cta_texto', 'Conocer Calidad', 'texto'),
    ('hero', 'slide3', 'descripcion', 'Detrás de cada análisis existe una decisión médica crucial. En LAESH® la precisión diagnóstica es nuestro compromiso inquebrantable.', 'texto'),
    ('hero', 'slide3', 'etiqueta', 'Excelencia y Calidad Certificada', 'texto'),
    ('hero', 'slide3', 'imagen_url', '/laesh-web-assets-uipv1a/img/recepcion-de-pacientes.webp', 'imagen_url'),
    ('hero', 'slide3', 'titulo', 'Resultados Confiables para Cuidar tu Salud', 'texto'),
    ('hero', 'slide4', 'cta_href', '#promociones', 'texto'),
    ('hero', 'slide4', 'cta_texto', 'Ver Promociones', 'texto'),
    ('hero', 'slide4', 'descripcion', 'Descubre nuestros paquetes preventivos y tarifas especiales diseñadas para el cuidado integral de tu salud y la de toda tu familia.', 'texto'),
    ('hero', 'slide4', 'etiqueta', 'Tarifas y Paquetes Preferenciales', 'texto'),
    ('hero', 'slide4', 'imagen_url', '/laesh-web-assets-uipv1a/img/sala-de-espera.webp', 'imagen_url'),
    ('hero', 'slide4', 'titulo', 'Promociones y Check-Ups Médicos 2026', 'texto'),
    ('hero', 'slide5', 'cta_href', '#ubicacion', 'texto'),
    ('hero', 'slide5', 'cta_texto', 'Ver Ubicación', 'texto'),
    ('hero', 'slide5', 'descripcion', 'Visítanos en Azucenas 8, Jardines del Sur, Huajuapan de León. Lunes a sábado 7:00 a.m. – 9:00 p.m.', 'texto'),
    ('hero', 'slide5', 'etiqueta', 'Atención Presencial y Horarios', 'texto'),
    ('hero', 'slide5', 'imagen_url', '/laesh-web-assets-uipv1a/img/recepcion-de-pacientes.webp', 'imagen_url'),
    ('hero', 'slide5', 'titulo', 'Ubicación, Horarios de Atención y Contacto', 'texto'),
    ('promociones', 'banner', 'subtitulo', 'Aprovecha nuestras tarifas preferenciales y paquetes diseñados para ti.', 'texto'),
    ('promociones', 'banner', 'titulo', 'Promociones Vigentes', 'texto'),

    ('quienes-somos', 'ficha1', 'texto', '<h3 class="acerca-h3b" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);flex-shrink:0;font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.75rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">🔵 25 años de experiencia al servicio del diagnóstico</h3><div class="modal-scroll-body" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0px;max-height:320px;orphans:2;overflow-y:auto;padding:0px 8px 0px 0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">LAESH, Laboratorio de Especialidades Hematológicas, es una empresa 100% de la Región Mixteca, fundada en septiembre de 2022 en Huajuapan de León, Oaxaca, con el propósito de ofrecer servicios de laboratorio clínico confiables, especializados y de alta calidad para médicos y pacientes.</p><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">Nuestra experiencia está respaldada por <strong class="txt-green" style="box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;">25 años</strong> de trayectoria profesional, un equipo de químicos especialistas con estudios de posgrado y especialización en Hematología Diagnóstica por Laboratorio, así como por la actualización permanente de nuestras pruebas y perfiles de acuerdo con las guías de práctica clínica y recomendaciones actuales.</p><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">Contamos con un amplio catálogo de estudios, desde análisis de rutina hasta pruebas altamente especializadas, apoyados en equipos de nueva generación, procesos de calidad y personal capacitado para proporcionar resultados confiables y clínicamente relevantes.</p><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">Nuestro compromiso con la calidad se refleja en nuestra participación en programas de evaluación externa, donde hemos obtenido calificaciones de <strong class="txt-primary-c" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">EXCELENCIA</strong>, así como en el <strong class="txt-green" style="box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;">Galardón Rey PACAL</strong>, reconocimiento relacionado con nuestro desempeño dentro de los laboratorios evaluados.</p><hr><p class="txt-pgd-sm" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;"><strong>Nuestro compromiso</strong></p><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">En LAESH trabajamos para que cada resultado sea una herramienta útil para el médico y una fuente de confianza para el paciente.</p><hr><p class="txt-pgd-sm" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;"><strong>Nuestro responsable sanitario</strong></p><p class="faq-p--text" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.5rem;padding:0px;"><strong class="txt-main" style="box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;">Q.F.B. y E.H.D.L. Jacob Santiago Blanco</strong><br>Químico Farmacéutico Biólogo egresado de la Universidad Autónoma de Sinaloa, con especialidad en Hematología Diagnóstica por Laboratorio por el Instituto de Hematopatología.</p><p class="faq-p--text2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.84rem;line-height:1.6;margin:0px 0px 0.9rem;padding:0px;">Cédula Profesional: <strong class="txt-main" style="box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;">3609293</strong> &nbsp;|&nbsp; Cédula de Especialidad: <strong class="txt-main" style="box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;">8935780</strong><br>Con <strong class="txt-green" style="box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;">25 años</strong> de experiencia profesional, su trayectoria representa uno de los principales pilares de la calidad y especialización de LAESH.</p><hr><p class="txt-pgd-sm" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;"><strong>🧬 Nuestra filosofía</strong></p><p class="faq-p--primary" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.5rem;padding:0px;"><strong>Resultados que dan confianza, decisiones que cuidan.</strong></p><p class="faq-p--tail" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px;padding:0px;">En LAESH entendemos que detrás de cada muestra existe una persona y detrás de cada resultado existe una decisión clínica. Por ello, trabajamos para ofrecer información diagnóstica confiable, oportuna y clínicamente relevante, que ayude al médico a tomar mejores decisiones y al paciente a recibir una atención adecuada.</p></div>', 'html'),
    ('quienes-somos', 'ficha2', 'texto', '<h3 class="txt-pgd-sub" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.6rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">🔵 MISIÓN 🔵</h3><p class="aviso-p aviso-p--muted" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">Brindar resultados confiables y clínicamente relevantes que ayuden al médico a tomar mejores decisiones y al paciente a recibir una atención oportuna y segura.</p>', 'texto'),
    ('quienes-somos', 'ficha3', 'texto', '<h3 class="txt-pgd-sub" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.6rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">🟢 VISIÓN 🟢</h3><p class="aviso-p aviso-p--muted" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">Ser el laboratorio de referencia para médicos y pacientes, reconocido por la excelencia de nuestros resultados, la especialización de nuestro equipo y nuestro compromiso permanente con la calidad.</p>', 'texto'),
    ('quienes-somos', 'ficha4', 'texto', '<h3 class="acerca-h3" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.85rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">🟢 ¿ POR QUÉ CONFIAR EN LAESH <sup style="box-sizing:border-box;margin:0px;padding:0px;">® </sup>? 🟢</h3><div class="acerca-flex" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(15, 23, 42);display:flex;flex-direction:column;font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;gap:7px;letter-spacing:normal;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-c fw-bold" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">25 años</strong> de experiencia</p><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-bold" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">Químicos especialistas</strong> con estudios de posgrado</p><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-bold" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">Guías de práctica clínica</strong> — pruebas y perfiles actualizados</p><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-bold" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">Excelencia</strong> en programas de control de calidad externo</p><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-c" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">Galardón Rey PACAL</strong> — reconocimiento a nuestro desempeño</p></div>', 'texto'),
    ('quienes-somos', 'seccion', 'h2', 'Quiénes somos', 'texto'),
    ('quienes-somos', 'seccion', 'subtitulo', 'La calidad de un resultado también se mide por la confianza que genera 25 años transformando resultados en decisiones clínicas.', 'texto'),
    ('seo', 'meta', 'description', 'Análisis clínicos especializados: hematología, bioquímica, inmunología, bacteriología y biología molecular en Huajuapan de León, Oaxaca.', 'texto'),
    ('seo', 'meta', 'title', 'LAESH — Laboratorio de Especialidades Hematológicas en Huajuapan de León, Oaxaca', 'texto'),
    ('seo', 'og', 'og_description', 'Diagnósticos clínicos de alta precisión con resultados confiables. Visítanos en Huajuapan de León, Oaxaca.', 'texto'),
    ('seo', 'og', 'og_image', '/laesh-web-assets-uipv1a/img/laesh-slider-futurista-c.webp', 'imagen_url'),
    ('seo', 'og', 'og_title', 'LAESH — Laboratorio de Especialidades Hematológicas', 'texto'),
    ('seo', 'schema', 'schema_name', 'Laboratorio de Especialidades Hematológicas LAESH', 'texto'),
    ('seo', 'schema', 'schema_type', 'MedicalLaboratory', 'texto'),
    ('ubicacion', 'seccion', 'h2', 'Ubicación y Contacto', 'texto'),
    ('ubicacion', 'seccion', 'subtitulo', 'Visítenos en nuestras instalaciones, será un placer atenderle.', 'texto')
;

