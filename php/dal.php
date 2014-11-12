<?php

require_once 'serverConfig.php';

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of dal
 *
 * @author tommygrealy
 */
class dal {

    private function connect() {
        $myConfig = new serverConfig();
        try {
            $this->database_link = new PDO("mysql:host={$myConfig->host};dbname={$myConfig->dbname};charset=utf8", $myConfig->username, $myConfig->password, $myConfig->options);
            return $this->database_link;
        } catch (PDOException $ex) {
            echo $ex->getMessage();
            return null;
        }
    }

    public function submitUserPrediction($fixtureId, $UserName, $prediction) {
        //$mylink=$this->connect();
        $mylink = $this->connect();

        $query = ("call insertPrediction (:fixtureId, :userName, :TeamSelected)");
        //echo $query;
        $stmt = $mylink->prepare($query);

        $stmt->bindParam(':fixtureId', $fixtureId);
        $stmt->bindParam(':userName', $UserName);
        $stmt->bindParam(':TeamSelected', $prediction);


        if ($stmt->execute()) {
            return "Success";
        } else {
            $myErrorArray = array($stmt->errorInfo());
            return $myErrorArray[0][2];
        }
    }
    
    public function getStandings(){
        $mylink = $this->connect();
        $query = "call showCurrentStandings";
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        $standings = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $standings;
    }

    public function getTeamsAvilableToUser($UserName) { // this method returns a list of teams which the current user can select (excludes 
        // teams which they previously selcted)
        $mylink = $this->connect();
        $query = ("call showAvailableTeamsForUser (:userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $UserName);
        $stmt->execute();
        $check = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $check;
    }
    
    
    
    

    public function getThisWeeksFixtures() {
        $mylink = $this->connect();
        $query = ("select * from allfixturesandclubinfo " .
                "where " .
                // temporary allowing -3 days to include fixtures while working on the code over weekend.
                //"KickOffTime between (select DateFrom from gameweekmap where DateFrom > (SELECT date_sub(CURRENT_TIMESTAMP, INTERVAL 3 DAY)) limit 1) " .
                "KickOffTime between (select DateFrom from gameweekmap where DateFrom > (select CURRENT_TIMESTAMP) limit 1) " .
                "and " .
                "(select DateTo from gameweekmap where DateTo > (select CURRENT_TIMESTAMP) limit 1)");
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $results;
    }

    public function getUserSelectionForThisWeek($UserName) {
        $mylink = $this->connect();
        $query = ("call showUserCurrentSelection (:userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $UserName);
        $stmt->execute();
        $check = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $check;
    }

    public function getUserPredictionHistory($UserName) {
        $mylink = $this->connect();       
        $query = "call showUserPredictionHistory (:userName)";
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $UserName);
        $stmt->execute();
        $userPredictions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $userPredictions;
    }

    public function getUserData($UserName) {
        $mylink = $this->connect();
        $query = ("select username,CompStatus,PaymentStatus from users where UserName = (:userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $UserName);
        $stmt->execute();
        $UserInfo = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $UserInfo[0];
    }

    function disconnect() {
        $this->database_link = NULL;
    }
    
    public function updatePaymentStatus($username, $status) {
        $mylink = $this->connect();
        $query = "call updatePaymentStatus (:userName, :status);";
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $username);
        $stmt->bindParam(':status', $status);
        if ($stmt->execute()) {
            return TRUE;
        } else {
            return FALSE;
        }
    }

}

?>
