<?php
//ini_set('display_errors', '1');
error_reporting(0); //ensure clean json

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../actions/lmsEmailNotifier.php';


header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();
$mailNotifier = new lmsEmailNotifier();
$requestStatus = new requestStatus();

$token=$_POST['token'];
$newpass=$_POST['password'];
$newpassConfirm=$_POST['passwordConfirm'];





//TODO: Check pass + confirmation match
if ($newpass != $newpassConfirm){
	$requestStatus->status="fail";
	$requestStatus->reason="Password and Confirmation password do not match";
	echo json_encode($requestStatus);
	die;
}


$usertoreset=$dal->getUsernameByToken($token);


//Generate SALT and hash password
$salt = dechex(mt_rand(0, 2147483647)) . dechex(mt_rand(0, 2147483647));
$newpass = hash('sha256', $newpass . $salt);
// 65K itterations - mitigate against brute force attack
for ($round = 0; $round < 65536; $round++) {
        $newpass = hash('sha256', $newpass . $salt);
    }



if(!empty($usertoreset)){
    $success=$dal->passwordReset($usertoreset, $newpass, $salt);
    if ($success){
        //send mail
        //$mailNotifier->sendPasswordResetInstructions($userDetails['email'], $token);
        $requestStatus->status="success";
        $requestStatus->reason=$usertoreset;
    }
}
 else {
     $requestStatus->status="fail";
     $requestStatus->reason="password reset failed - invalid or expired token";
}


echo json_encode($requestStatus);
?>
 
