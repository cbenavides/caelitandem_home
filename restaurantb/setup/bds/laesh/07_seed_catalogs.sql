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
    ('direccion',               'Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.',
                                 'Dirección física — reutilizada en Ubicación, Footer y Schema.org'),
    ('cp',                      '69007',
                                 'Código postal — Schema.org postalCode'),
    ('telefono',                '953 688 7694',
                                 'Teléfono directo — reutilizado en Ubicación, Footer y Schema.org'),
    ('email_contacto',          'lab_laesh@hotmail.com',
                                 'Correo de contacto público — reutilizado en Ubicación y Footer'),
    ('whatsapp_url',            'https://wa.me/529531190074',
                                 'Enlace de WhatsApp con código de país — D-04: vive en configuraciones'),
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
    ('maps_embed_url',          'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3773.7375!2d-97.7779575!3d17.8028691!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x85c60141d7aa4483%3A0x730f884bc7308bee!2sLaboratorio%20de%20Especialidades%20Hematol%C3%B3gicas%20S.C.!5e0!3m2!1ses!2smx!4v1724000000000!5m2!1ses!2smx',
                                 'Embed URL Google Maps con Place ID — iframe data-src en index.php sección #ubicacion'),
    -- Operaciones internas
    ('tiempo_rotacion_dias',    '90',
                                 'Días de validez antes de solicitar cambio de contraseña (admin policy)'),
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
-- ESTUDIOS — Catálogo completo extraído de medicos.html
-- Fuente: checkboxes name="estudio_item" data-fp="{grupo}"
-- Regla D-02: categoria (labadmin internal) + tipo_web (website grouping).
-- D-08: precio, ayuno_descripcion, tiempo_resultado → badges de catalog-card-day (index.php)
--       y autocomplete input-buscar-estudio-ficha (medicos.php).
-- SSOT: clave (ej. HEM-01) referenciada en web_contenidos/promociones/{dia}/estudio_clave.
--       muestra_requerida y preparacion_paciente → modal-estudio en labadmin.php.
-- ---------------------------------------------------------------------------

-- HEMATOLOGÍA — Estudios de fichas diarias: con precio, badges, clave y muestra SSOT
INSERT IGNORE INTO `estudios`
    (`nombre`, `categoria`, `tipo_web`, `precio`, `ayuno_descripcion`, `tiempo_resultado`, `clave`, `muestra_requerida`, `orden`)
VALUES
    ('Citometría Hemática',                'Hematología', 'rutina',  190.00, '8 hrs ayuno',    'Resultado 24 hrs',  'HEM-01', 'Sangre total — tubo EDTA (lila)',                   1),
    ('Grupo Sanguíneo y factor Rh',        'Hematología', 'rutina',   90.00, 'Sin ayuno',      'Resultado 2 hrs',   'HEM-02', 'Sangre total — tubo EDTA (lila)',                   2),
    ('Plaquetas',                          'Hematología', 'rutina',  150.00, 'Sin ayuno',      'Resultado 4 hrs',   'HEM-03', 'Sangre total — tubo EDTA (lila)',                   3),
    ('Velocidad de Sedimentación Globular','Hematología', 'rutina',  120.00, 'Sin ayuno',      'Resultado 4 hrs',   'HEM-04', 'Sangre total — tubo EDTA (lila)',                   4),
    ('Reticulocitos',                      'Hematología', 'rutina',  170.00, 'Sin ayuno',      'Resultado 6 hrs',   'HEM-05', 'Sangre total — tubo EDTA (lila)',                   5),
    ('Perfil de Hierro (Cinética)',        'Hematología', 'rutina', 1000.00, '8–12 hrs ayuno', 'Resultado 24 hrs',  'HEM-06', 'Sangre total — tubo seco (rojo) o SST (amarillo)', 6),
    ('Biometría Hemática Completa',        'Hematología', 'rutina',  NULL,   NULL,             NULL,                NULL,     NULL,                                                 7),
    ('Perfil de Coagulación (TP/INR y TTP)','Hematología','rutina',  NULL,   NULL,             NULL,                NULL,     NULL,                                                 8),
    ('Fibrinógeno',                        'Hematología', 'rutina',  NULL,   NULL,             NULL,                NULL,     NULL,                                                 9),
    ('Dímero D',                           'Hematología', 'rutina',  NULL,   NULL,             NULL,                NULL,     NULL,                                                10);

-- UROANÁLISIS
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('EGO — Radio prU/CrU',                  'Uroanálisis', 'rutina', 10),
    ('EGO Cribado Renal — Radio Alb/Crea',   'Uroanálisis', 'rutina', 11);

-- INMUNOLOGÍA
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Ac. Anti VIH',                         'Inmunología', 'rutina', 20),
    ('V.D.R.L.',                             'Inmunología', 'rutina', 21),
    ('Prueba de Embarazo',                   'Inmunología', 'rutina', 22),
    ('Hepatitis A',                          'Inmunología', 'rutina', 23),
    ('Hepatitis B',                          'Inmunología', 'rutina', 24),
    ('Hepatitis C',                          'Inmunología', 'rutina', 25);

-- INMUNOLOGÍA — Hormonas (endocrinología)
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Perfil Ginecológico 1',                'Inmunología', 'check_up', 30),
    ('Perfil Ginecológico 2',                'Inmunología', 'check_up', 31),
    ('Perfil Hormonal Masculino',            'Inmunología', 'check_up', 32),
    ('Testosterona Libre',                   'Inmunología', 'check_up', 33),
    ('Cortisol',                             'Inmunología', 'check_up', 34),
    ('DHEA-S',                               'Inmunología', 'check_up', 35),
    ('HGC Cuantitativa',                     'Inmunología', 'check_up', 36),
    ('AMH (Hormona Anti Mülleriana)',        'Inmunología', 'check_up', 37);

-- INMUNOLOGÍA — Infectología (serología)
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Procalcitonina',                       'Inmunología', 'rutina', 40),
    ('Dengue (NS1, IgG, IgM)',              'Inmunología', 'rutina', 41),
    ('Panel Viral Respiratorio',             'Inmunología', 'rutina', 42);

-- INMUNOLOGÍA — Reumatología (anticuerpos)
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Perfil Reumático',                     'Inmunología', 'check_up', 50),
    ('CCP (Anti Péptido Cíclico Citrulinado)', 'Inmunología', 'check_up', 51),
    ('Ac. Anti Nucleares por IFI',           'Inmunología', 'check_up', 52),
    ('Proteína C Reactiva',                  'Inmunología', 'rutina',   53),
    ('Factor Reumatoide',                    'Inmunología', 'rutina',   54);

-- BIOQUÍMICA — Diabetes
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Hemoglobina Glicada (A1c) HPLC',      'Bioquímica', 'rutina',   60),
    ('Resistencia a la Insulina (HOMA-IR)', 'Bioquímica', 'check_up', 61);

-- BIOQUÍMICA — Función hepática y perfil bioquímico
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Química Sanguínea 7E',                'Bioquímica', 'rutina',   70),
    ('Química Sanguínea Parcial 3E',        'Bioquímica', 'rutina',   71),
    ('Perfil Bioquímico 15 Elementos',      'Bioquímica', 'check_up', 72);

-- BIOQUÍMICA — Electrolitos
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Electrolitos Séricos Na+, K+, Cl-, Ca++, P, Mg', 'Bioquímica', 'rutina', 80);

-- BIOQUÍMICA — Cardiaca
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Perfil Cardiaco Completo',             'Bioquímica', 'check_up', 90),
    ('Troponinas (I y T)',                   'Bioquímica', 'check_up', 91),
    ('NT-pro BNP',                           'Bioquímica', 'check_up', 92);

-- BIOQUÍMICA — Tiroidea
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Perfil Tiroideo 1 (TSH, T4 y T3)',    'Bioquímica', 'check_up', 100),
    ('Perfil Tiroideo Completo',             'Bioquímica', 'check_up', 101),
    ('TSH',                                  'Bioquímica', 'rutina',   102),
    ('T4 Libre',                             'Bioquímica', 'rutina',   103),
    ('Ac. Anti Tiroideos 1',                 'Bioquímica', 'check_up', 104),
    ('Ac. Anti Receptor de TSH (TRAb)',     'Bioquímica', 'check_up', 105),
    ('Tiroglobulina',                        'Bioquímica', 'check_up', 106);

-- BIOQUÍMICA — Lípidos
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Perfil de Lípidos I',                  'Bioquímica', 'check_up', 110);

-- BIOQUÍMICA — Tumorales
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('PSA Total',                            'Bioquímica', 'check_up', 120),
    ('CEA',                                  'Bioquímica', 'check_up', 121),
    ('AFP',                                  'Bioquímica', 'check_up', 122),
    ('CA-125',                               'Bioquímica', 'check_up', 123),
    ('CA-15-3',                              'Bioquímica', 'check_up', 124),
    ('CA-19-9',                              'Bioquímica', 'check_up', 125);

-- BIOQUÍMICA — PFH
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('PFH Básico',                           'Bioquímica', 'rutina',   130),
    ('PFH Completo',                         'Bioquímica', 'check_up', 131);

-- OTROS — Parasitología
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Coprológico',                          'Otros', 'rutina', 140),
    ('Coprológico Especial',                 'Otros', 'rutina', 141),
    ('Sangre Oculta en Heces',              'Otros', 'rutina', 142),
    ('Calprotectina en Heces',              'Otros', 'rutina', 143),
    ('Lactoferrina en Heces',               'Otros', 'rutina', 144),
    ('Antígeno de H. Pylori en Heces',      'Otros', 'rutina', 145);

-- OTROS — Gasometrías
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Gasometría Arterial',                  'Otros', 'rutina', 150),
    ('Gasometría Venosa',                    'Otros', 'rutina', 151);

-- OTROS — Bacteriología
INSERT IGNORE INTO `estudios` (`nombre`, `categoria`, `tipo_web`, `orden`) VALUES
    ('Cultivo de Orina con MIC',             'Otros', 'rutina', 160),
    ('Cultivo de Exudado Faríngeo',          'Otros', 'rutina', 161),
    ('Cultivo de Exudado Vaginal con MIC',  'Otros', 'rutina', 162);

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Solo contenido editorial no derivable de entidades o config
-- REGLA SSOT: NO insertar aquí datos que ya viven en configuraciones o estudios.
-- ---------------------------------------------------------------------------

-- Panel 1: Hero / Banner Principal (Slide 1–5)
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero', 'slide1', 'etiqueta',    'Un laboratorio seguro con Resultados Confiables',    'texto'),
    ('hero', 'slide1', 'titulo',      'Laboratorio de Especialidades Hematológicas',         'texto'),
    ('hero', 'slide1', 'descripcion', 'Ofrecemos servicios integrales de análisis clínicos especializados con precisión científica y calidez humana.', 'texto'),
    ('hero', 'slide2', 'titulo',      'Un laboratorio seguro con Resultados Confiables',     'texto'),
    ('hero', 'slide2', 'descripcion', 'Detrás de cada resultado hay una decisión. Por eso, en LAESH® la calidad no es una opción: es nuestro compromiso.', 'texto'),
    ('hero', 'slide3', 'etiqueta',    'Excelencia y Calidad Certificada',                    'texto'),
    ('hero', 'slide3', 'titulo',      'Resultados Confiables para Cuidar tu Salud',          'texto'),
    ('hero', 'slide3', 'descripcion', 'Detrás de cada análisis existe una decisión médica crucial. En LAESH® la precisión diagnóstica es nuestro compromiso inquebrantable.', 'texto'),
    ('hero', 'slide4', 'etiqueta',    'Tarifas y Paquetes Preferenciales',                   'texto'),
    ('hero', 'slide4', 'titulo',      'Promociones y Check-Ups Médicos 2026',                'texto'),
    ('hero', 'slide5', 'titulo',      'Ubicación, Horarios de Atención y Contacto',          'texto'),
    ('hero', 'slide5', 'descripcion', 'Visítanos en Azucenas 8, Jardines del Sur, Huajuapan de León. Lunes a sábado 7:00 a.m. – 9:00 p.m.', 'texto'),
    ('hero', 'navbar', 'tagline_l1',  'Diagnósticos de',                                     'texto'),
    ('hero', 'navbar', 'tagline_l2',  'Confianza y Calidad',                                 'texto'),
    ('hero', 'config', 'transition_time', '5',                                               'texto');

-- Panel 2: Quiénes Somos — 6 contenidos editoriales canónicos consumidos por index.php
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('quienes-somos', 'seccion', 'h2',        'Quiénes somos', 'texto'),
    ('quienes-somos', 'seccion', 'subtitulo', 'La calidad de un resultado también se mide por la confianza que genera. 25 años transformando resultados en decisiones clínicas.', 'texto'),
    ('quienes-somos', 'ficha4',  'texto',     '<h3>🟢 ¿ POR QUÉ CONFIAR EN LAESH ® ? 🟢</h3><ul><li>25 años de experiencia</li><li>Químicos especialistas con estudios de posgrado</li><li>Guías de práctica clínica — pruebas y perfiles actualizados</li><li>Excelencia en programas de control de calidad externo</li><li>Galardón Rey PACAL — reconocimiento a nuestro desempeño</li></ul>', 'texto'),
    ('quienes-somos', 'ficha2',  'texto',     '<h3>🔵 MISIÓN 🔵</h3><p>Brindar resultados confiables y clínicamente relevantes que ayuden al médico a tomar mejores decisiones y al paciente a recibir una atención oportuna y segura.</p>', 'texto'),
    ('quienes-somos', 'ficha3',  'texto',     '<h3>🟢 VISIÓN 🟢</h3><p>Ser el laboratorio de referencia para médicos y pacientes, reconocido por la excelencia de nuestros resultados, la especialización de nuestro equipo y nuestro compromiso permanente con la calidad.</p>', 'texto'),
    ('quienes-somos', 'ficha1',  'texto',     '<h3>HISTORIA Y TRAYECTORIA INSTITUCIONAL</h3><p>LAESH, Laboratorio de Especialidades Hematológicas, es una empresa 100% de la Región Mixteca fundada con la visión de elevar los estándares de diagnóstico clínico.</p>', 'texto');

-- Panel 3: Especialidades — abanicos editoriales (el catálogo real vive en estudios)
-- SSOT: especialidades/catalogo/titulo y lista ELIMINADOS (redundantes con tabla estudios)
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades', 'cg1', 'titulo', 'Rutina General — Hematología, Química Clínica, Electrolitos, Uroanálisis, Coagulación', 'texto'),
    ('especialidades', 'cg1', 'fichas', '[Hematología] Citometría Hemática, Grupo y RH, Plaquetas, VSG, Reticulocitos, Perfil de Hierro\n[Química Clínica] QS3, QS7, Perfil Bioquímico 15/24/30/35/45, Glucosa, Creatinina, Colesterol, Triglicéridos\n[Electrolitos Séricos] ES 3/4/Completos, Calcio, Fósforo, Magnesio, Bicarbonato CO2\n[Uroanálisis] EGO + Radio Prot/Crea, EGO Especializado, Antidoping 5/12 elem.\n[Coagulación] Perfil de Coagulación, TP/INR, TTPa, Fibrinógeno, Dímero D, T. Sangrado\n[Lípidos] Perfil de Lípidos I, II, Perfil Aterogénico', 'texto'),
    ('especialidades', 'cg2', 'titulo', 'Función de Órganos — Hepática, Tiroidea, Pancreática, Renal, Cardiaca, Gasometría', 'texto'),
    ('especialidades', 'cg2', 'fichas', '[Función Hepática] PFH Básico, PFH Completo, Transaminasas, GGT, Proteínas Totales, Albumina\n[Función Tiroidea] Perfil Tiroideo I-IV, TSH, Ac. Anti Tiroideos I-II, Ac. Anti Receptor TSH, Tiroglobulina\n[Función Pancreática] Amilasa sérica, Lipasa sérica\n[Función Renal] Cistatina C, Depuración creatinina, Proteínas orina, Microalbuminuria\n[Función Cardiaca] Triage cardiaco, Perfil cardiaco completo, Troponina I, Troponina T, NT-pro BNP, Mioglobina\n[Gasometría] Gasometría Arterial Completa, Gasometría Venosa Completa', 'texto'),
    ('especialidades', 'cg3', 'titulo', 'Hormonas, Diabetes e Inmunología — Perfil Ginecológico, Masculino, Diabetes, Inmunología, Reumatología', 'texto'),
    ('especialidades', 'cg3', 'fichas', '[Hormonas] Perfil Ginecológico I-II, Perfil Hormonal Masculino, FSH, LH, PRL, PROG, TESTOSTERONA Total/Libre, DHEA-S, Cortisol, AMH, PTH-i\n[Diabetes] HbA1c, Insulina, HOMA-IR, Péptido C, Prueba de Tolerancia Glucosa, Test O\'Sullivan\n[Inmunología] HIV 1/2, V.D.R.L., Reacciones Febriles, Hepatitis A-B-C, Dengue, COVID-19, Coombs, Procalcitonina\n[Reumatología] Perfil Reumático, PCR, Factor Reumatoide, CCP, ANA, Anti DNA, Complementos C3/C4\n[Diversos] Vitamina D, Inmunoglobulina E, Somatomedina C, Papanicolaou', 'texto'),
    ('especialidades', 'cg4', 'titulo', 'Bacteriología, Marcadores Tumorales, Parasitología, Citroquímicos, Biología Molecular, Fertilidad', 'texto'),
    ('especialidades', 'cg4', 'fichas', '[Bacteriología] Cultivo de orina MIC, Ex. Faríngeo MIC, Ex. Vaginal MIC, Uretral MIC, Heces MIC, Lesión MIC, Expectoración MIC, Hemocultivo MIC, Cultivo Micológico\n[Marcadores Tumorales] PSA Total, PSA Libre, CEA, AFP, CA-125, CA-15-3, CA-19-9, Perfil Tumoral Femenino/Masculino\n[Parasitología] Coproparasitoscópico 3 muestras, Coprológico completo/especial, Sangre Oculta, H. Pylori, Calprotectina, Lactoferrina, Clostridium difficile\n[Citroquímicos] LCR, Sinovial, Pleural, Ascitis, Diálisis, Bronquial, Pericárdico\n[Biología Molecular] PCR VPH, PCR Mycobacterium, PCR Patógenos respiratorios, PCR Meningitis viral, PCR SARS-CoV-2\n[Fertilidad] Espermatobioscopia directa', 'texto');

-- Panel 4: Promociones
-- SSOT: titulo, precio, ayuno, tiempo → JOIN estudios WHERE clave = estudio_clave
-- Solo se edita en CMS: estudio_clave (referencia) + descripcion (marketing editorial)
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    -- Banner general
    ('promociones', 'banner', 'titulo',    'Promociones Vigentes', 'texto'),
    ('promociones', 'banner', 'subtitulo', 'Aprovecha nuestras tarifas preferenciales y paquetes diseñados para ti.', 'texto'),
    -- Lunes: Citometría Hemática (HEM-01)
    ('promociones', 'lunes',     'estudio_clave', 'HEM-01', 'texto'),
    ('promociones', 'lunes',     'descripcion',   'Hematología · Conteo globular y frotis de sangre periférica', 'texto'),
    -- Martes: Grupo Sanguíneo y factor Rh (HEM-02)
    ('promociones', 'martes',    'estudio_clave', 'HEM-02', 'texto'),
    ('promociones', 'martes',    'descripcion',   'Hematología · Determinación de grupo sanguíneo y factor RH', 'texto'),
    -- Miércoles: Plaquetas (HEM-03)
    ('promociones', 'miercoles', 'estudio_clave', 'HEM-03', 'texto'),
    ('promociones', 'miercoles', 'descripcion',   'Hematología · Recuento de trombocitos sanguíneos', 'texto'),
    -- Jueves: Velocidad de Sedimentación Globular (HEM-04)
    ('promociones', 'jueves',    'estudio_clave', 'HEM-04', 'texto'),
    ('promociones', 'jueves',    'descripcion',   'Hematología · Marcador de inflamación aguda y crónica', 'texto'),
    -- Viernes: Reticulocitos (HEM-05)
    ('promociones', 'viernes',   'estudio_clave', 'HEM-05', 'texto'),
    ('promociones', 'viernes',   'descripcion',   'Hematología · Evaluación de producción eritroide medular', 'texto'),
    -- Sábado: Perfil de Hierro Cinética (HEM-06)
    ('promociones', 'sabado',    'estudio_clave', 'HEM-06', 'texto'),
    ('promociones', 'sabado',    'descripcion',   'Hematología · Hierro sérico, ferritina y capacidad de fijación', 'texto'),
    -- Domingo: solo imagen (sin promo de texto en el HTML fuente)
    ('promociones', 'domingo',   'alt',           'Servicio dominical LAESH — Horario especial', 'texto');

-- Panel 5: Calidad — encabezado de sección
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad', 'seccion', 'h2',        'Calidad e Instalaciones', 'texto'),
    ('calidad', 'seccion', 'subtitulo', 'Conoce nuestras instalaciones equipadas con tecnología de vanguardia y un equipo comprometido con la excelencia diagnóstica.', 'texto');

-- Panel 6: Ubicación — solo el embed del mapa (dato CMS-específico)
-- SSOT: dirección, teléfono, email, horario, WhatsApp, responsable → configuraciones
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('ubicacion', 'info', 'maps_embed', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3773.7375!2d-97.7779575!3d17.8028691!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x85c60141d7aa4483%3A0x730f884bc7308bee!2sLaboratorio%20de%20Especialidades%20Hematol%C3%B3gicas%20S.C.!5e0!3m2!1ses!2smx!4v1724000000000!5m2!1ses!2smx', 'url');

-- Panel 7: Footer — solo contenido editorial (logo, nombre lab, legal)
-- SSOT: dirección, teléfono, WhatsApp, email, horarios, responsable → configuraciones
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('footer', 'logo',  'alt',              'LAESH — Laboratorio de Análisis Clínicos',   'texto'),
    ('footer', 'info',  'nombre',           'Laboratorio de Análisis Clínicos LAESH®',    'texto'),
    ('footer', 'legal', 'copyright',        '2026 LAESH. Todos los derechos reservados.', 'texto'),
    ('footer', 'legal', 'privacidad_label', 'Aviso de Privacidad',                        'texto'),
    ('footer', 'legal', 'privacidad_href',  '/laesh/privacidad',                          'texto');

-- Panel 8: SEO — meta, Open Graph y nombre/tipo Schema.org (editorial)
-- SSOT: dirección, teléfono, CP, horarios Schema → configuraciones (dirección, cp, telefono, hrs_open/close, dom_open/close)
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('seo', 'meta',   'title',          'LAESH — Laboratorio de Especialidades Hematológicas en Huajuapan de León, Oaxaca',  'texto'),
    ('seo', 'meta',   'description',    'Análisis clínicos especializados: hematología, bioquímica, inmunología, bacteriología y biología molecular en Huajuapan de León, Oaxaca.', 'texto'),
    ('seo', 'og',     'og_title',       'LAESH — Laboratorio de Especialidades Hematológicas',         'texto'),
    ('seo', 'og',     'og_description', 'Diagnósticos clínicos de alta precisión con resultados confiables. Visítanos en Huajuapan de León, Oaxaca.', 'texto'),
    ('seo', 'og',     'og_image',       '/laesh-web-assets-uipv1a/img/laesh-slider-futurista-c.webp',  'imagen_url'),
    ('seo', 'schema', 'schema_type',    'MedicalLaboratory',                                            'texto'),
    ('seo', 'schema', 'schema_name',    'Laboratorio de Especialidades Hematológicas LAESH',            'texto');
    -- schema_address, schema_telefono, schema_cp → configuraciones.direccion, .telefono, .cp
    -- hrs_open/close, dom_open/close → configuraciones.hrs_open/close, .dom_open/close

-- =============================================================================
-- ADDENDUM Phase J — 2026-08-22
-- Nuevas claves para que index.php lea 100% dinámico desde la BD.
-- Todos INSERT IGNORE excepto las correcciones de texto (ON DUPLICATE KEY UPDATE).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- CONFIGURACIONES — claves nuevas de ubicación geográfica
-- Necesarias para Schema.org addressLocality / addressRegion por separado.
-- ---------------------------------------------------------------------------
INSERT INTO `configuraciones` (`clave`, `valor`, `descripcion`) VALUES
    ('ciudad',          'Huajuapan de León',
                        'Ciudad — Schema.org addressLocality; reutilizada en Ubicación, Footer y Hero'),
    ('estado',          'Oaxaca',
                        'Estado — Schema.org addressRegion; reutilizado en Ubicación y Footer')
ON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`), `descripcion` = VALUES(`descripcion`);

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — encabezados de sección
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    -- § Especialidades — encabezado de sección (#especialidades)
    ('especialidades', 'seccion', 'h2',
        'Estudios de Rutina y Especialidades', 'texto'),
    ('especialidades', 'seccion', 'subtitulo',
        'Servicios clínicos diseñados con rigor científico para garantizar la máxima confiabilidad en el diagnóstico médico.',
        'texto'),
    -- Nota al pie del catálogo (texto exacto de index.html)
    ('especialidades', 'catalogo', 'nota_pie',
        'Listas de Estudios disponibles 2026 · Haz clic en cada grupo para expandir', 'texto'),

    -- § Ubicación — encabezado de sección (#ubicacion)
    ('ubicacion', 'seccion', 'h2',
        'Ubicación y Contacto', 'texto'),
    ('ubicacion', 'seccion', 'subtitulo',
        'Visítenos en nuestras instalaciones, será un placer atenderle.', 'texto');

-- =============================================================================
-- ADDENDUM 2026-08-23 — Corrección de mismatches CMS↔index y campos faltantes
-- =============================================================================

-- ---------------------------------------------------------------------------
-- CONFIGURACIONES — WA texto de apertura
-- ---------------------------------------------------------------------------
INSERT INTO `configuraciones` (`clave`, `valor`, `descripcion`) VALUES
    ('wa_texto_info',
     'Hola LAESH, necesito información sobre un estudio.',
     'Texto de apertura de chat de WhatsApp — botón flotante e info general')
ON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`), `descripcion` = VALUES(`descripcion`);

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Corrección de claves (mismatches CMS↔index.php)
-- ---------------------------------------------------------------------------
-- hero/config/transition_time: gestion-web.php guarda aquí; index.php leía de configuraciones
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero', 'config', 'transition_time', '5', 'texto');

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Corrección de claves (mismatches CMS↔index.php)
-- ---------------------------------------------------------------------------
-- hero/config/transition_time: gestion-web.php guarda aquí; index.php leía de configuraciones
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero', 'config', 'transition_time', '5', 'texto');

-- ficha1/texto: marcado como 'html' para habilitar RTE en CMS
UPDATE `web_contenidos`
   SET `tipo` = 'html'
 WHERE `seccion` = 'quienes-somos'
   AND `subseccion` = 'ficha1'
   AND `clave` = 'texto';

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Footer: enlace Política de Datos (faltaba)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('footer', 'legal', 'politica_label', 'Política de Datos',       'texto'),
    ('footer', 'legal', 'politica_href',  '/laesh/politica-de-datos', 'texto');

-- =============================================================================
-- ADDENDUM 2026-08-22b — Estabilización dinámica index.php
-- Nuevas claves: hero_autoplay · ficha4 (¿por qué confiar?) · carousel 1-12
--                calidad gallery 1-3 · aviso-privacidad (secciones)
-- Idempotente: INSERT IGNORE (no modifica registros existentes).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- CONFIGURACIONES — Hero autoplay / transición (segundos)
-- ---------------------------------------------------------------------------
INSERT INTO `configuraciones` (`clave`, `valor`, `descripcion`) VALUES
    ('hero_autoplay_seg', '5', 'Tiempo de autoplay del carrusel Hero (segundos). Mínimo 3.')
ON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`), `descripcion` = VALUES(`descripcion`);

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Carrusel de Especialidades y Áreas (16 tarjetas)
-- Cada tarjeta contiene HTML (h3 + p) consumido por index.php
-- ---------------------------------------------------------------------------
INSERT INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('especialidades', 'carousel1',  'texto', '<h3>Hematología Especializada</h3><p>Análisis morfológico de frotis sanguíneo y pruebas hematológicas de alta complejidad.</p>', 'html'),
    ('especialidades', 'carousel2',  'texto', '<h3>Química Clínica Avanzada</h3><p>Determinación automatizada de electrolitos, proteínas y enzimas específicas.</p>', 'html'),
    ('especialidades', 'carousel3',  'texto', '<h3>Microbiología y Cultivos</h3><p>Identificación microscópica y pruebas de susceptibilidad a antimicrobianos.</p>', 'html'),
    ('especialidades', 'carousel4',  'texto', '<h3>Uroanálisis y Sedimentos</h3><p>Examen de orina, química y microscopía para detección precoz de patologías renales.</p>', 'html'),
    ('especialidades', 'carousel5',  'texto', '<h3>Hemostasia y Coagulación</h3><p>Estudios de tiempos de protrombina (TP) y tromboplastina parcial activada (TTPa).</p>', 'html'),
    ('especialidades', 'carousel6',  'texto', '<h3>Pruebas Especiales</h3><p>Hormonas, anticuerpos específicos, pruebas inmunológicas y marcadores tumorales.</p>', 'html'),
    ('especialidades', 'carousel7',  'texto', '<h3>Pre-analítica</h3><p>Separación de suero y plasma con control estricto de tiempos y temperaturas.</p>', 'html'),
    ('especialidades', 'carousel8',  'texto', '<h3>Toma de Muestras I</h3><p>Áreas higiénicas equipadas para la extracción sanguínea convencional.</p>', 'html'),
    ('especialidades', 'carousel9',  'texto', '<h3>Toma de Muestras II</h3><p>Módulos individuales y confortables que aseguran una atención rápida y sin molestias.</p>', 'html'),
    ('especialidades', 'carousel10', 'texto', '<h3>Toma Pediátrica</h3><p>Espacio amigable y personal capacitado para el cuidado y tranquilidad de los niños.</p>', 'html'),
    ('especialidades', 'carousel11', 'texto', '<h3>Toma de Cultivos</h3><p>Zonas aisladas y estériles para la toma de exudados y cultivos microbiológicos.</p>', 'html'),
    ('especialidades', 'carousel12', 'texto', '<h3>Recepción Técnica</h3><p>Recepción técnica de muestras e indicaciones pre-analíticas detalladas.</p>', 'html'),
    ('especialidades', 'carousel13', 'texto', '', 'html'),
    ('especialidades', 'carousel14', 'texto', '', 'html'),
    ('especialidades', 'carousel15', 'texto', '', 'html'),
    ('especialidades', 'carousel16', 'texto', '', 'html')
ON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`), `tipo` = 'html';

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Calidad gallery (3 tarjetas)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('calidad', 'gallery1', 'titulo',      'Área de Hematología',      'texto'),
    ('calidad', 'gallery1', 'descripcion', 'Análisis de biometría hemática y células sanguíneas con rigor científico y alta precisión.',      'texto'),
    ('calidad', 'gallery2', 'titulo',      'Química Clínica',           'texto'),
    ('calidad', 'gallery2', 'descripcion', 'Determinación automatizada de metabolitos, perfil lipídico y enzimas específicas.',               'texto'),
    ('calidad', 'gallery3', 'titulo',      'Microbiología y Cultivos',  'texto'),
    ('calidad', 'gallery3', 'descripcion', 'Aislamiento, tinción de Gram y pruebas de susceptibilidad a antimicrobianos.',                   'texto');

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Aviso de Privacidad (secciones)
-- Placeholder {lab} en textos → sustituido en PHP por $cfgNombreC.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('aviso-privacidad', 'intro',           'texto',
        'es responsable del tratamiento, uso, protección y resguardo de los datos personales que recaba de sus pacientes, usuarios y personas que solicitan nuestros servicios.',
        'texto'),

    ('aviso-privacidad', 's1',   'titulo',  '1. Datos personales que recabamos', 'texto'),
    ('aviso-privacidad', 's1',   'items',
        'Nombre completo.
Fecha de nacimiento y edad.
Sexo.
Datos de contacto, como teléfono, correo electrónico y domicilio.
Datos relacionados con la atención y solicitud de estudios de laboratorio.
Información necesaria para la identificación y entrega de resultados.',
        'texto'),
    ('aviso-privacidad', 's1b',  'titulo',  'Datos personales sensibles', 'texto'),
    ('aviso-privacidad', 's1b',  'texto',
        'Por la naturaleza de nuestros servicios, podremos tratar datos personales sensibles relacionados con el estado de salud. Estos datos serán tratados con medidas de seguridad y confidencialidad.',
        'texto'),

    ('aviso-privacidad', 's2',   'titulo',  '2. Finalidades del tratamiento', 'texto'),
    ('aviso-privacidad', 's2',   'items',
        'Identificar y registrar al paciente.
Solicitar, procesar y entregar estudios de laboratorio.
Elaborar y conservar los resultados correspondientes.
Dar seguimiento a los servicios solicitados.
Atender dudas, aclaraciones o solicitudes relacionadas con sus resultados.
Cumplir con las obligaciones legales y sanitarias aplicables.
Mantener registros administrativos, contables y relacionados con la prestación del servicio.',
        'texto'),

    ('aviso-privacidad', 's3',   'titulo',  '3. Protección y confidencialidad', 'texto'),
    ('aviso-privacidad', 's3',   'texto',
        'Laboratorio {lab} implementa medidas administrativas, técnicas y físicas destinadas a proteger los datos personales contra daño, pérdida, alteración, destrucción, acceso o tratamiento no autorizado.',
        'texto'),

    ('aviso-privacidad', 's4',   'titulo',  '4. Derechos ARCO', 'texto'),
    ('aviso-privacidad', 's4',   'intro',
        'Usted tiene derecho a Acceder, Rectificar, Cancelar u Oponerse al tratamiento de sus datos personales. Para ejercer estos derechos contáctenos por:',
        'texto'),

    ('aviso-privacidad', 's5',   'titulo',  '5. Modificaciones', 'texto'),
    ('aviso-privacidad', 's5',   'texto',
        'Laboratorio {lab} podrá modificar este Aviso cuando resulte necesario. Las modificaciones estarán disponibles en nuestro sitio web.',
        'texto'),

    ('aviso-privacidad', 'meta', 'fecha_actualizacion',
        'agosto de 2026', 'texto'),

    ('aviso-privacidad', 'consentimiento', 'titulo',  'Consentimiento', 'texto'),
    ('aviso-privacidad', 'consentimiento', 'texto',
        'Declaro que he leído y comprendido el presente Aviso de Privacidad y manifiesto mi consentimiento para el tratamiento de mis datos personales para las finalidades señaladas.',
        'texto');

-- ---------------------------------------------------------------------------
-- ADDENDUM — Campos nuevos requeridos por la arquitectura sin fallback
-- Ref: corrección "elimina todo lo referente a fallback" — 2026-08-23
-- ---------------------------------------------------------------------------

-- Configuraciones: WA texto agendar + URL directa de Google Maps
INSERT IGNORE INTO `configuraciones` (`clave`, `valor`, `descripcion`) VALUES
    ('cms_upload_endpoint', '/laesh/adrc/cms/upload', 'Endpoint asíncrono para JS (relativo al host)'),
    ('cms_upload_dir', '/var/www/html/laesh-web-assets-uipv1a/img/cms/', 'Ruta física del disco para almacenar el binario de imagen CMS'),
    ('wa_texto_agendar',
     'Hola LAESH, deseo agendar {estudio}.',
     'Texto pre-llenado WhatsApp para agendar estudio — {estudio} se reemplaza con el nombre del estudio'),
    ('maps_url',
     'https://www.google.com/maps/place/Laboratorio+de+Especialidades+Hematol%C3%B3gicas+S.C./@17.8030093,-97.7777261,18z/data=!4m6!3m5!1s0x85c60141d7aa4483:0x730f884bc7308bee!8m2!3d17.8028691!4d-97.7779575!16s%2Fg%2F11ry4m4j5r',
     'URL directa de Google Maps — aparece en noscript y link en texto plano del mapa')
ON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`), `descripcion` = VALUES(`descripcion`);

-- Hero slides — etiquetas y descripciones faltantes
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero', 'slide2', 'etiqueta',    '25 Años de Experiencia Clínica',              'texto'),
    ('hero', 'slide4', 'descripcion', 'Descubre nuestros paquetes preventivos y tarifas especiales diseñadas para el cuidado integral de tu salud y la de toda tu familia.', 'texto'),
    ('hero', 'slide5', 'etiqueta',    'Atención Presencial y Horarios',              'texto');

-- Hero slides — imagen_url (alineada con bg-slide-N de landing.css)
-- Fallback visual: CSS class bg-slide-N; imagen_url permite cambio desde CMS sin tocar CSS.
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero', 'slide1', 'imagen_url', '/laesh-web-assets-uipv1a/img/recepcion-de-pacientes.webp', 'imagen_url'),
    ('hero', 'slide2', 'imagen_url', '/laesh-web-assets-uipv1a/img/recepcion.webp',               'imagen_url'),
    ('hero', 'slide3', 'imagen_url', '/laesh-web-assets-uipv1a/img/recepcion-de-pacientes.webp', 'imagen_url'),
    ('hero', 'slide4', 'imagen_url', '/laesh-web-assets-uipv1a/img/sala-de-espera.webp',          'imagen_url'),
    ('hero', 'slide5', 'imagen_url', '/laesh-web-assets-uipv1a/img/recepcion-de-pacientes.webp', 'imagen_url');

-- Hero slides — CTAs dinámicos (cta_texto + cta_href para cada slide)
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('hero', 'slide1', 'cta_texto',   'Conoce los Servicios',    'texto'),
    ('hero', 'slide1', 'cta_href',    '#especialidades',         'texto'),
    ('hero', 'slide2', 'cta_texto',   'Ver Especialidades',      'texto'),
    ('hero', 'slide2', 'cta_href',    '#especialidades',         'texto'),
    ('hero', 'slide3', 'cta_texto',   'Conocer Calidad',         'texto'),
    ('hero', 'slide3', 'cta_href',    '#calidad',                'texto'),
    ('hero', 'slide4', 'cta_texto',   'Ver Promociones',         'texto'),
    ('hero', 'slide4', 'cta_href',    '#promociones',            'texto'),
    ('hero', 'slide5', 'cta_texto',   'Ver Ubicación',           'texto'),
    ('hero', 'slide5', 'cta_href',    '#ubicacion',              'texto');

-- Ubicación — encabezado de sección (seccion.h2 / seccion.subtitulo ya sembrados en bloque anterior,
-- pero se agregan aquí en caso de que la ejecución parcial los haya omitido)
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('ubicacion', 'seccion', 'h2',        'Ubicación y Contacto',                         'texto'),
    ('ubicacion', 'seccion', 'subtitulo', 'Encuéntranos fácilmente y contáctanos en el horario que más te convenga.', 'texto');

-- ---------------------------------------------------------------------------
-- ADDENDUM — Promociones: imagen_url por día + estudio_clave domingo
-- Ref: Panel 4 editor de 7 días completo — 2026-08-23
-- ---------------------------------------------------------------------------

-- imagen_url para los 6 días con estudio (lunes–sábado) — inicialmente vacío
-- El cliente sube la imagen desde el CMS; INSERT IGNORE para no pisar imágenes ya cargadas
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('promociones', 'lunes',     'imagen_url', '', 'texto'),
    ('promociones', 'martes',    'imagen_url', '', 'texto'),
    ('promociones', 'miercoles', 'imagen_url', '', 'texto'),
    ('promociones', 'jueves',    'imagen_url', '', 'texto'),
    ('promociones', 'viernes',   'imagen_url', '', 'texto'),
    ('promociones', 'sabado',    'imagen_url', '', 'texto'),
    -- Domingo: imagen + estudio_clave vacío → activa modo imagen-full en index.php
    ('promociones', 'domingo',   'imagen_url',    '', 'texto'),
    ('promociones', 'domingo',   'estudio_clave', '', 'texto');
