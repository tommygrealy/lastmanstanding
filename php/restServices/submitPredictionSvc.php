<?php
//ini_set('display_errors', '1');

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../actions/lmsEmailNotifier.php';

error_reporting(0);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();
$mailNotifier = new lmsEmailNotifier();

$requestStatus = new requestStatus();

$auth = new Authenticator();
$user_info=$auth->get_current_user($_SESSION, $_REQUEST);

$current_user = $user_info['username'];

$UserStatus=$dal->getUserData($current_user);
if ($UserStatus['PaymentStatus']!="Paid"){
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


$raw_result=$dal->submitUserPrediction($_POST['FixtureId'], $current_user, $_POST['prediction'], 'MANUAL'); // will return "success" or the reason if not
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
 
