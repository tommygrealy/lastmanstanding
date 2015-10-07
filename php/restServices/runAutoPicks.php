<?php

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../objects/genericResponse.php';
require_once '../objects/prediction.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();

$requestStatus = new requestStatus();


if (($_SESSION['user']['PrivLevel']) < 0) {
    $requestStatus->status = 0;
    $requestStatus->reason = "Admin access only";
    echo json_encode($requestStatus);
    die();
}

$PredictionList = array();
/*for ($i = 1; $i <= 10; $i++) {
    $myPred = new prediction();
    $myPred->FixtureID=$i;
    $PredictionList[]=$myPred;
} */

$LazyUsers=($dal->getLazyUsers());
$AutoPredictsCompleted=0;
foreach ($LazyUsers as $luser){
    $myPred = new prediction();
    $myPred->UserName =  $luser['username'];
    $teamsAvilable = $dal->getTeamsAvilableToUser($luser['username']);
    $team=$teamsAvilable[0]['LongName'];
    $autoFixture = $dal->getNextFixtureForTeam($team);
    $myPred->FixtureID=$autoFixture['FixtureId'];
    if ($autoFixture['HomeTeam']==$team){
        $myPred->PredictedResult=1;
    }
    else{
        $myPred->PredictedResult=3;
    }
    $myPred->EntryType="AUTO";
    if ($dal->submitUserPrediction($myPred->FixtureID, $myPred->UserName, $myPred->PredictedResult, "AUTO")){
        $PredictionList[]=$myPred;
        $AutoPredictsCompleted++;
    }
}

if ($AutoPredictsCompleted>0){
    $requestStatus->status=1;
    $requestStatus->reason=$PredictionList;
}
else{
    $requestStatus->status=0;
    $requestStatus->reason="No auto predictions were made";
}



echo json_encode($requestStatus);

?>
