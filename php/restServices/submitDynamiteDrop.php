<?php

require_once '../dal.php';
require_once '../common.php';
require_once '../objects/requestStatus.php';
require_once '../actions/lmsEmailNotifier.php';

// Allow requests from any origin (for CORS)
header("Access-Control-Allow-Origin: *");
// Specify that the content type is JSON
header("Content-Type: application/json");

$dal = new dal();
$mailNotifier = new lmsEmailNotifier();

$requestStatus = new requestStatus();

// Check if a POST request was made and if 'drop_on_user' and 'dynamite_id' is present
if ($_SERVER['REQUEST_METHOD'] === 'POST' && 
    isset($_POST['user_last_update']) &&
    isset($_POST['drop_on_user']) &&
    isset($_POST['dynamite_id'])) 
    {
    // Get the value of 'drop_on_user' from the POST request
    $userLastUpdate = $_POST['user_last_update'];
    $dropOnUser = $_POST['drop_on_user'];
    $dynamiteId = $_POST['dynamite_id'];

    $db_last_update = $dal->getDynamiteLastUpdatedTimeStamp();

    $dynamite_expiry - $dal->getDynamiteExpiry($dynamiteId);

    // check if user has a stale version of the player standings
    if ($db_last_update != $userLastUpdate){
        $requestStatus->status=1;
        $requestStatus->reason="stale data";
        echo json_encode($requestStatus);
        exit();
    }

    // do drop
    $new_lives = $dal->dropDynamiteOnUser($dynamiteId, $dropOnUser);
    if ($new_lives == 0){
        $dal->updateCompStatus($dropOnUser, "Eliminated");
    }

    $dal->updateDynamite($dynamiteId, $dropOnUser);

    $reason = array(
        "player_hit" => $dropOnUser,
        "lives_remaining" => $new_lives
    );

    $requestStatus->status=1;
    $requestStatus->reason=$reason;

    echo json_encode($requestStatus);
} else {
    // If no valid POST request was made, return an error response
    $response = array(
        "status" => 0,
        "message" => "Invalid request"
    );

    echo json_encode($response);
}
?>
