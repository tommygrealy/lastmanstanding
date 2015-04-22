<?php
//ini_set('display_errors', '1');

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../actions/lmsEmailNotifier.php';

ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();
$mailNotifier = new lmsEmailNotifier();
$requestStatus = new requestStatus();

$userRequesting=$_POST['username'];
$token = dechex(mt_rand(0, 2147483647)) . dechex(mt_rand(0, 2147483647));
$userDetails=$dal->getUserData($userRequesting);


if(!empty($userDetails)){
    $success=$dal->insertResetToken($token, 'username', $userRequesting);
    if ($success){
        //user does exist - send mail
        $mailNotifier->sendPasswordResetInstructions($userDetails['email'], $token);
        $requestStatus->status="success";
        $requestStatus->reason="";
    }
    else{
        $requestStatus->status="fail";
        $requestStatus->reason="Could not store reset token";
    }
}
 else {
     $requestStatus->status="fail";
     $requestStatus->reason="username does not exist";
}

echo json_encode($requestStatus);
?>
 
