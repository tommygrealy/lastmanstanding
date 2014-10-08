<?php
//ini_set('display_errors', '1');

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../objects/userSelectionOptionsResponse.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();

$response=new userSelectionOptionsResponse;


if (empty($_SESSION['user'])) {
    $requestStatus = new requestStatus();
    $requestStatus->status = 0;
    $requestStatus->reason = "No valid user is logged in";
    echo json_encode($requestStatus);
    die();
}

$current_user = ($_SESSION['user']['username']);



$HasUserPredictedThisWeek=$dal->getUserSelectionForThisWeek($current_user);
if(count($HasUserPredictedThisWeek)>0){
    echo json_encode($HasUserPredictedThisWeek);
    die();
} 

$teamsAvilable = $dal->getTeamsAvilableToUser($current_user);
$fixtureList = $dal->getThisWeeksFixtures();

for ($i=0;$i<count($teamsAvilable);$i++){
    $shortNamesAvail[$i]=$teamsAvilable[$i]["ShortName"];
}

//TODO: reformat fixture list output to be an associative array with the FixtureId as the key for each element
// [89:{KickOffTime: "2014-12-01 16:00, HomeTeam: "Manu"},90:{}]

    
$response->availableTeams=$shortNamesAvail;
$response->fixtures=$fixtureList;
echo json_encode($response);

//echo $teamsAvilable[2]["ShortName"];
//echo count($teamsAvilable);
?>
 
