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
    ('facebook_url',            '',
                                 'URL de página Facebook (vacío hasta confirmar con cliente)'),
    ('maps_embed_url',          'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3773.7375!2d-97.7779575!3d17.8028691!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x85c60141d7aa4483%3A0x730f884bc7308bee!2sLaboratorio%20de%20Especialidades%20Hematol%C3%B3gicas%20S.C.!5e0!3m2!1ses!2smx!4v1724000000000!5m2!1ses!2smx',
                                 'Embed URL Google Maps con Place ID — iframe data-src en index.php sección #ubicacion'),
    -- Operaciones internas
    ('tiempo_rotacion_dias',    '90',
                                 'Días de validez antes de solicitar cambio de contraseña (admin policy)'),
    ('anios_experiencia',       '25',
                                 'Años de experiencia — usado en mensajes del sitio web');

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
    ('hero', 'slide3', 'etiqueta',    'Aprovecha nuestras ofertas',                          'texto'),
    ('hero', 'slide3', 'titulo',      'Promociones Vigentes',                                'texto'),
    ('hero', 'slide3', 'descripcion', 'Aprovecha nuestras tarifas preferenciales y paquetes de check-ups diseñados para el cuidado de tu salud y la de tu familia.', 'texto'),
    ('hero', 'slide4', 'etiqueta',    'Horarios y Ubicación',                                'texto'),
    ('hero', 'slide4', 'titulo',      'Nuestra Ubicación y Horarios',                        'texto'),
    ('hero', 'slide5', 'titulo',      'Ubicación, Horarios de Atención y Contacto',          'texto'),
    ('hero', 'slide5', 'descripcion', 'Visítanos en Azucenas 8, Jardines del Sur, Huajuapan de León. Lunes a sábado 7:00 a.m. – 9:00 p.m.', 'texto'),
    ('hero', 'navbar', 'tagline_l1',  'Diagnósticos de',                                     'texto'),
    ('hero', 'navbar', 'tagline_l2',  'Confianza y Calidad',                                 'texto'),
    ('hero', 'config', 'transition_time', '5',                                               'texto');

-- Panel 2: Quiénes Somos — 4 fichas + filosofía + bio del responsable
-- SSOT: nombre y cédulas del responsable → configuraciones (no duplicar aquí)
INSERT IGNORE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
    ('quienes-somos', 'ficha1', 'titulo', 'Historia y Quiénes Somos', 'texto'),
    ('quienes-somos', 'ficha1', 'texto',  'Fundado con la misión de brindar diagnósticos hematológicos y clínicos de alta precisión en la región de la Mixteca, LAESH cuenta con tecnología automatizada y personal altamente calificado.', 'texto'),
    ('quienes-somos', 'ficha2', 'titulo', 'Nuestra Misión', 'texto'),
    ('quienes-somos', 'ficha2', 'texto',  'Proporcionar un servicio de análisis clínicos con resultados confiables y oportunos para auxiliar en el diagnóstico de enfermedades, sobre una base de ética profesional y alto compromiso con la calidad.', 'texto'),
    ('quienes-somos', 'ficha3', 'titulo', 'Nuestra Visión', 'texto'),
    ('quienes-somos', 'ficha3', 'texto',  'Ser un Laboratorio Líder que proporcione los servicios más especializados y de alta calidad a médicos y pacientes.', 'texto'),
    ('quienes-somos', 'ficha4', 'titulo', 'Nuestros Valores', 'texto'),
    ('quienes-somos', 'ficha4', 'texto',  'Rigurosidad científica, empatía y calidez en el trato, integridad ética en los diagnósticos, responsabilidad social y constante mejora de nuestros análisis.', 'texto'),
    -- resp: solo contenido editorial biográfico; nombre/cédulas → configuraciones.responsable_*
    ('quienes-somos', 'resp',     'bio',     'Especialista en hematología diagnóstica con más de 25 años de experiencia en la región Mixteca. Comprometido con la calidad, la ética profesional y el servicio al paciente.', 'texto'),
    -- filosofía
    ('quienes-somos', 'filosofia','tagline', 'Ciencia con Calidez Humana', 'texto'),
    ('quienes-somos', 'filosofia','texto',   'En LAESH creemos que un diagnóstico preciso es la base de una atención médica de calidad. Por eso combinamos tecnología de punta con el trato humano y empático que merecen nuestros pacientes.', 'texto');

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
