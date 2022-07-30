-- phpMyAdmin SQL Dump
-- version 4.5.4.1deb2ubuntu2.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jul 30, 2022 at 12:18 PM
-- Server version: 5.7.33-0ubuntu0.16.04.1
-- PHP Version: 7.0.33-0ubuntu0.16.04.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `lastmanstanding`
--
CREATE DATABASE IF NOT EXISTS `lastmanstanding` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `lastmanstanding`;

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`lms`@`%` PROCEDURE `cancelPrediction` (IN `inPredictionID` INT(11), IN `inUserName` VARCHAR(255))  BEGIN

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

END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `checkResultsVsPredictions` ()  BEGIN

create TEMPORARY table WinningPredictions as (SELECT PredictionID FROM showwinningpredictions where KickOffTime > (SELECT DATE_SUB(NOW(), INTERVAL 5 day)));
create TEMPORARY table LoosingPredictions as (SELECT PredictionID FROM showloosingpredictions WHERE KickOffTime > (SELECT DATE_SUB(NOW(), INTERVAL 5 day)));
create TEMPORARY table LoosingUsers as (select username from showloosingpredictions WHERE KickOffTime > (SELECT DATE_SUB(NOW(), INTERVAL 5 day)));

update users set CompStatus = 'Eliminated' where username in 
 (select * from LoosingUsers);
update predictions set PredictionCorrect=0 where PredictionID in 
 (select * from LoosingPredictions);
update predictions set PredictionCorrect=1 where PredictionID in 
 (select * from WinningPredictions); 

DROP table WinningPredictions;
DROP table LoosingPredictions;
DROP table LoosingUsers;

END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `generateResetForUsername` (IN `inUsername` VARCHAR(255), IN `inToken` VARCHAR(45))  NO SQL
insert into passwordresettokens (username, token, expiry)
values
(
	inUsername,
	inToken,
	(SELECT DATE_ADD((select NOW()), INTERVAL 10 MINUTE))
)$$

CREATE DEFINER=`lms`@`%` PROCEDURE `getNextFixtureForTeam` (IN `TeamNameLong` VARCHAR(50))  BEGIN

select * from fixtureresults where 
(HomeTeam = TeamNameLong 
or AwayTeam = TeamNameLong) and KickOffTime > (select now()) order by KickOffTime 
Limit 1;

END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `getUserDetailsFromToken` (IN `inToken` VARCHAR(45))  NO SQL
select username from users where username = 
(select username from passwordresettokens where token = inToken and expiry > (select NOW()))$$

CREATE DEFINER=`lms`@`%` PROCEDURE `insertPrediction` (IN `inFixtureID` INT(11), IN `inUserName` VARCHAR(255), IN `inPredictedResult` INT(11), IN `inEntryType` VARCHAR(10))  BEGIN

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


END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `passwordReset` (IN `inUsername` VARCHAR(255), IN `inPassword` VARCHAR(64), IN `inSalt` VARCHAR(16))  NO SQL
update users 
set password=inPassword, salt=inSalt
where username = inUsername$$

CREATE DEFINER=`lms`@`%` PROCEDURE `selectRandomTeam` (IN `inUser` VARCHAR(255))  NO SQL
SELECT `LongName` FROM `clubs` WHERE `LongName` not in
(select `TeamName` from predictions where Username = inUser) order by rand() limit 1$$

CREATE DEFINER=`lms`@`%` PROCEDURE `showAvailableTeamsForUser` (IN `inUserName` VARCHAR(255))  BEGIN

select ClubId, LongName,MedName,ShortName from clubs 
where LongName not in (select TeamName from predictions where username = inUserName)
and MedName not in (select TeamName from predictions where username = inUserName)
ORDER by LongName;

END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `showCurrentSelections` ()  NO SQL
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
END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `showCurrentStandings` ()  BEGIN
select username, FullName, CompStatus from users where PaymentStatus='Paid';

END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `showNullResultFixtures` ()  NO SQL
    COMMENT 'Shows all past fixtures which have a null value for result'
select * from fixtureresults where Result is null and KickOffTime < (select now())$$

CREATE DEFINER=`lms`@`%` PROCEDURE `showPredsByGameWeek` (IN `inGameWeek` INT)  NO SQL
select * from predictions where gameweek=inGameWeek$$

CREATE DEFINER=`lms`@`%` PROCEDURE `showSelectionsPostDeadline` ()  NO SQL
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
   
END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `showUserCurrentSelection` (IN `inUserName` VARCHAR(255))  BEGIN

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

END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `showUserPredictionHistory` (IN `inUsername` VARCHAR(255))  BEGIN


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
/*
(select DateTo from gameweekmap where DateFrom > (SELECT NOW()) limit 1));
*/
(select now())) ORDER BY KickOffTime DESC;

END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `updateMatchScore` (IN `inFixtureID` INT(11), IN `inHomeScore` INT(11), IN `inAwayScore` INT(11), IN `inResult` INT(11))  BEGIN

update fixtureresults 
set HomeTeamScore=inHomeScore, AwayTeamScore=inAwayScore, Result=inResult
where FixtureId = inFixtureID;

END$$

CREATE DEFINER=`lms`@`%` PROCEDURE `updatePaymentStatus` (IN `inUserName` VARCHAR(255), IN `inPayStat` VARCHAR(45))  BEGIN

update users set PaymentStatus=inPayStat where username=inUserName;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `allfixturesandclubinfo`
--
CREATE TABLE `allfixturesandclubinfo` (
`FixtureId` int(11)
,`KickOffTime` datetime
,`HomeTeam` varchar(50)
,`AwayTeam` varchar(50)
,`ShortNameHome` varchar(8)
,`ShortNameAway` varchar(8)
,`MedNameHome` varchar(100)
,`MedNameAway` varchar(100)
,`HomeCrestImg` varchar(255)
,`AwayCrestImg` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `clubs`
--

CREATE TABLE `clubs` (
  `ClubId` int(11) NOT NULL,
  `LongName` varchar(100) NOT NULL,
  `MedName` varchar(100) NOT NULL,
  `ShortName` varchar(8) NOT NULL,
  `CrestURLSmall` varchar(255) NOT NULL,
  `CresURLLarge` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `clubs`
--

INSERT INTO `clubs` (`ClubId`, `LongName`, `MedName`, `ShortName`, `CrestURLSmall`, `CresURLLarge`) VALUES
(48, 'Man Utd', 'Man Utd', 'MNU', 'https://resources.premierleague.com/premierleague/badges/70/t1@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t1@x2.png'),
(49, 'Leicester', 'Leicester', 'LCY', 'https://resources.premierleague.com/premierleague/badges/70/t13@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t13@x2.png'),
(50, 'Liverpool', 'Liverpool', 'LIV', 'https://resources.premierleague.com/premierleague/badges/70/t14@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t14@x2.png'),
(51, 'West Ham', 'West Ham', 'WHU', 'https://resources.premierleague.com/premierleague/badges/70/t21@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t21@x2.png'),
(52, 'Chelsea', 'Chelsea', 'CHE', 'https://resources.premierleague.com/premierleague/badges/70/t8@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t8@x2.png'),
(53, 'Everton', 'Everton', 'EVR', 'https://resources.premierleague.com/premierleague/badges/70/t11@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t11@x2.png'),
(54, 'Aston Villa', 'Villa', 'AVA', 'https://resources.premierleague.com/premierleague/badges/70/t7@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t7@x2.png'),
(55, 'Spurs', 'Spurs', 'SPU', 'https://resources.premierleague.com/premierleague/badges/70/t6@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t6@x2.png'),
(56, 'Arsenal', 'Arsenal', 'ARS', 'https://resources.premierleague.com/premierleague/badges/70/t3@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t3@x2.png'),
(57, 'Leeds', 'Leeds', 'LED', 'https://resources.premierleague.com/premierleague/badges/70/t2@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t2@x2.png'),
(58, 'Southampton', 'Southampto', 'STH', 'https://resources.premierleague.com/premierleague/badges/70/t20@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t20@x2.png'),
(59, 'Crystal Palace', 'Crystal Pa', 'CPA', 'https://resources.premierleague.com/premierleague/badges/70/t31@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t31@x2.png'),
(60, 'Wolves', 'Wolves', 'WLV', 'https://resources.premierleague.com/premierleague/badges/70/t39@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t39@x2.png'),
(61, 'Brighton', 'BriHov Alb', 'BHA', 'https://resources.premierleague.com/premierleague/badges/70/t36@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t36@x2.png'),
(62, 'Newcastle', 'Newcastle', 'NCU', 'https://resources.premierleague.com/premierleague/badges/70/t4@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t4@x2.png'),
(63, 'Burnley', 'Burnley', 'BUR', 'https://resources.premierleague.com/premierleague/badges/70/t90@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t90@x2.png'),
(64, 'Fulham', 'Fulham', 'FUL', 'https://resources.premierleague.com/premierleague/badges/70/t54@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t54@x2.png'),
(65, 'West Brom', 'West Brom', 'WBA', 'https://resources.premierleague.com/premierleague/badges/70/t35@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t35@x2.png'),
(66, 'Sheffield Utd', 'Shefld Utd', 'SHE', 'https://resources.premierleague.com/premierleague/badges/70/t49@x2.png', 'https://resources.premierleague.com/premierleague/badges/70/t49@x2.png'),
(67, 'Man City', 'Man City', 'MCY', 'https://resources.premierleague.com/premierleague/badges/70/t43.png', 'https://resources.premierleague.com/premierleague/badges/70/t43.png'),
(68, 'Shamrock Rovers', 'Shamrock Rovers', 'SHA', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01SIFJ9DOC000000VUM100GLVTST5VQB/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01SIFJ9DOC000000VUM100GLVTST5VQB/verband/0123456789ABCDEF012345670IRL1010'),
(69, 'St. Patrick\'s Athletic', 'St. Patrick\'s Athletic', 'SPA', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGGKMO8000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGGKMO8000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010'),
(70, 'Finn Harps', 'Finn Harps', 'FH', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGFO9C4000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGFO9C4000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010'),
(71, 'Sligo Rovers', 'Sligo Rovers', 'SR', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGGBIO4000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGGBIO4000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010'),
(72, 'Drogheda United', 'Drogheda United', 'DU', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TGDKTNIG000000VUM100GLVUCCBM8E/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TGDKTNIG000000VUM100GLVUCCBM8E/verband/0123456789ABCDEF012345670IRL1010'),
(73, 'Derry City', 'Derry City', 'DC', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGEPQC4000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGEPQC4000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010'),
(74, 'Dundalk', 'Dundalk', 'DK', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGFGGLO000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGFGGLO000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010'),
(75, 'Longford Town', 'Longford Town', 'LT', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGG1M5K000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGG1M5K000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010'),
(76, 'Waterford', 'Waterford', '', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGHKPV0000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGHKPV0000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010'),
(77, 'Bohemians', 'Bohemians', '', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGE2P10000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010', 'https://fms.sseairtricityleague.ie/export.media/-/action/getLogo/id/01TUGE2P10000000VUM100GLVUSBBC1N/verband/0123456789ABCDEF012345670IRL1010'),
(78, 'Bournemouth', 'Bournemouth', 'BOU', 'https://ssl.gstatic.com/onebox/media/sports/logos/IcOt-hrK04B-RlRwI3R0yA_48x48.png', 'https://ssl.gstatic.com/onebox/media/sports/logos/IcOt-hrK04B-RlRwI3R0yA_96x96.png'),
(79, 'Brentford\r\n', 'Brentford\r\n', 'BRE', 'https://ssl.gstatic.com/onebox/media/sports/logos/QOUce0WQBYqnkSmN6_TxGA_48x48.png', 'https://ssl.gstatic.com/onebox/media/sports/logos/QOUce0WQBYqnkSmN6_TxGA_96x96.png'),
(80, 'Nottingham Forest', 'Nottm Forest', 'FOR', 'https://ssl.gstatic.com/onebox/media/sports/logos/Zr6FbE-8pDH7UBpWCO8U9A_48x48.png', 'https://ssl.gstatic.com/onebox/media/sports/logos/QOUce0WQBYqnkSmN6_TxGA_96x96.png');

-- --------------------------------------------------------

--
-- Stand-in structure for view `detailedpredictions`
--
CREATE TABLE `detailedpredictions` (
`FullName` varchar(45)
,`email` varchar(255)
,`KickOffTime` datetime
,`FixtureDetail` varchar(104)
,`User Selected` varchar(50)
,`DateTimeEntered` datetime
,`PredictionID` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `fixtureresults`
--

CREATE TABLE `fixtureresults` (
  `FixtureId` int(11) NOT NULL,
  `KickOffTime` datetime NOT NULL,
  `HomeTeam` varchar(50) NOT NULL,
  `AwayTeam` varchar(50) NOT NULL,
  `HomeTeamScore` int(11) DEFAULT NULL,
  `AwayTeamScore` int(11) DEFAULT NULL,
  `Result` smallint(6) DEFAULT NULL COMMENT '1=Home Win2=Draw3=Away Win'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Result (1=home win, 2=Draw, 3=away win)';

--
-- Dumping data for table `fixtureresults`
--

INSERT INTO `fixtureresults` (`FixtureId`, `KickOffTime`, `HomeTeam`, `AwayTeam`, `HomeTeamScore`, `AwayTeamScore`, `Result`) VALUES
(1335, '2022-08-05 19:00:00', 'Crystal Palace', 'Arsenal', NULL, NULL, NULL),
(1336, '2022-08-06 11:30:00', 'Fulham', 'Liverpool', NULL, NULL, NULL),
(1337, '2022-08-06 13:00:00', 'Leicester', 'Brentford', NULL, NULL, NULL),
(1338, '2022-08-06 14:00:00', 'Bournemouth', 'Aston Villa', NULL, NULL, NULL),
(1339, '2022-08-06 14:00:00', 'Leeds', 'Wolves', NULL, NULL, NULL),
(1340, '2022-08-06 14:00:00', 'Newcastle', 'Nottingham Forest', NULL, NULL, NULL),
(1341, '2022-08-06 14:00:00', 'Spurs', 'Southampton', NULL, NULL, NULL),
(1342, '2022-08-06 16:30:00', 'Everton', 'Chelsea', NULL, NULL, NULL),
(1343, '2022-08-07 13:00:00', 'Man Utd', 'Brighton', NULL, NULL, NULL),
(1344, '2022-08-07 15:30:00', 'West Ham', 'Man City', NULL, NULL, NULL),
(1345, '2022-08-13 11:30:00', 'Aston Villa', 'Everton', NULL, NULL, NULL),
(1346, '2022-08-13 14:00:00', 'Arsenal', 'Leicester', NULL, NULL, NULL),
(1347, '2022-08-13 14:00:00', 'Brighton', 'Newcastle', NULL, NULL, NULL),
(1348, '2022-08-13 14:00:00', 'Man City', 'Bournemouth', NULL, NULL, NULL),
(1349, '2022-08-13 14:00:00', 'Southampton', 'Leeds', NULL, NULL, NULL),
(1350, '2022-08-13 14:00:00', 'Wolves', 'Fulham', NULL, NULL, NULL),
(1351, '2022-08-13 16:30:00', 'Brentford', 'Man Utd', NULL, NULL, NULL),
(1352, '2022-08-14 13:00:00', 'Nottingham Forest', 'West Ham', NULL, NULL, NULL),
(1353, '2022-08-14 15:30:00', 'Chelsea', 'Spurs', NULL, NULL, NULL),
(1354, '2022-08-15 19:00:00', 'Liverpool', 'Crystal Palace', NULL, NULL, NULL),
(1355, '2022-08-20 11:30:00', 'Spurs', 'Wolves', NULL, NULL, NULL),
(1356, '2022-08-20 14:00:00', 'Crystal Palace', 'Aston Villa', NULL, NULL, NULL),
(1357, '2022-08-20 14:00:00', 'Everton', 'Nottingham Forest', NULL, NULL, NULL),
(1358, '2022-08-20 14:00:00', 'Fulham', 'Brentford', NULL, NULL, NULL),
(1359, '2022-08-20 14:00:00', 'Leicester', 'Southampton', NULL, NULL, NULL),
(1360, '2022-08-20 16:30:00', 'Bournemouth', 'Arsenal', NULL, NULL, NULL),
(1361, '2022-08-21 13:00:00', 'Leeds', 'Chelsea', NULL, NULL, NULL),
(1362, '2022-08-21 13:00:00', 'West Ham', 'Brighton', NULL, NULL, NULL),
(1363, '2022-08-21 15:30:00', 'Newcastle', 'Man City', NULL, NULL, NULL),
(1364, '2022-08-22 19:00:00', 'Man Utd', 'Liverpool', NULL, NULL, NULL),
(1365, '2022-08-27 11:30:00', 'Southampton', 'Man Utd', NULL, NULL, NULL),
(1366, '2022-08-27 14:00:00', 'Brentford', 'Everton', NULL, NULL, NULL),
(1367, '2022-08-27 14:00:00', 'Brighton', 'Leeds', NULL, NULL, NULL),
(1368, '2022-08-27 14:00:00', 'Chelsea', 'Leicester', NULL, NULL, NULL),
(1369, '2022-08-27 14:00:00', 'Liverpool', 'Bournemouth', NULL, NULL, NULL),
(1370, '2022-08-27 14:00:00', 'Man City', 'Crystal Palace', NULL, NULL, NULL),
(1371, '2022-08-27 16:30:00', 'Arsenal', 'Fulham', NULL, NULL, NULL),
(1372, '2022-08-28 13:00:00', 'Aston Villa', 'West Ham', NULL, NULL, NULL),
(1373, '2022-08-28 13:00:00', 'Wolves', 'Newcastle', NULL, NULL, NULL),
(1374, '2022-08-28 15:30:00', 'Nottingham Forest', 'Spurs', NULL, NULL, NULL),
(1375, '2022-08-30 18:30:00', 'Fulham', 'Brighton', NULL, NULL, NULL),
(1376, '2022-08-30 18:30:00', 'Crystal Palace', 'Brentford', NULL, NULL, NULL),
(1377, '2022-08-30 18:45:00', 'Southampton', 'Chelsea', NULL, NULL, NULL),
(1378, '2022-08-30 19:00:00', 'Leeds', 'Everton', NULL, NULL, NULL),
(1379, '2022-08-31 18:30:00', 'Bournemouth', 'Wolves', NULL, NULL, NULL),
(1380, '2022-08-31 18:30:00', 'Arsenal', 'Aston Villa', NULL, NULL, NULL),
(1381, '2022-08-31 18:30:00', 'Man City', 'Nottingham Forest', NULL, NULL, NULL),
(1382, '2022-08-31 18:45:00', 'West Ham', 'Spurs', NULL, NULL, NULL),
(1383, '2022-08-31 19:00:00', 'Liverpool', 'Newcastle', NULL, NULL, NULL),
(1384, '2022-09-01 19:00:00', 'Leicester', 'Man Utd', NULL, NULL, NULL),
(1385, '2022-09-03 11:30:00', 'Everton', 'Liverpool', NULL, NULL, NULL),
(1386, '2022-09-03 14:00:00', 'Brentford', 'Leeds', NULL, NULL, NULL),
(1387, '2022-09-03 14:00:00', 'Newcastle', 'Crystal Palace', NULL, NULL, NULL),
(1388, '2022-09-03 14:00:00', 'Nottingham Forest', 'Bournemouth', NULL, NULL, NULL),
(1389, '2022-09-03 14:00:00', 'Spurs', 'Fulham', NULL, NULL, NULL),
(1390, '2022-09-03 14:00:00', 'Wolves', 'Southampton', NULL, NULL, NULL),
(1391, '2022-09-03 16:30:00', 'Aston Villa', 'Man City', NULL, NULL, NULL),
(1392, '2022-09-04 13:00:00', 'Brighton', 'Leicester', NULL, NULL, NULL),
(1393, '2022-09-04 13:00:00', 'Chelsea', 'West Ham', NULL, NULL, NULL),
(1394, '2022-09-04 15:30:00', 'Man Utd', 'Arsenal', NULL, NULL, NULL),
(1395, '2022-09-10 11:30:00', 'Fulham', 'Chelsea', NULL, NULL, NULL),
(1396, '2022-09-10 14:00:00', 'Bournemouth', 'Brighton', NULL, NULL, NULL),
(1397, '2022-09-10 14:00:00', 'Leicester', 'Aston Villa', NULL, NULL, NULL),
(1398, '2022-09-10 14:00:00', 'Liverpool', 'Wolves', NULL, NULL, NULL),
(1399, '2022-09-10 14:00:00', 'Southampton', 'Brentford', NULL, NULL, NULL),
(1400, '2022-09-10 16:30:00', 'Man City', 'Spurs', NULL, NULL, NULL),
(1401, '2022-09-11 13:00:00', 'Arsenal', 'Everton', NULL, NULL, NULL),
(1402, '2022-09-11 13:00:00', 'West Ham', 'Newcastle', NULL, NULL, NULL),
(1403, '2022-09-11 15:30:00', 'Crystal Palace', 'Man Utd', NULL, NULL, NULL),
(1404, '2022-09-12 19:00:00', 'Leeds', 'Nottingham Forest', NULL, NULL, NULL),
(1405, '2022-09-16 19:00:00', 'Aston Villa', 'Southampton', NULL, NULL, NULL),
(1406, '2022-09-16 19:00:00', 'Nottingham Forest', 'Fulham', NULL, NULL, NULL),
(1407, '2022-09-17 11:30:00', 'Wolves', 'Man City', NULL, NULL, NULL),
(1408, '2022-09-17 14:00:00', 'Brighton', 'Crystal Palace', NULL, NULL, NULL),
(1409, '2022-09-17 14:00:00', 'Everton', 'West Ham', NULL, NULL, NULL),
(1410, '2022-09-17 14:00:00', 'Newcastle', 'Bournemouth', NULL, NULL, NULL),
(1411, '2022-09-17 16:30:00', 'Spurs', 'Leicester', NULL, NULL, NULL),
(1412, '2022-09-18 13:00:00', 'Brentford', 'Arsenal', NULL, NULL, NULL),
(1413, '2022-09-18 13:00:00', 'Man Utd', 'Leeds', NULL, NULL, NULL),
(1414, '2022-09-18 15:30:00', 'Chelsea', 'Liverpool', NULL, NULL, NULL),
(1415, '2022-10-01 14:00:00', 'Bournemouth', 'Brentford', NULL, NULL, NULL),
(1416, '2022-10-01 14:00:00', 'Arsenal', 'Spurs', NULL, NULL, NULL),
(1417, '2022-10-01 14:00:00', 'Crystal Palace', 'Chelsea', NULL, NULL, NULL),
(1418, '2022-10-01 14:00:00', 'Fulham', 'Newcastle', NULL, NULL, NULL),
(1419, '2022-10-01 14:00:00', 'Leeds', 'Aston Villa', NULL, NULL, NULL),
(1420, '2022-10-01 14:00:00', 'Leicester', 'Nottingham Forest', NULL, NULL, NULL),
(1421, '2022-10-01 14:00:00', 'Liverpool', 'Brighton', NULL, NULL, NULL),
(1422, '2022-10-01 14:00:00', 'Man City', 'Man Utd', NULL, NULL, NULL),
(1423, '2022-10-01 14:00:00', 'Southampton', 'Everton', NULL, NULL, NULL),
(1424, '2022-10-01 14:00:00', 'West Ham', 'Wolves', NULL, NULL, NULL),
(1425, '2022-10-08 14:00:00', 'Bournemouth', 'Leicester', NULL, NULL, NULL),
(1426, '2022-10-08 14:00:00', 'Arsenal', 'Liverpool', NULL, NULL, NULL),
(1427, '2022-10-08 14:00:00', 'Brighton', 'Spurs', NULL, NULL, NULL),
(1428, '2022-10-08 14:00:00', 'Chelsea', 'Wolves', NULL, NULL, NULL),
(1429, '2022-10-08 14:00:00', 'Crystal Palace', 'Leeds', NULL, NULL, NULL),
(1430, '2022-10-08 14:00:00', 'Everton', 'Man Utd', NULL, NULL, NULL),
(1431, '2022-10-08 14:00:00', 'Man City', 'Southampton', NULL, NULL, NULL),
(1432, '2022-10-08 14:00:00', 'Newcastle', 'Brentford', NULL, NULL, NULL),
(1433, '2022-10-08 14:00:00', 'Nottingham Forest', 'Aston Villa', NULL, NULL, NULL),
(1434, '2022-10-08 14:00:00', 'West Ham', 'Fulham', NULL, NULL, NULL),
(1435, '2022-10-15 14:00:00', 'Aston Villa', 'Chelsea', NULL, NULL, NULL),
(1436, '2022-10-15 14:00:00', 'Brentford', 'Brighton', NULL, NULL, NULL),
(1437, '2022-10-15 14:00:00', 'Fulham', 'Bournemouth', NULL, NULL, NULL),
(1438, '2022-10-15 14:00:00', 'Leeds', 'Arsenal', NULL, NULL, NULL),
(1439, '2022-10-15 14:00:00', 'Leicester', 'Crystal Palace', NULL, NULL, NULL),
(1440, '2022-10-15 14:00:00', 'Liverpool', 'Man City', NULL, NULL, NULL),
(1441, '2022-10-15 14:00:00', 'Man Utd', 'Newcastle', NULL, NULL, NULL),
(1442, '2022-10-15 14:00:00', 'Southampton', 'West Ham', NULL, NULL, NULL),
(1443, '2022-10-15 14:00:00', 'Spurs', 'Everton', NULL, NULL, NULL),
(1444, '2022-10-15 14:00:00', 'Wolves', 'Nottingham Forest', NULL, NULL, NULL),
(1445, '2022-10-18 18:45:00', 'Bournemouth', 'Southampton', NULL, NULL, NULL),
(1446, '2022-10-18 18:45:00', 'Arsenal', 'Man City', NULL, NULL, NULL),
(1447, '2022-10-18 18:45:00', 'Brentford', 'Chelsea', NULL, NULL, NULL),
(1448, '2022-10-18 18:45:00', 'Brighton', 'Nottingham Forest', NULL, NULL, NULL),
(1449, '2022-10-18 18:45:00', 'Fulham', 'Aston Villa', NULL, NULL, NULL),
(1450, '2022-10-18 18:45:00', 'Leicester', 'Leeds', NULL, NULL, NULL),
(1451, '2022-10-18 19:00:00', 'Crystal Palace', 'Wolves', NULL, NULL, NULL),
(1452, '2022-10-19 18:45:00', 'Newcastle', 'Everton', NULL, NULL, NULL),
(1453, '2022-10-19 19:00:00', 'Liverpool', 'West Ham', NULL, NULL, NULL),
(1454, '2022-10-19 19:00:00', 'Man Utd', 'Spurs', NULL, NULL, NULL),
(1455, '2022-10-22 14:00:00', 'Aston Villa', 'Brentford', NULL, NULL, NULL),
(1456, '2022-10-22 14:00:00', 'Chelsea', 'Man Utd', NULL, NULL, NULL),
(1457, '2022-10-22 14:00:00', 'Everton', 'Crystal Palace', NULL, NULL, NULL),
(1458, '2022-10-22 14:00:00', 'Leeds', 'Fulham', NULL, NULL, NULL),
(1459, '2022-10-22 14:00:00', 'Man City', 'Brighton', NULL, NULL, NULL),
(1460, '2022-10-22 14:00:00', 'Nottingham Forest', 'Liverpool', NULL, NULL, NULL),
(1461, '2022-10-22 14:00:00', 'Southampton', 'Arsenal', NULL, NULL, NULL),
(1462, '2022-10-22 14:00:00', 'Spurs', 'Newcastle', NULL, NULL, NULL),
(1463, '2022-10-22 14:00:00', 'West Ham', 'Bournemouth', NULL, NULL, NULL),
(1464, '2022-10-22 14:00:00', 'Wolves', 'Leicester', NULL, NULL, NULL),
(1465, '2022-10-29 14:00:00', 'Bournemouth', 'Spurs', NULL, NULL, NULL),
(1466, '2022-10-29 14:00:00', 'Arsenal', 'Nottingham Forest', NULL, NULL, NULL),
(1467, '2022-10-29 14:00:00', 'Brentford', 'Wolves', NULL, NULL, NULL),
(1468, '2022-10-29 14:00:00', 'Brighton', 'Chelsea', NULL, NULL, NULL),
(1469, '2022-10-29 14:00:00', 'Crystal Palace', 'Southampton', NULL, NULL, NULL),
(1470, '2022-10-29 14:00:00', 'Fulham', 'Everton', NULL, NULL, NULL),
(1471, '2022-10-29 14:00:00', 'Leicester', 'Man City', NULL, NULL, NULL),
(1472, '2022-10-29 14:00:00', 'Liverpool', 'Leeds', NULL, NULL, NULL),
(1473, '2022-10-29 14:00:00', 'Man Utd', 'West Ham', NULL, NULL, NULL),
(1474, '2022-10-29 14:00:00', 'Newcastle', 'Aston Villa', NULL, NULL, NULL),
(1475, '2022-11-05 15:00:00', 'Aston Villa', 'Man Utd', NULL, NULL, NULL),
(1476, '2022-11-05 15:00:00', 'Chelsea', 'Arsenal', NULL, NULL, NULL),
(1477, '2022-11-05 15:00:00', 'Everton', 'Leicester', NULL, NULL, NULL),
(1478, '2022-11-05 15:00:00', 'Leeds', 'Bournemouth', NULL, NULL, NULL),
(1479, '2022-11-05 15:00:00', 'Man City', 'Fulham', NULL, NULL, NULL),
(1480, '2022-11-05 15:00:00', 'Nottingham Forest', 'Brentford', NULL, NULL, NULL),
(1481, '2022-11-05 15:00:00', 'Southampton', 'Newcastle', NULL, NULL, NULL),
(1482, '2022-11-05 15:00:00', 'Spurs', 'Liverpool', NULL, NULL, NULL),
(1483, '2022-11-05 15:00:00', 'West Ham', 'Crystal Palace', NULL, NULL, NULL),
(1484, '2022-11-05 15:00:00', 'Wolves', 'Brighton', NULL, NULL, NULL),
(1485, '2022-11-12 15:00:00', 'Bournemouth', 'Everton', NULL, NULL, NULL),
(1486, '2022-11-12 15:00:00', 'Brighton', 'Aston Villa', NULL, NULL, NULL),
(1487, '2022-11-12 15:00:00', 'Fulham', 'Man Utd', NULL, NULL, NULL),
(1488, '2022-11-12 15:00:00', 'Liverpool', 'Southampton', NULL, NULL, NULL),
(1489, '2022-11-12 15:00:00', 'Man City', 'Brentford', NULL, NULL, NULL),
(1490, '2022-11-12 15:00:00', 'Newcastle', 'Chelsea', NULL, NULL, NULL),
(1491, '2022-11-12 15:00:00', 'Nottingham Forest', 'Crystal Palace', NULL, NULL, NULL),
(1492, '2022-11-12 15:00:00', 'Spurs', 'Leeds', NULL, NULL, NULL),
(1493, '2022-11-12 15:00:00', 'West Ham', 'Leicester', NULL, NULL, NULL),
(1494, '2022-11-12 15:00:00', 'Wolves', 'Arsenal', NULL, NULL, NULL),
(1495, '2022-12-26 15:00:00', 'Arsenal', 'West Ham', NULL, NULL, NULL),
(1496, '2022-12-26 15:00:00', 'Aston Villa', 'Liverpool', NULL, NULL, NULL),
(1497, '2022-12-26 15:00:00', 'Brentford', 'Spurs', NULL, NULL, NULL),
(1498, '2022-12-26 15:00:00', 'Chelsea', 'Bournemouth', NULL, NULL, NULL),
(1499, '2022-12-26 15:00:00', 'Crystal Palace', 'Fulham', NULL, NULL, NULL),
(1500, '2022-12-26 15:00:00', 'Everton', 'Wolves', NULL, NULL, NULL),
(1501, '2022-12-26 15:00:00', 'Leeds', 'Man City', NULL, NULL, NULL),
(1502, '2022-12-26 15:00:00', 'Leicester', 'Newcastle', NULL, NULL, NULL),
(1503, '2022-12-26 15:00:00', 'Man Utd', 'Nottingham Forest', NULL, NULL, NULL),
(1504, '2022-12-26 15:00:00', 'Southampton', 'Brighton', NULL, NULL, NULL),
(1505, '2022-12-31 15:00:00', 'Bournemouth', 'Crystal Palace', NULL, NULL, NULL),
(1506, '2022-12-31 15:00:00', 'Brighton', 'Arsenal', NULL, NULL, NULL),
(1507, '2022-12-31 15:00:00', 'Fulham', 'Southampton', NULL, NULL, NULL),
(1508, '2022-12-31 15:00:00', 'Liverpool', 'Leicester', NULL, NULL, NULL),
(1509, '2022-12-31 15:00:00', 'Man City', 'Everton', NULL, NULL, NULL),
(1510, '2022-12-31 15:00:00', 'Newcastle', 'Leeds', NULL, NULL, NULL),
(1511, '2022-12-31 15:00:00', 'Nottingham Forest', 'Chelsea', NULL, NULL, NULL),
(1512, '2022-12-31 15:00:00', 'Spurs', 'Aston Villa', NULL, NULL, NULL),
(1513, '2022-12-31 15:00:00', 'West Ham', 'Brentford', NULL, NULL, NULL),
(1514, '2022-12-31 15:00:00', 'Wolves', 'Man Utd', NULL, NULL, NULL),
(1515, '2023-01-02 15:00:00', 'Arsenal', 'Newcastle', NULL, NULL, NULL),
(1516, '2023-01-02 15:00:00', 'Aston Villa', 'Wolves', NULL, NULL, NULL),
(1517, '2023-01-02 15:00:00', 'Brentford', 'Liverpool', NULL, NULL, NULL),
(1518, '2023-01-02 15:00:00', 'Chelsea', 'Man City', NULL, NULL, NULL),
(1519, '2023-01-02 15:00:00', 'Crystal Palace', 'Spurs', NULL, NULL, NULL),
(1520, '2023-01-02 15:00:00', 'Everton', 'Brighton', NULL, NULL, NULL),
(1521, '2023-01-02 15:00:00', 'Leeds', 'West Ham', NULL, NULL, NULL),
(1522, '2023-01-02 15:00:00', 'Leicester', 'Fulham', NULL, NULL, NULL),
(1523, '2023-01-02 15:00:00', 'Man Utd', 'Bournemouth', NULL, NULL, NULL),
(1524, '2023-01-02 15:00:00', 'Southampton', 'Nottingham Forest', NULL, NULL, NULL),
(1525, '2023-01-14 15:00:00', 'Aston Villa', 'Leeds', NULL, NULL, NULL),
(1526, '2023-01-14 15:00:00', 'Brentford', 'Bournemouth', NULL, NULL, NULL),
(1527, '2023-01-14 15:00:00', 'Brighton', 'Liverpool', NULL, NULL, NULL),
(1528, '2023-01-14 15:00:00', 'Chelsea', 'Crystal Palace', NULL, NULL, NULL),
(1529, '2023-01-14 15:00:00', 'Everton', 'Southampton', NULL, NULL, NULL),
(1530, '2023-01-14 15:00:00', 'Man Utd', 'Man City', NULL, NULL, NULL),
(1531, '2023-01-14 15:00:00', 'Newcastle', 'Fulham', NULL, NULL, NULL),
(1532, '2023-01-14 15:00:00', 'Nottingham Forest', 'Leicester', NULL, NULL, NULL),
(1533, '2023-01-14 15:00:00', 'Spurs', 'Arsenal', NULL, NULL, NULL),
(1534, '2023-01-14 15:00:00', 'Wolves', 'West Ham', NULL, NULL, NULL),
(1535, '2023-01-21 15:00:00', 'Bournemouth', 'Nottingham Forest', NULL, NULL, NULL),
(1536, '2023-01-21 15:00:00', 'Arsenal', 'Man Utd', NULL, NULL, NULL),
(1537, '2023-01-21 15:00:00', 'Crystal Palace', 'Newcastle', NULL, NULL, NULL),
(1538, '2023-01-21 15:00:00', 'Fulham', 'Spurs', NULL, NULL, NULL),
(1539, '2023-01-21 15:00:00', 'Leeds', 'Brentford', NULL, NULL, NULL),
(1540, '2023-01-21 15:00:00', 'Leicester', 'Brighton', NULL, NULL, NULL),
(1541, '2023-01-21 15:00:00', 'Liverpool', 'Chelsea', NULL, NULL, NULL),
(1542, '2023-01-21 15:00:00', 'Man City', 'Wolves', NULL, NULL, NULL),
(1543, '2023-01-21 15:00:00', 'Southampton', 'Aston Villa', NULL, NULL, NULL),
(1544, '2023-01-21 15:00:00', 'West Ham', 'Everton', NULL, NULL, NULL),
(1545, '2023-02-04 15:00:00', 'Aston Villa', 'Leicester', NULL, NULL, NULL),
(1546, '2023-02-04 15:00:00', 'Brentford', 'Southampton', NULL, NULL, NULL),
(1547, '2023-02-04 15:00:00', 'Brighton', 'Bournemouth', NULL, NULL, NULL),
(1548, '2023-02-04 15:00:00', 'Chelsea', 'Fulham', NULL, NULL, NULL),
(1549, '2023-02-04 15:00:00', 'Everton', 'Arsenal', NULL, NULL, NULL),
(1550, '2023-02-04 15:00:00', 'Man Utd', 'Crystal Palace', NULL, NULL, NULL),
(1551, '2023-02-04 15:00:00', 'Newcastle', 'West Ham', NULL, NULL, NULL),
(1552, '2023-02-04 15:00:00', 'Nottingham Forest', 'Leeds', NULL, NULL, NULL),
(1553, '2023-02-04 15:00:00', 'Spurs', 'Man City', NULL, NULL, NULL),
(1554, '2023-02-04 15:00:00', 'Wolves', 'Liverpool', NULL, NULL, NULL),
(1555, '2023-02-11 15:00:00', 'Bournemouth', 'Newcastle', NULL, NULL, NULL),
(1556, '2023-02-11 15:00:00', 'Arsenal', 'Brentford', NULL, NULL, NULL),
(1557, '2023-02-11 15:00:00', 'Crystal Palace', 'Brighton', NULL, NULL, NULL),
(1558, '2023-02-11 15:00:00', 'Fulham', 'Nottingham Forest', NULL, NULL, NULL),
(1559, '2023-02-11 15:00:00', 'Leeds', 'Man Utd', NULL, NULL, NULL),
(1560, '2023-02-11 15:00:00', 'Leicester', 'Spurs', NULL, NULL, NULL),
(1561, '2023-02-11 15:00:00', 'Liverpool', 'Everton', NULL, NULL, NULL),
(1562, '2023-02-11 15:00:00', 'Man City', 'Aston Villa', NULL, NULL, NULL),
(1563, '2023-02-11 15:00:00', 'Southampton', 'Wolves', NULL, NULL, NULL),
(1564, '2023-02-11 15:00:00', 'West Ham', 'Chelsea', NULL, NULL, NULL),
(1565, '2023-02-18 15:00:00', 'Aston Villa', 'Arsenal', NULL, NULL, NULL),
(1566, '2023-02-18 15:00:00', 'Brentford', 'Crystal Palace', NULL, NULL, NULL),
(1567, '2023-02-18 15:00:00', 'Brighton', 'Fulham', NULL, NULL, NULL),
(1568, '2023-02-18 15:00:00', 'Chelsea', 'Southampton', NULL, NULL, NULL),
(1569, '2023-02-18 15:00:00', 'Everton', 'Leeds', NULL, NULL, NULL),
(1570, '2023-02-18 15:00:00', 'Man Utd', 'Leicester', NULL, NULL, NULL),
(1571, '2023-02-18 15:00:00', 'Newcastle', 'Liverpool', NULL, NULL, NULL),
(1572, '2023-02-18 15:00:00', 'Nottingham Forest', 'Man City', NULL, NULL, NULL),
(1573, '2023-02-18 15:00:00', 'Spurs', 'West Ham', NULL, NULL, NULL),
(1574, '2023-02-18 15:00:00', 'Wolves', 'Bournemouth', NULL, NULL, NULL),
(1575, '2023-02-25 15:00:00', 'Bournemouth', 'Man City', NULL, NULL, NULL),
(1576, '2023-02-25 15:00:00', 'Crystal Palace', 'Liverpool', NULL, NULL, NULL),
(1577, '2023-02-25 15:00:00', 'Everton', 'Aston Villa', NULL, NULL, NULL),
(1578, '2023-02-25 15:00:00', 'Fulham', 'Wolves', NULL, NULL, NULL),
(1579, '2023-02-25 15:00:00', 'Leeds', 'Southampton', NULL, NULL, NULL),
(1580, '2023-02-25 15:00:00', 'Leicester', 'Arsenal', NULL, NULL, NULL),
(1581, '2023-02-25 15:00:00', 'Man Utd', 'Brentford', NULL, NULL, NULL),
(1582, '2023-02-25 15:00:00', 'Newcastle', 'Brighton', NULL, NULL, NULL),
(1583, '2023-02-25 15:00:00', 'Spurs', 'Chelsea', NULL, NULL, NULL),
(1584, '2023-02-25 15:00:00', 'West Ham', 'Nottingham Forest', NULL, NULL, NULL),
(1585, '2023-03-04 15:00:00', 'Arsenal', 'Bournemouth', NULL, NULL, NULL),
(1586, '2023-03-04 15:00:00', 'Aston Villa', 'Crystal Palace', NULL, NULL, NULL),
(1587, '2023-03-04 15:00:00', 'Brentford', 'Fulham', NULL, NULL, NULL),
(1588, '2023-03-04 15:00:00', 'Brighton', 'West Ham', NULL, NULL, NULL),
(1589, '2023-03-04 15:00:00', 'Chelsea', 'Leeds', NULL, NULL, NULL),
(1590, '2023-03-04 15:00:00', 'Liverpool', 'Man Utd', NULL, NULL, NULL),
(1591, '2023-03-04 15:00:00', 'Man City', 'Newcastle', NULL, NULL, NULL),
(1592, '2023-03-04 15:00:00', 'Nottingham Forest', 'Everton', NULL, NULL, NULL),
(1593, '2023-03-04 15:00:00', 'Southampton', 'Leicester', NULL, NULL, NULL),
(1594, '2023-03-04 15:00:00', 'Wolves', 'Spurs', NULL, NULL, NULL),
(1595, '2023-03-11 15:00:00', 'Bournemouth', 'Liverpool', NULL, NULL, NULL),
(1596, '2023-03-11 15:00:00', 'Crystal Palace', 'Man City', NULL, NULL, NULL),
(1597, '2023-03-11 15:00:00', 'Everton', 'Brentford', NULL, NULL, NULL),
(1598, '2023-03-11 15:00:00', 'Fulham', 'Arsenal', NULL, NULL, NULL),
(1599, '2023-03-11 15:00:00', 'Leeds', 'Brighton', NULL, NULL, NULL),
(1600, '2023-03-11 15:00:00', 'Leicester', 'Chelsea', NULL, NULL, NULL),
(1601, '2023-03-11 15:00:00', 'Man Utd', 'Southampton', NULL, NULL, NULL),
(1602, '2023-03-11 15:00:00', 'Newcastle', 'Wolves', NULL, NULL, NULL),
(1603, '2023-03-11 15:00:00', 'Spurs', 'Nottingham Forest', NULL, NULL, NULL),
(1604, '2023-03-11 15:00:00', 'West Ham', 'Aston Villa', NULL, NULL, NULL),
(1605, '2023-03-18 15:00:00', 'Arsenal', 'Crystal Palace', NULL, NULL, NULL),
(1606, '2023-03-18 15:00:00', 'Aston Villa', 'Bournemouth', NULL, NULL, NULL),
(1607, '2023-03-18 15:00:00', 'Brentford', 'Leicester', NULL, NULL, NULL),
(1608, '2023-03-18 15:00:00', 'Brighton', 'Man Utd', NULL, NULL, NULL),
(1609, '2023-03-18 15:00:00', 'Chelsea', 'Everton', NULL, NULL, NULL),
(1610, '2023-03-18 15:00:00', 'Liverpool', 'Fulham', NULL, NULL, NULL),
(1611, '2023-03-18 15:00:00', 'Man City', 'West Ham', NULL, NULL, NULL),
(1612, '2023-03-18 15:00:00', 'Nottingham Forest', 'Newcastle', NULL, NULL, NULL),
(1613, '2023-03-18 15:00:00', 'Southampton', 'Spurs', NULL, NULL, NULL),
(1614, '2023-03-18 15:00:00', 'Wolves', 'Leeds', NULL, NULL, NULL),
(1615, '2023-04-01 14:00:00', 'Bournemouth', 'Fulham', NULL, NULL, NULL),
(1616, '2023-04-01 14:00:00', 'Arsenal', 'Leeds', NULL, NULL, NULL),
(1617, '2023-04-01 14:00:00', 'Brighton', 'Brentford', NULL, NULL, NULL),
(1618, '2023-04-01 14:00:00', 'Chelsea', 'Aston Villa', NULL, NULL, NULL),
(1619, '2023-04-01 14:00:00', 'Crystal Palace', 'Leicester', NULL, NULL, NULL),
(1620, '2023-04-01 14:00:00', 'Everton', 'Spurs', NULL, NULL, NULL),
(1621, '2023-04-01 14:00:00', 'Man City', 'Liverpool', NULL, NULL, NULL),
(1622, '2023-04-01 14:00:00', 'Newcastle', 'Man Utd', NULL, NULL, NULL),
(1623, '2023-04-01 14:00:00', 'Nottingham Forest', 'Wolves', NULL, NULL, NULL),
(1624, '2023-04-01 14:00:00', 'West Ham', 'Southampton', NULL, NULL, NULL),
(1625, '2023-04-08 14:00:00', 'Aston Villa', 'Nottingham Forest', NULL, NULL, NULL),
(1626, '2023-04-08 14:00:00', 'Brentford', 'Newcastle', NULL, NULL, NULL),
(1627, '2023-04-08 14:00:00', 'Fulham', 'West Ham', NULL, NULL, NULL),
(1628, '2023-04-08 14:00:00', 'Leeds', 'Crystal Palace', NULL, NULL, NULL),
(1629, '2023-04-08 14:00:00', 'Leicester', 'Bournemouth', NULL, NULL, NULL),
(1630, '2023-04-08 14:00:00', 'Liverpool', 'Arsenal', NULL, NULL, NULL),
(1631, '2023-04-08 14:00:00', 'Man Utd', 'Everton', NULL, NULL, NULL),
(1632, '2023-04-08 14:00:00', 'Southampton', 'Man City', NULL, NULL, NULL),
(1633, '2023-04-08 14:00:00', 'Spurs', 'Brighton', NULL, NULL, NULL),
(1634, '2023-04-08 14:00:00', 'Wolves', 'Chelsea', NULL, NULL, NULL),
(1635, '2023-04-15 14:00:00', 'Aston Villa', 'Newcastle', NULL, NULL, NULL),
(1636, '2023-04-15 14:00:00', 'Chelsea', 'Brighton', NULL, NULL, NULL),
(1637, '2023-04-15 14:00:00', 'Everton', 'Fulham', NULL, NULL, NULL),
(1638, '2023-04-15 14:00:00', 'Leeds', 'Liverpool', NULL, NULL, NULL),
(1639, '2023-04-15 14:00:00', 'Man City', 'Leicester', NULL, NULL, NULL),
(1640, '2023-04-15 14:00:00', 'Nottingham Forest', 'Man Utd', NULL, NULL, NULL),
(1641, '2023-04-15 14:00:00', 'Southampton', 'Crystal Palace', NULL, NULL, NULL),
(1642, '2023-04-15 14:00:00', 'Spurs', 'Bournemouth', NULL, NULL, NULL),
(1643, '2023-04-15 14:00:00', 'West Ham', 'Arsenal', NULL, NULL, NULL),
(1644, '2023-04-15 14:00:00', 'Wolves', 'Brentford', NULL, NULL, NULL),
(1645, '2023-04-22 14:00:00', 'Bournemouth', 'West Ham', NULL, NULL, NULL),
(1646, '2023-04-22 14:00:00', 'Arsenal', 'Southampton', NULL, NULL, NULL),
(1647, '2023-04-22 14:00:00', 'Brentford', 'Aston Villa', NULL, NULL, NULL),
(1648, '2023-04-22 14:00:00', 'Brighton', 'Man City', NULL, NULL, NULL),
(1649, '2023-04-22 14:00:00', 'Crystal Palace', 'Everton', NULL, NULL, NULL),
(1650, '2023-04-22 14:00:00', 'Fulham', 'Leeds', NULL, NULL, NULL),
(1651, '2023-04-22 14:00:00', 'Leicester', 'Wolves', NULL, NULL, NULL),
(1652, '2023-04-22 14:00:00', 'Liverpool', 'Nottingham Forest', NULL, NULL, NULL),
(1653, '2023-04-22 14:00:00', 'Man Utd', 'Chelsea', NULL, NULL, NULL),
(1654, '2023-04-22 14:00:00', 'Newcastle', 'Spurs', NULL, NULL, NULL),
(1655, '2023-04-25 18:45:00', 'Everton', 'Newcastle', NULL, NULL, NULL),
(1656, '2023-04-25 18:45:00', 'Leeds', 'Leicester', NULL, NULL, NULL),
(1657, '2023-04-25 18:45:00', 'Nottingham Forest', 'Brighton', NULL, NULL, NULL),
(1658, '2023-04-25 18:45:00', 'Spurs', 'Man Utd', NULL, NULL, NULL),
(1659, '2023-04-25 18:45:00', 'West Ham', 'Liverpool', NULL, NULL, NULL),
(1660, '2023-04-25 18:45:00', 'Wolves', 'Crystal Palace', NULL, NULL, NULL),
(1661, '2023-04-25 19:00:00', 'Aston Villa', 'Fulham', NULL, NULL, NULL),
(1662, '2023-04-26 18:45:00', 'Chelsea', 'Brentford', NULL, NULL, NULL),
(1663, '2023-04-26 18:45:00', 'Southampton', 'Bournemouth', NULL, NULL, NULL),
(1664, '2023-04-26 19:00:00', 'Man City', 'Arsenal', NULL, NULL, NULL),
(1665, '2023-04-29 14:00:00', 'Bournemouth', 'Leeds', NULL, NULL, NULL),
(1666, '2023-04-29 14:00:00', 'Arsenal', 'Chelsea', NULL, NULL, NULL),
(1667, '2023-04-29 14:00:00', 'Brentford', 'Nottingham Forest', NULL, NULL, NULL),
(1668, '2023-04-29 14:00:00', 'Brighton', 'Wolves', NULL, NULL, NULL),
(1669, '2023-04-29 14:00:00', 'Crystal Palace', 'West Ham', NULL, NULL, NULL),
(1670, '2023-04-29 14:00:00', 'Fulham', 'Man City', NULL, NULL, NULL),
(1671, '2023-04-29 14:00:00', 'Leicester', 'Everton', NULL, NULL, NULL),
(1672, '2023-04-29 14:00:00', 'Liverpool', 'Spurs', NULL, NULL, NULL),
(1673, '2023-04-29 14:00:00', 'Man Utd', 'Aston Villa', NULL, NULL, NULL),
(1674, '2023-04-29 14:00:00', 'Newcastle', 'Southampton', NULL, NULL, NULL),
(1675, '2023-05-06 14:00:00', 'Bournemouth', 'Chelsea', NULL, NULL, NULL),
(1676, '2023-05-06 14:00:00', 'Brighton', 'Everton', NULL, NULL, NULL),
(1677, '2023-05-06 14:00:00', 'Fulham', 'Leicester', NULL, NULL, NULL),
(1678, '2023-05-06 14:00:00', 'Liverpool', 'Brentford', NULL, NULL, NULL),
(1679, '2023-05-06 14:00:00', 'Man City', 'Leeds', NULL, NULL, NULL),
(1680, '2023-05-06 14:00:00', 'Newcastle', 'Arsenal', NULL, NULL, NULL),
(1681, '2023-05-06 14:00:00', 'Nottingham Forest', 'Southampton', NULL, NULL, NULL),
(1682, '2023-05-06 14:00:00', 'Spurs', 'Crystal Palace', NULL, NULL, NULL),
(1683, '2023-05-06 14:00:00', 'West Ham', 'Man Utd', NULL, NULL, NULL),
(1684, '2023-05-06 14:00:00', 'Wolves', 'Aston Villa', NULL, NULL, NULL),
(1685, '2023-05-13 14:00:00', 'Arsenal', 'Brighton', NULL, NULL, NULL),
(1686, '2023-05-13 14:00:00', 'Aston Villa', 'Spurs', NULL, NULL, NULL),
(1687, '2023-05-13 14:00:00', 'Brentford', 'West Ham', NULL, NULL, NULL),
(1688, '2023-05-13 14:00:00', 'Chelsea', 'Nottingham Forest', NULL, NULL, NULL),
(1689, '2023-05-13 14:00:00', 'Crystal Palace', 'Bournemouth', NULL, NULL, NULL),
(1690, '2023-05-13 14:00:00', 'Everton', 'Man City', NULL, NULL, NULL),
(1691, '2023-05-13 14:00:00', 'Leeds', 'Newcastle', NULL, NULL, NULL),
(1692, '2023-05-13 14:00:00', 'Leicester', 'Liverpool', NULL, NULL, NULL),
(1693, '2023-05-13 14:00:00', 'Man Utd', 'Wolves', NULL, NULL, NULL),
(1694, '2023-05-13 14:00:00', 'Southampton', 'Fulham', NULL, NULL, NULL),
(1695, '2023-05-20 14:00:00', 'Bournemouth', 'Man Utd', NULL, NULL, NULL),
(1696, '2023-05-20 14:00:00', 'Brighton', 'Southampton', NULL, NULL, NULL),
(1697, '2023-05-20 14:00:00', 'Fulham', 'Crystal Palace', NULL, NULL, NULL),
(1698, '2023-05-20 14:00:00', 'Liverpool', 'Aston Villa', NULL, NULL, NULL),
(1699, '2023-05-20 14:00:00', 'Man City', 'Chelsea', NULL, NULL, NULL),
(1700, '2023-05-20 14:00:00', 'Newcastle', 'Leicester', NULL, NULL, NULL),
(1701, '2023-05-20 14:00:00', 'Nottingham Forest', 'Arsenal', NULL, NULL, NULL),
(1702, '2023-05-20 14:00:00', 'Spurs', 'Brentford', NULL, NULL, NULL),
(1703, '2023-05-20 14:00:00', 'West Ham', 'Leeds', NULL, NULL, NULL),
(1704, '2023-05-20 14:00:00', 'Wolves', 'Everton', NULL, NULL, NULL),
(1705, '2023-05-28 15:00:00', 'Arsenal', 'Wolves', NULL, NULL, NULL),
(1706, '2023-05-28 15:00:00', 'Aston Villa', 'Brighton', NULL, NULL, NULL),
(1707, '2023-05-28 15:00:00', 'Brentford', 'Man City', NULL, NULL, NULL),
(1708, '2023-05-28 15:00:00', 'Chelsea', 'Newcastle', NULL, NULL, NULL),
(1709, '2023-05-28 15:00:00', 'Crystal Palace', 'Nottingham Forest', NULL, NULL, NULL),
(1710, '2023-05-28 15:00:00', 'Everton', 'Bournemouth', NULL, NULL, NULL),
(1711, '2023-05-28 15:00:00', 'Leeds', 'Spurs', NULL, NULL, NULL),
(1712, '2023-05-28 15:00:00', 'Leicester', 'West Ham', NULL, NULL, NULL),
(1713, '2023-05-28 15:00:00', 'Man Utd', 'Fulham', NULL, NULL, NULL),
(1714, '2023-05-28 15:00:00', 'Southampton', 'Liverpool', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `fixtureresults_archive`
--

CREATE TABLE `fixtureresults_archive` (
  `FixtureId` int(11) NOT NULL DEFAULT '0',
  `KickOffTime` datetime NOT NULL,
  `HomeTeam` varchar(50) CHARACTER SET latin1 NOT NULL,
  `AwayTeam` varchar(50) CHARACTER SET latin1 NOT NULL,
  `HomeTeamScore` int(11) DEFAULT NULL,
  `AwayTeamScore` int(11) DEFAULT NULL,
  `Result` smallint(6) DEFAULT NULL COMMENT '1=Home Win2=Draw3=Away Win'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `fixtureresults_archive`
--

INSERT INTO `fixtureresults_archive` (`FixtureId`, `KickOffTime`, `HomeTeam`, `AwayTeam`, `HomeTeamScore`, `AwayTeamScore`, `Result`) VALUES
(75, '2014-09-27 17:30:00', 'Arsenal', 'Tottenham Hotspur', 1, 1, 2),
(76, '2014-09-27 15:00:00', 'Chelsea', 'Aston Villa', 3, 0, 1),
(77, '2014-09-27 15:00:00', 'Crystal Palace', 'Leicester City', 2, 0, 1),
(78, '2014-09-27 15:00:00', 'Hull City', 'Manchester City', 2, 4, 3),
(79, '2014-09-27 12:45:00', 'Liverpool', 'Everton', 1, 1, 2),
(80, '2014-09-27 15:00:00', 'Manchester United', 'West Ham United', 2, 1, 1),
(81, '2014-09-27 15:00:00', 'Southampton', 'Queens Park Rangers', 2, 1, 1),
(82, '2014-09-29 20:00:00', 'Stoke City', 'Newcastle United', 1, 0, 1),
(83, '2014-09-27 15:00:00', 'Sunderland', 'Swansea City', 0, 0, 2),
(84, '2014-09-28 16:00:00', 'West Bromwich Albion', 'Burnley', 4, 0, 1),
(85, '2014-10-04 17:30:00', 'Aston Villa', 'Manchester City', 0, 2, 3),
(86, '2014-10-05 14:05:00', 'Chelsea', 'Arsenal', 2, 0, 1),
(87, '2014-10-04 15:00:00', 'Hull City', 'Crystal Palace', 2, 0, 1),
(88, '2014-10-04 15:00:00', 'Leicester City', 'Burnley', 2, 2, 2),
(89, '2014-10-04 15:00:00', 'Liverpool', 'West Bromwich Albion', 2, 1, 1),
(90, '2014-10-05 12:00:00', 'Manchester United', 'Everton', 2, 1, 1),
(91, '2014-10-04 15:00:00', 'Sunderland', 'Stoke City', 3, 1, 1),
(92, '2014-10-04 15:00:00', 'Swansea City', 'Newcastle United', 2, 2, 2),
(93, '2014-10-05 14:05:00', 'Tottenham Hotspur', 'Southampton', 1, 0, 1),
(94, '2014-10-05 16:15:00', 'West Ham United', 'Queens Park Rangers', 2, 0, 1),
(95, '2014-10-18 15:00:00', 'Arsenal', 'Hull City', 2, 2, 2),
(96, '2014-10-18 15:00:00', 'Burnley', 'West Ham United', 1, 3, 3),
(97, '2014-10-18 15:00:00', 'Crystal Palace', 'Chelsea', 1, 2, 3),
(98, '2014-10-18 15:00:00', 'Everton', 'Aston Villa', 3, 0, 1),
(99, '2014-10-18 12:45:00', 'Manchester City', 'Tottenham Hotspur', 4, 1, 1),
(100, '2014-10-18 15:00:00', 'Newcastle United', 'Leicester City', 1, 0, 1),
(101, '2014-10-19 13:30:00', 'Queens Park Rangers', 'Liverpool', 2, 3, 3),
(102, '2014-10-18 15:00:00', 'Southampton', 'Sunderland', 8, 0, 1),
(103, '2014-10-19 16:00:00', 'Stoke City', 'Swansea City', 2, 1, 0),
(104, '2014-10-20 20:00:00', 'West Bromwich Albion', 'Manchester United', 2, 2, 2),
(105, '2014-10-25 15:00:00', 'Burnley', 'Everton', 1, 3, 3),
(106, '2014-10-25 15:00:00', 'Liverpool', 'Hull City', 0, 0, 2),
(107, '2014-10-25 15:00:00', 'Manchester United', 'Chelsea', 1, 1, 2),
(108, '2014-10-25 15:00:00', 'Queens Park Rangers', 'Aston Villa', 2, 0, 1),
(109, '2014-10-25 15:00:00', 'Southampton', 'Stoke City', 1, 0, 1),
(110, '2014-10-25 15:00:00', 'Sunderland', 'Arsenal', 0, 2, 3),
(111, '2014-10-25 15:00:00', 'Swansea City', 'Leicester City', 2, 0, 1),
(112, '2014-10-25 15:00:00', 'Tottenham Hotspur', 'Newcastle United', 1, 2, 3),
(113, '2014-10-25 15:00:00', 'West Bromwich Albion', 'Crystal Palace', 2, 2, 2),
(114, '2014-10-25 15:00:00', 'West Ham United', 'Manchester City', 2, 1, 1),
(115, '2014-11-01 15:00:00', 'Arsenal', 'Burnley', 3, 0, 1),
(116, '2014-11-01 15:00:00', 'Aston Villa', 'Tottenham Hotspur', 1, 2, 3),
(117, '2014-11-01 15:00:00', 'Chelsea', 'Queens Park Rangers', 2, 1, 1),
(118, '2014-11-01 15:00:00', 'Crystal Palace', 'Sunderland', 1, 3, 3),
(119, '2014-11-01 15:00:00', 'Everton', 'Swansea City', 0, 0, 2),
(120, '2014-11-01 15:00:00', 'Hull City', 'Southampton', 0, 1, 3),
(121, '2014-11-01 15:00:00', 'Leicester City', 'West Bromwich Albion', 0, 1, 3),
(122, '2014-11-01 15:00:00', 'Manchester City', 'Manchester United', 1, 0, 1),
(123, '2014-11-01 15:00:00', 'Newcastle United', 'Liverpool', 1, 0, 1),
(124, '2014-11-01 15:00:00', 'Stoke City', 'West Ham United', 2, 2, 2),
(125, '2014-11-08 15:00:00', 'Burnley', 'Hull City', 1, 0, 1),
(126, '2014-11-08 15:00:00', 'Liverpool', 'Chelsea', 1, 2, 3),
(127, '2014-11-08 15:00:00', 'Manchester United', 'Crystal Palace', 1, 0, 1),
(128, '2014-11-08 15:00:00', 'Queens Park Rangers', 'Manchester City', 2, 2, 2),
(129, '2014-11-08 15:00:00', 'Southampton', 'Leicester City', 2, 0, 1),
(130, '2014-11-08 15:00:00', 'Sunderland', 'Everton', 1, 2, 3),
(131, '2014-11-08 15:00:00', 'Swansea City', 'Arsenal', 2, 1, 1),
(132, '2014-11-08 15:00:00', 'Tottenham Hotspur', 'Stoke City', 1, 2, 3),
(133, '2014-11-08 15:00:00', 'West Bromwich Albion', 'Newcastle United', 0, 2, 3),
(134, '2014-11-08 15:00:00', 'West Ham United', 'Aston Villa', 0, 0, 2),
(135, '2014-11-22 17:30:00', 'Arsenal', 'Manchester United', 2, 1, 1),
(136, '2014-11-24 20:00:00', 'Aston Villa', 'Southampton', 1, 1, 2),
(137, '2014-11-22 15:00:00', 'Chelsea', 'West Bromwich Albion', 2, 0, 1),
(138, '2014-11-23 13:30:00', 'Crystal Palace', 'Liverpool', 3, 1, 1),
(139, '2014-11-22 15:00:00', 'Everton', 'West Ham United', 2, 1, 1),
(140, '2014-11-23 16:00:00', 'Hull City', 'Tottenham Hotspur', 1, 2, 3),
(141, '2014-11-22 15:00:00', 'Leicester City', 'Sunderland', 0, 0, 2),
(142, '2014-11-22 15:00:00', 'Manchester City', 'Swansea City', 2, 1, 1),
(143, '2014-11-22 15:00:00', 'Newcastle United', 'Queens Park Rangers', 1, 0, 1),
(144, '2014-11-22 15:00:00', 'Stoke City', 'Burnley', 1, 2, 3),
(145, '2014-11-29 15:00:00', 'Burnley', 'Aston Villa', 1, 1, 2),
(146, '2014-11-29 15:00:00', 'Liverpool', 'Stoke City', 1, 0, 1),
(147, '2014-11-29 15:00:00', 'Manchester United', 'Hull City', 3, 0, 1),
(148, '2014-11-29 15:00:00', 'Queens Park Rangers', 'Leicester City', 3, 2, 1),
(149, '2014-11-29 15:00:00', 'Southampton', 'Manchester City', 0, 3, 3),
(150, '2014-11-29 15:00:00', 'Sunderland', 'Chelsea', 0, 0, 2),
(151, '2014-11-29 15:00:00', 'Swansea City', 'Crystal Palace', 1, 1, 2),
(152, '2014-11-29 15:00:00', 'Tottenham Hotspur', 'Everton', 2, 1, 1),
(153, '2014-11-29 15:00:00', 'West Bromwich Albion', 'Arsenal', 0, 1, 3),
(154, '2014-11-29 15:00:00', 'West Ham United', 'Newcastle United', 1, 0, 1),
(155, '2014-12-02 19:45:00', 'Arsenal', 'Southampton', 1, 0, 1),
(156, '2014-12-02 19:45:00', 'Burnley', 'Newcastle United', 1, 1, 2),
(157, '2014-12-02 20:00:00', 'Crystal Palace', 'Aston Villa', 0, 1, 3),
(158, '2014-12-02 19:45:00', 'Leicester City', 'Liverpool', 1, 3, 3),
(159, '2014-12-02 19:45:00', 'Manchester United', 'Stoke City', 2, 1, 1),
(160, '2014-12-02 19:45:00', 'Swansea City', 'Queens Park Rangers', 2, 0, 1),
(161, '2014-12-02 20:00:00', 'West Bromwich Albion', 'West Ham United', 1, 2, 3),
(162, '2014-12-03 19:45:00', 'Chelsea', 'Tottenham Hotspur', 3, 0, 1),
(163, '2014-12-03 19:45:00', 'Everton', 'Hull City', 1, 1, 2),
(164, '2014-12-03 19:45:00', 'Sunderland', 'Manchester City', 1, 4, 3),
(165, '2014-12-06 15:00:00', 'Aston Villa', 'Leicester City', 2, 1, 1),
(166, '2014-12-06 15:00:00', 'Hull City', 'West Bromwich Albion', 0, 0, 2),
(167, '2014-12-06 15:00:00', 'Liverpool', 'Sunderland', 0, 0, 2),
(168, '2014-12-06 15:00:00', 'Manchester City', 'Everton', 1, 0, 1),
(169, '2014-12-06 15:00:00', 'Newcastle United', 'Chelsea', 2, 1, 1),
(170, '2014-12-06 15:00:00', 'Queens Park Rangers', 'Burnley', 2, 0, 2),
(171, '2014-12-08 20:00:00', 'Southampton', 'Manchester United', 1, 2, 3),
(172, '2014-12-06 15:00:00', 'Stoke City', 'Arsenal', 3, 2, 1),
(173, '2014-12-06 15:00:00', 'Tottenham Hotspur', 'Crystal Palace', 0, 0, 2),
(174, '2014-12-06 15:00:00', 'West Ham United', 'Swansea City', 3, 1, 1),
(175, '2014-12-13 17:30:00', 'Arsenal', 'Newcastle United', 4, 1, 1),
(176, '2014-12-13 15:00:00', 'Burnley', 'Southampton', 1, 0, 1),
(177, '2014-12-13 15:00:00', 'Chelsea', 'Hull City', 2, 0, 1),
(178, '2014-12-13 15:00:00', 'Crystal Palace', 'Stoke City', 1, 1, 2),
(179, '2014-12-15 20:00:00', 'Everton', 'Queens Park Rangers', 3, 1, 1),
(180, '2014-12-13 15:00:00', 'Leicester City', 'Manchester City', 0, 1, 3),
(181, '2014-12-14 13:30:00', 'Manchester United', 'Liverpool', 3, 0, 1),
(182, '2014-12-13 15:00:00', 'Sunderland', 'West Ham United', 1, 1, 2),
(183, '2014-12-14 16:00:00', 'Swansea City', 'Tottenham Hotspur', 1, 2, 3),
(184, '2014-12-13 15:00:00', 'West Bromwich Albion', 'Aston Villa', 1, 0, 1),
(185, '2014-12-20 15:00:00', 'Aston Villa', 'Manchester United', 1, 1, 2),
(186, '2014-12-20 15:00:00', 'Hull City', 'Swansea City', 0, 1, 3),
(187, '2014-12-21 16:00:00', 'Liverpool', 'Arsenal', 2, 2, 2),
(188, '2014-12-20 12:45:00', 'Manchester City', 'Crystal Palace', 3, 0, 1),
(189, '2014-12-21 13:30:00', 'Newcastle United', 'Sunderland', 0, 1, 3),
(190, '2014-12-20 15:00:00', 'Queens Park Rangers', 'West Bromwich Albion', 3, 2, 1),
(191, '2014-12-20 15:00:00', 'Southampton', 'Everton', 3, 0, 1),
(192, '2014-12-22 20:00:00', 'Stoke City', 'Chelsea', 0, 2, 3),
(193, '2014-12-20 15:00:00', 'Tottenham Hotspur', 'Burnley', 2, 1, 1),
(194, '2014-12-20 15:00:00', 'West Ham United', 'Leicester City', 2, 0, 1),
(195, '2014-12-26 17:30:00', 'Arsenal', 'Queens Park Rangers', 2, 1, 1),
(196, '2014-12-26 15:00:00', 'Burnley', 'Liverpool', 0, 1, 3),
(197, '2014-12-26 12:45:00', 'Chelsea', 'West Ham United', 2, 0, 1),
(198, '2014-12-26 15:00:00', 'Crystal Palace', 'Southampton', 1, 3, 3),
(199, '2014-12-26 15:00:00', 'Everton', 'Stoke City', 0, 1, 3),
(200, '2014-12-26 15:00:00', 'Leicester City', 'Tottenham Hotspur', 1, 2, 3),
(201, '2014-12-26 15:00:00', 'Manchester United', 'Newcastle United', 3, 1, 1),
(202, '2014-12-26 15:00:00', 'Sunderland', 'Hull City', 1, 3, 3),
(203, '2014-12-26 15:00:00', 'Swansea City', 'Aston Villa', 1, 0, 1),
(204, '2014-12-26 15:00:00', 'West Bromwich Albion', 'Manchester City', 1, 3, 3),
(205, '2014-12-28 15:00:00', 'Aston Villa', 'Sunderland', NULL, NULL, NULL),
(206, '2014-12-28 15:00:00', 'Hull City', 'Leicester City', NULL, NULL, NULL),
(207, '2014-12-28 15:00:00', 'Liverpool', 'Swansea City', NULL, NULL, NULL),
(208, '2014-12-28 15:00:00', 'Manchester City', 'Burnley', NULL, NULL, NULL),
(209, '2014-12-28 15:00:00', 'Newcastle United', 'Everton', NULL, NULL, NULL),
(210, '2014-12-28 15:00:00', 'Queens Park Rangers', 'Crystal Palace', NULL, NULL, NULL),
(211, '2014-12-28 15:00:00', 'Southampton', 'Chelsea', NULL, NULL, NULL),
(212, '2014-12-28 15:00:00', 'Stoke City', 'West Bromwich Albion', NULL, NULL, NULL),
(213, '2014-12-28 15:00:00', 'Tottenham Hotspur', 'Manchester United', NULL, NULL, NULL),
(214, '2014-12-28 15:00:00', 'West Ham United', 'Arsenal', NULL, NULL, NULL),
(215, '2015-01-01 15:00:00', 'Aston Villa', 'Crystal Palace', 0, 0, 2),
(216, '2015-01-01 15:00:00', 'Hull City', 'Everton', 2, 0, 1),
(217, '2015-01-01 15:00:00', 'Liverpool', 'Leicester City', 2, 2, 2),
(218, '2015-01-01 15:00:00', 'Manchester City', 'Sunderland', 3, 2, 1),
(219, '2015-01-01 15:00:00', 'Newcastle United', 'Burnley', 3, 3, 2),
(220, '2015-01-01 15:00:00', 'Queens Park Rangers', 'Swansea City', 1, 1, 2),
(221, '2015-01-01 15:00:00', 'Southampton', 'Arsenal', 2, 0, 1),
(222, '2015-01-01 15:00:00', 'Stoke City', 'Manchester United', 1, 1, 2),
(223, '2015-01-01 15:00:00', 'Tottenham Hotspur', 'Chelsea', 5, 3, 1),
(224, '2015-01-01 15:00:00', 'West Ham United', 'West Bromwich Albion', 1, 1, 2),
(225, '2015-01-11 13:30:00', 'Arsenal', 'Stoke City', NULL, NULL, NULL),
(226, '2015-01-10 15:00:00', 'Burnley', 'Queens Park Rangers', NULL, NULL, NULL),
(227, '2015-01-10 15:00:00', 'Chelsea', 'Newcastle United', NULL, NULL, NULL),
(228, '2015-01-10 17:30:00', 'Crystal Palace', 'Tottenham Hotspur', NULL, NULL, NULL),
(229, '2015-01-10 15:00:00', 'Everton', 'Manchester City', NULL, NULL, NULL),
(230, '2015-01-10 15:00:00', 'Leicester City', 'Aston Villa', NULL, NULL, NULL),
(231, '2015-01-11 16:00:00', 'Manchester United', 'Southampton', NULL, NULL, NULL),
(232, '2015-01-10 12:45:00', 'Sunderland', 'Liverpool', NULL, NULL, NULL),
(233, '2015-01-10 15:00:00', 'Swansea City', 'West Ham United', NULL, NULL, NULL),
(234, '2015-01-10 15:00:00', 'West Bromwich Albion', 'Hull City', NULL, NULL, NULL),
(235, '2015-01-17 15:00:00', 'Aston Villa', 'Liverpool', 0, 2, 3),
(236, '2015-01-17 15:00:00', 'Burnley', 'Crystal Palace', 2, 3, 3),
(237, '2015-01-19 20:00:00', 'Everton', 'West Bromwich Albion', 0, 0, 2),
(238, '2015-01-17 15:00:00', 'Leicester City', 'Stoke City', 0, 1, 3),
(239, '2015-01-18 16:00:00', 'Manchester City', 'Arsenal', 0, 2, 3),
(240, '2015-01-17 17:30:00', 'Newcastle United', 'Southampton', 1, 2, 3),
(241, '2015-01-17 15:00:00', 'Queens Park Rangers', 'Manchester United', 0, 2, 3),
(242, '2015-01-17 15:00:00', 'Swansea City', 'Chelsea', 0, 5, 3),
(243, '2015-01-17 15:00:00', 'Tottenham Hotspur', 'Sunderland', 2, 1, 1),
(244, '2015-01-18 13:30:00', 'West Ham United', 'Hull City', 3, 0, 1),
(245, '2015-02-01 13:30:00', 'Arsenal', 'Aston Villa', 5, 0, 1),
(246, '2015-01-31 17:30:00', 'Chelsea', 'Manchester City', 1, 1, 2),
(247, '2015-01-31 15:00:00', 'Crystal Palace', 'Everton', 0, 1, 3),
(248, '2015-01-31 12:45:00', 'Hull City', 'Newcastle United', 0, 3, 3),
(249, '2015-01-31 15:00:00', 'Liverpool', 'West Ham United', 2, 0, 1),
(250, '2015-01-31 15:00:00', 'Manchester United', 'Leicester City', 3, 1, 1),
(251, '2015-02-01 16:00:00', 'Southampton', 'Swansea City', 0, 1, 3),
(252, '2015-01-31 15:00:00', 'Stoke City', 'Queens Park Rangers', 3, 1, 1),
(253, '2015-01-31 15:00:00', 'Sunderland', 'Burnley', 2, 0, 1),
(254, '2015-01-31 15:00:00', 'West Bromwich Albion', 'Tottenham Hotspur', 0, 3, 3),
(255, '2015-02-07 15:00:00', 'Aston Villa', 'Chelsea', 1, 2, 3),
(256, '2015-02-08 12:00:00', 'Burnley', 'West Bromwich Albion', NULL, NULL, NULL),
(257, '2015-02-07 17:30:00', 'Everton', 'Liverpool', 0, 0, 2),
(258, '2015-02-07 15:00:00', 'Leicester City', 'Crystal Palace', 0, 1, 3),
(259, '2015-02-07 15:00:00', 'Manchester City', 'Hull City', 1, 1, 2),
(260, '2015-02-08 14:05:00', 'Newcastle United', 'Stoke City', NULL, NULL, NULL),
(261, '2015-02-07 15:00:00', 'Queens Park Rangers', 'Southampton', 0, 1, 3),
(262, '2015-02-07 15:00:00', 'Swansea City', 'Sunderland', 1, 1, 2),
(263, '2015-02-07 12:45:00', 'Tottenham Hotspur', 'Arsenal', 2, 1, 1),
(264, '2015-02-08 16:15:00', 'West Ham United', 'Manchester United', NULL, NULL, NULL),
(265, '2015-02-10 19:45:00', 'Arsenal', 'Leicester City', NULL, NULL, NULL),
(266, '2015-02-10 20:00:00', 'Crystal Palace', 'Newcastle United', NULL, NULL, NULL),
(267, '2015-02-10 19:45:00', 'Hull City', 'Aston Villa', NULL, NULL, NULL),
(268, '2015-02-10 20:00:00', 'Liverpool', 'Tottenham Hotspur', NULL, NULL, NULL),
(269, '2015-02-10 19:45:00', 'Manchester United', 'Burnley', NULL, NULL, NULL),
(270, '2015-02-10 19:45:00', 'Southampton', 'West Ham United', NULL, NULL, NULL),
(271, '2015-02-10 20:00:00', 'West Bromwich Albion', 'Swansea City', NULL, NULL, NULL),
(272, '2015-02-11 19:45:00', 'Chelsea', 'Everton', NULL, NULL, NULL),
(273, '2015-02-11 19:45:00', 'Stoke City', 'Manchester City', NULL, NULL, NULL),
(274, '2015-02-11 19:45:00', 'Sunderland', 'Queens Park Rangers', NULL, NULL, NULL),
(275, '2015-02-21 15:00:00', 'Aston Villa', 'Stoke City', NULL, NULL, NULL),
(276, '2015-02-21 15:00:00', 'Chelsea', 'Burnley', NULL, NULL, NULL),
(277, '2015-02-21 15:00:00', 'Crystal Palace', 'Arsenal', NULL, NULL, NULL),
(278, '2015-02-21 15:00:00', 'Everton', 'Leicester City', NULL, NULL, NULL),
(279, '2015-02-21 15:00:00', 'Hull City', 'Queens Park Rangers', NULL, NULL, NULL),
(280, '2015-02-21 15:00:00', 'Manchester City', 'Newcastle United', NULL, NULL, NULL),
(281, '2015-02-21 15:00:00', 'Southampton', 'Liverpool', NULL, NULL, NULL),
(282, '2015-02-21 15:00:00', 'Sunderland', 'West Bromwich Albion', NULL, NULL, NULL),
(283, '2015-02-21 15:00:00', 'Swansea City', 'Manchester United', 2, 1, 1),
(284, '2015-02-21 15:00:00', 'Tottenham Hotspur', 'West Ham United', NULL, NULL, NULL),
(285, '2015-03-01 14:05:00', 'Arsenal', 'Everton', 2, 0, 1),
(286, '2015-02-28 15:00:00', 'Burnley', 'Swansea City', 0, 1, 3),
(287, '2015-04-29 19:45:00', 'Leicester City', 'Chelsea', NULL, NULL, NULL),
(288, '2015-03-01 12:00:00', 'Liverpool', 'Manchester City', 2, 1, 1),
(289, '2015-02-28 15:00:00', 'Manchester United', 'Sunderland', 2, 0, 1),
(290, '2015-02-28 15:00:00', 'Newcastle United', 'Aston Villa', 1, 0, 1),
(291, '2015-03-07 15:00:00', 'Queens Park Rangers', 'Tottenham Hotspur', NULL, NULL, NULL),
(292, '2015-02-28 15:00:00', 'Stoke City', 'Hull City', 1, 0, 1),
(293, '2015-02-28 15:00:00', 'West Bromwich Albion', 'Southampton', 1, 0, 1),
(294, '2015-02-28 12:45:00', 'West Ham United', 'Crystal Palace', 1, 3, 3),
(295, '2015-03-03 19:45:00', 'Aston Villa', 'West Bromwich Albion', 2, 1, 1),
(296, '2015-03-03 19:45:00', 'Hull City', 'Sunderland', 1, 1, 2),
(297, '2015-03-04 20:00:00', 'Liverpool', 'Burnley', 2, 0, 1),
(298, '2015-03-04 19:45:00', 'Queens Park Rangers', 'Arsenal', 1, 2, 3),
(299, '2015-03-03 19:45:00', 'Southampton', 'Crystal Palace', 1, 0, 1),
(300, '2015-03-04 19:45:00', 'West Ham United', 'Chelsea', 0, 1, 3),
(301, '2015-03-04 19:45:00', 'Manchester City', 'Leicester City', 2, 0, 1),
(302, '2015-03-04 19:45:00', 'Newcastle United', 'Manchester United', NULL, NULL, NULL),
(303, '2015-03-04 19:45:00', 'Stoke City', 'Everton', NULL, NULL, NULL),
(304, '2015-03-04 19:45:00', 'Tottenham Hotspur', 'Swansea City', NULL, NULL, NULL),
(305, '2015-03-14 15:00:00', 'Arsenal', 'West Ham United', 3, 0, 1),
(306, '2015-03-14 17:30:00', 'Burnley', 'Manchester City', 1, 0, 1),
(307, '2015-03-15 13:30:00', 'Chelsea', 'Southampton', 1, 1, 2),
(308, '2015-03-14 12:45:00', 'Crystal Palace', 'Queens Park Rangers', 3, 1, 1),
(309, '2015-03-14 15:00:00', 'Everton', 'Newcastle United', 3, 0, 1),
(310, '2015-03-14 15:00:00', 'Leicester City', 'Hull City', 0, 0, 2),
(311, '2015-03-15 16:00:00', 'Manchester United', 'Tottenham Hotspur', 3, 0, 1),
(312, '2015-03-14 15:00:00', 'Sunderland', 'Aston Villa', 0, 4, 3),
(313, '2015-03-16 20:00:00', 'Swansea City', 'Liverpool', NULL, NULL, NULL),
(314, '2015-03-14 15:00:00', 'West Bromwich Albion', 'Stoke City', 1, 0, 1),
(315, '2015-03-21 15:00:00', 'Aston Villa', 'Swansea City', 0, 1, 3),
(316, '2015-03-22 16:00:00', 'Hull City', 'Chelsea', 2, 3, 3),
(317, '2015-03-22 13:30:00', 'Liverpool', 'Manchester United', 1, 2, 3),
(318, '2015-03-21 12:45:00', 'Manchester City', 'West Bromwich Albion', 3, 0, 1),
(319, '2015-03-21 15:00:00', 'Newcastle United', 'Arsenal', 1, 2, 3),
(320, '2015-03-22 16:00:00', 'Queens Park Rangers', 'Everton', 1, 2, 3),
(321, '2015-03-21 15:00:00', 'Southampton', 'Burnley', 2, 0, 1),
(322, '2015-03-21 15:00:00', 'Stoke City', 'Crystal Palace', 1, 2, 3),
(323, '2015-03-21 15:00:00', 'Tottenham Hotspur', 'Leicester City', 4, 3, 1),
(324, '2015-03-21 17:30:00', 'West Ham United', 'Sunderland', 1, 0, 1),
(325, '2015-04-04 12:45:00', 'Arsenal', 'Liverpool', 4, 1, 1),
(326, '2015-04-05 13:30:00', 'Burnley', 'Tottenham Hotspur', 0, 0, 2),
(327, '2015-04-04 17:30:00', 'Chelsea', 'Stoke City', 2, 1, 1),
(328, '2015-04-06 20:00:00', 'Crystal Palace', 'Manchester City', 2, 1, 1),
(329, '2015-04-04 15:00:00', 'Everton', 'Southampton', 1, 0, 1),
(330, '2015-04-04 15:00:00', 'Leicester City', 'West Ham United', 2, 1, 1),
(331, '2015-04-04 15:00:00', 'Manchester United', 'Aston Villa', 3, 1, 1),
(332, '2015-04-05 16:00:00', 'Sunderland', 'Newcastle United', 1, 0, 1),
(333, '2015-04-04 15:00:00', 'Swansea City', 'Hull City', 3, 1, 1),
(334, '2015-04-04 15:00:00', 'West Bromwich Albion', 'Queens Park Rangers', 1, 4, 3),
(335, '2015-04-11 15:00:00', 'Burnley', 'Arsenal', 0, 1, 3),
(336, '2015-04-11 15:00:00', 'Liverpool', 'Newcastle United', 2, 0, 1),
(337, '2015-04-11 15:00:00', 'Manchester United', 'Manchester City', 4, 2, 1),
(338, '2015-04-11 15:00:00', 'Queens Park Rangers', 'Chelsea', 0, 1, 3),
(339, '2015-04-11 15:00:00', 'Southampton', 'Hull City', 2, 0, 1),
(340, '2015-04-11 15:00:00', 'Sunderland', 'Crystal Palace', 1, 4, 3),
(341, '2015-04-11 15:00:00', 'Swansea City', 'Everton', 1, 1, 2),
(342, '2015-04-11 15:00:00', 'Tottenham Hotspur', 'Aston Villa', 0, 1, 3),
(343, '2015-04-11 15:00:00', 'West Bromwich Albion', 'Leicester City', 2, 3, 3),
(344, '2015-04-11 15:00:00', 'West Ham United', 'Stoke City', 1, 1, 2),
(345, '2015-05-20 19:45:00', 'Arsenal', 'Sunderland', NULL, NULL, NULL),
(346, '2015-04-07 20:00:00', 'Aston Villa', 'Queens Park Rangers', 3, 3, 2),
(347, '2015-04-18 15:00:00', 'Chelsea', 'Manchester United', 1, 0, 1),
(348, '2015-04-18 15:00:00', 'Crystal Palace', 'West Bromwich Albion', 0, 2, 3),
(349, '2015-04-18 15:00:00', 'Everton', 'Burnley', 1, 0, 1),
(350, '2015-04-28 19:45:00', 'Hull City', 'Liverpool', 1, 0, 1),
(351, '2015-04-18 15:00:00', 'Leicester City', 'Swansea City', 2, 0, 1),
(352, '2015-04-18 15:00:00', 'Manchester City', 'West Ham United', 2, 0, 1),
(353, '2015-04-18 15:00:00', 'Newcastle United', 'Tottenham Hotspur', 1, 3, 3),
(354, '2015-04-18 15:00:00', 'Stoke City', 'Southampton', 2, 1, 1),
(355, '2015-04-26 16:00:00', 'Arsenal', 'Chelsea', 0, 0, 2),
(356, '2015-04-25 15:00:00', 'Burnley', 'Leicester City', 0, 1, 3),
(357, '2015-04-25 15:00:00', 'Crystal Palace', 'Hull City', 0, 2, 3),
(358, '2015-04-26 13:30:00', 'Everton', 'Manchester United', 3, 0, 1),
(359, '2015-04-25 17:30:00', 'Manchester City', 'Aston Villa', 1, 0, 1),
(360, '2015-04-25 15:00:00', 'Newcastle United', 'Swansea City', 2, 3, 3),
(361, '2015-04-25 15:00:00', 'Queens Park Rangers', 'West Ham United', 0, 0, 2),
(362, '2015-04-25 12:45:00', 'Southampton', 'Tottenham Hotspur', 2, 2, 2),
(363, '2015-04-25 15:00:00', 'Stoke City', 'Sunderland', 1, 1, 2),
(364, '2015-04-25 15:00:00', 'West Bromwich Albion', 'Liverpool', 0, 0, 2),
(365, '2015-05-02 15:00:00', 'Aston Villa', 'Everton', 3, 2, 1),
(366, '2015-05-03 13:30:00', 'Chelsea', 'Crystal Palace', 1, 0, 1),
(367, '2015-05-04 20:00:00', 'Hull City', 'Arsenal', 1, 3, 3),
(368, '2015-05-02 12:45:00', 'Leicester City', 'Newcastle United', 3, 0, 1),
(369, '2015-05-02 15:00:00', 'Liverpool', 'Queens Park Rangers', 2, 1, 1),
(370, '2015-05-02 17:30:00', 'Manchester United', 'West Bromwich Albion', 0, 1, 3),
(371, '2015-05-02 15:00:00', 'Sunderland', 'Southampton', 2, 1, 1),
(372, '2015-05-02 15:00:00', 'Swansea City', 'Stoke City', 2, 0, 1),
(373, '2015-05-03 16:00:00', 'Tottenham Hotspur', 'Manchester City', 0, 1, 3),
(374, '2015-05-02 15:00:00', 'West Ham United', 'Burnley', 1, 0, 1),
(375, '2015-05-11 20:00:00', 'Arsenal', 'Swansea City', NULL, NULL, NULL),
(376, '2015-05-09 15:00:00', 'Aston Villa', 'West Ham United', 1, 0, 1),
(377, '2015-05-10 16:00:00', 'Chelsea', 'Liverpool', NULL, NULL, NULL),
(378, '2015-05-09 17:30:00', 'Crystal Palace', 'Manchester United', NULL, NULL, NULL),
(379, '2015-05-09 12:45:00', 'Everton', 'Sunderland', NULL, NULL, NULL),
(380, '2015-05-09 15:00:00', 'Hull City', 'Burnley', 0, 1, 3),
(381, '2015-05-09 15:00:00', 'Leicester City', 'Southampton', NULL, NULL, NULL),
(382, '2015-05-10 13:30:00', 'Manchester City', 'Queens Park Rangers', NULL, NULL, NULL),
(383, '2015-05-09 15:00:00', 'Newcastle United', 'West Bromwich Albion', NULL, NULL, NULL),
(384, '2015-05-09 15:00:00', 'Stoke City', 'Tottenham Hotspur', NULL, NULL, NULL),
(385, '2015-05-16 15:00:00', 'Burnley', 'Stoke City', NULL, NULL, NULL),
(386, '2015-05-16 17:30:00', 'Liverpool', 'Crystal Palace', 1, 3, 3),
(387, '2015-05-17 16:00:00', 'Manchester United', 'Arsenal', NULL, NULL, NULL),
(388, '2015-05-16 15:00:00', 'Queens Park Rangers', 'Newcastle United', NULL, NULL, NULL),
(389, '2015-05-16 12:45:00', 'Southampton', 'Aston Villa', NULL, NULL, NULL),
(390, '2015-05-16 15:00:00', 'Sunderland', 'Leicester City', NULL, NULL, NULL),
(391, '2015-05-17 13:30:00', 'Swansea City', 'Manchester City', NULL, NULL, NULL),
(392, '2015-05-16 15:00:00', 'Tottenham Hotspur', 'Hull City', 2, 0, 1),
(393, '2015-05-18 20:00:00', 'West Bromwich Albion', 'Chelsea', NULL, NULL, NULL),
(394, '2015-05-16 15:00:00', 'West Ham United', 'Everton', NULL, NULL, NULL),
(405, '2015-05-22 19:45:00', 'Cork City', 'Shamrock Rovers', NULL, NULL, NULL),
(406, '2015-05-22 19:45:00', 'Bohemians', 'Bray Wanderers', NULL, NULL, NULL),
(407, '2015-05-22 19:45:00', 'Derry City', 'Sligo Rovers', NULL, NULL, NULL),
(408, '2015-05-22 19:45:00', 'Drogheda United', 'Galway United', NULL, NULL, NULL),
(409, '2015-05-22 19:45:00', 'St. Patrick’s Athletic', 'Dundalk', NULL, NULL, NULL),
(410, '2015-05-23 19:30:00', 'Longford Town', 'Limerick City', NULL, NULL, NULL),
(411, '2015-06-05 19:45:00', 'Bray Wanderers', 'Longford Town', 0, 1, 3),
(412, '2015-06-05 19:45:00', 'Derry City', 'St. Patrick’s Athletic', 0, 3, 3),
(413, '2015-06-05 19:45:00', 'Galway United', 'Cork City', 1, 3, 3),
(414, '2015-06-05 19:45:00', 'Dundalk', 'Bohemians', 1, 2, 3),
(415, '2015-06-05 19:45:00', 'Limerick', 'Drogheda United', 1, 2, 3),
(416, '2015-06-05 20:00:00', 'Shamrock Rovers', 'Sligo Rovers', 5, 1, 1),
(417, '2015-06-08 20:00:00', 'Shamrock Rovers', 'Derry City', NULL, NULL, NULL),
(418, '2015-06-09 19:45:00', 'St. Patrick’s Athletic', 'Bohemians', NULL, NULL, NULL),
(419, '2015-06-12 19:45:00', 'Bohemians', 'Shamrock Rovers', 3, 1, 1),
(420, '2015-06-12 19:45:00', 'Cork City', 'Bray Wanderers', 1, 0, 1),
(421, '2015-06-12 19:45:00', 'Drogheda United', 'Derry City', 1, 1, 2),
(422, '2015-06-12 19:45:00', 'St. Patrick’s Athletic', 'Limerick', 3, 1, 1),
(423, '2015-06-12 19:45:00', 'Sligo Rovers', 'Dundalk', 1, 2, 3),
(424, '2015-06-12 19:45:00', 'Longford Town', 'Galway United', 0, 1, 3),
(425, '2015-06-26 20:00:00', 'St. Patrick’s Athletic', 'Longford Town', 3, 0, 1),
(426, '2015-06-26 19:45:00', 'Derry City', 'Cork City', 0, 2, 3),
(427, '2015-06-26 19:45:00', 'Galway United', 'Shamrock Rovers', 1, 2, 3),
(428, '2015-06-26 19:45:00', 'Bohemians', 'Drogheda United', 0, 1, 3),
(429, '2015-06-26 19:45:00', 'Dundalk', 'Limerick', 6, 2, 1),
(430, '2015-06-27 17:45:00', 'Bray Wanderers', 'Sligo Rovers', NULL, NULL, NULL),
(431, '2015-06-03 00:20:05', 'Drogheda United', 'Dundalk', NULL, NULL, NULL),
(432, '2015-06-05 18:30:00', 'Limerick', 'Bray Wanderers', NULL, NULL, NULL),
(433, '2015-07-04 19:30:00', 'Longford Town', 'Bohemians', NULL, NULL, NULL),
(434, '2015-07-04 19:45:00', 'Sligo Rovers', 'Galway United', NULL, NULL, NULL),
(435, '2015-07-31 19:45:00', 'Cork City', 'Bohemians', 4, 0, 1),
(436, '2015-07-31 19:45:00', 'Derry City', 'Longford Town', 3, 0, 1),
(437, '2015-07-31 19:45:00', 'Drogheda United', 'Shamrock Rovers', 0, 1, 3),
(438, '2015-07-31 19:45:00', 'Bray Wanderers', 'Dundalk', 0, 1, 3),
(439, '2015-08-01 18:30:00', 'Limerick', 'Sligo Rovers', NULL, NULL, NULL),
(440, '2015-07-31 19:45:00', 'St. Patrick’s Athletic', 'Galway United', 3, 1, 1),
(441, '2015-08-07 19:45:00', 'Galway United', 'Derry City', 0, 4, 3),
(442, '2015-08-08 19:45:00', 'Sligo Rovers', 'Cork City', 0, 2, 3),
(443, '2015-08-07 19:45:00', 'Dundalk', 'Longford Town', 0, 0, 2),
(444, '2015-08-07 20:00:00', 'Shamrock Rovers', 'St. Patrick’s Athletic', 0, 2, 3),
(445, '2015-08-08 17:45:00', 'Bray Wanderers', 'Drogheda United', 1, 0, 1),
(446, '2015-08-08 18:30:00', 'Limerick', 'Bohemians', 4, 3, 1),
(447, '2015-08-14 19:45:00', 'Bohemians', 'Galway United', 3, 0, 1),
(448, '2015-08-14 19:45:00', 'Cork City', 'Limerick', 2, 3, 3),
(449, '2015-08-14 19:45:00', 'St. Patrick\'s Athletic', 'Bray Wanderers', 1, 0, 1),
(450, '2015-08-14 19:45:00', 'Drogheda United', 'Sligo Rovers', 0, 4, 3),
(451, '2015-08-14 19:45:00', 'Derry City', 'Dundalk', 0, 2, 3),
(452, '2015-08-14 20:00:00', 'Longford Town', 'Shamrock Rovers', 1, 3, 3),
(571, '2015-08-08 15:00:00', 'Bournemouth', 'Aston Villa', 0, 1, 3),
(572, '2015-08-08 15:00:00', 'Arsenal', 'West Ham United', 0, 2, 3),
(573, '2015-08-08 15:00:00', 'Chelsea', 'Swansea City', 2, 2, 2),
(574, '2015-08-08 15:00:00', 'Everton', 'Watford', 2, 2, 2),
(575, '2015-08-08 15:00:00', 'Leicester City', 'Sunderland', 4, 2, 1),
(576, '2015-08-08 15:00:00', 'Manchester United', 'Tottenham Hotspur', 1, 0, 1),
(577, '2015-08-08 15:00:00', 'Newcastle United', 'Southampton', 2, 2, 2),
(578, '2015-08-08 15:00:00', 'Norwich City', 'Crystal Palace', 1, 3, 3),
(579, '2015-08-08 15:00:00', 'Stoke City', 'Liverpool', 0, 1, 3),
(580, '2015-08-08 15:00:00', 'West Bromwich Albion', 'Manchester City', 0, 3, 3),
(581, '2015-08-15 15:00:00', 'Aston Villa', 'Manchester United', 0, 1, 3),
(582, '2015-08-15 15:00:00', 'Crystal Palace', 'Arsenal', 1, 2, 3),
(583, '2015-08-15 15:00:00', 'Liverpool', 'Bournemouth', 1, 0, 1),
(584, '2015-08-15 15:00:00', 'Manchester City', 'Chelsea', 3, 0, 1),
(585, '2015-08-15 15:00:00', 'Southampton', 'Everton', 0, 3, 3),
(586, '2015-08-15 15:00:00', 'Sunderland', 'Norwich City', 1, 3, 3),
(587, '2015-08-15 15:00:00', 'Swansea City', 'Newcastle United', 2, 0, 1),
(588, '2015-08-15 15:00:00', 'Tottenham Hotspur', 'Stoke City', 2, 2, 2),
(589, '2015-08-15 15:00:00', 'Watford', 'West Bromwich Albion', 0, 0, 2),
(590, '2015-08-15 15:00:00', 'West Ham United', 'Leicester City', 1, 2, 3),
(591, '2015-08-22 15:00:00', 'Arsenal', 'Liverpool', 0, 0, 2),
(592, '2015-08-22 15:00:00', 'Crystal Palace', 'Aston Villa', 2, 1, 1),
(593, '2015-08-22 15:00:00', 'Everton', 'Manchester City', 0, 2, 3),
(594, '2015-08-22 15:00:00', 'Leicester City', 'Tottenham Hotspur', 1, 1, 2),
(595, '2015-08-22 15:00:00', 'Manchester United', 'Newcastle United', 0, 0, 2),
(596, '2015-08-22 15:00:00', 'Norwich City', 'Stoke City', 1, 1, 2),
(597, '2015-08-22 15:00:00', 'Sunderland', 'Swansea City', 1, 1, 2),
(598, '2015-08-22 15:00:00', 'Watford', 'Southampton', 0, 0, 2),
(599, '2015-08-22 15:00:00', 'West Bromwich Albion', 'Chelsea', 2, 3, 3),
(600, '2015-08-22 15:00:00', 'West Ham United', 'Bournemouth', 3, 4, 3),
(601, '2015-08-29 15:00:00', 'Bournemouth', 'Leicester City', 1, 1, 2),
(602, '2015-08-29 15:00:00', 'Aston Villa', 'Sunderland', 2, 2, 2),
(603, '2015-08-29 15:00:00', 'Chelsea', 'Crystal Palace', 1, 2, 3),
(604, '2015-08-29 15:00:00', 'Liverpool', 'West Ham United', 0, 3, 3),
(605, '2015-08-29 15:00:00', 'Manchester City', 'Watford', 2, 0, 1),
(606, '2015-08-29 15:00:00', 'Newcastle United', 'Arsenal', 0, 1, 3),
(607, '2015-08-29 15:00:00', 'Southampton', 'Norwich City', 3, 0, 1),
(608, '2015-08-29 15:00:00', 'Stoke City', 'West Bromwich Albion', 0, 1, 3),
(609, '2015-08-29 15:00:00', 'Swansea City', 'Manchester United', 2, 1, 1),
(610, '2015-08-29 15:00:00', 'Tottenham Hotspur', 'Everton', 0, 0, 2),
(611, '2015-09-12 15:00:00', 'Arsenal', 'Stoke City', 2, 0, 1),
(612, '2015-09-12 15:00:00', 'Crystal Palace', 'Manchester City', 0, 1, 3),
(613, '2015-09-12 15:00:00', 'Everton', 'Chelsea', 3, 1, 1),
(614, '2015-09-12 15:00:00', 'Leicester City', 'Aston Villa', 3, 2, 1),
(615, '2015-09-12 15:00:00', 'Manchester United', 'Liverpool', 3, 1, 1),
(616, '2015-09-12 15:00:00', 'Norwich City', 'Bournemouth', 3, 1, 1),
(617, '2015-09-12 15:00:00', 'Sunderland', 'Tottenham Hotspur', 0, 1, 3),
(618, '2015-09-12 15:00:00', 'Watford', 'Swansea City', 1, 0, 1),
(619, '2015-09-12 15:00:00', 'West Bromwich Albion', 'Southampton', 0, 0, 2),
(620, '2015-09-12 15:00:00', 'West Ham United', 'Newcastle United', 2, 0, 1),
(621, '2015-09-19 15:00:00', 'Bournemouth', 'Sunderland', 2, 0, 1),
(622, '2015-09-19 15:00:00', 'Aston Villa', 'West Bromwich Albion', 0, 1, 3),
(623, '2015-09-19 12:45:00', 'Chelsea', 'Arsenal', 2, 0, 1),
(624, '2015-09-20 16:00:00', 'Liverpool', 'Norwich City', 1, 1, 2),
(625, '2015-09-19 17:30:00', 'Manchester City', 'West Ham United', 1, 2, 3),
(626, '2015-09-19 15:00:00', 'Newcastle United', 'Watford', 1, 2, 3),
(627, '2015-09-20 16:00:00', 'Southampton', 'Manchester United', 2, 3, 3),
(628, '2015-09-19 15:00:00', 'Stoke City', 'Leicester City', 2, 2, 2),
(629, '2015-09-19 15:00:00', 'Swansea City', 'Everton', 0, 0, 2),
(630, '2015-09-20 13:30:00', 'Tottenham Hotspur', 'Crystal Palace', 1, 0, 1),
(631, '2015-09-26 15:00:00', 'Leicester City', 'Arsenal', 2, 5, 3),
(632, '2015-09-26 15:00:00', 'Liverpool', 'Aston Villa', 3, 2, 1),
(633, '2015-09-26 15:00:00', 'Manchester United', 'Sunderland', 3, 0, 1),
(634, '2015-09-26 17:30:00', 'Newcastle United', 'Chelsea', 2, 2, 2),
(635, '2015-09-26 15:00:00', 'Southampton', 'Swansea City', 3, 1, 1),
(636, '2015-09-26 15:00:00', 'Stoke City', 'Bournemouth', 2, 1, 1),
(637, '2015-09-26 12:45:00', 'Tottenham Hotspur', 'Manchester City', 4, 1, 1),
(638, '2015-09-27 16:00:00', 'Watford', 'Crystal Palace', 0, 1, 3),
(639, '2015-09-28 20:00:00', 'West Bromwich Albion', 'Everton', 2, 3, 3),
(640, '2015-09-26 15:00:00', 'West Ham United', 'Norwich City', 2, 2, 2),
(641, '2015-10-03 15:00:00', 'Bournemouth', 'Watford', 1, 1, 2),
(642, '2015-10-04 16:00:00', 'Arsenal', 'Manchester United', 3, 0, 1),
(643, '2015-10-03 15:00:00', 'Aston Villa', 'Stoke City', 0, 1, 3),
(644, '2015-10-03 17:30:00', 'Chelsea', 'Southampton', 1, 3, 3),
(645, '2015-10-03 12:45:00', 'Crystal Palace', 'West Bromwich Albion', 2, 0, 1),
(646, '2015-10-04 13:30:00', 'Everton', 'Liverpool', 1, 1, 2),
(647, '2015-10-03 15:00:00', 'Manchester City', 'Newcastle United', 6, 1, 1),
(648, '2015-10-03 15:00:00', 'Norwich City', 'Leicester City', 1, 2, 3),
(649, '2015-10-03 15:00:00', 'Sunderland', 'West Ham United', 2, 2, 2),
(650, '2015-10-04 16:00:00', 'Swansea City', 'Tottenham Hotspur', 2, 2, 2),
(651, '2015-10-17 12:45:00', 'Chelsea', 'Aston Villa', 2, 0, 1),
(652, '2015-10-17 15:00:00', 'Crystal Palace', 'West Ham United', 1, 3, 3),
(653, '2015-10-17 15:00:00', 'Everton', 'Manchester United', 0, 3, 3),
(654, '2015-10-17 15:00:00', 'Manchester City', 'Bournemouth', 5, 1, 1),
(655, '2015-10-18 16:00:00', 'Newcastle United', 'Norwich City', 6, 2, 1),
(656, '2015-10-17 15:00:00', 'Southampton', 'Leicester City', 2, 2, 2),
(657, '2015-10-19 20:00:00', 'Swansea City', 'Stoke City', 0, 1, 3),
(658, '2015-10-17 15:00:00', 'Tottenham Hotspur', 'Liverpool', 0, 0, 2),
(659, '2015-10-17 17:30:00', 'Watford', 'Arsenal', 0, 3, 3),
(660, '2015-10-17 15:00:00', 'West Bromwich Albion', 'Sunderland', 1, 0, 1),
(661, '2015-10-25 14:05:00', 'Bournemouth', 'Tottenham Hotspur', 1, 5, 3),
(662, '2015-10-24 17:30:00', 'Arsenal', 'Everton', 2, 1, 1),
(663, '2015-10-24 15:00:00', 'Aston Villa', 'Swansea City', 1, 2, 3),
(664, '2015-10-24 15:00:00', 'Leicester City', 'Crystal Palace', 1, 0, 1),
(665, '2015-10-25 16:15:00', 'Liverpool', 'Southampton', 1, 1, 2),
(666, '2015-10-25 14:05:00', 'Manchester United', 'Manchester City', 0, 0, 2),
(667, '2015-10-24 15:00:00', 'Norwich City', 'West Bromwich Albion', 0, 1, 3),
(668, '2015-10-24 15:00:00', 'Stoke City', 'Watford', 0, 2, 3),
(669, '2015-10-25 12:00:00', 'Sunderland', 'Newcastle United', 3, 0, 1),
(670, '2015-10-24 15:00:00', 'West Ham United', 'Chelsea', 2, 1, 1),
(671, '2015-10-31 12:45:00', 'Chelsea', 'Liverpool', 1, 3, 3),
(672, '2015-10-31 15:00:00', 'Crystal Palace', 'Manchester United', 0, 0, 2),
(673, '2015-11-01 13:30:00', 'Everton', 'Sunderland', 6, 2, 1),
(674, '2015-10-31 15:00:00', 'Manchester City', 'Norwich City', 2, 1, 1),
(675, '2015-10-31 15:00:00', 'Newcastle United', 'Stoke City', 0, 0, 2),
(676, '2015-11-01 16:00:00', 'Southampton', 'Bournemouth', 2, 0, 1),
(677, '2015-10-31 15:00:00', 'Swansea City', 'Arsenal', 0, 3, 3),
(678, '2015-11-02 20:00:00', 'Tottenham Hotspur', 'Aston Villa', 3, 1, 1),
(679, '2015-10-31 15:00:00', 'Watford', 'West Ham United', 2, 0, 1),
(680, '2015-10-31 15:00:00', 'West Bromwich Albion', 'Leicester City', 2, 3, 3),
(681, '2015-11-07 12:45:00', 'Bournemouth', 'Newcastle United', 0, 1, 3),
(682, '2015-11-08 16:00:00', 'Arsenal', 'Tottenham Hotspur', 1, 1, 2),
(683, '2015-11-08 13:30:00', 'Aston Villa', 'Manchester City', 0, 0, 2),
(684, '2015-11-07 15:00:00', 'Leicester City', 'Watford', 2, 1, 1),
(685, '2015-11-08 16:00:00', 'Liverpool', 'Crystal Palace', 1, 2, 3),
(686, '2015-11-07 15:00:00', 'Manchester United', 'West Bromwich Albion', 2, 0, 1),
(687, '2015-11-07 15:00:00', 'Norwich City', 'Swansea City', 1, 0, 1),
(688, '2015-11-07 17:30:00', 'Stoke City', 'Chelsea', 1, 0, 1),
(689, '2015-11-07 15:00:00', 'Sunderland', 'Southampton', 0, 1, 3),
(690, '2015-11-07 15:00:00', 'West Ham United', 'Everton', 1, 1, 2),
(691, '2015-11-21 15:00:00', 'Chelsea', 'Norwich City', 1, 0, 1),
(692, '2015-11-23 20:00:00', 'Crystal Palace', 'Sunderland', 0, 1, 3),
(693, '2015-11-21 15:00:00', 'Everton', 'Aston Villa', 4, 0, 1),
(694, '2015-11-21 17:30:00', 'Manchester City', 'Liverpool', 1, 4, 3),
(695, '2015-11-21 15:00:00', 'Newcastle United', 'Leicester City', 0, 3, 3),
(696, '2015-11-21 15:00:00', 'Southampton', 'Stoke City', 0, 1, 3),
(697, '2015-11-21 15:00:00', 'Swansea City', 'Bournemouth', 2, 2, 2),
(698, '2015-11-22 16:00:00', 'Tottenham Hotspur', 'West Ham United', 4, 1, 1),
(699, '2015-11-21 12:45:00', 'Watford', 'Manchester United', 1, 2, 3),
(700, '2015-11-21 15:00:00', 'West Bromwich Albion', 'Arsenal', 2, 1, 1),
(701, '2015-11-28 15:00:00', 'Bournemouth', 'Everton', 3, 3, 2),
(702, '2015-11-28 15:00:00', 'Aston Villa', 'Watford', 2, 3, 3),
(703, '2015-11-28 15:00:00', 'Crystal Palace', 'Newcastle United', 5, 1, 1),
(704, '2015-11-28 17:30:00', 'Leicester City', 'Manchester United', 1, 1, 2),
(705, '2015-11-29 16:15:00', 'Liverpool', 'Swansea City', 1, 0, 1),
(706, '2015-11-28 15:00:00', 'Manchester City', 'Southampton', 3, 1, 1),
(707, '2015-11-29 16:15:00', 'Norwich City', 'Arsenal', 1, 1, 2),
(708, '2015-11-28 15:00:00', 'Sunderland', 'Stoke City', 2, 0, 1),
(709, '2015-11-29 12:00:00', 'Tottenham Hotspur', 'Chelsea', 0, 0, 2),
(710, '2015-11-29 14:05:00', 'West Ham United', 'West Bromwich Albion', 1, 1, 2),
(711, '2015-12-05 15:00:00', 'Arsenal', 'Sunderland', 3, 1, 1),
(712, '2015-12-05 17:30:00', 'Chelsea', 'Bournemouth', 0, 1, 3),
(713, '2015-12-07 20:00:00', 'Everton', 'Crystal Palace', 1, 1, 2),
(714, '2015-12-05 15:00:00', 'Manchester United', 'West Ham United', 0, 0, 2),
(715, '2015-12-06 16:00:00', 'Newcastle United', 'Liverpool', 2, 0, 1),
(716, '2015-12-05 15:00:00', 'Southampton', 'Aston Villa', 1, 1, 2),
(717, '2015-12-05 12:45:00', 'Stoke City', 'Manchester City', 2, 0, 1),
(718, '2015-12-05 15:00:00', 'Swansea City', 'Leicester City', 0, 3, 3),
(719, '2015-12-05 15:00:00', 'Watford', 'Norwich City', 2, 0, 1),
(720, '2015-12-05 15:00:00', 'West Bromwich Albion', 'Tottenham Hotspur', 1, 1, 2),
(721, '2015-12-12 17:30:00', 'Bournemouth', 'Manchester United', NULL, NULL, NULL),
(722, '2015-12-13 13:30:00', 'Aston Villa', 'Arsenal', NULL, NULL, NULL),
(723, '2015-12-12 15:00:00', 'Crystal Palace', 'Southampton', NULL, NULL, NULL),
(724, '2015-12-14 20:00:00', 'Leicester City', 'Chelsea', NULL, NULL, NULL),
(725, '2015-12-13 16:00:00', 'Liverpool', 'West Bromwich Albion', NULL, NULL, NULL),
(726, '2015-12-12 15:00:00', 'Manchester City', 'Swansea City', NULL, NULL, NULL),
(727, '2015-12-12 12:45:00', 'Norwich City', 'Everton', NULL, NULL, NULL),
(728, '2015-12-12 15:00:00', 'Sunderland', 'Watford', NULL, NULL, NULL),
(729, '2015-12-13 16:00:00', 'Tottenham Hotspur', 'Newcastle United', NULL, NULL, NULL),
(730, '2015-12-12 15:00:00', 'West Ham United', 'Stoke City', NULL, NULL, NULL),
(731, '2015-12-19 15:00:00', 'Arsenal', 'Manchester City', NULL, NULL, NULL),
(732, '2015-12-19 15:00:00', 'Chelsea', 'Sunderland', NULL, NULL, NULL),
(733, '2015-12-19 15:00:00', 'Everton', 'Leicester City', NULL, NULL, NULL),
(734, '2015-12-19 15:00:00', 'Manchester United', 'Norwich City', NULL, NULL, NULL),
(735, '2015-12-19 15:00:00', 'Newcastle United', 'Aston Villa', NULL, NULL, NULL),
(736, '2015-12-19 15:00:00', 'Southampton', 'Tottenham Hotspur', NULL, NULL, NULL),
(737, '2015-12-19 15:00:00', 'Stoke City', 'Crystal Palace', NULL, NULL, NULL),
(738, '2015-12-19 15:00:00', 'Swansea City', 'West Ham United', NULL, NULL, NULL),
(739, '2015-12-19 15:00:00', 'Watford', 'Liverpool', NULL, NULL, NULL),
(740, '2015-12-19 15:00:00', 'West Bromwich Albion', 'Bournemouth', NULL, NULL, NULL),
(741, '2015-12-26 15:00:00', 'Bournemouth', 'Crystal Palace', NULL, NULL, NULL),
(742, '2015-12-26 15:00:00', 'Aston Villa', 'West Ham United', NULL, NULL, NULL),
(743, '2015-12-26 15:00:00', 'Chelsea', 'Watford', NULL, NULL, NULL),
(744, '2015-12-26 15:00:00', 'Liverpool', 'Leicester City', NULL, NULL, NULL),
(745, '2015-12-26 15:00:00', 'Manchester City', 'Sunderland', NULL, NULL, NULL),
(746, '2015-12-26 15:00:00', 'Newcastle United', 'Everton', NULL, NULL, NULL),
(747, '2015-12-26 15:00:00', 'Southampton', 'Arsenal', NULL, NULL, NULL),
(748, '2015-12-26 15:00:00', 'Stoke City', 'Manchester United', NULL, NULL, NULL),
(749, '2015-12-26 15:00:00', 'Swansea City', 'West Bromwich Albion', NULL, NULL, NULL),
(750, '2015-12-26 15:00:00', 'Tottenham Hotspur', 'Norwich City', NULL, NULL, NULL),
(751, '2015-12-28 15:00:00', 'Arsenal', 'Bournemouth', NULL, NULL, NULL),
(752, '2015-12-28 15:00:00', 'Crystal Palace', 'Swansea City', NULL, NULL, NULL),
(753, '2015-12-28 15:00:00', 'Everton', 'Stoke City', NULL, NULL, NULL),
(754, '2015-12-28 15:00:00', 'Leicester City', 'Manchester City', NULL, NULL, NULL),
(755, '2015-12-28 15:00:00', 'Manchester United', 'Chelsea', NULL, NULL, NULL),
(756, '2015-12-28 15:00:00', 'Norwich City', 'Aston Villa', NULL, NULL, NULL),
(757, '2015-12-28 15:00:00', 'Sunderland', 'Liverpool', NULL, NULL, NULL),
(758, '2015-12-28 15:00:00', 'Watford', 'Tottenham Hotspur', NULL, NULL, NULL),
(759, '2015-12-28 15:00:00', 'West Bromwich Albion', 'Newcastle United', NULL, NULL, NULL),
(760, '2015-12-28 15:00:00', 'West Ham United', 'Southampton', NULL, NULL, NULL),
(761, '2018-01-27 19:00:00', 'Dublin', 'Kildare', 23, 16, 1),
(762, '2018-01-28 14:00:00', 'Kerry', 'Donegal', 24, 23, 1),
(763, '2018-01-28 14:00:00', 'Monaghan', 'Mayo', 12, 13, 3),
(764, '2018-01-28 14:30:00', 'Galway', 'Tyrone', 12, 8, 1),
(765, '2018-02-03 19:00:00', 'Mayo', 'Kerry', 15, 18, 3),
(766, '2018-02-03 19:00:00', 'Tyrone', 'Dublin', 14, 19, 3),
(767, '2018-02-04 14:00:00', 'Kildare', 'Monaghan', 12, 13, 3),
(768, '2018-02-04 14:30:00', 'Donegal', 'Galway', 14, 15, 3),
(769, '2018-02-10 19:00:00', 'Dublin', 'Donegal', 20, 15, 1),
(770, '2018-02-11 14:00:00', 'Galway', 'Mayo', 16, 11, 1),
(771, '2018-02-11 14:00:00', 'Kildare', 'Tyrone', 18, 19, 3),
(772, '2018-02-18 14:00:00', 'Monaghan', 'Kerry', 16, 14, 1),
(773, '2018-02-24 19:00:00', 'Mayo', 'Dublin', 12, 16, 3),
(774, '2018-02-24 19:00:00', 'Monaghan', 'Tyrone', 15, 14, 1),
(775, '2018-02-25 14:00:00', 'Donegal', 'Kildare', 18, 10, 1),
(776, '2018-02-25 14:30:00', 'Kerry', 'Galway', 17, 14, 1),
(777, '2018-03-11 16:00:00', 'Dublin', 'Kerry', 23, 11, 1),
(778, '2018-03-10 19:00:00', 'Tyrone', 'Donegal', 19, 13, 1),
(779, '2018-03-11 12:30:00', 'Galway', 'Monaghan', 17, 13, 1),
(780, '2018-03-11 14:00:00', 'Kildare', 'Mayo', 15, 22, 3),
(781, '2018-03-17 19:00:00', 'Mayo', 'Tyrone', 8, 20, 3),
(782, '2018-03-18 12:00:00', 'Kerry', 'Kildare', 19, 14, 1),
(783, '2018-03-18 13:00:00', 'Galway', 'Dublin', 13, 13, 2),
(784, '2018-03-18 14:00:00', 'Monaghan', 'Donegal', 19, 13, 1),
(785, '2018-03-25 15:00:00', 'Dublin', 'Monaghan', 1, 2, 3),
(786, '2018-03-25 15:00:00', 'Donegal', 'Mayo', 13, 13, 2),
(787, '2018-03-25 15:00:00', 'Kildare', 'Galway', 10, 16, 3),
(788, '2018-03-25 15:00:00', 'Tyrone', 'Kerry', 3, 4, 3),
(789, '0000-00-00 00:00:00', 'Aston Villa', 'Arsenal', NULL, NULL, NULL),
(790, '0000-00-00 00:00:00', 'Burnley', 'Brighton', NULL, NULL, NULL),
(791, '0000-00-00 00:00:00', 'Newcastle', 'Southampton', NULL, NULL, NULL),
(792, '0000-00-00 00:00:00', 'Fulham', 'West Ham', NULL, NULL, NULL),
(793, '0000-00-00 00:00:00', 'Man Utd', 'Everton', NULL, NULL, NULL),
(794, '0000-00-00 00:00:00', 'Spurs', 'West Brom', NULL, NULL, NULL),
(795, '0000-00-00 00:00:00', 'Wolves', 'Leicester', NULL, NULL, NULL),
(796, '0000-00-00 00:00:00', 'Liverpool', 'Man City', NULL, NULL, NULL),
(797, '0000-00-00 00:00:00', 'Sheffield Utd', 'Chelsea', NULL, NULL, NULL),
(798, '0000-00-00 00:00:00', 'Leeds', 'Crystal Palace', NULL, NULL, NULL),
(799, '0000-00-00 00:00:00', 'Leicester', 'Liverpool', NULL, NULL, NULL),
(800, '0000-00-00 00:00:00', 'Crystal Palace', 'Burnley', NULL, NULL, NULL),
(801, '0000-00-00 00:00:00', 'Man City', 'Spurs', NULL, NULL, NULL),
(802, '0000-00-00 00:00:00', 'Brighton', 'Aston Villa', NULL, NULL, NULL),
(803, '0000-00-00 00:00:00', 'Southampton', 'Wolves', NULL, NULL, NULL),
(804, '0000-00-00 00:00:00', 'West Brom', 'Man Utd', NULL, NULL, NULL),
(805, '0000-00-00 00:00:00', 'Arsenal', 'Leeds', NULL, NULL, NULL),
(806, '0000-00-00 00:00:00', 'Everton', 'Fulham', NULL, NULL, NULL),
(807, '0000-00-00 00:00:00', 'West Ham', 'Sheffield Utd', NULL, NULL, NULL),
(808, '0000-00-00 00:00:00', 'Chelsea', 'Newcastle', NULL, NULL, NULL),
(809, '0000-00-00 00:00:00', 'Wolves', 'Leeds', NULL, NULL, NULL),
(810, '0000-00-00 00:00:00', 'Southampton', 'Chelsea', NULL, NULL, NULL),
(811, '0000-00-00 00:00:00', 'Burnley', 'West Brom', NULL, NULL, NULL),
(812, '0000-00-00 00:00:00', 'Liverpool', 'Everton', NULL, NULL, NULL),
(813, '0000-00-00 00:00:00', 'Fulham', 'Sheffield Utd', NULL, NULL, NULL),
(814, '0000-00-00 00:00:00', 'West Ham', 'Spurs', NULL, NULL, NULL),
(815, '0000-00-00 00:00:00', 'Aston Villa', 'Leicester', NULL, NULL, NULL),
(816, '0000-00-00 00:00:00', 'Arsenal', 'Man City', NULL, NULL, NULL),
(817, '0000-00-00 00:00:00', 'Man Utd', 'Newcastle', NULL, NULL, NULL),
(818, '0000-00-00 00:00:00', 'Brighton', 'Crystal Palace', NULL, NULL, NULL),
(819, '0000-00-00 00:00:00', 'Man City', 'West Ham', NULL, NULL, NULL),
(820, '0000-00-00 00:00:00', 'West Brom', 'Brighton', NULL, NULL, NULL),
(821, '0000-00-00 00:00:00', 'Leeds', 'Aston Villa', NULL, NULL, NULL),
(822, '0000-00-00 00:00:00', 'Newcastle', 'Wolves', NULL, NULL, NULL),
(823, '0000-00-00 00:00:00', 'Crystal Palace', 'Fulham', NULL, NULL, NULL),
(824, '0000-00-00 00:00:00', 'Leicester', 'Arsenal', NULL, NULL, NULL),
(825, '0000-00-00 00:00:00', 'Spurs', 'Burnley', NULL, NULL, NULL),
(826, '0000-00-00 00:00:00', 'Chelsea', 'Man Utd', NULL, NULL, NULL),
(827, '0000-00-00 00:00:00', 'Sheffield Utd', 'Liverpool', NULL, NULL, NULL),
(828, '0000-00-00 00:00:00', 'Everton', 'Southampton', NULL, NULL, NULL),
(829, '0000-00-00 00:00:00', 'Aston Villa', 'Wolves', NULL, NULL, NULL),
(830, '0000-00-00 00:00:00', 'Brighton', 'Leicester', NULL, NULL, NULL),
(831, '0000-00-00 00:00:00', 'Burnley', 'Arsenal', NULL, NULL, NULL),
(832, '0000-00-00 00:00:00', 'Chelsea', 'Everton', NULL, NULL, NULL),
(833, '0000-00-00 00:00:00', 'Liverpool', 'Fulham', NULL, NULL, NULL),
(834, '0000-00-00 00:00:00', 'Man City', 'Man Utd', NULL, NULL, NULL),
(835, '0000-00-00 00:00:00', 'Sheffield Utd', 'Southampton', NULL, NULL, NULL),
(836, '0000-00-00 00:00:00', 'Spurs', 'Crystal Palace', NULL, NULL, NULL),
(837, '0000-00-00 00:00:00', 'West Brom', 'Newcastle', NULL, NULL, NULL),
(838, '0000-00-00 00:00:00', 'West Ham', 'Leeds', NULL, NULL, NULL),
(839, '0000-00-00 00:00:00', 'Arsenal', 'Spurs', NULL, NULL, NULL),
(840, '0000-00-00 00:00:00', 'Crystal Palace', 'West Brom', NULL, NULL, NULL),
(841, '0000-00-00 00:00:00', 'Everton', 'Burnley', NULL, NULL, NULL),
(842, '0000-00-00 00:00:00', 'Fulham', 'Man City', NULL, NULL, NULL),
(843, '0000-00-00 00:00:00', 'Leeds', 'Chelsea', NULL, NULL, NULL),
(844, '0000-00-00 00:00:00', 'Leicester', 'Sheffield Utd', NULL, NULL, NULL),
(845, '0000-00-00 00:00:00', 'Man Utd', 'West Ham', NULL, NULL, NULL),
(846, '0000-00-00 00:00:00', 'Newcastle', 'Aston Villa', NULL, NULL, NULL),
(847, '0000-00-00 00:00:00', 'Southampton', 'Brighton', NULL, NULL, NULL),
(848, '0000-00-00 00:00:00', 'Wolves', 'Liverpool', NULL, NULL, NULL),
(849, '0000-00-00 00:00:00', 'Brighton', 'Newcastle', NULL, NULL, NULL),
(850, '0000-00-00 00:00:00', 'Burnley', 'Leicester', NULL, NULL, NULL),
(851, '0000-00-00 00:00:00', 'Crystal Palace', 'Man Utd', NULL, NULL, NULL),
(852, '0000-00-00 00:00:00', 'Fulham', 'Leeds', NULL, NULL, NULL),
(853, '0000-00-00 00:00:00', 'Liverpool', 'Chelsea', NULL, NULL, NULL),
(854, '0000-00-00 00:00:00', 'Man City', 'Wolves', NULL, NULL, NULL),
(855, '0000-00-00 00:00:00', 'Sheffield Utd', 'Aston Villa', NULL, NULL, NULL),
(856, '0000-00-00 00:00:00', 'Spurs', 'Southampton', NULL, NULL, NULL),
(857, '0000-00-00 00:00:00', 'West Brom', 'Everton', NULL, NULL, NULL),
(858, '0000-00-00 00:00:00', 'West Ham', 'Arsenal', NULL, NULL, NULL),
(859, '0000-00-00 00:00:00', 'Arsenal', 'Liverpool', NULL, NULL, NULL),
(860, '0000-00-00 00:00:00', 'Aston Villa', 'Fulham', NULL, NULL, NULL),
(861, '0000-00-00 00:00:00', 'Chelsea', 'West Brom', NULL, NULL, NULL),
(862, '0000-00-00 00:00:00', 'Everton', 'Crystal Palace', NULL, NULL, NULL),
(863, '0000-00-00 00:00:00', 'Leeds', 'Sheffield Utd', NULL, NULL, NULL),
(864, '0000-00-00 00:00:00', 'Leicester', 'Man City', NULL, NULL, NULL),
(865, '0000-00-00 00:00:00', 'Man Utd', 'Brighton', NULL, NULL, NULL),
(866, '0000-00-00 00:00:00', 'Newcastle', 'Spurs', NULL, NULL, NULL),
(867, '0000-00-00 00:00:00', 'Southampton', 'Burnley', NULL, NULL, NULL),
(868, '0000-00-00 00:00:00', 'Wolves', 'West Ham', NULL, NULL, NULL),
(869, '0000-00-00 00:00:00', 'Brighton', 'Everton', NULL, NULL, NULL),
(870, '0000-00-00 00:00:00', 'Burnley', 'Newcastle', NULL, NULL, NULL),
(871, '0000-00-00 00:00:00', 'Crystal Palace', 'Chelsea', NULL, NULL, NULL),
(872, '0000-00-00 00:00:00', 'Fulham', 'Wolves', NULL, NULL, NULL),
(873, '0000-00-00 00:00:00', 'Liverpool', 'Aston Villa', NULL, NULL, NULL),
(874, '0000-00-00 00:00:00', 'Man City', 'Leeds', NULL, NULL, NULL),
(875, '0000-00-00 00:00:00', 'Sheffield Utd', 'Arsenal', NULL, NULL, NULL),
(876, '0000-00-00 00:00:00', 'Spurs', 'Man Utd', NULL, NULL, NULL),
(877, '0000-00-00 00:00:00', 'West Brom', 'Southampton', NULL, NULL, NULL),
(878, '0000-00-00 00:00:00', 'West Ham', 'Leicester', NULL, NULL, NULL),
(879, '0000-00-00 00:00:00', 'Arsenal', 'Fulham', NULL, NULL, NULL),
(880, '0000-00-00 00:00:00', 'Aston Villa', 'Man City', NULL, NULL, NULL),
(881, '0000-00-00 00:00:00', 'Chelsea', 'Brighton', NULL, NULL, NULL),
(882, '0000-00-00 00:00:00', 'Everton', 'Spurs', NULL, NULL, NULL),
(883, '0000-00-00 00:00:00', 'Leeds', 'Liverpool', NULL, NULL, NULL),
(884, '0000-00-00 00:00:00', 'Leicester', 'West Brom', NULL, NULL, NULL),
(885, '0000-00-00 00:00:00', 'Man Utd', 'Burnley', NULL, NULL, NULL),
(886, '0000-00-00 00:00:00', 'Newcastle', 'West Ham', NULL, NULL, NULL),
(887, '0000-00-00 00:00:00', 'Southampton', 'Crystal Palace', NULL, NULL, NULL),
(888, '0000-00-00 00:00:00', 'Wolves', 'Sheffield Utd', NULL, NULL, NULL),
(889, '0000-00-00 00:00:00', 'Arsenal', 'Everton', NULL, NULL, NULL),
(890, '0000-00-00 00:00:00', 'Aston Villa', 'West Brom', NULL, NULL, NULL),
(891, '0000-00-00 00:00:00', 'Fulham', 'Spurs', NULL, NULL, NULL),
(892, '0000-00-00 00:00:00', 'Leeds', 'Man Utd', NULL, NULL, NULL),
(893, '0000-00-00 00:00:00', 'Leicester', 'Crystal Palace', NULL, NULL, NULL),
(894, '0000-00-00 00:00:00', 'Liverpool', 'Newcastle', NULL, NULL, NULL),
(895, '0000-00-00 00:00:00', 'Man City', 'Southampton', NULL, NULL, NULL),
(896, '0000-00-00 00:00:00', 'Sheffield Utd', 'Brighton', NULL, NULL, NULL),
(897, '0000-00-00 00:00:00', 'West Ham', 'Chelsea', NULL, NULL, NULL),
(898, '0000-00-00 00:00:00', 'Wolves', 'Burnley', NULL, NULL, NULL),
(899, '0000-00-00 00:00:00', 'Brighton', 'Leeds', NULL, NULL, NULL),
(900, '0000-00-00 00:00:00', 'Burnley', 'West Ham', NULL, NULL, NULL),
(901, '0000-00-00 00:00:00', 'Chelsea', 'Fulham', NULL, NULL, NULL),
(902, '0000-00-00 00:00:00', 'Crystal Palace', 'Man City', NULL, NULL, NULL),
(903, '0000-00-00 00:00:00', 'Everton', 'Aston Villa', NULL, NULL, NULL),
(904, '0000-00-00 00:00:00', 'Man Utd', 'Liverpool', NULL, NULL, NULL),
(905, '0000-00-00 00:00:00', 'Newcastle', 'Arsenal', NULL, NULL, NULL),
(906, '0000-00-00 00:00:00', 'Southampton', 'Leicester', NULL, NULL, NULL);
INSERT INTO `fixtureresults_archive` (`FixtureId`, `KickOffTime`, `HomeTeam`, `AwayTeam`, `HomeTeamScore`, `AwayTeamScore`, `Result`) VALUES
(907, '0000-00-00 00:00:00', 'Spurs', 'Sheffield Utd', NULL, NULL, NULL),
(908, '0000-00-00 00:00:00', 'West Brom', 'Wolves', NULL, NULL, NULL),
(909, '0000-00-00 00:00:00', 'Arsenal', 'West Brom', NULL, NULL, NULL),
(910, '0000-00-00 00:00:00', 'Aston Villa', 'Man Utd', NULL, NULL, NULL),
(911, '0000-00-00 00:00:00', 'Fulham', 'Burnley', NULL, NULL, NULL),
(912, '0000-00-00 00:00:00', 'Leeds', 'Spurs', NULL, NULL, NULL),
(913, '0000-00-00 00:00:00', 'Leicester', 'Newcastle', NULL, NULL, NULL),
(914, '0000-00-00 00:00:00', 'Liverpool', 'Southampton', NULL, NULL, NULL),
(915, '0000-00-00 00:00:00', 'Man City', 'Chelsea', NULL, NULL, NULL),
(916, '0000-00-00 00:00:00', 'Sheffield Utd', 'Crystal Palace', NULL, NULL, NULL),
(917, '0000-00-00 00:00:00', 'West Ham', 'Everton', NULL, NULL, NULL),
(918, '0000-00-00 00:00:00', 'Wolves', 'Brighton', NULL, NULL, NULL),
(919, '0000-00-00 00:00:00', 'Brighton', 'West Ham', NULL, NULL, NULL),
(920, '0000-00-00 00:00:00', 'Burnley', 'Leeds', NULL, NULL, NULL),
(921, '0000-00-00 00:00:00', 'Everton', 'Sheffield Utd', NULL, NULL, NULL),
(922, '0000-00-00 00:00:00', 'Man Utd', 'Leicester', NULL, NULL, NULL),
(923, '0000-00-00 00:00:00', 'West Brom', 'Liverpool', NULL, NULL, NULL),
(924, '0000-00-00 00:00:00', 'Crystal Palace', 'Aston Villa', NULL, NULL, NULL),
(925, '0000-00-00 00:00:00', 'Chelsea', 'Arsenal', NULL, NULL, NULL),
(926, '0000-00-00 00:00:00', 'Newcastle', 'Man City', NULL, NULL, NULL),
(927, '0000-00-00 00:00:00', 'Southampton', 'Fulham', NULL, NULL, NULL),
(928, '0000-00-00 00:00:00', 'Spurs', 'Wolves', NULL, NULL, NULL),
(929, '0000-00-00 00:00:00', 'Brighton', 'Man City', NULL, NULL, NULL),
(930, '0000-00-00 00:00:00', 'Burnley', 'Liverpool', NULL, NULL, NULL),
(931, '0000-00-00 00:00:00', 'Chelsea', 'Leicester', NULL, NULL, NULL),
(932, '0000-00-00 00:00:00', 'Crystal Palace', 'Arsenal', NULL, NULL, NULL),
(933, '0000-00-00 00:00:00', 'Everton', 'Wolves', NULL, NULL, NULL),
(934, '0000-00-00 00:00:00', 'Man Utd', 'Fulham', NULL, NULL, NULL),
(935, '0000-00-00 00:00:00', 'Newcastle', 'Sheffield Utd', NULL, NULL, NULL),
(936, '0000-00-00 00:00:00', 'Southampton', 'Leeds', NULL, NULL, NULL),
(937, '0000-00-00 00:00:00', 'Spurs', 'Aston Villa', NULL, NULL, NULL),
(938, '0000-00-00 00:00:00', 'West Brom', 'West Ham', NULL, NULL, NULL),
(939, '0000-00-00 00:00:00', 'Arsenal', 'Brighton', NULL, NULL, NULL),
(940, '0000-00-00 00:00:00', 'Aston Villa', 'Chelsea', NULL, NULL, NULL),
(941, '0000-00-00 00:00:00', 'Fulham', 'Newcastle', NULL, NULL, NULL),
(942, '0000-00-00 00:00:00', 'Leeds', 'West Brom', NULL, NULL, NULL),
(943, '0000-00-00 00:00:00', 'Leicester', 'Spurs', NULL, NULL, NULL),
(944, '0000-00-00 00:00:00', 'Liverpool', 'Crystal Palace', NULL, NULL, NULL),
(945, '0000-00-00 00:00:00', 'Man City', 'Everton', NULL, NULL, NULL),
(946, '0000-00-00 00:00:00', 'Sheffield Utd', 'Burnley', NULL, NULL, NULL),
(947, '0000-00-00 00:00:00', 'West Ham', 'Southampton', NULL, NULL, NULL),
(948, '0000-00-00 00:00:00', 'Wolves', 'Man Utd', NULL, NULL, NULL),
(1109, '2021-02-06 12:30:00', 'Aston Villa', 'Arsenal', 1, 0, 1),
(1110, '2021-02-06 15:00:00', 'Burnley', 'Brighton', 1, 1, 2),
(1111, '2021-02-06 15:00:00', 'Newcastle', 'Southampton', 3, 2, 1),
(1112, '2021-02-06 17:30:00', 'Fulham', 'West Ham', 0, 0, 2),
(1113, '2021-02-06 20:00:00', 'Man Utd', 'Everton', 3, 3, 2),
(1114, '2021-02-07 12:00:00', 'Spurs', 'West Brom', 2, 0, 1),
(1115, '2021-02-07 14:00:00', 'Wolves', 'Leicester', 0, 0, 2),
(1116, '2021-02-07 16:30:00', 'Liverpool', 'Man City', 1, 4, 3),
(1117, '2021-02-07 19:15:00', 'Sheffield Utd', 'Chelsea', 1, 2, 3),
(1118, '2021-02-08 20:00:00', 'Leeds', 'Crystal Palace', 2, 0, 1),
(1119, '2021-02-13 12:30:00', 'Leicester', 'Liverpool', 3, 1, 1),
(1120, '2021-02-13 15:00:00', 'Crystal Palace', 'Burnley', 0, 3, 3),
(1121, '2021-02-13 17:30:00', 'Man City', 'Spurs', 3, 0, 1),
(1122, '2021-02-13 20:00:00', 'Brighton', 'Aston Villa', 0, 0, 2),
(1123, '2021-02-14 12:00:00', 'Southampton', 'Wolves', 1, 2, 3),
(1124, '2021-02-14 14:00:00', 'West Brom', 'Man Utd', 1, 1, 2),
(1125, '2021-02-14 16:30:00', 'Arsenal', 'Leeds', 4, 2, 1),
(1126, '2021-02-14 19:00:00', 'Everton', 'Fulham', 0, 2, 3),
(1127, '2021-02-15 18:00:00', 'West Ham', 'Sheffield Utd', 3, 0, 1),
(1128, '2021-02-15 20:00:00', 'Chelsea', 'Newcastle', 2, 0, 1),
(1129, '2021-02-19 20:00:00', 'Wolves', 'Leeds', 1, 0, 1),
(1130, '2021-02-20 12:30:00', 'Southampton', 'Chelsea', 1, 1, 2),
(1131, '2021-02-20 15:00:00', 'Burnley', 'West Brom', 0, 0, 2),
(1132, '2021-02-20 17:30:00', 'Liverpool', 'Everton', 0, 2, 3),
(1133, '2021-02-20 20:00:00', 'Fulham', 'Sheffield Utd', 1, 0, 1),
(1134, '2021-02-21 12:00:00', 'West Ham', 'Spurs', 2, 1, 1),
(1135, '2021-02-21 14:00:00', 'Aston Villa', 'Leicester', 1, 2, 3),
(1136, '2021-02-21 16:30:00', 'Arsenal', 'Man City', 0, 1, 3),
(1137, '2021-02-21 19:00:00', 'Man Utd', 'Newcastle', 3, 1, 1),
(1138, '2021-02-22 20:00:00', 'Brighton', 'Crystal Palace', 1, 2, 3),
(1139, '2021-02-27 12:30:00', 'Man City', 'West Ham', 2, 1, 1),
(1140, '2021-02-27 15:00:00', 'West Brom', 'Brighton', 1, 0, 1),
(1141, '2021-02-27 17:30:00', 'Leeds', 'Aston Villa', 0, 1, 3),
(1142, '2021-02-27 20:00:00', 'Newcastle', 'Wolves', 1, 1, 2),
(1143, '2021-02-28 12:00:00', 'Crystal Palace', 'Fulham', 0, 0, 2),
(1144, '2021-02-28 12:00:00', 'Leicester', 'Arsenal', 1, 3, 3),
(1145, '2021-02-28 14:00:00', 'Spurs', 'Burnley', 4, 0, 1),
(1146, '2021-02-28 16:30:00', 'Chelsea', 'Man Utd', 0, 0, 2),
(1147, '2021-02-28 19:15:00', 'Sheffield Utd', 'Liverpool', 0, 2, 3),
(1148, '2021-03-01 20:00:00', 'Everton', 'Southampton', 1, 0, 1),
(1149, '2021-03-06 17:30:00', 'Aston Villa', 'Wolves', 0, 0, 2),
(1150, '2021-03-06 20:00:00', 'Brighton', 'Leicester', 1, 2, 3),
(1151, '2021-03-06 12:30:00', 'Burnley', 'Arsenal', 1, 1, 2),
(1152, '2021-03-08 18:00:00', 'Chelsea', 'Everton', 2, 0, 1),
(1153, '2021-03-07 14:00:00', 'Liverpool', 'Fulham', 0, 1, 3),
(1154, '2021-03-07 16:30:00', 'Man City', 'Man Utd', 0, 2, 3),
(1155, '2021-03-06 15:00:00', 'Sheffield Utd', 'Southampton', 0, 2, 3),
(1156, '2021-03-07 19:15:00', 'Spurs', 'Crystal Palace', 4, 1, 1),
(1157, '2021-03-07 12:00:00', 'West Brom', 'Newcastle', 0, 0, 2),
(1158, '2021-03-08 20:00:00', 'West Ham', 'Leeds', 2, 0, 1),
(1159, '2021-03-14 16:30:00', 'Arsenal', 'Spurs', 0, 1, 3),
(1160, '2021-03-13 15:00:00', 'Crystal Palace', 'West Brom', 1, 0, 1),
(1161, '2021-03-13 17:30:00', 'Everton', 'Burnley', 1, 2, 3),
(1162, '2021-03-13 20:00:00', 'Fulham', 'Man City', 0, 3, 3),
(1163, '2021-03-13 12:30:00', 'Leeds', 'Chelsea', 0, 0, 2),
(1164, '2021-03-14 14:00:00', 'Leicester', 'Sheffield Utd', 5, 0, 1),
(1165, '2021-03-14 19:15:00', 'Man Utd', 'West Ham', 1, 0, 1),
(1166, '2021-03-12 20:00:00', 'Newcastle', 'Aston Villa', 1, 1, 2),
(1167, '2021-03-14 12:00:00', 'Southampton', 'Brighton', 1, 2, 3),
(1168, '2021-03-15 20:00:00', 'Wolves', 'Liverpool', 0, 1, 3),
(1169, '2021-03-20 15:00:00', 'Brighton', 'Newcastle', 3, 0, 1),
(1170, '2021-03-20 15:00:00', 'Burnley', 'Leicester', NULL, NULL, NULL),
(1171, '2021-03-20 15:00:00', 'Crystal Palace', 'Man Utd', NULL, NULL, NULL),
(1172, '2021-03-20 15:00:00', 'Fulham', 'Leeds', 1, 2, 3),
(1173, '2021-03-20 15:00:00', 'Liverpool', 'Chelsea', NULL, NULL, NULL),
(1174, '2021-03-20 15:00:00', 'Man City', 'Wolves', NULL, NULL, NULL),
(1175, '2021-03-20 15:00:00', 'Sheffield Utd', 'Aston Villa', NULL, NULL, NULL),
(1176, '2021-03-20 15:00:00', 'Spurs', 'Southampton', NULL, NULL, NULL),
(1177, '2021-03-20 15:00:00', 'West Brom', 'Everton', NULL, NULL, NULL),
(1178, '2021-03-20 15:00:00', 'West Ham', 'Arsenal', NULL, NULL, NULL),
(1179, '2021-04-03 15:00:00', 'Arsenal', 'Liverpool', NULL, NULL, NULL),
(1180, '2021-04-03 15:00:00', 'Aston Villa', 'Fulham', NULL, NULL, NULL),
(1181, '2021-04-03 15:00:00', 'Chelsea', 'West Brom', NULL, NULL, NULL),
(1182, '2021-04-03 15:00:00', 'Everton', 'Crystal Palace', NULL, NULL, NULL),
(1183, '2021-04-03 15:00:00', 'Leeds', 'Sheffield Utd', NULL, NULL, NULL),
(1184, '2021-04-03 15:00:00', 'Leicester', 'Man City', NULL, NULL, NULL),
(1185, '2021-04-03 15:00:00', 'Man Utd', 'Brighton', NULL, NULL, NULL),
(1186, '2021-04-03 15:00:00', 'Newcastle', 'Spurs', NULL, NULL, NULL),
(1187, '2021-04-03 15:00:00', 'Southampton', 'Burnley', NULL, NULL, NULL),
(1188, '2021-04-03 15:00:00', 'Wolves', 'West Ham', NULL, NULL, NULL),
(1189, '2021-04-10 15:00:00', 'Brighton', 'Everton', NULL, NULL, NULL),
(1190, '2021-04-10 15:00:00', 'Burnley', 'Newcastle', NULL, NULL, NULL),
(1191, '2021-04-10 15:00:00', 'Crystal Palace', 'Chelsea', NULL, NULL, NULL),
(1192, '2021-04-10 15:00:00', 'Fulham', 'Wolves', NULL, NULL, NULL),
(1193, '2021-04-10 15:00:00', 'Liverpool', 'Aston Villa', NULL, NULL, NULL),
(1194, '2021-04-10 15:00:00', 'Man City', 'Leeds', NULL, NULL, NULL),
(1195, '2021-04-10 15:00:00', 'Sheffield Utd', 'Arsenal', NULL, NULL, NULL),
(1196, '2021-04-10 15:00:00', 'Spurs', 'Man Utd', NULL, NULL, NULL),
(1197, '2021-04-10 15:00:00', 'West Brom', 'Southampton', NULL, NULL, NULL),
(1198, '2021-04-10 15:00:00', 'West Ham', 'Leicester', NULL, NULL, NULL),
(1199, '2021-04-17 15:00:00', 'Arsenal', 'Fulham', NULL, NULL, NULL),
(1200, '2021-04-17 15:00:00', 'Aston Villa', 'Man City', NULL, NULL, NULL),
(1201, '2021-04-17 15:00:00', 'Chelsea', 'Brighton', NULL, NULL, NULL),
(1202, '2021-04-17 15:00:00', 'Everton', 'Spurs', NULL, NULL, NULL),
(1203, '2021-04-17 15:00:00', 'Leeds', 'Liverpool', NULL, NULL, NULL),
(1204, '2021-04-17 15:00:00', 'Leicester', 'West Brom', NULL, NULL, NULL),
(1205, '2021-04-17 15:00:00', 'Man Utd', 'Burnley', NULL, NULL, NULL),
(1206, '2021-04-17 15:00:00', 'Newcastle', 'West Ham', NULL, NULL, NULL),
(1207, '2021-04-17 15:00:00', 'Southampton', 'Crystal Palace', NULL, NULL, NULL),
(1208, '2021-04-17 15:00:00', 'Wolves', 'Sheffield Utd', NULL, NULL, NULL),
(1209, '2021-04-24 15:00:00', 'Arsenal', 'Everton', NULL, NULL, NULL),
(1210, '2021-04-24 15:00:00', 'Aston Villa', 'West Brom', NULL, NULL, NULL),
(1211, '2021-04-24 15:00:00', 'Fulham', 'Spurs', NULL, NULL, NULL),
(1212, '2021-04-24 15:00:00', 'Leeds', 'Man Utd', NULL, NULL, NULL),
(1213, '2021-04-24 15:00:00', 'Leicester', 'Crystal Palace', NULL, NULL, NULL),
(1214, '2021-04-24 15:00:00', 'Liverpool', 'Newcastle', NULL, NULL, NULL),
(1215, '2021-04-24 15:00:00', 'Man City', 'Southampton', NULL, NULL, NULL),
(1216, '2021-04-24 15:00:00', 'Sheffield Utd', 'Brighton', NULL, NULL, NULL),
(1217, '2021-04-24 15:00:00', 'West Ham', 'Chelsea', NULL, NULL, NULL),
(1218, '2021-04-24 15:00:00', 'Wolves', 'Burnley', NULL, NULL, NULL),
(1219, '2021-05-01 15:00:00', 'Brighton', 'Leeds', NULL, NULL, NULL),
(1220, '2021-05-01 15:00:00', 'Burnley', 'West Ham', NULL, NULL, NULL),
(1221, '2021-05-01 15:00:00', 'Chelsea', 'Fulham', NULL, NULL, NULL),
(1222, '2021-05-01 15:00:00', 'Crystal Palace', 'Man City', NULL, NULL, NULL),
(1223, '2021-05-01 15:00:00', 'Everton', 'Aston Villa', NULL, NULL, NULL),
(1224, '2021-05-01 15:00:00', 'Man Utd', 'Liverpool', NULL, NULL, NULL),
(1225, '2021-05-01 15:00:00', 'Newcastle', 'Arsenal', NULL, NULL, NULL),
(1226, '2021-05-01 15:00:00', 'Southampton', 'Leicester', NULL, NULL, NULL),
(1227, '2021-05-01 15:00:00', 'Spurs', 'Sheffield Utd', NULL, NULL, NULL),
(1228, '2021-05-01 15:00:00', 'West Brom', 'Wolves', NULL, NULL, NULL),
(1229, '2021-05-08 15:00:00', 'Arsenal', 'West Brom', NULL, NULL, NULL),
(1230, '2021-05-08 15:00:00', 'Aston Villa', 'Man Utd', NULL, NULL, NULL),
(1231, '2021-05-08 15:00:00', 'Fulham', 'Burnley', NULL, NULL, NULL),
(1232, '2021-05-08 15:00:00', 'Leeds', 'Spurs', NULL, NULL, NULL),
(1233, '2021-05-08 15:00:00', 'Leicester', 'Newcastle', NULL, NULL, NULL),
(1234, '2021-05-08 15:00:00', 'Liverpool', 'Southampton', NULL, NULL, NULL),
(1235, '2021-05-08 15:00:00', 'Man City', 'Chelsea', NULL, NULL, NULL),
(1236, '2021-05-08 15:00:00', 'Sheffield Utd', 'Crystal Palace', NULL, NULL, NULL),
(1237, '2021-05-08 15:00:00', 'West Ham', 'Everton', NULL, NULL, NULL),
(1238, '2021-05-08 15:00:00', 'Wolves', 'Brighton', NULL, NULL, NULL),
(1239, '2021-05-11 19:45:00', 'Brighton', 'West Ham', NULL, NULL, NULL),
(1240, '2021-05-11 19:45:00', 'Burnley', 'Leeds', NULL, NULL, NULL),
(1241, '2021-05-11 19:45:00', 'Everton', 'Sheffield Utd', NULL, NULL, NULL),
(1242, '2021-05-11 20:00:00', 'Man Utd', 'Leicester', NULL, NULL, NULL),
(1243, '2021-05-11 20:00:00', 'West Brom', 'Liverpool', NULL, NULL, NULL),
(1244, '2021-05-11 20:00:00', 'Crystal Palace', 'Aston Villa', NULL, NULL, NULL),
(1245, '2021-05-12 19:45:00', 'Chelsea', 'Arsenal', NULL, NULL, NULL),
(1246, '2021-05-12 19:45:00', 'Newcastle', 'Man City', NULL, NULL, NULL),
(1247, '2021-05-12 19:45:00', 'Southampton', 'Fulham', NULL, NULL, NULL),
(1248, '2021-05-12 19:45:00', 'Spurs', 'Wolves', NULL, NULL, NULL),
(1249, '2021-05-15 15:00:00', 'Brighton', 'Man City', NULL, NULL, NULL),
(1250, '2021-05-15 15:00:00', 'Burnley', 'Liverpool', NULL, NULL, NULL),
(1251, '2021-05-15 15:00:00', 'Chelsea', 'Leicester', NULL, NULL, NULL),
(1252, '2021-05-15 15:00:00', 'Crystal Palace', 'Arsenal', NULL, NULL, NULL),
(1253, '2021-05-15 15:00:00', 'Everton', 'Wolves', NULL, NULL, NULL),
(1254, '2021-05-15 15:00:00', 'Man Utd', 'Fulham', NULL, NULL, NULL),
(1255, '2021-05-15 15:00:00', 'Newcastle', 'Sheffield Utd', NULL, NULL, NULL),
(1256, '2021-05-15 15:00:00', 'Southampton', 'Leeds', NULL, NULL, NULL),
(1257, '2021-05-15 15:00:00', 'Spurs', 'Aston Villa', NULL, NULL, NULL),
(1258, '2021-05-15 15:00:00', 'West Brom', 'West Ham', NULL, NULL, NULL),
(1259, '2021-05-23 16:00:00', 'Arsenal', 'Brighton', NULL, NULL, NULL),
(1260, '2021-05-23 16:00:00', 'Aston Villa', 'Chelsea', NULL, NULL, NULL),
(1261, '2021-05-23 16:00:00', 'Fulham', 'Newcastle', NULL, NULL, NULL),
(1262, '2021-05-23 16:00:00', 'Leeds', 'West Brom', NULL, NULL, NULL),
(1263, '2021-05-23 16:00:00', 'Leicester', 'Spurs', NULL, NULL, NULL),
(1264, '2021-05-23 16:00:00', 'Liverpool', 'Crystal Palace', NULL, NULL, NULL),
(1265, '2021-05-23 16:00:00', 'Man City', 'Everton', NULL, NULL, NULL),
(1266, '2021-05-23 16:00:00', 'Sheffield Utd', 'Burnley', NULL, NULL, NULL),
(1267, '2021-05-23 16:00:00', 'West Ham', 'Southampton', NULL, NULL, NULL),
(1268, '2021-05-23 16:00:00', 'Wolves', 'Man Utd', NULL, NULL, NULL),
(1189, '2021-04-12 20:15:00', 'Brighton', 'Everton', 0, 0, 2),
(1190, '2021-04-11 12:00:00', 'Burnley', 'Newcastle', 1, 2, 3),
(1191, '2021-04-10 17:30:00', 'Crystal Palace', 'Chelsea', 1, 4, 3),
(1192, '2021-04-09 20:00:00', 'Fulham', 'Wolves', 0, 1, 3),
(1193, '2021-04-10 15:00:00', 'Liverpool', 'Aston Villa', 2, 1, 1),
(1194, '2021-04-10 12:30:00', 'Man City', 'Leeds', 1, 2, 3),
(1195, '2021-04-11 19:00:00', 'Sheffield Utd', 'Arsenal', 0, 3, 3),
(1196, '2021-04-11 16:30:00', 'Spurs', 'Man Utd', 1, 3, 3),
(1197, '2021-04-12 18:00:00', 'West Brom', 'Southampton', 3, 0, 1),
(1198, '2021-04-11 14:05:00', 'West Ham', 'Leicester', 3, 2, 1),
(1199, '2021-04-18 13:30:00', 'Arsenal', 'Fulham', 1, 1, 2),
(1200, '2021-04-21 20:15:00', 'Aston Villa', 'Man City', 1, 2, 3),
(1201, '2021-04-20 20:00:00', 'Chelsea', 'Brighton', 0, 0, 2),
(1202, '2021-04-16 20:00:00', 'Everton', 'Spurs', 2, 2, 2),
(1203, '2021-04-19 20:00:00', 'Leeds', 'Liverpool', 1, 1, 2),
(1204, '2021-04-22 20:00:00', 'Leicester', 'West Brom', 3, 0, 1),
(1205, '2021-04-18 16:00:00', 'Man Utd', 'Burnley', 3, 1, 1),
(1206, '2021-04-17 12:30:00', 'Newcastle', 'West Ham', 3, 2, 1),
(1207, '2021-04-17 15:00:00', 'Southampton', 'Crystal Palace', 0, 2, 3),
(1208, '2021-04-17 20:15:00', 'Wolves', 'Sheffield Utd', 1, 0, 1),
(1209, '2021-04-24 15:00:00', 'Arsenal', 'Everton', 0, 1, 3),
(1210, '2021-04-24 15:00:00', 'Aston Villa', 'West Brom', 2, 2, 2),
(1211, '2021-04-24 15:00:00', 'Fulham', 'Spurs', 0, 1, 3),
(1212, '2021-04-24 15:00:00', 'Leeds', 'Man Utd', 0, 0, 2),
(1213, '2021-04-24 15:00:00', 'Leicester', 'Crystal Palace', 2, 1, 1),
(1214, '2021-04-24 15:00:00', 'Liverpool', 'Newcastle', 1, 1, 2),
(1215, '2021-04-24 15:00:00', 'Man City', 'Southampton', 5, 2, 1),
(1216, '2021-04-24 15:00:00', 'Sheffield Utd', 'Brighton', 1, 0, 1),
(1217, '2021-04-24 15:00:00', 'West Ham', 'Chelsea', 0, 1, 3),
(1218, '2021-04-24 15:00:00', 'Wolves', 'Burnley', 0, 4, 3),
(1219, '2021-05-01 15:00:00', 'Brighton', 'Leeds', 2, 0, 1),
(1220, '2021-05-01 15:00:00', 'Burnley', 'West Ham', 1, 2, 3),
(1221, '2021-05-01 15:00:00', 'Chelsea', 'Fulham', 2, 0, 1),
(1222, '2021-05-01 15:00:00', 'Crystal Palace', 'Man City', 0, 2, 3),
(1223, '2021-05-01 15:00:00', 'Everton', 'Aston Villa', 1, 2, 3),
(1224, '2021-05-01 15:00:00', 'Man Utd', 'Liverpool', 99, 0, 1),
(1225, '2021-05-01 15:00:00', 'Newcastle', 'Arsenal', 0, 2, 3),
(1226, '2021-05-01 15:00:00', 'Southampton', 'Leicester', 1, 1, 2),
(1227, '2021-05-01 15:00:00', 'Spurs', 'Sheffield Utd', 4, 0, 1),
(1228, '2021-05-01 15:00:00', 'West Brom', 'Wolves', 1, 1, 2),
(1229, '2021-05-09 19:00:00', 'Arsenal', 'West Brom', 3, 1, 1),
(1230, '2021-05-09 14:05:00', 'Aston Villa', 'Man Utd', 1, 3, 3),
(1231, '2021-05-10 20:00:00', 'Fulham', 'Burnley', 0, 2, 3),
(1232, '2021-05-08 12:30:00', 'Leeds', 'Spurs', 3, 1, 1),
(1233, '2021-05-07 20:00:00', 'Leicester', 'Newcastle', 2, 4, 3),
(1234, '2021-05-08 20:15:00', 'Liverpool', 'Southampton', 2, 0, 1),
(1235, '2021-05-08 17:30:00', 'Man City', 'Chelsea', 1, 2, 3),
(1236, '2021-05-08 15:00:00', 'Sheffield Utd', 'Crystal Palace', 0, 2, 3),
(1237, '2021-05-09 16:30:00', 'West Ham', 'Everton', 0, 1, 3),
(1238, '2021-05-09 12:00:00', 'Wolves', 'Brighton', 2, 1, 1),
(1239, '2021-05-15 20:00:00', 'Brighton', 'West Ham', 1, 1, 2),
(1240, '2021-05-15 12:30:00', 'Burnley', 'Leeds', 0, 4, 3),
(1241, '2021-05-16 19:00:00', 'Everton', 'Sheffield Utd', 0, 1, 3),
(1242, '2021-05-11 18:00:00', 'Man Utd', 'Leicester', 1, 2, 3),
(1243, '2021-05-16 16:30:00', 'West Brom', 'Liverpool', 1, 2, 3),
(1244, '2021-05-16 12:00:00', 'Crystal Palace', 'Aston Villa', 3, 2, 1),
(1245, '2021-05-12 20:15:00', 'Chelsea', 'Arsenal', 0, 1, 3),
(1246, '2021-05-14 20:00:00', 'Newcastle', 'Man City', 3, 4, 3),
(1247, '2021-05-15 15:00:00', 'Southampton', 'Fulham', 3, 1, 1),
(1248, '2021-05-16 14:05:00', 'Spurs', 'Wolves', 2, 0, 1),
(1249, '2021-05-18 19:00:00', 'Brighton', 'Man City', 3, 2, 1),
(1250, '2021-05-19 20:15:00', 'Burnley', 'Liverpool', 0, 3, 3),
(1251, '2021-05-18 20:15:00', 'Chelsea', 'Leicester', 2, 1, 1),
(1252, '2021-05-19 19:00:00', 'Crystal Palace', 'Arsenal', 1, 3, 3),
(1253, '2021-05-19 18:00:00', 'Everton', 'Wolves', 1, 0, 1),
(1254, '2021-05-18 18:00:00', 'Man Utd', 'Fulham', 1, 1, 2),
(1255, '2021-05-19 18:00:00', 'Newcastle', 'Sheffield Utd', 1, 0, 1),
(1256, '2021-05-18 18:00:00', 'Southampton', 'Leeds', 0, 2, 3),
(1257, '2021-05-19 18:00:00', 'Spurs', 'Aston Villa', 1, 2, 3),
(1258, '2021-05-19 20:15:00', 'West Brom', 'West Ham', 1, 3, 3),
(1259, '2021-05-23 16:00:00', 'Arsenal', 'Brighton', NULL, NULL, NULL),
(1260, '2021-05-23 16:00:00', 'Aston Villa', 'Chelsea', NULL, NULL, NULL),
(1261, '2021-05-23 16:00:00', 'Fulham', 'Newcastle', NULL, NULL, NULL),
(1262, '2021-05-23 16:00:00', 'Leeds', 'West Brom', NULL, NULL, NULL),
(1263, '2021-05-23 16:00:00', 'Leicester', 'Spurs', NULL, NULL, NULL),
(1264, '2021-05-23 16:00:00', 'Liverpool', 'Crystal Palace', NULL, NULL, NULL),
(1265, '2021-05-23 16:00:00', 'Man City', 'Everton', NULL, NULL, NULL),
(1266, '2021-05-23 16:00:00', 'Sheffield Utd', 'Burnley', NULL, NULL, NULL),
(1267, '2021-05-23 16:00:00', 'West Ham', 'Southampton', NULL, NULL, NULL),
(1268, '2021-05-23 16:00:00', 'Wolves', 'Man Utd', NULL, NULL, NULL),
(1270, '2021-05-28 19:45:00', 'Bohemians', 'Waterford', 3, 0, 1),
(1271, '2021-05-28 20:00:00', 'Finn Harps', 'Sligo Rovers', 1, 2, 3),
(1272, '2021-05-28 19:45:00', 'Drogheda United', 'Derry City', 1, 2, 3),
(1273, '2021-05-28 19:45:00', 'St. Patrick\'s Athletic', 'Dundalk', 0, 2, 3),
(1274, '2021-05-29 19:30:00', 'Longford Town', 'Shamrock Rovers', 0, 1, 3);

-- --------------------------------------------------------

--
-- Table structure for table `gameweekmap`
--

CREATE TABLE `gameweekmap` (
  `GameWeek` int(11) NOT NULL,
  `DateFrom` datetime NOT NULL,
  `DateTo` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `gameweekmap`
--

INSERT INTO `gameweekmap` (`GameWeek`, `DateFrom`, `DateTo`) VALUES
(1, '2022-08-05 19:00:00', '2022-08-07 22:20:00'),
(2, '2021-02-12 23:59:00', '2021-02-15 22:20:00'),
(3, '2021-02-19 19:00:00', '2021-02-22 22:20:00'),
(4, '2021-02-27 10:50:00', '2021-03-01 22:20:00'),
(14, '2021-05-28 18:45:00', '2021-05-29 23:00:00'),
(15, '2021-06-11 18:45:00', '2021-06-12 23:00:00'),
(27, '2021-03-06 11:30:00', '2021-03-08 22:30:00'),
(28, '2021-03-12 19:30:00', '2021-03-15 22:20:00'),
(30, '2021-04-03 11:30:00', '2021-04-05 22:30:00'),
(31, '2021-04-09 19:00:00', '2021-04-12 22:30:00'),
(32, '2021-04-16 19:00:00', '2021-04-22 22:15:00'),
(34, '2021-04-30 19:00:00', '2021-05-02 22:30:00'),
(35, '2021-05-07 19:00:00', '2021-05-10 22:30:00'),
(36, '2021-05-11 17:00:00', '2021-05-16 21:30:00'),
(37, '2021-05-18 17:00:00', '2021-05-19 22:30:00');

-- --------------------------------------------------------

--
-- Table structure for table `leagues`
--

CREATE TABLE `leagues` (
  `leagueId` int(11) NOT NULL,
  `LeagueName` varchar(50) NOT NULL,
  `LeaguePassword` varchar(10) NOT NULL,
  `LeagueDescr` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `leagues`
--

INSERT INTO `leagues` (`leagueId`, `LeagueName`, `LeaguePassword`, `LeagueDescr`) VALUES
(323, 'Intel and All', 'bollox', 'Intel Dicks'),
(555, 'Galway', 'beglin', 'Galway Dicks');

-- --------------------------------------------------------

--
-- Table structure for table `league_memberships`
--

CREATE TABLE `league_memberships` (
  `league_mem_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `league_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `league_memberships`
--

INSERT INTO `league_memberships` (`league_mem_id`, `user_id`, `league_id`) VALUES
(1, 2081, 555),
(2, 2086, 555),
(3, 2082, 555),
(4, 2079, 555),
(5, 2077, 555),
(6, 2080, 555),
(7, 2076, 555),
(8, 2078, 555),
(9, 2083, 555),
(10, 2088, 555);

-- --------------------------------------------------------

--
-- Table structure for table `passwordresettokens`
--

CREATE TABLE `passwordresettokens` (
  `idpasswordResetTokens` int(11) NOT NULL,
  `token` varchar(45) NOT NULL,
  `username` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `expiry` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `passwordresettokens`
--

INSERT INTO `passwordresettokens` (`idpasswordResetTokens`, `token`, `username`, `expiry`) VALUES
(0, '62f086da2a42b7d', 'tommygrealy', '2015-08-20 09:24:09'),
(0, '3ba22beb67586d7e', 'mjnolan', '2015-08-28 14:57:35'),
(0, '3de285a42c5e3a33', 'tommygrealy', '2015-08-28 14:57:53'),
(0, '2cfe556473a429d5', 'tommygrealy', '2015-08-28 15:01:07'),
(0, '549f544f3b75ae6f', 'tommygrealy', '2015-08-28 15:05:40'),
(0, '18bac8057daa366', 'tommygrealy', '2015-08-28 15:07:54'),
(0, '4a94da0938fc2fe9', 'tommygrealy', '2015-08-28 15:16:58'),
(0, '187a31e304b50c6', 'tommygrealy', '2015-08-28 15:19:24'),
(0, '7fad534d4f782bdc', 'jamesoneill', '2015-08-28 15:37:04'),
(0, '60ef1fbe2353c85e', 'jamesoneill', '2015-08-28 15:37:40'),
(0, '1cae80ed1fa0f37f', 'shethert', '2015-08-28 17:57:52'),
(0, '4e6c12bc38d48045', 'jamesoneill', '2015-09-11 10:19:51'),
(0, '7b7ecfe4bdbae4f', 'moeman96', '2015-09-30 18:01:41'),
(0, '51a16493477d670a', 'tonydoyle', '2015-09-24 14:10:30'),
(0, '508591dc2ebe12e6', 'tonydoyle', '2015-10-02 16:54:42'),
(0, '1bb9edcb249e9cd6', 'shethert', '2015-10-03 10:40:33'),
(0, '4841309b4608638d', 'mgrealy', '2015-10-18 05:03:38'),
(0, '798183dd5aaefe0', 'mgrealy', '2015-10-18 05:03:45'),
(0, '2602436e6f902f60', 'tommygrealy', '2016-10-21 14:15:34'),
(0, '4cd3d2ceb883580', 'jamesoneill', '2018-01-24 12:54:13'),
(0, '8f192d05d141577', 'tommygrealy', '2018-01-24 12:54:47'),
(0, '2e2db2e1a0fc9a1', 'Kris', '2018-01-25 16:10:44'),
(0, '1fdb31569870f3', 'tommygrealy', '2021-02-06 13:23:46'),
(0, '530de5522db7ec08', 'jbligh76', '2021-02-06 22:13:10'),
(0, '44ee7112783b8e09', 'test', '2021-02-09 10:36:33'),
(0, '14a85aed2cf7348', 'test', '2021-02-09 10:36:40'),
(0, '30ecb1733a42ab4', 'test', '2021-02-09 10:39:33'),
(0, '6505fb1e2f049012', 'tommygrealy', '2021-02-27 10:58:37'),
(0, 'd5d4906fbdfbde', 'tommygrealy', '2021-03-04 08:20:40'),
(0, '16c7f48f292d37b', 'Krustu', '2021-04-07 23:00:33');

-- --------------------------------------------------------

--
-- Stand-in structure for view `playingnotpaid`
--
CREATE TABLE `playingnotpaid` (
`username` varchar(255)
,`FullName` varchar(45)
,`email` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `predictions`
--

CREATE TABLE `predictions` (
  `DateTimeEntered` datetime DEFAULT NULL,
  `EntryType` varchar(10) NOT NULL,
  `PredictionID` int(11) NOT NULL,
  `GameWeek` int(11) DEFAULT NULL,
  `FixtureID` int(11) NOT NULL,
  `UserName` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `TeamName` varchar(50) DEFAULT NULL,
  `PredictedResult` int(11) NOT NULL COMMENT '1=Home Win, 3=Away Win',
  `PredictionStatus` varchar(8) NOT NULL COMMENT 'A=Active;C=Cancelled',
  `PredictionCorrect` tinyint(1) DEFAULT NULL COMMENT '1=correct, 0=incorrect, 2=Exception'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `predictions`
--

INSERT INTO `predictions` (`DateTimeEntered`, `EntryType`, `PredictionID`, `GameWeek`, `FixtureID`, `UserName`, `TeamName`, `PredictedResult`, `PredictionStatus`, `PredictionCorrect`) VALUES
('2021-05-20 10:06:22', 'MANUAL', 916, 14, 1274, 'Bort United', 'Shamrock Rovers', 3, 'A', 1),
('2021-05-20 10:21:16', 'MANUAL', 918, 14, 1270, 'LordStyxofdeNordsoide', 'Bohemians', 1, 'A', 1),
('2021-05-20 10:40:56', 'MANUAL', 919, 14, 1270, 'Hutto', 'Bohemians', 1, 'A', 1),
('2021-05-21 10:06:54', 'MANUAL', 920, 14, 1270, 'Patthing', 'Bohemians', 1, 'A', 1),
('2021-05-21 12:56:20', 'MANUAL', 921, 14, 1274, 'Krustu', 'Shamrock Rovers', 3, 'A', 1),
('2021-05-24 21:07:51', 'MANUAL', 922, 14, 1274, 'tommygrealy', 'Shamrock Rovers', 3, 'A', 1),
('2021-05-28 16:00:00', 'A', 923, 14, 1270, 'pullingmeplums69', 'Bohemians', 1, 'A', 1),
('2021-05-28 16:00:00', 'A', 924, 14, 1270, 'Mheg2021', 'Bohemians', 1, 'A', 1),
('2021-05-28 16:00:00', 'A', 925, 14, 1270, 'Matlock', 'Bohemians', 1, 'A', 1),
('2021-05-31 11:12:26', 'MANUAL', 926, 15, 1279, 'tommygrealy', 'Sligo Rovers', 1, 'A', NULL),
('2021-06-03 14:57:20', 'MANUAL', 927, 15, 1277, 'LordStyxofdeNordsoide', 'Shamrock Rovers', 1, 'A', NULL),
('2021-06-03 18:38:42', 'MANUAL', 928, 15, 1276, 'Hutto', 'Dundalk', 1, 'A', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `predictionstrash`
--

CREATE TABLE `predictionstrash` (
  `DateTimeEntered` datetime DEFAULT NULL,
  `EntryType` varchar(10) NOT NULL,
  `PredictionID` int(11) NOT NULL,
  `GameWeek` int(11) DEFAULT NULL,
  `FixtureID` int(11) NOT NULL,
  `UserName` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `TeamName` varchar(50) DEFAULT NULL,
  `PredictedResult` int(11) NOT NULL,
  `PredictionStatus` varchar(8) NOT NULL COMMENT 'C=Cancelled ; A=Active',
  `PredictionCorrect` bit(1) DEFAULT NULL COMMENT '1=correct, 0=incorrect'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `predictionstrash`
--

INSERT INTO `predictionstrash` (`DateTimeEntered`, `EntryType`, `PredictionID`, `GameWeek`, `FixtureID`, `UserName`, `TeamName`, `PredictedResult`, `PredictionStatus`, `PredictionCorrect`) VALUES
('2015-02-24 11:26:16', '', 335, 27, 286, 'tommygrealy', 'Burnley', 1, 'C', NULL),
('2015-02-24 12:56:23', '', 336, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 13:03:03', '', 337, 27, 293, 'tommygrealy', 'Southampton', 3, 'C', NULL),
('2015-02-24 13:21:40', '', 338, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 13:23:08', '', 339, 27, 288, 'tommygrealy', 'Manchester City', 3, 'C', NULL),
('2015-02-24 13:23:40', '', 340, 27, 292, 'tommygrealy', 'Hull City', 3, 'C', NULL),
('2015-02-24 14:23:17', '', 341, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:26:48', '', 342, 27, 286, 'tommygrealy', 'Swansea City', 3, 'C', NULL),
('2015-02-24 14:27:44', '', 343, 27, 290, 'tommygrealy', 'Newcastle United', 1, 'C', NULL),
('2015-02-24 14:27:50', '', 344, 27, 290, 'tommygrealy', 'Newcastle United', 1, 'C', NULL),
('2015-02-24 15:00:31', '', 345, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 15:04:48', '', 346, 27, 285, 'tommygrealy', 'Arsenal', 1, 'C', NULL),
('2015-02-24 15:08:02', '', 347, 27, 289, 'tommygrealy', 'Manchester United', 1, 'C', NULL),
('2015-02-24 15:29:09', '', 348, 27, 292, 'tommygrealy', 'Stoke City', 1, 'C', NULL),
('2015-02-24 18:48:22', '', 349, 27, 289, 'tommygrealy', 'Manchester United', 1, 'C', NULL),
('2015-02-24 19:47:07', '', 350, 27, 289, 'tommygrealy', 'Manchester United', 1, 'C', NULL),
('2015-02-24 22:32:19', '', 351, 27, 289, 'tommygrealy', 'Manchester United', 1, 'C', NULL),
('2015-03-01 21:01:00', '', 367, 28, 301, 'tommygrealy', 'Manchester City', 1, 'C', NULL),
('2015-03-02 10:13:02', '', 380, 28, 301, 'tommygrealy', 'Manchester City', 1, 'C', NULL),
('2015-04-07 09:12:00', '', 421, 32, 336, 'tommygrealy', 'Liverpool', 1, 'C', NULL),
('2015-04-07 09:16:10', '', 423, 32, 336, 'tommygrealy', 'Liverpool', 1, 'C', NULL),
('2015-04-14 09:50:31', '', 429, 33, 348, 'tommygrealy', 'Crystal Palace', 1, 'C', NULL),
('2015-04-14 10:11:07', '', 430, 33, 349, 'tommygrealy', 'Everton', 1, 'C', NULL),
('2015-04-15 11:39:49', '', 434, 33, 349, 'jamesoneill', 'Everton', 1, 'C', NULL),
('2015-05-06 14:08:17', '', 442, 36, 376, 'JohnLynch1982', 'Aston Villa', 1, 'C', NULL),
('2015-05-08 10:41:07', '', 445, 36, 380, 'jamesoneill', 'Hull City', 1, 'C', NULL),
('2015-05-18 16:26:33', '', 450, 114, 405, 'tommygrealy', 'Cork City FC', 1, 'C', NULL),
('2015-05-18 16:26:40', '', 451, 114, 405, 'tommygrealy', 'Shamrock Rovers', 3, 'C', NULL),
('2015-05-25 14:46:00', '', 453, 2, 415, 'tommygrealy', 'Limerick', 1, 'C', NULL),
('2015-06-06 12:43:55', '', 467, 3, 422, 'tommygrealy', 'St. Patrick’s Athletic', 1, 'C', NULL),
('2015-06-26 12:17:59', '', 477, 116, 429, 'tommygrealy', 'Dundalk', 1, 'C', NULL),
('2015-07-10 13:11:58', '', 487, 117, 435, 'tommygrealy', 'Cork City', 1, 'C', NULL),
('2015-08-05 09:34:15', '', 497, 118, 442, 'tommygrealy', 'Cork City', 3, 'C', NULL),
('2015-08-05 10:32:06', '', 498, 118, 442, 'tommygrealy', 'Cork City', 3, 'C', NULL),
('2015-08-15 21:57:29', '', 510, 3, 592, 'tommygrealy', 'Crystal Palace', 1, 'C', NULL),
('2015-08-15 22:02:47', '', 511, 3, 599, 'tommygrealy', 'Chelsea', 3, 'C', NULL),
('2015-08-16 09:23:29', '', 512, 3, 591, 'tommygrealy', 'Arsenal', 1, 'C', NULL),
('2015-08-16 10:07:14', '', 513, 3, 595, 'tommygrealy', 'Manchester United', 1, 'C', NULL),
('2015-08-18 09:10:15', '', 514, 3, 600, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-08-18 09:11:34', '', 515, 3, 600, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-08-18 09:16:03', '', 516, 3, 600, 'tommygrealy', 'Bournemouth', 3, 'C', NULL),
('2015-08-18 15:22:34', '', 517, 4, 607, 'tommygrealy', 'Southampton', 1, 'C', NULL),
('2015-08-18 15:59:27', '', 519, 4, 602, 'tommygrealy', 'Aston Villa', 1, 'C', NULL),
('2015-08-19 20:35:06', '', 520, 4, 603, 'tommygrealy', 'Chelsea', 1, 'C', NULL),
('2015-08-19 20:35:50', '', 521, 4, 607, 'tommygrealy', 'Southampton', 1, 'C', NULL),
('2015-08-19 21:07:39', '', 522, 4, 609, 'tommygrealy', 'Swansea City', 1, 'C', NULL),
('2015-08-19 21:08:47', '', 523, 4, 608, 'tommygrealy', 'Stoke City', 1, 'C', NULL),
('2015-08-19 21:09:36', '', 524, 4, 609, 'tommygrealy', 'Swansea City', 1, 'C', NULL),
('2015-08-19 21:11:15', '', 525, 4, 608, 'tommygrealy', 'Stoke City', 1, 'C', NULL),
('2015-08-19 21:12:07', '', 526, 4, 602, 'tommygrealy', 'Aston Villa', 1, 'C', NULL),
('2015-08-19 21:12:28', '', 527, 4, 609, 'tommygrealy', 'Manchester United', 3, 'C', NULL),
('2015-08-20 08:53:38', '', 528, 4, 607, 'tommygrealy', 'Southampton', 1, 'C', NULL),
('2015-08-20 08:57:01', '', 529, 4, 607, 'tommygrealy', 'Southampton', 1, 'C', NULL),
('2015-09-17 13:50:36', '', 557, 6, 626, 'jamesoneill', 'Newcastle United', 1, 'C', NULL),
('2015-09-29 08:57:26', '', 579, 8, 649, 'tommygrealy', 'West Ham United', 3, 'C', NULL),
('2015-10-04 19:49:42', '', 601, 9, 657, 'tommygrealy', 'Swansea City', 1, 'C', NULL),
('2015-10-04 23:22:51', '', 603, 9, 652, 'tommygrealy', 'Crystal Palace', 1, 'C', NULL),
('2015-10-05 10:21:51', 'MANUAL', 604, 9, 652, 'tommygrealy', 'West Ham United', 3, 'C', NULL),
('2015-10-06 10:08:38', 'MANUAL', 639, 9, 652, 'tommygrealy', 'Crystal Palace', 1, 'C', NULL),
('2015-10-07 10:03:46', 'MANUAL', 718, 9, 651, 'tommygrealy', 'Chelsea', 1, 'C', NULL),
('2015-10-26 23:28:46', 'MANUAL', 764, 11, 673, 'tommygrealy', 'Everton', 1, 'C', NULL),
('2018-01-25 13:52:08', 'MANUAL', 791, 1, 762, 'Jamesoneill', 'Kerry', 1, 'C', NULL),
('2018-01-25 14:06:01', 'MANUAL', 792, 1, 761, 'alanp', 'Dublin', 1, 'C', NULL),
('2018-01-25 14:38:22', 'MANUAL', 799, 1, 761, 'tommygrealy', 'Dublin', 1, 'C', NULL),
('2018-01-25 14:50:08', 'MANUAL', 800, 1, 762, 'tommygrealy', 'Kerry', 1, 'C', NULL),
('2018-01-25 15:41:51', 'MANUAL', 801, 1, 762, 'tommygrealy', 'Kerry', 1, 'C', NULL),
('2018-01-25 17:28:35', 'MANUAL', 802, 1, 764, 'tommygrealy', 'Galway', 1, 'C', NULL),
('2018-01-25 17:30:01', 'MANUAL', 803, 1, 762, 'tommygrealy', 'Kerry', 1, 'C', NULL),
('2018-01-26 13:44:56', 'MANUAL', 805, 1, 762, 'Jamesoneill', 'Kerry', 1, 'C', NULL),
('2018-01-29 16:02:15', 'MANUAL', 812, 2, 767, 'tommygrealy', 'Kildare', 1, 'C', NULL),
('2018-02-12 10:05:37', 'MANUAL', 840, 4, 775, 'tommygrealy', 'Donegal', 1, 'C', NULL),
('2018-02-25 20:53:44', 'MANUAL', 844, 5, 779, 'tommygrealy', 'Galway', 1, 'C', NULL),
('2018-02-25 21:25:26', 'MANUAL', 847, 5, 778, 'tommygrealy', 'Tyrone', 1, 'C', NULL),
('2018-03-09 10:30:53', 'MANUAL', 848, 5, 779, 'tommygrealy', 'Galway', 1, 'C', NULL),
('2018-03-13 08:41:07', 'MANUAL', 851, 6, 781, 'tommygrealy', 'Mayo', 1, 'C', NULL),
('2018-03-21 16:35:52', 'MANUAL', 854, 7, 786, 'tommygrealy', 'Donegal', 1, 'C', NULL),
('2021-02-06 14:05:04', 'MANUAL', 857, 2, 1119, 'tommygrealy', 'Leicester', 1, 'C', NULL),
('2021-02-06 18:47:19', 'MANUAL', 858, 2, 1120, 'tommygrealy', 'Crystal Palace', 1, 'C', NULL),
('2021-02-07 18:14:52', 'MANUAL', 861, 2, 1120, 'tommygrealy', 'Crystal Palace', 1, 'C', NULL),
('2021-02-08 14:18:39', 'MANUAL', 863, 2, 1119, ' Matlock', 'Leicester', 1, 'C', NULL),
('2021-02-12 16:59:27', 'MANUAL', 866, 2, 1119, 'pullingmeplums69', 'Liverpool', 3, 'C', NULL),
('2021-02-13 00:40:13', 'MANUAL', 869, 2, 1121, 'tommygrealy', 'Spurs', 3, 'C', NULL),
('2021-03-10 20:09:47', 'MANUAL', 883, 28, 1164, 'Patthing', 'Leicester', 1, 'C', NULL),
('2021-04-16 12:55:29', 'MANUAL', 899, 32, 1205, 'tommygrealy', 'Man Utd', 1, 'C', NULL),
('2021-04-22 23:34:33', 'MANUAL', 904, 34, 1223, 'tommygrealy', 'Everton', 1, 'C', NULL),
('2021-05-20 10:15:34', 'MANUAL', 917, 14, 1274, 'tommygrealy', 'Shamrock Rovers', 3, 'C', NULL),
('2022-07-30 11:23:06', 'MANUAL', 929, 1, 1337, 'tommygrealy', 'Brentford', 3, 'C', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `predictions_archive`
--

CREATE TABLE `predictions_archive` (
  `DateTimeEntered` datetime DEFAULT NULL,
  `EntryType` varchar(10) CHARACTER SET latin1 NOT NULL,
  `PredictionID` int(11) NOT NULL DEFAULT '0',
  `GameWeek` int(11) DEFAULT NULL,
  `FixtureID` int(11) NOT NULL,
  `UserName` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `TeamName` varchar(50) CHARACTER SET latin1 DEFAULT NULL,
  `PredictedResult` int(11) NOT NULL,
  `PredictionStatus` varchar(8) CHARACTER SET latin1 NOT NULL,
  `PredictionCorrect` bit(1) DEFAULT NULL COMMENT '1=correct, 0=incorrect'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `predictions_archive`
--

INSERT INTO `predictions_archive` (`DateTimeEntered`, `EntryType`, `PredictionID`, `GameWeek`, `FixtureID`, `UserName`, `TeamName`, `PredictedResult`, `PredictionStatus`, `PredictionCorrect`) VALUES
('2015-01-12 11:06:58', '', 246, 22, 243, 'tommygrealy', 'Tottenham Hotspur', 1, '', b'1'),
('2015-01-12 11:41:55', '', 247, 22, 243, 'JohnLynch1982', 'Tottenham Hotspur', 1, '', b'1'),
('2015-01-14 10:28:17', '', 248, 22, 243, 'tonydoyle', 'Tottenham Hotspur', 1, '', b'1'),
('2015-01-14 10:28:32', '', 249, 22, 244, 'monkey', 'West Ham United', 1, '', b'1'),
('2015-01-14 10:39:50', '', 250, 22, 244, 'kmacken', 'West Ham United', 1, '', b'1'),
('2015-01-14 11:23:48', '', 251, 22, 244, 'Rodge', 'West Ham United', 1, '', b'1'),
('2015-01-14 11:45:02', '', 252, 22, 244, 'declancotter', 'West Ham United', 1, '', b'1'),
('2015-01-14 15:59:53', '', 253, 22, 236, 'mjnolan', 'Burnley', 1, '', b'0'),
('2015-01-15 09:10:11', '', 254, 22, 244, 'jbligh', 'West Ham United', 1, '', b'1'),
('2015-01-15 11:06:11', '', 255, 22, 240, 'Gforde', 'Southampton', 3, '', b'1'),
('2015-01-16 14:04:43', '', 256, 22, 236, 'telordan', 'Burnley', 1, '', b'0'),
('2015-01-16 21:52:40', '', 257, 22, 242, 'shethert', 'Swansea City', 1, '', b'0'),
('2015-01-17 10:22:57', '', 258, 22, 237, 'jamesoneill', 'Everton', 1, '', b'0'),
('2015-01-20 09:26:37', '', 260, 23, 251, 'tommygrealy', 'Southampton', 1, '', b'0'),
('2015-01-20 14:00:49', '', 261, 23, 250, 'kmacken', 'Manchester United', 1, '', b'1'),
('2015-01-26 14:10:00', '', 262, 23, 250, 'tonydoyle', 'Manchester United', 1, '', b'1'),
('2015-01-26 14:25:23', '', 263, 23, 250, 'jbligh', 'Manchester United', 1, '', b'1'),
('2015-01-26 14:36:49', '', 264, 23, 245, 'declancotter', 'Arsenal', 1, '', b'1'),
('2015-01-29 10:33:16', '', 266, 23, 250, 'JohnLynch1982', 'Manchester United', 1, '', b'1'),
('2015-01-29 14:44:47', '', 267, 23, 250, 'Rodge', 'Manchester United', 1, '', b'1'),
('2015-01-29 17:11:08', '', 268, 23, 245, 'monkey', 'Arsenal', 1, '', b'1'),
('2015-01-30 11:24:46', '', 269, 23, 245, 'Gforde', 'Arsenal', 1, '', b'1'),
('2015-01-30 08:57:15', '', 270, 23, 250, 'shethert', 'Manchester United', 1, '', b'1'),
('2015-02-02 10:10:17', '', 271, 24, 259, 'JohnLynch1982', 'Manchester City', 1, '', b'0'),
('2015-02-02 23:46:44', '', 272, 24, 259, 'kmacken', 'Manchester City', 1, '', b'0'),
('2015-02-04 12:47:13', '', 273, 24, 259, 'jbligh', 'Manchester City', 1, '', b'0'),
('2015-02-05 14:08:19', '', 274, 24, 259, 'declancotter', 'Manchester City', 1, '', b'0'),
('2015-02-05 14:24:49', '', 275, 24, 259, 'Rodge', 'Manchester City', 1, '', b'0'),
('2015-02-05 14:44:32', '', 276, 24, 255, 'tonydoyle', 'Chelsea', 3, '', b'1'),
('2015-02-06 10:24:03', '', 277, 24, 259, 'Gforde', 'Manchester City', 1, '', b'0'),
('2015-02-06 10:38:27', '', 278, 24, 259, 'monkey', 'Manchester City', 1, '', b'0'),
('2015-02-07 01:28:31', '', 279, 24, 259, 'shethert', 'Manchester City', 1, '', b'0'),
('2021-02-16 09:47:24', 'MANUAL', 874, 0, 1133, ' Matlock', 'Fulham', 1, 'A', b'1'),
('2021-02-16 09:34:21', 'MANUAL', 873, 0, 1137, 'Bort United', 'Man Utd', 1, 'A', b'1'),
('2021-02-15 23:41:24', 'MANUAL', 872, 0, 1134, 'Mheg2021', 'Spurs', 3, 'A', b'0'),
('2021-02-13 00:44:55', 'MANUAL', 870, 2, 1120, 'tommygrealy', 'Crystal Palace', 1, 'A', b'0'),
('2021-02-12 22:13:40', 'MANUAL', 868, 2, 1128, 'Patthing', 'Chelsea', 1, 'A', b'1'),
('2021-02-12 16:59:47', 'MANUAL', 867, 2, 1119, 'pullingmeplums69', 'Liverpool', 3, 'A', b'0'),
('2021-02-08 22:47:06', 'MANUAL', 865, 2, 1126, 'Krustu', 'Everton', 1, 'A', b'0'),
('2021-02-08 14:20:58', 'MANUAL', 864, 2, 1128, ' Matlock', 'Chelsea', 1, 'A', b'1'),
('2021-02-08 01:23:24', 'MANUAL', 862, 2, 1128, 'Mheg2021', 'Chelsea', 1, 'A', b'1'),
('2015-03-02 08:09:29', '', 378, 28, 301, 'jamesoneill', 'Manchester City', 1, 'A', b'1'),
('2015-03-02 10:11:51', '', 379, 28, 297, 'JohnLynch1982', 'Liverpool', 1, 'A', b'1'),
('2015-03-02 10:24:04', '', 381, 28, 297, 'declancotter', 'Liverpool', 1, 'A', b'1'),
('2015-03-02 16:52:44', '', 382, 28, 301, 'kmacken', 'Manchester City', 1, 'A', b'1'),
('2015-03-02 20:45:51', '', 383, 28, 301, 'tommygrealy', 'Manchester City', 1, 'A', b'1'),
('2015-03-03 09:20:53', '', 385, 28, 297, 'Rob', 'Liverpool', 1, 'A', b'1'),
('2015-03-03 09:57:38', '', 386, 28, 301, 'Rodge', 'Manchester City', 1, 'A', b'1'),
('2015-03-03 12:28:11', '', 387, 28, 301, 'jbligh', 'Manchester City', 1, 'A', b'1'),
('2015-03-03 13:42:01', '', 388, 28, 301, 'tonydoyle', 'Manchester City', 1, 'A', b'1'),
('2015-03-03 15:46:54', '', 389, 28, 301, 'Gforde', 'Manchester City', 1, 'A', b'1'),
('2015-03-03 18:49:05', '', 390, 28, 298, 'shethert', 'Arsenal', 3, 'A', b'1'),
('2015-03-05 09:25:30', '', 391, 29, 305, 'tommygrealy', 'Arsenal', 1, 'A', b'1'),
('2015-03-05 09:56:11', '', 392, 29, 308, 'JohnLynch1982', 'Crystal Palace', 1, 'A', b'1'),
('2015-03-12 12:05:49', '', 393, 29, 305, 'jamesoneill', 'Arsenal', 1, 'A', b'1'),
('2015-03-12 14:45:04', '', 394, 29, 307, 'Rodge', 'Chelsea', 1, 'A', b'0'),
('2015-03-12 15:03:54', '', 395, 29, 310, 'Rob', 'Hull City', 3, 'A', b'0'),
('2015-03-12 23:44:49', '', 396, 29, 307, 'declancotter', 'Chelsea', 1, 'A', b'0'),
('2015-03-13 13:17:53', '', 397, 29, 308, 'kmacken', 'Crystal Palace', 1, 'A', b'1'),
('2015-03-13 13:47:28', '', 398, 29, 307, 'tonydoyle', 'Chelsea', 1, 'A', b'0'),
('2015-03-13 13:49:48', '', 404, 29, 307, 'Gforde', 'Chelsea', 1, 'A', b'0'),
('2015-03-14 10:25:15', '', 405, 29, 308, 'jbligh', 'Crystal Palace', 1, 'A', b'1'),
('2015-03-14 10:35:20', '', 409, 29, 306, 'shethert', 'Manchester City', 3, 'A', b'0'),
('2015-03-16 22:48:53', '', 410, 30, 321, 'tommygrealy', 'Southampton', 1, 'A', b'1'),
('2015-03-18 13:17:00', '', 411, 30, 318, 'JohnLynch1982', 'Manchester City', 1, 'A', b'1'),
('2015-03-20 14:16:30', '', 412, 30, 323, 'jbligh', 'Tottenham Hotspur', 1, 'A', b'1'),
('2015-03-20 14:55:07', '', 413, 30, 323, 'jamesoneill', 'Tottenham Hotspur', 1, 'A', b'1'),
('2015-03-20 15:07:57', '', 414, 30, 323, 'kmacken', 'Tottenham Hotspur', 1, 'A', b'1'),
('2015-03-23 10:22:45', '', 415, 31, 327, 'tommygrealy', 'Chelsea', 1, 'A', b'1'),
('2015-03-23 11:26:18', '', 416, 31, 331, 'JohnLynch1982', 'Manchester United', 1, 'A', b'1'),
('2015-03-26 14:50:07', '', 417, 31, 327, 'jamesoneill', 'Chelsea', 1, 'A', b'1'),
('2015-03-26 21:28:59', '', 418, 31, 327, 'kmacken', 'Chelsea', 1, 'A', b'1'),
('2015-04-04 10:45:30', '', 419, 31, 325, 'jbligh', 'Arsenal', 1, 'A', b'1'),
('2015-04-07 09:31:27', '', 424, 32, 336, 'tommygrealy', 'Liverpool', 1, 'A', b'1'),
('2015-04-10 13:19:09', '', 425, 32, 338, 'JohnLynch1982', 'Chelsea', 3, 'A', b'1'),
('2015-04-10 14:55:46', '', 426, 32, 336, 'jamesoneill', 'Liverpool', 1, 'A', b'1'),
('2015-04-10 22:53:34', '', 427, 32, 343, 'kmacken', 'West Bromwich Albion', 1, 'A', b'0'),
('2015-04-12 05:49:24', '', 428, 32, 339, 'jbligh', 'Southampton', 1, 'A', b'1'),
('2015-04-14 10:14:59', '', 431, 33, 348, 'tommygrealy', 'Crystal Palace', 1, 'A', b'0'),
('2015-04-14 11:49:09', '', 432, 33, 351, 'JohnLynch1982', 'Leicester City', 1, 'A', b'1'),
('2015-04-14 15:41:47', '', 433, 33, 349, 'jbligh', 'Everton', 1, 'A', b'1'),
('2015-04-15 11:40:13', '', 435, 33, 349, 'jamesoneill', 'Everton', 1, 'A', b'1'),
('2015-04-20 11:39:31', '', 436, 34, 361, 'JohnLynch1982', 'Queens Park Rangers', 1, 'A', b'0'),
('2015-04-24 13:29:26', '', 437, 34, 360, 'jamesoneill', 'Newcastle United', 1, 'A', b'0'),
('2015-04-24 13:36:57', '', 438, 34, 356, 'jbligh', 'Burnley', 1, 'A', b'0'),
('2015-04-27 14:56:14', '', 439, 35, 367, 'JohnLynch1982', 'Arsenal', 3, 'A', b'1'),
('2015-04-29 10:18:34', '', 440, 35, 371, 'jamesoneill', 'Sunderland', 1, 'A', b'1'),
('2015-04-30 09:31:59', '', 441, 35, 366, 'jbligh', 'Chelsea', 1, 'A', b'1'),
('2015-05-06 14:08:38', '', 443, 36, 376, 'JohnLynch1982', 'Aston Villa', 1, 'A', b'1'),
('2015-05-08 09:39:54', '', 444, 36, 376, 'jbligh', 'Aston Villa', 1, 'A', b'1'),
('2015-05-08 14:04:21', '', 447, 36, 380, 'jamesoneill', 'Hull City', 1, 'A', b'0'),
('2015-05-14 21:03:49', '', 448, 37, 392, 'JohnLynch1982', 'Tottenham Hotspur', 1, 'A', b'1'),
('2015-05-15 14:41:50', '', 449, 37, 386, 'jbligh', 'Liverpool', 1, 'A', b'0'),
('2015-06-03 09:03:34', '', 454, 2, 416, 'JohnLynch1982', 'Shamrock Rovers', 1, 'A', b'1'),
('2015-06-03 10:13:56', '', 455, 2, 416, 'declancotter', 'Shamrock Rovers', 1, 'A', b'1'),
('2015-06-03 13:19:28', '', 456, 2, 411, 'tommygrealy', 'Longford Town', 3, 'A', b'1'),
('2015-06-04 11:57:55', '', 457, 2, 416, 'jamesoneill', 'Shamrock Rovers', 1, 'A', b'1'),
('2015-06-04 16:33:56', '', 458, 2, 414, 'kmacken', 'Dundalk', 1, 'A', b'0'),
('2015-06-04 16:46:22', '', 459, 2, 416, 'monkey', 'Shamrock Rovers', 1, 'A', b'1'),
('2015-06-05 08:41:28', '', 460, 2, 414, 'jbligh', 'Dundalk', 1, 'A', b'0'),
('2015-06-05 09:00:44', '', 461, 2, 416, 'markr', 'Shamrock Rovers', 1, 'A', b'1'),
('2015-06-05 10:27:39', '', 462, 2, 414, 'Rodge', 'Dundalk', 1, 'A', b'0'),
('2015-06-05 10:29:00', '', 463, 2, 415, 'telordan', 'Drogheda United', 3, 'A', b'1'),
('2015-06-05 10:52:27', '', 464, 2, 416, 'tonydoyle', 'Shamrock Rovers', 1, 'A', b'1'),
('2015-06-05 11:07:53', '', 465, 2, 416, 'Rob', 'Shamrock Rovers', 1, 'A', b'1'),
('2015-06-05 11:50:45', '', 466, 2, 414, 'Gforde', 'Dundalk', 1, 'A', b'0'),
('2015-06-06 17:29:07', '', 468, 3, 422, 'tommygrealy', 'St. Patrick’s Athletic', 1, 'A', b'1'),
('2015-06-08 10:14:37', '', 469, 3, 420, 'tonydoyle', 'Cork City', 1, 'A', b'1'),
('2015-06-09 23:02:18', '', 470, 3, 422, 'declancotter', 'St. Patrick’s Athletic', 1, 'A', b'1'),
('2015-06-10 13:34:07', '', 471, 3, 420, 'monkey', 'Cork City', 1, 'A', b'1'),
('2015-06-10 13:34:31', '', 472, 3, 420, 'markr', 'Cork City', 1, 'A', b'1'),
('2015-06-11 15:47:08', '', 473, 3, 422, 'jamesoneill', 'St. Patrick’s Athletic', 1, 'A', b'1'),
('2015-06-11 15:47:33', '', 474, 3, 422, 'JohnLynch1982', 'St. Patrick’s Athletic', 1, 'A', b'1'),
('2015-06-11 15:48:40', '', 475, 3, 422, 'telordan', 'St. Patrick’s Athletic', 1, 'A', b'1'),
('2015-06-11 16:04:03', '', 476, 3, 420, 'Rob', 'Cork City', 1, 'A', b'1'),
('2015-06-26 12:19:31', '', 478, 116, 429, 'tommygrealy', 'Dundalk', 1, 'A', b'1'),
('2015-06-26 12:54:56', '', 479, 116, 429, 'monkey', 'Dundalk', 1, 'A', b'1'),
('2015-06-26 13:00:40', '', 480, 116, 425, 'tonydoyle', 'St. Patrick’s Athletic', 1, 'A', b'1'),
('2015-06-26 13:08:49', '', 481, 116, 429, 'JohnLynch1982', 'Dundalk', 1, 'A', b'1'),
('2015-06-26 13:09:26', '', 482, 116, 429, 'Rob', 'Dundalk', 1, 'A', b'1'),
('2015-06-26 13:12:19', '', 483, 116, 429, 'declancotter', 'Dundalk', 1, 'A', b'1'),
('2015-06-26 13:18:03', '', 484, 116, 429, 'jamesoneill', 'Dundalk', 1, 'A', b'1'),
('2015-06-26 13:27:11', '', 485, 116, 429, 'telordan', 'Dundalk', 1, 'A', b'1'),
('2015-06-26 14:27:30', '', 486, 116, 428, 'markr', 'Bohemians', 1, 'A', b'0'),
('2015-07-16 16:38:01', '', 488, 117, 437, 'tommygrealy', 'Shamrock Rovers', 3, 'A', b'1'),
('2015-07-30 14:11:38', '', 489, 117, 436, 'JohnLynch1982', 'Derry City', 1, 'A', b'1'),
('2015-07-30 16:19:01', '', 490, 117, 435, 'declancotter', 'Cork City', 1, 'A', b'1'),
('2015-07-30 17:06:43', '', 491, 117, 440, 'monkey', 'St. Patrick’s Athletic', 1, 'A', b'1'),
('2015-07-31 13:36:16', '', 492, 117, 436, 'jamesoneill', 'Derry City', 1, 'A', b'1'),
('2015-07-31 14:21:19', '', 493, 117, 438, 'tonydoyle', 'Dundalk', 3, 'A', b'1'),
('2015-08-01 11:07:17', '', 494, NULL, 435, 'Rob', 'Bohemians', 3, 'A', b'0'),
('2015-08-01 11:07:53', '', 496, NULL, 435, 'telordan', 'Bohemians', 3, 'A', b'0'),
('2015-08-05 12:01:38', '', 499, 118, 441, 'JohnLynch1982', 'Galway United', 1, 'A', b'0'),
('2015-08-05 13:06:00', '', 502, 118, 442, 'tommygrealy', 'Cork City', 3, 'A', b'1'),
('2015-08-05 15:46:15', '', 503, 118, 442, 'jamesoneill', 'Cork City', 3, 'A', b'1'),
('2015-08-05 21:21:11', '', 504, 118, 441, 'monkey', 'Galway United', 1, 'A', b'0'),
('2015-08-06 16:09:40', '', 505, 118, 445, 'tonydoyle', 'Bray Wanderers', 1, 'A', b'1'),
('2015-08-06 16:12:56', '', 506, 118, 446, 'declancotter', 'Bohemians', 3, 'A', b'0'),
('2015-08-12 11:30:42', '', 507, 119, 450, 'tommygrealy', 'Drogheda United', 1, 'A', b'0'),
('2015-08-14 10:58:30', '', 508, 119, 447, 'tonydoyle', 'Bohemians', 1, 'A', b'1'),
('2015-08-14 10:59:12', '', 509, 119, 447, 'jamesoneill', 'Bohemians', 1, 'A', b'1'),
('2015-08-18 15:49:21', '', 518, 4, 606, 'mgrealy', 'Arsenal', 3, 'A', b'1'),
('2015-08-20 09:07:29', '', 530, 4, 603, 'kmacken', 'Chelsea', 1, 'A', b'0'),
('2015-08-20 09:14:48', '', 531, 4, 609, 'tommygrealy', 'Manchester United', 3, 'A', b'0'),
('2015-08-27 14:47:02', '', 532, 4, 608, 'tonydoyle', 'Stoke City', 1, 'A', b'0'),
('2015-08-28 11:44:14', '', 533, 4, 608, 'JohnLynch1982', 'Stoke City', 1, 'A', b'0'),
('2015-08-28 12:23:19', '', 534, 4, 605, 'Rob', 'Manchester City', 1, 'A', b'1'),
('2015-08-28 14:40:36', '', 535, 4, 605, 'Gforde', 'Manchester City', 1, 'A', b'1'),
('2015-08-28 14:44:09', '', 536, 4, 604, 'Alan G', 'Liverpool', 1, 'A', b'0'),
('2015-08-28 15:18:31', '', 537, 4, 604, 'Rodge', 'Liverpool', 1, 'A', b'0'),
('2015-08-28 15:28:11', '', 538, 4, 605, 'jamesoneill', 'Manchester City', 1, 'A', b'1'),
('2015-08-28 15:30:07', '', 539, 4, 605, 'mjnolan', 'Manchester City', 1, 'A', b'1'),
('2015-08-28 15:38:01', '', 540, 4, 605, 'monkey', 'Manchester City', 1, 'A', b'1'),
('2015-08-28 15:38:52', '', 541, 4, 605, 'jbligh', 'Manchester City', 1, 'A', b'1'),
('2015-08-28 15:59:43', '', 542, 4, 605, 'markr', 'Manchester City', 1, 'A', b'1'),
('2015-08-28 17:50:20', '', 543, 4, 605, 'shethert', 'Manchester City', 1, 'A', b'1'),
('2015-08-28 21:02:33', '', 544, 4, 605, 'declancotter', 'Manchester City', 1, 'A', b'1'),
('2015-09-09 10:27:39', '', 545, 5, 611, 'declancotter', 'Arsenal', 1, 'A', b'1'),
('2015-09-09 10:43:33', '', 546, 5, 611, 'jamesoneill', 'Arsenal', 1, 'A', b'1'),
('2015-09-09 13:25:11', '', 547, 5, 611, 'markr', 'Arsenal', 1, 'A', b'1'),
('2015-09-09 14:45:07', '', 548, 5, 620, 'monkey', 'West Ham United', 1, 'A', b'1'),
('2015-09-10 14:00:33', '', 549, 5, 612, 'mgrealy', 'Manchester City', 3, 'A', b'1'),
('2015-09-11 14:53:45', '', 550, 5, 614, 'jbligh', 'Leicester City', 1, 'A', b'1'),
('2015-09-11 16:18:46', '', 551, 5, 613, 'Rob', 'Chelsea', 3, 'A', b'0'),
('2015-09-11 16:19:03', '', 552, 5, 611, 'mjnolan', 'Arsenal', 1, 'A', b'1'),
('2015-09-11 19:39:01', '', 553, 5, 613, 'shethert', 'Chelsea', 3, 'A', b'0'),
('2015-09-12 02:34:44', '', 554, 5, 618, 'Gforde', 'Swansea City', 3, 'A', b'0'),
('2015-09-16 05:05:00', '', 555, 6, 624, 'mgrealy', 'Liverpool', 1, 'A', b'0'),
('2015-09-17 11:34:05', '', 556, 6, 627, 'markr', 'Manchester United', 3, 'A', b'1'),
('2015-09-17 13:52:16', '', 558, 6, 624, 'jamesoneill', 'Liverpool', 1, 'A', b'0'),
('2015-09-17 16:10:54', '', 559, 6, 624, 'declancotter', 'Liverpool', 1, 'A', b'0'),
('2015-09-18 15:10:08', '', 560, 6, 624, 'monkey', 'Liverpool', 1, 'A', b'0'),
('2015-09-18 17:30:23', '', 561, 6, 626, 'jbligh', 'Newcastle United', 1, 'A', b'0'),
('2015-09-18 19:57:08', '', 562, 6, 624, 'mjnolan', 'Liverpool', 1, 'A', b'0'),
('2015-09-23 12:50:33', 'MANUAL', 563, 7, 633, 'tommygrealy', 'Manchester United', 1, 'A', b'1'),
('2015-09-23 19:34:07', 'MANUAL', 564, 7, 634, 'moeman96', 'Chelsea', 3, 'A', b'0'),
('2015-09-24 11:54:54', 'MANUAL', 565, 7, 633, 'mjnolan', 'Manchester United', 1, 'A', b'1'),
('2015-09-24 13:38:41', 'MANUAL', 566, 7, 633, 'markr', 'Manchester United', 1, 'A', b'1'),
('2015-09-24 14:02:28', 'MANUAL', 567, 7, 633, 'tonydoyle', 'Manchester United', 1, 'A', b'1'),
('2015-09-24 14:10:34', 'MANUAL', 568, 7, 633, 'Rodge', 'Manchester United', 1, 'A', b'1'),
('2015-09-24 14:27:08', 'MANUAL', 569, 7, 633, 'Alan G', 'Manchester United', 1, 'A', b'1'),
('2015-09-24 14:44:19', 'MANUAL', 570, 7, 633, 'declancotter', 'Manchester United', 1, 'A', b'1'),
('2015-09-24 14:49:08', 'MANUAL', 571, 7, 633, 'jamesoneill', 'Manchester United', 1, 'A', b'1'),
('2015-09-24 14:52:59', 'MANUAL', 572, 7, 639, 'mgrealy', 'Everton', 3, 'A', b'1'),
('2015-09-24 20:18:32', 'MANUAL', 573, 7, 633, 'monkey', 'Manchester United', 1, 'A', b'1'),
('2015-09-25 09:56:25', 'MANUAL', 574, 7, 633, 'jbligh', 'Manchester United', 1, 'A', b'1'),
('2015-09-25 13:54:44', 'MANUAL', 575, 7, 633, 'kmacken', 'Manchester United', 1, 'A', b'1'),
('2015-09-25 15:39:52', 'MANUAL', 576, 7, 633, 'shethert', 'Manchester United', 1, 'A', b'1'),
('2015-09-25 19:06:41', 'MANUAL', 577, 7, 633, 'Gforde', 'Manchester United', 1, 'A', b'1'),
('2015-09-25 19:17:46', 'MANUAL', 578, 7, 633, 'Rob', 'Manchester United', 1, 'A', b'1'),
('2015-09-29 10:00:29', 'MANUAL', 586, 8, 647, 'tommygrealy', 'Manchester City', 1, 'A', b'1'),
('2015-09-30 09:54:37', 'MANUAL', 587, 8, 647, 'declancotter', 'Manchester City', 1, 'A', b'1'),
('2015-09-30 20:14:46', 'MANUAL', 588, 8, 644, 'kmacken', 'Chelsea', 1, 'A', b'0'),
('2015-10-01 03:30:02', 'MANUAL', 589, 8, 647, 'mgrealy', 'Manchester City', 1, 'A', b'1'),
('2015-10-01 10:06:07', 'MANUAL', 590, 8, 647, 'mjnolan', 'Manchester City', 1, 'A', b'1'),
('2015-10-01 16:08:21', 'MANUAL', 591, 8, 647, 'Rodge', 'Manchester City', 1, 'A', b'1'),
('2015-10-01 23:04:59', 'MANUAL', 592, 8, 647, 'tonydoyle', 'Manchester City', 1, 'A', b'1'),
('2015-10-01 23:29:19', 'MANUAL', 593, 8, 647, 'monkey', 'Manchester City', 1, 'A', b'1'),
('2015-10-02 12:23:52', 'MANUAL', 594, 8, 647, 'jbligh', 'Manchester City', 1, 'A', b'1'),
('2015-10-02 14:17:55', 'MANUAL', 595, 8, 647, 'Alan G', 'Manchester City', 1, 'A', b'1'),
('2015-10-02 14:28:35', 'MANUAL', 596, 8, 644, 'jamesoneill', 'Chelsea', 1, 'A', b'0'),
('2015-10-02 20:43:42', 'MANUAL', 597, 8, 647, 'markr', 'Manchester City', 1, 'A', b'1'),
('2015-10-03 10:33:54', 'MANUAL', 598, 8, 647, 'shethert', 'Manchester City', 1, 'A', b'1'),
('2015-10-03 12:11:33', 'AUTO', 599, 8, 642, 'Rob', 'Arsenal', 1, 'A', b'1'),
('2015-10-03 12:12:05', 'AUTO', 600, 8, 642, 'Gforde', 'Arsenal', 1, 'A', b'1'),
('2015-10-12 12:54:51', 'MANUAL', 740, 9, 651, 'tommygrealy', 'Chelsea', 1, 'A', b'1'),
('2015-10-12 15:03:34', 'MANUAL', 741, 9, 659, 'mgrealy', 'Arsenal', 3, 'A', b'1'),
('2015-10-14 00:11:25', 'MANUAL', 742, 9, 659, 'markr', 'Arsenal', 3, 'A', b'1'),
('2015-10-14 18:53:15', 'MANUAL', 743, 9, 656, 'Alan G', 'Southampton', 1, 'A', b'0'),
('2015-10-15 09:53:15', 'MANUAL', 744, 9, 651, 'declancotter', 'Chelsea', 1, 'A', b'1'),
('2015-10-15 16:03:45', 'MANUAL', 745, 9, 651, 'tonydoyle', 'Chelsea', 1, 'A', b'1'),
('2015-10-16 11:52:03', 'MANUAL', 746, 9, 651, 'Rob', 'Chelsea', 1, 'A', b'1'),
('2015-10-16 14:16:21', 'MANUAL', 747, 9, 659, 'mjnolan', 'Arsenal', 3, 'A', b'1'),
('2015-10-16 14:31:38', 'MANUAL', 748, 9, 651, 'Rodge', 'Chelsea', 1, 'A', b'1'),
('2015-10-16 22:39:10', 'MANUAL', 749, 9, 659, 'shethert', 'Arsenal', 3, 'A', b'1'),
('2015-10-17 07:36:44', 'MANUAL', 750, 9, 651, 'monkey', 'Chelsea', 1, 'A', b'1'),
('2015-10-17 10:06:39', 'MANUAL', 751, 9, 660, 'jbligh', 'West Bromwich Albion', 1, 'A', b'1'),
('2015-10-17 11:44:04', 'AUTO', 752, 9, 651, 'Gforde', 'Aston Villa', 3, 'A', b'0'),
('2015-10-20 20:16:53', 'MANUAL', 753, 10, 661, 'tommygrealy', 'Tottenham Hotspur', 3, 'A', b'1'),
('2015-10-21 10:44:57', 'MANUAL', 754, 10, 668, 'tonydoyle', 'Stoke City', 1, 'A', b'0'),
('2015-10-22 11:57:01', 'MANUAL', 755, 10, 662, 'declancotter', 'Arsenal', 1, 'A', b'1'),
('2015-10-23 18:21:16', 'MANUAL', 756, 10, 661, 'Rob', 'Tottenham Hotspur', 3, 'A', b'1'),
('2015-10-23 21:15:24', 'MANUAL', 757, 10, 662, 'jbligh', 'Arsenal', 1, 'A', b'1'),
('2015-10-24 09:19:28', 'MANUAL', 758, 10, 665, 'monkey', 'Liverpool', 1, 'A', b'0'),
('2015-10-24 10:06:40', 'MANUAL', 759, 10, 661, 'mjnolan', 'Tottenham Hotspur', 3, 'A', b'1'),
('2015-10-24 12:11:31', 'MANUAL', 760, 10, 662, 'Rodge', 'Arsenal', 1, 'A', b'1'),
('2015-10-24 13:05:49', 'MANUAL', 761, 10, 661, 'mgrealy', 'Tottenham Hotspur', 3, 'A', b'1'),
('2015-10-24 14:01:17', 'AUTO', 762, 10, 663, 'shethert', 'Aston Villa', 1, 'A', b'0'),
('2015-10-24 14:01:18', 'AUTO', 763, 10, 663, 'markr', 'Aston Villa', 1, 'A', b'0'),
('2015-10-27 09:49:50', 'MANUAL', 765, 11, 673, 'tommygrealy', 'Everton', 1, 'A', b'1'),
('2015-10-27 15:40:09', 'MANUAL', 766, 11, 674, 'Rob', 'Manchester City', 1, 'A', b'1'),
('2015-10-28 14:29:53', 'MANUAL', 767, 11, 676, 'declancotter', 'Southampton', 1, 'A', b'1'),
('2015-10-29 13:26:30', 'MANUAL', 768, 11, 676, 'mgrealy', 'Southampton', 1, 'A', b'1'),
('2015-10-30 17:12:10', 'MANUAL', 769, 11, 676, 'jbligh', 'Southampton', 1, 'A', b'1'),
('2015-10-30 18:26:42', 'MANUAL', 770, 11, 673, 'Rodge', 'Everton', 1, 'A', b'1'),
('2015-10-30 20:31:04', 'MANUAL', 771, 11, 679, 'mjnolan', 'West Ham United', 3, 'A', b'0'),
('2015-11-05 09:13:13', 'MANUAL', 772, 12, 684, 'tommygrealy', 'Leicester City', 1, 'A', b'1'),
('2015-11-05 09:55:33', 'MANUAL', 773, 12, 685, 'declancotter', 'Liverpool', 1, 'A', b'0'),
('2015-11-05 10:55:38', 'MANUAL', 774, 12, 689, 'Rodge', 'Southampton', 3, 'A', b'1'),
('2015-11-05 12:09:48', 'MANUAL', 775, 12, 686, 'mgrealy', 'Manchester United', 1, 'A', b'1'),
('2015-11-05 15:36:07', 'MANUAL', 776, 12, 685, 'Rob', 'Liverpool', 1, 'A', b'0'),
('2015-11-07 09:18:32', 'MANUAL', 777, 12, 684, 'jbligh', 'Leicester City', 1, 'A', b'1'),
('2015-11-14 22:21:36', 'MANUAL', 778, 13, 692, 'tommygrealy', 'Crystal Palace', 1, 'A', b'0'),
('2015-11-18 14:40:48', 'MANUAL', 779, 13, 692, 'Rodge', 'Crystal Palace', 1, 'A', b'0'),
('2015-11-19 01:45:20', 'MANUAL', 780, 13, 691, 'mgrealy', 'Chelsea', 1, 'A', b'1'),
('2015-11-20 20:33:50', 'MANUAL', 781, 13, 691, 'jbligh', 'Chelsea', 1, 'A', b'1'),
('2015-11-26 17:40:40', 'MANUAL', 782, 14, 705, 'mgrealy', 'Liverpool', 1, 'A', b'1'),
('2015-11-26 19:39:45', 'MANUAL', 783, 14, 705, 'jbligh', 'Liverpool', 1, 'A', b'1'),
('2015-12-04 17:23:07', 'MANUAL', 784, 15, 716, 'mgrealy', 'Aston Villa', 3, 'A', NULL),
('2015-12-04 22:50:05', 'MANUAL', 785, 15, 720, 'jbligh', 'Tottenham Hotspur', 3, 'A', NULL),
('2015-12-10 11:49:46', 'MANUAL', 786, 16, 723, 'mgrealy', 'Crystal Palace', 1, 'A', NULL),
('2015-12-12 10:19:06', 'MANUAL', 787, 16, 727, 'jbligh', 'Everton', 3, 'A', NULL),
('2018-01-25 14:25:03', 'MANUAL', 798, 1, 761, 'johnlynch1982', 'Dublin', 1, 'A', b'1'),
('2018-01-26 09:17:54', 'MANUAL', 804, 1, 763, 'Kris', 'Monaghan', 1, 'A', b'0'),
('2018-01-26 15:37:11', 'MANUAL', 806, 1, 764, 'telordan', 'Galway', 1, 'A', b'1'),
('2018-01-26 19:10:36', 'MANUAL', 807, 1, 764, 'pguerin', 'Tyrone', 3, 'A', b'0'),
('2018-01-26 21:09:58', 'MANUAL', 808, 1, 761, 'Jamesoneill', 'Dublin', 1, 'A', b'1'),
('2018-01-26 21:50:04', 'MANUAL', 809, 1, 762, 'Declancotter', 'Kerry', 1, 'A', b'1'),
('2018-01-26 22:52:17', 'MANUAL', 810, 1, 762, 'jbligh76', 'Kerry', 1, 'A', b'1'),
('2018-01-27 08:31:43', 'MANUAL', 811, 1, 762, 'tommygrealy', 'Kerry', 1, 'A', b'1'),
('2018-01-30 21:54:17', 'MANUAL', 813, 2, 767, 'tommygrealy', 'Kildare', 1, 'A', b'0'),
('2018-01-30 22:46:10', 'MANUAL', 814, 2, 768, 'Jamesoneill', 'Donegal', 1, 'A', b'0'),
('2018-02-02 21:12:22', 'MANUAL', 815, 2, 768, 'Declancotter', 'Donegal', 1, 'A', b'0'),
('2018-02-02 10:37:29', 'MANUAL', 816, 2, 768, 'jbligh76', 'Donegal', 1, 'A', b'0'),
('2018-02-02 10:38:17', 'MANUAL', 817, 2, 768, 'johnlynch1982', 'Donegal', 1, 'A', b'0'),
('2018-02-03 10:40:15', 'MANUAL', 818, 2, 768, 'telordan', 'Donegal', 1, 'A', b'0'),
('2018-02-05 11:00:39', 'MANUAL', 819, 3, 769, 'tommygrealy', 'Dublin', 1, 'A', b'1'),
('2018-02-05 15:02:06', 'MANUAL', 835, 3, 772, 'johnlynch1982', 'Kerry', 3, 'A', b'0'),
('2018-02-08 15:09:25', 'MANUAL', 836, 3, 771, 'telordan', 'Kildare', 1, 'A', b'0'),
('2018-02-08 15:57:25', 'MANUAL', 837, 3, 769, 'Declancotter', 'Dublin', 1, 'A', b'1'),
('2018-02-08 15:58:53', 'MANUAL', 838, 3, 769, 'jbligh76', 'Dublin', 1, 'A', b'1'),
('2018-02-09 08:49:04', 'MANUAL', 839, 3, 772, 'Jamesoneill', 'Kerry', 3, 'A', b'0'),
('2018-02-20 09:57:08', 'MANUAL', 841, 4, 774, 'tommygrealy', 'Monaghan', 1, 'A', b'1'),
('2018-02-23 11:27:56', 'MANUAL', 842, 4, 774, 'Declancotter', 'Tyrone', 3, 'A', b'0'),
('2018-02-23 12:17:02', 'MANUAL', 843, 4, 774, 'jbligh76', 'Monaghan', 1, 'A', b'1'),
('2018-03-09 13:06:49', 'MANUAL', 849, 5, 778, 'jbligh76', 'Tyrone', 1, 'A', b'1'),
('2018-03-09 13:36:44', 'MANUAL', 850, 5, 779, 'tommygrealy', 'Galway', 1, 'A', b'1'),
('2018-03-16 10:08:28', 'MANUAL', 852, 6, 781, 'jbligh76', 'Mayo', 1, 'A', b'1'),
('2018-03-16 14:06:26', 'MANUAL', 853, 6, 781, 'tommygrealy', 'Mayo', 1, 'A', b'1'),
('2018-03-21 16:42:30', 'MANUAL', 855, 7, 786, 'tommygrealy', 'Donegal', 1, 'A', b'0'),
('2018-03-23 14:52:12', 'MANUAL', 856, 7, 787, 'jbligh76', 'Galway', 3, 'A', b'1'),
('2021-02-07 12:45:35', 'MANUAL', 860, 2, 1128, 'Bort United', 'Chelsea', 1, 'A', b'1'),
('2021-02-07 10:27:42', 'MANUAL', 859, 2, 1128, 'LordStyxofdeNordsoide', 'Chelsea', 1, 'A', b'1'),
('2021-02-16 10:07:07', 'MANUAL', 875, 0, 1132, 'LordStyxofdeNordsoide', 'Liverpool', 1, 'A', b'0'),
('2021-02-19 16:52:18', 'MANUAL', 876, 0, 1136, 'Patthing', 'Man City', 3, 'A', b'1'),
('2021-02-26 10:22:13', 'MANUAL', 877, 4, 1147, 'Bort United', 'Liverpool', 3, 'A', b'1'),
('2021-02-27 00:51:36', 'MANUAL', 878, 4, 1145, 'Patthing', 'Spurs', 1, 'A', b'1'),
('2021-02-27 10:05:50', 'MANUAL', 879, 4, 1145, ' Matlock', 'Spurs', 1, 'A', b'1'),
('2021-03-04 21:49:22', 'MANUAL', 880, 27, 1153, ' Matlock', 'Liverpool', 1, 'A', b'1'),
('2021-03-05 22:52:09', 'MANUAL', 881, 27, 1151, 'Patthing', 'Arsenal', 3, 'A', b'1'),
('2021-03-06 12:00:00', 'AUTO', 882, 27, 1159, 'Bort United', 'Arsenal', 1, 'A', b'1'),
('2021-02-07 10:27:42', 'MANUAL', 859, 2, 1128, 'LordStyxofdeNordsoide', 'Chelsea', 1, 'A', b'1'),
('2021-02-07 12:45:35', 'MANUAL', 860, 2, 1128, 'Bort United', 'Chelsea', 1, 'A', b'1'),
('2021-02-08 01:23:24', 'MANUAL', 862, 2, 1128, 'Mheg2021', 'Chelsea', 1, 'A', b'1'),
('2021-02-08 14:20:58', 'MANUAL', 864, 2, 1128, ' Matlock', 'Chelsea', 1, 'A', b'1'),
('2021-02-08 22:47:06', 'MANUAL', 865, 2, 1126, 'Krustu', 'Everton', 1, 'A', b'0'),
('2021-02-12 16:59:47', 'MANUAL', 867, 2, 1119, 'pullingmeplums69', 'Liverpool', 3, 'A', b'0'),
('2021-02-12 22:13:40', 'MANUAL', 868, 2, 1128, 'Patthing', 'Chelsea', 1, 'A', b'1'),
('2021-02-13 00:44:55', 'MANUAL', 870, 2, 1120, 'tommygrealy', 'Crystal Palace', 1, 'A', b'0'),
('2021-02-15 23:41:24', 'MANUAL', 872, 0, 1134, 'Mheg2021', 'Spurs', 3, 'A', b'0'),
('2021-02-16 09:34:21', 'MANUAL', 873, 0, 1137, 'Bort United', 'Man Utd', 1, 'A', b'1'),
('2021-02-16 09:47:24', 'MANUAL', 874, 0, 1133, ' Matlock', 'Fulham', 1, 'A', b'1'),
('2021-02-16 10:07:07', 'MANUAL', 875, 0, 1132, 'LordStyxofdeNordsoide', 'Liverpool', 1, 'A', b'0'),
('2021-02-19 16:52:18', 'MANUAL', 876, 0, 1136, 'Patthing', 'Man City', 3, 'A', b'1'),
('2021-02-26 10:22:13', 'MANUAL', 877, 4, 1147, 'Bort United', 'Liverpool', 3, 'A', b'1'),
('2021-02-27 00:51:36', 'MANUAL', 878, 4, 1145, 'Patthing', 'Spurs', 1, 'A', b'1'),
('2021-02-27 10:05:50', 'MANUAL', 879, 4, 1145, ' Matlock', 'Spurs', 1, 'A', b'1'),
('2021-03-04 21:49:22', 'MANUAL', 880, 27, 1153, ' Matlock', 'Liverpool', 1, 'A', b'1'),
('2021-03-05 22:52:09', 'MANUAL', 881, 27, 1151, 'Patthing', 'Arsenal', 3, 'A', b'1'),
('2021-03-06 12:00:00', 'AUTO', 882, 27, 1151, 'Bort United', 'Arsenal', 3, 'A', b'1'),
('2021-03-10 20:32:48', 'MANUAL', 884, 28, 1162, 'Bort United', 'Man City', 3, 'A', b'1'),
('2021-03-10 20:51:26', 'MANUAL', 885, 28, 1164, ' Matlock', 'Leicester', 1, 'A', b'1'),
('2021-03-12 19:00:04', 'MANUAL', 886, 28, 1164, 'Patthing', 'Leicester', 1, 'A', b'1'),
('2021-03-20 10:53:34', 'MANUAL', 887, 30, 1185, ' Matlock', 'Man Utd', 1, 'A', NULL),
('2021-04-03 10:24:38', 'MANUAL', 888, 30, 1185, 'Patthing', 'Man Utd', 1, 'A', NULL),
('2021-04-02 14:04:18', 'AUTO', 889, 30, 1180, 'Bort United', 'Aston Villa', 1, 'A', NULL),
('2021-04-07 13:58:12', 'MANUAL', 890, 31, 1194, 'Mheg2021', 'Man City', 1, 'A', b'0'),
('2021-04-07 15:07:13', 'MANUAL', 891, 31, 1195, 'tommygrealy', 'Arsenal', 3, 'A', b'1'),
('2021-04-07 23:44:38', 'MANUAL', 892, 31, 1194, 'Hutto', 'Man City', 1, 'A', b'0'),
('2021-04-08 13:12:01', 'MANUAL', 893, 31, 1194, 'Krustu', 'Man City', 1, 'A', b'0'),
('2021-04-08 13:14:26', 'MANUAL', 894, 31, 1191, 'Bort United', 'Chelsea', 3, 'A', b'1'),
('2021-04-08 20:39:56', 'MANUAL', 895, 31, 1191, 'LordStyxofdeNordsoide', 'Chelsea', 3, 'A', b'1'),
('2021-04-09 14:00:40', 'MANUAL', 896, 31, 1194, 'pullingmeplums69', 'Man City', 1, 'A', b'0'),
('2021-04-09 18:20:04', 'MANUAL', 897, 31, 1197, ' Matlock', 'Southampton', 3, 'A', b'0'),
('2021-04-09 18:56:31', 'MANUAL', 898, 31, 1191, 'Patthing', 'Chelsea', 3, 'A', b'1'),
('2021-04-16 13:40:54', 'MANUAL', 900, 32, 1208, 'LordStyxofdeNordsoide', 'Wolves', 1, 'A', b'1'),
('2021-04-16 15:09:40', 'MANUAL', 901, 32, 1205, 'tommygrealy', 'Man Utd', 1, 'A', b'1'),
('2021-04-16 17:06:24', 'MANUAL', 902, 32, 1200, 'Bort United', 'Man City', 3, 'A', b'1'),
('2021-04-16 19:06:15', 'AUTO', 903, 32, 1199, 'Patthing', 'Arsenal', 1, 'A', b'0'),
('2021-04-22 23:36:08', 'MANUAL', 905, 34, 1227, 'tommygrealy', 'Spurs', 1, 'A', b'1'),
('2021-04-30 11:17:40', 'MANUAL', 906, 34, 1222, 'LordStyxofdeNordsoide', 'Man City', 3, 'A', b'1'),
('2021-04-30 11:31:18', 'MANUAL', 907, 34, 1224, 'Bort United', 'Man Utd', 1, 'A', b'1'),
('2021-05-05 23:04:24', 'MANUAL', 908, 35, 1233, 'tommygrealy', 'Newcastle', 3, 'A', b'1'),
('2021-05-06 06:44:52', 'MANUAL', 909, 35, 1234, 'Bort United', 'Liverpool', 1, 'A', b'1'),
('2021-05-06 09:26:48', 'MANUAL', 910, 35, 1234, 'LordStyxofdeNordsoide', 'Liverpool', 1, 'A', b'1'),
('2021-05-11 08:21:31', 'MANUAL', 911, 36, 1246, 'tommygrealy', 'Man City', 3, 'A', b'1'),
('2021-05-11 08:25:16', 'MANUAL', 912, 36, 1239, 'Bort United', 'West Ham', 3, 'A', b'0'),
('2021-05-11 09:20:50', 'MANUAL', 913, 36, 1240, 'LordStyxofdeNordsoide', 'Leeds', 3, 'A', b'1'),
('2021-05-17 19:43:14', 'MANUAL', 914, 37, 1258, 'tommygrealy', 'West Ham', 3, 'A', b'1'),
('2021-05-17 20:01:49', 'MANUAL', 915, 37, 1257, 'LordStyxofdeNordsoide', 'Spurs', 1, 'A', b'0');

-- --------------------------------------------------------

--
-- Stand-in structure for view `showloosingpredictions`
--
CREATE TABLE `showloosingpredictions` (
`KickOffTime` datetime
,`FixtureId` int(11)
,`HomeTeam` varchar(50)
,`AwayTeam` varchar(50)
,`Result` smallint(6)
,`PredictionID` int(11)
,`username` varchar(255)
,`PredictedResult` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `showwinningpredictions`
--
CREATE TABLE `showwinningpredictions` (
`KickOffTime` datetime
,`FixtureId` int(11)
,`HomeTeam` varchar(50)
,`AwayTeam` varchar(50)
,`Result` smallint(6)
,`PredictionID` int(11)
,`username` varchar(255)
,`PredictedResult` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `status`
--

CREATE TABLE `status` (
  `StatusID` int(11) NOT NULL,
  `Description` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `status`
--

INSERT INTO `status` (`StatusID`, `Description`) VALUES
(1, 'Active'),
(2, 'Eliminated'),
(3, 'Waiting Payment');

-- --------------------------------------------------------

--
-- Stand-in structure for view `thisWeeksFixtures`
--
CREATE TABLE `thisWeeksFixtures` (
`FixtureId` int(11)
,`KickOffTime` datetime
,`HomeTeam` varchar(50)
,`AwayTeam` varchar(50)
,`ShortNameHome` varchar(8)
,`ShortNameAway` varchar(8)
,`MedNameHome` varchar(100)
,`MedNameAway` varchar(100)
,`HomeCrestImg` varchar(255)
,`AwayCrestImg` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `userfeedback`
--

CREATE TABLE `userfeedback` (
  `commentId` int(11) NOT NULL,
  `commentUserName` varchar(100) DEFAULT NULL,
  `commentEmail` varchar(100) DEFAULT NULL,
  `commentText` text,
  `commentDate` datetime DEFAULT NULL,
  `commentReplySent` binary(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `FullName` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` char(64) COLLATE utf8_unicode_ci NOT NULL,
  `salt` char(16) COLLATE utf8_unicode_ci NOT NULL,
  `PrivLevel` int(11) NOT NULL DEFAULT '1',
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `CompStatus` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `PaymentStatus` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `FullName`, `password`, `salt`, `PrivLevel`, `email`, `CompStatus`, `PaymentStatus`) VALUES
(2076, 'Patthing', 'Pat Collins ', 'f4a32980e006988cb683d4910dcd94948b18de4623dcc3550a47e3021bbbd95f', '180bbcb942553031', 1, 'patthing@gmail.com', 'Playing', 'Paid'),
(2077, 'Matlock', 'Matlock QC', '0bccc9fe8d210f52eceb4ed275bb20bf923ac552289b07ef17b0622ac2c320a7', '5ee0b22c49af6856', 1, 'bclarkie@gmail.com', 'Playing', 'Paid'),
(2078, 'pullingmeplums69', 'Philip Flynn', '0eef60740951773d24b9eb379267a9a60a397719906febf714634a8bf62d8ff8', '61eaad8d5aec04af', 1, 'philipflynn76@gmail.com', 'Playing', 'Paid'),
(2079, 'LordStyxofdeNordsoide', 'Styx', '01cabca0e910767248f51924844cc023b843e90d7c45fc7d9b447b8bf2607984', 'a60428c71df0551', 1, 'd_oshaughnessy@yahoo.com', 'Playing', 'Paid'),
(2080, 'Mheg2021', 'Cairbre O Donnell', 'd9466f0a4b6178f21ab84dc2ca962683af3b4050a6eaf5d23bc3396b21e9d435', '6e5d6aa6ffeb1b8', 1, 'cairbre.odonnell@me.com', 'Playing', 'Paid'),
(2081, 'Bort United', 'Thomas Bartlett', '524146a99fcd2dacdc31f3677cc679e141297df6c551cbd9c1d0ced3416a398c', '710ee7e579ea7f6e', 1, 'thomasbartlet@gmail.com', 'Playing', 'Paid'),
(2082, 'Krustu', 'Krustu', 'a6499235ef6935327ef664ed89288e4507f55f63eeb4951d24f50685f202d62d', '284d0a0231278c06', 1, 'b_o_farrell@yahoo.com', 'Playing', 'Paid'),
(2083, 'test', 'testy', '831cbafba30b6e34773d1067940ca6ea4473cdc9a687feaf6f6709cf928d5089', '359b22061cebadf3', 1, 'doshaug@tcd.ie', 'Playing', 'Pending'),
(2086, 'Hutto', 'Dougie Hutton', 'cf3a639345b71cd05c8a08ca4931a6eb88f84dae64ce8ed634f8348f8c14a019', '71f4950a4717afdf', 1, 'huttod76@gmail.com', 'Playing', 'Paid'),
(2088, 'tommygrealy', 'Tommy Grealy', '1710c8b4e408ff44ea1bf42dd78a8e15cd7a08001438b412498fae0a924155cf', '14d238201c07fa05', 3, 'tommygrealy@gmail.com', 'Playing', 'Paid');

-- --------------------------------------------------------

--
-- Stand-in structure for view `usersnotsubmitted`
--
CREATE TABLE `usersnotsubmitted` (
`Email` varchar(255)
,`FullName` varchar(45)
,`username` varchar(255)
);

-- --------------------------------------------------------

--
-- Structure for view `allfixturesandclubinfo`
--
DROP TABLE IF EXISTS `allfixturesandclubinfo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`lms`@`%` SQL SECURITY DEFINER VIEW `allfixturesandclubinfo`  AS  select distinct `fr`.`FixtureId` AS `FixtureId`,`fr`.`KickOffTime` AS `KickOffTime`,`fr`.`HomeTeam` AS `HomeTeam`,`fr`.`AwayTeam` AS `AwayTeam`,(select `clubs`.`ShortName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8))) AS `ShortNameHome`,(select `clubs`.`ShortName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8))) AS `ShortNameAway`,(select `clubs`.`MedName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8))) AS `MedNameHome`,(select `clubs`.`MedName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8))) AS `MedNameAway`,(select `clubs`.`CrestURLSmall` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8))) AS `HomeCrestImg`,(select `clubs`.`CrestURLSmall` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8))) AS `AwayCrestImg` from (`fixtureresults` `fr` join `clubs` `cl`) where ((convert(`fr`.`HomeTeam` using utf8) = `cl`.`LongName`) or (convert(`fr`.`AwayTeam` using utf8) = `cl`.`LongName`)) order by `fr`.`KickOffTime` ;

-- --------------------------------------------------------

--
-- Structure for view `detailedpredictions`
--
DROP TABLE IF EXISTS `detailedpredictions`;

CREATE ALGORITHM=UNDEFINED DEFINER=`lms`@`%` SQL SECURITY DEFINER VIEW `detailedpredictions`  AS  select `users`.`FullName` AS `FullName`,`users`.`email` AS `email`,`fixtureresults`.`KickOffTime` AS `KickOffTime`,(select concat(`fixtureresults`.`HomeTeam`,' vs ',`fixtureresults`.`AwayTeam`)) AS `FixtureDetail`,`predictions`.`TeamName` AS `User Selected`,`predictions`.`DateTimeEntered` AS `DateTimeEntered`,`predictions`.`PredictionID` AS `PredictionID` from ((`users` join `predictions` on((`users`.`username` = `predictions`.`UserName`))) join `fixtureresults` on((`predictions`.`FixtureID` = `fixtureresults`.`FixtureId`))) ;

-- --------------------------------------------------------

--
-- Structure for view `playingnotpaid`
--
DROP TABLE IF EXISTS `playingnotpaid`;

CREATE ALGORITHM=UNDEFINED DEFINER=`lms`@`%` SQL SECURITY DEFINER VIEW `playingnotpaid`  AS  select `users`.`username` AS `username`,`users`.`FullName` AS `FullName`,`users`.`email` AS `email` from `users` where ((`users`.`CompStatus` = 'Playing') and (`users`.`PaymentStatus` <> 'Paid')) ;

-- --------------------------------------------------------

--
-- Structure for view `showloosingpredictions`
--
DROP TABLE IF EXISTS `showloosingpredictions`;

CREATE ALGORITHM=UNDEFINED DEFINER=`lms`@`%` SQL SECURITY DEFINER VIEW `showloosingpredictions`  AS  select `fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`Result` AS `Result`,`predictions`.`PredictionID` AS `PredictionID`,`predictions`.`UserName` AS `username`,`predictions`.`PredictedResult` AS `PredictedResult` from (`fixtureresults` join `predictions` on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where ((`fixtureresults`.`Result` <> `predictions`.`PredictedResult`) and (`fixtureresults`.`Result` is not null)) ;

-- --------------------------------------------------------

--
-- Structure for view `showwinningpredictions`
--
DROP TABLE IF EXISTS `showwinningpredictions`;

CREATE ALGORITHM=UNDEFINED DEFINER=`lms`@`%` SQL SECURITY DEFINER VIEW `showwinningpredictions`  AS  select `fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`Result` AS `Result`,`predictions`.`PredictionID` AS `PredictionID`,`predictions`.`UserName` AS `username`,`predictions`.`PredictedResult` AS `PredictedResult` from (`fixtureresults` join `predictions` on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where (`fixtureresults`.`Result` = `predictions`.`PredictedResult`) ;

-- --------------------------------------------------------

--
-- Structure for view `thisWeeksFixtures`
--
DROP TABLE IF EXISTS `thisWeeksFixtures`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `thisWeeksFixtures`  AS  select `allfixturesandclubinfo`.`FixtureId` AS `FixtureId`,`allfixturesandclubinfo`.`KickOffTime` AS `KickOffTime`,`allfixturesandclubinfo`.`HomeTeam` AS `HomeTeam`,`allfixturesandclubinfo`.`AwayTeam` AS `AwayTeam`,`allfixturesandclubinfo`.`ShortNameHome` AS `ShortNameHome`,`allfixturesandclubinfo`.`ShortNameAway` AS `ShortNameAway`,`allfixturesandclubinfo`.`MedNameHome` AS `MedNameHome`,`allfixturesandclubinfo`.`MedNameAway` AS `MedNameAway`,`allfixturesandclubinfo`.`HomeCrestImg` AS `HomeCrestImg`,`allfixturesandclubinfo`.`AwayCrestImg` AS `AwayCrestImg` from `allfixturesandclubinfo` where (`allfixturesandclubinfo`.`KickOffTime` between (select `gameweekmap`.`DateFrom` from `gameweekmap` where (`gameweekmap`.`DateFrom` > (select now())) order by `gameweekmap`.`DateFrom` limit 1) and (select `gameweekmap`.`DateTo` from `gameweekmap` where (`gameweekmap`.`DateTo` > (select now())) order by `gameweekmap`.`DateTo` limit 1)) ;

-- --------------------------------------------------------

--
-- Structure for view `usersnotsubmitted`
--
DROP TABLE IF EXISTS `usersnotsubmitted`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `usersnotsubmitted`  AS  select `users`.`email` AS `Email`,`users`.`FullName` AS `FullName`,`users`.`username` AS `username` from `users` where ((not(`users`.`username` in (select `predictions`.`UserName` from `predictions` where (`predictions`.`GameWeek` = (select `gameweekmap`.`GameWeek` from `gameweekmap` where (`gameweekmap`.`DateTo` > (select now())) order by `gameweekmap`.`DateTo` limit 1))))) and (`users`.`CompStatus` = 'Playing') and (`users`.`PaymentStatus` = 'Paid')) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `clubs`
--
ALTER TABLE `clubs`
  ADD PRIMARY KEY (`ClubId`);

--
-- Indexes for table `fixtureresults`
--
ALTER TABLE `fixtureresults`
  ADD UNIQUE KEY `FixtureId` (`FixtureId`),
  ADD KEY `HomeTeam` (`HomeTeam`),
  ADD KEY `AwayTeam` (`AwayTeam`);

--
-- Indexes for table `gameweekmap`
--
ALTER TABLE `gameweekmap`
  ADD PRIMARY KEY (`GameWeek`);

--
-- Indexes for table `leagues`
--
ALTER TABLE `leagues`
  ADD PRIMARY KEY (`leagueId`);

--
-- Indexes for table `league_memberships`
--
ALTER TABLE `league_memberships`
  ADD PRIMARY KEY (`league_mem_id`);

--
-- Indexes for table `predictions`
--
ALTER TABLE `predictions`
  ADD PRIMARY KEY (`PredictionID`),
  ADD UNIQUE KEY `UserTeam` (`UserName`,`TeamName`),
  ADD UNIQUE KEY `UserGameWeek` (`GameWeek`,`UserName`),
  ADD KEY `User` (`UserName`(191)),
  ADD KEY `Fixture` (`FixtureID`),
  ADD KEY `DateTimeEntered` (`DateTimeEntered`);

--
-- Indexes for table `predictionstrash`
--
ALTER TABLE `predictionstrash`
  ADD PRIMARY KEY (`PredictionID`);

--
-- Indexes for table `userfeedback`
--
ALTER TABLE `userfeedback`
  ADD PRIMARY KEY (`commentId`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `clubs`
--
ALTER TABLE `clubs`
  MODIFY `ClubId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;
--
-- AUTO_INCREMENT for table `fixtureresults`
--
ALTER TABLE `fixtureresults`
  MODIFY `FixtureId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1715;
--
-- AUTO_INCREMENT for table `leagues`
--
ALTER TABLE `leagues`
  MODIFY `leagueId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=556;
--
-- AUTO_INCREMENT for table `league_memberships`
--
ALTER TABLE `league_memberships`
  MODIFY `league_mem_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;
--
-- AUTO_INCREMENT for table `predictions`
--
ALTER TABLE `predictions`
  MODIFY `PredictionID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=930;
--
-- AUTO_INCREMENT for table `predictionstrash`
--
ALTER TABLE `predictionstrash`
  MODIFY `PredictionID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=930;
--
-- AUTO_INCREMENT for table `userfeedback`
--
ALTER TABLE `userfeedback`
  MODIFY `commentId` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2089;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
