-- MySQL dump 10.13  Distrib 8.0.40, for Linux (x86_64)
--
-- Host: localhost    Database: lastmanstanding
-- ------------------------------------------------------
-- Server version	8.0.40-0ubuntu0.22.04.1

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
-- Temporary view structure for view `allfixturesandclubinfo`
--

DROP TABLE IF EXISTS `allfixturesandclubinfo`;
/*!50001 DROP VIEW IF EXISTS `allfixturesandclubinfo`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `allfixturesandclubinfo` AS SELECT 
 1 AS `FixtureId`,
 1 AS `KickOffTime`,
 1 AS `HomeTeam`,
 1 AS `AwayTeam`,
 1 AS `KillerTeam`,
 1 AS `ShortNameHome`,
 1 AS `ShortNameAway`,
 1 AS `MedNameHome`,
 1 AS `MedNameAway`,
 1 AS `HomeCrestImg`,
 1 AS `AwayCrestImg`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `api_tokens`
--

DROP TABLE IF EXISTS `api_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_tokens` (
  `id_api_tokens` int NOT NULL AUTO_INCREMENT,
  `fk_user_id` int DEFAULT NULL,
  `token` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `expire_dt` datetime DEFAULT NULL,
  PRIMARY KEY (`id_api_tokens`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clubs`
--

DROP TABLE IF EXISTS `clubs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clubs` (
  `ClubId` int NOT NULL AUTO_INCREMENT,
  `LongName` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `MedName` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `ShortName` varchar(8) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `CrestURLSmall` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `CresURLLarge` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  PRIMARY KEY (`ClubId`)
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `detailedpredictions`
--

DROP TABLE IF EXISTS `detailedpredictions`;
/*!50001 DROP VIEW IF EXISTS `detailedpredictions`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `detailedpredictions` AS SELECT 
 1 AS `FullName`,
 1 AS `email`,
 1 AS `KickOffTime`,
 1 AS `FixtureDetail`,
 1 AS `User Selected`,
 1 AS `DateTimeEntered`,
 1 AS `PredictionID`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `dynamite`
--

DROP TABLE IF EXISTS `dynamite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dynamite` (
  `dynamite_id` int NOT NULL AUTO_INCREMENT,
  `granted_to_user_fk` int DEFAULT NULL,
  `target_user_fk` int DEFAULT NULL,
  `won_in_fixture_id` int DEFAULT NULL,
  `status` int DEFAULT NULL COMMENT '1=Active\n0=Used',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expiry` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`dynamite_id`),
  UNIQUE KEY `unique_granted_won` (`granted_to_user_fk`,`won_in_fixture_id`),
  KEY `id_idx` (`granted_to_user_fk`),
  CONSTRAINT `id` FOREIGN KEY (`granted_to_user_fk`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dynamite_archive`
--

DROP TABLE IF EXISTS `dynamite_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dynamite_archive` (
  `dynamite_id` int NOT NULL AUTO_INCREMENT,
  `granted_to_user_fk` int DEFAULT NULL,
  `target_user_fk` int DEFAULT NULL,
  `won_in_fixture_id` int DEFAULT NULL,
  `status` int DEFAULT NULL COMMENT '1=Active\n0=Used',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expiry` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`dynamite_id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fixtureresults`
--

DROP TABLE IF EXISTS `fixtureresults`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fixtureresults` (
  `FixtureId` int NOT NULL AUTO_INCREMENT,
  `KickOffTime` datetime NOT NULL,
  `HomeTeam` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `AwayTeam` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `HomeTeamScore` int DEFAULT NULL,
  `AwayTeamScore` int DEFAULT NULL,
  `KillerTeam` int DEFAULT NULL,
  `Result` smallint DEFAULT NULL COMMENT '1=Home Win2=Draw3=Away Win',
  UNIQUE KEY `FixtureId` (`FixtureId`),
  KEY `HomeTeam` (`HomeTeam`),
  KEY `AwayTeam` (`AwayTeam`)
) ENGINE=InnoDB AUTO_INCREMENT=2176 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci COMMENT='Result (1=home win, 2=Draw, 3=away win)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fixtureresults_archive`
--

DROP TABLE IF EXISTS `fixtureresults_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fixtureresults_archive` (
  `FixtureId` int NOT NULL DEFAULT '0',
  `KickOffTime` datetime NOT NULL,
  `HomeTeam` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `AwayTeam` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `HomeTeamScore` int DEFAULT NULL,
  `AwayTeamScore` int DEFAULT NULL,
  `Result` smallint DEFAULT NULL COMMENT '1=Home Win2=Draw3=Away Win'
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fixtures_join_gameweek`
--

DROP TABLE IF EXISTS `fixtures_join_gameweek`;
/*!50001 DROP VIEW IF EXISTS `fixtures_join_gameweek`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `fixtures_join_gameweek` AS SELECT 
 1 AS `GameWeek`,
 1 AS `FixtureId`,
 1 AS `KickOffTime`,
 1 AS `HomeTeam`,
 1 AS `AwayTeam`,
 1 AS `HomeTeamScore`,
 1 AS `AwayTeamScore`,
 1 AS `KillerTeam`,
 1 AS `Result`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `gameweekmap`
--

DROP TABLE IF EXISTS `gameweekmap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gameweekmap` (
  `GameWeek` int NOT NULL,
  `DateFrom` datetime NOT NULL,
  `DateTo` datetime NOT NULL,
  PRIMARY KEY (`GameWeek`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `league_memberships`
--

DROP TABLE IF EXISTS `league_memberships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `league_memberships` (
  `league_mem_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `league_id` int NOT NULL,
  PRIMARY KEY (`league_mem_id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `leagues`
--

DROP TABLE IF EXISTS `leagues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `leagues` (
  `leagueId` int NOT NULL AUTO_INCREMENT,
  `LeagueName` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `LeaguePassword` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `LeagueDescr` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `entry_fee` int NOT NULL,
  PRIMARY KEY (`leagueId`)
) ENGINE=InnoDB AUTO_INCREMENT=556 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `passwordresettokens`
--

DROP TABLE IF EXISTS `passwordresettokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `passwordresettokens` (
  `idpasswordResetTokens` int NOT NULL AUTO_INCREMENT,
  `token` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `username` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `expiry` datetime NOT NULL,
  PRIMARY KEY (`idpasswordResetTokens`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `playingnotpaid`
--

DROP TABLE IF EXISTS `playingnotpaid`;
/*!50001 DROP VIEW IF EXISTS `playingnotpaid`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `playingnotpaid` AS SELECT 
 1 AS `username`,
 1 AS `FullName`,
 1 AS `email`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `predictions`
--

DROP TABLE IF EXISTS `predictions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `predictions` (
  `DateTimeEntered` datetime DEFAULT NULL,
  `EntryType` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `PredictionID` int NOT NULL AUTO_INCREMENT,
  `GameWeek` int DEFAULT NULL,
  `FixtureID` int NOT NULL,
  `UserName` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `TeamName` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `PredictedResult` int NOT NULL COMMENT '1=Home Win, 3=Away Win',
  `PredictionStatus` varchar(8) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT 'A=Active;C=Cancelled',
  `PredictionCorrect` tinyint(1) DEFAULT NULL COMMENT '1=correct, 0=incorrect, 2=Exception',
  PRIMARY KEY (`PredictionID`),
  UNIQUE KEY `UserTeam` (`UserName`,`TeamName`),
  UNIQUE KEY `UserGameWeek` (`GameWeek`,`UserName`),
  KEY `User` (`UserName`(191)),
  KEY `Fixture` (`FixtureID`),
  KEY `DateTimeEntered` (`DateTimeEntered`)
) ENGINE=InnoDB AUTO_INCREMENT=1476 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `predictions_archive`
--

DROP TABLE IF EXISTS `predictions_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `predictions_archive` (
  `DateTimeEntered` datetime DEFAULT NULL,
  `EntryType` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `PredictionID` int NOT NULL DEFAULT '0',
  `GameWeek` int DEFAULT NULL,
  `FixtureID` int NOT NULL,
  `UserName` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `TeamName` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `PredictedResult` int NOT NULL,
  `PredictionStatus` varchar(8) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `PredictionCorrect` bit(1) DEFAULT NULL COMMENT '1=correct, 0=incorrect'
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `predictionstrash`
--

DROP TABLE IF EXISTS `predictionstrash`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `predictionstrash` (
  `DateTimeEntered` datetime DEFAULT NULL,
  `EntryType` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `PredictionID` int NOT NULL AUTO_INCREMENT,
  `GameWeek` int DEFAULT NULL,
  `FixtureID` int NOT NULL,
  `UserName` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `TeamName` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `PredictedResult` int NOT NULL,
  `PredictionStatus` varchar(8) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT 'C=Cancelled ; A=Active',
  `PredictionCorrect` bit(1) DEFAULT NULL COMMENT '1=correct, 0=incorrect',
  PRIMARY KEY (`PredictionID`)
) ENGINE=InnoDB AUTO_INCREMENT=1472 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `showloosingpredictions`
--

DROP TABLE IF EXISTS `showloosingpredictions`;
/*!50001 DROP VIEW IF EXISTS `showloosingpredictions`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `showloosingpredictions` AS SELECT 
 1 AS `KickOffTime`,
 1 AS `FixtureId`,
 1 AS `HomeTeam`,
 1 AS `AwayTeam`,
 1 AS `Result`,
 1 AS `PredictionID`,
 1 AS `username`,
 1 AS `PredictedResult`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `showwinningpredictions`
--

DROP TABLE IF EXISTS `showwinningpredictions`;
/*!50001 DROP VIEW IF EXISTS `showwinningpredictions`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `showwinningpredictions` AS SELECT 
 1 AS `KickOffTime`,
 1 AS `FixtureId`,
 1 AS `HomeTeam`,
 1 AS `AwayTeam`,
 1 AS `Result`,
 1 AS `PredictionID`,
 1 AS `username`,
 1 AS `PredictedResult`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `status`
--

DROP TABLE IF EXISTS `status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `status` (
  `StatusID` int NOT NULL,
  `Description` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `thisweeksfixtures`
--

DROP TABLE IF EXISTS `thisweeksfixtures`;
/*!50001 DROP VIEW IF EXISTS `thisweeksfixtures`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `thisweeksfixtures` AS SELECT 
 1 AS `FixtureId`,
 1 AS `KickOffTime`,
 1 AS `HomeTeam`,
 1 AS `AwayTeam`,
 1 AS `ShortNameHome`,
 1 AS `ShortNameAway`,
 1 AS `MedNameHome`,
 1 AS `MedNameAway`,
 1 AS `HomeCrestImg`,
 1 AS `AwayCrestImg`,
 1 AS `KillerTeam`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `userfeedback`
--

DROP TABLE IF EXISTS `userfeedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `userfeedback` (
  `commentId` int NOT NULL AUTO_INCREMENT,
  `commentUserName` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `commentEmail` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `commentText` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `commentDate` datetime DEFAULT NULL,
  `commentReplySent` binary(1) DEFAULT NULL,
  PRIMARY KEY (`commentId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `FullName` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `password` char(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `salt` char(16) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `PrivLevel` int NOT NULL DEFAULT '1',
  `email` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `lives` int NOT NULL DEFAULT '3',
  `CompStatus` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `PaymentStatus` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2225 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `users_join_leagues`
--

DROP TABLE IF EXISTS `users_join_leagues`;
/*!50001 DROP VIEW IF EXISTS `users_join_leagues`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `users_join_leagues` AS SELECT 
 1 AS `id`,
 1 AS `username`,
 1 AS `FullName`,
 1 AS `password`,
 1 AS `salt`,
 1 AS `PrivLevel`,
 1 AS `email`,
 1 AS `CompStatus`,
 1 AS `PaymentStatus`,
 1 AS `league_id`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `usersnotsubmitted`
--

DROP TABLE IF EXISTS `usersnotsubmitted`;
/*!50001 DROP VIEW IF EXISTS `usersnotsubmitted`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `usersnotsubmitted` AS SELECT 
 1 AS `Email`,
 1 AS `FullName`,
 1 AS `username`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'lastmanstanding'
--

--
-- Dumping routines for database 'lastmanstanding'
--
/*!50003 DROP PROCEDURE IF EXISTS `cancelPrediction` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `cancelPrediction`(IN `inPredictionID` INT(11), IN `inUserName` VARCHAR(255))
BEGIN

DECLARE deadline datetime;

SET deadline = (select DateFrom from gameweekmap where DateFrom > 
(select now()) 
order by DateFrom asc limit 1);

if ((select now()) < (select deadline))
THEN
update predictions set PredictionStatus='C' where PredictionID = inPredictionID;
insert into predictionstrash (select * from predictions  WHERE PredictionID = inPredictionID and username = inUserName);
delete from predictions where PredictionID = inPredictionID and username = inUserName;
SELECT ROW_COUNT() as ROWS_AFFECTED;
ELSE
SELECT ('too late') as ROWS_AFFECTED;
END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `checkResultsVsPredictions` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `checkResultsVsPredictions`()
BEGIN

create TEMPORARY table WinningPredictions as (SELECT PredictionID FROM showwinningpredictions where KickOffTime > (SELECT DATE_SUB(NOW(), INTERVAL 5 day)));
create TEMPORARY table LoosingPredictions as (SELECT PredictionID FROM showloosingpredictions WHERE KickOffTime > (SELECT DATE_SUB(NOW(), INTERVAL 5 day)));
create TEMPORARY table LoosingUsers as (select username from showloosingpredictions WHERE KickOffTime > (SELECT DATE_SUB(NOW(), INTERVAL 5 day)));


update users set lives = lives - 1 where username in
(select * from LoosingUsers);
update predictions set PredictionCorrect=0 where PredictionID in 
 (select * from LoosingPredictions);
update predictions set PredictionCorrect=1 where PredictionID in 
 (select * from WinningPredictions);
update users set CompStatus = 'Eliminated' where lives = 0;

DROP table WinningPredictions;
DROP table LoosingPredictions;
DROP table LoosingUsers;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `generateResetForUsername` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `generateResetForUsername`(IN `inUsername` VARCHAR(255), IN `inToken` VARCHAR(45))
    NO SQL
insert into passwordresettokens (username, token, expiry)
values
(
	inUsername,
	inToken,
	(SELECT DATE_ADD((select NOW()), INTERVAL 10 MINUTE))
) ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `getNextFixtureForTeam` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `getNextFixtureForTeam`(IN `TeamNameLong` VARCHAR(50))
BEGIN

select * from fixtureresults where 
(HomeTeam = TeamNameLong 
or AwayTeam = TeamNameLong) and KickOffTime > (select now()) order by KickOffTime 
Limit 1;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `getUserDetailsFromToken` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserDetailsFromToken`(IN `inToken` VARCHAR(45))
    NO SQL
select username from users where username = 
(select username from passwordresettokens where token = inToken and expiry > (select NOW())) ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `insertPrediction` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `insertPrediction`(IN `inFixtureID` INT(11), IN `inUserName` VARCHAR(255), IN `inPredictedResult` INT(11), IN `inEntryType` VARCHAR(10))
BEGIN

DECLARE inGameWeek int (11);
DECLARE inTeamName varchar(50);


SET inGameWeek =  (select GameWeek from gameweekmap where DateTo > (select CURRENT_TIMESTAMP) limit 1);

	IF inPredictedResult=1 THEN SET inTeamName=(select HomeTeam from fixtureresults where fixtureid = inFixtureId);
	ELSEIF inPredictedResult=3 THEN SET inTeamName=(select AwayTeam from fixtureresults where fixtureid = inFixtureId);
END IF;




insert into predictions 
(DateTimeEntered, EntryType, FixtureID, GameWeek, UserName, TeamName, PredictionStatus, PredictedResult)
values
(
	(select CURRENT_TIMESTAMP),
	inEntryType,
	inFixtureID,
	inGameWeek,
	inUserName,
	inTeamName,
    'A',
	inPredictedResult
);

SELECT LAST_INSERT_ID() as PredictionID;


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `passwordReset` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `passwordReset`(IN `inUsername` VARCHAR(255), IN `inPassword` VARCHAR(64), IN `inSalt` VARCHAR(16))
    NO SQL
update users 
set password=inPassword, salt=inSalt
where username = inUsername ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `selectRandomTeam` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `selectRandomTeam`(IN `inUser` VARCHAR(255))
    NO SQL
SELECT `LongName` FROM `clubs` WHERE `LongName` not in
(select `TeamName` from predictions where Username = inUser) order by rand() limit 1 ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showAvailableTeamsForUser` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showAvailableTeamsForUser`(IN `inUserName` VARCHAR(255))
    READS SQL DATA
BEGIN

select ClubId, LongName,MedName,ShortName from clubs 
where LongName not in (select TeamName from predictions where username = inUserName)
and MedName not in (select TeamName from predictions where username = inUserName)
ORDER by LongName;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showCurrentSelections` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showCurrentSelections`()
    NO SQL
    COMMENT 'Shows all user selections for the next round of games.'
BEGIN

DECLARE inGameWeek int (11);
SET inGameWeek =  (select GameWeek from gameweekmap where DateFrom > (select CURRENT_TIMESTAMP) limit 1);
select 
        `fixtureresults`.`KickOffTime` AS `KickOffTime`,
        `fixtureresults`.`FixtureId` AS `FixtureId`,
        `predictions`.`DateTimeEntered`, 
        `fixtureresults`.`HomeTeam` AS `HomeTeam`,
        `fixtureresults`.`AwayTeam` AS `AwayTeam`,
        `fixtureresults`.`Result` AS `Result`,
        `predictions`.`PredictionID` AS `PredictionID`,
        `predictions`.`UserName` AS `username`,
        `predictions`.`TeamName` AS `PredictedTeam`
    from
        (`fixtureresults`
        join `predictions` ON ((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`)))
    where
        `predictions`.`GameWeek` = inGameWeek
   ORDER BY  `predictions`.`DateTimeEntered` DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showCurrentStandings` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showCurrentStandings`()
BEGIN
select username, FullName, lives, CompStatus from users where PaymentStatus='Paid';

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showCurrentStandingsByLeague` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showCurrentStandingsByLeague`(IN `league_id` INT(11))
BEGIN
select username, FullName, lives, CompStatus from users where PaymentStatus='Paid' 
AND username IN (SELECT username from users_join_leagues WHERE users_join_leagues.league_id = league_id);

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showNullResultFixtures` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showNullResultFixtures`()
    NO SQL
    COMMENT 'Shows all past fixtures which have a null value for result'
select * from fixtureresults where Result is null and KickOffTime < (select now()) ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showPredsByGameWeek` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showPredsByGameWeek`(IN `inGameWeek` INT)
    NO SQL
select * from predictions where gameweek=inGameWeek ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showSelectionsPostDeadline` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showSelectionsPostDeadline`()
    NO SQL
    COMMENT 'Shows all user selections for the next round of games.'
BEGIN

DECLARE inGameWeek int (11);
DECLARE deadline datetime;

SET inGameWeek =  (select GameWeek from gameweekmap where DateTo > (select CURRENT_TIMESTAMP) limit 1);
SET deadline = (select DateFrom from gameweekmap where GameWeek = (select inGameWeek));

if ((select now()) > (select deadline))
THEN
	select 
        `fixtureresults`.`KickOffTime` AS `KickOffTime`,
        `fixtureresults`.`FixtureId` AS `FixtureId`,
        `predictions`.`DateTimeEntered`, 
        `fixtureresults`.`HomeTeam` AS `HomeTeam`,
        `fixtureresults`.`AwayTeam` AS `AwayTeam`,
        `fixtureresults`.`Result` AS `Result`,
        `fixtureresults`.`KillerTeam` AS KillerTeam,
        `predictions`.`PredictionID` AS `PredictionID`,
        `predictions`.`UserName` AS `username`,
        `predictions`.`TeamName` AS `PredictedTeam`,
		`predictions`.`EntryType` AS `EntryType`,
	`users`.`FullName` AS `FullName`
    from
        (`fixtureresults`
        join `predictions` ON (`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`)
		join `users` ON (`predictions`.`UserName` = `users`.`username`))
    where
        `predictions`.`GameWeek` = inGameWeek
   ORDER BY  `predictions`.`DateTimeEntered` DESC;
ELSE
	SELECT deadline as TIME_PUBLIC;
END IF;
   
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showUserCurrentSelection` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showUserCurrentSelection`(IN `inUserName` VARCHAR(255))
BEGIN

DECLARE inGameWeek int (11);
SET inGameWeek =  (select GameWeek from gameweekmap where DateFrom > (select CURRENT_TIMESTAMP) limit 1);

select 
        `fixtureresults`.`KickOffTime` AS `KickOffTime`,
        `fixtureresults`.`FixtureId` AS `FixtureId`,
        `fixtureresults`.`HomeTeam` AS `HomeTeam`,
        `fixtureresults`.`AwayTeam` AS `AwayTeam`,
        `fixtureresults`.`Result` AS `Result`,
        `predictions`.`PredictionID` AS `PredictionID`,
        `predictions`.`UserName` AS `username`,
        `predictions`.`TeamName` AS `PredictedTeam`
    from
        (`fixtureresults`
        join `predictions` ON ((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`)))
    where
        (`predictions`.`UserName` = inUserName)
		and
		(`predictions`.`GameWeek` = inGameWeek);

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `showUserPredictionHistory` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showUserPredictionHistory`(IN `inUsername` VARCHAR(255))
BEGIN


select 
`fixtureresults`.`KickOffTime` AS `KickOffTime`,
`fixtureresults`.`FixtureId` AS `FixtureId`,
`fixtureresults`.`HomeTeam` AS `HomeTeam`,
`fixtureresults`.`AwayTeam` AS `AwayTeam`,
`fixtureresults`.`Result` AS `Result`,
`predictions`.`PredictionID` AS `PredictionID`,
`predictions`.`TeamName` AS `PredictedWinner`, 
`predictions`.`PredictedResult` AS `PredictedResult`, 
`predictions`.`PredictionCorrect` AS `PredictedResult` 
from (`fixtureresults` join `predictions` 
on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where 
(`predictions`.`UserName`= inUsername and
`fixtureresults`.`KickOffTime` < 

(select now())) ORDER BY KickOffTime DESC;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `updateMatchScore` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateMatchScore`(IN `inFixtureID` INT(11), IN `inHomeScore` INT(11), IN `inAwayScore` INT(11), IN `inResult` INT(11))
BEGIN

update fixtureresults 
set HomeTeamScore=inHomeScore, AwayTeamScore=inAwayScore, Result=inResult
where FixtureId = inFixtureID;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `updatePaymentStatus` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updatePaymentStatus`(IN `inUserName` VARCHAR(255), IN `inPayStat` VARCHAR(45))
BEGIN

update users set PaymentStatus=inPayStat where username=inUserName;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `allfixturesandclubinfo`
--

/*!50001 DROP VIEW IF EXISTS `allfixturesandclubinfo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `allfixturesandclubinfo` AS select distinct `fr`.`FixtureId` AS `FixtureId`,`fr`.`KickOffTime` AS `KickOffTime`,`fr`.`HomeTeam` AS `HomeTeam`,`fr`.`AwayTeam` AS `AwayTeam`,`fr`.`KillerTeam` AS `KillerTeam`,(select `clubs`.`ShortName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8mb3))) AS `ShortNameHome`,(select `clubs`.`ShortName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8mb3))) AS `ShortNameAway`,(select `clubs`.`MedName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8mb3))) AS `MedNameHome`,(select `clubs`.`MedName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8mb3))) AS `MedNameAway`,(select `clubs`.`CrestURLSmall` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8mb3))) AS `HomeCrestImg`,(select `clubs`.`CrestURLSmall` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8mb3))) AS `AwayCrestImg` from (`fixtureresults` `fr` join `clubs` `cl`) where ((convert(`fr`.`HomeTeam` using utf8mb3) = `cl`.`LongName`) or (convert(`fr`.`AwayTeam` using utf8mb3) = `cl`.`LongName`)) order by `fr`.`KickOffTime` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `detailedpredictions`
--

/*!50001 DROP VIEW IF EXISTS `detailedpredictions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `detailedpredictions` AS select `users`.`FullName` AS `FullName`,`users`.`email` AS `email`,`fixtureresults`.`KickOffTime` AS `KickOffTime`,(select concat(`fixtureresults`.`HomeTeam`,' vs ',`fixtureresults`.`AwayTeam`)) AS `FixtureDetail`,`predictions`.`TeamName` AS `User Selected`,`predictions`.`DateTimeEntered` AS `DateTimeEntered`,`predictions`.`PredictionID` AS `PredictionID` from ((`users` join `predictions` on((`users`.`username` = `predictions`.`UserName`))) join `fixtureresults` on((`predictions`.`FixtureID` = `fixtureresults`.`FixtureId`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fixtures_join_gameweek`
--

/*!50001 DROP VIEW IF EXISTS `fixtures_join_gameweek`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `fixtures_join_gameweek` AS select `gameweekmap`.`GameWeek` AS `GameWeek`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`HomeTeamScore` AS `HomeTeamScore`,`fixtureresults`.`AwayTeamScore` AS `AwayTeamScore`,`fixtureresults`.`KillerTeam` AS `KillerTeam`,`fixtureresults`.`Result` AS `Result` from (`fixtureresults` join `gameweekmap` on(((`fixtureresults`.`KickOffTime` >= `gameweekmap`.`DateFrom`) and (`fixtureresults`.`KickOffTime` < `gameweekmap`.`DateTo`)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `playingnotpaid`
--

/*!50001 DROP VIEW IF EXISTS `playingnotpaid`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `playingnotpaid` AS select `users`.`username` AS `username`,`users`.`FullName` AS `FullName`,`users`.`email` AS `email` from `users` where ((`users`.`CompStatus` = 'Playing') and (`users`.`PaymentStatus` <> 'Paid')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `showloosingpredictions`
--

/*!50001 DROP VIEW IF EXISTS `showloosingpredictions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `showloosingpredictions` AS select `fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`Result` AS `Result`,`predictions`.`PredictionID` AS `PredictionID`,`predictions`.`UserName` AS `username`,`predictions`.`PredictedResult` AS `PredictedResult` from (`fixtureresults` join `predictions` on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where ((`fixtureresults`.`Result` <> `predictions`.`PredictedResult`) and (`fixtureresults`.`Result` is not null) and (`predictions`.`PredictionCorrect` is null)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `showwinningpredictions`
--

/*!50001 DROP VIEW IF EXISTS `showwinningpredictions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `showwinningpredictions` AS select `fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`Result` AS `Result`,`predictions`.`PredictionID` AS `PredictionID`,`predictions`.`UserName` AS `username`,`predictions`.`PredictedResult` AS `PredictedResult` from (`fixtureresults` join `predictions` on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where ((`fixtureresults`.`Result` = `predictions`.`PredictedResult`) and (`predictions`.`PredictionCorrect` is null)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `thisweeksfixtures`
--

/*!50001 DROP VIEW IF EXISTS `thisweeksfixtures`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `thisweeksfixtures` AS select `allfixturesandclubinfo`.`FixtureId` AS `FixtureId`,`allfixturesandclubinfo`.`KickOffTime` AS `KickOffTime`,`allfixturesandclubinfo`.`HomeTeam` AS `HomeTeam`,`allfixturesandclubinfo`.`AwayTeam` AS `AwayTeam`,`allfixturesandclubinfo`.`ShortNameHome` AS `ShortNameHome`,`allfixturesandclubinfo`.`ShortNameAway` AS `ShortNameAway`,`allfixturesandclubinfo`.`MedNameHome` AS `MedNameHome`,`allfixturesandclubinfo`.`MedNameAway` AS `MedNameAway`,`allfixturesandclubinfo`.`HomeCrestImg` AS `HomeCrestImg`,`allfixturesandclubinfo`.`AwayCrestImg` AS `AwayCrestImg`,`allfixturesandclubinfo`.`KillerTeam` AS `KillerTeam` from `allfixturesandclubinfo` where (`allfixturesandclubinfo`.`KickOffTime` between (select `gameweekmap`.`DateFrom` from `gameweekmap` where (`gameweekmap`.`DateFrom` > (select now())) order by `gameweekmap`.`DateFrom` limit 1) and (select `gameweekmap`.`DateTo` from `gameweekmap` where (`gameweekmap`.`DateTo` > (select now())) order by `gameweekmap`.`DateTo` limit 1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `users_join_leagues`
--

/*!50001 DROP VIEW IF EXISTS `users_join_leagues`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `users_join_leagues` AS select `u`.`id` AS `id`,`u`.`username` AS `username`,`u`.`FullName` AS `FullName`,`u`.`password` AS `password`,`u`.`salt` AS `salt`,`u`.`PrivLevel` AS `PrivLevel`,`u`.`email` AS `email`,`u`.`CompStatus` AS `CompStatus`,`u`.`PaymentStatus` AS `PaymentStatus`,`l`.`league_id` AS `league_id` from (`users` `u` join `league_memberships` `l` on((`u`.`id` = `l`.`user_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `usersnotsubmitted`
--

/*!50001 DROP VIEW IF EXISTS `usersnotsubmitted`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `usersnotsubmitted` AS select `users`.`email` AS `Email`,`users`.`FullName` AS `FullName`,`users`.`username` AS `username` from `users` where (`users`.`username` in (select `predictions`.`UserName` from `predictions` where (`predictions`.`GameWeek` = (select `gameweekmap`.`GameWeek` from `gameweekmap` where (`gameweekmap`.`DateTo` > (select now())) order by `gameweekmap`.`DateTo` limit 1))) is false and (`users`.`CompStatus` = 'Playing') and (`users`.`PaymentStatus` = 'Paid')) */;
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

-- Dump completed on 2026-08-23 16:22:49
