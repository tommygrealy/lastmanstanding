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


if (empty($_SESSION['user'])) {
    $requestStatus = new requestStatus();
    $requestStatus->status = 0;
    $requestStatus->reason = "No valid user is logged in";
    echo json_encode($requestStatus);
    die();
}

$current_user = ($_SESSION['user']['username']);


$userdata = $dal->getUserData($current_user);
echo json_encode($dal->getStandings($userdata['league_id']));
//echo json_encode($dal->getStandings())

?>