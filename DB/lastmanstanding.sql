-- phpMyAdmin SQL Dump
-- version 4.2.5
-- http://www.phpmyadmin.net
--
-- Host: localhost:3306
-- Generation Time: Apr 22, 2015 at 07:21 AM
-- Server version: 5.5.36
-- PHP Version: 5.4.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `lastmanstanding`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `cancelPrediction`(IN `inPredictionID` INT(11), IN `inUserName` VARCHAR(255))
BEGIN

DECLARE deadline datetime;

SET deadline = (select DateFrom from gameweekmap where DateFrom > 
(select now()) 
order by DateFrom asc limit 1);

if ((select now()) < (select deadline))
THEN
update predictions set PredictionStatus='C' where PredictionID = inPredictionID;
insert into predictionstrash (select * from predictions  WHERE PredictionID = inPredictionID and username = inUserName COLLATE utf8_general_ci);
delete from predictions where PredictionID = inPredictionID and username = inUserName COLLATE utf8_general_ci;
SELECT ROW_COUNT() as ROWS_AFFECTED;
ELSE
SELECT ('too late') as ROWS_AFFECTED;
END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `checkResultsVsPredictions`()
BEGIN

create TEMPORARY table WinningPredictions as (SELECT PredictionID FROM showwinningpredictions);
create TEMPORARY table LoosingPredictions as (SELECT PredictionID FROM showloosingpredictions);
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

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `generateResetForUsername`(IN `inUsername` varchar(255), IN `inToken` VARCHAR(45))
BEGIN


insert into passwordresettokens (username, token, expiry)
values
(
	inUsername,
	inToken,
	(SELECT DATE_ADD((select NOW()), INTERVAL 10 MINUTE))
);




END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getNextFixtureForTeam`(in TeamNameLong varchar(50))
BEGIN

select * from fixtureresults where 
(HomeTeam = TeamNameLong 
or AwayTeam = TeamNameLong) and KickOffTime > (select now()) order by KickOffTime 
Limit 1;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insertPrediction`(IN `inFixtureID` INT(11), IN `inUserName` VARCHAR(255), IN `inPredictedResult` INT(11))
BEGIN

DECLARE inGameWeek int (11);
DECLARE inTeamName varchar(50);
DECLARE deadline datetime;

SET inGameWeek =  (select GameWeek from gameweekmap where DateFrom > (select CURRENT_TIMESTAMP) limit 1);

	IF inPredictedResult=1 THEN SET inTeamName=(select HomeTeam from fixtureresults where fixtureid = inFixtureId);
	ELSEIF inPredictedResult=3 THEN SET inTeamName=(select AwayTeam from fixtureresults where fixtureid = inFixtureId);
END IF;


SET deadline = (SELECT DATE_SUB(
(select DateFrom from gameweekmap where GameWeek = inGameWeek), INTERVAL 1 HOUR));


insert into predictions (DateTimeEntered, FixtureID, GameWeek, UserName, TeamName, PredictionStatus, PredictedResult)
values
(
	(select CURRENT_TIMESTAMP),
	inFixtureID,
	inGameWeek,
	inUserName,
	inTeamName,
    'A',
	inPredictedResult
);

SELECT LAST_INSERT_ID() as PredictionID;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `selectRandomTeam`(IN `inUser` VARCHAR(255))
    NO SQL
SELECT `LongName` FROM `clubs` WHERE `LongName` not in
(select `TeamName` from predictions where Username = inUser COLLATE utf8_general_ci) order by rand() limit 1$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAvailableTeamsForUser`(inUserName varchar(255))
BEGIN

select ClubId, LongName,MedName,ShortName from clubs 
where LongName not in (select TeamName from predictions where username = inUserName COLLATE utf8_general_ci and PredictionStatus='A');

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showCurrentStandings`()
BEGIN
select username, FullName, CompStatus from users where PaymentStatus='Paid';

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPredsByGameWeek`(IN `inGameWeek` INT)
    NO SQL
select * from predictions where gameweek=inGameWeek$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showUserCurrentSelection`(inUserName varchar(255))
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
        (`predictions`.`UserName` = inUserName COLLATE utf8_general_ci)
		and
		(`predictions`.`GameWeek` = inGameWeek)
		and
		(`predictions`.`PredictionStatus` = 'A');

END$$

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
(`predictions`.`UserName`= inUsername COLLATE utf8_general_ci and
`fixtureresults`.`KickOffTime` < 
/*(select DateTo from gameweekmap where DateFrom > (SELECT NOW()) limit 1));*/
(select NOW()));

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updatePaymentStatus`(
IN 
inUserName varchar(255),
inPayStat varchar(45)
)
BEGIN

update users set PaymentStatus=inPayStat where username=inUserName COLLATE utf8_general_ci;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `allfixturesandclubinfo`
--
CREATE TABLE IF NOT EXISTS `allfixturesandclubinfo` (
`FixtureId` int(11)
,`KickOffTime` datetime
,`HomeTeam` varchar(50)
,`AwayTeam` varchar(50)
,`ShortNameHome` varchar(8)
,`ShortNameAway` varchar(8)
,`MedNameHome` varchar(10)
,`MedNameAway` varchar(10)
,`HomeCrestImg` varchar(255)
,`AwayCrestImg` varchar(255)
);
-- --------------------------------------------------------

--
-- Table structure for table `clubs`
--

CREATE TABLE IF NOT EXISTS `clubs` (
`ClubId` int(11) NOT NULL,
  `LongName` varchar(100) NOT NULL,
  `MedName` varchar(10) NOT NULL,
  `ShortName` varchar(8) NOT NULL,
  `CrestURLSmall` varchar(255) NOT NULL,
  `CresURLLarge` varchar(255) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=21 ;

--
-- Dumping data for table `clubs`
--

INSERT INTO `clubs` (`ClubId`, `LongName`, `MedName`, `ShortName`, `CrestURLSmall`, `CresURLLarge`) VALUES
(1, 'Arsenal', 'Arsenal', 'ARS', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/a/arsenal/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/a/arsenal/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(2, 'Aston Villa', 'A. Villa', 'AVL', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/a/aston-villa/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/a/aston-villa/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(3, 'Burnley', 'Burnley', 'BUR', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/b/burnley/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/b/burnley/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(4, 'Chelsea', 'Chelsea', 'CHE', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/c/chelsea/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/c/chelsea/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(5, 'Crystal Palace', 'C. Palace', 'CRY', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/c/crystal-palace/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/c/crystal-palace/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(6, 'Everton', 'Everton', 'EVE', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/e/everton/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/e/everton/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(7, 'Hull City', 'Hull', 'HUL', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/h/hull/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/h/hull/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(8, 'Leicester City', 'Leicester', 'LEI', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/l/leicester/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/l/leicester/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(9, 'Liverpool', 'Liverpool', 'LIV', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/l/liverpool/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/l/liverpool/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(10, 'Manchester City', 'Man City', 'MCI', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/m/man-city/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/m/man-city/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(11, 'Manchester United', 'Man Utd', 'MUN', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/m/man-utd/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/m/man-utd/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(12, 'Newcastle United', 'Newcastle', 'NEW', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/n/newcastle/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/n/newcastle/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(13, 'Queens Park Rangers', 'QPR', 'QPR', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/q/qpr/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/q/qpr/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(14, 'Southampton', 'Southham', 'SOU', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/southampton/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/southampton/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(15, 'Stoke City', 'Stoke', 'STK', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/stoke/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/stoke/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(16, 'Sunderland', 'Sunderland', 'SUN', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/sunderland/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/sunderland/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(17, 'Swansea City', 'Swansea', 'SWA', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/swansea/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/swansea/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(18, 'Tottenham Hotspur', 'Spurs', 'TOT', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/spurs/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/s/spurs/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(19, 'West Bromwich Albion', 'West Brom', 'WBA', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/w/west-brom/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/w/west-brom/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png'),
(20, 'West Ham United', 'West Ham', 'WHU', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/w/west-ham/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png', 'http://www.premierleague.com/content/dam/premierleague/shared-images/clubs/w/west-ham/logo.png/_jcr_content/renditions/cq5dam.thumbnail.48.48.png');

-- --------------------------------------------------------

--
-- Stand-in structure for view `detailedpredictions`
--
CREATE TABLE IF NOT EXISTS `detailedpredictions` (
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

CREATE TABLE IF NOT EXISTS `fixtureresults` (
`FixtureId` int(11) NOT NULL,
  `KickOffTime` datetime NOT NULL,
  `HomeTeam` varchar(50) NOT NULL,
  `AwayTeam` varchar(50) NOT NULL,
  `HomeTeamScore` int(11) DEFAULT NULL,
  `AwayTeamScore` int(11) DEFAULT NULL,
  `Result` smallint(6) DEFAULT NULL COMMENT '1=Home Win2=Draw3=Away Win'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 COMMENT='Result (1=home win, 2=Draw, 3=away win)' AUTO_INCREMENT=405 ;

--
-- Dumping data for table `fixtureresults`
--

INSERT INTO `fixtureresults` (`FixtureId`, `KickOffTime`, `HomeTeam`, `AwayTeam`, `HomeTeamScore`, `AwayTeamScore`, `Result`) VALUES
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
(285, '2015-03-01 14:05:00', 'Arsenal', 'Everton', NULL, NULL, NULL),
(286, '2015-02-28 15:00:00', 'Burnley', 'Swansea City', NULL, NULL, NULL),
(287, '2015-04-29 19:45:00', 'Leicester City', 'Chelsea', NULL, NULL, NULL),
(288, '2015-03-01 12:00:00', 'Liverpool', 'Manchester City', NULL, NULL, NULL),
(289, '2015-02-28 15:00:00', 'Manchester United', 'Sunderland', NULL, NULL, NULL),
(290, '2015-02-28 15:00:00', 'Newcastle United', 'Aston Villa', NULL, NULL, NULL),
(291, '2015-03-07 15:00:00', 'Queens Park Rangers', 'Tottenham Hotspur', NULL, NULL, NULL),
(292, '2015-02-28 15:00:00', 'Stoke City', 'Hull City', NULL, NULL, NULL),
(293, '2015-02-28 15:00:00', 'West Bromwich Albion', 'Southampton', NULL, NULL, NULL),
(294, '2015-02-28 12:45:00', 'West Ham United', 'Crystal Palace', NULL, NULL, NULL),
(295, '2015-03-03 19:45:00', 'Aston Villa', 'West Bromwich Albion', NULL, NULL, NULL),
(296, '2015-03-03 19:45:00', 'Hull City', 'Sunderland', NULL, NULL, NULL),
(297, '2015-03-04 20:00:00', 'Liverpool', 'Burnley', NULL, NULL, NULL),
(298, '2015-03-04 19:45:00', 'Queens Park Rangers', 'Arsenal', NULL, NULL, NULL),
(299, '2015-03-03 19:45:00', 'Southampton', 'Crystal Palace', NULL, NULL, NULL),
(300, '2015-03-04 19:45:00', 'West Ham United', 'Chelsea', NULL, NULL, NULL),
(301, '2015-03-04 19:45:00', 'Manchester City', 'Leicester City', NULL, NULL, NULL),
(302, '2015-03-04 19:45:00', 'Newcastle United', 'Manchester United', NULL, NULL, NULL),
(303, '2015-03-04 19:45:00', 'Stoke City', 'Everton', NULL, NULL, NULL),
(304, '2015-03-04 19:45:00', 'Tottenham Hotspur', 'Swansea City', NULL, NULL, NULL),
(305, '2015-03-14 15:00:00', 'Arsenal', 'West Ham United', NULL, NULL, NULL),
(306, '2015-03-14 17:30:00', 'Burnley', 'Manchester City', NULL, NULL, NULL),
(307, '2015-03-15 13:30:00', 'Chelsea', 'Southampton', NULL, NULL, NULL),
(308, '2015-03-14 12:45:00', 'Crystal Palace', 'Queens Park Rangers', NULL, NULL, NULL),
(309, '2015-03-14 15:00:00', 'Everton', 'Newcastle United', NULL, NULL, NULL),
(310, '2015-03-14 15:00:00', 'Leicester City', 'Hull City', NULL, NULL, NULL),
(311, '2015-03-15 16:00:00', 'Manchester United', 'Tottenham Hotspur', NULL, NULL, NULL),
(312, '2015-03-14 15:00:00', 'Sunderland', 'Aston Villa', NULL, NULL, NULL),
(313, '2015-03-16 20:00:00', 'Swansea City', 'Liverpool', NULL, NULL, NULL),
(314, '2015-03-14 15:00:00', 'West Bromwich Albion', 'Stoke City', NULL, NULL, NULL),
(315, '2015-03-21 15:00:00', 'Aston Villa', 'Swansea City', NULL, NULL, NULL),
(316, '2015-03-21 15:00:00', 'Hull City', 'Chelsea', NULL, NULL, NULL),
(317, '2015-03-21 15:00:00', 'Liverpool', 'Manchester United', NULL, NULL, NULL),
(318, '2015-03-21 15:00:00', 'Manchester City', 'West Bromwich Albion', NULL, NULL, NULL),
(319, '2015-03-21 15:00:00', 'Newcastle United', 'Arsenal', NULL, NULL, NULL),
(320, '2015-03-21 15:00:00', 'Queens Park Rangers', 'Everton', NULL, NULL, NULL),
(321, '2015-03-21 15:00:00', 'Southampton', 'Burnley', NULL, NULL, NULL),
(322, '2015-03-21 15:00:00', 'Stoke City', 'Crystal Palace', NULL, NULL, NULL),
(323, '2015-03-21 15:00:00', 'Tottenham Hotspur', 'Leicester City', NULL, NULL, NULL),
(324, '2015-03-21 15:00:00', 'West Ham United', 'Sunderland', NULL, NULL, NULL),
(325, '2015-04-04 15:00:00', 'Arsenal', 'Liverpool', NULL, NULL, NULL),
(326, '2015-04-04 15:00:00', 'Burnley', 'Tottenham Hotspur', NULL, NULL, NULL),
(327, '2015-04-04 15:00:00', 'Chelsea', 'Stoke City', NULL, NULL, NULL),
(328, '2015-04-04 15:00:00', 'Crystal Palace', 'Manchester City', NULL, NULL, NULL),
(329, '2015-04-04 15:00:00', 'Everton', 'Southampton', NULL, NULL, NULL),
(330, '2015-04-04 15:00:00', 'Leicester City', 'West Ham United', NULL, NULL, NULL),
(331, '2015-04-04 15:00:00', 'Manchester United', 'Aston Villa', NULL, NULL, NULL),
(332, '2015-04-04 15:00:00', 'Sunderland', 'Newcastle United', NULL, NULL, NULL),
(333, '2015-04-04 15:00:00', 'Swansea City', 'Hull City', NULL, NULL, NULL),
(334, '2015-04-04 15:00:00', 'West Bromwich Albion', 'Queens Park Rangers', NULL, NULL, NULL),
(335, '2015-04-11 15:00:00', 'Burnley', 'Arsenal', NULL, NULL, NULL),
(336, '2015-04-11 15:00:00', 'Liverpool', 'Newcastle United', NULL, NULL, NULL),
(337, '2015-04-11 15:00:00', 'Manchester United', 'Manchester City', NULL, NULL, NULL),
(338, '2015-04-11 15:00:00', 'Queens Park Rangers', 'Chelsea', NULL, NULL, NULL),
(339, '2015-04-11 15:00:00', 'Southampton', 'Hull City', NULL, NULL, NULL),
(340, '2015-04-11 15:00:00', 'Sunderland', 'Crystal Palace', NULL, NULL, NULL),
(341, '2015-04-11 15:00:00', 'Swansea City', 'Everton', NULL, NULL, NULL),
(342, '2015-04-11 15:00:00', 'Tottenham Hotspur', 'Aston Villa', NULL, NULL, NULL),
(343, '2015-04-11 15:00:00', 'West Bromwich Albion', 'Leicester City', NULL, NULL, NULL),
(344, '2015-04-11 15:00:00', 'West Ham United', 'Stoke City', NULL, NULL, NULL),
(345, '2015-04-18 15:00:00', 'Arsenal', 'Sunderland', NULL, NULL, NULL),
(346, '2015-04-18 15:00:00', 'Aston Villa', 'Queens Park Rangers', NULL, NULL, NULL),
(347, '2015-04-18 15:00:00', 'Chelsea', 'Manchester United', NULL, NULL, NULL),
(348, '2015-04-18 15:00:00', 'Crystal Palace', 'West Bromwich Albion', NULL, NULL, NULL),
(349, '2015-04-18 15:00:00', 'Everton', 'Burnley', NULL, NULL, NULL),
(350, '2015-04-18 15:00:00', 'Hull City', 'Liverpool', NULL, NULL, NULL),
(351, '2015-04-18 15:00:00', 'Leicester City', 'Swansea City', NULL, NULL, NULL),
(352, '2015-04-18 15:00:00', 'Manchester City', 'West Ham United', NULL, NULL, NULL),
(353, '2015-04-18 15:00:00', 'Newcastle United', 'Tottenham Hotspur', NULL, NULL, NULL),
(354, '2015-04-18 15:00:00', 'Stoke City', 'Southampton', NULL, NULL, NULL),
(355, '2015-04-25 15:00:00', 'Arsenal', 'Chelsea', NULL, NULL, NULL),
(356, '2015-04-25 15:00:00', 'Burnley', 'Leicester City', NULL, NULL, NULL),
(357, '2015-04-25 15:00:00', 'Crystal Palace', 'Hull City', NULL, NULL, NULL),
(358, '2015-04-25 15:00:00', 'Everton', 'Manchester United', NULL, NULL, NULL),
(359, '2015-04-25 15:00:00', 'Manchester City', 'Aston Villa', NULL, NULL, NULL),
(360, '2015-04-25 15:00:00', 'Newcastle United', 'Swansea City', NULL, NULL, NULL),
(361, '2015-04-25 15:00:00', 'Queens Park Rangers', 'West Ham United', NULL, NULL, NULL),
(362, '2015-04-25 15:00:00', 'Southampton', 'Tottenham Hotspur', NULL, NULL, NULL),
(363, '2015-04-25 15:00:00', 'Stoke City', 'Sunderland', NULL, NULL, NULL),
(364, '2015-04-25 15:00:00', 'West Bromwich Albion', 'Liverpool', NULL, NULL, NULL),
(365, '2015-05-02 15:00:00', 'Aston Villa', 'Everton', NULL, NULL, NULL),
(366, '2015-05-02 15:00:00', 'Chelsea', 'Crystal Palace', NULL, NULL, NULL),
(367, '2015-05-02 15:00:00', 'Hull City', 'Arsenal', NULL, NULL, NULL),
(368, '2015-05-02 15:00:00', 'Leicester City', 'Newcastle United', NULL, NULL, NULL),
(369, '2015-05-02 15:00:00', 'Liverpool', 'Queens Park Rangers', NULL, NULL, NULL),
(370, '2015-05-02 15:00:00', 'Manchester United', 'West Bromwich Albion', NULL, NULL, NULL),
(371, '2015-05-02 15:00:00', 'Sunderland', 'Southampton', NULL, NULL, NULL),
(372, '2015-05-02 15:00:00', 'Swansea City', 'Stoke City', NULL, NULL, NULL),
(373, '2015-05-02 15:00:00', 'Tottenham Hotspur', 'Manchester City', NULL, NULL, NULL),
(374, '2015-05-02 15:00:00', 'West Ham United', 'Burnley', NULL, NULL, NULL),
(375, '2015-05-09 15:00:00', 'Arsenal', 'Swansea City', NULL, NULL, NULL),
(376, '2015-05-09 15:00:00', 'Aston Villa', 'West Ham United', NULL, NULL, NULL),
(377, '2015-05-09 15:00:00', 'Chelsea', 'Liverpool', NULL, NULL, NULL),
(378, '2015-05-09 15:00:00', 'Crystal Palace', 'Manchester United', NULL, NULL, NULL),
(379, '2015-05-09 15:00:00', 'Everton', 'Sunderland', NULL, NULL, NULL),
(380, '2015-05-09 15:00:00', 'Hull City', 'Burnley', NULL, NULL, NULL),
(381, '2015-05-09 15:00:00', 'Leicester City', 'Southampton', NULL, NULL, NULL),
(382, '2015-05-09 15:00:00', 'Manchester City', 'Queens Park Rangers', NULL, NULL, NULL),
(383, '2015-05-09 15:00:00', 'Newcastle United', 'West Bromwich Albion', NULL, NULL, NULL),
(384, '2015-05-09 15:00:00', 'Stoke City', 'Tottenham Hotspur', NULL, NULL, NULL),
(385, '2015-05-16 15:00:00', 'Burnley', 'Stoke City', NULL, NULL, NULL),
(386, '2015-05-16 15:00:00', 'Liverpool', 'Crystal Palace', NULL, NULL, NULL),
(387, '2015-05-16 15:00:00', 'Manchester United', 'Arsenal', NULL, NULL, NULL),
(388, '2015-05-16 15:00:00', 'Queens Park Rangers', 'Newcastle United', NULL, NULL, NULL),
(389, '2015-05-16 15:00:00', 'Southampton', 'Aston Villa', NULL, NULL, NULL),
(390, '2015-05-16 15:00:00', 'Sunderland', 'Leicester City', NULL, NULL, NULL),
(391, '2015-05-16 15:00:00', 'Swansea City', 'Manchester City', NULL, NULL, NULL),
(392, '2015-05-16 15:00:00', 'Tottenham Hotspur', 'Hull City', NULL, NULL, NULL),
(393, '2015-05-16 15:00:00', 'West Bromwich Albion', 'Chelsea', NULL, NULL, NULL),
(394, '2015-05-16 15:00:00', 'West Ham United', 'Everton', NULL, NULL, NULL),
(395, '2015-05-24 15:00:00', 'Arsenal', 'West Bromwich Albion', NULL, NULL, NULL),
(396, '2015-05-24 15:00:00', 'Aston Villa', 'Burnley', NULL, NULL, NULL),
(397, '2015-05-24 15:00:00', 'Chelsea', 'Sunderland', NULL, NULL, NULL),
(398, '2015-05-24 15:00:00', 'Crystal Palace', 'Swansea City', NULL, NULL, NULL),
(399, '2015-05-24 15:00:00', 'Everton', 'Tottenham Hotspur', NULL, NULL, NULL),
(400, '2015-05-24 15:00:00', 'Hull City', 'Manchester United', NULL, NULL, NULL),
(401, '2015-05-24 15:00:00', 'Leicester City', 'Queens Park Rangers', NULL, NULL, NULL),
(402, '2015-05-24 15:00:00', 'Manchester City', 'Southampton', NULL, NULL, NULL),
(403, '2015-05-24 15:00:00', 'Newcastle United', 'West Ham United', NULL, NULL, NULL),
(404, '2015-05-24 15:00:00', 'Stoke City', 'Liverpool', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `gameweekmap`
--

CREATE TABLE IF NOT EXISTS `gameweekmap` (
  `GameWeek` int(11) NOT NULL,
  `DateFrom` datetime NOT NULL,
  `DateTo` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `gameweekmap`
--

INSERT INTO `gameweekmap` (`GameWeek`, `DateFrom`, `DateTo`) VALUES
(6, '2014-09-27 00:00:00', '2014-09-29 23:59:00'),
(7, '2014-10-04 00:00:00', '2014-10-05 23:59:00'),
(8, '2014-10-18 00:00:00', '2014-10-20 23:59:00'),
(9, '2014-10-25 00:00:00', '2014-10-27 23:59:00'),
(10, '2014-11-01 00:00:00', '2014-11-03 23:59:00'),
(11, '2014-11-08 00:00:00', '2014-11-09 23:59:00'),
(12, '2014-11-22 00:00:00', '2014-11-24 23:59:00'),
(13, '2014-11-29 00:00:00', '2014-11-30 23:00:00'),
(14, '2014-12-02 00:00:00', '2014-12-03 23:59:00'),
(15, '2014-12-06 00:00:00', '2014-12-08 23:00:00'),
(16, '2014-12-13 14:00:00', '2014-12-15 22:10:59'),
(17, '2014-12-20 12:00:00', '2014-12-22 23:59:59'),
(18, '2014-12-26 00:00:00', '2014-12-26 23:00:00'),
(20, '2015-01-01 16:00:00', '2015-01-01 23:59:00'),
(21, '2015-01-10 12:45:00', '2015-01-11 23:59:59'),
(22, '2015-01-17 14:00:00', '2015-01-19 23:59:59'),
(23, '2015-01-31 11:45:00', '2015-02-01 23:59:59'),
(24, '2015-02-07 11:45:00', '2015-02-08 19:00:00'),
(25, '2015-02-10 18:45:00', '2015-02-11 08:30:00'),
(27, '2015-02-28 11:45:00', '2015-03-01 17:00:00'),
(28, '2015-02-03 19:45:00', '2015-03-04 23:59:59'),
(29, '2015-03-14 11:45:00', '2015-03-16 23:59:00');

-- --------------------------------------------------------

--
-- Table structure for table `passwordresettokens`
--

CREATE TABLE IF NOT EXISTS `passwordresettokens` (
`idpasswordResetTokens` int(11) NOT NULL,
  `token` varchar(45) NOT NULL,
  `username` varchar(255) NOT NULL,
  `expiry` datetime NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=45 ;

--
-- Dumping data for table `passwordresettokens`
--

INSERT INTO `passwordresettokens` (`idpasswordResetTokens`, `token`, `username`, `expiry`) VALUES
(39, '3815e33b5b9eddea', 'jbligh', '2015-04-22 10:46:47'),
(40, '4f859e3151b8a093', 'jamesoneill', '2015-04-22 10:47:07'),
(41, '595295a1bc2fd0f', 'mjnolan', '2015-04-22 10:47:53'),
(42, 'de6b4a77943b731', 'tommygrealy', '2015-04-22 10:48:51'),
(43, '62104f524024e3c', 'tommygrealy', '2015-04-22 10:55:23'),
(44, '1f7f282d3d28518e', 'tommygrealy', '2015-04-22 10:55:56');

-- --------------------------------------------------------

--
-- Table structure for table `predictions`
--

CREATE TABLE IF NOT EXISTS `predictions` (
  `DateTimeEntered` datetime DEFAULT NULL,
  `EntryType` varchar(10) NOT NULL,
`PredictionID` int(11) NOT NULL,
  `GameWeek` int(11) DEFAULT NULL,
  `FixtureID` int(11) NOT NULL,
  `UserName` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `TeamName` varchar(50) DEFAULT NULL,
  `PredictedResult` int(11) NOT NULL COMMENT '1=home win;2=draw; 3=away win',
  `PredictionStatus` varchar(8) NOT NULL COMMENT 'A=Active;C=Cancelled',
  `PredictionCorrect` bit(1) DEFAULT NULL COMMENT '1=correct, 0=incorrect'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=359 ;

--
-- Dumping data for table `predictions`
--

INSERT INTO `predictions` (`DateTimeEntered`, `EntryType`, `PredictionID`, `GameWeek`, `FixtureID`, `UserName`, `TeamName`, `PredictedResult`, `PredictionStatus`, `PredictionCorrect`) VALUES
('2015-02-25 12:08:50', '', 353, 27, 294, 'monkey', 'West Ham United', 1, 'A', NULL),
('2015-02-25 12:20:41', '', 355, 27, 289, 'tommygrealy', 'Manchester United', 1, 'A', NULL),
('2015-02-25 15:23:53', '', 356, 27, 292, 'kmacken', 'Stoke City', 1, 'A', NULL),
('2015-02-26 10:59:02', '', 357, 27, 294, 'mjnolan', 'West Ham United', 1, 'A', NULL),
('2015-02-26 11:29:39', '', 358, 27, 292, 'Rob', 'Stoke City', 1, 'A', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `predictionstrash`
--

CREATE TABLE IF NOT EXISTS `predictionstrash` (
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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=328 ;

--
-- Dumping data for table `predictionstrash`
--

INSERT INTO `predictionstrash` (`DateTimeEntered`, `EntryType`, `PredictionID`, `GameWeek`, `FixtureID`, `UserName`, `TeamName`, `PredictedResult`, `PredictionStatus`, `PredictionCorrect`) VALUES
('2015-02-20 19:55:26', '', 289, 26, 280, 'tommygrealy', 'Manchester City', 1, 'C', NULL),
('2015-02-20 19:57:24', '', 290, 26, 280, 'tommygrealy', 'Manchester City', 1, 'A', NULL),
('2015-02-20 19:57:53', '', 291, 26, 281, 'tommygrealy', 'Southampton', 1, 'A', NULL),
('2015-02-23 10:38:48', '', 292, 27, 292, 'tommygrealy', 'Stoke City', 1, 'A', NULL),
('2015-02-24 11:18:51', '', 293, 27, 290, 'tommygrealy', 'Newcastle United', 1, 'C', NULL),
('2015-02-24 11:45:38', '', 294, 27, 294, 'tommygrealy', 'Crystal Palace', 3, 'C', NULL),
('2015-02-24 12:06:28', '', 295, 27, 294, 'tommygrealy', 'Crystal Palace', 3, 'C', NULL),
('2015-02-24 12:09:29', '', 296, 27, 290, 'tommygrealy', 'Aston Villa', 3, 'C', NULL),
('2015-02-24 12:12:45', '', 297, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 12:12:56', '', 298, 27, 290, 'tommygrealy', 'Aston Villa', 3, 'C', NULL),
('2015-02-24 12:13:05', '', 299, 27, 293, 'tommygrealy', 'Southampton', 3, 'C', NULL),
('2015-02-24 12:13:13', '', 300, 27, 293, 'tommygrealy', 'West Bromwich Albion', 1, 'C', NULL),
('2015-02-24 13:49:23', '', 301, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:04:35', '', 302, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:06:34', '', 303, 27, 294, 'tommygrealy', 'Crystal Palace', 3, 'C', NULL),
('2015-02-24 14:06:44', '', 304, 27, 288, 'tommygrealy', 'Manchester City', 3, 'C', NULL),
('2015-02-24 14:07:57', '', 305, 27, 289, 'tommygrealy', 'Manchester United', 1, 'C', NULL),
('2015-02-24 14:09:52', '', 306, 27, 288, 'tommygrealy', 'Manchester City', 3, 'C', NULL),
('2015-02-24 14:14:12', '', 307, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:16:49', '', 308, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:17:28', '', 309, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:17:35', '', 310, 27, 292, 'tommygrealy', 'Stoke City', 1, 'C', NULL),
('2015-02-24 14:17:43', '', 311, 27, 293, 'tommygrealy', 'West Bromwich Albion', 1, 'C', NULL),
('2015-02-24 14:17:52', '', 312, 27, 285, 'tommygrealy', 'Arsenal', 1, 'C', NULL),
('2015-02-24 14:18:01', '', 313, 27, 288, 'tommygrealy', 'Liverpool', 1, 'C', NULL),
('2015-02-24 14:18:45', '', 314, 27, 285, 'tommygrealy', 'Everton', 3, 'C', NULL),
('2015-02-24 14:18:58', '', 315, 27, 293, 'tommygrealy', 'West Bromwich Albion', 1, 'C', NULL),
('2015-02-24 14:19:09', '', 316, 27, 289, 'tommygrealy', 'Sunderland', 3, 'C', NULL),
('2015-02-24 14:19:55', '', 317, 27, 292, 'tommygrealy', 'Hull City', 3, 'C', NULL),
('2015-02-24 14:20:01', '', 318, 27, 286, 'tommygrealy', 'Swansea City', 3, 'C', NULL),
('2015-02-24 14:33:14', '', 319, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:34:06', '', 320, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:34:19', '', 321, 27, 290, 'tommygrealy', 'Newcastle United', 1, 'C', NULL),
('2015-02-24 14:34:27', '', 322, 27, 292, 'tommygrealy', 'Hull City', 3, 'C', NULL),
('2015-02-24 14:34:40', '', 323, 27, 289, 'tommygrealy', 'Sunderland', 3, 'C', NULL),
('2015-02-24 14:34:50', '', 324, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:49:36', '', 325, 27, 294, 'tommygrealy', 'West Ham United', 1, 'C', NULL),
('2015-02-24 14:49:41', '', 326, 27, 289, 'tommygrealy', 'Sunderland', 3, 'C', NULL),
('2015-02-24 15:49:52', '', 327, NULL, 288, 'tommygrealy', 'Manchester City', 3, 'C', NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `showloosingpredictions`
--
CREATE TABLE IF NOT EXISTS `showloosingpredictions` (
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
CREATE TABLE IF NOT EXISTS `showwinningpredictions` (
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

CREATE TABLE IF NOT EXISTS `status` (
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
-- Stand-in structure for view `thisweeksfixtures`
--
CREATE TABLE IF NOT EXISTS `thisweeksfixtures` (
`FixtureId` int(11)
,`KickOffTime` datetime
,`HomeTeam` varchar(50)
,`AwayTeam` varchar(50)
,`ShortNameHome` varchar(8)
,`ShortNameAway` varchar(8)
,`MedNameHome` varchar(10)
,`MedNameAway` varchar(10)
,`HomeCrestImg` varchar(255)
,`AwayCrestImg` varchar(255)
);
-- --------------------------------------------------------

--
-- Table structure for table `userfeedback`
--

CREATE TABLE IF NOT EXISTS `userfeedback` (
`commentId` int(11) NOT NULL,
  `commentUserName` varchar(100) DEFAULT NULL,
  `commentEmail` varchar(100) DEFAULT NULL,
  `commentText` text,
  `commentDate` datetime DEFAULT NULL,
  `commentReplySent` binary(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
`id` int(11) NOT NULL,
  `username` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `privlevel` int(11) DEFAULT NULL,
  `FullName` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` char(64) COLLATE utf8_unicode_ci NOT NULL,
  `salt` char(16) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `CompStatus` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `PaymentStatus` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=2057 ;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `privlevel`, `FullName`, `password`, `salt`, `email`, `CompStatus`, `PaymentStatus`) VALUES
(2041, 'tommygrealy', 5, 'Tommy Grealy', '9bee4021cb6373bbb36ef9fc0a0de96a1da025024a49d00cbcb7f3a5d6927c13', '12c35acf6fde1c66', 'tommy.grealy@intel.com', 'Playing', 'Paid'),
(2042, 'jamesoneill', 1, 'James O''Neill', '27bb94c49c5361c3525af95026f5337b748c3cec02ccf88be780e86d3ba8e8d8', '44ee29c07d65a476', 'james.a.o''neill@intel.com', 'Playing', 'Paid'),
(2043, 'declancotter', 1, 'Declan Cotter', '1875f1ff59cfef14d63c322bbcff0616a446c71e22877316f0fd1b076edff095', '40edec6e6dd62bc4', 'declan.cotter@intel.com', 'Playing', 'Paid'),
(2044, 'mjnolan', 1, 'mike nolan', '0754ea964594eba7f6b6c8bf4e21fe3b11c9d493b1db3e8190ca3e10ddb3531e', '73f537597ba2fbaa', 'michael.nolan@intel.com', 'Playing', 'Paid'),
(2045, 'JohnLynch1982', 1, 'John Lynch', '54658097a78a65db548da9b3122ecff22e8dbeec48d7dc423c5d606deaf50870', 'ce64ca04950dfb7', 'john.lynch@intel.com', 'Playing', 'Paid'),
(2046, 'monkey', 1, 'Pat Guerin', '553444ca74412f66853b074035fb8b0dda447ddab2f3764d255f59fe48ee831c', '698dd37229928f09', 'patrick.guerin@intel.com', 'Playing', 'Paid'),
(2047, 'tonydoyle', 1, 'Tony Doyle', '95e3783bbe397b91b2c314ca06a1edcc854d4de79380d6d2c1e51558b20a8578', '378b8db242f1183f', 'anthonyx.doyle@intel.com', 'Playing', 'IOY'),
(2048, 'kmacken', 1, 'Kieran Macken', '1743e9472114cac5716f7f5c50dbd871210cd008fc6ba48c17008bbfb8030aec', 'fcfd1154d4cea0d', 'kieran.j.macken@intel.com', 'Playing', 'Paid'),
(2049, 'Rodge', 1, 'Rodger Mooney', 'b7ba54fa6f50e27cd9946cc88bad693e9652bed3248ed7b878cb0edc3f2c808b', '81e304938d9a4e2', 'rodger.mooney@intel.com', 'Playing', 'IOY'),
(2050, 'jbligh', 1, 'John Bligh', 'bb5b0b36e652088c537ccc7ca4beb77e2fabea73e94ddd32101ea067e87e553e', '2c8deec4158b889c', 'john.bligh@intel.com', 'Playing', 'IOY'),
(2051, 'Gforde', 1, 'Gerard Forde', 'fc3afe953716a0c5a5c65b5a0f9698981cd6704b0370a03c45dfc8d22b3cd009', '2419bd005367df3a', 'Gerard.m.forde@intel.com', 'Playing', 'Pending'),
(2052, 'telordan', 1, 'Thomas', '45867e58ab21df185ccd7e5ba852ccabbd981284de57b0987e1b57e684298278', '5c154aa5712ecfa3', 'thomas.e.lordan@intel.com', 'Playing', 'Pending'),
(2053, 'shethert', 1, 'Seamus Hetherton', '224426ad6e0405b8c3209db29bba0e839625d8cd91507030209806c95f0b0c0a', '61c2e6a43c941072', 'seamus.p.hetherton@intel.com', 'Playing', 'Paid'),
(2056, 'Rob', 1, 'Rob Buggle', '1ad304ee31a65fd47518cb1132e2134507a589d5d5352ed11b228b8c42823828', '3b238d031d11cc5d', 'robert.m.buggle@intel.com', 'Playing', 'Paid');

-- --------------------------------------------------------

--
-- Stand-in structure for view `usersnotsubmitted`
--
CREATE TABLE IF NOT EXISTS `usersnotsubmitted` (
`Email` varchar(255)
,`FullName` varchar(45)
,`username` varchar(255)
);
-- --------------------------------------------------------

--
-- Structure for view `allfixturesandclubinfo`
--
DROP TABLE IF EXISTS `allfixturesandclubinfo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `allfixturesandclubinfo` AS select distinct `fr`.`FixtureId` AS `FixtureId`,`fr`.`KickOffTime` AS `KickOffTime`,`fr`.`HomeTeam` AS `HomeTeam`,`fr`.`AwayTeam` AS `AwayTeam`,(select `clubs`.`ShortName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8))) AS `ShortNameHome`,(select `clubs`.`ShortName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8))) AS `ShortNameAway`,(select `clubs`.`MedName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8))) AS `MedNameHome`,(select `clubs`.`MedName` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8))) AS `MedNameAway`,(select `clubs`.`CrestURLSmall` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`HomeTeam` using utf8))) AS `HomeCrestImg`,(select `clubs`.`CrestURLSmall` from `clubs` where (`clubs`.`LongName` = convert(`fr`.`AwayTeam` using utf8))) AS `AwayCrestImg` from (`fixtureresults` `fr` join `clubs` `cl`) where ((convert(`fr`.`HomeTeam` using utf8) = `cl`.`LongName`) or (convert(`fr`.`AwayTeam` using utf8) = `cl`.`LongName`)) order by `fr`.`KickOffTime`;

-- --------------------------------------------------------

--
-- Structure for view `detailedpredictions`
--
DROP TABLE IF EXISTS `detailedpredictions`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `detailedpredictions` AS select `users`.`FullName` AS `FullName`,`users`.`email` AS `email`,`fixtureresults`.`KickOffTime` AS `KickOffTime`,(select concat(`fixtureresults`.`HomeTeam`,' vs ',`fixtureresults`.`AwayTeam`)) AS `FixtureDetail`,`predictions`.`TeamName` AS `User Selected`,`predictions`.`DateTimeEntered` AS `DateTimeEntered`,`predictions`.`PredictionID` AS `PredictionID` from ((`users` join `predictions` on((`users`.`username` = `predictions`.`UserName`))) join `fixtureresults` on((`predictions`.`FixtureID` = `fixtureresults`.`FixtureId`)));

-- --------------------------------------------------------

--
-- Structure for view `showloosingpredictions`
--
DROP TABLE IF EXISTS `showloosingpredictions`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `showloosingpredictions` AS select `fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`Result` AS `Result`,`predictions`.`PredictionID` AS `PredictionID`,`predictions`.`UserName` AS `username`,`predictions`.`PredictedResult` AS `PredictedResult` from (`fixtureresults` join `predictions` on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where ((`fixtureresults`.`Result` <> `predictions`.`PredictedResult`) and (`fixtureresults`.`Result` is not null));

-- --------------------------------------------------------

--
-- Structure for view `showwinningpredictions`
--
DROP TABLE IF EXISTS `showwinningpredictions`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `showwinningpredictions` AS select `fixtureresults`.`KickOffTime` AS `KickOffTime`,`fixtureresults`.`FixtureId` AS `FixtureId`,`fixtureresults`.`HomeTeam` AS `HomeTeam`,`fixtureresults`.`AwayTeam` AS `AwayTeam`,`fixtureresults`.`Result` AS `Result`,`predictions`.`PredictionID` AS `PredictionID`,`predictions`.`UserName` AS `username`,`predictions`.`PredictedResult` AS `PredictedResult` from (`fixtureresults` join `predictions` on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where (`fixtureresults`.`Result` = `predictions`.`PredictedResult`);

-- --------------------------------------------------------

--
-- Structure for view `thisweeksfixtures`
--
DROP TABLE IF EXISTS `thisweeksfixtures`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `thisweeksfixtures` AS select `allfixturesandclubinfo`.`FixtureId` AS `FixtureId`,`allfixturesandclubinfo`.`KickOffTime` AS `KickOffTime`,`allfixturesandclubinfo`.`HomeTeam` AS `HomeTeam`,`allfixturesandclubinfo`.`AwayTeam` AS `AwayTeam`,`allfixturesandclubinfo`.`ShortNameHome` AS `ShortNameHome`,`allfixturesandclubinfo`.`ShortNameAway` AS `ShortNameAway`,`allfixturesandclubinfo`.`MedNameHome` AS `MedNameHome`,`allfixturesandclubinfo`.`MedNameAway` AS `MedNameAway`,`allfixturesandclubinfo`.`HomeCrestImg` AS `HomeCrestImg`,`allfixturesandclubinfo`.`AwayCrestImg` AS `AwayCrestImg` from `allfixturesandclubinfo` where (`allfixturesandclubinfo`.`KickOffTime` between (select `gameweekmap`.`DateFrom` from `gameweekmap` where (`gameweekmap`.`DateFrom` > (select now())) order by `gameweekmap`.`DateFrom` limit 1) and (select `gameweekmap`.`DateTo` from `gameweekmap` where (`gameweekmap`.`DateTo` > (select now())) order by `gameweekmap`.`DateTo` limit 1)) order by `allfixturesandclubinfo`.`KickOffTime`;

-- --------------------------------------------------------

--
-- Structure for view `usersnotsubmitted`
--
DROP TABLE IF EXISTS `usersnotsubmitted`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `usersnotsubmitted` AS select `users`.`email` AS `Email`,`users`.`FullName` AS `FullName`,`users`.`username` AS `username` from `users` where ((not(`users`.`username` in (select `predictions`.`UserName` from `predictions` where (`predictions`.`GameWeek` = (select `gameweekmap`.`GameWeek` from `gameweekmap` where (`gameweekmap`.`DateFrom` > (select now())) order by `gameweekmap`.`DateFrom` limit 1))))) and (`users`.`CompStatus` = 'Playing') and (`users`.`PaymentStatus` = 'Paid'));

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
 ADD UNIQUE KEY `FixtureId` (`FixtureId`);

--
-- Indexes for table `gameweekmap`
--
ALTER TABLE `gameweekmap`
 ADD PRIMARY KEY (`GameWeek`);

--
-- Indexes for table `passwordresettokens`
--
ALTER TABLE `passwordresettokens`
 ADD PRIMARY KEY (`idpasswordResetTokens`);

--
-- Indexes for table `predictions`
--
ALTER TABLE `predictions`
 ADD PRIMARY KEY (`PredictionID`), ADD UNIQUE KEY `UserTeam` (`UserName`,`TeamName`), ADD UNIQUE KEY `UserGameWeek` (`GameWeek`,`UserName`), ADD KEY `User` (`UserName`(191)), ADD KEY `Fixture` (`FixtureID`), ADD KEY `DateTimeEntered` (`DateTimeEntered`);

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
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `username` (`username`), ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `clubs`
--
ALTER TABLE `clubs`
MODIFY `ClubId` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=21;
--
-- AUTO_INCREMENT for table `fixtureresults`
--
ALTER TABLE `fixtureresults`
MODIFY `FixtureId` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=405;
--
-- AUTO_INCREMENT for table `passwordresettokens`
--
ALTER TABLE `passwordresettokens`
MODIFY `idpasswordResetTokens` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=45;
--
-- AUTO_INCREMENT for table `predictions`
--
ALTER TABLE `predictions`
MODIFY `PredictionID` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=359;
--
-- AUTO_INCREMENT for table `predictionstrash`
--
ALTER TABLE `predictionstrash`
MODIFY `PredictionID` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=328;
--
-- AUTO_INCREMENT for table `userfeedback`
--
ALTER TABLE `userfeedback`
MODIFY `commentId` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2057;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
