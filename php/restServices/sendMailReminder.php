<?php
//ini_set('display_errors', '1');
error_reporting(1);

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../actions/lmsEmailNotifier.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');




$dal = new dal();
$mailNotifier = new lmsEmailNotifier();

$requestStatus = new requestStatus();

if (($_SESSION['user']['PrivLevel']) < 3) {
    $requestStatus = new requestStatus();
    $requestStatus->status = 0;
    $requestStatus->reason = "Admin access only";
    echo json_encode($requestStatus);
    die();
}


if($mailNotifier->sendSubmitReminder()){
    $requestStatus->status=1;
    $requestStatus->reason="mail is sent";
};


echo json_encode($requestStatus);

