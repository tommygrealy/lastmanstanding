CREATE DATABASE  IF NOT EXISTS `lastmanstanding` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `lastmanstanding`;
-- MySQL dump 10.13  Distrib 5.5.16, for Win32 (x86)
--
-- Host: localhost    Database: lastmanstanding
-- ------------------------------------------------------
-- Server version	5.5.36

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Temporary table structure for view `allfixturesandclubinfo`
--

DROP TABLE IF EXISTS `allfixturesandclubinfo`;
/*!50001 DROP VIEW IF EXISTS `allfixturesandclubinfo`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `allfixturesandclubinfo` (
  `KickOffTime` datetime,
  `HomeTeam` varchar(50),
  `AwayTeam` varchar(50),
  `ShortName` varchar(8),
  `ShortNameAway` varchar(8),
  `HomeCrestImg` varchar(255),
  `AwayCrestImg` varchar(255)
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `clubs`
--

DROP TABLE IF EXISTS `clubs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clubs` (
  `ClubId` int(11) NOT NULL AUTO_INCREMENT,
  `LongName` varchar(100) NOT NULL,
  `MedName` varchar(10) NOT NULL,
  `ShortName` varchar(8) NOT NULL,
  `CrestURLSmall` varchar(255) NOT NULL,
  `CresURLLarge` varchar(255) NOT NULL,
  PRIMARY KEY (`ClubId`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clubs`
--

LOCK TABLES `clubs` WRITE;
/*!40000 ALTER TABLE `clubs` DISABLE KEYS */;
INSERT INTO `clubs` VALUES (1,'Arsenal','Arsenal','ARS','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/a/arsenal/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/a/arsenal/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(2,'Aston Villa','A. Villa','AVL','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/a/aston-villa/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/a/aston-villa/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(3,'Burnley','Burnley','BUR','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/b/burnley/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/b/burnley/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(4,'Chelsea','Chelsea','CHE','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/c/chelsea/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/c/chelsea/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(5,'Crystal Palace','C. Palace','CRY','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/c/crystal-palace/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/c/crystal-palace/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(6,'Everton','Everton','EVE','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/e/everton/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/e/everton/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(7,'Hull City','Hull','HUL','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/h/hull/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/h/hull/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(8,'Leicester City','Leicester','LEI','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/l/leicester/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/l/leicester/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(9,'Liverpool','Liverpool','LIV','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/l/liverpool/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/l/liverpool/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(10,'Manchester City','Man City','MCI','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/m/man-city/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/m/man-city/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(11,'Manchester United','Man Utd','MUN','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/m/man-utd/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/m/man-utd/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(12,'Newcastle United','Newcastle','NEW','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/n/newcastle/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/n/newcastle/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(13,'Queens Park Rangers','QPR','QPR','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/q/qpr/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/q/qpr/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(14,'Southampton','Sthampton','SOU','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/southampton/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/southampton/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(15,'Stoke City','Stoke','STK','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/stoke/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/stoke/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(16,'Sunderland','Sunderland','SUN','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/sunderland/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/sunderland/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(17,'Swansea City','Swansea','SWA','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/swansea/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/swansea/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(18,'Tottenham Hotspur','Spurs','TOT','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/spurs/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/spurs/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(19,'West Bromwich Albion','West Brom','WBA','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/w/west-brom/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/w/west-brom/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),(20,'West Ham United','West Ham','WHU','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/w/west-ham/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png','http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/w/west-ham/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png');
/*!40000 ALTER TABLE `clubs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fixtureresults`
--

DROP TABLE IF EXISTS `fixtureresults`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fixtureresults` (
  `FixtureId` int(11) NOT NULL AUTO_INCREMENT,
  `KickOffTime` datetime NOT NULL,
  `HomeTeam` varchar(50) NOT NULL,
  `AwayTeam` varchar(50) NOT NULL,
  `HomeTeamScore` int(11) DEFAULT NULL,
  `AwayTeamScore` int(11) DEFAULT NULL,
  `Result` smallint(6) DEFAULT NULL COMMENT '1=Home Win2=Draw3=Away Win',
  UNIQUE KEY `FixtureId` (`FixtureId`)
) ENGINE=InnoDB AUTO_INCREMENT=405 DEFAULT CHARSET=latin1 COMMENT='Result (1=home win, 2=Draw, 3=away win)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fixtureresults`
--

LOCK TABLES `fixtureresults` WRITE;
/*!40000 ALTER TABLE `fixtureresults` DISABLE KEYS */;
INSERT INTO `fixtureresults` VALUES (75,'2014-09-27 17:30:00','Arsenal','Tottenham Hotspur',1,1,2),(76,'2014-09-27 15:00:00','Chelsea','Aston Villa',3,0,1),(77,'2014-09-27 15:00:00','Crystal Palace','Leicester City',2,0,1),(78,'2014-09-27 15:00:00','Hull City','Manchester City',2,4,3),(79,'2014-09-27 12:45:00','Liverpool','Everton',1,1,2),(80,'2014-09-27 15:00:00','Manchester United','West Ham United',2,1,1),(81,'2014-09-27 15:00:00','Southampton','Queens Park Rangers',2,1,1),(82,'2014-09-29 20:00:00','Stoke City','Newcastle United',1,0,1),(83,'2014-09-27 15:00:00','Sunderland','Swansea City',0,0,2),(84,'2014-09-28 16:00:00','West Bromwich Albion','Burnley',4,0,1),(85,'2014-10-04 17:30:00','Aston Villa','Manchester City',NULL,NULL,NULL),(86,'2014-10-05 14:05:00','Chelsea','Arsenal',NULL,NULL,NULL),(87,'2014-10-04 15:00:00','Hull City','Crystal Palace',NULL,NULL,NULL),(88,'2014-10-04 15:00:00','Leicester City','Burnley',NULL,NULL,NULL),(89,'2014-10-04 15:00:00','Liverpool','West Bromwich Albion',NULL,NULL,NULL),(90,'2014-10-05 12:00:00','Manchester United','Everton',NULL,NULL,NULL),(91,'2014-10-04 15:00:00','Sunderland','Stoke City',NULL,NULL,NULL),(92,'2014-10-04 15:00:00','Swansea City','Newcastle United',NULL,NULL,NULL),(93,'2014-10-05 14:05:00','Tottenham Hotspur','Southampton',NULL,NULL,NULL),(94,'2014-10-05 16:15:00','West Ham United','Queens Park Rangers',NULL,NULL,NULL),(95,'2014-10-18 15:00:00','Arsenal','Hull City',NULL,NULL,NULL),(96,'2014-10-18 15:00:00','Burnley','West Ham United',NULL,NULL,NULL),(97,'2014-10-18 15:00:00','Crystal Palace','Chelsea',NULL,NULL,NULL),(98,'2014-10-18 15:00:00','Everton','Aston Villa',NULL,NULL,NULL),(99,'2014-10-18 15:00:00','Manchester City','Tottenham Hotspur',NULL,NULL,NULL),(100,'2014-10-18 15:00:00','Newcastle United','Leicester City',NULL,NULL,NULL),(101,'2014-10-18 15:00:00','Queens Park Rangers','Liverpool',NULL,NULL,NULL),(102,'2014-10-18 15:00:00','Southampton','Sunderland',NULL,NULL,NULL),(103,'2014-10-18 15:00:00','Stoke City','Swansea City',NULL,NULL,NULL),(104,'2014-10-18 15:00:00','West Bromwich Albion','Manchester United',NULL,NULL,NULL),(105,'2014-10-25 15:00:00','Burnley','Everton',NULL,NULL,NULL),(106,'2014-10-25 15:00:00','Liverpool','Hull City',NULL,NULL,NULL),(107,'2014-10-25 15:00:00','Manchester United','Chelsea',NULL,NULL,NULL),(108,'2014-10-25 15:00:00','Queens Park Rangers','Aston Villa',NULL,NULL,NULL),(109,'2014-10-25 15:00:00','Southampton','Stoke City',NULL,NULL,NULL),(110,'2014-10-25 15:00:00','Sunderland','Arsenal',NULL,NULL,NULL),(111,'2014-10-25 15:00:00','Swansea City','Leicester City',NULL,NULL,NULL),(112,'2014-10-25 15:00:00','Tottenham Hotspur','Newcastle United',NULL,NULL,NULL),(113,'2014-10-25 15:00:00','West Bromwich Albion','Crystal Palace',NULL,NULL,NULL),(114,'2014-10-25 15:00:00','West Ham United','Manchester City',NULL,NULL,NULL),(115,'2014-11-01 15:00:00','Arsenal','Burnley',NULL,NULL,NULL),(116,'2014-11-01 15:00:00','Aston Villa','Tottenham Hotspur',NULL,NULL,NULL),(117,'2014-11-01 15:00:00','Chelsea','Queens Park Rangers',NULL,NULL,NULL),(118,'2014-11-01 15:00:00','Crystal Palace','Sunderland',NULL,NULL,NULL),(119,'2014-11-01 15:00:00','Everton','Swansea City',NULL,NULL,NULL),(120,'2014-11-01 15:00:00','Hull City','Southampton',NULL,NULL,NULL),(121,'2014-11-01 15:00:00','Leicester City','West Bromwich Albion',NULL,NULL,NULL),(122,'2014-11-01 15:00:00','Manchester City','Manchester United',NULL,NULL,NULL),(123,'2014-11-01 15:00:00','Newcastle United','Liverpool',NULL,NULL,NULL),(124,'2014-11-01 15:00:00','Stoke City','West Ham United',NULL,NULL,NULL),(125,'2014-11-08 15:00:00','Burnley','Hull City',NULL,NULL,NULL),(126,'2014-11-08 15:00:00','Liverpool','Chelsea',NULL,NULL,NULL),(127,'2014-11-08 15:00:00','Manchester United','Crystal Palace',NULL,NULL,NULL),(128,'2014-11-08 15:00:00','Queens Park Rangers','Manchester City',NULL,NULL,NULL),(129,'2014-11-08 15:00:00','Southampton','Leicester City',NULL,NULL,NULL),(130,'2014-11-08 15:00:00','Sunderland','Everton',NULL,NULL,NULL),(131,'2014-11-08 15:00:00','Swansea City','Arsenal',NULL,NULL,NULL),(132,'2014-11-08 15:00:00','Tottenham Hotspur','Stoke City',NULL,NULL,NULL),(133,'2014-11-08 15:00:00','West Bromwich Albion','Newcastle United',NULL,NULL,NULL),(134,'2014-11-08 15:00:00','West Ham United','Aston Villa',NULL,NULL,NULL),(135,'2014-11-22 15:00:00','Arsenal','Manchester United',NULL,NULL,NULL),(136,'2014-11-22 15:00:00','Aston Villa','Southampton',NULL,NULL,NULL),(137,'2014-11-22 15:00:00','Chelsea','West Bromwich Albion',NULL,NULL,NULL),(138,'2014-11-22 15:00:00','Crystal Palace','Liverpool',NULL,NULL,NULL),(139,'2014-11-22 15:00:00','Everton','West Ham United',NULL,NULL,NULL),(140,'2014-11-22 15:00:00','Hull City','Tottenham Hotspur',NULL,NULL,NULL),(141,'2014-11-22 15:00:00','Leicester City','Sunderland',NULL,NULL,NULL),(142,'2014-11-22 15:00:00','Manchester City','Swansea City',NULL,NULL,NULL),(143,'2014-11-22 15:00:00','Newcastle United','Queens Park Rangers',NULL,NULL,NULL),(144,'2014-11-22 15:00:00','Stoke City','Burnley',NULL,NULL,NULL),(145,'2014-11-29 15:00:00','Burnley','Aston Villa',NULL,NULL,NULL),(146,'2014-11-29 15:00:00','Liverpool','Stoke City',NULL,NULL,NULL),(147,'2014-11-29 15:00:00','Manchester United','Hull City',NULL,NULL,NULL),(148,'2014-11-29 15:00:00','Queens Park Rangers','Leicester City',NULL,NULL,NULL),(149,'2014-11-29 15:00:00','Southampton','Manchester City',NULL,NULL,NULL),(150,'2014-11-29 15:00:00','Sunderland','Chelsea',NULL,NULL,NULL),(151,'2014-11-29 15:00:00','Swansea City','Crystal Palace',NULL,NULL,NULL),(152,'2014-11-29 15:00:00','Tottenham Hotspur','Everton',NULL,NULL,NULL),(153,'2014-11-29 15:00:00','West Bromwich Albion','Arsenal',NULL,NULL,NULL),(154,'2014-11-29 15:00:00','West Ham United','Newcastle United',NULL,NULL,NULL),(155,'2014-12-02 19:45:00','Arsenal','Southampton',NULL,NULL,NULL),(156,'2014-12-02 19:45:00','Burnley','Newcastle United',NULL,NULL,NULL),(157,'2014-12-02 20:00:00','Crystal Palace','Aston Villa',NULL,NULL,NULL),(158,'2014-12-02 19:45:00','Leicester City','Liverpool',NULL,NULL,NULL),(159,'2014-12-02 19:45:00','Manchester United','Stoke City',NULL,NULL,NULL),(160,'2014-12-02 19:45:00','Swansea City','Queens Park Rangers',NULL,NULL,NULL),(161,'2014-12-02 20:00:00','West Bromwich Albion','West Ham United',NULL,NULL,NULL),(162,'2014-12-03 19:45:00','Chelsea','Tottenham Hotspur',NULL,NULL,NULL),(163,'2014-12-03 19:45:00','Everton','Hull City',NULL,NULL,NULL),(164,'2014-12-03 19:45:00','Sunderland','Manchester City',NULL,NULL,NULL),(165,'2014-12-06 15:00:00','Aston Villa','Leicester City',NULL,NULL,NULL),(166,'2014-12-06 15:00:00','Hull City','West Bromwich Albion',NULL,NULL,NULL),(167,'2014-12-06 15:00:00','Liverpool','Sunderland',NULL,NULL,NULL),(168,'2014-12-06 15:00:00','Manchester City','Everton',NULL,NULL,NULL),(169,'2014-12-06 15:00:00','Newcastle United','Chelsea',NULL,NULL,NULL),(170,'2014-12-06 15:00:00','Queens Park Rangers','Burnley',NULL,NULL,NULL),(171,'2014-12-06 15:00:00','Southampton','Manchester United',NULL,NULL,NULL),(172,'2014-12-06 15:00:00','Stoke City','Arsenal',NULL,NULL,NULL),(173,'2014-12-06 15:00:00','Tottenham Hotspur','Crystal Palace',NULL,NULL,NULL),(174,'2014-12-06 15:00:00','West Ham United','Swansea City',NULL,NULL,NULL),(175,'2014-12-13 15:00:00','Arsenal','Newcastle United',NULL,NULL,NULL),(176,'2014-12-13 15:00:00','Burnley','Southampton',NULL,NULL,NULL),(177,'2014-12-13 15:00:00','Chelsea','Hull City',NULL,NULL,NULL),(178,'2014-12-13 15:00:00','Crystal Palace','Stoke City',NULL,NULL,NULL),(179,'2014-12-14 16:00:00','Everton','Queens Park Rangers',NULL,NULL,NULL),(180,'2014-12-13 15:00:00','Leicester City','Manchester City',NULL,NULL,NULL),(181,'2014-12-13 15:00:00','Manchester United','Liverpool',NULL,NULL,NULL),(182,'2014-12-13 15:00:00','Sunderland','West Ham United',NULL,NULL,NULL),(183,'2014-12-13 15:00:00','Swansea City','Tottenham Hotspur',NULL,NULL,NULL),(184,'2014-12-13 15:00:00','West Bromwich Albion','Aston Villa',NULL,NULL,NULL),(185,'2014-12-20 15:00:00','Aston Villa','Manchester United',NULL,NULL,NULL),(186,'2014-12-20 15:00:00','Hull City','Swansea City',NULL,NULL,NULL),(187,'2014-12-20 15:00:00','Liverpool','Arsenal',NULL,NULL,NULL),(188,'2014-12-20 15:00:00','Manchester City','Crystal Palace',NULL,NULL,NULL),(189,'2014-12-20 15:00:00','Newcastle United','Sunderland',NULL,NULL,NULL),(190,'2014-12-20 15:00:00','Queens Park Rangers','West Bromwich Albion',NULL,NULL,NULL),(191,'2014-12-20 15:00:00','Southampton','Everton',NULL,NULL,NULL),(192,'2014-12-20 15:00:00','Stoke City','Chelsea',NULL,NULL,NULL),(193,'2014-12-20 15:00:00','Tottenham Hotspur','Burnley',NULL,NULL,NULL),(194,'2014-12-20 15:00:00','West Ham United','Leicester City',NULL,NULL,NULL),(195,'2014-12-26 15:00:00','Arsenal','Queens Park Rangers',NULL,NULL,NULL),(196,'2014-12-26 15:00:00','Burnley','Liverpool',NULL,NULL,NULL),(197,'2014-12-26 15:00:00','Chelsea','West Ham United',NULL,NULL,NULL),(198,'2014-12-26 15:00:00','Crystal Palace','Southampton',NULL,NULL,NULL),(199,'2014-12-26 15:00:00','Everton','Stoke City',NULL,NULL,NULL),(200,'2014-12-26 15:00:00','Leicester City','Tottenham Hotspur',NULL,NULL,NULL),(201,'2014-12-26 15:00:00','Manchester United','Newcastle United',NULL,NULL,NULL),(202,'2014-12-26 15:00:00','Sunderland','Hull City',NULL,NULL,NULL),(203,'2014-12-26 15:00:00','Swansea City','Aston Villa',NULL,NULL,NULL),(204,'2014-12-26 15:00:00','West Bromwich Albion','Manchester City',NULL,NULL,NULL),(205,'2014-12-28 15:00:00','Aston Villa','Sunderland',NULL,NULL,NULL),(206,'2014-12-28 15:00:00','Hull City','Leicester City',NULL,NULL,NULL),(207,'2014-12-28 15:00:00','Liverpool','Swansea City',NULL,NULL,NULL),(208,'2014-12-28 15:00:00','Manchester City','Burnley',NULL,NULL,NULL),(209,'2014-12-28 15:00:00','Newcastle United','Everton',NULL,NULL,NULL),(210,'2014-12-28 15:00:00','Queens Park Rangers','Crystal Palace',NULL,NULL,NULL),(211,'2014-12-28 15:00:00','Southampton','Chelsea',NULL,NULL,NULL),(212,'2014-12-28 15:00:00','Stoke City','West Bromwich Albion',NULL,NULL,NULL),(213,'2014-12-28 15:00:00','Tottenham Hotspur','Manchester United',NULL,NULL,NULL),(214,'2014-12-28 15:00:00','West Ham United','Arsenal',NULL,NULL,NULL),(215,'2015-01-01 15:00:00','Aston Villa','Crystal Palace',NULL,NULL,NULL),(216,'2015-01-01 15:00:00','Hull City','Everton',NULL,NULL,NULL),(217,'2015-01-01 15:00:00','Liverpool','Leicester City',NULL,NULL,NULL),(218,'2015-01-01 15:00:00','Manchester City','Sunderland',NULL,NULL,NULL),(219,'2015-01-01 15:00:00','Newcastle United','Burnley',NULL,NULL,NULL),(220,'2015-01-01 15:00:00','Queens Park Rangers','Swansea City',NULL,NULL,NULL),(221,'2015-01-01 15:00:00','Southampton','Arsenal',NULL,NULL,NULL),(222,'2015-01-01 15:00:00','Stoke City','Manchester United',NULL,NULL,NULL),(223,'2015-01-01 15:00:00','Tottenham Hotspur','Chelsea',NULL,NULL,NULL),(224,'2015-01-01 15:00:00','West Ham United','West Bromwich Albion',NULL,NULL,NULL),(225,'2015-01-10 15:00:00','Arsenal','Stoke City',NULL,NULL,NULL),(226,'2015-01-10 15:00:00','Burnley','Queens Park Rangers',NULL,NULL,NULL),(227,'2015-01-10 15:00:00','Chelsea','Newcastle United',NULL,NULL,NULL),(228,'2015-01-10 15:00:00','Crystal Palace','Tottenham Hotspur',NULL,NULL,NULL),(229,'2015-01-10 15:00:00','Everton','Manchester City',NULL,NULL,NULL),(230,'2015-01-10 15:00:00','Leicester City','Aston Villa',NULL,NULL,NULL),(231,'2015-01-10 15:00:00','Manchester United','Southampton',NULL,NULL,NULL),(232,'2015-01-10 15:00:00','Sunderland','Liverpool',NULL,NULL,NULL),(233,'2015-01-10 15:00:00','Swansea City','West Ham United',NULL,NULL,NULL),(234,'2015-01-10 15:00:00','West Bromwich Albion','Hull City',NULL,NULL,NULL),(235,'2015-01-17 15:00:00','Aston Villa','Liverpool',NULL,NULL,NULL),(236,'2015-01-17 15:00:00','Burnley','Crystal Palace',NULL,NULL,NULL),(237,'2015-01-17 15:00:00','Everton','West Bromwich Albion',NULL,NULL,NULL),(238,'2015-01-17 15:00:00','Leicester City','Stoke City',NULL,NULL,NULL),(239,'2015-01-17 15:00:00','Manchester City','Arsenal',NULL,NULL,NULL),(240,'2015-01-17 15:00:00','Newcastle United','Southampton',NULL,NULL,NULL),(241,'2015-01-17 15:00:00','Queens Park Rangers','Manchester United',NULL,NULL,NULL),(242,'2015-01-17 15:00:00','Swansea City','Chelsea',NULL,NULL,NULL),(243,'2015-01-17 15:00:00','Tottenham Hotspur','Sunderland',NULL,NULL,NULL),(244,'2015-01-17 15:00:00','West Ham United','Hull City',NULL,NULL,NULL),(245,'2015-01-31 15:00:00','Arsenal','Aston Villa',NULL,NULL,NULL),(246,'2015-01-31 15:00:00','Chelsea','Manchester City',NULL,NULL,NULL),(247,'2015-01-31 15:00:00','Crystal Palace','Everton',NULL,NULL,NULL),(248,'2015-01-31 15:00:00','Hull City','Newcastle United',NULL,NULL,NULL),(249,'2015-01-31 15:00:00','Liverpool','West Ham United',NULL,NULL,NULL),(250,'2015-01-31 15:00:00','Manchester United','Leicester City',NULL,NULL,NULL),(251,'2015-01-31 15:00:00','Southampton','Swansea City',NULL,NULL,NULL),(252,'2015-01-31 15:00:00','Stoke City','Queens Park Rangers',NULL,NULL,NULL),(253,'2015-01-31 15:00:00','Sunderland','Burnley',NULL,NULL,NULL),(254,'2015-01-31 15:00:00','West Bromwich Albion','Tottenham Hotspur',NULL,NULL,NULL),(255,'2015-02-07 15:00:00','Aston Villa','Chelsea',NULL,NULL,NULL),(256,'2015-02-07 15:00:00','Burnley','West Bromwich Albion',NULL,NULL,NULL),(257,'2015-02-07 15:00:00','Everton','Liverpool',NULL,NULL,NULL),(258,'2015-02-07 15:00:00','Leicester City','Crystal Palace',NULL,NULL,NULL),(259,'2015-02-07 15:00:00','Manchester City','Hull City',NULL,NULL,NULL),(260,'2015-02-07 15:00:00','Newcastle United','Stoke City',NULL,NULL,NULL),(261,'2015-02-07 15:00:00','Queens Park Rangers','Southampton',NULL,NULL,NULL),(262,'2015-02-07 15:00:00','Swansea City','Sunderland',NULL,NULL,NULL),(263,'2015-02-07 15:00:00','Tottenham Hotspur','Arsenal',NULL,NULL,NULL),(264,'2015-02-07 15:00:00','West Ham United','Manchester United',NULL,NULL,NULL),(265,'2015-02-10 19:45:00','Arsenal','Leicester City',NULL,NULL,NULL),(266,'2015-02-10 20:00:00','Crystal Palace','Newcastle United',NULL,NULL,NULL),(267,'2015-02-10 19:45:00','Hull City','Aston Villa',NULL,NULL,NULL),(268,'2015-02-10 20:00:00','Liverpool','Tottenham Hotspur',NULL,NULL,NULL),(269,'2015-02-10 19:45:00','Manchester United','Burnley',NULL,NULL,NULL),(270,'2015-02-10 19:45:00','Southampton','West Ham United',NULL,NULL,NULL),(271,'2015-02-10 20:00:00','West Bromwich Albion','Swansea City',NULL,NULL,NULL),(272,'2015-02-11 19:45:00','Chelsea','Everton',NULL,NULL,NULL),(273,'2015-02-11 19:45:00','Stoke City','Manchester City',NULL,NULL,NULL),(274,'2015-02-11 19:45:00','Sunderland','Queens Park Rangers',NULL,NULL,NULL),(275,'2015-02-21 15:00:00','Aston Villa','Stoke City',NULL,NULL,NULL),(276,'2015-02-21 15:00:00','Chelsea','Burnley',NULL,NULL,NULL),(277,'2015-02-21 15:00:00','Crystal Palace','Arsenal',NULL,NULL,NULL),(278,'2015-02-21 15:00:00','Everton','Leicester City',NULL,NULL,NULL),(279,'2015-02-21 15:00:00','Hull City','Queens Park Rangers',NULL,NULL,NULL),(280,'2015-02-21 15:00:00','Manchester City','Newcastle United',NULL,NULL,NULL),(281,'2015-02-21 15:00:00','Southampton','Liverpool',NULL,NULL,NULL),(282,'2015-02-21 15:00:00','Sunderland','West Bromwich Albion',NULL,NULL,NULL),(283,'2015-02-21 15:00:00','Swansea City','Manchester United',NULL,NULL,NULL),(284,'2015-02-21 15:00:00','Tottenham Hotspur','West Ham United',NULL,NULL,NULL),(285,'2015-02-28 15:00:00','Arsenal','Everton',NULL,NULL,NULL),(286,'2015-02-28 15:00:00','Burnley','Swansea City',NULL,NULL,NULL),(287,'2015-02-28 15:00:00','Leicester City','Chelsea',NULL,NULL,NULL),(288,'2015-02-28 15:00:00','Liverpool','Manchester City',NULL,NULL,NULL),(289,'2015-02-28 15:00:00','Manchester United','Sunderland',NULL,NULL,NULL),(290,'2015-02-28 15:00:00','Newcastle United','Aston Villa',NULL,NULL,NULL),(291,'2015-02-28 15:00:00','Queens Park Rangers','Tottenham Hotspur',NULL,NULL,NULL),(292,'2015-02-28 15:00:00','Stoke City','Hull City',NULL,NULL,NULL),(293,'2015-02-28 15:00:00','West Bromwich Albion','Southampton',NULL,NULL,NULL),(294,'2015-02-28 15:00:00','West Ham United','Crystal Palace',NULL,NULL,NULL),(295,'2015-03-03 19:45:00','Aston Villa','West Bromwich Albion',NULL,NULL,NULL),(296,'2015-03-03 19:45:00','Hull City','Sunderland',NULL,NULL,NULL),(297,'2015-03-03 20:00:00','Liverpool','Burnley',NULL,NULL,NULL),(298,'2015-03-03 19:45:00','Queens Park Rangers','Arsenal',NULL,NULL,NULL),(299,'2015-03-03 19:45:00','Southampton','Crystal Palace',NULL,NULL,NULL),(300,'2015-03-03 19:45:00','West Ham United','Chelsea',NULL,NULL,NULL),(301,'2015-03-04 19:45:00','Manchester City','Leicester City',NULL,NULL,NULL),(302,'2015-03-04 19:45:00','Newcastle United','Manchester United',NULL,NULL,NULL),(303,'2015-03-04 19:45:00','Stoke City','Everton',NULL,NULL,NULL),(304,'2015-03-04 19:45:00','Tottenham Hotspur','Swansea City',NULL,NULL,NULL),(305,'2015-03-14 15:00:00','Arsenal','West Ham United',NULL,NULL,NULL),(306,'2015-03-14 15:00:00','Burnley','Manchester City',NULL,NULL,NULL),(307,'2015-03-14 15:00:00','Chelsea','Southampton',NULL,NULL,NULL),(308,'2015-03-14 15:00:00','Crystal Palace','Queens Park Rangers',NULL,NULL,NULL),(309,'2015-03-14 15:00:00','Everton','Newcastle United',NULL,NULL,NULL),(310,'2015-03-14 15:00:00','Leicester City','Hull City',NULL,NULL,NULL),(311,'2015-03-14 15:00:00','Manchester United','Tottenham Hotspur',NULL,NULL,NULL),(312,'2015-03-14 15:00:00','Sunderland','Aston Villa',NULL,NULL,NULL),(313,'2015-03-14 15:00:00','Swansea City','Liverpool',NULL,NULL,NULL),(314,'2015-03-14 15:00:00','West Bromwich Albion','Stoke City',NULL,NULL,NULL),(315,'2015-03-21 15:00:00','Aston Villa','Swansea City',NULL,NULL,NULL),(316,'2015-03-21 15:00:00','Hull City','Chelsea',NULL,NULL,NULL),(317,'2015-03-21 15:00:00','Liverpool','Manchester United',NULL,NULL,NULL),(318,'2015-03-21 15:00:00','Manchester City','West Bromwich Albion',NULL,NULL,NULL),(319,'2015-03-21 15:00:00','Newcastle United','Arsenal',NULL,NULL,NULL),(320,'2015-03-21 15:00:00','Queens Park Rangers','Everton',NULL,NULL,NULL),(321,'2015-03-21 15:00:00','Southampton','Burnley',NULL,NULL,NULL),(322,'2015-03-21 15:00:00','Stoke City','Crystal Palace',NULL,NULL,NULL),(323,'2015-03-21 15:00:00','Tottenham Hotspur','Leicester City',NULL,NULL,NULL),(324,'2015-03-21 15:00:00','West Ham United','Sunderland',NULL,NULL,NULL),(325,'2015-04-04 15:00:00','Arsenal','Liverpool',NULL,NULL,NULL),(326,'2015-04-04 15:00:00','Burnley','Tottenham Hotspur',NULL,NULL,NULL),(327,'2015-04-04 15:00:00','Chelsea','Stoke City',NULL,NULL,NULL),(328,'2015-04-04 15:00:00','Crystal Palace','Manchester City',NULL,NULL,NULL),(329,'2015-04-04 15:00:00','Everton','Southampton',NULL,NULL,NULL),(330,'2015-04-04 15:00:00','Leicester City','West Ham United',NULL,NULL,NULL),(331,'2015-04-04 15:00:00','Manchester United','Aston Villa',NULL,NULL,NULL),(332,'2015-04-04 15:00:00','Sunderland','Newcastle United',NULL,NULL,NULL),(333,'2015-04-04 15:00:00','Swansea City','Hull City',NULL,NULL,NULL),(334,'2015-04-04 15:00:00','West Bromwich Albion','Queens Park Rangers',NULL,NULL,NULL),(335,'2015-04-11 15:00:00','Burnley','Arsenal',NULL,NULL,NULL),(336,'2015-04-11 15:00:00','Liverpool','Newcastle United',NULL,NULL,NULL),(337,'2015-04-11 15:00:00','Manchester United','Manchester City',NULL,NULL,NULL),(338,'2015-04-11 15:00:00','Queens Park Rangers','Chelsea',NULL,NULL,NULL),(339,'2015-04-11 15:00:00','Southampton','Hull City',NULL,NULL,NULL),(340,'2015-04-11 15:00:00','Sunderland','Crystal Palace',NULL,NULL,NULL),(341,'2015-04-11 15:00:00','Swansea City','Everton',NULL,NULL,NULL),(342,'2015-04-11 15:00:00','Tottenham Hotspur','Aston Villa',NULL,NULL,NULL),(343,'2015-04-11 15:00:00','West Bromwich Albion','Leicester City',NULL,NULL,NULL),(344,'2015-04-11 15:00:00','West Ham United','Stoke City',NULL,NULL,NULL),(345,'2015-04-18 15:00:00','Arsenal','Sunderland',NULL,NULL,NULL),(346,'2015-04-18 15:00:00','Aston Villa','Queens Park Rangers',NULL,NULL,NULL),(347,'2015-04-18 15:00:00','Chelsea','Manchester United',NULL,NULL,NULL),(348,'2015-04-18 15:00:00','Crystal Palace','West Bromwich Albion',NULL,NULL,NULL),(349,'2015-04-18 15:00:00','Everton','Burnley',NULL,NULL,NULL),(350,'2015-04-18 15:00:00','Hull City','Liverpool',NULL,NULL,NULL),(351,'2015-04-18 15:00:00','Leicester City','Swansea City',NULL,NULL,NULL),(352,'2015-04-18 15:00:00','Manchester City','West Ham United',NULL,NULL,NULL),(353,'2015-04-18 15:00:00','Newcastle United','Tottenham Hotspur',NULL,NULL,NULL),(354,'2015-04-18 15:00:00','Stoke City','Southampton',NULL,NULL,NULL),(355,'2015-04-25 15:00:00','Arsenal','Chelsea',NULL,NULL,NULL),(356,'2015-04-25 15:00:00','Burnley','Leicester City',NULL,NULL,NULL),(357,'2015-04-25 15:00:00','Crystal Palace','Hull City',NULL,NULL,NULL),(358,'2015-04-25 15:00:00','Everton','Manchester United',NULL,NULL,NULL),(359,'2015-04-25 15:00:00','Manchester City','Aston Villa',NULL,NULL,NULL),(360,'2015-04-25 15:00:00','Newcastle United','Swansea City',NULL,NULL,NULL),(361,'2015-04-25 15:00:00','Queens Park Rangers','West Ham United',NULL,NULL,NULL),(362,'2015-04-25 15:00:00','Southampton','Tottenham Hotspur',NULL,NULL,NULL),(363,'2015-04-25 15:00:00','Stoke City','Sunderland',NULL,NULL,NULL),(364,'2015-04-25 15:00:00','West Bromwich Albion','Liverpool',NULL,NULL,NULL),(365,'2015-05-02 15:00:00','Aston Villa','Everton',NULL,NULL,NULL),(366,'2015-05-02 15:00:00','Chelsea','Crystal Palace',NULL,NULL,NULL),(367,'2015-05-02 15:00:00','Hull City','Arsenal',NULL,NULL,NULL),(368,'2015-05-02 15:00:00','Leicester City','Newcastle United',NULL,NULL,NULL),(369,'2015-05-02 15:00:00','Liverpool','Queens Park Rangers',NULL,NULL,NULL),(370,'2015-05-02 15:00:00','Manchester United','West Bromwich Albion',NULL,NULL,NULL),(371,'2015-05-02 15:00:00','Sunderland','Southampton',NULL,NULL,NULL),(372,'2015-05-02 15:00:00','Swansea City','Stoke City',NULL,NULL,NULL),(373,'2015-05-02 15:00:00','Tottenham Hotspur','Manchester City',NULL,NULL,NULL),(374,'2015-05-02 15:00:00','West Ham United','Burnley',NULL,NULL,NULL),(375,'2015-05-09 15:00:00','Arsenal','Swansea City',NULL,NULL,NULL),(376,'2015-05-09 15:00:00','Aston Villa','West Ham United',NULL,NULL,NULL),(377,'2015-05-09 15:00:00','Chelsea','Liverpool',NULL,NULL,NULL),(378,'2015-05-09 15:00:00','Crystal Palace','Manchester United',NULL,NULL,NULL),(379,'2015-05-09 15:00:00','Everton','Sunderland',NULL,NULL,NULL),(380,'2015-05-09 15:00:00','Hull City','Burnley',NULL,NULL,NULL),(381,'2015-05-09 15:00:00','Leicester City','Southampton',NULL,NULL,NULL),(382,'2015-05-09 15:00:00','Manchester City','Queens Park Rangers',NULL,NULL,NULL),(383,'2015-05-09 15:00:00','Newcastle United','West Bromwich Albion',NULL,NULL,NULL),(384,'2015-05-09 15:00:00','Stoke City','Tottenham Hotspur',NULL,NULL,NULL),(385,'2015-05-16 15:00:00','Burnley','Stoke City',NULL,NULL,NULL),(386,'2015-05-16 15:00:00','Liverpool','Crystal Palace',NULL,NULL,NULL),(387,'2015-05-16 15:00:00','Manchester United','Arsenal',NULL,NULL,NULL),(388,'2015-05-16 15:00:00','Queens Park Rangers','Newcastle United',NULL,NULL,NULL),(389,'2015-05-16 15:00:00','Southampton','Aston Villa',NULL,NULL,NULL),(390,'2015-05-16 15:00:00','Sunderland','Leicester City',NULL,NULL,NULL),(391,'2015-05-16 15:00:00','Swansea City','Manchester City',NULL,NULL,NULL),(392,'2015-05-16 15:00:00','Tottenham Hotspur','Hull City',NULL,NULL,NULL),(393,'2015-05-16 15:00:00','West Bromwich Albion','Chelsea',NULL,NULL,NULL),(394,'2015-05-16 15:00:00','West Ham United','Everton',NULL,NULL,NULL),(395,'2015-05-24 15:00:00','Arsenal','West Bromwich Albion',NULL,NULL,NULL),(396,'2015-05-24 15:00:00','Aston Villa','Burnley',NULL,NULL,NULL),(397,'2015-05-24 15:00:00','Chelsea','Sunderland',NULL,NULL,NULL),(398,'2015-05-24 15:00:00','Crystal Palace','Swansea City',NULL,NULL,NULL),(399,'2015-05-24 15:00:00','Everton','Tottenham Hotspur',NULL,NULL,NULL),(400,'2015-05-24 15:00:00','Hull City','Manchester United',NULL,NULL,NULL),(401,'2015-05-24 15:00:00','Leicester City','Queens Park Rangers',NULL,NULL,NULL),(402,'2015-05-24 15:00:00','Manchester City','Southampton',NULL,NULL,NULL),(403,'2015-05-24 15:00:00','Newcastle United','West Ham United',NULL,NULL,NULL),(404,'2015-05-24 15:00:00','Stoke City','Liverpool',NULL,NULL,NULL);
/*!40000 ALTER TABLE `fixtureresults` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gameweekmap`
--

DROP TABLE IF EXISTS `gameweekmap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gameweekmap` (
  `GameWeek` int(11) NOT NULL,
  `DateFrom` datetime NOT NULL,
  `DateTo` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gameweekmap`
--

LOCK TABLES `gameweekmap` WRITE;
/*!40000 ALTER TABLE `gameweekmap` DISABLE KEYS */;
INSERT INTO `gameweekmap` VALUES (6,'2014-09-27 00:00:00','2014-09-29 23:59:00'),(7,'2014-10-04 00:00:00','2014-10-05 23:59:00'),(8,'2014-10-18 00:00:00','2014-10-20 23:59:00'),(9,'2014-10-25 00:00:00','2014-10-27 23:59:00'),(10,'2014-11-01 00:00:00','2014-11-03 23:59:00'),(11,'2014-11-08 00:00:00','2014-11-09 23:59:00'),(12,'2014-11-22 00:00:00','2014-11-24 23:59:00');
/*!40000 ALTER TABLE `gameweekmap` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `predictions`
--

DROP TABLE IF EXISTS `predictions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `predictions` (
  `DateTimeEntered` datetime DEFAULT NULL,
  `PredictionID` int(11) NOT NULL AUTO_INCREMENT,
  `FixtureID` int(11) NOT NULL,
  `UserName` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `TeamName` varchar(50) DEFAULT NULL,
  `PredictedResult` int(11) NOT NULL,
  `PredictionCorrect` bit(1) DEFAULT NULL COMMENT '1=correct, 0=incorrect',
  PRIMARY KEY (`PredictionID`),
  UNIQUE KEY `UserTeam` (`UserName`,`TeamName`),
  KEY `User` (`UserName`(191)),
  KEY `Fixture` (`FixtureID`),
  CONSTRAINT `predictions_ibfk_1` FOREIGN KEY (`UserName`) REFERENCES `users` (`username`),
  CONSTRAINT `predictions_ibfk_2` FOREIGN KEY (`FixtureID`) REFERENCES `fixtureresults` (`FixtureId`)
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `predictions`
--

LOCK TABLES `predictions` WRITE;
/*!40000 ALTER TABLE `predictions` DISABLE KEYS */;
INSERT INTO `predictions` VALUES ('2014-10-01 08:35:19',97,87,'tommygrealy','Hull City',1,NULL),('2014-10-01 08:35:19',98,90,'myname','Everton',3,NULL),('2014-10-01 08:35:19',99,89,'johnbligh','Liverpool',1,NULL),('2014-10-01 08:35:19',100,89,'deccotter','Liverpool',1,NULL),('2014-10-01 08:35:19',101,89,'jamesoneill','Liverpool',1,NULL),('2014-10-01 08:35:19',102,93,'markryan','Tottenham Hotspur',1,NULL),('2014-10-01 08:35:19',103,90,'patguerin','Manchester United',1,NULL),('2014-10-01 08:35:19',104,86,'seamushetherton','Arsenal',3,NULL),('2014-10-01 08:35:19',105,91,'joegleeson','Stoke City',3,NULL),('2014-10-01 08:35:19',106,86,'gerforde','Chelsea',1,NULL);
/*!40000 ALTER TABLE `predictions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `showloosingpredictions`
--

DROP TABLE IF EXISTS `showloosingpredictions`;
/*!50001 DROP VIEW IF EXISTS `showloosingpredictions`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `showloosingpredictions` (
  `KickOffTime` datetime,
  `FixtureId` int(11),
  `HomeTeam` varchar(50),
  `AwayTeam` varchar(50),
  `Result` smallint(6),
  `PredictionID` int(11),
  `username` varchar(255),
  `PredictedResult` int(11)
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `showwinningpredictions`
--

DROP TABLE IF EXISTS `showwinningpredictions`;
/*!50001 DROP VIEW IF EXISTS `showwinningpredictions`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `showwinningpredictions` (
  `KickOffTime` datetime,
  `FixtureId` int(11),
  `HomeTeam` varchar(50),
  `AwayTeam` varchar(50),
  `Result` smallint(6),
  `PredictionID` int(11),
  `username` varchar(255),
  `PredictedResult` int(11)
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `status`
--

DROP TABLE IF EXISTS `status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `status` (
  `StatusID` int(11) NOT NULL,
  `Description` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `status`
--

LOCK TABLES `status` WRITE;
/*!40000 ALTER TABLE `status` DISABLE KEYS */;
INSERT INTO `status` VALUES (1,'Active'),(2,'Eliminated'),(3,'Waiting Payment');
/*!40000 ALTER TABLE `status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `FullName` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` char(64) COLLATE utf8_unicode_ci NOT NULL,
  `salt` char(16) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `CompStatus` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `PaymentStatus` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (11,'tommygrealy',NULL,'3078438e6cd67c546ada7732be5d8a325598d510a94b5372fd91627f43009fa1','57cf4c9917d1f481','tommygrealy@gmail.com','Eliminated',NULL),(12,'myname',NULL,'419df665541cdf86a5a0b86907a36b10709d35668134939e0f53e88e04d2de95','58ffd6f41f1b1fb2','myname@gmail.com','Eliminated',NULL),(13,'johnbligh',NULL,'77c2958be9737d0fb710110e239554685305b72fa52edc535422c703b6cf5e62','2b6baa00484e0989','johnbligh@gmail.com','Eliminated',NULL),(14,'deccotter',NULL,'c80c476e31498ec2ad0328f53ffb589824c8a2dbbc968647ccd8f3fb3886fd6a','1cf96204445cf8b6','dec@eowfk.ie','Eliminated',NULL),(15,'jamesoneill',NULL,'2b8c10c40b5eaa84d6c406cea860f6b0e77ba1ceae4267296afbfa48b0145a40','31bee322217c7f3','jamesoneill@gmail.com','Eliminated',NULL),(16,'markryan',NULL,'aea948da33c33dab88ff0f5031c4f4881d1c3bbe33cd12b5fafdd672c715f53b','9019c16588d7cc2','markryan@gmail.com','Eliminated',NULL),(17,'patguerin',NULL,'a2fa756cfcf88905c90135c231cd619e94ba6fe4f5d06d5efd9b4b2eff70a1ec','17b7a63c50cbf012','patguerin@gmail.com','Eliminated',NULL),(18,'seamushetherton',NULL,'f4a9c76726556f837b76672319bee5ce503dd6010b67e5a5e4252a1e9af06ab4','2de7dc4a541ee2c9','seamushetherton@gmail.com','Eliminated',NULL),(19,'joegleeson',NULL,'f1fd97fcc3ea4f4d77c013649ab70810453e4583bbee23756050d071dd2c5893','6c32ca6b19aaa8c1','joegleeson@gmail.com','Eliminated',NULL),(20,'gerforde',NULL,'3c71235b037720e7437881d27f3e3754b017a864763160225ee2fd53bc19c66a','5d54210d44d70fad','gerforde@gmail.com','Eliminated',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'lastmanstanding'
--
/*!50003 DROP PROCEDURE IF EXISTS `insertPrediction` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `insertPrediction`(
IN 
inFixtureID int(11),
inUserName varchar(255),
inPredictedResult int(11)
)
BEGIN

DECLARE inTeamName varchar(50);

	IF inPredictedResult=1 THEN SET inTeamName=(select HomeTeam from fixtureresults where fixtureid = inFixtureId);
	ELSEIF inPredictedResult=3 THEN SET inTeamName=(select AwayTeam from fixtureresults where fixtureid = inFixtureId);
END IF;


insert into predictions (DateTimeEntered, FixtureID, UserName, TeamName, PredictedResult)
values
(
	(select CURRENT_TIMESTAMP),
	inFixtureID,
	inUserName,
	inTeamName,
	inPredictedResult
);

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `updateUserPositions` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `updateUserPositions`()
BEGIN

create TEMPORARY table WinningPredictions as (SELECT PredictionID FROM lastmanstanding.showwinningpredictions);
create TEMPORARY table LoosingPredictions as (SELECT PredictionID FROM lastmanstanding.showloosingpredictions);
create TEMPORARY table LoosingUsers as (select username from showloosingpredictions);


update users set CompStatus = 'Eliminated' where username in 
 (select * from LoosingUsers);
update predictions set PredictionCorrect=0 where PredictionID in 
 (select * from LoosingPredictions);
update predictions set PredictionCorrect=1 where PredictionID in 
 (select * from WinningPredictions); 

DROP table WinningPredictions;
DROP table LoosingPredictions;
DROP table LoosingUsers;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `allfixturesandclubinfo`
--

/*!50001 DROP TABLE IF EXISTS `allfixturesandclubinfo`*/;
/*!50001 DROP VIEW IF EXISTS `allfixturesandclubinfo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `allfixturesandclubinfo` AS select distinct `fr`.`KickOffTime` AS `KickOffTime`,`fr`.`HomeTeam` AS `HomeTeam`,`fr`.`AwayTeam` AS `AwayTeam`,(select `clubs`.`ShortName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8))) AS `ShortName`,(select `clubs`.`ShortName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8))) AS `ShortNameAway`,(select `clubs`.`CrestURLSmall` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8))) AS `HomeCrestImg`,(select `clubs`.`CrestURLSmall` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8))) AS `AwayCrestImg` from (`fixtureresults` `fr` join `clubs` `cl`) where ((convert(`fr`.`HomeTeam` using utf8) = `cl`.`LongName`) or (convert(`fr`.`AwayTeam` using utf8) = `cl`.`LongName`)) order by `fr`.`KickOffTime` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `showloosingpredictions`
--

/*!50001 DROP TABLE IF EXISTS `showloosingpredictions`*/;
/*!50001 DROP VIEW IF EXISTS `showloosingpredictions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `showloosingpredictions` AS select `fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`Result` AS `Result`,`predictions`.`PredictionID` AS `PredictionID`,`predictions`.`UserName` AS `username`,`predictions`.`PredictedResult` AS `PredictedResult` from (`fixtureresults` join `predictions` on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where (`fixtureresults`.`Result` <> `predictions`.`PredictedResult`) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `showwinningpredictions`
--

/*!50001 DROP TABLE IF EXISTS `showwinningpredictions`*/;
/*!50001 DROP VIEW IF EXISTS `showwinningpredictions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `showwinningpredictions` AS select `fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`Result` AS `Result`,`predictions`.`PredictionID` AS `PredictionID`,`predictions`.`UserName` AS `username`,`predictions`.`PredictedResult` AS `PredictedResult` from (`fixtureresults` join `predictions` on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where (`fixtureresults`.`Result` = `predictions`.`PredictedResult`) */;
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

-- Dump completed on 2014-10-01  8:58:25
