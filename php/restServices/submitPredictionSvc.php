<?php
//ini_set('display_errors', '1');
error_reporting(0);

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../actions/lmsEmailNotifier.php';



header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();
$mailNotifier = new lmsEmailNotifier();

$requestStatus = new requestStatus();

if (empty($_SESSION['user'])) {
    $requestStatus->status = 0;
    $requestStatus->reason = "No valid user is logged in";
    echo json_encode($requestStatus);
    die();
}


$current_user = ($_SESSION['user']['username']);

$UserStatus=$dal->getUserData($current_user);
if ($UserStatus['PaymentStatus']=="Pending"){
    $requestStatus = new requestStatus();
    $requestStatus->status = 0;
    $requestStatus->reason = "Payment Pending";
    echo json_encode($requestStatus);
    die();
}

if ($UserStatus['CompStatus']=="Eliminated"){
    $requestStatus = new requestStatus();
    $requestStatus->status = 0;
    $requestStatus->reason = "eliminated from comp";
    echo json_encode($requestStatus);
    die();
}


$raw_result=$dal->submitUserPrediction($_POST['FixtureId'], $current_user, $_POST['prediction']); // will return "success" or the reason if not
$result = explode("|", $raw_result);
if ($result[0]=="success"){ 
    $requestStatus->status=1;
    $requestStatus->reason=$result[1];
    $mailNotifier->sendPredictionConfirmation($result[1]);
}
else{
    $requestStatus->status=0;
    $requestStatus->reason=$result;
}

echo json_encode($requestStatus);
?>
 
