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



if (($_SESSION['user']['PrivLevel']) < 3) {
    $requestStatus = new requestStatus();
    $requestStatus->status = 0;
    $requestStatus->reason = "Admin access only";
    echo json_encode($requestStatus);
    die();
}

$resultsHistory = $dal->getResultsHistory();
$form = [];
//echo json_encode($resultsHistory);

foreach ($resultsHistory as $row){
    if ($row['Result']==1){
        //HomeWin
        //isset($foo) ? $foo += $bar : $foo = $bar;
        isset($form[$row['HomeTeam']]) ? $form[$row['HomeTeam']] .= "W": $form[$row['HomeTeam']] = "W";
        isset($form[$row['AwayTeam']]) ? $form[$row['AwayTeam']] .= "L": $form[$row['AwayTeam']] = "L";

    };
    if ($row['Result']==2){
        //Draw
        isset($form[$row['AwayTeam']]) ? $form[$row['AwayTeam']] .= "D": $form[$row['AwayTeam']] = "D";
        isset($form[$row['HomeTeam']]) ? $form[$row['HomeTeam']] .= "D": $form[$row['HomeTeam']] = "D";

    };
    
    if ($row['Result']==3){
        //Away win
        isset($form[$row['HomeTeam']]) ? $form[$row['HomeTeam']] .= "L": $form[$row['HomeTeam']] = "L";
        isset($form[$row['AwayTeam']]) ? $form[$row['AwayTeam']] .= "W": $form[$row['AwayTeam']] = "W";
    }
}
//
$pre_output = json_encode($form);
echo str_replace('"\u000', '"',$pre_output); // to strop out unicode escape characters '\000 inserted by json_encode function

?>
 
