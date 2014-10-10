-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `insertPrediction`(
IN 
inFixtureID int(11),
inUserName varchar(255),
inPredictedResult int(11)
)
BEGIN

DECLARE inGameWeek int (11);
DECLARE inTeamName varchar(50);

SET inGameWeek =  (select GameWeek from gameweekmap where DateFrom > (select CURRENT_TIMESTAMP) order by DateFrom asc limit 1);

	IF inPredictedResult=1 THEN SET inTeamName=(select HomeTeam from fixtureresults where fixtureid = inFixtureId);
	ELSEIF inPredictedResult=3 THEN SET inTeamName=(select AwayTeam from fixtureresults where fixtureid = inFixtureId);
END IF;




insert into predictions (DateTimeEntered, FixtureID, GameWeek, UserName, TeamName, PredictedResult)
values
(
	(select CURRENT_TIMESTAMP),
	inFixtureID,
	inGameWeek,
	inUserName,
	inTeamName,
	inPredictedResult
);

END