<?php
//ini_set('display_errors', '1');

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


$raw_result=$dal->cancelPrediction($current_user, $_POST['predictionId']); 
echo json_encode($raw_result);
?>
 
