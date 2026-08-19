/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.8.8-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: laesh_db
-- ------------------------------------------------------
-- Server version	11.8.8-MariaDB-ubu2404-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `cat_estados_medico`
--

DROP TABLE IF EXISTS `cat_estados_medico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
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

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `cat_estados_medico` WRITE;
/*!40000 ALTER TABLE `cat_estados_medico` DISABLE KEYS */;
INSERT INTO `cat_estados_medico` VALUES
(1,'Activo','El médico puede crear y consultar órdenes'),
(2,'Pausado','El médico no puede crear órdenes; su historial se conserva');
/*!40000 ALTER TABLE `cat_estados_medico` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `catalogo_estados`
--

DROP TABLE IF EXISTS `catalogo_estados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `catalogo_estados` (
  `id` tinyint(3) unsigned NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `color_hex` char(7) DEFAULT '#6B7280',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Estados de orden: 1=Pendiente 2=En proceso 3=Listo 4=Entregado 5=Cancelado';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogo_estados`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `catalogo_estados` WRITE;
/*!40000 ALTER TABLE `catalogo_estados` DISABLE KEYS */;
INSERT INTO `catalogo_estados` VALUES
(1,'Pendiente','Orden recibida, en espera de procesamiento','#F59E0B'),
(2,'En proceso','Muestras en análisis','#3B82F6'),
(3,'Listo','Resultados listos para entrega','#10B981'),
(4,'Entregado','PDF de resultados descargado por el médico','#6B7280'),
(5,'Cancelado','Orden cancelada','#EF4444');
/*!40000 ALTER TABLE `catalogo_estados` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `catalogos_ui`
--

DROP TABLE IF EXISTS `catalogos_ui`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `catalogos_ui` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tipo` varchar(50) NOT NULL,
  `valor` varchar(255) NOT NULL,
  `orden` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_tipo_activo` (`tipo`,`activo`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogos polimórficos para selects dinámicos de UI';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogos_ui`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `catalogos_ui` WRITE;
/*!40000 ALTER TABLE `catalogos_ui` DISABLE KEYS */;
INSERT INTO `catalogos_ui` VALUES
(1,'universidad','Universidad Nacional Autónoma de México (UNAM)',1,1),
(2,'universidad','Universidad Autónoma Benito Juárez de Oaxaca',2,1),
(3,'universidad','Universidad Autónoma Metropolitana (UAM)',3,1),
(4,'universidad','Instituto Politécnico Nacional (IPN)',4,1),
(5,'universidad','Universidad Autónoma de Guadalajara',5,1),
(6,'universidad','Universidad Autónoma de Puebla (BUAP)',6,1),
(7,'universidad','Universidad Veracruzana',7,1),
(8,'universidad','Universidad Autónoma del Estado de México',8,1),
(9,'universidad','Otra universidad',99,1),
(10,'lugar_trabajo','Consultorio particular',1,1),
(11,'lugar_trabajo','Hospital General de Huajuapan',2,1),
(12,'lugar_trabajo','IMSS — Delegación Oaxaca',3,1),
(13,'lugar_trabajo','ISSSTE — Unidad Huajuapan',4,1),
(14,'lugar_trabajo','Clínica privada',5,1),
(15,'lugar_trabajo','Hospital Regional de la Mixteca',6,1),
(16,'lugar_trabajo','Otro',99,1);
/*!40000 ALTER TABLE `catalogos_ui` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `configuraciones`
--

DROP TABLE IF EXISTS `configuraciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `configuraciones` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `clave` varchar(100) NOT NULL,
  `valor` text DEFAULT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_clave` (`clave`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Parámetros globales de la instancia LAESH (singleton por clave)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuraciones`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `configuraciones` WRITE;
/*!40000 ALTER TABLE `configuraciones` DISABLE KEYS */;
INSERT INTO `configuraciones` VALUES
(1,'nombre_laboratorio','Laboratorio de Especialidades Hematológicas','Nombre oficial','2026-08-18 03:50:30'),
(2,'nombre_corto','LAESH','Nombre corto / marca','2026-08-18 03:50:30'),
(3,'direccion','Azucenas #8, Fraccionamiento Jardines del Sur, Huajuapan de León, Oaxaca.','Dirección física','2026-08-18 03:50:30'),
(4,'telefono','953 688 7694','Teléfono directo','2026-08-18 03:50:30'),
(5,'email_contacto','lab_laesh@hotmail.com','Correo de contacto público','2026-08-18 03:50:30'),
(6,'horario','Lunes a sábado: 7:00 a.m. – 9:00 p.m. | Domingo: 7:00 a.m. – 3:00 p.m.','Horario de atención','2026-08-18 03:50:30'),
(7,'responsable_sanitario','Q.F.B. y E.H.D.L. Jacob Santiago Blanco. Céd. Prof. 3609293 | Céd. Esp. 8935780','Responsable sanitario','2026-08-18 03:50:30'),
(8,'whatsapp_url','https://wa.me/529531190074','Enlace WhatsApp (D-04)','2026-08-18 03:50:30'),
(9,'facebook_url','','URL Facebook','2026-08-18 03:50:30'),
(10,'maps_embed_url','https://maps.google.com/?q=Azucenas+8+Jardines+del+Sur+Huajuapan+de+Leon+Oaxaca','URL Google Maps','2026-08-18 03:50:30'),
(11,'tiempo_rotacion_dias','90','Días antes de solicitar cambio de contraseña','2026-08-18 03:50:30'),
(12,'anios_experiencia','25','Años de experiencia — usado en sitio web','2026-08-18 03:50:30');
/*!40000 ALTER TABLE `configuraciones` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `detalle_ordenes`
--

DROP TABLE IF EXISTS `detalle_ordenes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_ordenes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int(10) unsigned NOT NULL,
  `estudio_id` int(10) unsigned NOT NULL,
  `precio_snap` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_orden` (`orden_id`),
  KEY `fk_detalle_estudio` (`estudio_id`),
  CONSTRAINT `fk_detalle_estudio` FOREIGN KEY (`estudio_id`) REFERENCES `estudios` (`id`),
  CONSTRAINT `fk_detalle_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ordenes`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `detalle_ordenes` WRITE;
/*!40000 ALTER TABLE `detalle_ordenes` DISABLE KEYS */;
INSERT INTO `detalle_ordenes` VALUES
(1,1,1,NULL),
(2,1,7,NULL),
(3,2,1,NULL),
(4,2,3,NULL),
(5,2,6,NULL);
/*!40000 ALTER TABLE `detalle_ordenes` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `empleados`
--

DROP TABLE IF EXISTS `empleados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `empleados` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellidos` varchar(200) NOT NULL,
  `rol` enum('MEDICO','RECEPCION','ADMIN') NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_id` (`user_id`),
  KEY `idx_rol` (`rol`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Extensión de users para personal LAESH';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `empleados`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `empleados` WRITE;
/*!40000 ALTER TABLE `empleados` DISABLE KEYS */;
INSERT INTO `empleados` VALUES
(1,1,'Admin','LAESH','ADMIN',1,'2026-08-18 13:52:51'),
(2,2,'Recepcion','Demo','RECEPCION',1,'2026-08-18 13:52:51'),
(3,3,'Médico','Demo','MEDICO',1,'2026-08-18 13:52:51');
/*!40000 ALTER TABLE `empleados` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `estudios`
--

DROP TABLE IF EXISTS `estudios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `estudios` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(200) NOT NULL,
  `categoria` enum('Hematología','Bioquímica','Uroanálisis','Inmunología','Otros') NOT NULL,
  `tipo_web` enum('rutina','check_up') NOT NULL DEFAULT 'rutina',
  `precio` decimal(10,2) DEFAULT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT 1,
  `orden` smallint(5) unsigned NOT NULL DEFAULT 0,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nombre` (`nombre`),
  KEY `idx_categoria` (`categoria`),
  KEY `idx_tipo_web` (`tipo_web`)
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de estudios/análisis de laboratorio';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `estudios`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `estudios` WRITE;
/*!40000 ALTER TABLE `estudios` DISABLE KEYS */;
INSERT INTO `estudios` VALUES
(1,'Biometría Hemática Completa','Hematología','rutina',NULL,1,1,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(2,'Grupo Sanguíneo y factor Rh','Hematología','rutina',NULL,1,2,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(3,'Perfil de Hierro Completo','Hematología','rutina',NULL,1,3,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(4,'Perfil de Coagulación (TP/INR y TTP)','Hematología','rutina',NULL,1,4,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(5,'Fibrinógeno','Hematología','rutina',NULL,1,5,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(6,'Dímero D','Hematología','rutina',NULL,1,6,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(7,'EGO — Radio prU/CrU','Uroanálisis','rutina',NULL,1,10,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(8,'EGO Cribado Renal — Radio Alb/Crea','Uroanálisis','rutina',NULL,1,11,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(9,'Ac. Anti VIH','Inmunología','rutina',NULL,1,20,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(10,'V.D.R.L.','Inmunología','rutina',NULL,1,21,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(11,'Prueba de Embarazo','Inmunología','rutina',NULL,1,22,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(12,'Hepatitis A','Inmunología','rutina',NULL,1,23,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(13,'Hepatitis B','Inmunología','rutina',NULL,1,24,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(14,'Hepatitis C','Inmunología','rutina',NULL,1,25,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(15,'Perfil Ginecológico 1','Inmunología','check_up',NULL,1,30,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(16,'Perfil Ginecológico 2','Inmunología','check_up',NULL,1,31,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(17,'Perfil Hormonal Masculino','Inmunología','check_up',NULL,1,32,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(18,'Testosterona Libre','Inmunología','check_up',NULL,1,33,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(19,'Cortisol','Inmunología','check_up',NULL,1,34,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(20,'DHEA-S','Inmunología','check_up',NULL,1,35,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(21,'HGC Cuantitativa','Inmunología','check_up',NULL,1,36,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(22,'AMH (Hormona Anti Mülleriana)','Inmunología','check_up',NULL,1,37,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(23,'Procalcitonina','Inmunología','rutina',NULL,1,40,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(24,'Dengue (NS1, IgG, IgM)','Inmunología','rutina',NULL,1,41,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(25,'Panel Viral Respiratorio','Inmunología','rutina',NULL,1,42,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(26,'Perfil Reumático','Inmunología','check_up',NULL,1,50,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(27,'CCP (Anti Péptido Cíclico Citrulinado)','Inmunología','check_up',NULL,1,51,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(28,'Ac. Anti Nucleares por IFI','Inmunología','check_up',NULL,1,52,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(29,'Proteína C Reactiva','Inmunología','rutina',NULL,1,53,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(30,'Factor Reumatoide','Inmunología','rutina',NULL,1,54,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(31,'Hemoglobina Glicada (A1c) HPLC','Bioquímica','rutina',NULL,1,60,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(32,'Resistencia a la Insulina (HOMA-IR)','Bioquímica','check_up',NULL,1,61,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(33,'Química Sanguínea 7E','Bioquímica','rutina',NULL,1,70,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(34,'Química Sanguínea Parcial 3E','Bioquímica','rutina',NULL,1,71,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(35,'Perfil Bioquímico 15 Elementos','Bioquímica','check_up',NULL,1,72,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(36,'Electrolitos Séricos Na+, K+, Cl-, Ca++, P, Mg','Bioquímica','rutina',NULL,1,80,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(37,'Perfil Cardiaco Completo','Bioquímica','check_up',NULL,1,90,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(38,'Troponinas (I y T)','Bioquímica','check_up',NULL,1,91,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(39,'NT-pro BNP','Bioquímica','check_up',NULL,1,92,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(40,'Perfil Tiroideo 1 (TSH, T4 y T3)','Bioquímica','check_up',NULL,1,100,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(41,'Perfil Tiroideo Completo','Bioquímica','check_up',NULL,1,101,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(42,'TSH','Bioquímica','rutina',NULL,1,102,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(43,'T4 Libre','Bioquímica','rutina',NULL,1,103,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(44,'Ac. Anti Tiroideos 1','Bioquímica','check_up',NULL,1,104,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(45,'Ac. Anti Receptor de TSH (TRAb)','Bioquímica','check_up',NULL,1,105,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(46,'Tiroglobulina','Bioquímica','check_up',NULL,1,106,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(47,'Perfil de Lípidos I','Bioquímica','check_up',NULL,1,110,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(48,'PSA Total','Bioquímica','check_up',NULL,1,120,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(49,'CEA','Bioquímica','check_up',NULL,1,121,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(50,'AFP','Bioquímica','check_up',NULL,1,122,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(51,'CA-125','Bioquímica','check_up',NULL,1,123,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(52,'CA-15-3','Bioquímica','check_up',NULL,1,124,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(53,'CA-19-9','Bioquímica','check_up',NULL,1,125,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(54,'PFH Básico','Bioquímica','rutina',NULL,1,130,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(55,'PFH Completo','Bioquímica','check_up',NULL,1,131,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(56,'Coprológico','Otros','rutina',NULL,1,140,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(57,'Coprológico Especial','Otros','rutina',NULL,1,141,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(58,'Sangre Oculta en Heces','Otros','rutina',NULL,1,142,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(59,'Calprotectina en Heces','Otros','rutina',NULL,1,143,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(60,'Lactoferrina en Heces','Otros','rutina',NULL,1,144,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(61,'Antígeno de H. Pylori en Heces','Otros','rutina',NULL,1,145,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(62,'Gasometría Arterial','Otros','rutina',NULL,1,150,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(63,'Gasometría Venosa','Otros','rutina',NULL,1,151,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(64,'Cultivo de Orina con MIC','Otros','rutina',NULL,1,160,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(65,'Cultivo de Exudado Faríngeo','Otros','rutina',NULL,1,161,'2026-08-18 03:53:46','2026-08-18 03:53:46'),
(66,'Cultivo de Exudado Vaginal con MIC','Otros','rutina',NULL,1,162,'2026-08-18 03:53:46','2026-08-18 03:53:46');
/*!40000 ALTER TABLE `estudios` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `fallback_log`
--

DROP TABLE IF EXISTS `fallback_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fallback_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `nivel` enum('WARN','ERROR','FALLBACK','CRITICAL') NOT NULL DEFAULT 'ERROR',
  `origen` varchar(120) DEFAULT NULL,
  `funcion` varchar(80) DEFAULT NULL,
  `query_type` enum('SELECT','INSERT','UPDATE','DELETE','CALL','OTHER') DEFAULT 'OTHER',
  `query_hash` char(8) CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL,
  `query_text` text DEFAULT NULL,
  `error_msg` varchar(300) DEFAULT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_nivel` (`nivel`),
  KEY `idx_fecha` (`fecha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Log técnico SQL/PHP — columnas alineadas con DB.php::logFallback()';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fallback_log`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `fallback_log` WRITE;
/*!40000 ALTER TABLE `fallback_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `fallback_log` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `folios_control`
--

DROP TABLE IF EXISTS `folios_control`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `folios_control` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serie` varchar(10) NOT NULL DEFAULT 'LAESH',
  `ultimo_numero` int(10) unsigned NOT NULL DEFAULT 0,
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_serie` (`serie`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `folios_control`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `folios_control` WRITE;
/*!40000 ALTER TABLE `folios_control` DISABLE KEYS */;
INSERT INTO `folios_control` VALUES
(1,'LAESH',2,'2026-08-18 23:35:28');
/*!40000 ALTER TABLE `folios_control` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `historial_estados_orden`
--

DROP TABLE IF EXISTS `historial_estados_orden`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_estados_orden` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int(10) unsigned NOT NULL,
  `estado_desde` tinyint(3) unsigned DEFAULT NULL,
  `estado_hasta` tinyint(3) unsigned NOT NULL,
  `cambiado_por` int(10) unsigned DEFAULT NULL,
  `observacion` varchar(500) DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_orden` (`orden_id`),
  KEY `idx_hist_orden_creado` (`orden_id`,`creado_en`),
  CONSTRAINT `fk_hist_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Movimientos de estado por orden — auditoría de transiciones';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_estados_orden`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `historial_estados_orden` WRITE;
/*!40000 ALTER TABLE `historial_estados_orden` DISABLE KEYS */;
INSERT INTO `historial_estados_orden` VALUES
(1,1,NULL,1,2,'Orden creada','2026-08-18 23:35:28'),
(2,2,NULL,1,NULL,'Orden creada','2026-08-18 23:35:28');
/*!40000 ALTER TABLE `historial_estados_orden` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `notas_orden`
--

DROP TABLE IF EXISTS `notas_orden`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas_orden` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int(10) unsigned NOT NULL,
  `autor_id` int(10) unsigned NOT NULL,
  `nota` text NOT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_orden` (`orden_id`),
  CONSTRAINT `fk_nota_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notas_orden`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `notas_orden` WRITE;
/*!40000 ALTER TABLE `notas_orden` DISABLE KEYS */;
/*!40000 ALTER TABLE `notas_orden` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `notificaciones`
--

DROP TABLE IF EXISTS `notificaciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificaciones` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `destinatario_id` int(10) unsigned NOT NULL,
  `tipo` enum('nueva_orden','resultados_listos') NOT NULL,
  `folio_referencia` varchar(20) DEFAULT NULL,
  `mensaje` varchar(500) NOT NULL,
  `leido` tinyint(1) NOT NULL DEFAULT 0,
  `entregado_ws` tinyint(1) NOT NULL DEFAULT 0,
  `retry_count` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_destinatario` (`destinatario_id`),
  KEY `idx_fallback_poll` (`destinatario_id`,`entregado_ws`,`leido`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones sistema — SSOT QoS: Swoole WS + fallback AJAX poll';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notificaciones`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `notificaciones` WRITE;
/*!40000 ALTER TABLE `notificaciones` DISABLE KEYS */;
/*!40000 ALTER TABLE `notificaciones` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ordenes`
--

DROP TABLE IF EXISTS `ordenes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ordenes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `folio` varchar(20) NOT NULL,
  `paciente_id` int(10) unsigned NOT NULL,
  `medico_id` int(10) unsigned NOT NULL,
  `recepcion_id` int(10) unsigned DEFAULT NULL,
  `estado_id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `edad_al_emitir` tinyint(3) unsigned NOT NULL,
  `diagnostico` varchar(500) DEFAULT NULL,
  `otros_estudios` varchar(500) DEFAULT NULL,
  `estudios` text DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_folio` (`folio`),
  KEY `idx_paciente` (`paciente_id`),
  KEY `idx_medico` (`medico_id`),
  KEY `idx_estado` (`estado_id`),
  KEY `idx_creado` (`creado_en`),
  KEY `idx_ordenes_medico_fecha` (`medico_id`,`creado_en`),
  KEY `idx_ordenes_estado_fecha` (`estado_id`,`creado_en`),
  CONSTRAINT `fk_orden_estado` FOREIGN KEY (`estado_id`) REFERENCES `catalogo_estados` (`id`),
  CONSTRAINT `fk_orden_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Solicitudes de análisis — folio LAESH-NNNNN';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ordenes`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ordenes` WRITE;
/*!40000 ALTER TABLE `ordenes` DISABLE KEYS */;
INSERT INTO `ordenes` VALUES
(1,'LAESH-00001',1,1,2,1,34,'Revisión general de rutina','','[1,7]','2026-08-18 23:35:28','2026-08-18 23:35:28'),
(2,'LAESH-00002',2,3,NULL,1,42,'Evaluación hematológica','','[1,3,6]','2026-08-18 23:35:28','2026-08-18 23:35:28');
/*!40000 ALTER TABLE `ordenes` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `pacientes`
--

DROP TABLE IF EXISTS `pacientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pacientes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `apellido_paterno` varchar(100) NOT NULL,
  `apellido_materno` varchar(100) DEFAULT NULL,
  `fecha_nacimiento` date DEFAULT NULL,
  `sexo` enum('H','M','Otro') NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_apellido` (`apellido_paterno`,`apellido_materno`),
  KEY `idx_pacientes_nombre` (`apellido_paterno`,`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registro demográfico de pacientes';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pacientes`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `pacientes` WRITE;
/*!40000 ALTER TABLE `pacientes` DISABLE KEYS */;
INSERT INTO `pacientes` VALUES
(1,'María','González López','',NULL,'M','9531112233','2026-08-18 23:35:28'),
(2,'Carlos','Ramírez Mendoza','',NULL,'H','9534445566','2026-08-18 23:35:28');
/*!40000 ALTER TABLE `pacientes` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `perfiles_medicos`
--

DROP TABLE IF EXISTS `perfiles_medicos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `perfiles_medicos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `empleado_id` int(10) unsigned NOT NULL,
  `especialidad` varchar(150) DEFAULT NULL,
  `cedula_profesional` varchar(50) DEFAULT NULL,
  `universidad_id` int(10) unsigned DEFAULT NULL,
  `lugar_trabajo_id` int(10) unsigned DEFAULT NULL,
  `estado_id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `foto_url` varchar(255) DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_empleado` (`empleado_id`),
  KEY `idx_universidad` (`universidad_id`),
  KEY `idx_lugar_trabajo` (`lugar_trabajo_id`),
  KEY `idx_estado` (`estado_id`),
  CONSTRAINT `fk_pm_empleado` FOREIGN KEY (`empleado_id`) REFERENCES `empleados` (`id`),
  CONSTRAINT `fk_pm_estado` FOREIGN KEY (`estado_id`) REFERENCES `cat_estados_medico` (`id`),
  CONSTRAINT `fk_pm_lugar` FOREIGN KEY (`lugar_trabajo_id`) REFERENCES `catalogos_ui` (`id`),
  CONSTRAINT `fk_pm_universidad` FOREIGN KEY (`universidad_id`) REFERENCES `catalogos_ui` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `perfiles_medicos`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `perfiles_medicos` WRITE;
/*!40000 ALTER TABLE `perfiles_medicos` DISABLE KEYS */;
/*!40000 ALTER TABLE `perfiles_medicos` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `rbac_permisos`
--

DROP TABLE IF EXISTS `rbac_permisos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rbac_permisos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rbac_permisos`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `rbac_permisos` WRITE;
/*!40000 ALTER TABLE `rbac_permisos` DISABLE KEYS */;
INSERT INTO `rbac_permisos` VALUES
(1,'ver_ordenes_propias','Médico: consultar y crear sus propias órdenes'),
(2,'ver_solicitud_digital','Médico: ver PDF de solicitud digital'),
(3,'gestionar_ordenes','Recepción: procesar órdenes, cambiar estados, subir PDFs'),
(4,'gestionar_medicos','Recepción/Admin: alta, edición y pausa de médicos'),
(5,'gestionar_cms','Admin: editar contenidos del sitio web (CMS)'),
(6,'gestionar_estudios','Admin: alta y edición del catálogo de estudios'),
(7,'ver_reportes','Admin/Recepción: acceso a reportes de actividad');
/*!40000 ALTER TABLE `rbac_permisos` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `rbac_permisos_usuarios`
--

DROP TABLE IF EXISTS `rbac_permisos_usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rbac_permisos_usuarios` (
  `user_id` int(10) unsigned NOT NULL,
  `permiso_id` int(10) unsigned NOT NULL,
  `otorgado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`,`permiso_id`),
  KEY `fk_pu_permiso` (`permiso_id`),
  CONSTRAINT `fk_pu_permiso` FOREIGN KEY (`permiso_id`) REFERENCES `rbac_permisos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rbac_permisos_usuarios`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `rbac_permisos_usuarios` WRITE;
/*!40000 ALTER TABLE `rbac_permisos_usuarios` DISABLE KEYS */;
INSERT INTO `rbac_permisos_usuarios` VALUES
(1,4,'2026-08-18 13:52:51'),
(1,5,'2026-08-18 13:52:51'),
(1,6,'2026-08-18 13:52:51'),
(1,7,'2026-08-18 13:52:51'),
(2,3,'2026-08-18 13:52:51'),
(2,4,'2026-08-18 13:52:51'),
(2,7,'2026-08-18 13:52:51'),
(3,1,'2026-08-18 13:52:51'),
(3,2,'2026-08-18 13:52:51');
/*!40000 ALTER TABLE `rbac_permisos_usuarios` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `resultados_pdf`
--

DROP TABLE IF EXISTS `resultados_pdf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `resultados_pdf` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int(10) unsigned NOT NULL,
  `nombre_archivo` varchar(255) NOT NULL,
  `ruta_storage` varchar(500) NOT NULL,
  `subido_por` int(10) unsigned DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_orden` (`orden_id`),
  CONSTRAINT `fk_pdf_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resultados_pdf`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `resultados_pdf` WRITE;
/*!40000 ALTER TABLE `resultados_pdf` DISABLE KEYS */;
/*!40000 ALTER TABLE `resultados_pdf` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_logs`
--

DROP TABLE IF EXISTS `sys_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `level` enum('DEBUG','INFO','WARN','ERROR','FATAL','CRITICAL') NOT NULL DEFAULT 'INFO',
  `message` text NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_level` (`level`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_syslogs_level_created` (`level`,`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=159 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Log operativo PSR-3 — columnas alineadas con Logger.php';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_logs`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_logs` WRITE;
/*!40000 ALTER TABLE `sys_logs` DISABLE KEYS */;
INSERT INTO `sys_logs` VALUES
(1,'WARN','Token CSRF inválido en login. IP: 172.19.0.1','172.19.0.1',NULL,'2026-08-18 13:49:43'),
(2,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 13:49:43'),
(3,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 13:49:43'),
(4,'ERROR','Error inesperado en login.php: SQLSTATE[42S02]: Base table or view not found: 1146 Table \'laesh_db.users_throttling\' doesn\'t exist','172.19.0.1',NULL,'2026-08-18 13:49:52'),
(5,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 13:49:52'),
(6,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 13:49:52'),
(7,'ERROR','Error inesperado en login.php: SQLSTATE[42S22]: Column not found: 1054 Unknown column \'event_at\' in \'INSERT INTO\'','172.19.0.1',NULL,'2026-08-18 13:53:01'),
(8,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 13:53:01'),
(9,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 13:53:01'),
(10,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 13:55:14'),
(11,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 13:55:14'),
(12,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 13:55:14'),
(13,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 13:55:14'),
(14,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 13:55:14'),
(15,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 13:55:14'),
(16,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 13:55:24'),
(17,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 13:55:24'),
(18,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 13:55:24'),
(19,'INFO','Login exitoso. rol=MEDICO','192.168.0.120',3,'2026-08-18 14:10:02'),
(20,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 14:10:02'),
(21,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 14:10:02'),
(22,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 14:31:37'),
(23,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(24,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(25,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 14:31:37'),
(26,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(27,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(28,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 14:31:37'),
(29,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(30,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(31,'WARN','Login fallido — credenciales incorrectas. IP: 172.19.0.1','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(32,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(33,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 14:31:37'),
(34,'WARN','Login fallido — credenciales incorrectas. IP: 172.19.0.1','172.19.0.1',NULL,'2026-08-18 14:49:00'),
(35,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 14:49:00'),
(36,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 14:49:00'),
(37,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 14:49:00'),
(38,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 14:49:00'),
(39,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 14:49:00'),
(40,'WARN','Token CSRF inválido en login. IP: 192.168.0.120','192.168.0.120',NULL,'2026-08-18 16:55:09'),
(41,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 16:55:09'),
(42,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 16:55:09'),
(43,'INFO','Login exitoso. rol=ADMIN','192.168.0.120',1,'2026-08-18 16:55:20'),
(44,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 16:55:20'),
(45,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 16:55:20'),
(46,'INFO','Login exitoso. rol=ADMIN','192.168.0.120',1,'2026-08-18 16:57:32'),
(47,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 16:57:32'),
(48,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 16:57:32'),
(49,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 17:49:35'),
(50,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 17:49:35'),
(51,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 17:49:35'),
(52,'INFO','Sesión cerrada.','172.19.0.1',1,'2026-08-18 18:06:16'),
(53,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:06:16'),
(54,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:06:16'),
(55,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 18:06:35'),
(56,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:06:35'),
(57,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:06:35'),
(58,'INFO','Sesión cerrada.','172.19.0.1',2,'2026-08-18 18:18:49'),
(59,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:18:49'),
(60,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:18:49'),
(61,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 18:19:19'),
(62,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:19:19'),
(63,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:19:19'),
(64,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 18:25:45'),
(65,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:25:45'),
(66,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:25:45'),
(67,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 18:26:09'),
(68,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:26:09'),
(69,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:26:09'),
(70,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 18:26:30'),
(71,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:26:30'),
(72,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:26:30'),
(73,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 18:26:59'),
(74,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:26:59'),
(75,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:26:59'),
(76,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 18:27:24'),
(77,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:27:24'),
(78,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:27:24'),
(79,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 18:28:44'),
(80,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:28:44'),
(81,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:28:44'),
(82,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 18:29:16'),
(83,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:29:16'),
(84,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:29:16'),
(85,'INFO','Sesión cerrada.','172.19.0.1',1,'2026-08-18 18:29:28'),
(86,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:29:28'),
(87,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:29:28'),
(88,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 18:29:50'),
(89,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:29:50'),
(90,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:29:50'),
(91,'INFO','Sesión cerrada.','172.19.0.1',1,'2026-08-18 18:29:55'),
(92,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:29:55'),
(93,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:29:55'),
(94,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 18:33:57'),
(95,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:33:57'),
(96,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:33:57'),
(97,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 18:34:23'),
(98,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:34:23'),
(99,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:34:23'),
(100,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 18:35:20'),
(101,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:35:20'),
(102,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:35:20'),
(103,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 18:52:01'),
(104,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:52:01'),
(105,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:52:01'),
(106,'INFO','Login exitoso. rol=ADMIN','172.19.0.1',1,'2026-08-18 18:52:59'),
(107,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:52:59'),
(108,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:52:59'),
(109,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 18:53:46'),
(110,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:53:46'),
(111,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:53:46'),
(112,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 18:57:59'),
(113,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:57:59'),
(114,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:57:59'),
(115,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 18:58:26'),
(116,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 18:58:26'),
(117,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 18:58:26'),
(118,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 19:02:36'),
(119,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 19:02:36'),
(120,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 19:02:36'),
(121,'INFO','Login exitoso. rol=RECEPCION','172.19.0.1',2,'2026-08-18 19:04:22'),
(122,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 19:04:22'),
(123,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 19:04:22'),
(124,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 19:05:54'),
(125,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 19:05:54'),
(126,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 19:05:54'),
(127,'INFO','Login exitoso. rol=MEDICO','172.19.0.1',3,'2026-08-18 19:06:35'),
(128,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','172.19.0.1',NULL,'2026-08-18 19:06:35'),
(129,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','172.19.0.1',NULL,'2026-08-18 19:06:35'),
(130,'INFO','Login exitoso. rol=MEDICO','192.168.0.120',3,'2026-08-18 19:12:02'),
(131,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 19:12:02'),
(132,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 19:12:02'),
(133,'INFO','Login exitoso. rol=RECEPCION','192.168.0.120',2,'2026-08-18 19:12:39'),
(134,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 19:12:39'),
(135,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 19:12:39'),
(136,'INFO','Login exitoso. rol=ADMIN','192.168.0.120',1,'2026-08-18 19:13:08'),
(137,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 19:13:08'),
(138,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 19:13:08'),
(139,'INFO','Sesión cerrada.','192.168.0.120',1,'2026-08-18 19:13:19'),
(140,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 19:13:19'),
(141,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 19:13:19'),
(142,'INFO','Login exitoso. rol=MEDICO','192.168.0.120',3,'2026-08-18 19:13:37'),
(143,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 19:13:37'),
(144,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 19:13:37'),
(145,'INFO','Login exitoso. rol=ADMIN','192.168.0.120',1,'2026-08-18 19:13:56'),
(146,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 19:13:56'),
(147,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 19:13:56'),
(148,'INFO','Login exitoso. rol=RECEPCION','192.168.0.120',2,'2026-08-18 21:49:30'),
(149,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 21:49:30'),
(150,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 21:49:30'),
(151,'INFO','Login exitoso. rol=MEDICO','192.168.0.120',3,'2026-08-18 21:50:04'),
(152,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 21:50:04'),
(153,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 21:50:04'),
(154,'INFO','Login exitoso. rol=RECEPCION','192.168.0.120',2,'2026-08-18 21:52:53'),
(155,'ERROR','Error [2]: mkdir(): Permission denied en /var/www/html/laesh-swbldi/commons/Logger.php:53','192.168.0.120',NULL,'2026-08-18 21:52:53'),
(156,'ERROR','Error [2]: file_put_contents(/var/www/html/laesh-swbldi/commons/../logs/app.log): Failed to open stream: No such file or directory en /var/www/html/laesh-swbldi/commons/Logger.php:65','192.168.0.120',NULL,'2026-08-18 21:52:53'),
(157,'INFO','Orden de Recepción LAESH-00001 registrada correctamente para María González López','127.0.0.1',2,'2026-08-18 23:35:28'),
(158,'INFO','Solicitud Médica Digital LAESH-00002 creada para Carlos Ramírez Mendoza por médico user_id=3','127.0.0.1',3,'2026-08-18 23:35:28');
/*!40000 ALTER TABLE `sys_logs` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'9990000001@laesh.local','$2y$10$6S7GynRj2.HeehtBHTypxeA8EWfzs8jf3lDtpYzzjb67CysXR3.ue','9990000001',0,1,1,0,1787061171,1787080436,0),
(2,'9990000002@laesh.local','$2y$10$OgP6TbraKFX8u2cwGQOUH.v3D4c3pHagEv/JIdFXbX4PqArj3qBse','9990000002',0,1,1,0,1787061171,1787089973,0),
(3,'9990000003@laesh.local','$2y$10$V5wmoYOrTuanVG7u/Jh.ceNlyoJaoLd1WYzKyXpi4aUOYNHNTYWdy','9990000003',0,1,1,0,1787061171,1787089804,0);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users_2fa`
--

DROP TABLE IF EXISTS `users_2fa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_2fa` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `mechanism` tinyint(4) unsigned NOT NULL,
  `seed` varbinary(255) NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  `expires_at` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id_mechanism` (`user_id`,`mechanism`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_2fa`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users_2fa` WRITE;
/*!40000 ALTER TABLE `users_2fa` DISABLE KEYS */;
/*!40000 ALTER TABLE `users_2fa` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users_audit_log`
--

DROP TABLE IF EXISTS `users_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=74 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_audit_log`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users_audit_log` WRITE;
/*!40000 ALTER TABLE `users_audit_log` DISABLE KEYS */;
INSERT INTO `users_audit_log` VALUES
(1,1,1787061259,'login',NULL,NULL,NULL,'{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(2,1,1787061302,'login',NULL,NULL,NULL,'{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(3,2,1787061314,'login',NULL,'172.19.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(4,3,1787061314,'login',NULL,'172.19.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(5,1,1787061324,'login',NULL,'172.19.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(6,3,1787062202,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(7,1,1787063497,'login',NULL,'172.19.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(8,2,1787063497,'login',NULL,'172.19.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(9,3,1787063497,'login',NULL,'172.19.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(10,1,1787064540,'login',NULL,'172.19.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(11,1,1787072120,'login',NULL,'192.168.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(12,1,1787072252,'login',NULL,'192.168.0.0/24','tWeLtnsY7lcFdzaqCpGKpuBK7QxpFe2LstyVWCj3E8k=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(13,1,1787075375,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(14,1,1787076376,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(15,2,1787076395,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(16,2,1787077129,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(17,3,1787077158,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(18,3,1787077545,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(19,2,1787077545,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(20,2,1787077569,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(21,1,1787077569,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(22,1,1787077590,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(23,3,1787077590,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(24,3,1787077619,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(25,2,1787077619,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(26,2,1787077644,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(27,3,1787077644,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(28,3,1787077724,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(29,2,1787077724,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(30,2,1787077756,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(31,1,1787077756,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(32,1,1787077768,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(33,1,1787077790,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(34,1,1787077795,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(35,3,1787078037,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(36,3,1787078063,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(37,2,1787078063,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(38,2,1787078120,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(39,1,1787078120,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(40,1,1787079121,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(41,3,1787079121,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(42,3,1787079179,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(43,1,1787079179,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(44,1,1787079226,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(45,2,1787079226,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(46,2,1787079479,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(47,3,1787079479,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(48,3,1787079506,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(49,3,1787079506,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(50,3,1787079756,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(51,3,1787079756,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(52,3,1787079862,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(53,2,1787079862,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(54,2,1787079954,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(55,3,1787079954,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(56,3,1787079995,'logout.local',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(57,3,1787079995,'login',NULL,'172.19.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(58,3,1787080322,'logout.local',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(59,3,1787080322,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(60,3,1787080358,'logout.local',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(61,2,1787080358,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(62,2,1787080388,'logout.local',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(63,1,1787080388,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(64,1,1787080399,'logout.local',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(65,3,1787080417,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(66,3,1787080436,'logout.local',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(67,1,1787080436,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***1@l***h.l***l\",\"username\":null}'),
(68,1,1787089770,'logout.local',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(69,2,1787089770,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}'),
(70,2,1787089804,'logout.local',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(71,3,1787089804,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***3@l***h.l***l\",\"username\":null}'),
(72,3,1787089973,'logout.local',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=',NULL),
(73,2,1787089973,'login',NULL,'192.168.0.0/24','geE7xWKhbTWM676hiiB/ExwSrF0H0q2I7mA7JvXkcl8=','{\"email\":\"9***2@l***h.l***l\",\"username\":null}');
/*!40000 ALTER TABLE `users_audit_log` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users_confirmations`
--

DROP TABLE IF EXISTS `users_confirmations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
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

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users_confirmations` WRITE;
/*!40000 ALTER TABLE `users_confirmations` DISABLE KEYS */;
/*!40000 ALTER TABLE `users_confirmations` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users_remembered`
--

DROP TABLE IF EXISTS `users_remembered`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_remembered` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user` int(10) unsigned NOT NULL,
  `selector` varchar(24) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `token` varchar(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  `expires` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `selector` (`selector`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_remembered`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users_remembered` WRITE;
/*!40000 ALTER TABLE `users_remembered` DISABLE KEYS */;
INSERT INTO `users_remembered` VALUES
(27,2,'1xTOcSUfv8DWWRayjVAzNdmH','$2y$10$VP.cEhOZRBy4uT8vxVo07.zSHdzstfPCamzyvWezpBvzwfvRd4xBy',1787089770),
(28,3,'5B45fyWKUe2-sGJ6SoCl7Vwj','$2y$10$1qrxfYHR9IhzqGcMBJG6o.hIrvY.xATogLMH537NUwdnU3IHJXM/W',1787089804),
(29,2,'dwxDfwK3Ibr3xoQqvf5wT1tq','$2y$10$Ma/3ZOm0D3PkU/fQYsMdC.AY7zsJ3bf8U7oTveyM8hquZDa0IfNXq',1787089973);
/*!40000 ALTER TABLE `users_remembered` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users_resets`
--

DROP TABLE IF EXISTS `users_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
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

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users_resets` WRITE;
/*!40000 ALTER TABLE `users_resets` DISABLE KEYS */;
/*!40000 ALTER TABLE `users_resets` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users_throttling`
--

DROP TABLE IF EXISTS `users_throttling`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
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

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users_throttling` WRITE;
/*!40000 ALTER TABLE `users_throttling` DISABLE KEYS */;
INSERT INTO `users_throttling` VALUES
('LMROmz72EgDq8WNE6eBeDz6DDLLmCtJ0GLTbO_c9Unk',55.6805,1787079995,1787619995),
('rjgHCoYmAKeLtI6qXu_8NGsJf8X7dv3yH8rpUWUY6bM',69.6808,1787089973,1787629973);
/*!40000 ALTER TABLE `users_throttling` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `web_contenidos`
--

DROP TABLE IF EXISTS `web_contenidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `web_contenidos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seccion` varchar(50) NOT NULL,
  `subseccion` varchar(100) DEFAULT NULL,
  `clave` varchar(100) NOT NULL,
  `valor` mediumtext DEFAULT NULL,
  `tipo` enum('texto','imagen_url','html','json') NOT NULL DEFAULT 'texto',
  `actualizado_por` int(10) unsigned DEFAULT NULL,
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sec_subsec_clave` (`seccion`,`subseccion`,`clave`),
  KEY `idx_seccion` (`seccion`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contenido editable del sitio web LAESH por sección CMS';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `web_contenidos`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `web_contenidos` WRITE;
/*!40000 ALTER TABLE `web_contenidos` DISABLE KEYS */;
INSERT INTO `web_contenidos` VALUES
(1,'hero','slide1','etiqueta','Un laboratorio seguro con Resultados Confiables','texto',NULL,'2026-08-18 03:54:15'),
(2,'hero','slide1','titulo','Laboratorio de Especialidades Hematológicas','texto',NULL,'2026-08-18 03:54:15'),
(3,'hero','slide1','descripcion','Ofrecemos servicios integrales de análisis clínicos especializados con precisión científica y calidez humana.','texto',NULL,'2026-08-18 03:54:15'),
(4,'hero','slide2','titulo','Un laboratorio seguro con Resultados Confiables','texto',NULL,'2026-08-18 03:54:15'),
(5,'hero','slide2','descripcion','Detrás de cada resultado hay una decisión. Por eso, en LAESH® la calidad no es una opción: es nuestro compromiso.','texto',NULL,'2026-08-18 03:54:15'),
(6,'hero','slide3','etiqueta','Aprovecha nuestras ofertas','texto',NULL,'2026-08-18 03:54:15'),
(7,'hero','slide3','titulo','Promociones Vigentes','texto',NULL,'2026-08-18 03:54:15'),
(8,'hero','slide3','descripcion','Aprovecha nuestras tarifas preferenciales y paquetes de check-ups diseñados para el cuidado de tu salud y la de tu familia.','texto',NULL,'2026-08-18 03:54:15'),
(9,'hero','slide4','etiqueta','Horarios y Ubicación','texto',NULL,'2026-08-18 03:54:15'),
(10,'hero','slide4','titulo','Nuestra Ubicación y Horarios','texto',NULL,'2026-08-18 03:54:15'),
(11,'quienes-somos','ficha1','titulo','Historia y Quiénes Somos','texto',NULL,'2026-08-18 03:54:15'),
(12,'quienes-somos','ficha1','texto','Fundado con la misión de brindar diagnósticos hematológicos y clínicos de alta precisión en la región de la Mixteca, LAESH cuenta con tecnología automatizada y personal altamente calificado.','texto',NULL,'2026-08-18 03:54:15'),
(13,'quienes-somos','ficha2','titulo','Nuestra Misión','texto',NULL,'2026-08-18 03:54:15'),
(14,'quienes-somos','ficha2','texto','Proporcionar un servicio de análisis clínicos con resultados confiables y oportunos para auxiliar en el diagnóstico de enfermedades, sobre una base de ética profesional y alto compromiso con la calidad.','texto',NULL,'2026-08-18 03:54:15'),
(15,'quienes-somos','ficha3','titulo','Nuestra Visión','texto',NULL,'2026-08-18 03:54:15'),
(16,'quienes-somos','ficha3','texto','Ser un Laboratorio Líder que proporcione los servicios más especializados y de alta calidad a médicos y pacientes.','texto',NULL,'2026-08-18 03:54:15'),
(17,'quienes-somos','ficha4','titulo','Nuestros Valores','texto',NULL,'2026-08-18 03:54:15'),
(18,'quienes-somos','ficha4','texto','Rigurosidad científica, empatía y calidez en el trato, integridad ética en los diagnósticos, responsabilidad social y constante mejora de nuestros análisis.','texto',NULL,'2026-08-18 03:54:15'),
(19,'especialidades','catalogo','titulo','Catálogo Completo de Estudios de Rutina','texto',NULL,'2026-08-18 03:54:15'),
(20,'especialidades','catalogo','lista','Biometría Hemática Completa, Química Sanguínea (7 Elem.), Examen General de Orina, Grupo Sanguíneo y Factor RH, Química Sanguínea (3 Elem.), Glucosa Sérica, Perfil de Coagulación (TP, INR, TTPa), Hemoglobina Glicada (HbA1c), Prueba de Embarazo (HCG), Electrolitos Séricos (Na, K, Cl, Ca), Perfil de Lípidos, Proteína C Reactiva Cuant., Perfil Reumático, Factor Reumatoide, Ac. VIH 1 y 2, Perfil Hepático Básico','texto',NULL,'2026-08-18 03:54:15'),
(21,'promociones','banner','titulo','Promociones Vigentes','texto',NULL,'2026-08-18 03:54:15'),
(22,'promociones','banner','subtitulo','Aprovecha nuestras tarifas preferenciales y paquetes diseñados para ti.','texto',NULL,'2026-08-18 03:54:15'),
(23,'ubicacion','info','direccion','Azucenas 8, Jardines del Sur, 69007 Heroica Cdad. de Huajuapan de León, Oax., México','texto',NULL,'2026-08-18 03:54:15'),
(24,'ubicacion','info','telefono','953 6 88 76 94','texto',NULL,'2026-08-18 03:54:15'),
(25,'ubicacion','info','email','lab_laesh@hotmail.com','texto',NULL,'2026-08-18 03:54:15'),
(26,'ubicacion','info','horario','Lunes a sábado: 7:00 a.m. – 9:00 p.m. | Domingo: 7:00 a.m. – 3:00 p.m.','texto',NULL,'2026-08-18 03:54:15'),
(27,'ubicacion','info','responsable_sanitario','Q.F.B. y E.H.D.L. Jacob Santiago Blanco. Céd. Prof. 3609293 | Céd. Esp. 8935780','texto',NULL,'2026-08-18 03:54:15');
/*!40000 ALTER TABLE `web_contenidos` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-08-19 13:03:08
