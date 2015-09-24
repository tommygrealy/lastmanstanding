<?php
//ini_set('display_errors', '1');

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';


error_reporting(1);

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
$priv_level = ($_SESSION['user']['PrivLevel']);
if ($priv_level < 3) {
    $requestStatus->status = 0;
    $requestStatus->reason = "Insufficient Privilage";
    echo json_encode($requestStatus);
    die();
}

$user=$_POST['userToUpdate'];
$field=$_POST['fieldToUpdate'];
$newValue=$_POST['newValue'];

//$requestStatus->status=1;
//$requestStatus->reason="$user - $field - $newValue";

if ($field=="PaymentStatus"){
    $result = $dal->updatePaymentStatus($user, "Paid");
    if ($result) {
        $requestStatus->status = 1;
        $requestStatus->reason = "Update Succssful";
    }
}

else if ($field=="CompStatus"){
    $result = 1;
    if ($result) {
        $requestStatus->status = 1;
        $requestStatus->reason = "Update Succssful";
    }
}

else{
    $requestStatus->status=0;
    $requestStatus->reason="DB update failed";
}



echo json_encode($requestStatus);
?>
 
