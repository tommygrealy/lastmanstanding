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

$auth = new Authenticator();
$user_info=$auth->get_current_user($_SESSION, $_REQUEST);

$current_user = $user_info['username'];

$predictionHistory = $dal->getUserPredictionHistory($_GET['player']);
$pre_output = json_encode($predictionHistory);
echo str_replace('"\u000', '"',$pre_output); // to strop out unicode escape characters '\000 inserted by json_encode function

?>
 
