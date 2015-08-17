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


/* Temporarily allow global access to this service
if (empty($_SESSION['user'])) {
    $requestStatus = new requestStatus();
    $requestStatus->status = 0;
    $requestStatus->reason = "No valid user is logged in";
    echo json_encode($requestStatus);
    die();
}*/


echo json_encode($dal->getStandings());



?>