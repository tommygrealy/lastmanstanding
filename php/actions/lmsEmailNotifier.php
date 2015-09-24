<?php

/**
 * Description of lmsMailer
 *
 * @author tgrealy
 */
include_once '../objects/prediction.php';
include_once 'Mailer.php';
include_once '../dal.php';
include_once '../serverConfig.php';

$serverConfig = new serverConfig();

error_reporting(1);

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
        $textMessage .= "<tr><td>Game</td><td>" . $predictionToSend['FixtureDetail'] . " - Kick-off time: " . $predictionToSend['KickOffTime'] . " </td></tr>\n";
        $textMessage .= "<tr><td>You selected</td><td>" . $predictionToSend['User Selected'] . "</td></tr></table>";
        $textMessage .= "<a href=\"" . $baseUrl . "\">Click here </a> if you want to change your selection ";
        $textMessage .= "\n\n</body></html>";
        //$textMessage .= json_encode($predictionToSend);

        $myMailer->fillMessage($textMessage);
        $myMailer->send(); // disabled for dev env, mail doesnt work  
        $myDal->disconnect();
    }

    public function sendSubmitReminder() {
		$sentTo="";
		$serverConfig = new serverConfig();
        $myDal = new dal();
        $distlist = $myDal->getLazyUsers();
        foreach ($distlist as $userdetails) {
			$myMailer = new Mailer();
            $myMailer->addRecipient($userdetails['FullName'], $userdetails['Email']);
			$myMailer->addCC("Tommy","tommygrealy@gmail.com");
			$myMailer->fillSubject("Last Man Standing - Reminder");
			$myMailer->setFrom("Last Man Standing", "lms@actionshots.ie");
			$textMessage = "Reminder to submit your team for LPS. Log in <a href=\"" . $serverConfig->baseUrl  . "\">here</a>";
			$myMailer->fillMessage($textMessage);
			if($myMailer->send()){
				$sentTo .= $userdetails['Email'] . "|";
			}
			else{
				$sentTo .= $userdetails['Email'] . "-send_err-|";
			}
			
		}
		if (strpos($sentTo,"-send_err-")){
			return false;
		} 
		else{
			return true;  // no errors found 
		}
    }

    public function sendPredictions() {
        $myDal = new dal();
        $predictionToSend = $myDal->getPredictionDetails($predId);
        $myMailer = new Mailer();
    }

    public function sendRegistrationConfirmation() {
        
    }

    public function sendPasswordResetInstructions($emailAddress, $token) {
        $serverConfig = new serverConfig();
        $resetUrl = $serverConfig->baseUrl . "/ResetPass.php?token=" . $token;
        $myMailer = new Mailer();
        $myMailer->addRecipient("Name", $emailAddress);
        $myMailer->fillSubject("Last Man Standing - Password Reset Instructions");
        $myMailer->setFrom("Last Man Standing", "lms@actionshots.ie");
        $textMessage = "<html><body>A request to change your password was submitted\n\n<br>";
        $textMessage .= "<a href=\"" . $resetUrl . "\">Click here </a> to reset your password ";
        $textMessage .= "\n\n</body></html>";
        $myMailer->fillMessage($textMessage);
        $myMailer->send(); // disable for dev env, mail doesnt work  
    }
	
	public function testMail(){
		$sentTo="";
		$serverConfig = new serverConfig();
		$myDal = new dal();
        $distlist = $myDal->getLazyUsers();
        foreach ($distlist as $userdetails) {
			$myMailer = new Mailer();
            $myMailer->addRecipient($userdetails['FullName'], $userdetails['Email']);
			$myMailer->addRecipient("Tommy Grealy", "tommygrealy@gmail.com");
			$myMailer->setFrom("Last Man Standing", "lms@actionshots.ie");
			$myMailer->fillSubject("Last Man Standing - Reminder");
			$textMessage = "<html><strong>Reminder</strong> to submit your team for LPS. Log in <a href=\"" . $serverConfig->baseUrl . "\">here</a></html>";
			$myMailer->fillMessage($textMessage);
			if($myMailer->send()){
				$sentTo .= $userdetails['Email'] . "|";
			}
			else{
				$sentTo .= $userdetails['Email'] . "-send_err-|";
			}
        }
		
		if (strpos($sentTo,"-send_err-")){
			return false;
		} 
		else{
			return true;  // no errors found 
		}
		
        
	}

}
