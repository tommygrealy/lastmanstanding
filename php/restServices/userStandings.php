<?php
//ini_set('display_errors', '1');

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../objects/genericResponse.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$dal = new dal();

$response=new genericResponse();


$auth = new Authenticator();
$user_info=$auth->get_current_user($_SESSION, $_REQUEST);

$current_user = $user_info['username'];


$userdata = $dal->getUserData($current_user);
echo json_encode($dal->getStandings($userdata['league_id']));
//echo json_encode($dal->getStandings())

?>