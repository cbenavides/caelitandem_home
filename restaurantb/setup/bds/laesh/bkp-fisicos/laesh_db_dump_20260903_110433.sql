-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: laesh_db
-- ------------------------------------------------------
-- Server version	11.8.8-MariaDB-ubu2404-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `cat_estados_medico`
--

DROP TABLE IF EXISTS `cat_estados_medico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cat_estados_medico` (
  `id` tinyint(3) unsigned NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de estados del médico: 1=Activo, 2=Pausado';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cat_estados_medico`
--

LOCK TABLES `cat_estados_medico` WRITE;
/*!40000 ALTER TABLE `cat_estados_medico` DISABLE KEYS */;
INSERT INTO `cat_estados_medico` VALUES (1,'Activo','El médico puede crear y consultar órdenes'),(2,'Pausado','El médico no puede crear órdenes; su historial se conserva');
/*!40000 ALTER TABLE `cat_estados_medico` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `catalogo_categorias`
--

DROP TABLE IF EXISTS `catalogo_categorias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `catalogo_categorias` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `grupo_id` int(10) unsigned NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `orden` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `grupo_id` (`grupo_id`),
  CONSTRAINT `catalogo_categorias_ibfk_1` FOREIGN KEY (`grupo_id`) REFERENCES `catalogo_grupos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogo_categorias`
--

LOCK TABLES `catalogo_categorias` WRITE;
/*!40000 ALTER TABLE `catalogo_categorias` DISABLE KEYS */;
INSERT INTO `catalogo_categorias` VALUES (1,1,'Hematología',1),(2,1,'Química Clínica',2),(3,1,'Electrolitos Séricos',3),(4,1,'Uroanálisis',4),(5,1,'Coagulación',5),(6,1,'Lípidos',6),(7,2,'Función Hepática',1),(8,2,'Función Tiroidea',2),(9,2,'Función Pancreática',3),(10,2,'Función Renal',4),(11,2,'Función Cardiaca',5),(12,2,'Gasometría',6),(13,3,'Hormonas',1),(14,3,'Diabetes',2),(15,3,'Inmunología',3),(16,3,'Reumatología',4),(17,3,'Diversos',5),(18,4,'Bacteriología',1),(19,4,'Marcadores Tumorales',2),(20,4,'Parasitología',3),(21,4,'Citroquímicos',4),(22,4,'Biología Molecular',5),(23,4,'Fertilidad',6);
/*!40000 ALTER TABLE `catalogo_categorias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `catalogo_estados`
--

DROP TABLE IF EXISTS `catalogo_estados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `catalogo_estados` (
  `id` tinyint(3) unsigned NOT NULL,
  `valor` varchar(50) NOT NULL COMMENT 'Valor canónico: Remitido|En Atención|Resultados Listos|Cerrada',
  `descripcion` varchar(255) DEFAULT NULL,
  `color_hex` char(7) DEFAULT '#6B7280' COMMENT 'Color UI para badges de estado',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Estados de orden: 1=Remitido, 2=En Atención, 3=Resultados Listos, 4=Cerrada';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogo_estados`
--

LOCK TABLES `catalogo_estados` WRITE;
/*!40000 ALTER TABLE `catalogo_estados` DISABLE KEYS */;
INSERT INTO `catalogo_estados` VALUES (1,'Remitido','Orden creada por el médico, en espera de atención en recepción','#F59E0B'),(2,'En Atención','Paciente recibido en recepción, muestras en proceso','#3B82F6'),(3,'Resultados Listos','PDF de resultados cargado, disponible para el médico','#10B981'),(4,'Cerrada','Orden finalizada y entregada','#6B7280');
/*!40000 ALTER TABLE `catalogo_estados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `catalogo_estudios`
--

DROP TABLE IF EXISTS `catalogo_estudios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `catalogo_estudios` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `categoria_id` int(10) unsigned NOT NULL,
  `clave_interna` varchar(20) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `tiempo_procesamiento` varchar(100) DEFAULT '',
  `muestra_requerida` varchar(255) DEFAULT '',
  `preparacion` varchar(255) DEFAULT '',
  `detalle` text DEFAULT NULL,
  `precio` decimal(10,2) DEFAULT 0.00,
  `activo` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_estudios_cat_activo` (`categoria_id`,`activo`,`id`),
  FULLTEXT KEY `ft_nombre` (`nombre`),
  CONSTRAINT `catalogo_estudios_ibfk_1` FOREIGN KEY (`categoria_id`) REFERENCES `catalogo_categorias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=145 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogo_estudios`
--

LOCK TABLES `catalogo_estudios` WRITE;
/*!40000 ALTER TABLE `catalogo_estudios` DISABLE KEYS */;
INSERT INTO `catalogo_estudios` VALUES (1,1,'HEM-01','BHC','4 Horas','Sangre total (Tubo Lila/EDTA)','Sin ayuno estricto (ideal 4 hrs)',NULL,0.00,1),(2,1,'HEM-02','GRUPO SANGUINEO y FACTOR Rh','2 Horas','Sangre total (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(3,1,'HEM-03','Plaquetas','4 Horas','Sangre total (Tubo Lila/EDTA)','Sin ayuno',NULL,0.00,1),(4,1,'GEN-6552','VSG','','','',NULL,0.00,1),(5,1,'HEM-05','Reticulocitos','6 Horas','Sangre total (Tubo Lila/EDTA)','Sin ayuno',NULL,0.00,1),(6,1,'GEN-8794','Perfil de Hierro','','','',NULL,0.00,1),(7,2,'GEN-8558','QS3','','','',NULL,0.00,1),(8,2,'GEN-1807','QS7','','','',NULL,0.00,1),(9,2,'GEN-7978','Perfil Bioquímico 15/24/30/35/45','','','',NULL,0.00,1),(10,2,'GEN-1927','Glucosa','','','',NULL,0.00,1),(11,2,'GEN-6331','Creatinina','','','',NULL,0.00,1),(12,2,'GEN-1746','Colesterol','','','',NULL,0.00,1),(13,2,'QUI-11','Triglicéridos','2 Horas','Suero (Tubo Rojo)','9–12 hrs de ayuno',NULL,0.00,1),(14,3,'GEN-1844','ES 3/4/Completos','','','',NULL,0.00,1),(15,3,'GEN-9574','Calcio','','','',NULL,0.00,1),(16,3,'GEN-2936','Fósforo','','','',NULL,0.00,1),(17,3,'GEN-9539','Magnesio','','','',NULL,0.00,1),(18,3,'GEN-6777','Bicarbonato CO2','','','',NULL,0.00,1),(19,4,'URO-01','EXAMEN GENERAL DE ORINA CUANTITATIVO','4 Horas','Orina de primer chorro (frasco limpio)','Sin ayuno; orina matutina preferida',NULL,0.00,1),(20,4,'GEN-7280','EGO Especializado','','','',NULL,0.00,1),(21,4,'GEN-3945','Antidoping 5/12 elem.','','','',NULL,0.00,1),(22,5,'GEN-7159','Perfil de Coagulación','','','',NULL,0.00,1),(23,5,'GEN-2337','TP/INR','','','',NULL,0.00,1),(24,5,'GEN-3713','TTPa','','','',NULL,0.00,1),(25,5,'COA-05','Fibrinógeno','4 Horas','Plasma (Tubo Azul citrato)','Sin ayuno',NULL,0.00,1),(26,5,'COA-06','Dímero D','4 Horas','Plasma (Tubo Azul citrato)','Sin ayuno',NULL,0.00,1),(27,5,'GEN-8787','T. Sangrado','','','',NULL,0.00,1),(28,6,'GEN-1869','Perfil de Lípidos I','','','',NULL,0.00,1),(29,6,'GEN-3650','II','','','',NULL,0.00,1),(30,6,'GEN-7130','Perfil Aterogénico','','','',NULL,0.00,1),(31,7,'GEN-2807','PFH Básico','','','',NULL,0.00,1),(32,7,'GEN-1460','PFH Completo','','','',NULL,0.00,1),(33,7,'GEN-7111','Transaminasas','','','',NULL,0.00,1),(34,7,'GEN-7275','GGT','','','',NULL,0.00,1),(35,7,'GEN-9831','Proteínas Totales','','','',NULL,0.00,1),(36,7,'GEN-9313','Albumina','','','',NULL,0.00,1),(37,8,'GEN-2914','Perfil Tiroideo I-IV','','','',NULL,0.00,1),(38,8,'GEN-8400','TSH','','','',NULL,0.00,1),(39,8,'GEN-3254','Ac. Anti Tiroideos I-II','','','',NULL,0.00,1),(40,8,'GEN-6247','Ac. Anti Receptor TSH','','','',NULL,0.00,1),(41,8,'GEN-9679','Tiroglobulina','','','',NULL,0.00,1),(42,9,'PAN-01','Amilasa sérica','2 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(43,9,'PAN-02','Lipasa sérica','2 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(44,10,'REN-01','Cistatina C','24 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(45,10,'GEN-4480','Depuración creatinina','','','',NULL,0.00,1),(46,10,'GEN-2858','Proteínas orina','','','',NULL,0.00,1),(47,10,'REN-04','Microalbuminuria','4 Horas','Orina de primer chorro o 24 h','Sin ayuno; orina matutina preferida',NULL,0.00,1),(48,11,'GEN-8934','Triage cardiaco','','','',NULL,0.00,1),(49,11,'GEN-6200','Perfil cardiaco completo','','','',NULL,0.00,1),(50,11,'CAR-03','Troponina I','1 Hora','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(51,11,'CAR-04','Troponina T','1 Hora','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(52,11,'GEN-1322','NT-pro BNP','','','',NULL,0.00,1),(53,11,'CAR-07','Mioglobina','1 Hora','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(54,12,'GAS-01','GASOMETRIA ARTERIAL COMPLETA','1 Hora','Sangre arterial (jeringa heparinizada)','Sin ayuno; urgencia; procesamiento inmediato (<15 min)',NULL,0.00,1),(55,12,'GAS-02','Gasometría Venosa Completa','1 Hora','Sangre venosa (jeringa heparinizada)','Sin ayuno; procesamiento inmediato (<15 min)',NULL,0.00,1),(56,13,'GEN-1406','Perfil Ginecológico I-II','','','',NULL,0.00,1),(57,13,'GEN-4207','Perfil Hormonal Masculino','','','',NULL,0.00,1),(58,13,'GEN-6206','FSH','','','',NULL,0.00,1),(59,13,'GEN-1645','LH','','','',NULL,0.00,1),(60,13,'GEN-7406','PRL','','','',NULL,0.00,1),(61,13,'GEN-4307','PROG','','','',NULL,0.00,1),(62,13,'GEN-7092','TESTOSTERONA Total/Libre','','','',NULL,0.00,1),(63,13,'GEN-6345','DHEA-S','','','',NULL,0.00,1),(64,13,'HOR-12','Cortisol','24 Horas','Suero (Tubo Rojo)','Sin ayuno; muestra matutina (8–9 am); sin estrés previo',NULL,0.00,1),(65,13,'GEN-8913','AMH','','','',NULL,0.00,1),(66,13,'GEN-2442','PTH-i','','','',NULL,0.00,1),(67,14,'GEN-8561','HbA1c','','','',NULL,0.00,1),(68,14,'DIA-02','Insulina','4 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(69,14,'GEN-2486','HOMA-IR','','','',NULL,0.00,1),(70,14,'DIA-04','Péptido C','24 Horas','Suero (Tubo Rojo)','8 hrs de ayuno',NULL,0.00,1),(71,14,'GEN-9787','Prueba de Tolerancia Glucosa','','','',NULL,0.00,1),(72,14,'GEN-7428','Test O\'Sullivan','','','',NULL,0.00,1),(73,15,'GEN-2743','HIV 1/2','','','',NULL,0.00,1),(74,15,'GEN-6197','V.D.R.L.','','','',NULL,0.00,1),(75,15,'INM-03','Reacciones Febriles','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(76,15,'GEN-1076','Hepatitis A-B-C','','','',NULL,0.00,1),(77,15,'GEN-5580','Dengue','','','',NULL,0.00,1),(78,15,'GEN-8487','COVID-19','','','',NULL,0.00,1),(79,15,'GEN-5761','Coombs','','','',NULL,0.00,1),(80,15,'INM-15','Procalcitonina','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(81,16,'GEN-6885','Perfil Reumático','','','',NULL,0.00,1),(82,16,'GEN-9635','PCR','','','',NULL,0.00,1),(83,16,'GEN-9830','Factor Reumatoide','','','',NULL,0.00,1),(84,16,'GEN-8074','CCP','','','',NULL,0.00,1),(85,16,'GEN-5186','ANA','','','',NULL,0.00,1),(86,16,'GEN-9904','Anti DNA','','','',NULL,0.00,1),(87,16,'GEN-6329','Complementos C3/C4','','','',NULL,0.00,1),(88,17,'GEN-8910','Vitamina D','','','',NULL,0.00,1),(89,17,'GEN-5010','Inmunoglobulina E','','','',NULL,0.00,1),(90,17,'GEN-5032','Somatomedina C','','','',NULL,0.00,1),(91,17,'GEN-6913','Papanicolaou','','','',NULL,0.00,1),(92,18,'GEN-3694','Cultivo de orina MIC','','','',NULL,0.00,1),(93,18,'GEN-6253','Ex. Faríngeo MIC','','','',NULL,0.00,1),(94,18,'GEN-5756','Ex. Vaginal MIC','','','',NULL,0.00,1),(95,18,'GEN-8973','Uretral MIC','','','',NULL,0.00,1),(96,18,'GEN-3626','Heces MIC','','','',NULL,0.00,1),(97,18,'GEN-2059','Lesión MIC','','','',NULL,0.00,1),(98,18,'GEN-4065','Expectoración MIC','','','',NULL,0.00,1),(99,18,'GEN-6380','Hemocultivo MIC','','','',NULL,0.00,1),(100,18,'BAC-09','Cultivo Micológico','21 Días','Muestra según sitio (raspado, hisopo, biopsia)','Suspender antifúngicos tópicos y sistémicos 7 días antes',NULL,0.00,1),(101,19,'GEN-3483','PSA Total','','','',NULL,0.00,1),(102,19,'GEN-3504','PSA Libre','','','',NULL,0.00,1),(103,19,'GEN-4416','CEA','','','',NULL,0.00,1),(104,19,'GEN-3002','AFP','','','',NULL,0.00,1),(105,19,'GEN-7655','CA-125','','','',NULL,0.00,1),(106,19,'GEN-8602','CA-15-3','','','',NULL,0.00,1),(107,19,'GEN-1102','CA-19-9','','','',NULL,0.00,1),(108,19,'GEN-4885','Perfil Tumoral Femenino/Masculino','','','',NULL,0.00,1),(109,20,'PAR-01','Coproparasitoscópico 3 muestras','24 Horas','Heces (3 muestras en frasco LAESH)','Muestras en días alternos; sin bario, bismuto ni antiparasitarios 3 días antes',NULL,0.00,1),(110,20,'GEN-4725','Coprológico completo/especial','','','',NULL,0.00,1),(111,20,'GEN-1815','Sangre Oculta','','','',NULL,0.00,1),(112,20,'GEN-7333','H. Pylori','','','',NULL,0.00,1),(113,20,'GEN-9700','Calprotectina','','','',NULL,0.00,1),(114,20,'GEN-4095','Lactoferrina','','','',NULL,0.00,1),(115,20,'GEN-9252','Clostridium difficile','','','',NULL,0.00,1),(116,21,'GEN-4856','LCR','','','',NULL,0.00,1),(117,21,'GEN-6279','Sinovial','','','',NULL,0.00,1),(118,21,'GEN-1077','Pleural','','','',NULL,0.00,1),(119,21,'GEN-4103','Ascitis','','','',NULL,0.00,1),(120,21,'GEN-2696','Diálisis','','','',NULL,0.00,1),(121,21,'GEN-3510','Bronquial','','','',NULL,0.00,1),(122,21,'GEN-7428','Pericárdico','','','',NULL,0.00,1),(123,22,'GEN-6241','PCR VPH','','','',NULL,0.00,1),(124,22,'GEN-2374','PCR Mycobacterium','','','',NULL,0.00,1),(125,22,'GEN-9525','PCR Patógenos respiratorios','','','',NULL,0.00,1),(126,22,'GEN-3235','PCR Meningitis viral','','','',NULL,0.00,1),(127,22,'GEN-6541','PCR SARS-CoV-2','','','',NULL,0.00,1),(128,23,'GEN-4575','Espermatobioscopia directa','','','',NULL,0.00,1),(129,2,'QUI-02','QUIMICA SANGUINEA COMPLETA (7 ELEMENTOS)','4 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(130,14,'DIA-01','HEMOGLOBINA GLICADA (Hb A1c)','4 Horas','Sangre total (Tubo Lila/EDTA)','Sin ayuno',NULL,0.00,1),(131,2,'QUI-01','QUIMICA SANGUINEA ( 3 ELEMENTOS)','4 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(132,3,'ELE-03','ELECTROLITOS SERICOS COMPLETOS','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(133,5,'COA-01','PERFIL DE COAGULACION 1 (TP, INR, TTP)','4 Horas','Plasma (Tubo Azul citrato)','Sin ayuno; no suspender anticoagulantes sin indicación médica',NULL,0.00,1),(134,7,'HEP-01','PERFIL HEPATICO (PFH)','4 Horas','Suero (Tubo Rojo)','8 hrs de ayuno (preferible)',NULL,0.00,1),(135,8,'TIR-01','PERFIL TIROIDEO 1','24 Horas','Suero (Tubo Rojo)','Sin ayuno; tomar muestra antes del medicamento tiroideo',NULL,0.00,1),(136,3,'ELE-02','ELECTROLITOS SERICOS (Na, K, Cl, Ca)','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(137,14,'DIA-03','RESISTENCIA A LAINSULINA (HOMA-IR, %8, %S).','4 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(138,7,'HEP-02','PERFIL HEPATICO 2 (PFH 2)','8 Horas','Suero + Plasma (Tubo Rojo y Azul)','8 hrs de ayuno',NULL,0.00,1),(139,6,'LIP-01','PERFIL DE LIPIDOS','4 Horas','Suero (Tubo Rojo)','9–12 hrs de ayuno',NULL,0.00,1),(140,8,'TIR-02','PERFIL TIROIDEO 2','24 Horas','Suero (Tubo Rojo)','Sin ayuno; tomar muestra antes del medicamento tiroideo',NULL,0.00,1),(141,3,'ELE-01','ELECTROLITOS SERICOS (Na, K, Cl)','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1),(142,2,'QUI-03','PERFIL BIOQUIMICO 15 ELEMENTOS','24 Horas','Suero (Tubo Rojo)','8–12 hrs de ayuno',NULL,0.00,1),(143,4,'URO-02','EXAMEN DE ORINA ESPECIALIZADO (Ego + Coc. Alb/Cre)','4 Horas','Orina de primer chorro (frasco limpio)','Sin ayuno; orina matutina preferida',NULL,0.00,1),(144,15,'INM-13','AC. ANTI DENGUE (NS1, IgM, IgG)','4 Horas','Suero (Tubo Rojo)','Sin ayuno',NULL,0.00,1);
/*!40000 ALTER TABLE `catalogo_estudios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `catalogo_grupos`
--

DROP TABLE IF EXISTS `catalogo_grupos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `catalogo_grupos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `clave` varchar(10) NOT NULL,
  `titulo` varchar(255) NOT NULL,
  `orden` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `clave` (`clave`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogo_grupos`
--

LOCK TABLES `catalogo_grupos` WRITE;
/*!40000 ALTER TABLE `catalogo_grupos` DISABLE KEYS */;
INSERT INTO `catalogo_grupos` VALUES (1,'cg1','Rutina General — Hematología, Química Clínica, Electrolitos, Uroanálisis, CoagulaciónTT',1),(2,'cg2','Función de Órganos — Hepática, Tiroidea, Pancreática, Renal, Cardiaca, GasometríaYY',2),(3,'cg3','Hormonas, Diabetes e Inmunología — Perfil Ginecológico, Masculino, Diabetes, Inmunología, Reumatología',3),(4,'cg4','Bacteriología, Marcadores Tumorales, Parasitología, Citroquímicos, Biología Molecular, Fertilidad',4);
/*!40000 ALTER TABLE `catalogo_grupos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `catalogo_promociones`
--

DROP TABLE IF EXISTS `catalogo_promociones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `catalogo_promociones` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `estudio_id` int(10) unsigned DEFAULT NULL,
  `dia_semana` varchar(255) NOT NULL,
  `nombre_oferta` varchar(255) NOT NULL,
  `subtitulo` varchar(255) DEFAULT '',
  `descripcion` text DEFAULT NULL,
  `ayuno` varchar(255) DEFAULT NULL,
  `tiempo_entrega` varchar(255) DEFAULT NULL,
  `precio_regular` decimal(10,2) DEFAULT NULL,
  `precio_oferta` decimal(10,2) DEFAULT NULL,
  `imagen_fondo` varchar(255) DEFAULT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `orden` int(11) DEFAULT 0,
  `creado_en` timestamp NULL DEFAULT current_timestamp(),
  `actualizado_en` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `estudio_id` (`estudio_id`),
  KEY `idx_promos_activo_orden` (`activo`,`orden`,`id`),
  CONSTRAINT `catalogo_promociones_ibfk_1` FOREIGN KEY (`estudio_id`) REFERENCES `catalogo_estudios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogo_promociones`
--

LOCK TABLES `catalogo_promociones` WRITE;
/*!40000 ALTER TABLE `catalogo_promociones` DISABLE KEYS */;
INSERT INTO `catalogo_promociones` VALUES (1,1,'Lunes','Biometría Hemática Completa (BHC)','Hematología · Marcador de inflamación aguda y crónica','Análisis completo de células sanguíneas (glóbulos rojos, blancos y plaquetas). Ideal para detección temprana de anemia e infecciones.','Sin ayuno estricto (ideal 4 hrs)','4 Horas',220.00,150.00,'/laesh-web-assets-uipv1a/img/cms/promo-lunes-bhc.webp',1,1,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(2,129,'Martes','Química Sanguínea Completa (7 Elementos)','Química Clínica · Evaluación metabólica y renal integral','Mide glucosa, urea, creatinina, ácido úrico, colesterol, triglicéridos y nitrógeno ureico. Diagnóstico preventivo completo.','Ayuno de 8 a 12 hrs','Mismo día (6 hrs)',350.00,260.00,'/laesh-web-assets-uipv1a/img/cms/promo-martes-qs7.webp',1,2,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(3,19,'Miércoles','Examen General de Orina Cuantitativo (EGO)','Uroanálisis · Tamizaje del sistema urinario y renal','Evaluación fisicoquímica y microscópica de la orina para descartar infecciones de vías urinarias y función renal.','Primera orina de la mañana','3 Horas',140.00,95.00,'/laesh-web-assets-uipv1a/img/cms/promo-miercoles-ego.webp',1,3,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(4,130,'Jueves','Hemoglobina Glicada (Hb A1c)','Diabetes · Control glicémico retrospectivo de 90 días','Prueba estándar de oro para el monitoreo y control glucémico de los últimos 3 meses en pacientes con sospecha o diagnóstico de diabetes.','Sin ayuno necesario','4 Horas',280.00,195.00,'/laesh-web-assets-uipv1a/img/cms/promo-jueves-hba1c.webp',1,4,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(5,133,'Viernes','Perfil de Coagulación 1 (TP, INR, TTP)','Coagulación · Valoración pre-quirúrgica y hemostática','Pruebas hemostáticas fundamentales para medir tiempos de protrombina y tromboplastina parcial activa.','Ayuno de 4 hrs','4 Horas',310.00,220.00,'/laesh-web-assets-uipv1a/img/lunes.webp',1,5,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(6,134,'Sábado','Perfil Hepático (PFH)','Función Hepática · Evaluación de enzimas hepáticas e ictericia','Incluye bilirrubinas, transaminasas (TGO/TGP), fosfatasa alcalina y proteínas totales para valoración del hígado.','Ayuno de 8 hrs','6 Horas',420.00,310.00,'/laesh-web-assets-uipv1a/img/cms/promo-sabado-pfh.webp',1,6,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(7,135,'Domingo','Perfil Tiroideo 1 (TSH, T4, T3)','Función Tiroidea · Tamizaje de hipo e hipertiroidismo','Determinación hormonal para descartar alteraciones del metabolismo basal, tiroides e hipermetabolismo.','Ayuno de 8 hrs','24 Horas',480.00,350.00,NULL,1,7,'2026-09-03 01:53:37','2026-09-03 01:53:37');
/*!40000 ALTER TABLE `catalogo_promociones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `catalogos_ui`
--

DROP TABLE IF EXISTS `catalogos_ui`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `catalogos_ui` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tipo` varchar(50) NOT NULL COMMENT 'universidad|lugar_trabajo — discriminador de tipo',
  `valor` varchar(255) NOT NULL,
  `orden` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_tipo_activo` (`tipo`,`activo`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogos polimórficos para selects dinámicos de UI (universidad, lugar_trabajo)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogos_ui`
--

LOCK TABLES `catalogos_ui` WRITE;
/*!40000 ALTER TABLE `catalogos_ui` DISABLE KEYS */;
INSERT INTO `catalogos_ui` VALUES (1,'universidad','Universidad Nacional Autónoma de México (UNAM)',1,1),(2,'universidad','Universidad Autónoma Benito Juárez de Oaxaca',2,1),(3,'universidad','Universidad Autónoma Metropolitana (UAM)',3,1),(4,'universidad','Instituto Politécnico Nacional (IPN)',4,1),(5,'universidad','Universidad Autónoma de Guadalajara',5,1),(6,'universidad','Universidad Autónoma de Puebla (BUAP)',6,1),(7,'universidad','Universidad Veracruzana',7,1),(8,'universidad','Universidad Autónoma del Estado de México',8,1),(9,'universidad','Otra universidad',99,1),(10,'lugar_trabajo','Consultorio particular',1,1),(11,'lugar_trabajo','Hospital General de Huajuapan',2,1),(12,'lugar_trabajo','IMSS — Delegación Oaxaca',3,1),(13,'lugar_trabajo','ISSSTE — Unidad Huajuapan',4,1),(14,'lugar_trabajo','Clínica privada',5,1),(15,'lugar_trabajo','Hospital Regional de la Mixteca',6,1),(16,'lugar_trabajo','Otro',99,1);
/*!40000 ALTER TABLE `catalogos_ui` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `configuraciones`
--

DROP TABLE IF EXISTS `configuraciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `configuraciones` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `clave` varchar(100) NOT NULL,
  `valor` text DEFAULT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_clave` (`clave`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Parámetros globales de la instancia LAESH (singleton por clave)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuraciones`
--

LOCK TABLES `configuraciones` WRITE;
/*!40000 ALTER TABLE `configuraciones` DISABLE KEYS */;
INSERT INTO `configuraciones` VALUES (1,'nombre_laboratorio','Laboratorio de Especialidades Hematológicas','Nombre oficial del laboratorio','2026-09-03 01:53:37'),(2,'nombre_corto','LAESH','Nombre corto / marca','2026-09-03 01:53:37'),(3,'direccion','Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.','Dirección física — reutilizada en Ubicación, Footer y Schema.org','2026-09-03 01:53:37'),(4,'cp','69007','Código postal — Schema.org postalCode','2026-09-03 01:53:37'),(5,'telefono','953 688 7694','Teléfono directo — reutilizado en Ubicación, Footer y Schema.org','2026-09-03 01:53:37'),(6,'email_contacto','lab_laesh@hotmail.com','Correo de contacto público — reutilizado en Ubicación y Footer','2026-09-03 01:53:37'),(7,'whatsapp_url','https://wa.me/529531190074','Enlace de WhatsApp con código de país — D-04: vive en configuraciones','2026-09-03 01:53:37'),(8,'whatsapp_numero','953 119 0074','Número WhatsApp formato display (sin código de país) — Footer, Ubicación','2026-09-03 01:53:37'),(9,'horario_semana','Lunes a sábado: 7:00 a.m. – 9:00 p.m.','Horario días hábiles — Footer, Ubicación, Schema.org','2026-09-03 01:53:37'),(10,'horario_domingo','Domingo: 7:00 a.m. – 3:00 p.m.','Horario domingo — Footer, Ubicación, Schema.org','2026-09-03 01:53:37'),(11,'hrs_open','07:00','Apertura Lun–Sáb HH:MM 24h — Schema.org openingHoursSpecification','2026-09-03 01:53:37'),(12,'hrs_close','21:00','Cierre Lun–Sáb HH:MM 24h — Schema.org openingHoursSpecification','2026-09-03 01:53:37'),(13,'dom_open','07:00','Apertura domingo HH:MM 24h — Schema.org openingHoursSpecification','2026-09-03 01:53:37'),(14,'dom_close','15:00','Cierre domingo HH:MM 24h — Schema.org openingHoursSpecification','2026-09-03 01:53:37'),(15,'responsable_nombre','Q.F.B. y E.H.D.L. Jacob Santiago Blanco','Nombre completo con grado del responsable sanitario','2026-09-03 01:53:37'),(16,'responsable_cedula_prof','3609293','Cédula profesional del responsable sanitario','2026-09-03 01:53:37'),(17,'responsable_cedula_esp','8935780','Cédula de especialidad del responsable sanitario','2026-09-03 01:53:37'),(18,'facebook_url','https://www.facebook.com/profile.php?id=100072263716098','URL de la página oficial de Facebook del laboratorio','2026-09-03 01:53:37'),(19,'maps_url','https://www.google.com/maps/place/Laboratorio+de+Especialidades+Hematol%C3%B3gicas+S.C./@17.8030093,-97.7777261,18z/data=!4m6!3m5!1s0x85c60141d7aa4483:0x730f884bc7308bee!8m2!3d17.8028691!4d-97.7779575!16s%2Fg%2F11ry4m4j5r','URL directa a la ubicación en Google Maps','2026-09-03 01:53:37'),(20,'wa_texto_agendar','Hola LAESH, me interesa agendar el estudio de {estudio}','Texto pre-llenado de WhatsApp al agendar en Promociones','2026-09-03 01:53:37'),(21,'wa_texto_info','Hola LAESH, necesito información','Texto pre-llenado de WhatsApp para consultas generales','2026-09-03 01:53:37'),(22,'tiempo_rotacion_dias','90','Días de validez antes de solicitar cambio de contraseña (admin policy)','2026-09-03 01:53:37'),(23,'tiempo_depuracion_pdf_meses','12','Meses de retención de archivos PDF generados antes de la depuración automática','2026-09-03 01:53:37'),(24,'ruta_almacenamiento_pdf','/var/www/html/laesh-bloc-assets/pdf/','Ruta física de almacenamiento seguro de PDFs de recibos','2026-09-03 01:53:37'),(25,'anios_experiencia','25','Años de experiencia — usado en mensajes del sitio web','2026-09-03 01:53:37'),(26,'session_lifetime','518400','Duración de sesión PHP en segundos. 86400=24h · 518400=6 días. Se aplica en commons.php al iniciar sesión. Requiere recargar la página para que el nuevo valor tenga efecto.','2026-09-03 01:53:37');
/*!40000 ALTER TABLE `configuraciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_ordenes`
--

DROP TABLE IF EXISTS `detalle_ordenes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_ordenes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int(10) unsigned NOT NULL,
  `estudio_id` int(10) unsigned NOT NULL,
  `precio_snap` decimal(10,2) DEFAULT NULL COMMENT 'Precio al momento de la orden (snapshot)',
  PRIMARY KEY (`id`),
  KEY `idx_orden` (`orden_id`),
  KEY `fk_detalle_estudio` (`estudio_id`),
  CONSTRAINT `fk_detalle_estudio` FOREIGN KEY (`estudio_id`) REFERENCES `catalogo_estudios` (`id`),
  CONSTRAINT `fk_detalle_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Estudios individuales por orden (N:M ordenes ↔ estudios)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ordenes`
--

LOCK TABLES `detalle_ordenes` WRITE;
/*!40000 ALTER TABLE `detalle_ordenes` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalle_ordenes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `empleados`
--

DROP TABLE IF EXISTS `empleados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `empleados` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL COMMENT 'FK users.id (Delight-Auth)',
  `nombre` varchar(100) NOT NULL,
  `apellidos` varchar(200) NOT NULL,
  `rol` enum('MEDICO','RECEPCION','ADMIN') NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Boolean simple para recepción/admin (D-05)',
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_id` (`user_id`),
  KEY `idx_rol` (`rol`),
  CONSTRAINT `fk_emp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Extensión de users para personal LAESH — rol operativo y estado activo';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `empleados`
--

LOCK TABLES `empleados` WRITE;
/*!40000 ALTER TABLE `empleados` DISABLE KEYS */;
INSERT INTO `empleados` VALUES (1,1,'Admin','LAESH','ADMIN',1,'2026-09-03 01:53:37'),(2,2,'Recepcion','Demo','RECEPCION',1,'2026-09-03 01:53:37'),(3,3,'Hedilberto','Reyes Venegas','MEDICO',1,'2026-09-03 01:53:37'),(4,4,'Elena','Torres Vance','MEDICO',1,'2026-09-03 01:53:37'),(5,5,'Carlos','Fuentes Morales','MEDICO',1,'2026-09-03 01:53:37'),(6,6,'Sofía','Medina Ortiz','MEDICO',1,'2026-09-03 01:53:37'),(7,7,'Roberto','Mendoza Silva','MEDICO',1,'2026-09-03 01:53:38');
/*!40000 ALTER TABLE `empleados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fallback_log`
--

DROP TABLE IF EXISTS `fallback_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fallback_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `nivel` enum('WARN','ERROR','FALLBACK','CRITICAL') NOT NULL DEFAULT 'ERROR',
  `origen` varchar(120) DEFAULT NULL COMMENT 'Archivo:línea del caller',
  `funcion` varchar(80) DEFAULT NULL COMMENT 'Clase::método del caller',
  `query_type` enum('SELECT','INSERT','UPDATE','DELETE','CALL','OTHER') DEFAULT 'OTHER',
  `query_hash` char(8) CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL COMMENT 'CRC32 de query_text para agrupar repeticiones',
  `query_text` text DEFAULT NULL COMMENT 'Sentencia SQL fallida',
  `error_msg` varchar(300) DEFAULT NULL COMMENT 'Mensaje de error PDO',
  `fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_nivel` (`nivel`),
  KEY `idx_fecha` (`fecha`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Log técnico de errores SQL/PHP — retención indefinida, revisión manual requerida';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fallback_log`
--

LOCK TABLES `fallback_log` WRITE;
/*!40000 ALTER TABLE `fallback_log` DISABLE KEYS */;
INSERT INTO `fallback_log` VALUES (1,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 02:39:44'),(2,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:31:29'),(3,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:24'),(4,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:24'),(5,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:25'),(6,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:25'),(7,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:26'),(8,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:27'),(9,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:28'),(10,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:28'),(11,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:28'),(12,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:29'),(13,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:29'),(14,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:29'),(15,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:29'),(16,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 03:59:54'),(17,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:00:58'),(18,'ERROR','negocio/Ordenes.php:174','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:08:10'),(19,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:33'),(20,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:34'),(21,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:34'),(22,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:34'),(23,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:36'),(24,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:37'),(25,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:37'),(26,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:37'),(27,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:38'),(28,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:38'),(29,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:18:39'),(30,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:15'),(31,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:22'),(32,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:32'),(33,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:32'),(34,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:33'),(35,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:33'),(36,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:34'),(37,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:36'),(38,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:37'),(39,'ERROR','negocio/Ordenes.php:167','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.cat_estados_orden\' doesn\'t exist','2026-09-03 04:19:38'),(40,'ERROR','home/carlos/GitHub/caelitandem_home/restaurantb/www/laesh-swbldi/md/negocio/Ordenes.php:169','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[HY093]: Invalid parameter number','2026-09-03 04:41:38'),(41,'ERROR','home/carlos/GitHub/caelitandem_home/restaurantb/www/laesh-swbldi/md/negocio/Ordenes.php:169','Common\\DB::logFallback','OTHER','4d3d6743','Fallo en MD\\Negocio\\Ordenes::obtenerPacientesMedico','SQLSTATE[HY093]: Invalid parameter number','2026-09-03 04:41:50');
/*!40000 ALTER TABLE `fallback_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `folios_control`
--

DROP TABLE IF EXISTS `folios_control`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `folios_control` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tipo_documento` varchar(50) NOT NULL COMMENT 'Discriminador: orden_laboratorio | factura | etc.',
  `prefijo` varchar(10) NOT NULL DEFAULT 'LAESH' COMMENT 'Prefijo del folio — ej: LAESH → LAESH-00001',
  `longitud` tinyint(3) unsigned NOT NULL DEFAULT 5 COMMENT 'Dígitos con cero-padding en LPAD — ej: 5 → 00001',
  `ultimo_folio` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Último número emitido — incrementar con SELECT ... FOR UPDATE',
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tipo_documento` (`tipo_documento`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Control de folios correlativos — usar SELECT ... FOR UPDATE para atomicidad';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `folios_control`
--

LOCK TABLES `folios_control` WRITE;
/*!40000 ALTER TABLE `folios_control` DISABLE KEYS */;
INSERT INTO `folios_control` VALUES (1,'orden_laboratorio','LAESH',5,3,'2026-09-03 04:00:37');
/*!40000 ALTER TABLE `folios_control` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_estados_orden`
--

DROP TABLE IF EXISTS `historial_estados_orden`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_estados_orden` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int(10) unsigned NOT NULL,
  `estado_anterior_id` tinyint(3) unsigned DEFAULT NULL COMMENT 'FK catalogo_estados.id (NULL si es creación)',
  `estado_nuevo_id` tinyint(3) unsigned NOT NULL COMMENT 'FK catalogo_estados.id',
  `cambiado_por_user_id` int(10) unsigned DEFAULT NULL COMMENT 'FK users.id — quién realizó el cambio',
  `observacion` varchar(500) DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_orden` (`orden_id`),
  KEY `idx_creado` (`creado_en`),
  KEY `idx_estado_ant` (`estado_anterior_id`),
  KEY `idx_estado_nue` (`estado_nuevo_id`),
  KEY `idx_cambiado_por` (`cambiado_por_user_id`),
  KEY `idx_hist_orden_creado` (`orden_id`,`creado_en`),
  CONSTRAINT `fk_hist_cambiado` FOREIGN KEY (`cambiado_por_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_hist_est_ant` FOREIGN KEY (`estado_anterior_id`) REFERENCES `catalogo_estados` (`id`),
  CONSTRAINT `fk_hist_est_nue` FOREIGN KEY (`estado_nuevo_id`) REFERENCES `catalogo_estados` (`id`),
  CONSTRAINT `fk_hist_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Movimientos de estado por orden — auditoría y reportes de tiempos de atención';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_estados_orden`
--

LOCK TABLES `historial_estados_orden` WRITE;
/*!40000 ALTER TABLE `historial_estados_orden` DISABLE KEYS */;
INSERT INTO `historial_estados_orden` VALUES (1,1,NULL,1,NULL,'Orden creada — estado inicial: Remitido','2026-09-03 02:41:02'),(2,2,NULL,1,NULL,'Orden creada — estado inicial: Remitido','2026-09-03 03:32:15'),(3,3,NULL,1,NULL,'Orden creada — estado inicial: Remitido','2026-09-03 04:00:37');
/*!40000 ALTER TABLE `historial_estados_orden` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notas_orden`
--

DROP TABLE IF EXISTS `notas_orden`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas_orden` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL COMMENT 'FK users.id — autor de la nota',
  `autor_rol` enum('MEDICO','RECEPCION','ADMIN') NOT NULL COMMENT 'Rol snapshot al momento de escribir. ADMIN: extensión intencional sobre spec ET (MEDICO|RECEPCION) para soporte de notas administrativas.',
  `texto` text NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_orden` (`orden_id`),
  KEY `idx_fecha` (`fecha`),
  KEY `idx_user` (`user_id`),
  CONSTRAINT `fk_nota_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_nota_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notas internas por orden entre recepción y médico — con autor_rol snapshot';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notas_orden`
--

LOCK TABLES `notas_orden` WRITE;
/*!40000 ALTER TABLE `notas_orden` DISABLE KEYS */;
/*!40000 ALTER TABLE `notas_orden` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notificaciones`
--

DROP TABLE IF EXISTS `notificaciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificaciones` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL COMMENT 'FK users.id (médico o recepción)',
  `tipo` enum('nueva_orden','resultados_listos','orden_actualizada') NOT NULL,
  `folio_referencia` varchar(20) DEFAULT NULL COMMENT 'folio_unico LAESH-NNNNN de la orden referenciada',
  `mensaje` varchar(500) NOT NULL,
  `url_enlace` varchar(255) DEFAULT NULL COMMENT 'URL de acción directa — ej: /laesh/rc/?orden=LAESH-00001',
  `leido` tinyint(1) NOT NULL DEFAULT 0,
  `entregado_ws` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Fast-path: 1 = entregado vía Swoole WS',
  `retry_count` tinyint(3) unsigned NOT NULL DEFAULT 0 COMMENT 'Intentos de entrega WS fallidos',
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_fallback_poll` (`user_id`,`entregado_ws`,`leido`) COMMENT 'Índice para poll: WHERE user_id=? AND (entregado_ws=0 OR leido=0)',
  CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones sistema — SSOT QoS: Swoole WS + fallback AJAX poll';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notificaciones`
--

LOCK TABLES `notificaciones` WRITE;
/*!40000 ALTER TABLE `notificaciones` DISABLE KEYS */;
INSERT INTO `notificaciones` VALUES (1,3,'nueva_orden','LAESH-00001','Nueva Solicitud Médica Digital (LAESH-00001) — Solicitud enviada para pepe lopez',NULL,0,1,0,'2026-09-03 02:41:02'),(2,2,'nueva_orden','LAESH-00002','Nueva Solicitud Médica Digital (LAESH-00002) — Solicitud enviada para juan manuel',NULL,0,1,0,'2026-09-03 03:32:15'),(3,2,'nueva_orden','LAESH-00003','Nueva Solicitud Médica Digital (LAESH-00003) — Solicitud enviada para ame vazquez',NULL,0,1,0,'2026-09-03 04:00:37');
/*!40000 ALTER TABLE `notificaciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ordenes`
--

DROP TABLE IF EXISTS `ordenes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ordenes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `folio_unico` varchar(20) NOT NULL COMMENT 'LAESH-NNNNN — generado atómicamente por folios_control',
  `paciente_id` int(10) unsigned NOT NULL,
  `medico_id` int(10) unsigned NOT NULL COMMENT 'FK users.id (rol MEDICO)',
  `recepcion_id` int(10) unsigned DEFAULT NULL COMMENT 'FK users.id (rol RECEPCION) — quién capturó',
  `estado_id` tinyint(3) unsigned NOT NULL DEFAULT 1 COMMENT 'FK catalogo_estados.id',
  `edad_al_emitir` tinyint(3) unsigned NOT NULL COMMENT 'D-01: edad clínica en el momento de emisión',
  `diagnostico` varchar(200) DEFAULT NULL COMMENT 'D-01: impresión diagnóstica libre del médico — máx 200 chars (spec ET)',
  `otros_estudios` text DEFAULT NULL COMMENT 'D-01: estudios fuera del catálogo digitalizado (sin límite de chars)',
  `estudios` text DEFAULT NULL COMMENT 'JSON array de nombres (desnormalización para solicitud digital)',
  `hora_captura` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Timestamp de captura de la orden (era creado_en)',
  `fecha_resultado` datetime DEFAULT NULL COMMENT 'Fecha/hora en que se subió el PDF de resultados',
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_folio_unico` (`folio_unico`),
  KEY `idx_paciente` (`paciente_id`),
  KEY `idx_medico` (`medico_id`),
  KEY `idx_estado` (`estado_id`),
  KEY `idx_hora_captura` (`hora_captura`),
  KEY `fk_orden_recepcion` (`recepcion_id`),
  KEY `idx_ordenes_medico_fecha` (`medico_id`,`hora_captura`),
  KEY `idx_ordenes_estado_fecha` (`estado_id`,`hora_captura`),
  CONSTRAINT `fk_orden_estado` FOREIGN KEY (`estado_id`) REFERENCES `catalogo_estados` (`id`),
  CONSTRAINT `fk_orden_medico` FOREIGN KEY (`medico_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_orden_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`id`),
  CONSTRAINT `fk_orden_recepcion` FOREIGN KEY (`recepcion_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Solicitudes de análisis (cabecera) — folio_unico LAESH-NNNNN';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ordenes`
--

LOCK TABLES `ordenes` WRITE;
/*!40000 ALTER TABLE `ordenes` DISABLE KEYS */;
INSERT INTO `ordenes` VALUES (1,'LAESH-00001',1,3,NULL,1,45,'rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr','ddddddddd','[]','2026-09-03 02:41:02',NULL,'2026-09-03 02:41:02'),(2,'LAESH-00002',2,3,NULL,1,12,'aaaaaaaaaaaaaaaaaaa','bbbbbbbbb','[]','2026-09-03 03:32:15',NULL,'2026-09-03 03:32:15'),(3,'LAESH-00003',3,3,NULL,1,12,'hiperactividad','qqqqqqqq','[]','2026-09-03 04:00:37',NULL,'2026-09-03 04:00:37');
/*!40000 ALTER TABLE `ordenes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pacientes`
--

DROP TABLE IF EXISTS `pacientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pacientes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nombre_completo` varchar(200) NOT NULL COMMENT 'Nombre y apellidos como string único — fuente: localStorage form medicos.php',
  `fecha_nacimiento` date DEFAULT NULL,
  `sexo` enum('H','M') NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_pacientes_nombre_completo` (`nombre_completo`(50)),
  FULLTEXT KEY `ft_nombre_completo` (`nombre_completo`) COMMENT 'Búsqueda por nombre para autocomplete de recepción'
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registro demográfico de pacientes — nombre_completo como campo único';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pacientes`
--

LOCK TABLES `pacientes` WRITE;
/*!40000 ALTER TABLE `pacientes` DISABLE KEYS */;
INSERT INTO `pacientes` VALUES (1,'pepe lopez',NULL,'H','5555555555','2026-09-03 02:41:02'),(2,'juan manuel',NULL,'H','9535324298','2026-09-03 03:32:15'),(3,'ame vazquez',NULL,'M','9535324290','2026-09-03 04:00:37');
/*!40000 ALTER TABLE `pacientes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `perfiles_medicos`
--

DROP TABLE IF EXISTS `perfiles_medicos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `perfiles_medicos` (
  `user_id` int(10) unsigned NOT NULL COMMENT 'PK y FK users.id — un perfil por médico',
  `nombre_completo` varchar(255) DEFAULT NULL COMMENT 'Nombre completo del médico (autogenerado/migrado)',
  `especialidad` varchar(150) DEFAULT NULL,
  `cedula_profesional` varchar(50) DEFAULT NULL,
  `celular` varchar(10) DEFAULT NULL COMMENT 'Teléfono celular del médico (10 dígitos)',
  `telefono_consultorio` varchar(20) DEFAULT NULL COMMENT 'Teléfono fijo del consultorio',
  `direccion_consultorio` varchar(255) DEFAULT NULL COMMENT 'Dirección del consultorio (mostrada en solicitud digital)',
  `universidad_id` int(10) unsigned DEFAULT NULL COMMENT 'FK catalogos_ui.id (tipo=universidad)',
  `lugar_trabajo_id` int(10) unsigned DEFAULT NULL COMMENT 'FK catalogos_ui.id (tipo=lugar_trabajo)',
  `estado_id` tinyint(3) unsigned NOT NULL DEFAULT 1 COMMENT 'FK cat_estados_medico.id (1=Activo, 2=Pausado)',
  `total_ordenes` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Contador estadístico de órdenes emitidas',
  `foto_url` varchar(255) DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`),
  KEY `idx_universidad` (`universidad_id`),
  KEY `idx_lugar_trabajo` (`lugar_trabajo_id`),
  KEY `idx_estado` (`estado_id`),
  KEY `idx_pm_estado_user` (`estado_id`,`user_id`),
  CONSTRAINT `fk_pm_estado` FOREIGN KEY (`estado_id`) REFERENCES `cat_estados_medico` (`id`),
  CONSTRAINT `fk_pm_lugar` FOREIGN KEY (`lugar_trabajo_id`) REFERENCES `catalogos_ui` (`id`),
  CONSTRAINT `fk_pm_universidad` FOREIGN KEY (`universidad_id`) REFERENCES `catalogos_ui` (`id`),
  CONSTRAINT `fk_pm_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Perfil extendido de médicos — user_id PK/FK directa, especialidad, cédula, contacto consultorio';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `perfiles_medicos`
--

LOCK TABLES `perfiles_medicos` WRITE;
/*!40000 ALTER TABLE `perfiles_medicos` DISABLE KEYS */;
INSERT INTO `perfiles_medicos` VALUES (3,'Dr(a). Hedilberto Reyes Venegas','Med. Interna',NULL,'9990000003',NULL,NULL,NULL,NULL,1,3,NULL,'2026-09-03 01:53:37','2026-09-03 04:46:24'),(4,'Dr(a). Elena Torres Vance','Ginecología',NULL,'9990000004',NULL,NULL,NULL,NULL,1,0,NULL,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(5,'Dr(a). Carlos Fuentes Morales','Pediatría',NULL,'9990000005',NULL,NULL,NULL,NULL,1,0,NULL,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(6,'Dr(a). Sofía Medina Ortiz','Cardiología',NULL,'9990000006',NULL,NULL,NULL,NULL,1,0,NULL,'2026-09-03 01:53:37','2026-09-03 01:53:37'),(7,'Dr(a). Roberto Mendoza Silva','Med. General',NULL,'9990000007',NULL,NULL,NULL,NULL,1,0,NULL,'2026-09-03 01:53:38','2026-09-03 01:53:38');
/*!40000 ALTER TABLE `perfiles_medicos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rbac_permisos`
--

DROP TABLE IF EXISTS `rbac_permisos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rbac_permisos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL COMMENT 'ej: ver_ordenes_propias, gestionar_cms',
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de permisos granulares RBAC';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rbac_permisos`
--

LOCK TABLES `rbac_permisos` WRITE;
/*!40000 ALTER TABLE `rbac_permisos` DISABLE KEYS */;
INSERT INTO `rbac_permisos` VALUES (1,'ver_ordenes_propias','Médico: consultar y crear sus propias órdenes'),(2,'ver_solicitud_digital','Médico: ver PDF de solicitud digital'),(3,'gestionar_ordenes','Recepción: procesar órdenes, cambiar estados, subir PDFs'),(4,'gestionar_medicos','Recepción/Admin: alta, edición y pausa de médicos'),(5,'gestionar_cms','Admin: editar contenidos del sitio web (CMS)'),(6,'gestionar_estudios','Admin: alta y edición del catálogo de estudios'),(7,'ver_reportes','Admin/Recepción: acceso a reportes de actividad');
/*!40000 ALTER TABLE `rbac_permisos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rbac_permisos_usuarios`
--

DROP TABLE IF EXISTS `rbac_permisos_usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rbac_permisos_usuarios` (
  `user_id` int(10) unsigned NOT NULL COMMENT 'FK users.id (Delight-Auth)',
  `permiso_id` int(10) unsigned NOT NULL,
  `otorgado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`,`permiso_id`),
  KEY `fk_pu_permiso` (`permiso_id`),
  CONSTRAINT `fk_pu_permiso` FOREIGN KEY (`permiso_id`) REFERENCES `rbac_permisos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Asignación permiso → usuario (granular, independiente del rol de empleados)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rbac_permisos_usuarios`
--

LOCK TABLES `rbac_permisos_usuarios` WRITE;
/*!40000 ALTER TABLE `rbac_permisos_usuarios` DISABLE KEYS */;
INSERT INTO `rbac_permisos_usuarios` VALUES (1,3,'2026-09-03 01:53:37'),(1,4,'2026-09-03 01:53:37'),(1,5,'2026-09-03 01:53:37'),(1,6,'2026-09-03 01:53:37'),(1,7,'2026-09-03 01:53:37'),(2,3,'2026-09-03 01:53:37'),(2,4,'2026-09-03 01:53:37'),(2,7,'2026-09-03 01:53:37'),(3,1,'2026-09-03 01:53:37'),(3,2,'2026-09-03 01:53:37'),(4,1,'2026-09-03 01:53:37'),(4,2,'2026-09-03 01:53:37'),(5,1,'2026-09-03 01:53:37'),(5,2,'2026-09-03 01:53:37'),(6,1,'2026-09-03 01:53:37'),(6,2,'2026-09-03 01:53:37'),(7,1,'2026-09-03 01:53:38'),(7,2,'2026-09-03 01:53:38');
/*!40000 ALTER TABLE `rbac_permisos_usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resultados_pdf`
--

DROP TABLE IF EXISTS `resultados_pdf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resultados_pdf` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int(10) unsigned NOT NULL,
  `nombre_archivo` varchar(255) NOT NULL,
  `ruta_storage` varchar(500) NOT NULL COMMENT 'Path en filesystem de la VM OCI',
  `subido_por` int(10) unsigned DEFAULT NULL COMMENT 'FK users.id',
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_orden` (`orden_id`),
  KEY `idx_subido_por` (`subido_por`),
  CONSTRAINT `fk_pdf_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pdf_subido_por` FOREIGN KEY (`subido_por`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PDFs de resultados de laboratorio vinculados a órdenes';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resultados_pdf`
--

LOCK TABLES `resultados_pdf` WRITE;
/*!40000 ALTER TABLE `resultados_pdf` DISABLE KEYS */;
/*!40000 ALTER TABLE `resultados_pdf` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_logs`
--

DROP TABLE IF EXISTS `sys_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `level` enum('DEBUG','INFO','WARN','ERROR','FATAL','CRITICAL') NOT NULL DEFAULT 'INFO',
  `message` text NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL COMMENT 'FK users.id (nullable — puede ser request no autenticado)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_level` (`level`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_syslogs_level_created` (`level`,`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Log operativo PSR-3 — purga auto de INFO/DEBUG >30 días via Event Scheduler';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_logs`
--

LOCK TABLES `sys_logs` WRITE;
/*!40000 ALTER TABLE `sys_logs` DISABLE KEYS */;
INSERT INTO `sys_logs` VALUES (1,'INFO','Login exitoso. rol=MEDICO','192.168.1.71',3,'2026-09-03 02:39:44'),(2,'INFO','Solicitud Médica Digital LAESH-00001 creada para pepe lopez por médico user_id=3','192.168.1.71',3,'2026-09-03 02:41:02'),(3,'INFO','Sesión cerrada.','192.168.1.71',3,'2026-09-03 02:41:43'),(4,'INFO','Login exitoso. rol=RECEPCION','192.168.1.71',2,'2026-09-03 02:41:59'),(5,'INFO','Login exitoso. rol=MEDICO','192.168.1.71',3,'2026-09-03 03:31:29'),(6,'INFO','Solicitud Médica Digital LAESH-00002 creada para juan manuel por médico user_id=3','192.168.1.71',3,'2026-09-03 03:32:15'),(7,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:34:43'),(8,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:34:48'),(9,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:34:49'),(10,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:37:00'),(11,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:37:01'),(12,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:37:02'),(13,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:37:02'),(14,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:37:02'),(15,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:37:02'),(16,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:37:03'),(17,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:37:18'),(18,'WARN','Token CSRF inválido en creación de orden médica por user_id=3','192.168.1.71',NULL,'2026-09-03 03:40:34'),(19,'INFO','Sesión cerrada.','192.168.1.71',3,'2026-09-03 03:59:39'),(20,'INFO','Login exitoso. rol=MEDICO','192.168.1.71',3,'2026-09-03 03:59:54'),(21,'INFO','Solicitud Médica Digital LAESH-00003 creada para ame vazquez por médico user_id=3','192.168.1.71',3,'2026-09-03 04:00:37'),(22,'INFO','Login exitoso. rol=MEDICO','192.168.1.71',3,'2026-09-03 17:03:27'),(23,'INFO','Login exitoso. rol=RECEPCION','192.168.1.71',2,'2026-09-03 17:04:25');
/*!40000 ALTER TABLE `sys_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(249) NOT NULL,
  `password` varchar(255) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `username` varchar(100) DEFAULT NULL,
  `status` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `verified` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `resettable` tinyint(1) unsigned NOT NULL DEFAULT 1,
  `roles_mask` int(10) unsigned NOT NULL DEFAULT 0,
  `registered` int(10) unsigned NOT NULL,
  `last_login` int(10) unsigned DEFAULT NULL,
  `force_logout` mediumint(7) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Autenticación Delight-Auth — R15.5: email virtual {tel}@laesh.local';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'9990000001@laesh.local','$pa01$2y$10$sYD5UNKyYc6DJqLtZKI9xePp4N.AyDBAfPCZitu3IisaVLUEhcolK','9990000001',0,1,1,0,1788400417,NULL,0),(2,'9990000002@laesh.local','$pa01$2y$10$bzeZbogUCtHQsWRYje0hseP7qS3qfoCX1/1i0KAanB90NTkRTd1Ie','9990000002',0,1,1,0,1788400417,1788455065,0),(3,'9990000003@laesh.local','$pa01$2y$10$Xm5wUae6vMVOVZqQhRWMUOxZYW/HOIFq04x4J2ZB9aIkohbhPxpZ.','9990000003',0,1,1,0,1788400417,1788455007,0),(4,'9990000004@laesh.local','$pa01$2y$10$JEI4eFI6v8Fpt1uuYfUpi.zlJi8COT2.baoe9txwIn9t0HfXz5f2i','9990000004',0,1,1,0,1788400417,NULL,0),(5,'9990000005@laesh.local','$pa01$2y$10$GyKvy0WOsnI9nML4Y41rHOXEvlowps/8P8IOuBjO.PPmmW9H2YMdy','9990000005',0,1,1,0,1788400417,NULL,0),(6,'9990000006@laesh.local','$pa01$2y$10$KYoo6yUK5aa9CUejXepUeORMhhv3H18vyfVbjiYXK6lHdXlCBEifi','9990000006',0,1,1,0,1788400417,NULL,0),(7,'9990000007@laesh.local','$pa01$2y$10$/ZLoCkOtsAnewyDXqFelE.s5N2Xrfpz4mUsUVq3W.5rX/KJx.qSS2','9990000007',0,1,1,0,1788400418,NULL,0);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users_2fa`
--

DROP TABLE IF EXISTS `users_2fa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_2fa` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `mechanism` tinyint(4) unsigned NOT NULL,
  `seed` varbinary(255) NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  `expires_at` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id_mechanism` (`user_id`,`mechanism`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='2FA seeds Delight-Auth — mecanismo TOTP/SMS/Email según mechanism enum';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_2fa`
--

LOCK TABLES `users_2fa` WRITE;
/*!40000 ALTER TABLE `users_2fa` DISABLE KEYS */;
/*!40000 ALTER TABLE `users_2fa` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users_audit_log`
--

DROP TABLE IF EXISTS `users_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_audit_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `event_at` int(10) unsigned NOT NULL,
  `event_type` varchar(64) NOT NULL,
  `admin_id` int(10) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `details_json` mediumtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Auditoría Delight-Auth — event_at, event_type, admin_id, ip_address, user_agent';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_audit_log`
--

LOCK TABLES `users_audit_log` WRITE;
/*!40000 ALTER TABLE `users_audit_log` DISABLE KEYS */;
INSERT INTO `users_audit_log` VALUES (1,1,1788403184,'logout.local',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=',NULL),(2,3,1788403184,'login',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),(3,3,1788403303,'logout.local',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=',NULL),(4,2,1788403319,'login',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),(5,3,1788406289,'login',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),(6,3,1788407979,'logout.local',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=',NULL),(7,3,1788407993,'login',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),(8,2,1788455007,'logout.local',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=',NULL),(9,3,1788455007,'login',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),(10,2,1788455065,'login',NULL,'192.168.1.0/24','dISkPtmlzf5cC+oTS8f+lbx1c5NZ9U6C57A6NJ9mthk=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}');
/*!40000 ALTER TABLE `users_audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users_confirmations`
--

DROP TABLE IF EXISTS `users_confirmations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_confirmations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `email` varchar(249) NOT NULL,
  `selector` varchar(24) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `token` varchar(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `expires` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `selector` (`selector`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_confirmations`
--

LOCK TABLES `users_confirmations` WRITE;
/*!40000 ALTER TABLE `users_confirmations` DISABLE KEYS */;
/*!40000 ALTER TABLE `users_confirmations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users_remembered`
--

DROP TABLE IF EXISTS `users_remembered`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_remembered` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user` int(10) unsigned NOT NULL,
  `selector` varchar(24) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `token` varchar(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `expires` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `selector` (`selector`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_remembered`
--

LOCK TABLES `users_remembered` WRITE;
/*!40000 ALTER TABLE `users_remembered` DISABLE KEYS */;
INSERT INTO `users_remembered` VALUES (1,3,'RbnYZk2ExM5FSA8Ttd2gV_88','$2y$10$JvTcXsYFUVLrnmzzD.dxN.x1ayFHmF4ArtfRJ0eFhxdtS0sYE8ZA6',1788403184),(2,2,'JXjUNW8DFVOOvYf_oE2IITyM','$2y$10$lG5v5EYzYIp7Oaov7pLD9Ou/1COfYv4fa5L214.3X8N9ljcTu8Yqa',1788403319),(3,3,'H1_ByOkwQdny49vdF8WS23wy','$2y$10$yCRNq8Lijuvs7g26TUuR9ONZ57DPA1Ai7Nbz/HFO9.YDt6SV781jS',1788406289),(4,3,'gi06sgL3lYoPNrmeFZPXMSFB','$2y$10$sZGeErxnypn4o/2btDBwGO9GUKWXl9IC66wM3rRpOBXGgBHfqEEbi',1788407994),(5,3,'vV1AYmg_WSplmpGVcjlafDej','$2y$10$iXG1UlxG5sjJrhJXuU0PUOUmIomUCzDULTSummff.qatNihppPJx2',1788455007),(6,2,'CqD9I-xtjnz67ExAtojFr1Jc','$2y$10$tBSNYV0cP99EgCo4pyznxee2TZbYzflQHCwNtStbyxaDwqZiAZEZa',1788455065);
/*!40000 ALTER TABLE `users_remembered` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users_resets`
--

DROP TABLE IF EXISTS `users_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_resets` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user` int(10) unsigned NOT NULL,
  `selector` varchar(24) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `token` varchar(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `expires` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `selector` (`selector`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_resets`
--

LOCK TABLES `users_resets` WRITE;
/*!40000 ALTER TABLE `users_resets` DISABLE KEYS */;
/*!40000 ALTER TABLE `users_resets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users_throttling`
--

DROP TABLE IF EXISTS `users_throttling`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_throttling` (
  `bucket` varchar(255) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `tokens` float unsigned NOT NULL,
  `replenished_at` int(10) unsigned NOT NULL,
  `expires_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`bucket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_throttling`
--

LOCK TABLES `users_throttling` WRITE;
/*!40000 ALTER TABLE `users_throttling` DISABLE KEYS */;
INSERT INTO `users_throttling` VALUES ('nZAw0czp1WPwG8Cgfg9KqJV-ZocU1UET_f1ziljJh5w',73.0161,1788455065,1788995065);
/*!40000 ALTER TABLE `users_throttling` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_ordenes_completas`
--

DROP TABLE IF EXISTS `vw_ordenes_completas`;
/*!50001 DROP VIEW IF EXISTS `vw_ordenes_completas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_ordenes_completas` AS SELECT 
 1 AS `orden_id`,
 1 AS `folio_unico`,
 1 AS `hora_captura`,
 1 AS `fecha_resultado`,
 1 AS `diagnostico`,
 1 AS `estudios_json`,
 1 AS `edad_al_emitir`,
 1 AS `paciente_id`,
 1 AS `paciente_nombre`,
 1 AS `paciente_sexo`,
 1 AS `paciente_fecha_nac`,
 1 AS `paciente_telefono`,
 1 AS `estado_id`,
 1 AS `estado_valor`,
 1 AS `estado_color`,
 1 AS `medico_empleado_id`,
 1 AS `medico_nombre`,
 1 AS `medico_apellidos`,
 1 AS `medico_nombre_completo`,
 1 AS `medico_especialidad`,
 1 AS `medico_cedula`,
 1 AS `recepcion_nombre`,
 1 AS `recepcion_apellidos`,
 1 AS `actualizado_en`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_pacientes_historial`
--

DROP TABLE IF EXISTS `vw_pacientes_historial`;
/*!50001 DROP VIEW IF EXISTS `vw_pacientes_historial`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_pacientes_historial` AS SELECT 
 1 AS `paciente_id`,
 1 AS `nombre_completo`,
 1 AS `sexo`,
 1 AS `fecha_nacimiento`,
 1 AS `telefono`,
 1 AS `orden_id`,
 1 AS `folio_unico`,
 1 AS `hora_captura`,
 1 AS `fecha_resultado`,
 1 AS `diagnostico`,
 1 AS `edad_al_emitir`,
 1 AS `estado_valor`,
 1 AS `estado_color`,
 1 AS `medico_nombre_completo`,
 1 AS `medico_especialidad`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `web_contenidos`
--

DROP TABLE IF EXISTS `web_contenidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `web_contenidos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seccion` varchar(50) NOT NULL COMMENT 'hero|quienes-somos|especialidades|promociones|calidad|ubicacion|privacidad|footer|seo',
  `subseccion` varchar(100) DEFAULT NULL COMMENT 'slide1..5|ficha1..4|banner|lunes..domingo|logo|info|contacto|meta|og|schema',
  `clave` varchar(100) NOT NULL COMMENT 'titulo|descripcion|texto|imagen_url|etiqueta',
  `valor` mediumtext DEFAULT NULL,
  `tipo` enum('texto','imagen_url','html','json') NOT NULL DEFAULT 'texto',
  `actualizado_por` int(10) unsigned DEFAULT NULL COMMENT 'FK users.id',
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sec_subsec_clave` (`seccion`,`subseccion`,`clave`),
  KEY `idx_seccion` (`seccion`),
  KEY `idx_cms_sec_sub_clave` (`seccion`,`subseccion`,`clave`)
) ENGINE=InnoDB AUTO_INCREMENT=111 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contenido editable del sitio web LAESH por sección CMS';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `web_contenidos`
--

LOCK TABLES `web_contenidos` WRITE;
/*!40000 ALTER TABLE `web_contenidos` DISABLE KEYS */;
INSERT INTO `web_contenidos` VALUES (1,'aviso-privacidad','contenido','cuerpo_html','<p class=\"modal-p\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 1rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><strong style=\"box-sizing:border-box;margin:0px;padding:0px;\">LABORATORIO </strong><span style=\"color:#71CA11;\"><strong style=\"box-sizing:border-box;margin:0px;padding:0px;\">LAESH</strong></span>, con domicilio en Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.2, es responsable del tratamiento, uso, protección y resguardo de los datos personales que recaba de sus pacientes, usuarios y personas que solicitan nuestros servicios.</p><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">1. Datos personales que recabamos</h4><ul class=\"aviso-list\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.75rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Nombre completo.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Fecha de nacimiento y edad.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Sexo.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Datos de contacto, como teléfono, correo electrónico y domicilio.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Datos relacionados con la atención y solicitud de estudios de laboratorio.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Información necesaria para la identificación y entrega de resultados.</li></ul><p class=\"modal-p--main\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><strong>Datos personales sensibles</strong></p><p class=\"aviso-p aviso-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Por la naturaleza de nuestros servicios, podremos tratar datos personales sensibles relacionados con el estado de salud. Estos datos serán tratados con medidas de seguridad y confidencialidad.</p><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">2. Finalidades del tratamiento</h4><ol class=\"aviso-list\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.75rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Identificar y registrar al paciente.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Solicitar, procesar y entregar estudios de laboratorio.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Elaborar y conservar los resultados correspondientes.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Dar seguimiento a los servicios solicitados.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Atender dudas, aclaraciones o solicitudes relacionadas con sus resultados.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Cumplir con las obligaciones legales y sanitarias aplicables.</li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Mantener registros administrativos, contables y relacionados con la prestación del servicio.</li></ol><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">3. Protección y confidencialidad</h4><p class=\"aviso-p aviso-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Laboratorio LAESH implementa medidas administrativas, técnicas y físicas destinadas a proteger los datos personales contra daño, pérdida, alteración, destrucción, acceso o tratamiento no autorizado.</p><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">4. Derechos ARCO</h4><p class=\"aviso-p aviso-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Usted tiene derecho a Acceder, Rectificar, Cancelar u Oponerse al tratamiento de sus datos personales. Para ejercer estos derechos contáctenos por:</p><ul class=\"aviso-list aviso-list--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.75;margin:0px 0px 0.5rem;orphans:2;padding:0px 0px 0px 1.2rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Correo: <a class=\"txt-primary-c\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;\" href=\"mailto:11lab_laesh@hotmail.com\">11lab_laesh@hotmail.com</a></li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Teléfono: <strong style=\"box-sizing:border-box;margin:0px;padding:0px;\">953 688 769410</strong></li><li style=\"box-sizing:border-box;margin-bottom:0px;margin-right:0px;margin-top:0px;padding:0px;\">Domicilio: Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.2</li></ul><h4 class=\"aviso-h4\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:0.9rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:1.25rem 0px 0.35rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">5. Modificaciones</h4><p class=\"aviso-p aviso-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px 0px 0.5rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Laboratorio LAESH podrá modificar este Aviso cuando resulte necesario. Las modificaciones estarán disponibles en nuestro sitio web.</p><p class=\"modal-p--sm\" style=\"-webkit-text-stroke-width:0px;background-color:rgb(255, 255, 255);box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.8rem;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0px 0px 1rem;orphans:2;padding:0px;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><i>Última actualización: agosto de 2026</i></p><div class=\"highlight-block\" style=\"-webkit-text-stroke-width:0px;background-color:rgba(113, 202, 17, 0.06);border-left:3px solid rgb(113, 202, 17);border-radius:0px 6px 6px 0px;box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0.5rem 0px 0px;orphans:2;padding:0.85rem 1rem;text-align:start;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><p class=\"modal-p--pgd\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.88rem;margin:0px 0px 0.35rem;padding:0px;\"><strong>Consentimiento</strong></p><p class=\"modal-p--tail\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.7;margin:0px;padding:0px;\">Declaro que he leído y comprendido el presente Aviso de Privacidad y manifiesto mi consentimiento para el tratamiento de mis datos personales para las finalidades señaladas.</p></div>','html',NULL,'2026-09-03 01:53:37'),(2,'calidad','gallery1','descripcion','Análisis de biometría hemática y células sanguíneas con rigor científico y alta precisión.','texto',NULL,'2026-09-03 01:53:37'),(3,'calidad','gallery1','titulo','Área de Hematología','texto',NULL,'2026-09-03 01:53:37'),(4,'calidad','gallery2','descripcion','Determinación automatizada de metabolitos, perfil lipídico y enzimas específicas.','texto',NULL,'2026-09-03 01:53:37'),(5,'calidad','gallery2','titulo','Química Clínica','texto',NULL,'2026-09-03 01:53:37'),(6,'calidad','gallery3','descripcion','Aislamiento, tinción de Gram y pruebas de susceptibilidad a antimicrobianos.','texto',NULL,'2026-09-03 01:53:37'),(7,'calidad','gallery3','titulo','Microbiología y Cultivos','texto',NULL,'2026-09-03 01:53:37'),(8,'calidad','seccion','h2','Calidad e Instalaciones','texto',NULL,'2026-09-03 01:53:37'),(9,'calidad','seccion','subtitulo','Conoce nuestras instalaciones equipadas con tecnología de vanguardia y un equipo comprometido con la excelencia diagnóstica.','texto',NULL,'2026-09-03 01:53:37'),(10,'especialidades','carousel1','texto','<h3>Hematología Especializada</h3><p>Análisis morfológico de frotis sanguíneo y pruebas hematológicas de alta complejidad.</p>','html',NULL,'2026-09-03 01:53:37'),(11,'especialidades','carousel10','texto','<h3>Toma Pediátrica</h3><p>Espacio amigable y personal capacitado para el cuidado y tranquilidad de los niños.</p>','html',NULL,'2026-09-03 01:53:37'),(12,'especialidades','carousel11','texto','<h3>Toma de Cultivos</h3><p>Zonas aisladas y estériles para la toma de exudados y cultivos microbiológicos.</p>','html',NULL,'2026-09-03 01:53:37'),(13,'especialidades','carousel12','texto','<h3>Recepción Técnica</h3><p>Recepción técnica de muestras e indicaciones pre-analíticas detalladas.</p>','html',NULL,'2026-09-03 01:53:37'),(14,'especialidades','carousel13','texto','','html',NULL,'2026-09-03 01:53:37'),(15,'especialidades','carousel14','texto','','html',NULL,'2026-09-03 01:53:37'),(16,'especialidades','carousel15','texto','','html',NULL,'2026-09-03 01:53:37'),(17,'especialidades','carousel16','texto','','html',NULL,'2026-09-03 01:53:37'),(18,'especialidades','carousel2','texto','<h3>Química Clínica Avanzada</h3><p>Determinación automatizada de electrolitos, proteínas y enzimas específicas.</p>','html',NULL,'2026-09-03 01:53:37'),(19,'especialidades','carousel3','texto','<h3>Microbiología y Cultivos</h3><p>Identificación microscópica y pruebas de susceptibilidad a antimicrobianos.</p>','html',NULL,'2026-09-03 01:53:37'),(20,'especialidades','carousel4','texto','<h3>Uroanálisis y Sedimentos</h3><p>Examen de orina, química y microscopía para detección precoz de patologías renales.</p>','html',NULL,'2026-09-03 01:53:37'),(21,'especialidades','carousel5','texto','<h3>Hemostasia y Coagulación</h3><p>Estudios de tiempos de protrombina (TP) y tromboplastina parcial activada (TTPa).</p>','html',NULL,'2026-09-03 01:53:37'),(22,'especialidades','carousel6','texto','<h3>Pruebas Especiales</h3><p>Hormonas, anticuerpos específicos, pruebas inmunológicas y marcadores tumorales.</p>','html',NULL,'2026-09-03 01:53:37'),(23,'especialidades','carousel7','texto','<h3>Pre-analítica</h3><p>Separación de suero y plasma con control estricto de tiempos y temperaturas.</p>','html',NULL,'2026-09-03 01:53:37'),(24,'especialidades','carousel8','texto','<h3>Toma de Muestras I</h3><p>Áreas higiénicas equipadas para la extracción sanguínea convencional.</p>','html',NULL,'2026-09-03 01:53:37'),(25,'especialidades','carousel9','texto','<h3>Toma de Muestras II</h3><p>Módulos individuales y confortables que aseguran una atención rápida y sin molestias.</p>','html',NULL,'2026-09-03 01:53:37'),(26,'especialidades','catalogo','nota_pie','Listas de Estudios disponibles 2026 · Haz clic en cada grupo para expandir','texto',NULL,'2026-09-03 01:53:37'),(27,'especialidades','cg1','fichas','[Hematología] Citometría Hemática, Grupo y RH, Plaquetas, VSG, Reticulocitos, Perfil de Hierro,\n[Química Clínica] QS3, QS7, Perfil Bioquímico 15/24/30/35/45, Glucosa, Creatinina, Colesterol, Triglicéridos,\n[Electrolitos Séricos] ES 3/4/Completos, Calcio, Fósforo, Magnesio, Bicarbonato CO2,\n[Uroanálisis] EGO + Radio Prot/Crea, EGO Especializado, Antidoping 5/12 elem.,\n[Coagulación] Perfil de Coagulación, TP/INR, TTPa, Fibrinógeno, Dímero D, T. Sangrado,\n[Lípidos] Perfil de Lípidos I, II, Perfil Aterogénico','texto',NULL,'2026-09-03 01:53:37'),(28,'especialidades','cg1','titulo','Rutina General — Hematología, Química Clínica, Electrolitos, Uroanálisis, Coagulación','texto',NULL,'2026-09-03 01:53:37'),(29,'especialidades','cg2','fichas','[Función Hepática] PFH Básico, PFH Completo, Transaminasas, GGT, Proteínas Totales, Albumina,\n[Función Tiroidea] Perfil Tiroideo I-IV, TSH, Ac. Anti Tiroideos I-II, Ac. Anti Receptor TSH, Tiroglobulina,\n[Función Pancreática] Amilasa sérica, Lipasa sérica,\n[Función Renal] Cistatina C, Depuración creatinina, Proteínas orina, Microalbuminuria,\n[Función Cardiaca] Triage cardiaco, Perfil cardiaco completo, Troponina I, Troponina T, NT-pro BNP, Mioglobina,\n[Gasometría] Gasometría Arterial Completa, Gasometría Venosa Completa','texto',NULL,'2026-09-03 01:53:37'),(30,'especialidades','cg2','titulo','Función de Órganos — Hepática, Tiroidea, Pancreática, Renal, Cardiaca, Gasometría','texto',NULL,'2026-09-03 01:53:37'),(31,'especialidades','cg3','fichas','[Hormonas] Perfil Ginecológico I-II, Perfil Hormonal Masculino, FSH, LH, PRL, PROG, TESTOSTERONA Total/Libre, DHEA-S, Cortisol, AMH, PTH-i,\n[Diabetes] HbA1c, Insulina, HOMA-IR, Péptido C, Prueba de Tolerancia Glucosa, Test O\'Sullivan,\n[Inmunología] HIV 1/2, V.D.R.L., Reacciones Febriles, Hepatitis A-B-C, Dengue, COVID-19, Coombs, Procalcitonina,\n[Reumatología] Perfil Reumático, PCR, Factor Reumatoide, CCP, ANA, Anti DNA, Complementos C3/C4,\n[Diversos] Vitamina D, Inmunoglobulina E, Somatomedina C, Papanicolaou','texto',NULL,'2026-09-03 01:53:37'),(32,'especialidades','cg3','titulo','Hormonas, Diabetes e Inmunología — Perfil Ginecológico, Masculino, Diabetes, Inmunología, Reumatología','texto',NULL,'2026-09-03 01:53:37'),(33,'especialidades','cg4','fichas','[Bacteriología] Cultivo de orina MIC, Ex. Faríngeo MIC, Ex. Vaginal MIC, Uretral MIC, Heces MIC, Lesión MIC, Expectoración MIC, Hemocultivo MIC, Cultivo Micológico,\n[Marcadores Tumorales] PSA Total, PSA Libre, CEA, AFP, CA-125, CA-15-3, CA-19-9, Perfil Tumoral Femenino/Masculino,\n[Parasitología] Coproparasitoscópico 3 muestras, Coprológico completo/especial, Sangre Oculta, H. Pylori, Calprotectina, Lactoferrina, Clostridium difficile,\n[Citroquímicos] LCR, Sinovial, Pleural, Ascitis, Diálisis, Bronquial, Pericárdico,\n[Biología Molecular] PCR VPH, PCR Mycobacterium, PCR Patógenos respiratorios, PCR Meningitis viral, PCR SARS-CoV-2,\n[Fertilidad] Espermatobioscopia directa','texto',NULL,'2026-09-03 01:53:37'),(34,'especialidades','cg4','titulo','Bacteriología, Marcadores Tumorales, Parasitología, Citroquímicos, Biología Molecular, Fertilidad','texto',NULL,'2026-09-03 01:53:37'),(35,'especialidades','seccion','h2','Estudios de Rutina y Especialidades','texto',NULL,'2026-09-03 01:53:37'),(36,'especialidades','seccion','subtitulo','Servicios clínicos diseñados con rigor científico para garantizar la máxima confiabilidad en el diagnóstico médico.','texto',NULL,'2026-09-03 01:53:37'),(37,'footer','contenido','cuerpo_html','<div class=\"footer-info\">\n    <img src=\"/laesh-web-assets-uipv1a/img/logo-laesh.webp\" alt=\"LAESH Laboratorio de Especialidades Hematológicas\" class=\"footer-logo-img\" style=\"max-height: 40px; width: auto;\" decoding=\"async\" loading=\"lazy\">\n    <p class=\"footer-text\">\n        <strong>Laboratorio de Especialidades Hematológicas S.C.</strong> &nbsp;|&nbsp; Azucenas No. 8, Col. Jardines del Sur, Huajuapan de León, Oax. &nbsp;|&nbsp; Tel: <a href=\"tel:9535320268\">953 532 0268</a> &nbsp;|&nbsp; WhatsApp: <a href=\"https://wa.me/529531190074\" target=\"_blank\" rel=\"noopener noreferrer\">953 119 0074</a>\n    </p>\n    <p class=\"footer-text\">\n        Lunes a Sábado 7:00 a 20:00 hrs &nbsp;·&nbsp; Domingo 8:00 a 14:00 hrs &nbsp;|&nbsp; <a href=\"#\" id=\"link-privacy\">Aviso de Privacidad</a> &nbsp;|&nbsp; © 2026 LAESH. Todos los derechos reservados.\n    </p>\n</div>','html',NULL,'2026-09-03 01:53:37'),(38,'footer','estilo','bg_color','#0f172a','texto',NULL,'2026-09-03 01:53:37'),(39,'hero','config','transition_time','5','texto',NULL,'2026-09-03 01:53:37'),(40,'hero','navbar','tagline_l1','Diagnósticos deB','texto',NULL,'2026-09-03 01:53:37'),(41,'hero','navbar','tagline_l2','Confianza y Calidad','texto',NULL,'2026-09-03 01:53:37'),(42,'hero','slide1','cta_href','#especialidades','texto',NULL,'2026-09-03 01:53:37'),(43,'hero','slide1','cta_texto','Conoce los Servicios','texto',NULL,'2026-09-03 01:53:37'),(44,'hero','slide1','descripcion','Ofrecemos servicios integrales de análisis clínicos especializados con precisión científica y calidez humana.','texto',NULL,'2026-09-03 01:53:37'),(45,'hero','slide1','etiqueta','Un laboratorio seguro con Resultados ConfiablesB','texto',NULL,'2026-09-03 01:53:37'),(46,'hero','slide1','imagen_url','/laesh-web-assets-uipv1a/img/cms/hero-slide1-20260824-a689d2fa.webp','imagen_url',NULL,'2026-09-03 01:53:37'),(47,'hero','slide1','titulo','Laboratorio de Especialidades Hematológicas','texto',NULL,'2026-09-03 01:53:37'),(48,'hero','slide2','cta_href','#especialidades','texto',NULL,'2026-09-03 01:53:37'),(49,'hero','slide2','cta_texto','Ver Especialidades','texto',NULL,'2026-09-03 01:53:37'),(50,'hero','slide2','descripcion','Detrás de cada resultado hay una decisión. Por eso, en LAESH® la calidad no es una opción: es nuestro compromiso.','texto',NULL,'2026-09-03 01:53:37'),(51,'hero','slide2','etiqueta','25 Años de Experiencia Clínica','texto',NULL,'2026-09-03 01:53:37'),(52,'hero','slide2','imagen_url','/laesh-web-assets-uipv1a/img/recepcion.webp','imagen_url',NULL,'2026-09-03 01:53:37'),(53,'hero','slide2','titulo','Un laboratorio seguro con Resultados Confiables','texto',NULL,'2026-09-03 01:53:37'),(54,'hero','slide3','cta_href','#calidad','texto',NULL,'2026-09-03 01:53:37'),(55,'hero','slide3','cta_texto','Conocer Calidad','texto',NULL,'2026-09-03 01:53:37'),(56,'hero','slide3','descripcion','Detrás de cada análisis existe una decisión médica crucial. En LAESH® la precisión diagnóstica es nuestro compromiso inquebrantable.','texto',NULL,'2026-09-03 01:53:37'),(57,'hero','slide3','etiqueta','Excelencia y Calidad Certificada','texto',NULL,'2026-09-03 01:53:37'),(58,'hero','slide3','imagen_url','/laesh-web-assets-uipv1a/img/recepcion-de-pacientes.webp','imagen_url',NULL,'2026-09-03 01:53:37'),(59,'hero','slide3','titulo','Resultados Confiables para Cuidar tu Salud','texto',NULL,'2026-09-03 01:53:37'),(60,'hero','slide4','cta_href','#promociones','texto',NULL,'2026-09-03 01:53:37'),(61,'hero','slide4','cta_texto','Ver Promociones','texto',NULL,'2026-09-03 01:53:37'),(62,'hero','slide4','descripcion','Descubre nuestros paquetes preventivos y tarifas especiales diseñadas para el cuidado integral de tu salud y la de toda tu familia.','texto',NULL,'2026-09-03 01:53:37'),(63,'hero','slide4','etiqueta','Tarifas y Paquetes Preferenciales','texto',NULL,'2026-09-03 01:53:37'),(64,'hero','slide4','imagen_url','/laesh-web-assets-uipv1a/img/sala-de-espera.webp','imagen_url',NULL,'2026-09-03 01:53:37'),(65,'hero','slide4','titulo','Promociones y Check-Ups Médicos 2026','texto',NULL,'2026-09-03 01:53:37'),(66,'hero','slide5','cta_href','#ubicacion','texto',NULL,'2026-09-03 01:53:37'),(67,'hero','slide5','cta_texto','Ver Ubicación','texto',NULL,'2026-09-03 01:53:37'),(68,'hero','slide5','descripcion','Visítanos en Azucenas 8, Jardines del Sur, Huajuapan de León. Lunes a sábado 7:00 a.m. – 9:00 p.m.','texto',NULL,'2026-09-03 01:53:37'),(69,'hero','slide5','etiqueta','Atención Presencial y Horarios','texto',NULL,'2026-09-03 01:53:37'),(70,'hero','slide5','imagen_url','/laesh-web-assets-uipv1a/img/recepcion-de-pacientes.webp','imagen_url',NULL,'2026-09-03 01:53:37'),(71,'hero','slide5','titulo','Ubicación, Horarios de Atención y Contacto','texto',NULL,'2026-09-03 01:53:37'),(72,'promociones','banner','subtitulo','Aprovecha nuestras tarifas preferenciales y paquetes diseñados para ti.','texto',NULL,'2026-09-03 01:53:37'),(73,'promociones','banner','titulo','Promociones Vigentes','texto',NULL,'2026-09-03 01:53:37'),(74,'promociones','domingo','alt','Servicio dominical LAESH — Horario especial','texto',NULL,'2026-09-03 01:53:37'),(75,'promociones','domingo','estudio_clave','','texto',NULL,'2026-09-03 01:53:37'),(76,'promociones','domingo','imagen_url','','texto',NULL,'2026-09-03 01:53:37'),(77,'promociones','jueves','descripcion','Hematología · Marcador de inflamación aguda y crónica','texto',NULL,'2026-09-03 01:53:37'),(78,'promociones','jueves','estudio_clave','HEM-04','texto',NULL,'2026-09-03 01:53:37'),(79,'promociones','jueves','imagen_url','','texto',NULL,'2026-09-03 01:53:37'),(80,'promociones','lunes','descripcion','Hematología · Conteo globular y frotis de sangre periférica','texto',NULL,'2026-09-03 01:53:37'),(81,'promociones','lunes','estudio_clave','HEM-01','texto',NULL,'2026-09-03 01:53:37'),(82,'promociones','lunes','imagen_url','','texto',NULL,'2026-09-03 01:53:37'),(83,'promociones','martes','descripcion','Hematología · Determinación de grupo sanguíneo y factor RH','texto',NULL,'2026-09-03 01:53:37'),(84,'promociones','martes','estudio_clave','HEM-02','texto',NULL,'2026-09-03 01:53:37'),(85,'promociones','martes','imagen_url','','texto',NULL,'2026-09-03 01:53:37'),(86,'promociones','miercoles','descripcion','Hematología · Recuento de trombocitos sanguíneos','texto',NULL,'2026-09-03 01:53:37'),(87,'promociones','miercoles','estudio_clave','HEM-03','texto',NULL,'2026-09-03 01:53:37'),(88,'promociones','miercoles','imagen_url','','texto',NULL,'2026-09-03 01:53:37'),(89,'promociones','sabado','descripcion','Hematología · Hierro sérico, ferritina y capacidad de fijación','texto',NULL,'2026-09-03 01:53:37'),(90,'promociones','sabado','estudio_clave','HEM-06','texto',NULL,'2026-09-03 01:53:37'),(91,'promociones','sabado','imagen_url','','texto',NULL,'2026-09-03 01:53:37'),(92,'promociones','viernes','descripcion','Hematología · Evaluación de producción eritroide medular','texto',NULL,'2026-09-03 01:53:37'),(93,'promociones','viernes','estudio_clave','HEM-05','texto',NULL,'2026-09-03 01:53:37'),(94,'promociones','viernes','imagen_url','','texto',NULL,'2026-09-03 01:53:37'),(95,'quienes-somos','ficha1','texto','<h3 class=\"acerca-h3b\" style=\"-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);flex-shrink:0;font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.75rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">🔵 25 años de experiencia al servicio del diagnóstico</h3><div class=\"modal-scroll-body\" style=\"-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(15, 23, 42);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;margin:0px;max-height:320px;orphans:2;overflow-y:auto;padding:0px 8px 0px 0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><p class=\"faq-p--sm2\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;\">LAESH, Laboratorio de Especialidades Hematológicas, es una empresa 100% de la Región Mixteca, fundada en septiembre de 2022 en Huajuapan de León, Oaxaca, con el propósito de ofrecer servicios de laboratorio clínico confiables, especializados y de alta calidad para médicos y pacientes.</p><p class=\"faq-p--sm2\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;\">Nuestra experiencia está respaldada por <strong class=\"txt-green\" style=\"box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;\">25 años</strong> de trayectoria profesional, un equipo de químicos especialistas con estudios de posgrado y especialización en Hematología Diagnóstica por Laboratorio, así como por la actualización permanente de nuestras pruebas y perfiles de acuerdo con las guías de práctica clínica y recomendaciones actuales.</p><p class=\"faq-p--sm2\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;\">Contamos con un amplio catálogo de estudios, desde análisis de rutina hasta pruebas altamente especializadas, apoyados en equipos de nueva generación, procesos de calidad y personal capacitado para proporcionar resultados confiables y clínicamente relevantes.</p><p class=\"faq-p--sm2\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;\">Nuestro compromiso con la calidad se refleja en nuestra participación en programas de evaluación externa, donde hemos obtenido calificaciones de <strong class=\"txt-primary-c\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;\">EXCELENCIA</strong>, así como en el <strong class=\"txt-green\" style=\"box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;\">Galardón Rey PACAL</strong>, reconocimiento relacionado con nuestro desempeño dentro de los laboratorios evaluados.</p><hr><p class=\"txt-pgd-sm\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;\"><strong>Nuestro compromiso</strong></p><p class=\"faq-p--sm2\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.9rem;padding:0px;\">En LAESH trabajamos para que cada resultado sea una herramienta útil para el médico y una fuente de confianza para el paciente.</p><hr><p class=\"txt-pgd-sm\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;\"><strong>Nuestro responsable sanitario</strong></p><p class=\"faq-p--text\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px 0px 0.5rem;padding:0px;\"><strong class=\"txt-main\" style=\"box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;\">Q.F.B. y E.H.D.L. Jacob Santiago Blanco</strong><br>Químico Farmacéutico Biólogo egresado de la Universidad Autónoma de Sinaloa, con especialidad en Hematología Diagnóstica por Laboratorio por el Instituto de Hematopatología.</p><p class=\"faq-p--text2\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.84rem;line-height:1.6;margin:0px 0px 0.9rem;padding:0px;\">Cédula Profesional: <strong class=\"txt-main\" style=\"box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;\">3609293</strong> &nbsp;|&nbsp; Cédula de Especialidad: <strong class=\"txt-main\" style=\"box-sizing:border-box;color:rgb(15, 23, 42);margin:0px;padding:0px;\">8935780</strong><br>Con <strong class=\"txt-green\" style=\"box-sizing:border-box;color:rgb(113, 202, 17);margin:0px;padding:0px;\">25 años</strong> de experiencia profesional, su trayectoria representa uno de los principales pilares de la calidad y especialización de LAESH.</p><hr><p class=\"txt-pgd-sm\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.4rem;padding:0px;\"><strong>🧬 Nuestra filosofía</strong></p><p class=\"faq-p--primary\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);font-size:0.87rem;margin:0px 0px 0.5rem;padding:0px;\"><strong>Resultados que dan confianza, decisiones que cuidan.</strong></p><p class=\"faq-p--tail\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.87rem;line-height:1.7;margin:0px;padding:0px;\">En LAESH entendemos que detrás de cada muestra existe una persona y detrás de cada resultado existe una decisión clínica. Por ello, trabajamos para ofrecer información diagnóstica confiable, oportuna y clínicamente relevante, que ayude al médico a tomar mejores decisiones y al paciente a recibir una atención adecuada.</p></div>','html',NULL,'2026-09-03 01:53:37'),(96,'quienes-somos','ficha2','texto','<h3 class=\"txt-pgd-sub\" style=\"-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.6rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">🔵 MISIÓN 🔵</h3><p class=\"aviso-p aviso-p--muted\" style=\"-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Brindar resultados confiables y clínicamente relevantes que ayuden al médico a tomar mejores decisiones y al paciente a recibir una atención oportuna y segura.</p>','texto',NULL,'2026-09-03 01:53:37'),(97,'quienes-somos','ficha3','texto','<h3 class=\"txt-pgd-sub\" style=\"-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.6rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">🟢 VISIÓN 🟢</h3><p class=\"aviso-p aviso-p--muted\" style=\"-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(100, 116, 139);font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:0.88rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;letter-spacing:normal;line-height:1.7;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">Ser el laboratorio de referencia para médicos y pacientes, reconocido por la excelencia de nuestros resultados, la especialización de nuestro equipo y nuestro compromiso permanente con la calidad.</p>','texto',NULL,'2026-09-03 01:53:37'),(98,'quienes-somos','ficha4','texto','<h3 class=\"acerca-h3\" style=\"-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(0, 82, 183);font-family:&quot;Mosquito Std Black&quot;, &quot;Arial Black&quot;, Impact, sans-serif;font-size:1rem;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;letter-spacing:normal;margin:0px 0px 0.85rem;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\">🟢 ¿ POR QUÉ CONFIAR EN LAESH <sup style=\"box-sizing:border-box;margin:0px;padding:0px;\">® </sup>? 🟢</h3><div class=\"acerca-flex\" style=\"-webkit-text-stroke-width:0px;box-sizing:border-box;color:rgb(15, 23, 42);display:flex;flex-direction:column;font-family:&quot;Gill Sans&quot;, &quot;Gill Sans MT&quot;, Cabin, Calibri, &quot;Trebuchet MS&quot;, sans-serif;font-size:16.8px;font-style:normal;font-variant-caps:normal;font-variant-ligatures:normal;font-weight:400;gap:7px;letter-spacing:normal;margin:0px;orphans:2;padding:0px;text-align:left;text-decoration-color:initial;text-decoration-style:initial;text-decoration-thickness:initial;text-indent:0px;text-transform:none;white-space:normal;widows:2;word-spacing:0px;\"><p class=\"faq-p--muted\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;\"><strong class=\"txt-primary-c fw-bold\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;\">25 años</strong> de experiencia</p><p class=\"faq-p--muted\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;\"><strong class=\"txt-primary-bold\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;\">Químicos especialistas</strong> con estudios de posgrado</p><p class=\"faq-p--muted\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;\"><strong class=\"txt-primary-bold\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;\">Guías de práctica clínica</strong> — pruebas y perfiles actualizados</p><p class=\"faq-p--muted\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;\"><strong class=\"txt-primary-bold\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;\">Excelencia</strong> en programas de control de calidad externo</p><p class=\"faq-p--muted\" style=\"box-sizing:border-box;color:rgb(100, 116, 139);font-size:0.88rem;line-height:1.5;margin:0px;padding:0px;\"><strong class=\"txt-primary-c\" style=\"box-sizing:border-box;color:rgb(0, 82, 183);margin:0px;padding:0px;\">Galardón Rey PACAL</strong> — reconocimiento a nuestro desempeño</p></div>','texto',NULL,'2026-09-03 01:53:37'),(99,'quienes-somos','seccion','h2','Quiénes somos','texto',NULL,'2026-09-03 01:53:37'),(100,'quienes-somos','seccion','subtitulo','La calidad de un resultado también se mide por la confianza que genera 25 años transformando resultados en decisiones clínicas.','texto',NULL,'2026-09-03 01:53:37'),(101,'seo','meta','description','Análisis clínicos especializados: hematología, bioquímica, inmunología, bacteriología y biología molecular en Huajuapan de León, Oaxaca.','texto',NULL,'2026-09-03 01:53:37'),(102,'seo','meta','title','LAESH — Laboratorio de Especialidades Hematológicas en Huajuapan de León, Oaxaca','texto',NULL,'2026-09-03 01:53:37'),(103,'seo','og','og_description','Diagnósticos clínicos de alta precisión con resultados confiables. Visítanos en Huajuapan de León, Oaxaca.','texto',NULL,'2026-09-03 01:53:37'),(104,'seo','og','og_image','/laesh-web-assets-uipv1a/img/laesh-slider-futurista-c.webp','imagen_url',NULL,'2026-09-03 01:53:37'),(105,'seo','og','og_title','LAESH — Laboratorio de Especialidades Hematológicas','texto',NULL,'2026-09-03 01:53:37'),(106,'seo','schema','schema_name','Laboratorio de Especialidades Hematológicas LAESH','texto',NULL,'2026-09-03 01:53:37'),(107,'seo','schema','schema_type','MedicalLaboratory','texto',NULL,'2026-09-03 01:53:37'),(108,'ubicacion','info','maps_embed','https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3773.7375!2d-97.7779575!3d17.8028691!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x85c60141d7aa4483%3A0x730f884bc7308bee!2sLaboratorio%20de%20Especialidades%20Hematol%C3%B3gicas%20S.C.!5e0!3m2!1ses!2smx!4v1724000000000!5m2!1ses!2smx','',NULL,'2026-09-03 01:53:37'),(109,'ubicacion','seccion','h2','Ubicación y Contacto','texto',NULL,'2026-09-03 01:53:37'),(110,'ubicacion','seccion','subtitulo','Visítenos en nuestras instalaciones, será un placer atenderle.','texto',NULL,'2026-09-03 01:53:37');
/*!40000 ALTER TABLE `web_contenidos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `vw_ordenes_completas`
--

/*!50001 DROP VIEW IF EXISTS `vw_ordenes_completas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_ordenes_completas` AS select `o`.`id` AS `orden_id`,`o`.`folio_unico` AS `folio_unico`,`o`.`hora_captura` AS `hora_captura`,`o`.`fecha_resultado` AS `fecha_resultado`,`o`.`diagnostico` AS `diagnostico`,`o`.`estudios` AS `estudios_json`,`o`.`edad_al_emitir` AS `edad_al_emitir`,`p`.`id` AS `paciente_id`,`p`.`nombre_completo` AS `paciente_nombre`,`p`.`sexo` AS `paciente_sexo`,`p`.`fecha_nacimiento` AS `paciente_fecha_nac`,`p`.`telefono` AS `paciente_telefono`,`ce`.`id` AS `estado_id`,`ce`.`valor` AS `estado_valor`,`ce`.`color_hex` AS `estado_color`,`em`.`id` AS `medico_empleado_id`,`em`.`nombre` AS `medico_nombre`,`em`.`apellidos` AS `medico_apellidos`,concat(`em`.`nombre`,' ',`em`.`apellidos`) AS `medico_nombre_completo`,`pm`.`especialidad` AS `medico_especialidad`,`pm`.`cedula_profesional` AS `medico_cedula`,`er`.`nombre` AS `recepcion_nombre`,`er`.`apellidos` AS `recepcion_apellidos`,`o`.`actualizado_en` AS `actualizado_en` from (((((`ordenes` `o` join `pacientes` `p` on(`p`.`id` = `o`.`paciente_id`)) join `catalogo_estados` `ce` on(`ce`.`id` = `o`.`estado_id`)) join `empleados` `em` on(`em`.`user_id` = `o`.`medico_id`)) left join `perfiles_medicos` `pm` on(`pm`.`user_id` = `o`.`medico_id`)) left join `empleados` `er` on(`er`.`user_id` = `o`.`recepcion_id`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_pacientes_historial`
--

/*!50001 DROP VIEW IF EXISTS `vw_pacientes_historial`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_pacientes_historial` AS select `p`.`id` AS `paciente_id`,`p`.`nombre_completo` AS `nombre_completo`,`p`.`sexo` AS `sexo`,`p`.`fecha_nacimiento` AS `fecha_nacimiento`,`p`.`telefono` AS `telefono`,`o`.`id` AS `orden_id`,`o`.`folio_unico` AS `folio_unico`,`o`.`hora_captura` AS `hora_captura`,`o`.`fecha_resultado` AS `fecha_resultado`,`o`.`diagnostico` AS `diagnostico`,`o`.`edad_al_emitir` AS `edad_al_emitir`,`ce`.`valor` AS `estado_valor`,`ce`.`color_hex` AS `estado_color`,concat(`em`.`nombre`,' ',`em`.`apellidos`) AS `medico_nombre_completo`,`pm`.`especialidad` AS `medico_especialidad` from ((((`pacientes` `p` join `ordenes` `o` on(`o`.`paciente_id` = `p`.`id`)) join `catalogo_estados` `ce` on(`ce`.`id` = `o`.`estado_id`)) join `empleados` `em` on(`em`.`user_id` = `o`.`medico_id`)) left join `perfiles_medicos` `pm` on(`pm`.`user_id` = `o`.`medico_id`)) order by `p`.`nombre_completo`,`o`.`hora_captura` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-03 11:04:33
