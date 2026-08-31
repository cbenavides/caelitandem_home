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

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Contenido editorial (seed fidedigno desde local BD)
-- SSOT: exportado de laesh_db local 2026-08-25
-- Estrategia: REPLACE INTO (elimina fila existente con misma clave única y
--             la reinserta) — garantiza que el seed SIEMPRE gana sobre datos
--             previos, a diferencia de INSERT IGNORE que los preservaría.
-- Clave única: (seccion, subseccion, clave)
-- ---------------------------------------------------------------------------

REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES
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
    ('hero', 'slide1', 'imagen_url', '/laesh-web-assets-uipv1a/img/cms/hero-slide1-20260824-a689d2fa.webp', 'imagen_url'),
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
    ('promociones', 'domingo', 'alt', 'Servicio dominical LAESH — Horario especial', 'texto'),
    ('promociones', 'domingo', 'estudio_clave', '', 'texto'),
    ('promociones', 'domingo', 'imagen_url', '', 'texto'),
    ('promociones', 'jueves', 'descripcion', 'Hematología · Marcador de inflamación aguda y crónica', 'texto'),
    ('promociones', 'jueves', 'estudio_clave', 'HEM-04', 'texto'),
    ('promociones', 'jueves', 'imagen_url', '', 'texto'),
    ('promociones', 'lunes', 'descripcion', 'Hematología · Conteo globular y frotis de sangre periférica', 'texto'),
    ('promociones', 'lunes', 'estudio_clave', 'HEM-01', 'texto'),
    ('promociones', 'lunes', 'imagen_url', '', 'texto'),
    ('promociones', 'martes', 'descripcion', 'Hematología · Determinación de grupo sanguíneo y factor RH', 'texto'),
    ('promociones', 'martes', 'estudio_clave', 'HEM-02', 'texto'),
    ('promociones', 'martes', 'imagen_url', '', 'texto'),
    ('promociones', 'miercoles', 'descripcion', 'Hematología · Recuento de trombocitos sanguíneos', 'texto'),
    ('promociones', 'miercoles', 'estudio_clave', 'HEM-03', 'texto'),
    ('promociones', 'miercoles', 'imagen_url', '', 'texto'),
    ('promociones', 'sabado', 'descripcion', 'Hematología · Hierro sérico, ferritina y capacidad de fijación', 'texto'),
    ('promociones', 'sabado', 'estudio_clave', 'HEM-06', 'texto'),
    ('promociones', 'sabado', 'imagen_url', '', 'texto'),
    ('promociones', 'viernes', 'descripcion', 'Hematología · Evaluación de producción eritroide medular', 'texto'),
    ('promociones', 'viernes', 'estudio_clave', 'HEM-05', 'texto'),
    ('promociones', 'viernes', 'imagen_url', '', 'texto'),
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
    ('ubicacion', 'info', 'maps_embed', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3773.7375!2d-97.7779575!3d17.8028691!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x85c60141d7aa4483%3A0x730f884bc7308bee!2sLaboratorio%20de%20Especialidades%20Hematol%C3%B3gicas%20S.C.!5e0!3m2!1ses!2smx!4v1724000000000!5m2!1ses!2smx', ''),
    ('ubicacion', 'seccion', 'h2', 'Ubicación y Contacto', 'texto'),
    ('ubicacion', 'seccion', 'subtitulo', 'Visítenos en nuestras instalaciones, será un placer atenderle.', 'texto')
;

