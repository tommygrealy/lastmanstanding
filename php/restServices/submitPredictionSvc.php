<?php
//ini_set('display_errors', '1');

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';


header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();

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




$result=$dal->submitUserPrediction($_POST['FixtureId'], $current_user, $_POST['prediction']); // will return "success" or the reason if not
if ($result=="Success"){ 
    $requestStatus->status=1;
    $requestStatus->reason="";
}
else{
    $requestStatus->status=0;
    $requestStatus->reason=$result;
}

echo json_encode($requestStatus);
?>
 
