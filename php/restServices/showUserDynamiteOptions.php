<?php
//ini_set('display_errors', '1');

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../objects/genericResponse.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://www.actionshots.ie');

$dal = new dal();
$requestStatus = new requestStatus();

$auth = new Authenticator();
$user_info=$auth->get_current_user($_SESSION, $_REQUEST);

$current_user = $user_info['username'];
$current_user_id = $user_info['id'];

$userDynamiteOptions=$dal->getDynamiteDataForUser($current_user_id);
if(count($userDynamiteOptions)>0){
    echo json_encode($userDynamiteOptions);
}
else{
    $requestStatus->status = 0;
    $requestStatus->reason = "No dynamite";
    echo json_encode($requestStatus);
}
?>
 
