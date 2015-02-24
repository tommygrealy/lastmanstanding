<?php

/**
 * Description of lmsMailer
 *
 * @author tgrealy
 */
include_once '../objects/prediction.php';
include_once 'Mailer.php';
include_once '../dal.php';

class lmsEmailNotifier {

    public function sendPredictionConfirmation($predId) {
        $myDal = new dal();
        $predictionToSend = $myDal->getPredictionDetails($predId);
        $myMailer = new Mailer();
        $myMailer->addRecipient($predictionToSend['FullName'], $predictionToSend['email']);
        $myMailer->fillSubject("Last Man Standing - Prediction Confirmation");
        $myMailer->setFrom("Last Man Standing", "lms@actionshots.ie");
        $textMessage = "<html><body>Your prediction has been submitted\n\n";
        $textMessage .= "<table style=\"border: 1px solid\"><tr><td>Prediction ID</td><td>" . $predId . "</td></tr>\n";
        $textMessage .= "<tr><td>Game</td><td>" . $predictionToSend['FixtureDetail'] . " - Kick-off time: ".$predictionToSend['KickOffTime']." </td></tr>\n";
        $textMessage .= "<tr><td>You selected</td><td>" . $predictionToSend['User Selected'] . "</td></tr></table>";
        $textMessage .= "\n\n</body></html>";
        //$textMessage .= json_encode($predictionToSend);

        $myMailer->fillMessage($textMessage);
        $myMailer->send(); // disabled for dev env, mail doesnt work       
    }

    public function sendResults() {
        
    }

    public function sendRegistrationConfirmation() {
        
    }

}
