-- ===========================================================================
-- import_top20.sql — Actualización de los 20 Estudios Más Solicitados (SSOT)
-- Generado por import_catalogo_estudios.py (Post-Refactor m010)
-- REGLA: Match estricto en catálogo existente por CLAVE y NOMBRE (CERO INSERT)
-- ===========================================================================
USE laesh_db;
SET FOREIGN_KEY_CHECKS = 0;
-- 1. Resetear asignaciones previas de Top 20 para evitar duplicados
UPDATE cat_estudios SET top20_orden = NULL WHERE top20_orden IS NOT NULL;

-- Top 01: CITOMETRIA HEMATICA (BHC) (Clave: 692) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 1,
       muestra           = COALESCE(NULLIF('Sangre total EDTA', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo lila', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 4 horas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Serie Roja\nSerie Plaquetaria\nSerie Blanca\nVelocidad de Eritrosedimentación\nFrotis de sangre periférica', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '692'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('CITOMETRIA HEMATICA (BHC)'))
        OR LOWER(TRIM('CITOMETRIA HEMATICA (BHC)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('CITOMETRIA HEMATICA (BHC)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 1
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '692'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('CITOMETRIA HEMATICA (BHC)'))
             OR LOWER(TRIM('CITOMETRIA HEMATICA (BHC)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('CITOMETRIA HEMATICA (BHC)')), '%'))
      LIMIT 1
 );

-- Top 02: QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS) (Clave: 1321) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 2,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 10 - 12 horas, cena ligera baja en grasas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Glucosa sérica\nUrea/ Nitrógeno ureico (BUN)\nCreatinina sérica\nÁcido úrico sérico\nColesterol total\nTriglicéridos', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '1321'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)'))
        OR LOWER(TRIM('QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 2
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '1321'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)'))
             OR LOWER(TRIM('QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)')), '%'))
      LIMIT 1
 );

-- Top 03: EXAMEN GENERAL DE ORINA CUANTITATIVO (Clave: 4714) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 3,
       muestra           = COALESCE(NULLIF('Orina (Primera micción)', ''), muestra),
       contenedor        = COALESCE(NULLIF('Frasco esteril', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Primera orina de la Mañana, chorro medio', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Examen Macroscópico\nAnálisis Físico-Químico (Tira Reactiva)\nÍndice Proteína/Creatinina\nSedimento Urinario', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '4714'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('EXAMEN GENERAL DE ORINA CUANTITATIVO'))
        OR LOWER(TRIM('EXAMEN GENERAL DE ORINA CUANTITATIVO')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('EXAMEN GENERAL DE ORINA CUANTITATIVO')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 3
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '4714'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('EXAMEN GENERAL DE ORINA CUANTITATIVO'))
             OR LOWER(TRIM('EXAMEN GENERAL DE ORINA CUANTITATIVO')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('EXAMEN GENERAL DE ORINA CUANTITATIVO')), '%'))
      LIMIT 1
 );

-- Top 04: HEMOGLOBINA GLICADA (HB A1c) por HPLC (Clave: 868) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 4,
       muestra           = COALESCE(NULLIF('Sangre total EDTA', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo lila', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Sin indicaciones especiales', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Fracción de Hemoglobina A1c\nGlucosa Promedio Trimestral\nCromatograma', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '868'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('HEMOGLOBINA GLICADA (HB A1c) por HPLC'))
        OR LOWER(TRIM('HEMOGLOBINA GLICADA (HB A1c) por HPLC')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('HEMOGLOBINA GLICADA (HB A1c) por HPLC')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 4
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '868'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('HEMOGLOBINA GLICADA (HB A1c) por HPLC'))
             OR LOWER(TRIM('HEMOGLOBINA GLICADA (HB A1c) por HPLC')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('HEMOGLOBINA GLICADA (HB A1c) por HPLC')), '%'))
      LIMIT 1
 );

-- Top 05: QUIMICA SANGUINEA ( 3 ELEMENTOS) (Clave: 1319) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 5,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 8 horas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Glucosa sérica\nUrea/ Nitrógeno ureico (BUN)\nCreatinina sérica', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '1319'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('QUIMICA SANGUINEA ( 3 ELEMENTOS)'))
        OR LOWER(TRIM('QUIMICA SANGUINEA ( 3 ELEMENTOS)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('QUIMICA SANGUINEA ( 3 ELEMENTOS)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 5
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '1319'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('QUIMICA SANGUINEA ( 3 ELEMENTOS)'))
             OR LOWER(TRIM('QUIMICA SANGUINEA ( 3 ELEMENTOS)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('QUIMICA SANGUINEA ( 3 ELEMENTOS)')), '%'))
      LIMIT 1
 );

-- Top 06: ELECTROLITOS SERICOS COMPLETOS (Clave: 2852) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 6,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Sin indicaciones especiales', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Sodio sérico (Na⁺)\nPotasio sérico (K⁺)\nCloro sérico (Cl⁻)\nCalcio sérico (Ca²⁺)\nFósforo sérico (P)\nMagnesio sérico (Mg²⁺)', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '2852'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('ELECTROLITOS SERICOS COMPLETOS'))
        OR LOWER(TRIM('ELECTROLITOS SERICOS COMPLETOS')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('ELECTROLITOS SERICOS COMPLETOS')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 6
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '2852'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('ELECTROLITOS SERICOS COMPLETOS'))
             OR LOWER(TRIM('ELECTROLITOS SERICOS COMPLETOS')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('ELECTROLITOS SERICOS COMPLETOS')), '%'))
      LIMIT 1
 );

-- Top 07: PERFIL DE COAGULACION 1 (TP, INR, TTP) (Clave: 1943) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 7,
       muestra           = COALESCE(NULLIF('Plasma/Citrato', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo azul citrato', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 4 horas, Indicar si toma anticoagulantes', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Tiempo de protrombina\nInr\nTP control\nTiempo de Tromboplastina\nTTP control', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '1943'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL DE COAGULACION 1 (TP, INR, TTP)'))
        OR LOWER(TRIM('PERFIL DE COAGULACION 1 (TP, INR, TTP)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL DE COAGULACION 1 (TP, INR, TTP)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 7
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '1943'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL DE COAGULACION 1 (TP, INR, TTP)'))
             OR LOWER(TRIM('PERFIL DE COAGULACION 1 (TP, INR, TTP)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL DE COAGULACION 1 (TP, INR, TTP)')), '%'))
      LIMIT 1
 );

-- Top 08: GRUPO SANGUINEO y FACTOR Rh (Clave: 119) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 8,
       muestra           = COALESCE(NULLIF('Sangre total EDTA', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo lila', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Sin indicaciones previas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Grupo ABO\nFactor RH', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '119'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('GRUPO SANGUINEO y FACTOR Rh'))
        OR LOWER(TRIM('GRUPO SANGUINEO y FACTOR Rh')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('GRUPO SANGUINEO y FACTOR Rh')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 8
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '119'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('GRUPO SANGUINEO y FACTOR Rh'))
             OR LOWER(TRIM('GRUPO SANGUINEO y FACTOR Rh')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('GRUPO SANGUINEO y FACTOR Rh')), '%'))
      LIMIT 1
 );

-- Top 09: PERFIL HEPATICO (PFH) (Clave: 1340) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 9,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 8 horas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Bilirrubina total\nBilirrubina directa\nBilirrubina Indirecta\nTGO/AST Aspartato amino transferasa\nTGP/ALT Alanina amino transferasa\nRelacion AST/ALT\nALP Fosfatasa alcalina', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '1340'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL HEPATICO (PFH)'))
        OR LOWER(TRIM('PERFIL HEPATICO (PFH)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL HEPATICO (PFH)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 9
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '1340'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL HEPATICO (PFH)'))
             OR LOWER(TRIM('PERFIL HEPATICO (PFH)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL HEPATICO (PFH)')), '%'))
      LIMIT 1
 );

-- Top 10: PERFIL TIROIDEO 1 (Clave: 419) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 10,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 8 horas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('TSH Hormona Estimulante de la tiroides\nFT4 Tiroxina Libre\nFT3 Triyodotironina libre', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '419'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL TIROIDEO 1'))
        OR LOWER(TRIM('PERFIL TIROIDEO 1')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL TIROIDEO 1')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 10
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '419'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL TIROIDEO 1'))
             OR LOWER(TRIM('PERFIL TIROIDEO 1')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL TIROIDEO 1')), '%'))
      LIMIT 1
 );

-- Top 11: ELECTROLITOS SERICOS (Na, K, Cl, Ca) (Clave: 1877) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 11,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Sin indicaciones previas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Sodio sérico (Na⁺)\nPotasio sérico (K⁺)\nCloro sérico (Cl⁻)\nCalcio sérico (Ca²⁺)', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '1877'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl, Ca)'))
        OR LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl, Ca)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl, Ca)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 11
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '1877'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl, Ca)'))
             OR LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl, Ca)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl, Ca)')), '%'))
      LIMIT 1
 );

-- Top 12: RESISTENCIA A LA INSULINA (HOMA-IR, %ß, %S) (Clave: 1934) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 12,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 8 horas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Glucosa basal\nInsulina basal\nHOMA-IR (HOMA resistencia insulina)\nHOMA-%ß (función de las células beta)\nHOMA-%S (Sensibilidad a la insulina)', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '1934'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('RESISTENCIA A LA INSULINA (HOMA-IR, %ß, %S)'))
        OR LOWER(TRIM('RESISTENCIA A LA INSULINA (HOMA-IR, %ß, %S)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('RESISTENCIA A LA INSULINA (HOMA-IR, %ß, %S)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 12
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '1934'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('RESISTENCIA A LA INSULINA (HOMA-IR, %ß, %S)'))
             OR LOWER(TRIM('RESISTENCIA A LA INSULINA (HOMA-IR, %ß, %S)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('RESISTENCIA A LA INSULINA (HOMA-IR, %ß, %S)')), '%'))
      LIMIT 1
 );

-- Top 13: PERFIL HEPATICO 2 (PFH 2) (Clave: 1932) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 13,
       muestra           = COALESCE(NULLIF('Suero y Plasma/Citrato', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 8 horas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Bilirrubina total\nBilirrubina directa\nBilirrubina Indirecta\nTGO/AST Aspartato amino transferasa\nTGP/ALT Alanina amino transferasa\nRelación AST/ALT\nALP Fosfatasa alcalina\nGGT Gammaglutamil transpeptidasa\nDHL Deshidrogenasa láctica\nProteínas totales séricas\nAlbumina sérica\nGlobulinas Séricas\nRelación A/G\nTP Tiempo de protrombina\nINR Razón Normalizada Internacional', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '1932'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL HEPATICO 2 (PFH 2)'))
        OR LOWER(TRIM('PERFIL HEPATICO 2 (PFH 2)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL HEPATICO 2 (PFH 2)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 13
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '1932'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL HEPATICO 2 (PFH 2)'))
             OR LOWER(TRIM('PERFIL HEPATICO 2 (PFH 2)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL HEPATICO 2 (PFH 2)')), '%'))
      LIMIT 1
 );

-- Top 14: PERFIL DE LIPIDOS (Clave: 2492) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 14,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 10 - 12 horas, cena ligera baja en grasas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Trigliceridos\nColesterol total\nColesterol de alta sensidad (HDL)\nColestrol no-HDL\nColestrol de baja densidad (LDL)\nColestrol remanente\nÍndices aterogénicos', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '2492'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL DE LIPIDOS'))
        OR LOWER(TRIM('PERFIL DE LIPIDOS')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL DE LIPIDOS')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 14
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '2492'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL DE LIPIDOS'))
             OR LOWER(TRIM('PERFIL DE LIPIDOS')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL DE LIPIDOS')), '%'))
      LIMIT 1
 );

-- Top 15: PERFIL TIROIDEO 2 (Clave: 2020) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 15,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 8 horas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('TSH Hormona Estimulante de la tiroides\nFT4 Tiroxina Libre\nFT3 Triyodotironina libre\nT4T Tiroxina Total\nT3T Triyodotironina Total\nTU Captacion tiroidea', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '2020'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL TIROIDEO 2'))
        OR LOWER(TRIM('PERFIL TIROIDEO 2')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL TIROIDEO 2')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 15
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '2020'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL TIROIDEO 2'))
             OR LOWER(TRIM('PERFIL TIROIDEO 2')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL TIROIDEO 2')), '%'))
      LIMIT 1
 );

-- Top 16: ELECTROLITOS SERICOS (Na, K, Cl) (Clave: 69) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 16,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Sin indicaciones previas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Sodio sérico (Na⁺)\nPotasio sérico (K⁺)\nCloro sérico (Cl⁻)', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '69'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl)'))
        OR LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 16
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '69'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl)'))
             OR LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('ELECTROLITOS SERICOS (Na, K, Cl)')), '%'))
      LIMIT 1
 );

-- Top 17: PERFIL BIOQUIMICO 15 ELEMENTOS (Clave: 1915) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 17,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Ayuno de 10 - 12 horas, cena ligera baja en grasas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Glucosa sérica\nUrea/ Nitrógeno ureico (BUN)\nCreatinina sérica\nÁcido úrico sérico\nTrigliceridos\nColesterol total\nColesterol de alta sensidad (HDL)\nColestrol no-HDL\nColestrol de baja densidad (LDL)\nColestrol remanente\nÍndices aterogénicos\nBilirrubina total\nBilirrubina directa\nBilirrubina Indirecta\nTGO/AST Aspartato amino transferasa\nTGP/ALT Alanina amino transferasa\nRelacion AST/ALT\nALP Fosfatasa alcalina', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '1915'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL BIOQUIMICO 15 ELEMENTOS'))
        OR LOWER(TRIM('PERFIL BIOQUIMICO 15 ELEMENTOS')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL BIOQUIMICO 15 ELEMENTOS')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 17
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '1915'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('PERFIL BIOQUIMICO 15 ELEMENTOS'))
             OR LOWER(TRIM('PERFIL BIOQUIMICO 15 ELEMENTOS')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('PERFIL BIOQUIMICO 15 ELEMENTOS')), '%'))
      LIMIT 1
 );

-- Top 18: GASOMETRIA ARTERIAL COMPLETA (Clave: 4477) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 18,
       muestra           = COALESCE(NULLIF('Sangre total heparina', ''), muestra),
       contenedor        = COALESCE(NULLIF('Jeringa heparinizada', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Sin indicaciones previas', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('GASES\npH\npCO2\npO2\nHCO3\nExceso de base\nSauración de oxigeno\nSosio\nPotasio\nCalcio ionizado\nCloro\nCO2 TOTAL\nAnion GAP\nHematocrito\nHemoglobina\nGlucosa\nLactato\nBun\nCreatinina\neGFR', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '4477'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('GASOMETRIA ARTERIAL COMPLETA'))
        OR LOWER(TRIM('GASOMETRIA ARTERIAL COMPLETA')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('GASOMETRIA ARTERIAL COMPLETA')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 18
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '4477'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('GASOMETRIA ARTERIAL COMPLETA'))
             OR LOWER(TRIM('GASOMETRIA ARTERIAL COMPLETA')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('GASOMETRIA ARTERIAL COMPLETA')), '%'))
      LIMIT 1
 );

-- Top 19: EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre) (Clave: 4515) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 19,
       muestra           = COALESCE(NULLIF('Orina (Primera micción)', ''), muestra),
       contenedor        = COALESCE(NULLIF('Frasco esteril', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('Primera orina de la Mañana, chorro medio', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Examen Macroscópico\nAnálisis Físico-Químico (Tira Reactiva)\nÍndice Albúmina/Creatinina\nSedimento Urinario', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '4515'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)'))
        OR LOWER(TRIM('EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 19
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '4515'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)'))
             OR LOWER(TRIM('EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)')), '%'))
      LIMIT 1
 );

-- Top 20: AC. ANTI DENGUE (NS1, IgM, IgG) (Clave: 330) | Match por Clave y Nombre
UPDATE cat_estudios
   SET top20_orden       = 20,
       muestra           = COALESCE(NULLIF('Suero', ''), muestra),
       contenedor        = COALESCE(NULLIF('Tubo amarillo', ''), contenedor),
       tiempo            = COALESCE(NULLIF('0', ''), tiempo),
       preparacion       = COALESCE(NULLIF('No aplica', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('Antígeno NS1\nAnticuerpos IgM\nAnticuerpos IgG', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '330'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('AC. ANTI DENGUE (NS1, IgM, IgG)'))
        OR LOWER(TRIM('AC. ANTI DENGUE (NS1, IgM, IgG)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('AC. ANTI DENGUE (NS1, IgM, IgG)')), '%'));
UPDATE rel_estudio_gabinete
   SET orden = 20
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '330'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('AC. ANTI DENGUE (NS1, IgM, IgG)'))
             OR LOWER(TRIM('AC. ANTI DENGUE (NS1, IgM, IgG)')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('AC. ANTI DENGUE (NS1, IgM, IgG)')), '%'))
      LIMIT 1
 );

SET FOREIGN_KEY_CHECKS = 1;
-- Validar Top 20 asignado en el catálogo
SELECT id, clave, nombre, top20_orden, activo FROM cat_estudios WHERE top20_orden IS NOT NULL ORDER BY top20_orden ASC;