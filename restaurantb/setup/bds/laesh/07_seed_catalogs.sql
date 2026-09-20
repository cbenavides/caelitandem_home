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
--   • estudios = fuente de verdad de todo dato clínico (nombre, ayuno, tiempo, clave, muestra)
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
    (4, 'Cerrada',           'Orden finalizada y entregada',                                   '#6B7280'),
    (5, 'Cancelada',         'Orden cancelada — solo posible desde Remitido o En Atención',     '#EF4444');

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
-- CATALOGOS RELACIONALES — Datos exportados de BD local (SSOT: LISTA 2026 PAGINA BUENAS.xlsx)
-- Última exportación: 2026-09-17
-- ---------------------------------------------------------------------------
LOCK TABLES `cat_categorias` WRITE;
INSERT IGNORE INTO `cat_categorias` (`id`, `nombre`, `orden`) VALUES
(1,'Referencia orthin',1),
(2,'Referencia LCP',2),
(3,'Serología',3),
(4,'Química Sanguínea',4),
(5,'Referencia QUEST',5),
(6,'Inmunología/Placa',6),
(7,'Inmunología',7),
(8,'referencia arh',8),
(9,'Referencia Galindo',9),
(10,'Urianálisis',10),
(11,'Microbiología',11),
(12,'PATOLOGIA',12),
(13,'Referencia asesores',13),
(14,'Parasitología',14),
(15,'Hematología',15),
(16,'LAESH',16),
(17,'DIVERSOS',17),
(18,'LAESH',18),
(19,'LAESH/ORTHIN',19),
(20,'Coagulación',20),
(21,'LCP/ORTM',21),
(22,'COAGULACION',22),
(23,'LAESH/ARH',23),
(24,'MATERIAL',24);
UNLOCK TABLES;

LOCK TABLES `cat_estudios` WRITE;
INSERT IGNORE INTO `cat_estudios` (`id`, `categoria_id`, `clave`, `nombre`, `tiempo`, `muestra`, `contenedor`, `preparacion`, `pruebas_incluidas`, `descripcion_breve`, `activo`) VALUES
(1,1,'1','17 ALFA HIDROXIPROGESTERONA BASAL','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(2,2,'1153','17 CETOESTEROIDES EN SUERO','2','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(3,1,'228','17 HIDROXICORTICOESTEROIDES EN ORINA','8','Orina de 24 hrs. 20 ml','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(4,1,'4103','AC ANTI CARDIOLIPINA IGA','13','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(5,1,'2022','AC ANTI CARDIOLIPINA IGG,IGM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(6,1,'1897','AC ANTI CHLAMYDIA TRACHOMATIS IgM','3','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(7,1,'2026','AC ANTI RICKETTSIA TYPHI (IgG, IgM)','20','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(8,2,'4679','AC CITOSOL HEPATICO (ALC-1)','0',NULL,NULL,NULL,NULL,NULL,1),
(9,2,'4330','AC CONTRA AG ASOCIADO A ESCLEROSIS','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(10,2,'2817','AC CONTRA AG ASOCIADOS A MIOSITIS','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(11,2,'2385','AC.  ANTI GLIADINA (IgG, IgA)','9',NULL,NULL,NULL,NULL,NULL,1),
(12,2,'2113','Ac.  ANTI VARICELA/ZOSTER (IgG, IgM)','13','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(13,2,'2617','AC. ADDISON','5','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(14,2,'2587','AC. ADRENALES','5',NULL,NULL,NULL,NULL,NULL,1),
(15,1,'578','AC. ANTI   JO 1','5','Sangre total heparina',NULL,NULL,NULL,NULL,1),
(16,3,'122','AC. ANTI  HEPATITIS " A " IgG','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(17,4,'123','AC. ANTI  HEPATITIS A IgM','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(18,1,'2796','AC. ANTI  MUSCULO LISO (ASMA)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(19,2,'1184','Ac. ANTI  MYCOBACTERIUM TB (IgG, IgM)','5',NULL,NULL,NULL,NULL,NULL,1),
(20,2,'502','AC. ANTI  RNA','5',NULL,NULL,NULL,NULL,NULL,1),
(21,1,'300','AC. ANTI  SCL-70','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(22,2,'585','Ac. ANTI  SSA (Ro)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(23,2,'595','AC. ANTI  SSB (La)','5',NULL,NULL,NULL,NULL,NULL,1),
(24,1,'4398','Ac. Anti 21 Hidroxilasa (Adrenal 21 hidroxilasa)','24',NULL,NULL,NULL,NULL,NULL,1),
(25,2,'185','AC. ANTI AMIBA (SERAMEBA)','3',NULL,NULL,NULL,NULL,NULL,1),
(26,5,'4304','AC. ANTI ANEXINA V','15','Suero 2 ml congelado','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(27,1,'4680','AC. ANTI ANTIGENO HEPATICO SOLUBLE (SLA)','0',NULL,NULL,NULL,NULL,NULL,1),
(28,2,'2109','Ac. ANTI ASPERGILLUS FUMIGATUS IgE','11',NULL,NULL,NULL,NULL,NULL,1),
(29,1,'2800','AC. ANTI BARTONELLA HENSESLAE','12',NULL,NULL,NULL,NULL,NULL,1),
(30,1,'2104','AC. ANTI BETA 2 GLICOPROTEINA IgA, IgG, IgM','4',NULL,NULL,NULL,NULL,NULL,1),
(31,1,'2123','Ac. Anti Beta 2 glucoproteina IgA','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(32,2,'2121','Ac. Anti Beta 2 glucoproteina IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(33,2,'2122','Ac. Anti Beta 2 glucoproteina IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(34,2,'1159','AC. ANTI BORDETELLA PERTUSSIS (TOSFERINA)','9',NULL,NULL,NULL,NULL,NULL,1),
(35,2,'554','AC. ANTI BORRELIA BURGDORFERI (Lyme)','9',NULL,NULL,NULL,NULL,NULL,1),
(36,2,'2111','Ac. ANTI BRUCELLA  IgM','8',NULL,NULL,NULL,NULL,NULL,1),
(37,2,'2110','Ac. ANTI BRUCELLA IgG','8',NULL,NULL,NULL,NULL,NULL,1),
(38,1,'2023','Ac. Anti Cardiolipina IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(39,1,'2024','Ac. Anti Cardiolipina IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(40,2,'1936','AC. ANTI CENTROMERO (Cenp-B)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(41,1,'2802','AC. ANTI CHIKUNGUNYA IgM, IgG','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(42,2,'413','AC. ANTI CHLAMYDIA PNEUMONIAE IgG, IgA','8',NULL,NULL,NULL,NULL,NULL,1),
(43,1,'2984','AC. ANTI CHLAMYDIA TRACHOMATIS IgA','3','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(44,1,'217','AC. ANTI CHLAMYDIA TRACHOMATIS IgG','3','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(45,1,'37','Ac. ANTI CHLAMYDIA TRACHOMATIS IgM, IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(46,2,'242','AC. ANTI CISTICERCO EN LCR','7','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(47,1,'252','AC. ANTI CISTICERCO EN SUERO','7',NULL,NULL,NULL,NULL,NULL,1),
(48,1,'263','AC. ANTI CITOMEGALOVIRUS IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(49,2,'4230','AC. ANTI CITOMEGALOVIRUS IgG/IgM','4',NULL,NULL,NULL,NULL,NULL,1),
(50,1,'274','AC. ANTI CITOMEGALOVIRUS IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(51,2,'571','AC. ANTI CITOPLASMA DE NEUTROFILOS (ANCA P y C)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(52,1,'1162','AC. ANTI COCCIDIOIDES IMMITIS IgM','12',NULL,NULL,NULL,NULL,NULL,1),
(53,2,'2384','AC. ANTI CORE VBH (TOTAL)','4',NULL,NULL,NULL,NULL,NULL,1),
(54,1,'2774','AC. ANTI COXIELLA BURNETTI (IgG, IgM)','20',NULL,NULL,NULL,NULL,NULL,1),
(55,1,'3017','Ac. Anti Coxsackie A virus (A2,4,7,9,10,16)','25',NULL,NULL,NULL,NULL,NULL,1),
(56,1,'3018','Ac. Anti Coxsackie B virus (B1, 2, 3, 4, 5, 6)','20',NULL,NULL,NULL,NULL,NULL,1),
(57,1,'1166','AC. ANTI CRYPTOCOCCUS NEOFORMANS EN SUERO','20',NULL,NULL,NULL,NULL,NULL,1),
(58,6,'330','AC. ANTI DENGUE (NS1, IgM, IgG)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(59,1,'297','Ac. anti DNA DOBLE CADENA (dsDNA)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(60,2,'287','Ac. ANTI DNA UNA CADENA (ssDNA)','5','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(61,1,'4877','AC. ANTI DNASA B ( ADN-B )','18','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(62,1,'1168','AC. ANTI ECHINOCOCCUS GRANULOSUS IgG','25',NULL,NULL,NULL,NULL,NULL,1),
(63,1,'307','AC. ANTI ENA (SM Y RNP)','5','Sangre total heparina',NULL,NULL,NULL,NULL,1),
(64,2,'2133','Ac. ANTI ENDOMISIO (Anti-EMA)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(65,1,'483','AC. ANTI EPSTEIN BARR Ag CAPSIDE  IgG','6',NULL,NULL,NULL,NULL,NULL,1),
(66,1,'486','AC. ANTI EPSTEIN BARR Ag CAPSIDE IgM','6',NULL,NULL,NULL,NULL,NULL,1),
(67,1,'490','AC. ANTI EPSTEIN BARR Ag NUCLEAR IgG','6',NULL,NULL,NULL,NULL,NULL,1),
(68,1,'1172','AC. ANTI EPSTEIN BARR IgG ANTIGENO TEMPRANO','6',NULL,NULL,NULL,NULL,NULL,1),
(69,2,'258','AC. ANTI ESPERMA (INDIRECTOS)','3',NULL,NULL,NULL,NULL,NULL,1),
(70,2,'329','AC. ANTI ESPERMATOZOIDES','3',NULL,NULL,NULL,NULL,NULL,1),
(71,2,'1158','AC. ANTI FACTOR INTRINSECO','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(72,1,'339','AC. ANTI FOSFOLIPIDOS (IgG, IgM)','5',NULL,NULL,NULL,NULL,NULL,1),
(73,1,'805','Ac. Anti Fosfolípidos IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(74,1,'806','Ac. Anti Fosfolípidos IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(75,2,'2130','AC. ANTI GAD (Ácido Glutámico Descarboxilasa)','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(76,2,'2590','AC. ANTI GNATHOSTOMA','12','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(77,1,'350','Ac. ANTI HELICOBACTER PYLORI  IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(78,1,'482','Ac. ANTI HELICOBACTER PYLORI IgA','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(79,1,'1183','Ac. ANTI HELICOBACTER PYLORI IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(80,4,'131','Ac. ANTI HEPATITIS C','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(81,7,'2928','Ac. ANTI HEPATITIS C (CLIA)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(82,2,'1261','AC. ANTI HEPATITIS D','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(83,1,'372','AC. ANTI HERPES  1  IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(84,1,'361','AC. ANTI HERPES 1  IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(85,1,'383','AC. ANTI HERPES 2  IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(86,1,'394','AC. ANTI HERPES 2  IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(87,1,'405','AC. ANTI HISTONAS','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(88,2,'299','AC. ANTI HISTOPLASMA CAPSULATUM IgM','12',NULL,NULL,NULL,NULL,NULL,1),
(89,4,'416','Ac. ANTI HIV 1/ HIV 2','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(90,2,'4323','Ac. ANTI HIV 1/ HIV 2 (CLIA/ELISA)','2','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(91,2,'528','AC. ANTI INSULINA','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(92,1,'543','AC. ANTI ISLOTES DE LANGERHANS','15','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(93,2,'2114','Ac. ANTI LEISHMANIA DONOVANI IgG e IgM','10',NULL,NULL,NULL,NULL,NULL,1),
(94,2,'2450','AC. ANTI LEPTOSPIRA IgG e IgM','8','Suero','Tubo amarillo',NULL,NULL,NULL,1),
(95,1,'2115','Ac. ANTI LKM (Microsomales de Higado y Riñon)','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(96,2,'4513','Ac. ANTI LRP4  (LDL receptor related protein 4)','40','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(97,2,'550','AC. ANTI M. TUBERCULOSIS IGG, IGM','5',NULL,NULL,NULL,NULL,NULL,1),
(98,2,'2501','AC. ANTI MELANOCITOS','8',NULL,NULL,NULL,NULL,NULL,1),
(99,1,'2116','Ac. ANTI MEMBRANA BASAL GLOMERULAR','15',NULL,NULL,NULL,NULL,NULL,1),
(100,1,'436','AC. ANTI MITOCONDRIA','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(101,2,'2795','AC. ANTI MUSCULO ESTRIADO','5',NULL,NULL,NULL,NULL,NULL,1),
(102,2,'4514','Ac. Anti MusK (tirosina quinasa muscular)','15','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(103,2,'2473','AC. ANTI MYCOBACTERIUM TUBERCULOSIS IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(104,2,'481','AC. ANTI MYCOPLASMA PNEUMONIAE  IgM','7',NULL,NULL,NULL,NULL,NULL,1),
(105,2,'480','AC. ANTI MYCOPLASMA PNEUMONIAE IgG','8',NULL,NULL,NULL,NULL,NULL,1),
(106,1,'467','AC. ANTI MYCOPLASMA PNEUMONIAE IgG e IgM','8',NULL,NULL,NULL,NULL,NULL,1),
(107,1,'498','AC. ANTI NUCLEARES (ANAS CUANTITATIVO)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(108,8,'4731','AC. ANTI NUCLEARES DIFERENCIADO','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(109,2,'2119','Ac. ANTI NUCLEOSOMAS','5',NULL,NULL,NULL,NULL,NULL,1),
(110,2,'504','AC. ANTI PAROTIDITIS  (PARAMIXOVIRUS)','8',NULL,NULL,NULL,NULL,NULL,1),
(111,2,'2865','AC. ANTI PAROTIDITIS IgG','8',NULL,NULL,NULL,NULL,NULL,1),
(112,2,'2603','AC. ANTI PAROTIDITIS IgM','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(113,2,'1076','AC. ANTI PARVOVIRUS B19 (IgG, IgM)','10',NULL,NULL,NULL,NULL,NULL,1),
(114,6,'2035','AC. ANTI PEPTIDO CICLICO CITRULINADO (CCP)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(115,6,'425','Ac. ANTI PEROXIDASA TIROIDEA (TPOAb)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(116,2,'582','AC. ANTI PLAQUETARIOS','2',NULL,NULL,NULL,NULL,NULL,1),
(117,6,'2569','AC. ANTI RECEPTOR DE TSH (TRAb)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(118,9,'2850','AC. ANTI RNA POLIMERASA III','20','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(119,1,'531','AC. ANTI RUBEOLA IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(120,1,'542','AC. ANTI RUBEOLA IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(121,2,'553','Ac. Anti SARAMPION (IgG, IgM)','8',NULL,NULL,NULL,NULL,NULL,1),
(122,2,'1063','AC. ANTI SARAMPION IgG','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(123,2,'1064','AC. ANTI SARAMPION IgM','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(124,1,'574','Ac. ANTI SMITH (SM)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(125,6,'599','Ac. ANTI TIROGLOBULINA (TgAb)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(126,6,'2052','AC. ANTI TIROIDEOS (Tiroglobulina y Peroxidasa)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(127,6,'3005','AC. ANTI TIROIDEOS II (TgAb, TPOAb, TRAb)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(128,2,'2851','AC. ANTI TOPOISOMERASA (scl-70)','25','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(129,1,'603','AC. ANTI TOXOPLASMA GONDII  IgG','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(130,1,'604','AC. ANTI TOXOPLASMA GONDII  IgM','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(131,1,'2829','AC. ANTI TRYPANOSOMA CRUZI IgG','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(132,2,'4676','Ac. ANTI TRYPANOSOMA CRUZI IgM','18','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(133,2,'606','AC. ANTI VARICELA IgG, IgM','7',NULL,NULL,NULL,NULL,NULL,1),
(134,6,'2838','Ac. ANTI VIH-1/VIH-2  y/o  Ag. VIH','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(135,1,'2841','AC. ANTI ZIKA IgG, IgM','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(136,2,'607','AC. AVIARIOS','8',NULL,NULL,NULL,NULL,NULL,1),
(137,2,'2591','AC. CELULAS PARIETALES','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(138,1,'1253','AC. CORE IgG VIRUS B DE HEPATITIS','6','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(139,2,'1476','AC. CORE IgM VIRUS B DE HEPATITIS','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(140,2,'125','AC. e VIRUS B DE HEPATITIS','2',NULL,NULL,NULL,NULL,NULL,1),
(141,1,'2970','Ac. FLUORESCENTES TREPONEMA  (FTA-Abs)','6','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(142,2,'2717','AC. GOODPASTURE','5','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(143,2,'2595','AC. GRANULOCITOS','2',NULL,NULL,NULL,NULL,NULL,1),
(144,1,'2596','AC. HERPES 1 y 2  (IgG, IgM)','4',NULL,NULL,NULL,NULL,NULL,1),
(145,1,'608','AC. HETEROFILOS','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(146,2,'2598','AC. HTLV 1+2','5',NULL,NULL,NULL,NULL,NULL,1),
(147,2,'4870','Ac. IgG  anti receptor de fosfolipasa A2','19',NULL,NULL,NULL,NULL,NULL,1),
(148,2,'2599','AC. IgG ADAMTS-13','8',NULL,NULL,NULL,NULL,NULL,1),
(149,1,'304','AC. IgG ANTI BRUCELLA (2 MERCAPTOETANOL)','7',NULL,NULL,NULL,NULL,NULL,1),
(150,1,'4340','Ac. IgG Neuromielitis óptica (Aquaporina-4)','26',NULL,NULL,NULL,NULL,NULL,1),
(151,2,'2600','AC. LISTERIA (IgE)','20',NULL,NULL,NULL,NULL,NULL,1),
(152,2,'1180','AC. MIELINA','7',NULL,NULL,NULL,NULL,NULL,1),
(153,2,'2586','AC. PROTEINA P-RIBOSOMAL','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(154,2,'1848','AC. REC. ACETILCOLINA (anti-AChR)','13','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(155,1,'2604','AC. RUBEOLA (IgG, IgM)','4',NULL,NULL,NULL,NULL,NULL,1),
(156,2,'1255','AC. s  VIRUS B DE HEPATITIS','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(157,2,'2605','AC. SACCHAROMYCES CEREVISIAE IgA','8',NULL,NULL,NULL,NULL,NULL,1),
(158,2,'2606','AC. SACCHAROMYCES CEREVISIAE IgG','8',NULL,NULL,NULL,NULL,NULL,1),
(159,2,'602','AC. TOXOCARA CANIS','8',NULL,NULL,NULL,NULL,NULL,1),
(160,1,'2607','AC. TOXOPLASMA GONDII (IgG, IgM)','4',NULL,NULL,NULL,NULL,NULL,1),
(161,2,'2112','AC. VIRUS EPSTEIN-BARR','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(162,6,'302','AC. vs  BRUCELLA (ROSA DE BENGALA)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(163,8,'1187','ACETAMINOFEN','8',NULL,NULL,NULL,NULL,NULL,1),
(164,1,'2792','ACETONA EN ORINA','8',NULL,NULL,NULL,NULL,NULL,1),
(165,1,'2791','ACETONA EN SANGRE','8',NULL,NULL,NULL,NULL,NULL,1),
(166,2,'2269','Ácido ascórbico (Vitamina C)','12','Plasma heparina','Tubo verde',NULL,NULL,NULL,1),
(167,2,'2609','ACIDO CITRICO EN SEMEN','2','Semen','Frasco esteril',NULL,NULL,NULL,1),
(168,2,'338','ACIDO DELTA AMINO LEVULINICO','6',NULL,NULL,NULL,NULL,NULL,1),
(169,2,'2611','ACIDO FENIL MERCAPTOPURICO','20',NULL,NULL,NULL,NULL,NULL,1),
(170,1,'424','ACIDO FOLICO (FOLATOS)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(171,2,'1190','ACIDO FOLICO INTRAERITROCITARIO','7','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(172,1,'2612','Ácido hipúrico en orina (Tolueno)','9','Orina','F',NULL,NULL,NULL,1),
(173,5,'2877','ACIDO HOMOVANILICO (ORINA 24 HORAS)','15','Orina de 24 hrs.','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(174,1,'2616','Ácido metil hipúrico (Xileno)','14','Orina','Frasco esteril',NULL,NULL,NULL,1),
(175,1,'4307','ACIDO METILMALONICO','12',NULL,NULL,NULL,NULL,NULL,1),
(176,2,'2125','ACIDO MICOFENOLICO','25',NULL,NULL,NULL,NULL,NULL,1),
(177,2,'2577','ACIDO PERYODICO DE SCHIFF','1','Frotis','Laminilla',NULL,NULL,NULL,1),
(178,4,'2567','ACIDO URICO EN ORINA AL AZAR','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(179,4,'1703','ACIDO URICO EN ORINA DE 24 HORAS','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(180,10,'1652','Acido úrico en orina de 24 horas','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(181,4,'516','ACIDO URICO SERICO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(182,1,'621','ACIDO VALPROICO (VALPROATO)','3','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(183,2,'610','ACIDO VANILLINMANDELICO','5',NULL,NULL,NULL,NULL,NULL,1),
(184,1,'2960','ACIDOS BILIARES TOTALES Y FRACCIONADOS','15','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(185,1,'1193','ACIDOS GRASOS LIBRES EN SUERO','8',NULL,NULL,NULL,NULL,NULL,1),
(186,2,'2614','ACTIVIDAD ADAMTS-13','8',NULL,NULL,NULL,NULL,NULL,1),
(187,2,'2694','ACTIVIDAD DEL FIBRINOGENO','5',NULL,NULL,NULL,NULL,NULL,1),
(188,11,'568','ACTIVIDAD TRIPTICA','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(189,12,'1982','ADENOIDES','8','Pieza quirúrgica','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(190,1,'2542','ADENOSIN DEAMINASA (ADA)','4','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(191,6,'4764','ADENOVIRUS.','0','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(192,2,'2425','ADRENALINA EN ORINA','7','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(193,2,'2915','Ag. CYFRA-21','5',NULL,NULL,NULL,NULL,NULL,1),
(194,4,'130','Ag. DE SUPERF. HEPATITIS B (Ag. Australia)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(195,2,'2621','AG. e VIRUS B DE HEPATITIS','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(196,2,'2622','AG. HLA DQ','18','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(197,2,'2623','AG. HLA DR','18','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(198,2,'2624','AG. HLA-A y B','9','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(199,2,'143','AG. HLA-B27','2','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(200,13,'2331','AGUA PREPARADA NOM-093-SSA1-1994','7','AGUA','Frasco especial esteril',NULL,NULL,NULL,1),
(201,13,'2332','AGUA Y HIELO POTABLE QUE SE EXPENDEN EN ESTABLECIMIENTOS PUBLICOS NOM-093-SSA1-1994','7','AGUA','Frasco especial esteril',NULL,NULL,NULL,1),
(202,4,'278','ALANINA AMINO TRANSFERASA (TGP/ALT)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(203,4,'24','ALBUMINA SERICA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(204,2,'46','ALCOHOL ETILICO EN ORINA','4',NULL,NULL,NULL,NULL,NULL,1),
(205,13,'59','ALCOHOL ETILICO EN SANGRE','2','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(206,1,'70','ALDOLASA','17','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(207,1,'81','ALDOSTERONA','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(208,2,'479','ALDOSTERONA EN ORINA','7',NULL,NULL,NULL,NULL,NULL,1),
(209,2,'1006','ALFA 1 ANTITRIPSINA','6',NULL,NULL,NULL,NULL,NULL,1),
(210,2,'2630','ALFA 2 ANTIPLASMINA','3',NULL,NULL,NULL,NULL,NULL,1),
(211,2,'2631','ALFA 2 MACROGLOBULINA','2',NULL,NULL,NULL,NULL,NULL,1),
(212,6,'105','ALFAFETOPROTEINA (AFP)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(213,13,'2333','ALIMENTO COCIDO NOM-093-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(214,13,'2334','ALIMENTO CRUDO NOM-093-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(215,13,'2335','ALIMENTO MAYONESAS Y ADEREZOS NOM-093-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(216,13,'2633','ALIMENTO MIXTO','5','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(217,13,'2336','ALIMENTO POSTRE LACTEO NOM-093-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(218,13,'2338','ALIMENTO POSTRE LACTEO NOM-093-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(219,13,'2339','ALIMENTO PRODUCTOS CARNICOS, TROCEADOS, CURADOS Y MADUROS NOM-122-SSA1-1995','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(220,13,'2340','ALIMENTO PRODUCTOS CARNICOS, TROCEADOS, CURADOS Y MADUROS NOM-145-SSA1-1995','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(221,13,'2341','ALIMENTO QUESOS FRESCOS, MADUROS, Y PROCESADOS NOM-121-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(222,13,'2343','ALIMENTOS CRUSTACEOS FRESCOS, REFRIGERADOS Y CONGELADOS NOM-029-SSA1-1993','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(223,13,'2342','ALIMENTOS HELADOS NOM-093-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(224,13,'2344','ALIMENTOS PESCADOS FRESCOS, REFRIGERADOS Y CONGELADOS NOM- 027-SSA1-1993','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(225,13,'2346','ALIMENTOS PRODUCTOS CARNICOS CRUDOS NOM-194-SSA1-2004','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(226,2,'1199','ALUMINIO EN ORINA','17',NULL,NULL,NULL,NULL,NULL,1),
(227,2,'1198','ALUMINIO EN SUERO','17',NULL,NULL,NULL,NULL,NULL,1),
(228,14,'118','AMIBA EN FRESCO (BAF)','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(229,12,'2868','AMIGDALAS','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(230,4,'2878','AMILASA EN LIQUIDOS ORGANICOS','0',NULL,NULL,NULL,NULL,NULL,1),
(231,4,'140','AMILASA EN ORINA','2',NULL,NULL,NULL,NULL,NULL,1),
(232,4,'129','AMILASA EN SUERO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(233,13,'475','ANALISIS FISICO-QUIMICO DE AGUA POTABLE (SALES DISUELTAS)','5','agua','Frasco especial esteril',NULL,NULL,NULL,1),
(234,13,'2330','ANALISIS MICROBIOLOGICO DE AGUA','6','agua','Frasco especial esteril',NULL,NULL,NULL,1),
(235,1,'163','ANDROSTENEDIONA','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(236,12,'4300','ANEXO (BIOSIA)',NULL,'Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(237,10,'174','ANFETAMINAS (AMP)','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(238,2,'1204','ANGIOTESINA','7','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(239,12,'2849','ANO','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(240,11,'2357','ANTIBIOGRAMA','2','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(241,11,'341','ANTIBIOGRAMA MIC','5','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(242,2,'4856','ANTIBIOGRAMA TB (Mycobacterium tuberculosis)',NULL,'Medio especial','Cepa',NULL,NULL,NULL,1),
(243,1,'298','ANTICOAGULANTE LUPICO (CIRCULANTES)','4','Plasma/Citrato','Toma directa',NULL,NULL,NULL,1),
(244,1,'4878','Anticuerpo inmunohistoquimico HER2/cebB2','15',NULL,NULL,NULL,NULL,NULL,1),
(245,1,'4879','Anticuerpo Inmunohistoquímico Ki67','15',NULL,NULL,NULL,NULL,NULL,1),
(246,1,'4881','Anticuerpo receptor de estrógenos','15',NULL,NULL,NULL,NULL,NULL,1),
(247,1,'4880','Anticuerpo receptor de progesterona','15',NULL,NULL,NULL,NULL,NULL,1),
(248,2,'4652','Anticuerpos anti Plasmodium falciparum','0',NULL,NULL,NULL,NULL,NULL,1),
(249,5,'2419','ANTICUERPOS ANTI PM/SCL-100','5',NULL,NULL,NULL,NULL,NULL,1),
(250,2,'4631','ANTICUERPOS ANTI -RECEPTOR NMDA','0',NULL,NULL,NULL,NULL,NULL,1),
(251,2,'2543','ANTICUERPOS ANTI SSA/Ro y SSB/La','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(252,2,'4681','Anticuerpos contra antígenos hígado-páncreas(M2, LKM1, LC1, SLA, Sp100/PML, gp210)','16','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(253,6,'4193','ANTICUERPOS SARS-CoV-2 (IgM/IgG)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(254,6,'4607','Anticuerpos Totales contra T. pallidum','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(255,6,'609','ANTIESTREPTOLISINAS (AEL/ASTO)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(256,6,'633','ANTIGENO  CA 19-9','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(257,2,'564','ANTIGENO  CA 27-29','10','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(258,6,'631','ANTIGENO CA 125 (OVARIO)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(259,6,'632','ANTIGENO CA 15-3 (MAMA)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(260,2,'1205','ANTIGENO CA 72-4','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(261,2,'4614','ANTIGENO CA-50','16','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(262,6,'611','ANTIGENO CARCINOEMBRIONARIO (CEA)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(263,1,'1165','ANTIGENO CRYPTOCOCCUS NEOFORMANS EN LCR','8','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(264,11,'155','ANTIGENO DE CHLAMYDIA TRACHOMATIS','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(265,2,'3003','ANTIGENO DE GIARDIA EN HECES','3','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(266,14,'577','ANTIGENO DE H. PYLORI EN HECES','0','Heces','Frasco para heces',NULL,NULL,NULL,1),
(267,2,'1132','ANTIGENO DE VON WILLEBRAND','8',NULL,NULL,NULL,NULL,NULL,1),
(268,1,'4349','ANTIGENO HE4','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(269,4,'2138','ANTIGENO P24 DE HIV 1','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(270,6,'612','ANTIGENO PROSTATICO ESPECIFICO (PSA)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(271,6,'311','ANTIGENO PROSTATICO LIBRE (PSA LIBRE)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(272,1,'478','ANTIGENO RNP','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(273,2,'613','ANTITROMBINA III','8',NULL,NULL,NULL,NULL,NULL,1),
(274,12,'16','APENDICE CECAL','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(275,4,'614','APOLIPOPROTEINA A1','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(276,4,'702','APOLIPOPROTEINA B','2','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(277,4,'703','APOLIPOPROTEINAS A1 y B','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(278,2,'615','ARSENICO EN ORINA','14',NULL,NULL,NULL,NULL,NULL,1),
(279,2,'2140','ARSENICO EN SUERO','16',NULL,NULL,NULL,NULL,NULL,1),
(280,4,'277','ASPARTATO AMINO TRANSFERASA(TGO/AST)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(281,5,'4297','AVIDEZ DE ANTICUERPOS IgG ANTI CITOMEGALOVIRUS','10','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(282,14,'1884','AZUCARES REDUCTORES','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(283,10,'4887','AZUCARES REDUCTORES EN ORINA','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(284,12,'2657','BAAF DE MAMA (LAMINILLAS)','8','Tejido','Laminillas',NULL,NULL,NULL,1),
(285,12,'4238','BAAF DE TRACTO RESPIRATORIO','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(286,12,'445','BAAF TIROIDES','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(287,11,'618','BACILOSCOPIA 1 MUESTRA (BAAR)','1',NULL,NULL,NULL,NULL,NULL,1),
(288,11,'617','BACILOSCOPIA 10 MUESTRAS (BAAR)','12','Espectoración 1 mta.','Frasco esteril',NULL,NULL,NULL,1),
(289,11,'4116','BACILOSCOPIA 12 MUESTRAS (BAAR)','13','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(290,11,'619','BACILOSCOPIA 2M (BAAR)','3',NULL,NULL,NULL,NULL,NULL,1),
(291,11,'620','BACILOSCOPIA 3M (BAAR)','4',NULL,NULL,NULL,NULL,NULL,1),
(292,11,'2575','BACILOSCOPIA 4 MUESTRAS (BAAR)','5','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(293,11,'622','BACILOSCOPIA 5M (BAAR)','6',NULL,NULL,NULL,NULL,NULL,1),
(294,2,'1208','BANDAS OLIGOCLONALES LCR','25','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(295,11,'301','BARBITURICOS (ORINA)','0',NULL,NULL,NULL,NULL,NULL,1),
(296,12,'2660','BAZO','0','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(297,2,'54','BETA 2 MICROGLOBULINA (orina)','2',NULL,NULL,NULL,NULL,NULL,1),
(298,2,'624','BETA 2 MICROGLOBULINA EN SUERO','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(299,5,'4147','BETA 2 TRANSFERRINA','6','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(300,5,'2961','BETA D-GLUCANO','10','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(301,1,'4886','Beta hidroxibutirato','18','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(302,2,'430','BICARBONATO EN ORINA AL AZAR','3',NULL,NULL,NULL,NULL,NULL,1),
(303,4,'4772','Bicarbonato y CO2','0','Plasma heparina','Tubo verde',NULL,NULL,NULL,1),
(304,4,'625','BILIRRUBINA TOTAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(305,4,'2120','Bilirrubina Total','2','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(306,12,'1963','BIOPSIA CHICA','7','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(307,12,'4237','BIOPSIA DE CAVIDAD ORAL','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(308,12,'4249','BIOPSIA DE CEREBRO','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(309,12,'2666','BIOPSIA DE ENDOMETRIO (LUI)','8','Biopsia de tejido','Frasco esteril',NULL,NULL,NULL,1),
(310,12,'2659','BIOPSIA DE MAMA (menora 2 cm)','0','Tejido','Frasco patologia',NULL,NULL,NULL,1),
(311,12,'2656','BIOPSIA DE OIDO','8','Tejido','Frasco patologia',NULL,NULL,NULL,1),
(312,12,'4248','BIOPSIA DE OJO','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(313,12,'4241','BIOPSIA DE PANCREAS','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(314,12,'4299','BIOPSIA DE PIEL','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(315,12,'1979','BIOPSIA DE PROSTATA TRANSRECTAL','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(316,12,'4234','BIOPSIA DE RIÑON','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(317,12,'4199','BIOPSIA DE TEJIDO OSEO','10','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(318,12,'4247','BIOPSIA DE TEJIDOS BLANDOS','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(319,12,'451','BIOPSIA DE TIROIDES','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(320,12,'4243','BIOPSIA DE TRACTO RESPIRATORIO','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(321,12,'4175','BIOPSIA GLANDULA SALIVAL','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(322,1,'4768','BIOPSIA PIEZAS ESPECIALES','14',NULL,NULL,NULL,NULL,NULL,1),
(323,12,'4250','BIOPSIA VULVAR','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(324,2,'4710','Bordetella (B.pertussis, B.parapertussis) DNA, exudado','15',NULL,NULL,NULL,NULL,NULL,1),
(325,15,'4636','Búsqueda de Precipitados de Hemoglobina H','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(326,14,'2049','BUSQUEDA DE TRYPANOSOMA CRUZI','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(327,14,'2818','BUSQUEDA DE: Sarcoptes scabiei (Sarna)','0','Frotis','Toma especial',NULL,NULL,NULL,1),
(328,14,'412','BUSQUEDA: AMIBAS DE VIDA LIBRE','0',NULL,NULL,NULL,NULL,NULL,1),
(329,1,'306','Ca++ (Calcio ionizado)','4',NULL,NULL,NULL,NULL,NULL,1),
(330,2,'1212','CADENAS KAPPA y LAMBDA LIBRES EN ORINA','4','Orina','Frasco esteril',NULL,NULL,NULL,1),
(331,2,'1893','CADENAS LIGERAS KAPPA/LAMBDA LIBRES EN SUERO','6','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(332,2,'2658','CADMIO EN SANGRE','18','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(333,4,'2153','CALCIO EN ORINA AL AZAR','0',NULL,NULL,NULL,NULL,NULL,1),
(334,4,'635','CALCIO EN ORINA DE 24 HORAS','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(335,4,'634','CALCIO SERICO (Ca)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(336,1,'3','CALCITONINA','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(337,2,'4775','CALCULO BILIAR (FISICOQUIMICO)','10',NULL,NULL,NULL,NULL,NULL,1),
(338,2,'4','CALCULO RENAL (FISICOQUIMICO)','4','Cálculo','frasco',NULL,NULL,NULL,1),
(339,14,'4184','CALPROTECTINA','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(340,6,'7','CAPTACION TIROIDEA  (T-Uptake)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(341,2,'10','CARBAMAZEPINA','3',NULL,NULL,NULL,NULL,NULL,1),
(342,2,'1215','CARBOXIHEMOGLOBINA','10','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(343,1,'2981','CARGA VIRAL CMV','12','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(344,1,'2144','CARGA VIRAL DE HBV','7','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(345,1,'579','CARGA VIRAL DE HEPATITIS C (HCV)','6','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(346,2,'464','CARGA VIRAL DE VIH-1','13','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(347,2,'1104','CARIOTIPO (MUESTRAS DIVERSAS)','25',NULL,NULL,NULL,NULL,NULL,1),
(348,2,'183','CARIOTIPO EN SANGRE','30','Sangre total heparina',NULL,NULL,NULL,NULL,1),
(349,2,'1216','CAROTENOS','2',NULL,NULL,NULL,NULL,NULL,1),
(350,6,'4876','CEA (Ag. Carcinoembrionario) líquido peritoneal','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(351,2,'2066','CELULAS CD3/CD4/CD8','10','Sangre total','Tubo lila',NULL,NULL,NULL,1),
(352,15,'14','CELULAS LE','0','Tubo rojo s/Centrifugar','Tubo rojo',NULL,NULL,NULL,1),
(353,2,'1217','CERULOPLASMINA SUERO','3',NULL,NULL,NULL,NULL,NULL,1),
(354,12,'187','CERVIX (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(355,12,'6','CERVIX (CONO)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(356,18,'2931','CHECK UP GENERAL','0',NULL,NULL,NULL,NULL,NULL,1),
(357,18,'2932','CHECK UP GENERAL + EKG','0',NULL,NULL,NULL,NULL,NULL,1),
(358,18,'150','CHEK UP MEDICO FEMENINO','0',NULL,NULL,NULL,NULL,NULL,1),
(359,18,'4107','CHEK UP MEDICO MASCULINO','0',NULL,NULL,NULL,NULL,NULL,1),
(360,5,'2145','CIANURO','9','Sangre total heparina',NULL,NULL,NULL,NULL,1),
(361,4,'2387','CISTATINA "C"','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(362,11,'2088','CITOLOGIA DE LIQUIDO (TINCION DE GRAM)','0',NULL,NULL,NULL,NULL,NULL,1),
(363,14,'1875','CITOLOGIA DE MOCO FECAL','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(364,12,'583','CITOLOGIA EN LIQUIDOS CORPORALES (ASCITIS, PLEURAL, ORINA, EXPECTORACION)','8','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(365,15,'308','CITOLOGIA MEDULA OSEA','3','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(366,12,'1431','CITOLOGIA URETRAL  (Papanicolaou)','8','Frotis','Laminilla',NULL,NULL,NULL,1),
(367,12,'2554','CITOLOGIA/PAPANICOLAOU EN LIQUIDOS ORGANICOS','8',NULL,NULL,NULL,NULL,NULL,1),
(368,15,'692','CITOMETRIA HEMATICA (BHC)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(369,15,'2463','CITOMETRIA HEMATICA DATOS DEL EQUIPO','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(370,15,'2147','CITOMETRIA HEMATICA DE VERIFICACION','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(371,15,'17','CITOQUIMICO DE LIQUIDO BRONQUIAL','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(372,15,'18','CITOQUIMICO DE LIQUIDO CEFALORRAQUIDEO','0','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(373,15,'19','CITOQUIMICO DE LIQUIDO DE ASCITIS O PERITONEAL','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(374,15,'20','CITOQUIMICO DE LIQUIDO DE DIALISIS','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(375,15,'2465','CITOQUIMICO DE LIQUIDO DE:','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(376,15,'2456','CITOQUIMICO DE LIQUIDO PERICARDICO','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(377,17,'2091','CITOQUIMICO DE LIQUIDO PLEURAL','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(378,15,'22','CITOQUIMICO DE LIQUIDO SINOVIAL','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(379,2,'2148','CITRATO EN ORINA','2','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(380,4,'26','CLORO EN ORINA','0',NULL,NULL,NULL,NULL,NULL,1),
(381,4,'25','CLORO SERICO (Cl)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(382,2,'4596','CLOSTRIDIUM DIFFICILE (GDH, TOX-A, TOX-B)','8','Heces','Frasco para heces',NULL,NULL,NULL,1),
(383,2,'1940','CLOSTRIDIUM DIFFICILE ANTIGENO-GDH','8','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(384,2,'28','COAGLUTINACION DE LIQUIDO CEFALORRAQUIDEO','3','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(385,2,'431','COBRE EN ORINA','12','Orina','Frasco esteril',NULL,NULL,NULL,1),
(386,2,'29','COBRE SERICO','12',NULL,NULL,NULL,NULL,NULL,1),
(387,10,'30','COCAINA (COC)','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(388,4,'2888','COCIENTE ALBUMINA/CREATININA (RAC/CACu)','0','Orina (Primera micción)','Frasco esteril',NULL,NULL,NULL,1),
(389,4,'31','COLESTEROL DE ALTA DENSIDAD (HDL)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(390,4,'32','COLESTEROL DE BAJA DENSIDAD (LDL)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(391,4,'696','COLESTEROL DE MUY BAJA DENSIDAD (VLDL)','0',NULL,NULL,NULL,NULL,NULL,1),
(392,4,'34','COLESTEROL TOTAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(393,4,'1913','COLESTEROL Y SUS DENSIDADES','0',NULL,NULL,NULL,NULL,NULL,1),
(394,4,'36','COLINESTERASA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(395,12,'237','COLON (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(396,2,'4851','Complemento C-1 esterasa inhibidor','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(397,5,'2025','COMPLEMENTO C1q','15','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(398,5,'2152','COMPLEMENTO C2','15','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(399,1,'38','COMPLEMENTO C-3','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(400,1,'39','COMPLEMENTO C-4','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(401,2,'2154','COMPLEMENTO C5','8',NULL,NULL,NULL,NULL,NULL,1),
(402,1,'40','COMPLEMENTO HEMOLITICO 50% (CH50)','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(403,12,'243','CONDUCTOS DEFERENTES','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(404,15,'4374','CONTEO MANUAL DE PLAQUETAS','0','Sangre total','Tubo lila',NULL,NULL,NULL,1),
(405,18,'2069','CONTROL DIABETICO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(406,18,'1888','CONTROL ESCOLAR GUARDERIA','5',NULL,NULL,NULL,NULL,NULL,1),
(407,18,'1614','CONTROL ESCOLAR SECUNDARIA','2',NULL,NULL,NULL,NULL,NULL,1),
(408,4,'1304','CONTROL PRENATAL','0',NULL,NULL,NULL,NULL,NULL,1),
(409,15,'42','COOMBS INDIRECTO (Ac anti Rh sericos)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(410,14,'1659','COPROLOGICO COMPLETO','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(411,14,'4554','COPROLOGICO ESPECIAL','0','Heces','Frasco para heces',NULL,NULL,NULL,1),
(412,14,'43','COPROPARASITOSCOPICO 1M (CPS)','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(413,14,'2051','COPROPARASITOSCOPICO 2M','2','Heces 2 muestra','Frasco para heces',NULL,NULL,NULL,1),
(414,14,'44','COPROPARASITOSCOPICO 3M (CPS)','3','Heces 3 muestra','Frasco para heces',NULL,NULL,NULL,1),
(415,2,'1220','COPROPORFIRINAS EN ORINA','5',NULL,NULL,NULL,NULL,NULL,1),
(416,5,'4125','CORTISOL EN SALIVA','19','SALIVA','Frasco esteril',NULL,NULL,NULL,1),
(417,2,'4117','CORTISOL LIBRE EN ORINA 24 HORAS','8',NULL,NULL,NULL,NULL,NULL,1),
(418,6,'1113','CORTISOL PLASMATICO MATUTINO BASAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(419,4,'1114','CORTISOL PLASMATICO VESPERTINO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(420,6,'47','CORTISOL URINARIO','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(421,12,'4732','COSTO ADICIONAL: MUESTRA DE PATOLOGIA','8',NULL,NULL,NULL,NULL,NULL,1),
(422,4,'48','CREATINFOSFOQUINASA (CPK)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(423,4,'49','CREATINFOSFOQUINASA FRACCION MB (CKMB)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(424,2,'1222','CREATINFOSFOQUINASA ISOENZIMAS','7',NULL,NULL,NULL,NULL,NULL,1),
(425,4,'2756','CREATININA EN ORINA AL AZAR','0','Orina al azar','Pa',NULL,NULL,NULL,1),
(426,4,'2828','CREATININA EN ORINA DE 24 HRS','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(427,4,'50','CREATININA SERICA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(428,15,'1223','CRIOAGLUTININAS','1','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(429,15,'55','CRIOGLOBULINAS','0','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(430,14,'2134','CRIPTOCOCCUS NEOFORMANS EXAMEN DIRECTO','0','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(431,2,'4104','Criptosporidium EN HECES','2','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(432,10,'1764','CRISTALOGRAFIA','0','Líquido biológico','Laminilla',NULL,NULL,NULL,1),
(433,4,'4135','CRITERIOS LIGHT (Gradientes Líquido PLEURAL)','0',NULL,NULL,NULL,NULL,NULL,1),
(434,2,'439','CROMO (ORINA ó SANGRE)','12',NULL,NULL,NULL,NULL,NULL,1),
(435,2,'4781','CROMOGRANINA A','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(436,2,'2677','CROMOSOMA FILADELFIA p190 (LAL)','6','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(437,2,'2678','CROMOSOMA FILADELFIA p210 (LGC)','6','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(438,2,'2043','CROMOSOMA FILADELFIA POR FISH','7','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(439,2,'2680','CROMOSOMA X FRAGIL','17',NULL,NULL,NULL,NULL,NULL,1),
(440,2,'458','C-TELOPEPTIDOS','12',NULL,NULL,NULL,NULL,NULL,1),
(441,19,'2491','CUADRUPLE MARCADOR','16',NULL,NULL,NULL,NULL,NULL,1),
(442,2,'4757','CUANTIFICACION DE CELULAS CD19 Y CD20','4','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(443,7,'57','CUANTIFICACION DE HGC EN ORINA DE 24 HRS','0','Orina de 24 hrs.','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(444,13,'2347','CUENTA DE BACTERIAS COLIFORMES FECALES NOM-112-SSA-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(445,13,'2348','CUENTA DE BACTERIAS COLIFORMES TOTALES NOM-113-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(446,13,'2349','CUENTA DE BACTERIAS MESOFILICAS AEROBIAS NOM-092-SSA-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(447,13,'2350','CUENTA DE HONGOS FILAMENTOSOS Y LEVADURIFORMES NOM-111-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(448,13,'2351','CUENTA DE STAPHYLOCOCCUS AUREUS NOM-115-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(449,11,'2309','CULTIVO DE CATETER','5','Catéter','frasco esteril',NULL,NULL,NULL,1),
(450,11,'348','CULTIVO DE EXPECTORACION (ESPUTO)','5','Esputo','Frasco esteril',NULL,NULL,NULL,1),
(451,11,'349','CULTIVO DE EXUDADO CERVICO-VAGINAL','5','Exudado vaginal','Kit especial',NULL,NULL,NULL,1),
(452,11,'351','CULTIVO DE EXUDADO CONJUNTIVAL','5','Exudado','kit cultivo',NULL,NULL,NULL,1),
(453,11,'353','CULTIVO DE EXUDADO FARINGEO (EXFAR)','4','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(454,11,'352','CULTIVO DE EXUDADO NASAL','5','Exudado','kit cultivo',NULL,NULL,NULL,1),
(455,11,'356','CULTIVO DE HECES (COPROCULTIVO)','5','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(456,11,'2295','CULTIVO DE LESION','7','Exudado','kit cultivo',NULL,NULL,NULL,1),
(457,11,'2004','CULTIVO DE MANOS (RASPADO DE MANOS, UÑAS)','4','Raspado de manos','Toma directa',NULL,NULL,NULL,1),
(458,2,'4207','CULTIVO DE MYCOBACTERIUM TUBERCULOSIS','45',NULL,NULL,NULL,NULL,NULL,1),
(459,11,'367','CULTIVO DE ORINA (UROCULTIVO)','5','Orina','Frasco esteril',NULL,NULL,NULL,1),
(460,11,'4650','CULTIVO DE ORINA (UROCULTIVO) ESPECIALIZADO','5','Orina','Frasco esteril',NULL,NULL,NULL,1),
(461,11,'4626','CULTIVO DE ORINA AMPLIADO','5',NULL,NULL,NULL,NULL,NULL,1),
(462,11,'373','CULTIVO DE SEMEN (ESPERMOCULTIVO)','5','Semen','Frasco esteril',NULL,NULL,NULL,1),
(463,11,'4124','CULTIVO DE:','5',NULL,NULL,NULL,NULL,NULL,1),
(464,11,'375','CULTIVO DE: CON ANTIBIOGRAMA','4',NULL,NULL,NULL,NULL,NULL,1),
(465,11,'2683','CULTIVO ESPECIAL  CON ANTIBIOGRAMA','6',NULL,NULL,NULL,NULL,NULL,1),
(466,11,'376','CULTIVO MICOLOGICO  (HONGOS PATOGENOS)','60','Escamas','Frasco esteril',NULL,NULL,NULL,1),
(467,4,'2329','CULTIVO MICROBIOLOGICO DE AGUA POTABLE','7','agua','Frasco especial esteril',NULL,NULL,NULL,1),
(468,11,'371','CULTIVO OTICO','5','Exudado','kit cultivo',NULL,NULL,NULL,1),
(469,11,'4512','CULTIVO URETRAL ESPECIAL','0','Exudado','kit cultivo',NULL,NULL,NULL,1),
(470,11,'355','CULTIVO VULVAR','4','Exudado','kit cultivo',NULL,NULL,NULL,1),
(471,6,'2176','CURVA DE HORMONA DE CRECIMIENTO (Basal, Tiempo 1, Tiempo 2)','0',NULL,NULL,NULL,NULL,NULL,1),
(472,6,'4347','CURVA DE HORMONA DE CRECIMIENTO 5M (Basal, 30, 60, 90, 120 min)','0',NULL,NULL,NULL,NULL,NULL,1),
(473,6,'2531','CURVA DE INSULINA 3 DETERMINACIONES','0',NULL,NULL,NULL,NULL,NULL,1),
(474,7,'2837','CURVA DE INSULINA 4 DETERMINACIONES','0',NULL,NULL,NULL,NULL,NULL,1),
(475,4,'4621','CURVA DE TOLERANCIA 100 gr  (Embarazo)','0',NULL,NULL,NULL,NULL,NULL,1),
(476,4,'58','CURVA DE TOLERANCIA 75 gr  (Embarazo)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(477,4,'4770','CURVA DE TOLERANCIA 75 gr (Embarazo) 4M','0',NULL,NULL,NULL,NULL,NULL,1),
(478,4,'1303','CURVA DE TOLERANCIA A LA GLUCOSA ( 7 Muestras 1/2 Hora)','0',NULL,NULL,NULL,NULL,NULL,1),
(479,4,'2904','CURVA DE TOLERANCIA A LA GLUCOSA (3 m)','0',NULL,NULL,NULL,NULL,NULL,1),
(480,4,'1603','CURVA DE TOLERANCIA A LA GLUCOSA (4 m)','0',NULL,NULL,NULL,NULL,NULL,1),
(481,4,'4226','CURVA DE TOLERANCIA A LA GLUCOSA (4 m, 1/2 h)','0',NULL,NULL,NULL,NULL,NULL,1),
(482,1,'60','DEHIDROEPIANDROSTERONA (DHEA)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(483,6,'61','DEHIDROEPIANDROSTERONA SULFATO(DHEA-S)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(484,2,'4198','DENGUE POR PCR','4',NULL,NULL,NULL,NULL,NULL,1),
(485,1,'319','DEOXIPIRIDINOLINA  (PYRILINKS-D)','14',NULL,NULL,NULL,NULL,NULL,1),
(486,4,'62','DEPURACION DE CREATININA EN ORINA DE 24 HORAS','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(487,4,'4127','DEPURACION DE CREATININA ORINA 36 HORAS','0','orina 36 hrs + suero1ml','Frasco ambar',NULL,NULL,NULL,1),
(488,4,'535','DEPURACION DE UREA','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(489,2,'2690','DESAMINASA DE PORFOBILINOGENO','3','Plasma heparina','Tubo verde',NULL,NULL,NULL,1),
(490,2,'2610','DESHIDRATASA DEL ACIDO DELTA AMINO LEVULINICO','2','Sangre total heparina',NULL,NULL,NULL,NULL,1),
(491,4,'63','DESHIDROGENASA LACTICA  (DHL)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(492,4,'4728','DESHIDROGENASA LÁCTICA EN LÍQUIDO','0','Líquido biológico','fr',NULL,NULL,NULL,1),
(493,2,'2041','DETERMINACION DE FOSFOLIPIDOS','2',NULL,NULL,NULL,NULL,NULL,1),
(494,1,'64','DIAZEPAM (Valium, alboral)','15','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(495,2,'65','DIFENILHIDANTOINA (FENITOINA)','2',NULL,NULL,NULL,NULL,NULL,1),
(496,2,'66','DIGOXINA','2',NULL,NULL,NULL,NULL,NULL,1),
(497,1,'1911','DIHIDROTESTOSTERONA','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(498,6,'4197','DIMEROS D.','0','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(499,7,'2968','DOMINGO: FUNCIONAMIENTO RENAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(500,2,'1134','DOPAMINA EN ORINA','7',NULL,NULL,NULL,NULL,NULL,1),
(501,1,'4619','DOPAMINA EN PLASMA','10',NULL,NULL,NULL,NULL,NULL,1),
(502,1,'2942','ELASTASA','15','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(503,2,'67','ELECTROFORESIS DE HEMOGLOBINA (HB.  ANORMALES)','5','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(504,1,'1679','ELECTROFORESIS DE LIPOPROTEINAS','6',NULL,NULL,NULL,NULL,NULL,1),
(505,2,'532','ELECTROFORESIS DE PROTEINAS EN LCR','4','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(506,2,'562','ELECTROFORESIS DE PROTEINAS EN ORINA','4',NULL,NULL,NULL,NULL,NULL,1),
(507,2,'68','ELECTROFORESIS DE PROTEINAS EN SANGRE','3','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(508,4,'2468','ELECTROLITOS SERICOS (Na, K)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(509,4,'69','ELECTROLITOS SERICOS (Na, K, Cl)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(510,4,'1877','ELECTROLITOS SERICOS (Na, K, Cl, Ca)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(511,4,'2852','ELECTROLITOS SERICOS COMPLETOS','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(512,4,'200','ELECTROLITOS URINARIOS (3)','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(513,12,'305','ENDOMETRIO (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(514,5,'2992','ENOLASA  ESPECIFICA DE NEURONA (NSE)','10','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(515,5,'2642','ENZIMA CONVERTIDORA DE ANGIOTESINA','10','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(516,15,'73','EOSINOFILOS EN MOCO NASAL (EOMN 1 Muestra)','0','Frotis','Laminilla',NULL,NULL,NULL,1),
(517,15,'74','EOSINOFILOS EN MOCO NASAL (EOMN 3 Muestras)','3','Frotis','Laminilla',NULL,NULL,NULL,1),
(518,2,'1235','EPINEFRINA EN ORINA','7',NULL,NULL,NULL,NULL,NULL,1),
(519,12,'4111','EPIPLON','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(520,2,'539','ERITROPOYETINA (EPO)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(521,12,'4239','ESOFAGO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(522,12,'2548','ESOFAGO (BIOPSIA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(523,12,'1983','ESPECIMENES MENORES A 5 CM (LIPOMAS, FIBROMAS, MIOMAS, FIBROADENOMAS)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(524,15,'75','ESPERMATOBIOSCOPIA (SEMINOGRAMA/ESPERMOGRAMA/EBD)','0','Semen','Frasco esteril',NULL,NULL,NULL,1),
(525,19,'2808','ESTIMULACION CON ACTH','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(526,12,'342','ESTOMAGO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(527,12,'2485','ESTOMAGO (BIOPSIA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(528,6,'77','ESTRADIOL  (E 2)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(529,2,'2101','ESTRIOL LIBRE','5',NULL,NULL,NULL,NULL,NULL,1),
(530,6,'1432','ESTROGENOS TOTALES','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(531,1,'560','ESTRONA','6',NULL,NULL,NULL,NULL,NULL,1),
(532,12,'4196','ESTUDIO DE INMUNOHISTOQUIMICA','15','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(533,6,'4599','EVALUACIÓN COMPLETA DE LA TIROIDES','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(534,10,'4515','EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)','0','Orina (Primera micción)','Frasco esteril',NULL,NULL,NULL,1),
(535,10,'4714','EXAMEN GENERAL DE ORINA CUANTITATIVO','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(536,2,'2164','F5 (FACTOR V), MUTACION P. ARG534GLN (LEIDEN, R506Q)','7','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(537,2,'2699','FACTOR ANTIHEMOFILICO B (CHRISTMAS) (FACTOR IX)','2','Plasma citrato 2 ml','Tubo azul citrato',NULL,NULL,NULL,1),
(538,2,'2700','FACTOR ANTIHEMOFILICO C','2','Plasma citrato 2 ml','Tubo azul citrato',NULL,NULL,NULL,1),
(539,1,'2583','FACTOR DE NECROSIS TUMORAL ALFA','20',NULL,NULL,NULL,NULL,NULL,1),
(540,2,'4890','FACTOR DE VON WILLEBRAD ACTIVIDAD (RICO)','20',NULL,NULL,NULL,NULL,NULL,1),
(541,2,'2703','FACTOR HAGEMAN (FACTOR XII)','2',NULL,NULL,NULL,NULL,NULL,1),
(542,2,'1766','FACTOR II DE LA COAGULACION','5',NULL,NULL,NULL,NULL,NULL,1),
(543,2,'1767','FACTOR III','3','Plasma citrato 2 ml','Tubo azul citrato',NULL,NULL,NULL,1),
(544,2,'316','FACTOR IX COAGULACION','3',NULL,NULL,NULL,NULL,NULL,1),
(545,6,'85','FACTOR REUMATOIDE','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(546,4,'2927','FACTOR REUMATOIDE CUANTITATIVO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(547,4,'4276','FACTOR REUMATOIDE EN LIQUIDO SINOVIAL.','0','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(548,2,'1769','FACTOR V DE LA COAGULACION','2',NULL,NULL,NULL,NULL,NULL,1),
(549,2,'1770','FACTOR VII DE LA COAGULACION','3','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(550,2,'315','FACTOR VIII ANTIGENICO','15',NULL,NULL,NULL,NULL,NULL,1),
(551,1,'2698','FACTOR VIII DE COAGULACIÓN','10','Plasma','Tubo azul citrato',NULL,NULL,NULL,1),
(552,2,'1772','FACTOR X DE COAGULACION','2',NULL,NULL,NULL,NULL,NULL,1),
(553,2,'1773','FACTOR XI DE COAGULACION','2',NULL,NULL,NULL,NULL,NULL,1),
(554,2,'1774','FACTOR XII DE COAGULACION','2',NULL,NULL,NULL,NULL,NULL,1),
(555,2,'1775','FACTOR XIII DE COAGULACION','3',NULL,NULL,NULL,NULL,NULL,1),
(556,2,'714','FENILALANINA','18','Plasma heparina','Tubo verde',NULL,NULL,NULL,1),
(557,2,'86','FENOBARBITAL','2',NULL,NULL,NULL,NULL,NULL,1),
(558,2,'1241','FENOL URINARIO','12',NULL,NULL,NULL,NULL,NULL,1),
(559,2,'2720','FENOTIPO HPN (HEMOGLOBINURIA PAROXISTICA NOCTURNA)','3','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(560,6,'1859','Ferritina','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(561,4,'2985','FGR  NIÑOS (Filtrado Glomerular Renal) SCHWARTZ','0',NULL,NULL,NULL,NULL,NULL,1),
(562,20,'88','FIBRINOGENO','0','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(563,1,'4373','FilmArray® Panel Respiratorio','4',NULL,NULL,NULL,NULL,NULL,1),
(564,4,'2919','FILTRACION GLOMERULAR PRIMARIA (FGP-EPI cr-cys)','0',NULL,NULL,NULL,NULL,NULL,1),
(565,4,'2885','FILTRADO GLOMERULAR (IFG ó eGFR)','0',NULL,NULL,NULL,NULL,NULL,1),
(566,2,'2710','FISH PARA HER 1','9',NULL,NULL,NULL,NULL,NULL,1),
(567,2,'2711','FISH PARA HER 2','9',NULL,NULL,NULL,NULL,NULL,1),
(568,2,'2712','FLUORUROS EN ORINA','20',NULL,NULL,NULL,NULL,NULL,1),
(569,15,'90','FORMULA BLANCA','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(570,15,'2469','FORMULA BLANCA DE VERIFICACION','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(571,15,'91','FORMULA ROJA','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(572,4,'92','FOSFATASA ACIDA TOTAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(573,4,'1910','FOSFATASA ACIDA-PROSTATICA.','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(574,4,'95','FOSFATASA ALCALINA ( ALP )','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(575,2,'1865','FOSFATASA ALCALINA EN LEUCOCITOS','6','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(576,21,'559','FOSFATASA ALCALINA FRACCION OSEA','8',NULL,NULL,NULL,NULL,NULL,1),
(577,2,'1707','FOSFORO EN ORINA DE 24 HORAS.','2','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(578,4,'97','FOSFORO SERICO (P)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(579,6,'1850','FRACCION BETA CUANTITATIVA(HGC)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(580,15,'4331','FROTIS DE SANGRE PERIFÉRICA','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(581,2,'1242','FRUCTOSA EN SEMEN','2','Semen','Frasco esteril',NULL,NULL,NULL,1),
(582,2,'100','FRUCTOSAMINA','2',NULL,NULL,NULL,NULL,NULL,1),
(583,2,'2040','FUNCION DE VON WILLEBRAND','5',NULL,NULL,NULL,NULL,NULL,1),
(584,2,'2679','FUSION BCR/ABL1(P210,Cromosoma Filadelfia,t(9,22))','7','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(585,1,'2536','GABAPENTINA','15',NULL,NULL,NULL,NULL,NULL,1),
(586,5,'4291','GALACTOSA 1-FOSFATO URIDILTRANSFERASA (GALT)','10','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(587,5,'4294','GALECTINA 3','0','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(588,4,'101','GAMMAGLUTAMIL TRANSPEPTIDASA ( GGT )','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(589,12,'4203','GANGLIO LINFATICO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(590,4,'4477','GASOMETRIA ARTERIAL COMPLETA','0','Sangre total heparina','Jeringa heparinizada',NULL,NULL,NULL,1),
(591,4,'4476','GASOMETRIA VENOSA COMPLETA','0','Sangre total heparina','Jeringa heparinizada',NULL,NULL,NULL,1),
(592,2,'104','GASTRINA','8',NULL,NULL,NULL,NULL,NULL,1),
(593,2,'2170','GLOBULINA DE HORMONAS SEXUALES (SHBG)','6','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(594,2,'107','GLUCAGON','8','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(595,2,'1124','GLUCOSA 6 FOSFATO DESHIDROGENASA','2','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(596,4,'824','Glucosa a los 60 min.','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(597,4,'2359','GLUCOSA BASAL y  POSTPRANDIAL CON CARGA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(598,4,'108','GLUCOSA BASAL y POSTPRANDIAL','0',NULL,NULL,NULL,NULL,NULL,1),
(599,4,'1018','GLUCOSA POST PRANDIAL','0','Suero postprandial','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(600,4,'109','GLUCOSA SERICA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(601,4,'111','GLUCOSA URINARIA','0',NULL,NULL,NULL,NULL,NULL,1),
(602,2,'4889','Glycomark','17','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(603,2,'2046','GONADOTROFINA C. BETA LIBRE','6','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(604,15,'113','GOTA GRUESA (Plasmodium sp)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(605,18,'3019','GRADIENTES DE LIQUIDO DE ASCITIS O PERITONEAL','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(606,14,'115','GRASA EN HECES (Cualitativa)','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(607,11,'310','GRASA EN HECES (CUANTITATIVA)','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(608,14,'2389','GRASA EN HECES 3 M','3','Heces 3 muestra','Frasco para heces',NULL,NULL,NULL,1),
(609,15,'119','GRUPO SANGUINEO y FACTOR Rh','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(610,2,'120','HAPTOGLOBINA','2','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(611,2,'2929','HBsAg - HEPATITIS B (Ag. Australia)','3','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(612,11,'1874','HEMOCULTIVO','15','Sangre total','Tubo lila',NULL,NULL,NULL,1),
(613,4,'868','HEMOGLOBINA GLICADA (HB A1c)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(614,2,'1245','HEMOGLOBINA LIBRE EN PLASMA','2','Plasma heparina','Tubo verde',NULL,NULL,NULL,1),
(615,2,'1741','HEMOSIDERINA','2','Frotis','Laminilla',NULL,NULL,NULL,1),
(616,2,'1247','HEMOSIDERINA EN ORINA','2',NULL,NULL,NULL,NULL,NULL,1),
(617,2,'2867','HEPATITIS C GENOTIPO','15','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(618,1,'3014','HEPATITIS E IgG','6',NULL,NULL,NULL,NULL,NULL,1),
(619,1,'3013','HEPATITIS E IgM','6',NULL,NULL,NULL,NULL,NULL,1),
(620,1,'2204','HERPES SIMPLE POR PCR','10',NULL,NULL,NULL,NULL,NULL,1),
(621,1,'2721','HERPES ZOSTER PCR','10',NULL,NULL,NULL,NULL,NULL,1),
(622,2,'132','HIDROXIPROLINA (ORINA DE 24 HRS)','6',NULL,NULL,NULL,NULL,NULL,1),
(623,4,'133','Hierro sérico','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(624,12,'4240','HIGADO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(625,12,'346','HIGADO (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(626,1,'2962','HISTAMINA','6','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(627,2,'1754','HOMOCISTEINA EN SANGRE','3','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(628,6,'134','HORMONA ADRENOCORTICOTROFICA  (ACTH)','0','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(629,6,'2831','HORMONA ANTI MULLERIANA (AMH)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(630,1,'137','HORMONA DEL CRECIMIENTO (GH)','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(631,6,'138','HORMONA ESTIMULANTE DE TIROIDES(TSH)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(632,6,'139','HORMONA FOLICULO ESTIMULANTE(FSH)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(633,6,'141','HORMONA LUTEINIZANTE(LH)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(634,6,'3006','HORMONA PARATIROIDEA INTACTA (PTH)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(635,1,'4675','HORMONA RELACIONADA A GONADOTROPINA, GNRH, LHRH','25','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(636,12,'354','HUESO (BIOPSIA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(637,12,'357','HUESO (EXTREMIDAD POR CARCINOMA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(638,5,'1849','IgE    ESPECIFICA VS ALERGENO','8','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(639,4,'2891','INDICE PROTEINAS/CREATININA (Pr/Cr)','0',NULL,NULL,NULL,NULL,NULL,1),
(640,2,'4730','INDICE SFIT-1/PIGF','14',NULL,NULL,NULL,NULL,NULL,1),
(641,15,'2182','INDUCCION DE DREPANOCITOS','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(642,6,'2416','INFLUENZA A y B (PRUEBA RAPIDA CUALITATIVA)','0','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(643,2,'1955','INHIBIDOR DE ESTERASA DE C1','14','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(644,2,'2183','INHIBINA A','10','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(645,2,'4392','INHIBINA B','13','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(646,12,'4191','INMUNOCITOQUIMICA','8','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(647,2,'2471','INMUNOFENOTIPO','5','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(648,2,'2188','INMUNOFIJACION DE PROTEINAS  EN LCR','4','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(649,2,'2189','INMUNOFIJACION DE PROTEINAS EN ORINA','4','Orina','Frasco esteril',NULL,NULL,NULL,1),
(650,2,'2190','INMUNOFIJACION EN SUERO','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(651,2,'1120','INMUNOGLOBULINA  "A" en LCR','4','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(652,1,'476','INMUNOGLOBULINA  "D" (IgD)','14',NULL,NULL,NULL,NULL,NULL,1),
(653,1,'144','INMUNOGLOBULINA "A" (IgA)','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(654,6,'145','INMUNOGLOBULINA "E" (IgE)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(655,1,'146','INMUNOGLOBULINA "G" (IgG)','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(656,1,'147','INMUNOGLOBULINA "M" (IgM)','3','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(657,7,'1668','Insulina  60 min.','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(658,6,'4505','INSULINA A LAS 2 HORAS','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(659,6,'838','INSULINA BASAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(660,6,'1729','INSULINA BASAL Y POSTPRANDIAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(661,6,'488','INSULINA POST-PRANDIAL','0','Suero postprandial','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(662,2,'2390','INTERLEUCINA 6 (ITL-6)','2','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(663,12,'359','INTESTINO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(664,12,'358','INTESTINO (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(665,12,'362','INTESTINO (RESECCION POR PROCESO INFLAMATORIO)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(666,2,'2908','INVESTIGACION DE GALACTOMANANO','3',NULL,NULL,NULL,NULL,NULL,1),
(667,4,'151','ION AMONIO','0','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(668,2,'8','ISOENZIMAS DE DESHIDROGENASA LACTICA','11',NULL,NULL,NULL,NULL,NULL,1),
(669,1,'2191','ISOENZIMAS DE FOSFATASA ALCALINA','15',NULL,NULL,NULL,NULL,NULL,1),
(670,2,'2869','JAK2, MUTACION C.1849G>T (P.VAL61PHE, V617F)','7','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(671,4,'2102','JUEVES: PERFIL METABÓLICO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(672,4,'4343','KIT TOMA CATETER','0',NULL,NULL,NULL,NULL,NULL,1),
(673,4,'4344','KIT TOMA HEMOCULTIVO','0',NULL,NULL,NULL,NULL,NULL,1),
(674,1,'4758','LACOSAMIDA','18',NULL,NULL,NULL,NULL,NULL,1),
(675,4,'584','LACTATO (ACIDO LACTICO)','0','jeringa/heparina',NULL,NULL,NULL,NULL,1),
(676,14,'2647','LACTOFERRINA EN HECES','0','Heces','Frasco para heces',NULL,NULL,NULL,1),
(677,2,'2192','LAMOTRIGINA','23',NULL,NULL,NULL,NULL,NULL,1),
(678,2,'2193','LEPTINA','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(679,1,'283','LEVETIRACETAM (Keppra)','15','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(680,4,'2887','LIPASA EN LIQUIDOS ORGANICOS','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(681,4,'160','LIPASA SERICA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(682,4,'1853','LIPIDOS TOTALES','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(683,12,'4298','LIPOMA (TAMAÑO: MEDIANO A GRANDE)','8',NULL,NULL,NULL,NULL,NULL,1),
(684,1,'332','LIPOPROTEINA A','6',NULL,NULL,NULL,NULL,NULL,1),
(685,12,'4245','LIQUIDO PERITONEAL','8','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(686,13,'388','LISTERIA MONOCYTOGENES EN ALIMENTOS NOM-143-SSA1-1995','14','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(687,2,'164','LITIO EN SUERO','2',NULL,NULL,NULL,NULL,NULL,1),
(688,18,'4310','LUNES: PAQUETE DE CONTROL PRENATAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(689,2,'4867','MACROPROLACTINA','13','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(690,2,'4630','MAGNESIO EN ORINA AL AZAR','0','Orina al azar','Frasco esteril',NULL,NULL,NULL,1),
(691,2,'1712','MAGNESIO EN ORINA DE 24 HORAS','2','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(692,4,'165','MAGNESIO SERICO (Mg)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(693,12,'370','MAMA (BIOPSIA INCISIONAL MENOR A 5 CM)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(694,12,'336','MAMA (BIOPSIA POR ASPIRACION) BAAF','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(695,12,'378','MAMA (GANGLIO CENTINELA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(696,12,'4308','MAMA (IMPRONTA)',NULL,'Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(697,12,'363','MAMA (MASTECTOMIA RADICAL)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(698,12,'365','MAMA (RESECCION PARCIAL POR MICROCALCIFICACIONES)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(699,12,'369','MAMA (TRUCUT)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(700,2,'2729','MANGANESO','12',NULL,NULL,NULL,NULL,NULL,1),
(701,6,'2983','MARCADORES TUMORALES COMPLETOS','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(702,6,'1334','MARCADORES TUMORALES II (CEA,  CA 19-9, AFP)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(703,10,'5','MARIHUANA (THC)','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(704,1,'4224','MARIHUANA (THC) CONFIRMATORIO','25',NULL,NULL,NULL,NULL,NULL,1),
(705,18,'4311','MARTES: PERFIL GINECOLOGICO COMPLETO','0',NULL,NULL,NULL,NULL,NULL,1),
(706,12,'364','MASTECTOMIA','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(707,12,'392','MEDULA OSEA (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(708,2,'444','MERCURIO EN ORINA','16',NULL,NULL,NULL,NULL,NULL,1),
(709,2,'2195','MERCURIO EN SANGRE','16','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(710,2,'1285','METAHEMOGLOBINA','3','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(711,21,'2814','METANEFRINAS EN PLASMA','9','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(712,10,'2472','METANFETAMINAS (MET)','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(713,2,'2731','METOTREXATO','6',NULL,NULL,NULL,NULL,NULL,1),
(714,4,'1723','MICROALBUMINURIA (ORINA DE 24 HRS)','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(715,4,'2819','MICROALBUMINURIA (Orina espontanea)','0','Orina (Primera micción)','Frasco esteril',NULL,NULL,NULL,1),
(716,18,'4312','MIERCOLES: PERFIL DE LÍPIDOS','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(717,4,'544','MIOGLOBINA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(718,2,'2875','MTHFR, VARIANTE P.Ala222Val (MTHFR 677 C>T), GENOTIPO','7','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(719,12,'4146','MUESTRA: LIQUIDO DE NODULO TIROIDEO (Jeringa)','8','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(720,12,'393','MUSCULO ESTRIADO (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(721,2,'2874','Mutación PROTROMBINA 20210 G-A','7','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(722,2,'2834','MUTACION W515 L/K DEL GEN MPL','10','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(723,2,'2832','MUTACIONES DEL EXON 9 DE CALR','12','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(724,11,'4320','MYCOBACTERIUM TUBERCULOSIS COMPLEX','15','Esputo','Frasco esteril',NULL,NULL,NULL,1),
(725,2,'2474','MYCOBACTERIUM TUBERCULOSIS IgG','4',NULL,NULL,NULL,NULL,NULL,1),
(726,2,'325','NICOTINA (ORINA)','5',NULL,NULL,NULL,NULL,NULL,1),
(727,2,'1805','NICOTINA EN SUERO','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(728,2,'2734','NIQUEL','12','Sangre total heparina',NULL,NULL,NULL,NULL,1),
(729,4,'2021','NITROGENO UREICO (BUN)','0',NULL,NULL,NULL,NULL,NULL,1),
(730,1,'2127','NIVELES DE AMIODORONA','12',NULL,NULL,NULL,NULL,NULL,1),
(731,2,'15','NIVELES DE CICLOSPORINA','4','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(732,2,'1807','NORADRENALINA EN ORINA','8','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(733,6,'2937','NT-pro BNP (Fracción N-terminal del BNP)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(734,12,'461','ÓBITO/FETO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(735,14,'2356','OBSERVACION EN FRESCO DE:','0','Toma Directa',NULL,NULL,NULL,NULL,1),
(736,1,'2202','OPIACEOS','4',NULL,NULL,NULL,NULL,NULL,1),
(737,4,'2830','OSMOLARIDAD EN ORINA','0','Orina al azar','Frasco esteril',NULL,NULL,NULL,1),
(738,4,'175','OSMOLARIDAD SERICA','0',NULL,NULL,NULL,NULL,NULL,1),
(739,2,'317','OSTEOCALCINA','7',NULL,NULL,NULL,NULL,NULL,1),
(740,12,'1969','OTROS, BIOPSIA POR ASPIRACION','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(741,12,'399','OVARIO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(742,12,'400','OVARIO (RUTINA CARCINOMA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(743,12,'404','OVULOPLACENTARIOS','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(744,2,'2097','OXALATOS EN ORINA DE 24HRS','5','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(745,2,'2203','OXCARBAZEPINA','10',NULL,NULL,NULL,NULL,NULL,1),
(746,12,'4242','PANCREAS','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(747,2,'2813','PANEL DE ALERGENOS ALIMENTARIOS','10','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(748,2,'2812','PANEL DE ALERGENOS INHALATORIOS','10','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(749,4,'1813','PANEL DE HEPATITIS VIRAL A, B y C','0',NULL,NULL,NULL,NULL,NULL,1),
(750,1,'4148','PANEL DE PATOGENOS RESPIRATORIOS','15','Exudado','Vial especial',NULL,NULL,NULL,1),
(751,6,'4765','PANEL DE VIRUS RESPIRATORIOS','0','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(752,7,'2855','PANEL VIRAL (HIV, VHB, VHC)','0',NULL,NULL,NULL,NULL,NULL,1),
(753,6,'4593','PANEL VIRAL RESPIRATORIO','0','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(754,8,'4717','PANEL VIRAL RESPIRATORIO POR PCR','3','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(755,12,'177','PAPANICOLAOU (CITOLOGIA CERVICOVAGINAL)','8','Frotis','Laminilla',NULL,NULL,NULL,1),
(756,18,'4401','PAQUETE PAPÁ SALUDABLE BASICO','0',NULL,NULL,NULL,NULL,NULL,1),
(757,18,'4402','PAQUETE PAPÁ SALUDABLE COMPLETO','0',NULL,NULL,NULL,NULL,NULL,1),
(758,1,'2476','PCR CARGA VIRAL DE CITOMEGALOVIRUS (CMV)','7','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(759,1,'4682','PCR Detección de borrelia','14','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(760,1,'272','PCR DETECCION DE BRUCELLA','10','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(761,1,'4600','PCR DETECCION DE HELICOBACTER PYLORI','7',NULL,NULL,NULL,NULL,NULL,1),
(762,1,'4711','PCR Detección de toxoplasma Gondii TR','15',NULL,NULL,NULL,NULL,NULL,1),
(763,1,'170','PCR DETECCION Mycobacterium tuberculosis','7',NULL,NULL,NULL,NULL,NULL,1),
(764,1,'4769','PCR GENE XPERT Mycobacterium tubercolusis (MTB/RIF)','8','Espectoración','Frasco esteril',NULL,NULL,NULL,1),
(765,1,'2754','PCR INFECCIOSO DE TRANSMISION  SEXUAL','7','Exudado','Vial especial',NULL,NULL,NULL,1),
(766,1,'4500','PCR PANEL VIRAL GASTROINTESTINAL','5',NULL,NULL,NULL,NULL,NULL,1),
(767,1,'2809','PCR PANEL VIRAL PARA MENINGITIS','18','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(768,8,'2437','PCR PARA INFLUENZA','2','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(769,4,'1778','PCR ULTRASENSIBLE (PCR-us)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(770,1,'1119','PCR VIRUS DE LA HEPATITIS B','10',NULL,NULL,NULL,NULL,NULL,1),
(771,1,'4723','PCR Virus del Papiloma Humano 35 Genotipos','7',NULL,NULL,NULL,NULL,NULL,1),
(772,8,'4145','PCR, DETECCIÓN DEL CORONAVIRUS SARS-COV-2','2',NULL,NULL,NULL,NULL,NULL,1),
(773,8,'2328','PCR-VIRUS SINCITIAL RESPIRATORIO (VSR)','5','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(774,6,'1676','PEPTIDO  C','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(775,4,'2293','Perfil 24','0',NULL,NULL,NULL,NULL,NULL,1),
(776,19,'2897','PERFIL ANDROGENICO','4',NULL,NULL,NULL,NULL,NULL,1),
(777,4,'4715','PERFIL ATEROGENICO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(778,4,'4708','PERFIL BASICO DE SOP','0',NULL,NULL,NULL,NULL,NULL,1),
(779,4,'1925','PERFIL BIOQUIMICO 10 ELEMENTOS','0',NULL,NULL,NULL,NULL,NULL,1),
(780,4,'1915','PERFIL BIOQUIMICO 15 ELEMENTOS','0',NULL,NULL,NULL,NULL,NULL,1),
(781,4,'1926','PERFIL BIOQUIMICO 20 ELEMENTOS','0',NULL,NULL,NULL,NULL,NULL,1),
(782,4,'691','PERFIL BIOQUIMICO DE 24 ELEMENTOS','0',NULL,NULL,NULL,NULL,NULL,1),
(783,4,'1927','PERFIL BIOQUIMICO DE 25 ELEMENTOS','0',NULL,NULL,NULL,NULL,NULL,1),
(784,4,'1928','PERFIL BIOQUIMICO DE 30 ELEMENTOS','0',NULL,NULL,NULL,NULL,NULL,1),
(785,18,'4329','PERFIL BIOQUIMICO DE 35 ELEMENTOS','0',NULL,NULL,NULL,NULL,NULL,1),
(786,4,'4390','PERFIL BIOQUIMICO DE 45 ELEMENTOS','0',NULL,NULL,NULL,NULL,NULL,1),
(787,4,'102','PERFIL BIOQUIMICO ESPECIAL','0',NULL,NULL,NULL,NULL,NULL,1),
(788,6,'4620','PERFIL CARDIACO COMPLETO','0',NULL,NULL,NULL,NULL,NULL,1),
(789,19,'4709','PERFIL COMPLETO DE SOP','5',NULL,NULL,NULL,NULL,NULL,1),
(790,4,'2980','PERFIL CORONARIO','0','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(791,4,'1364','PERFIL DE BILIRRUBINAS (BT, BD, BI)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(792,2,'1610','PERFIL DE CATECOLAMINAS PLASMATICAS','8','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(793,2,'1477','PERFIL DE CATECOLAMINAS TOTALES  EN ORINA.','8',NULL,NULL,NULL,NULL,NULL,1),
(794,15,'1943','PERFIL DE COAGULACION 1 (TP, INR, TTP)','0','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(795,22,'1616','PERFIL DE COAGULACION 2 (PRUEBAS HEMORRAGIPARAS)','0','Plasma citratado PP','Tubo azul citrato',NULL,NULL,NULL,1),
(796,10,'1846','PERFIL DE DROGAS 1 (ANTIDOPING) 3 PRUEBAS','0','Orina al azar','Frasco esteril',NULL,NULL,NULL,1),
(797,10,'1843','PERFIL DE DROGAS 2 (ANTIDOPING) 5 PRUEBAS','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(798,10,'4391','PERFIL DE DROGAS 3 (ANTIDOPING) 12 PRUEBAS','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(799,6,'4611','PERFIL DE ETS  III  MASCULINO','8',NULL,NULL,NULL,NULL,NULL,1),
(800,6,'4610','PERFIL DE ETS I','0',NULL,NULL,NULL,NULL,NULL,1),
(801,6,'4673','PERFIL DE ETS II','5',NULL,NULL,NULL,NULL,NULL,1),
(802,4,'1713','PERFIL DE HIERRO II (CINETICA DE HIERRO)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(803,19,'2972','PERFIL DE HIPERANDROGENISMO','4',NULL,NULL,NULL,NULL,NULL,1),
(804,19,'2973','PERFIL DE HIPERTENSION','12',NULL,NULL,NULL,NULL,NULL,1),
(805,19,'2976','PERFIL DE HIRSUTISMO I','5',NULL,NULL,NULL,NULL,NULL,1),
(806,19,'2977','PERFIL DE HIRSUTISMO II','8',NULL,NULL,NULL,NULL,NULL,1),
(807,1,'1678','PERFIL DE INMUNOGLOBULINAS 1 (IgG,IgA,IgM)','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(808,6,'1269','PERFIL DE INMUNOGLOBULINAS 2  (IgG, IgA, IgM, IgE)','5','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(809,4,'2492','PERFIL DE LIPIDOS','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(810,18,'4313','PERFIL DE LIPIDOS II','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(811,2,'3022','PERFIL DE LUPUS (AUTOINMUNIDAD)','6',NULL,NULL,NULL,NULL,NULL,1),
(812,1,'1765','PERFIL DE METANEFRINAS EN ORINA DE 24 HORAS','8','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(813,1,'1655','PERFIL DE TORCH COMPLETO (IgG, IgM)','4',NULL,NULL,NULL,NULL,NULL,1),
(814,1,'4646','PERFIL DE TROMBOFILIA II','12',NULL,NULL,NULL,NULL,NULL,1),
(815,3,'4400','PERFIL DE TROPONINAS (I y T)','0',NULL,NULL,NULL,NULL,NULL,1),
(816,7,'1872','PERFIL DONADOR','0',NULL,NULL,NULL,NULL,NULL,1),
(817,2,'2896','PERFIL FIBROTEST-ACTITEST','3',NULL,NULL,NULL,NULL,NULL,1),
(818,4,'2823','PERFIL GCT','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(819,6,'1300','PERFIL GINECOLOGICO I (HORMONAL FEMENINO)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(820,19,'1683','PERFIL GINECOLOGICO II (HORMONAL FEMENINO II)','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(821,4,'1340','PERFIL HEPATICO (PFH)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(822,4,'1932','PERFIL HEPATICO 2 (PFH 2)','0','Suero y Plasma/Citrato','Tubo amarillo y tubo azul',NULL,NULL,NULL,1),
(823,4,'2511','PERFIL HEPATICO 3 (PFH 3)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(824,19,'11','PERFIL HIPOFISIARIO','5',NULL,NULL,NULL,NULL,NULL,1),
(825,6,'1290','PERFIL HORMONAL (CLIMATERIO)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(826,6,'1708','PERFIL HORMONAL MASCULINO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(827,6,'1731','PERFIL HORMONAL MASCULINO 2','0',NULL,NULL,NULL,NULL,NULL,1),
(828,23,'4852','PERFIL LABORAL 1 FLAMA AZUL','0',NULL,NULL,NULL,NULL,NULL,1),
(829,18,'4853','PERFIL LABORAL 2 FLAMA AZUL',NULL,NULL,NULL,NULL,NULL,NULL,1),
(830,4,'4341','PERFIL METABÓLICO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(831,2,'2895','PERFIL NASH FIBROTEST (FIBROMAX)','5',NULL,NULL,NULL,NULL,NULL,1),
(832,4,'2979','PERFIL OSEO BASICO','9',NULL,NULL,NULL,NULL,NULL,1),
(833,19,'2971','PERFIL OSEO COMPLETO','15',NULL,NULL,NULL,NULL,NULL,1),
(834,4,'4302','PERFIL OVARICO 1','3',NULL,NULL,NULL,NULL,NULL,1),
(835,4,'1306','PERFIL PREOPERATORIO','0',NULL,NULL,NULL,NULL,NULL,1),
(836,6,'1914','PERFIL PROSTATICO 1','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(837,18,'1307','PERFIL PROSTATICO 2','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(838,4,'4612','PERFIL RENAL BASICO','0',NULL,NULL,NULL,NULL,NULL,1),
(839,4,'4613','PERFIL RENAL COMPLETO','0',NULL,NULL,NULL,NULL,NULL,1),
(840,6,'4597','PERFIL REUMATICO ESPECIALIZADO','0',NULL,NULL,NULL,NULL,NULL,1),
(841,11,'313','PERFIL SANITARIO','4','Suero 1 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(842,8,'4348','PERFIL SINTOMAS GRIPALES POR PCR','2',NULL,NULL,NULL,NULL,NULL,1),
(843,19,'2974','PERFIL SUPRARRENAL','8',NULL,NULL,NULL,NULL,NULL,1),
(844,6,'2975','PERFIL TESTICULAR','0',NULL,NULL,NULL,NULL,NULL,1),
(845,6,'419','PERFIL TIROIDEO 1','0','Suero','Tubo amarillo o Tubo rojo',NULL,'hormona estimulante de tiroideos, tiroxina libre, triyodotironina libre',NULL,1),
(846,6,'2020','PERFIL TIROIDEO 2','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(847,6,'1937','PERFIL TIROIDEO 3','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(848,6,'2930','PERFIL TIROIDEO 4','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(849,6,'2500','PERFIL TIROIDEO 5','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(850,1,'199','PERFIL TORCH   IgM','4',NULL,NULL,NULL,NULL,NULL,1),
(851,1,'198','PERFIL TORCH  IgG','4',NULL,NULL,NULL,NULL,NULL,1),
(852,4,'2496','PERFIL TOXEMICO (PREECLAMTICO)','0','tubo:lila,rojo,azul+orina','Lila, amarillo, azul, frasco',NULL,NULL,NULL,1),
(853,6,'4494','PERFIL TUMORAL FEMENINO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(854,6,'1621','PERFIL TUMORAL I (AFP, CEA, CA 125)','4',NULL,NULL,NULL,NULL,NULL,1),
(855,6,'1491','PERFIL TUMORAL MASCULINO (CEA, AFP, PSA, HGC)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(856,14,'1886','PH Y AZUCARES REDUCTORES','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(857,12,'484','PIEL (MÁS DE 2 CM)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(858,12,'409','PIEL (MENOS DE 2 CM)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(859,12,'410','PLACENTA','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(860,15,'212','Plaquetas (PLT)','0','Sangre total','Tubo lila',NULL,NULL,NULL,1),
(861,2,'1311','PLASMINOGENO','2',NULL,NULL,NULL,NULL,NULL,1),
(862,2,'4653','Plasmodium DNA','15','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(863,15,'4205','PLEUROCRITO','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(864,2,'213','PLOMO EN ORINA','16',NULL,NULL,NULL,NULL,NULL,1),
(865,2,'214','PLOMO EN SANGRE','16','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(866,2,'215','POBLACION DE LINFOCITOS T y B','3','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(867,12,'4251','POLIPO (ESTOMAGO, INTESTINO)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(868,12,'4244','POLIPO ENDOCERVICAL','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(869,2,'218','PORFOBILINOGENO EN ORINA','3',NULL,NULL,NULL,NULL,NULL,1),
(870,4,'219','POTASIO SERICO (K)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(871,4,'220','POTASIO URINARIO','0',NULL,NULL,NULL,NULL,NULL,1),
(872,2,'2355','PREALBUMINA','2',NULL,NULL,NULL,NULL,NULL,1),
(873,1,'3012','PREGNENOLONA','18',NULL,NULL,NULL,NULL,NULL,1),
(874,7,'503','PRENUPCIALES    (grupo-RH, VDRL, HIV )','0',NULL,NULL,NULL,NULL,NULL,1),
(875,6,'2247','PROCALCITONINA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(876,6,'224','PROGESTERONA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(877,5,'4316','PROINSULINA','10','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(878,6,'2582','PROLACTINA 2 MUESTRAS (Basal, Tiempo 1)','0',NULL,NULL,NULL,NULL,NULL,1),
(879,6,'2249','PROLACTINA 3 MUESTRAS','0',NULL,NULL,NULL,NULL,NULL,1),
(880,6,'225','PROLACTINA SERICA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(881,4,'4305','PROMOCION SEP-OCT (PERFIL BIOQUIMICO ESPECIAL)','0','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(882,12,'1967','PROSTA (RESECCION TRANSRECTAL O SUPRAPUBICA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(883,12,'411','PROSTATA COMPLETA  (PROSTATECTOMIA RADICAL)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(884,2,'2250','PROTEINA A PLASMATICA  (PAPP-A)','5',NULL,NULL,NULL,NULL,NULL,1),
(885,2,'322','PROTEINA C DE COAGULACION','8','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(886,4,'2396','PROTEINA C REACTIVA CUANTITATIVA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(887,10,'227','PROTEINA DE BENCE JONES (ORINA)','0',NULL,NULL,NULL,NULL,NULL,1),
(888,2,'323','PROTEINA S DE COAGULACION','12','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(889,2,'2934','PROTEINA UNION FCI, IgFBP3','6','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(890,5,'4301','PROTEINAS DE MATRIZ NUCLEAR (NMP22)',NULL,'Orina casual','Frasco esteril',NULL,NULL,NULL,1),
(891,4,'2252','PROTEINAS TOTALES EN LCR','0','LCR','Tubo tapa rosca esteril',NULL,NULL,NULL,1),
(892,4,'2397','PROTEINAS TOTALES EN LIQUIDO PLEURAL','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(893,10,'230','PROTEINAS TOTALES EN ORINA DE 24 HRS.','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(894,4,'2825','PROTEINAS TOTALES EN ORINA ESPONTANEA','0','Orina al azar','Frasco esteril',NULL,NULL,NULL,1),
(895,4,'877','PROTEINAS TOTALES SERICAS','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(896,4,'231','PROTEINAS TOTALES SERICAS Y RELACION A/G','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(897,2,'2253','PROTOPORFIRINA LIBRE ERITROCITARIA','3','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(898,2,'2943','PRUEBA CONFIRMATORIA PARA TREPONEMA PALLIDUM IgG  (SIFILIS)','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(899,2,'2255','PRUEBA DE ALIENTO DE H. PYLORI','5','Aire exhalado','Kit especial',NULL,NULL,NULL,1),
(900,7,'136','PRUEBA DE EMBARAZO EN ORINA','0','Orina','Frasco esteril',NULL,NULL,NULL,1),
(901,4,'135','PRUEBA DE EMBARAZO EN SUERO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(902,15,'2166','PRUEBA DE FRAGILIDAD OSMOTICA (NaCl)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(903,14,'157','PRUEBA DE GRAHAM (OXIUROS)','0','Heces','Frasco para heces',NULL,NULL,NULL,1),
(904,2,'2398','PRUEBA DE PATERNIDAD (2 MUESTRAS)','20',NULL,NULL,NULL,NULL,NULL,1),
(905,2,'2399','PRUEBA DE PATERNIDAD (3 MUESTRAS)','20',NULL,NULL,NULL,NULL,NULL,1),
(906,2,'4126','PRUEBA DE PATERNIDAD DUO + PERSONA EXTRA','20',NULL,NULL,NULL,NULL,NULL,1),
(907,2,'2772','PRUEBA DE PATERNIDAD TRIO + PERSONA EXTRA','20',NULL,NULL,NULL,NULL,NULL,1),
(908,15,'41','PRUEBA DIRECTA DE COOMBS (PDC)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(909,4,'4352','PRUEBA RAPIDA COMBO COVID-FLU','0','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(910,11,'4272','Prueba Rapida, ANTIGENOS DEL SARS-CoV-2','0','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(911,7,'1854','PRUEBAS DE COMPATIBILIDAD','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(912,2,'2907','QUANTIFERON TB-PLUS','7','Sangre total heparina','Tubo verde',NULL,NULL,NULL,1),
(913,2,'4227','QUANTOSE RI (Prueba diagnóstica de Resistencia a Insulina)','12','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(914,4,'1319','QUIMICA SANGUINEA ( 3 ELEMENTOS)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(915,4,'1947','QUIMICA SANGUINEA (4 ELEMENTOS)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(916,4,'1322','QUIMICA SANGUINEA (5 ELEMENTOS)','0',NULL,NULL,NULL,NULL,NULL,1),
(917,4,'1321','QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)','0',NULL,NULL,NULL,NULL,NULL,1),
(918,7,'328','R.P.R.','2','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(919,4,'238','REACCIONES FEBRILES','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(920,24,'4633','Recipiente Para Orina 24 Horas Ambar','0','Orina de 24 h','Frasco ambar 24 horas',NULL,NULL,NULL,1),
(921,12,'414','RECTO (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(922,15,'1916','RECUENTO CELULAR DE LIQUIDO DE:','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(923,10,'4511','RECUENTO DE ADDIS','0','Orina (Primera micción)','Frasco esteril',NULL,NULL,NULL,1),
(924,4,'1062','RELACION ALBUMINA/GLOBULINA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(925,4,'4868','RELACION BUN/CREATININA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(926,4,'4767','Relación BUN/CREATININA','0',NULL,NULL,NULL,NULL,NULL,1),
(927,1,'240','RENINA','16','Plasma EDTA','Tubo lila',NULL,NULL,NULL,1),
(928,12,'4303','RESECCION DE TUMOR (BIOPSIA)','0','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(929,4,'4632','RESISTENCIA A LA INSULINA  (HOMA-IR, %ß, %S).','0',NULL,NULL,NULL,NULL,NULL,1),
(930,7,'1934','RESISTENCIA A LA INSULINA (HOMA-IR, %ß, %S)','0',NULL,NULL,NULL,NULL,NULL,1),
(931,1,'4318','RESISTENCIA A LA PROTEINA C ACTIVADA (RPCa)','8','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(932,12,'4232','RESTOS OVULOPLACENTARIOS','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(933,5,'2935','RETICULINA AC. IgA CON PATRON','8','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(934,15,'245','RETICULOCITOS (% y VALOR ABSOLUTO)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(935,15,'2053','RETRACCION DE COAGULO','1','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(936,12,'4200','RIÑON','10','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(937,12,'437','RIÑON (NEFRECTOMIA POR PROCESO INFLAMATORIO)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(938,12,'427','RIÑON (NEFRECTOMIA POR TUMOR)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(939,14,'2386','ROTAVIRUS y ADENOVIRUS EN HECES','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(940,12,'4282','RTU DE PROSTATA','8',NULL,NULL,NULL,NULL,NULL,1),
(941,7,'2967','SABADO 1: PERFIL PROSTATICO','0',NULL,NULL,NULL,NULL,NULL,1),
(942,7,'4314','SABADO 2: PERFIL TIROIDEO COMPLETO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(943,5,'247','SALICILATOS (ACIDO ACETILSALICILICO )','8','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(944,13,'2352','SALMONELLA SP. EN ALIMENTOS NOM-114-SSA1-1994','7','ALIMENTO','Conrtenedor para aliementos',NULL,NULL,NULL,1),
(945,12,'438','SALPINGES','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(946,14,'248','SANGRE OCULTA EN HECES 1 M (iFOB/FIT)','0','Heces 1 muestra','Frasco para heces',NULL,NULL,NULL,1),
(947,14,'2257','SANGRE OCULTA EN HECES 2 M  (iFOB/FIT)','0','Heces 3 muestra','Frasco para heces',NULL,NULL,NULL,1),
(948,14,'249','SANGRE OCULTA EN HECES 3 M (iFOB/FIT)','0',NULL,NULL,NULL,NULL,NULL,1),
(949,2,'2045','SELENIO (SUERO, ORINA)','20',NULL,NULL,NULL,NULL,NULL,1),
(950,2,'567','SEROTONINA (Orina, Suero)','8',NULL,NULL,NULL,NULL,NULL,1),
(951,1,'4712','Sexado Fetal Molecular','8',NULL,NULL,NULL,NULL,NULL,1),
(952,4,'2959','SODIO EN ORINA ALEATORIA','0','Orina casual','Frasco esteril',NULL,NULL,NULL,1),
(953,4,'250','SODIO SERICO (Na)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(954,4,'251','SODIO URINARIO','0',NULL,NULL,NULL,NULL,NULL,1),
(955,6,'253','SOMATOMEDINA C (IGF-1)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(956,5,'2998','STREPTOCOCCUS PNEUMONIAE IGG AB (23 SER)','10','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(957,2,'2259','SUBCLASES DE INMUNOGLOBULINA IgA ( IgA 1, IgA 2)','8',NULL,NULL,NULL,NULL,NULL,1),
(958,1,'1268','SUBCLASES DE INMUNOGLOBULINAS  IgG 1,2,3,4','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(959,15,'2807','SUERO AUTOLOGO','0','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(960,12,'4233','SUPRARRENAL','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(961,1,'4273','T3 REVERSA (T3 R)','16','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(962,2,'2261','TACROLIMUS EN SANGRE TOTAL','4','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(963,2,'2744','TALIO (SUERO, ORINA)','16',NULL,NULL,NULL,NULL,NULL,1),
(964,1,'4403','TAMIZ METABÓLICO NEONATAL AMPLIADO COMPLETO','8','Sangre seca/Papel filtro','Papel filtro especial',NULL,NULL,NULL,1),
(965,2,'2449','TAMIZ NEONATAL','10','Papel Tamiz','Papel filtro especial',NULL,NULL,NULL,1),
(966,2,'2982','TEOFILINA','8',NULL,NULL,NULL,NULL,NULL,1),
(967,4,'4882','Test de O´Sullivan (50g) Diabetes gestacional','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(968,12,'443','TESTICULO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(969,12,'440','TESTICULO (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(970,12,'441','TESTICULO (PROCESO INFLAMATORIO)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(971,6,'257','TESTOSTERONA LIBRE','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(972,6,'256','TESTOSTERONA TOTAL','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(973,6,'1146','TIEMPO DE COAGULACION','0','Sangre total','Tubo lila',NULL,NULL,NULL,1),
(974,15,'259','TIEMPO DE PROTROMBINA  (TP, INR)','0','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(975,22,'2481','TIEMPO DE PROTROMBINA CON CORRECCIONES, DILUCIONES','0','Plasma citratado PP','Tubo azul citrato',NULL,NULL,NULL,1),
(976,2,'2745','TIEMPO DE REPTILASA','2',NULL,NULL,NULL,NULL,NULL,1),
(977,6,'260','TIEMPO DE SANGRADO','0','Toma directa','Toma directa',NULL,NULL,NULL,1),
(978,1,'261','TIEMPO DE TROMBINA  (TT)','3','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(979,22,'2482','TIEMPO DE TROMBOPLASTINA CON CORRECIONES, DILUCIONES','0','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(980,15,'262','TIEMPO DE TROMBOPLASTINA PARCIAL (TTPa)','0','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(981,11,'265','TINCION DE GRAM','0','Frotis','Laminilla',NULL,NULL,NULL,1),
(982,14,'4871','Tinción de Kinyoun en heces','0','Heces','Frasco para heces',NULL,NULL,NULL,1),
(983,11,'269','Tinción de Tinta China','0',NULL,NULL,NULL,NULL,NULL,1),
(984,15,'3016','TINCION DE WRIGHT','0','DIVERSOS','Diverso',NULL,NULL,NULL,1),
(985,14,'1392','Tinción de Wright','0',NULL,NULL,NULL,NULL,NULL,1),
(986,15,'2578','TINCION DE WRIGHT MEDULA OSEA','1',NULL,NULL,NULL,NULL,NULL,1),
(987,11,'270','TINCION DE ZIEHL NEELSEN','0',NULL,NULL,NULL,NULL,NULL,1),
(988,2,'2746','TIOSULFATO EN ORINA','16',NULL,NULL,NULL,NULL,NULL,1),
(989,10,'2370','TIRA REACTIVA','0','Líquido corporal','Frasco esteril',NULL,NULL,NULL,1),
(990,6,'271','TIROGLOBULINA (TGB)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(991,12,'447','TIROIDES','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(992,12,'449','TIROIDES (TIROIDECTOMIA TOTAL POR CARCINOMA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(993,12,'446','TIROIDES (TIROIDECTOMIA TOTAL POR LESIONES NO NEOPLASICAS)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(994,2,'4615','TIROSINA','18',NULL,NULL,NULL,NULL,NULL,1),
(995,6,'1388','TIROXINA LIBRE ( T4 libre )','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(996,6,'273','TIROXINA TOTAL  (T4 total)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(997,1,'2262','TOPIRAMATO','15','Suero','Tubo amarillo',NULL,NULL,NULL,1),
(998,20,'4355','TP/TTPa CORRECCION CON PLASMA NORMAL (1:1 y 4:1)','0','Plasma/Citrato','Tubo azul citrato',NULL,NULL,NULL,1),
(999,5,'2999','TPMT ACTIVIDAD (tiopurina metiltransferasa)','20','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(1000,5,'3000','TPMT GENOTIPO (tiopurina metiltransferasa)','13','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(1001,4,'279','Transferrina','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1002,2,'2459','TRANSGLUTAMINASA TISULAR IgG, IgA','8','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1003,2,'280','TREPONEMA EN CAMPO OBSCURO (SIFILIS)','0','Frotis','Laminilla',NULL,NULL,NULL,1),
(1004,4,'4317','TRIAGE CARDIACO','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1005,4,'281','TRIGLICERIDOS','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1006,4,'4875','Triglicéridos en líquido peritoneal','0','Líquido biológico','Frasco esteril',NULL,NULL,NULL,1),
(1007,19,'1980','TRIPLE MARCADOR','16',NULL,NULL,NULL,NULL,NULL,1),
(1008,5,'2913','TRIPTASA','15','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1009,6,'314','TRIYODOTIRONINA LIBRE (T3 libre)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1010,6,'282','TRIYODOTIRONINA TOTAL (T3 total)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1011,4,'290','TROPONINA I CARDIACA (cTn I)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1012,4,'4399','TROPONINA T CARDIACA (cTn T)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1013,5,'2916','TSI (INMUNOGLOBULINA ESTIMULANTE DE TIROIDES)','10','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1014,12,'4120','TUMOR DE OVARIO','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1015,12,'4292','TUMOR DE PARTES BLANDAS','8',NULL,NULL,NULL,NULL,NULL,1),
(1016,12,'4246','TUMOR SALPINGE','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1017,4,'4322','UREA EN ORINA AL AZAR','0','Orina al azar','Frasco esteril',NULL,NULL,NULL,1),
(1018,4,'1648','UREA EN ORINA DE 24 HORAS','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1019,4,'284','UREA SERICA','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1020,4,'158','UREA SERICA y NITROGENO UREICO (BUN)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1021,2,'216','UROPORFIRINAS TOTALES (ORINA)','5',NULL,NULL,NULL,NULL,NULL,1),
(1022,12,'2842','UTERO (CON ANEXOS)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(1023,12,'455','UTERO (HISTERECTOMIA POR CARCINOMA INVASOR)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1024,12,'459','UTERO (HISTERECTOMIA POR LESION DE ALTO GRADO, CA IN SITU O MICROINVASOR)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1025,12,'454','UTERO (MIOMATOSIS DE GRANDES ELEMENTOS)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1026,12,'4295','UTERO (MIOMATOSIS DE MEDIANOS ELEMENTOS)','8',NULL,NULL,NULL,NULL,NULL,1),
(1027,12,'452','UTERO (SIN ANEXOS)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1028,6,'286','V.D.R.L.(Reacciones serolueticas)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1029,2,'1808','VANCOMICINA','9',NULL,NULL,NULL,NULL,NULL,1),
(1030,2,'546','VASOPRESINA (HORMONA ANTIDIURETICA)','25',NULL,NULL,NULL,NULL,NULL,1),
(1031,12,'4236','VEJIGA','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1032,12,'4185','VEJIGA (BIOPSIA)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(1033,15,'288','Velocidad de Sedimentación G. (VSG)','0','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(1034,12,'462','VESICULA BILIAR','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1035,12,'463','VESICULA BILIAR POR CARCINOMA','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1036,18,'2099','VIERNES: CONTROL DIABETICO','0',NULL,NULL,NULL,NULL,NULL,1),
(1037,1,'2263','VIRUS DE LA HEPATITIS C (PCR)','8','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(1038,6,'4594','VIRUS SINCITIAL RESPIRATORIO','0','Exudado nasofaríngeo','Kit especial',NULL,NULL,NULL,1),
(1039,1,'291','VITAMINA  B12','4','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1040,5,'1809','VITAMINA A','10','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1041,1,'2267','VITAMINA B 1','10','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1042,2,'2268','VITAMINA B 6','15','Sangre total','Tubo lila',NULL,NULL,NULL,1),
(1043,6,'2806','VITAMINA D (25 OH CALCIFEROL)','0','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1044,13,'2810','VITAMINA D 1,25  TOTAL(CALCITRIOL)','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1045,1,'4324','VITAMINA D3','11','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1046,1,'2270','VITAMINA E (TOCOFEROL)','20',NULL,NULL,NULL,NULL,NULL,1),
(1047,1,'4651','VITAMINA K','20','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1048,12,'468','VULVA (BIOPSIA INCISIONAL)','8','Biopsia','Frasco especial patologia',NULL,NULL,NULL,1),
(1049,12,'472','VULVA (VULVECTOMIA POR CARCINOMA)','8','Pieza quirúrgica','Frasco patologia',NULL,NULL,NULL,1),
(1050,1,'2780','WESTERN BLOT PARA HEPATITIS C','5',NULL,NULL,NULL,NULL,NULL,1),
(1051,2,'293','WESTERN BLOT VIH 1 Y VIH 2','9','Sangre total EDTA','Tubo lila',NULL,NULL,NULL,1),
(1052,6,'2050','YODO PROTEICO','8','Suero 2 ml','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1),
(1053,2,'2836','ZIKA VIRUS RNA','3',NULL,NULL,NULL,NULL,NULL,1),
(1054,2,'295','ZINC EN ORINA','15',NULL,NULL,NULL,NULL,NULL,1),
(1055,1,'473','ZINC EN SUERO','7','Suero','Tubo amarillo o Tubo rojo',NULL,NULL,NULL,1);
UNLOCK TABLES;

-- =========================================================================
-- SEMILLAS SSOT PARA NAVEGACIÓN Y GABINETES (14 GABINETES Y 9 SUBGABINETES)
-- =========================================================================

-- 1. iGabinetes (Abanicos Principales)
LOCK TABLES `cat_igabinetes` WRITE;
INSERT IGNORE INTO `cat_igabinetes` (`id`, `nombre`, `orden`) VALUES
(1,'Grupo 1.1',1),
(2,'Grupo 2',2),
(3,'Grupo 3',3),
(4,'Grupo 4',4);
UNLOCK TABLES;

-- 2. Gabinetes Principales (14 Fondos Verdes Oficiales)
LOCK TABLES `cat_gabinetes` WRITE;
INSERT IGNORE INTO `cat_gabinetes` (`id`, `nombre`, `orden`) VALUES
(1,'Hematología',1),
(2,'Química Clínica',2),
(3,'Bacteriología',3),
(4,'Coagulación',4),
(5,'Inmunología',5),
(6,'Uroanálisis',6),
(7,'Endocrinología',7),
(8,'Marcadores Tumorales',8),
(9,'Gasometría Arterial y Venosa',9),
(10,'Citoquímicos',10),
(11,'Reumatología y Autoinmunidad',11),
(12,'Parasitología',12),
(13,'Biología Molecular',13),
(14,'Diversos',14);
UNLOCK TABLES;

-- 3. Subgabinetes (9 Fondos Gris/Azul Oficiales)
LOCK TABLES `cat_subgabinetes` WRITE;
INSERT IGNORE INTO `cat_subgabinetes` (`id`, `gabinete_id`, `nombre`, `orden`) VALUES
(1,2,'Electrolitos Séricos',1),
(2,2,'Función Hepática',2),
(3,2,'Lípidos',3),
(4,2,'Función Pancreática',4),
(5,2,'Función Cardiaca y Muscular',5),
(6,2,'Diabetes: Diagnóstico y Control',6),
(7,7,'Tiroides',1),
(8,7,'Hormonas Femeninas y Masculinas',2),
(9,2,'subg',999);
UNLOCK TABLES;

-- 4. Vinculaciones iGabinete -> Gabinetes / Subgabinetes
LOCK TABLES `rel_igabinete_vinculos` WRITE;
INSERT IGNORE INTO `rel_igabinete_vinculos` (`igabinete_id`, `gabinete_id`, `subgabinete_id`) VALUES
(1,2,1),
(1,2,2),
(1,2,3),
(1,2,4),
(1,2,5),
(1,2,6),
(2,2,NULL),
(3,7,7),
(3,7,8),
(3,9,NULL),
(4,1,NULL),
(4,4,NULL),
(4,6,NULL);
UNLOCK TABLES;

-- 5. Vinculaciones Estudio -> Gabinete (derivado de categoria_id — 1,055 filas)
-- Mapping aplicado en KVM2 2026-09-17: DELETE + INSERT SELECT con CASE por categoria_id.
DELETE FROM `rel_estudio_gabinete`;
INSERT INTO `rel_estudio_gabinete` (`estudio_id`, `gabinete_id`, `subgabinete_id`)
SELECT e.id,
  CASE
    WHEN e.categoria_id = 15          THEN 1   -- Hematología
    WHEN e.categoria_id = 4           THEN 2   -- Química Clínica
    WHEN e.categoria_id = 11          THEN 3   -- Bacteriología
    WHEN e.categoria_id IN (20,22)    THEN 4   -- Coagulación
    WHEN e.categoria_id IN (3,6,7)    THEN 5   -- Inmunología
    WHEN e.categoria_id = 10          THEN 6   -- Uroanálisis
    WHEN e.categoria_id = 14          THEN 12  -- Parasitología
    ELSE 14                                    -- Diversos (fallback)
  END,
  NULL
FROM `cat_estudios` e;

-- 5b. Reclasificación fina: estudios hormonales/tiroideos de Inmunología (5) -> Endocrinología (7)
-- Sin esto, cat_igabinetes id=3 (Grupo 3, ligado a subgabinetes 7/8 de Endocrinología) queda vacío.
UPDATE `rel_estudio_gabinete` reg
JOIN `cat_estudios` e ON e.id = reg.estudio_id
SET reg.gabinete_id = 7
WHERE reg.gabinete_id = 5
  AND UPPER(e.nombre) REGEXP 'TSH|TIROID|TIROXINA|TRIYODOTIRONINA|ESTRADIOL|TESTOSTERONA|PROGESTERONA|PROLACTINA|\\bFSH\\b|\\bLH\\b|CORTISOL|INSULINA|\\bPTH\\b|HORMONA|CAPTACION TIROIDEA';

-- 5c. Subgabinete dentro de Endocrinología (7): Tiroides (7) vs Hormonas (8)
UPDATE `rel_estudio_gabinete` reg
JOIN `cat_estudios` e ON e.id = reg.estudio_id
SET reg.subgabinete_id = CASE
    WHEN UPPER(e.nombre) REGEXP 'TSH|TIROID|TIROXINA|TRIYODOTIRONINA|\\bT3\\b|\\bT4\\b' THEN 7
    ELSE 8
  END
WHERE reg.gabinete_id = 7;

-- 5d. Subgabinete dentro de Química Clínica (2): Electrolitos/Hepática/Lípidos/Pancreática/Cardiaca/Diabetes
UPDATE `rel_estudio_gabinete` reg
JOIN `cat_estudios` e ON e.id = reg.estudio_id
SET reg.subgabinete_id = CASE
    WHEN UPPER(e.nombre) REGEXP 'GLUCOSA|GLICADA|HBA1C|CURVA DE TOLERANCIA|HOMA-IR|O.SULLIVAN|PERFIL GCT' THEN 6
    WHEN UPPER(e.nombre) REGEXP 'TROPONINA|CREATINFOSFOQUINASA|\\bCPK\\b|\\bCKMB\\b|DESHIDROGENASA L.CTICA|\\bDHL\\b|MIOGLOBINA|TRIAGE CARDIACO|PERFIL CORONARIO' THEN 5
    WHEN UPPER(e.nombre) REGEXP 'AMILASA|LIPASA' THEN 4
    WHEN UPPER(e.nombre) REGEXP 'COLESTEROL|TRIGLIC.RID|\\bLIPIDOS\\b|APOLIPOPROTEINA|ATEROGENICO' THEN 3
    WHEN UPPER(e.nombre) REGEXP 'HEPATIC|TRANSAMINASA|BILIRRUBINA|FOSFATASA ALCALINA|GAMMAGLUTAMIL|\\bGGT\\b|AMINO TRANSFERASA|COLINESTERASA|HEPATITIS' THEN 2
    WHEN UPPER(e.nombre) REGEXP 'ELECTROLITO|\\bSODIO\\b|\\bPOTASIO\\b|\\bCLORO\\b|\\bCALCIO\\b|\\bMAGNESIO\\b|\\bFOSFORO\\b|BICARBONATO|\\bCO2\\b|ION AMONIO|OSMOLARIDAD' THEN 1
    ELSE NULL
  END
WHERE reg.gabinete_id = 2
FROM `cat_estudios` e;

-- =========================================================================
-- SEMILLAS TOP 20 EST.MED (Selección Rápida de Estudios Principales)
-- Criterio: estudios in-house de mayor demanda clínica general en LAESH.
-- =========================================================================
UPDATE `cat_estudios` SET `top20_orden` = NULL;
UPDATE `cat_estudios` SET `top20_orden` =  1 WHERE `id` = 368;  -- CITOMETRIA HEMATICA (BHC)
UPDATE `cat_estudios` SET `top20_orden` =  2 WHERE `id` = 600;  -- GLUCOSA SERICA
UPDATE `cat_estudios` SET `top20_orden` =  3 WHERE `id` = 613;  -- HEMOGLOBINA GLICADA (HB A1c)
UPDATE `cat_estudios` SET `top20_orden` =  4 WHERE `id` = 427;  -- CREATININA SERICA
UPDATE `cat_estudios` SET `top20_orden` =  5 WHERE `id` = 1019; -- UREA SERICA
UPDATE `cat_estudios` SET `top20_orden` =  6 WHERE `id` = 392;  -- COLESTEROL TOTAL
UPDATE `cat_estudios` SET `top20_orden` =  7 WHERE `id` = 1005; -- TRIGLICERIDOS
UPDATE `cat_estudios` SET `top20_orden` =  8 WHERE `id` = 809;  -- PERFIL DE LIPIDOS
UPDATE `cat_estudios` SET `top20_orden` =  9 WHERE `id` = 821;  -- PERFIL HEPATICO (PFH)
UPDATE `cat_estudios` SET `top20_orden` = 10 WHERE `id` = 631;  -- HORMONA ESTIMULANTE DE TIROIDES (TSH)
UPDATE `cat_estudios` SET `top20_orden` = 11 WHERE `id` = 886;  -- PROTEINA C REACTIVA CUANTITATIVA
UPDATE `cat_estudios` SET `top20_orden` = 12 WHERE `id` = 510;  -- ELECTROLITOS SERICOS (Na, K, Cl, Ca)
UPDATE `cat_estudios` SET `top20_orden` = 13 WHERE `id` = 535;  -- EXAMEN GENERAL DE ORINA CUANTITATIVO
UPDATE `cat_estudios` SET `top20_orden` = 14 WHERE `id` = 459;  -- CULTIVO DE ORINA (UROCULTIVO)
UPDATE `cat_estudios` SET `top20_orden` = 15 WHERE `id` = 412;  -- COPROPARASITOSCOPICO 1M (CPS)
UPDATE `cat_estudios` SET `top20_orden` = 16 WHERE `id` = 1033; -- VELOCIDAD DE SEDIMENTACION G. (VSG)
UPDATE `cat_estudios` SET `top20_orden` = 17 WHERE `id` = 845;  -- PERFIL TIROIDEO 1
UPDATE `cat_estudios` SET `top20_orden` = 18 WHERE `id` = 598;  -- GLUCOSA BASAL y POSTPRANDIAL
UPDATE `cat_estudios` SET `top20_orden` = 19 WHERE `id` = 839;  -- PERFIL RENAL COMPLETO
UPDATE `cat_estudios` SET `top20_orden` = 20 WHERE `id` = 599;  -- GLUCOSA POST PRANDIAL


-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Contenido Editorial
-- SSOT: exportado de BD local (laesh_db) — 2026-09-17 15:25
-- Regenerar con: bash setup/bds/laesh/bash/cms-sync/04_export_cms_seed.sh
-- REPLACE INTO garantiza que el seed siempre sobreescriba ediciones CMS.
-- ---------------------------------------------------------------------------

REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('aviso-privacidad','contenido','cuerpo_html','<p class="modal-p" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 1rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><strong style="box-sizing:border-box;margin:0px;padding:0px;">LABORATORIO </strong><span style="color:#71CA11;"><strong style="box-sizing:border-box;margin:0px;padding:0px;">LAESH</strong></span>, con domicilio en Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.2, es responsable del tratamiento, uso, protección y resguardo de los datos personales que recaba de sus pacientes, usuarios y personas que solicitan nuestros servicios.</p><h4 class="aviso-h4" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">1. Datos personales que recabamos</h4><ul class="aviso-list" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.75rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Nombre completo.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Fecha de nacimiento y edad.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Sexo.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Datos de contacto, como teléfono, correo electrónico y domicilio.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Datos relacionados con la atención y solicitud de estudios de laboratorio.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Información necesaria para la identificación y entrega de resultados.</li></ul><p class="modal-p--main" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><strong>Datos personales sensibles</strong></p><p class="aviso-p aviso-p--sm" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">Por la naturaleza de nuestros servicios, podremos tratar datos personales sensibles relacionados con el estado de salud. Estos datos serán tratados con medidas de seguridad y confidencialidad.</p><h4 class="aviso-h4" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">2. Finalidades del tratamiento</h4><ol class="aviso-list" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.75rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Identificar y registrar al paciente.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Solicitar, procesar y entregar estudios de laboratorio.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Elaborar y conservar los resultados correspondientes.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Dar seguimiento a los servicios solicitados.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Atender dudas, aclaraciones o solicitudes relacionadas con sus resultados.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Cumplir con las obligaciones legales y sanitarias aplicables.</li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Mantener registros administrativos, contables y relacionados con la prestación del servicio.</li></ol><h4 class="aviso-h4" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">3. Protección y confidencialidad</h4><p class="aviso-p aviso-p--sm" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">Laboratorio LAESH implementa medidas administrativas, técnicas y físicas destinadas a proteger los datos personales contra daño, pérdida, alteración, destrucción, acceso o tratamiento no autorizado.</p><h4 class="aviso-h4" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">4. Derechos ARCO</h4><p class="aviso-p aviso-p--sm" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">Usted tiene derecho a Acceder, Rectificar, Cancelar u Oponerse al tratamiento de sus datos personales. Para ejercer estos derechos contáctenos por:</p><ul class="aviso-list aviso-list--sm" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.5rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Correo: <a class="txt-primary-c" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;" href="mailto:11lab_laesh@hotmail.com">11lab_laesh@hotmail.com</a></li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Teléfono: <strong style="box-sizing:border-box;margin:0px;padding:0px;">953 688 769410</strong></li><li style="box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;">Domicilio: Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.2</li></ul><h4 class="aviso-h4" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">5. Modificaciones</h4><p class="aviso-p aviso-p--sm" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">Laboratorio LAESH podrá modificar este Aviso cuando resulte necesario. Las modificaciones estarán disponibles en nuestro sitio web.</p><p class="modal-p--sm" style="-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.8rem;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0px 0px 1rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><i>Última actualización: agosto de 2026</i></p><div class="highlight-block" style="-webkit-text-stroke-width:0px;background-color:rgba(113, 202, 17, 0.06);border-left:3px solid rgb(113, 202, 17);border-radius:0px 6px 6px 0px;box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0.5rem 0px 0px;orphans:2;padding:0.85rem 1rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><p class="modal-p--pgd" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.88rem;margin:0px 0px 0.35rem;padding:0px;"><strong>Consentimiento</strong></p><p class="modal-p--tail" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.7;margin:0px;padding:0px;">Declaro que he leído y comprendido el presente Aviso de Privacidad y manifiesto mi consentimiento para el tratamiento de mis datos personales para las finalidades señaladas.</p></div>','html');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery1','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery1','descripcion','Análisis de biometría hemática y células sanguíneas con rigor científico y alta precisión.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery1','imagen_url','/laesh-web-assets-uipv1a/cms/calidad-gallery1-20260913-153fe798.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery1','titulo','Área de Hematología','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery2','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery2','descripcion','Determinación automatizada de metabolitos, perfil lipídico y enzimas específicas.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery2','imagen_url','/laesh-web-assets-uipv1a/cms/calidad-gallery2-20260913-9d7a6baf.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery2','titulo','Química Clínica','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery3','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery3','descripcion','Aislamiento, tinción de Gram y pruebas de susceptibilidad a antimicrobianos.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery3','imagen_url','/laesh-web-assets-uipv1a/cms/calidad-gallery3-20260913-a20bc539.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','gallery3','titulo','Microbiología y Cultivos','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','seccion','h2','Calidad e Instalaciones','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad','seccion','subtitulo','Conoce nuestras instalaciones equipadas con tecnología de vanguardia y un equipo comprometido con la excelencia diagnóstica.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel1','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel1','texto','<h3>Hematología Especializada</h3><p>Análisis morfológico de frotis sanguíneo y pruebas hematológicas de alta complejidad.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel10','activo','0','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel10','texto','<h3>Toma Pediátrica</h3><p>Espacio amigable y personal capacitado para el cuidado y tranquilidad de los niños.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel11','activo','0','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel11','texto','<h3>Toma de Cultivos</h3><p>Zonas aisladas y estériles para la toma de exudados y cultivos microbiológicos.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel12','activo','0','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel12','texto','<h3>Recepción Técnica</h3><p>Recepción técnica de muestras e indicaciones pre-analíticas detalladas.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel13','activo','0','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel13','texto','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel14','activo','0','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel14','texto','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel15','activo','0','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel15','texto','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel16','activo','0','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel16','texto','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel2','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel2','texto','<h3>Química Clínica Avanzada</h3><p>Determinación automatizada de electrolitos, proteínas y enzimas específicas.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel3','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel3','texto','<h3>Microbiología y Cultivos</h3><p>Identificación microscópica y pruebas de susceptibilidad a antimicrobianos.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel4','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel4','texto','<h3>Uroanálisis y Sedimentos</h3><p>Examen de orina, química y microscopía para detección precoz de patologías renales.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel5','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel5','texto','<h3>Hemostasia y Coagulación</h3><p>Estudios de tiempos de protrombina (TP) y tromboplastina parcial activada (TTPa).</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel6','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel6','texto','<h3>Pruebas Especiales</h3><p>Hormonas, anticuerpos específicos, pruebas inmunológicas y marcadores tumorales.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel7','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel7','texto','<h3>Pre-analítica</h3><p>Separación de suero y plasma con control estricto de tiempos y temperaturas.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel8','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel8','texto','<h3>Toma de Muestras I</h3><p>Áreas higiénicas equipadas para la extracción sanguínea convencional.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel9','activo','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','carousel9','texto','<h3>Toma de Muestras II</h3><p>Módulos individuales y confortables que aseguran una atención rápida y sin molestias.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','catalogo','nota_pie','Listas de Estudios disponibles 2026 · Haz clic en cada grupo para expandir','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','cg1','fichas','[Hematología] Citometría Hemática, Grupo y RH, Plaquetas, VSG, Reticulocitos, Perfil de Hierro,\\n[Química Clínica] QS3, QS7, Perfil Bioquímico 15/24/30/35/45, Glucosa, Creatinina, Colesterol, Triglicéridos,\\n[Electrolitos Séricos] ES 3/4/Completos, Calcio, Fósforo, Magnesio, Bicarbonato CO2,\\n[Uroanálisis] EGO + Radio Prot/Crea, EGO Especializado, Antidoping 5/12 elem.,\\n[Coagulación] Perfil de Coagulación, TP/INR, TTPa, Fibrinógeno, Dímero D, T. Sangrado,\\n[Lípidos] Perfil de Lípidos I, II, Perfil Aterogénico','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','cg1','titulo','Rutina General — Hematología, Química Clínica, Electrolitos, Uroanálisis, Coagulación','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','cg2','fichas','[Función Hepática] PFH Básico, PFH Completo, Transaminasas, GGT, Proteínas Totales, Albumina,\\n[Función Tiroidea] Perfil Tiroideo I-IV, TSH, Ac. Anti Tiroideos I-II, Ac. Anti Receptor TSH, Tiroglobulina,\\n[Función Pancreática] Amilasa sérica, Lipasa sérica,\\n[Función Renal] Cistatina C, Depuración creatinina, Proteínas orina, Microalbuminuria,\\n[Función Cardiaca] Triage cardiaco, Perfil cardiaco completo, Troponina I, Troponina T, NT-pro BNP, Mioglobina,\\n[Gasometría] Gasometría Arterial Completa, Gasometría Venosa Completa','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','cg2','titulo','Función de Órganos — Hepática, Tiroidea, Pancreática, Renal, Cardiaca, Gasometría','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','cg3','fichas','[Hormonas] Perfil Ginecológico I-II, Perfil Hormonal Masculino, FSH, LH, PRL, PROG, TESTOSTERONA Total/Libre, DHEA-S, Cortisol, AMH, PTH-i,\\n[Diabetes] HbA1c, Insulina, HOMA-IR, Péptido C, Prueba de Tolerancia Glucosa, Test O\'Sullivan,\\n[Inmunología] HIV 1/2, V.D.R.L., Reacciones Febriles, Hepatitis A-B-C, Dengue, COVID-19, Coombs, Procalcitonina,\\n[Reumatología] Perfil Reumático, PCR, Factor Reumatoide, CCP, ANA, Anti DNA, Complementos C3/C4,\\n[Diversos] Vitamina D, Inmunoglobulina E, Somatomedina C, Papanicolaou','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','cg3','titulo','Hormonas, Diabetes e Inmunología — Perfil Ginecológico, Masculino, Diabetes, Inmunología, Reumatología','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','cg4','fichas','[Bacteriología] Cultivo de orina MIC, Ex. Faríngeo MIC, Ex. Vaginal MIC, Uretral MIC, Heces MIC, Lesión MIC, Expectoración MIC, Hemocultivo MIC, Cultivo Micológico,\\n[Marcadores Tumorales] PSA Total, PSA Libre, CEA, AFP, CA-125, CA-15-3, CA-19-9, Perfil Tumoral Femenino/Masculino,\\n[Parasitología] Coproparasitoscópico 3 muestras, Coprológico completo/especial, Sangre Oculta, H. Pylori, Calprotectina, Lactoferrina, Clostridium difficile,\\n[Citroquímicos] LCR, Sinovial, Pleural, Ascitis, Diálisis, Bronquial, Pericárdico,\\n[Biología Molecular] PCR VPH, PCR Mycobacterium, PCR Patógenos respiratorios, PCR Meningitis viral, PCR SARS-CoV-2,\\n[Fertilidad] Espermatobioscopia directa','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','cg4','titulo','Bacteriología, Marcadores Tumorales, Parasitología, Citroquímicos, Biología Molecular, Fertilidad','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel1_img','/laesh-web-assets-uipv1a/cms/carousel-1-20260913-3812b189.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel10_img','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel11_img','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel12_img','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel13_img','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel14_img','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel15_img','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel16_img','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel2_img','/laesh-web-assets-uipv1a/cms/carousel-2-20260913-d7792cf6.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel3_img','/laesh-web-assets-uipv1a/cms/carousel-3-20260913-45b622da.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel4_img','/laesh-web-assets-uipv1a/cms/carousel-4-20260913-6575c21d.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel5_img','/laesh-web-assets-uipv1a/cms/carousel-5-20260913-f6fd1e35.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel6_img','/laesh-web-assets-uipv1a/cms/carousel-6-20260913-27547b50.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel7_img','/laesh-web-assets-uipv1a/cms/carousel-7-20260913-ba912813.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel8_img','/laesh-web-assets-uipv1a/cms/carousel-8-20260913-9c329782.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','config','carousel9_img','/laesh-web-assets-uipv1a/cms/carousel-9-20260913-4fa2ebaa.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','seccion','h2','Estudios de Rutina y Especialidades','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades','seccion','subtitulo','Servicios clínicos diseñados con rigor científico para garantizar la máxima confiabilidad en el diagnóstico médico','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('footer','contenido','cuerpo_html','<div class="footer-info"><p><img class="footer-logo-img" style="max-height:40px;width:auto;" src="/laesh-web-assets-uipv1a/img/logo-laesh.webp" alt="LAESH Laboratorio de Especialidades Hematológicas" decoding="async" loading="lazy"></p><p class="footer-text"><span style="color:#0052B7;"><strong>Laboratorio de Especialidades Hematológicas S.C.</strong> &nbsp;|&nbsp; Azucenas No. 8, Col. Jardines del Sur, Huajuapan de León, Oax. &nbsp;|&nbsp; Tel: </span><a href="tel:9535320268"><span style="color:#0052B7;">953 532 0268</span></a><span style="color:#0052B7;"> &nbsp;|&nbsp; WhatsApp: </span><a href="https://wa.me/529531190074" target="_blank" rel="noopener noreferrer"><span style="color:#0052B7;">953 119 0074</span></a></p><p class="footer-text"><span style="color:#0052B7;">Lunes a Sábado 7:00 a 20:00 hrs &nbsp;·&nbsp; Domingo 8:00 a 14:00 hrs &nbsp;|&nbsp; </span><a href="#" id="link-privacy"><span style="color:#0052B7;">Aviso de Privacidad</span></a><span style="color:#0052B7;"> &nbsp;|&nbsp; © 2026 LAESH. Todos los derechos reservados</span>.</p></div>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('footer','estilo','bg_color','#71ca11','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','config','fixed_image','1','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','config','slider_mode','sync','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','config','transition_time','8','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','navbar','tagline_l1','Diagnósticos de','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','navbar','tagline_l2','Confianza y Calidad','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide1','cta_href','#especialidades','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide1','cta_texto','Conoce los Servicios','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide1','descripcion','Ofrecemos servicios integrales de análisis clínicos especializados con precisión científica y calidez humana.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide1','etiqueta','Un laboratorio seguro con Resultados ConfiablesB','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide1','imagen_url','/laesh-web-assets-uipv1a/cms/hero-slide1-20260913-df21da66.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide1','titulo','Laboratorio de Especialidades Hematológicas','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide2','cta_href','#especialidades','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide2','cta_texto','Ver Especialidades','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide2','descripcion','Detrás de cada resultado hay una decisión. Por eso, en LAESH® la calidad no es una opción: es nuestro compromiso.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide2','etiqueta','25 Años de Experiencia Clínica','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide2','imagen_url','/laesh-web-assets-uipv1a/cms/hero-slide2-20260913-aeb9f22d.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide2','titulo','Un laboratorio seguro con Resultados Confiables','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide3','cta_href','#calidad','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide3','cta_texto','Conocer Calidad','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide3','descripcion','Detrás de cada análisis existe una decisión médica crucial. En LAESH® la precisión diagnóstica es nuestro compromiso inquebrantable.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide3','etiqueta','Excelencia y Calidad Certificada','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide3','imagen_url','/laesh-web-assets-uipv1a/cms/hero-slide3-20260913-240ddec0.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide3','titulo','Resultados Confiables para Cuidar tu Salud','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide4','cta_href','#promociones','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide4','cta_texto','Ver Promociones','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide4','descripcion','Descubre nuestros paquetes preventivos y tarifas especiales diseñadas para el cuidado integral de tu salud y la de toda tu familia.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide4','etiqueta','Tarifas y Paquetes Preferenciales','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide4','imagen_url','/laesh-web-assets-uipv1a/cms/hero-slide4-20260913-60baaecb.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide4','titulo','Promociones y Check-Ups Médicos 2026','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide5','cta_href','#ubicacion','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide5','cta_texto','Ver Ubicación','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide5','descripcion','Visítanos en Azucenas 8, Jardines del Sur, Huajuapan de León. Lunes a sábado 7:00 a.m. – 9:00 p.m.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide5','etiqueta','Atención Presencial y Horarios','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide5','imagen_url','/laesh-web-assets-uipv1a/cms/hero-slide5-20260913-615eeaf9.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero','slide5','titulo','Ubicación, Horarios de Atención y Contacto','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('promociones','banner','subtitulo','Aprovecha nuestras tarifas preferenciales y paquetes diseñados para ti.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('promociones','banner','titulo','Promociones Vigentes','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('quienes-somos','ficha1','texto','<h3 class="acerca-h3b" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);flex-shrink:0;font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.75rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">🔵 25 años de experiencia al servicio del diagnóstico</h3><div class="modal-scroll-body" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0px;max-height:320px;orphans:2;overflow-y:auto;padding:0px 8px 0px 0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">LAESH, Laboratorio de Especialidades Hematológicas, es una empresa 100% de la Región Mixteca, fundada en septiembre de 2022 en Huajuapan de León, Oaxaca, con el propósito de ofrecer servicios de laboratorio clínico confiables, especializados y de alta calidad para médicos y pacientes.</p><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">Nuestra experiencia está respaldada por <strong class="txt-green" style="box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;">25 años</strong> de trayectoria profesional, un equipo de químicos especialistas con estudios de posgrado y especialización en Hematología Diagnóstica por Laboratorio, así como por la actualización permanente de nuestras pruebas y perfiles de acuerdo con las guías de práctica clínica y recomendaciones actuales.</p><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">Contamos con un amplio catálogo de estudios, desde análisis de rutina hasta pruebas altamente especializadas, apoyados en equipos de nueva generación, procesos de calidad y personal capacitado para proporcionar resultados confiables y clínicamente relevantes.</p><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">Nuestro compromiso con la calidad se refleja en nuestra participación en programas de evaluación externa, donde hemos obtenido calificaciones de <strong class="txt-primary-c" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">EXCELENCIA</strong>, así como en el <strong class="txt-green" style="box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;">Galardón Rey PACAL</strong>, reconocimiento relacionado con nuestro desempeño dentro de los laboratorios evaluados.</p><hr><p class="txt-pgd-sm" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;"><strong>Nuestro compromiso</strong></p><p class="faq-p--sm2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;">En LAESH trabajamos para que cada resultado sea una herramienta útil para el médico y una fuente de confianza para el paciente.</p><hr><p class="txt-pgd-sm" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;"><strong>Nuestro responsable sanitario</strong></p><p class="faq-p--text" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.5rem;padding:0px;"><strong class="txt-main" style="box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;">Q.F.B. y E.H.D.L. Jacob Santiago Blanco</strong><br>Químico Farmacéutico Biólogo egresado de la Universidad Autónoma de Sinaloa, con especialidad en Hematología Diagnóstica por Laboratorio por el Instituto de Hematopatología.</p><p class="faq-p--text2" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.84rem;line-height:1.6;margin:0px 0px 0.9rem;padding:0px;">Cédula Profesional: <strong class="txt-main" style="box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;">3609293</strong> &nbsp;|&nbsp; Cédula de Especialidad: <strong class="txt-main" style="box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;">8935780</strong><br>Con <strong class="txt-green" style="box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;">25 años</strong> de experiencia profesional, su trayectoria representa uno de los principales pilares de la calidad y especialización de LAESH.</p><hr><p class="txt-pgd-sm" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;"><strong>🧬 Nuestra filosofía</strong></p><p class="faq-p--primary" style="box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.5rem;padding:0px;"><strong>Resultados que dan confianza, decisiones que cuidan.</strong></p><p class="faq-p--tail" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px;padding:0px;">En LAESH entendemos que detrás de cada muestra existe una persona y detrás de cada resultado existe una decisión clínica. Por ello, trabajamos para ofrecer información diagnóstica confiable, oportuna y clínicamente relevante, que ayude al médico a tomar mejores decisiones y al paciente a recibir una atención adecuada.</p></div>','html');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('quienes-somos','ficha2','texto','<h3 class="txt-pgd-sub" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.6rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">🔵 MISIÓN 🔵</h3><p class="aviso-p aviso-p--muted" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">Brindar resultados confiables y clínicamente relevantes que ayuden al médico a tomar mejores decisiones y al paciente a recibir una atención oportuna y segura.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('quienes-somos','ficha3','texto','<h3 class="txt-pgd-sub" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.6rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">🟢 VISIÓN 🟢</h3><p class="aviso-p aviso-p--muted" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">Ser el laboratorio de referencia para médicos y pacientes, reconocido por la excelencia de nuestros resultados, la especialización de nuestro equipo y nuestro compromiso permanente con la calidad.</p>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('quienes-somos','ficha4','texto','<h3 class="acerca-h3" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.85rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;">🟢 ¿ POR QUÉ CONFIAR EN LAESH <sup style="box-sizing:border-box;margin:0px;padding:0px;">® </sup>? 🟢</h3><div class="acerca-flex" style="-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(15, 23, 42);display:flex;flex-direction:column;font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;gap:7px;letter-spacing:normal;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;"><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-c fw-bold" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">25 años</strong> de experiencia</p><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-bold" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">Químicos especialistas</strong> con estudios de posgrado</p><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-bold" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">Guías de práctica clínica</strong> — pruebas y perfiles actualizados</p><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-bold" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">Excelencia</strong> en programas de control de calidad externo</p><p class="faq-p--muted" style="box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;"><strong class="txt-primary-c" style="box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;">Galardón Rey PACAL</strong> — reconocimiento a nuestro desempeño</p></div>','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('quienes-somos','seccion','h2','Quiénes somos','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('quienes-somos','seccion','subtitulo','La calidad de un resultado también se mide por la confianza que genera 25 años transformando resultados en decisiones clínicas.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo','meta','description','Análisis clínicos especializados: hematología, bioquímica, inmunología, bacteriología y biología molecular en Huajuapan de León, Oaxaca.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo','meta','title','LAESH — Laboratorio de Especialidades Hematológicas en Huajuapan de León, Oaxaca','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo','og','og_description','Diagnósticos clínicos de alta precisión con resultados confiables. Visítanos en Huajuapan de León, Oaxaca.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo','og','og_image','/laesh-web-assets-uipv1a/cms/seo-og-20260913-1ab2c531.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo','og','og_title','LAESH — Laboratorio de Especialidades Hematológicas','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo','og','site_name','','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo','schema','schema_name','Laboratorio de Especialidades Hematológicas LAESH','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo','schema','schema_type','MedicalLaboratory','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('ubicacion','croquis','imagen_url','/laesh-web-assets-uipv1a/cms/ubicacion-croquis-20260913-0a4f3643.webp','imagen_url');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('ubicacion','seccion','h2','Ubicación y Contacto','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('ubicacion','seccion','subtitulo','Visítenos en nuestras instalaciones, será un placer atenderle.','texto');
REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('video-promo','contenido','cuerpo_html','<h2 style="text-align:center;"><span style="color:#71CA11;">Promo 2025</span></h2><figure class="media"><div data-oembed-url="https://youtu.be/6lkvdY6nAm4?si=E-Fk2UKWMcLDwl5W"><div style="position: relative; padding-bottom: 100%; height: 0; padding-bottom: 56.2493%;"><iframe src="https://www.youtube.com/embed/6lkvdY6nAm4" style="position: absolute; width: 100%; height: 100%; top: 0; left: 0;" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen=""></iframe></div></div></figure>','texto');

-- ---------------------------------------------------------------------------
-- CATALOGO_PROMOCIONES — 7 días de la semana
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `catalogo_promociones` (`id`, `dia_semana`, `imagen_fondo`, `activo`, `orden`) VALUES
(1,'<h2 style="text-align:center;">Lunes</h2>','/laesh-web-assets-uipv1a/cms/promo-1-20260913-27600325.webp',1,1),
(2,'<p>Martes</p>','/laesh-web-assets-uipv1a/cms/promo-2-20260913-36fd13bd.webp',1,2),
(3,'<p>Miércoles</p>',NULL,1,3),
(4,'<p>Jueves</p>',NULL,1,4),
(5,'<p>Viernes</p>',NULL,1,5),
(6,'<p>Sábado</p>',NULL,1,6),
(7,'<p>Domingo</p>',NULL,1,7);
