<?php
require_once 'objects/requestStatus.php';

class Authenticator {
    public function get_current_user($session, $headers) {
        // If user is logged in, return user details (you can modify this as per your logic)
        if (!empty($session['user'])) {
            return $session['user'];
        }

        # if we have reached this point, all authentication checks failed
        $requestStatus = new RequestStatus();
        $requestStatus->status = 0;
        $requestStatus->reason = "No valid user is logged in";
        echo json_encode($requestStatus);
        header("Location: login.php");
        die("Redirecting to login page");
        
    }
}
?>
