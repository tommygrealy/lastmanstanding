<?php

/**
 * Description of autoPredictAll
 *
 * Checks for users who have not yet made their prediction for the next round 
 * Selects a random team for each user above
 * Identifies the next fixture involving that team and whether they are home or away
 * builds a prediction for each user
 * 
 * @author tgrealy
 */
require_once '../dal.php';
require_once '../common.php';
require_once '../actions/lmsEmailNotifier.php';
require_once '../objects/requestStatus.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

ini_set('dislplay_errors', 1);

$dal = new dal();
$mailNotifier = new lmsEmailNotifier();

$requestStatus = new requestStatus();

$arrayOfPredictions=new ArrayObject();

if (empty($_SESSION['user'])) {
    $requestStatus->status = 0;
    $requestStatus->reason = "No valid user is logged in";
    echo json_encode($requestStatus);
    die();
}

$current_user = ($_SESSION['user']['username']);
//TODO: Replace below with priv level when implemented
if ($current_user != 'tommygrealy') {
    $requestStatus->status = 0;
    $requestStatus->reason = "Need admin privilage to invoke this service";
    echo json_encode($requestStatus);
    die();
}



$users = $dal->getLazyUsers();
foreach ($users as $nUser) {
    $selectedTeam = $dal->selectRandTeamForUser($nUser['username']);
    $nextFixture = $dal->getNextFixtureForTeam($selectedTeam['LongName']);
    //echo json_encode($nextFixture);
    if ($nextFixture['HomeTeam'] == $selectedTeam['LongName']) {
        $prediciton = 1;
    } else {
        $prediciton = 3;
    }
    $arrayOfPredictions->append($prediciton);
}
echo json_encode($arrayOfPredictions);
?>
