DELIMITER $$

CREATE PROCEDURE `lastmanstanding`.`showUserPredictionHistory` (IN inUsername varchar(255))
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
on((`fixtureresults`.`FixtureId` = `predictions`.`FixtureID`))) where (`predictions`.`UserName`= inUsername);


END