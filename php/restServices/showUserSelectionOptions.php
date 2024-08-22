<?php
//ini_set('display_errors', '1');

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../objects/genericResponse.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();

$response=new genericResponse;

$auth = new Authenticator();
$user_info=$auth->get_current_user($_SESSION, $_REQUEST);

$current_user = $user_info['username'];

$HasUserPredictedThisWeek=$dal->getUserSelectionForThisWeek($current_user);
if(count($HasUserPredictedThisWeek)>0){
    echo json_encode($HasUserPredictedThisWeek);
    die();
} 

$userCurrentStatus=$dal->getUserData($current_user);


$teamsAvilable = $dal->getTeamsAvilableToUser($current_user);
$fixtureList = $dal->getThisWeeksFixtures();

for ($i=0;$i<count($teamsAvilable);$i++){
    $shortNamesAvail[$i]=$teamsAvilable[$i]["ShortName"];
}


$resultsHistory = $dal->getResultsHistory();
$formguide = [];
//echo json_encode($resultsHistory);

foreach ($resultsHistory as $row){
    if ($row['Result']==1){
        //HomeWin
        //isset($foo) ? $foo += $bar : $foo = $bar;
        isset($formguide[$row['HomeTeam']]) ? $formguide[$row['HomeTeam']] .= "WIN,": $formguide[$row['HomeTeam']] = "WIN,";
        isset($formguide[$row['AwayTeam']]) ? $formguide[$row['AwayTeam']] .= "LOS,": $formguide[$row['AwayTeam']] = "LOS,";

    };
    if ($row['Result']==2){
        //Draw
        isset($formguide[$row['AwayTeam']]) ? $formguide[$row['AwayTeam']] .= "DRW,": $formguide[$row['AwayTeam']] = "DRW,";
        isset($formguide[$row['HomeTeam']]) ? $formguide[$row['HomeTeam']] .= "DRW,": $formguide[$row['HomeTeam']] = "DRW,";

    };
    
    if ($row['Result']==3){
        //Away win
        isset($formguide[$row['HomeTeam']]) ? $formguide[$row['HomeTeam']] .= "LOS,": $formguide[$row['HomeTeam']] = "LOS,";
        isset($formguide[$row['AwayTeam']]) ? $formguide[$row['AwayTeam']] .= "WIN,": $formguide[$row['AwayTeam']] = "WIN,";
    }
}

//TODO: reformat fixture list output to be an associative array with the FixtureId as the key for each element
// [89:{KickOffTime: "2014-12-01 16:00, HomeTeam: "Manu"},90:{}]

    
$response->availableTeams=$shortNamesAvail;
$response->fixtures=$fixtureList;
$response->userstatus=$userCurrentStatus;
$response->formguide=$formguide;
echo json_encode($response);

//echo $teamsAvilable[2]["ShortName"];
//echo count($teamsAvilable);
?>
 
