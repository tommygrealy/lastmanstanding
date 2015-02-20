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
    
    
    public function sendPredictionConfirmation($predId){
		$myDal = new dal();
        $predictionToSend = $myDal->getPredictionDetails($predId);
        $myMailer=new Mailer();
        $myMailer->addRecipient($predictionToSend['FullName'], $predictionToSend['email']);
        $myMailer->fillSubject("Last Man Standing - Prediction Confirmation");
		$myMailer->setFrom("Last Man Standing", "lms@actionshots.ie");
        $textMessage="Your prediction has been submitted\n\n";
        $textMessage .= "Prediction ID: " . $predId . "\n";
		$textMessage .= $predictionToSend['FixtureDetail'] . " - Kick-off time: 00:00:00\n";
        $textMessage .= "You selected: ". $predictionToSend['User Selected'];
		$textMessage .= "\n\n";
		$textMessage .= json_encode($predictionToSend);
		
        $myMailer->fillMessage($textMessage);
		$myMailer->send(); // disabled for dev env, mail doesnt work       
    }
    
    public function sendResults(){
    
    }
    
    public function sendRegistrationConfirmation(){
        
    }
    
    
}
