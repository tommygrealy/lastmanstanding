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

$thisWeeksSelections = $dal->getAllSelectionsForThisWeek();
$pre_output = json_encode($thisWeeksSelections);
echo str_replace('"\u000', '"',$pre_output); // to strop out unicode escape characters '\000 inserted by json_encode function

?>
 
