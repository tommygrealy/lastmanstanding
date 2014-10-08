<?php

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

    private $username = "lms";
    private $password = "lmsintel2014";
    private $host = "localhost";
    private $dbname = "lastmanstanding";
    private $options = array(PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8');
    public $database_link;

    private function connect() {
        try {
            $this->database_link = new PDO("mysql:host={$host};dbname={$dbname};charset=utf8", $this->username, $this->password, $this->options);
            return database_link;
        } catch (PDOException $ex) {
            echo $ex->getMessage();
            return null;
        }
    }

    public function submitUserPrediction($fixtureId, $UserName, $prediction) {
        //$mylink=$this->connect();
        $mylink = new PDO("mysql:host={$this->host};dbname={$this->dbname};charset=utf8", $this->username, $this->password, $this->options);

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

    public function getTeamsAvilableToUser($UserName) { // this method returns a list of teams which the current user can select (excludes 
        // teams which they previously selcted)
        $mylink = new PDO("mysql:host={$this->host};dbname={$this->dbname};charset=utf8", $this->username, $this->password, $this->options);
        $query = ("call showAvailableTeamsForUser (:userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $UserName);
        $stmt->execute();
        $check = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $check;
    }

    public function getThisWeeksFixtures() {
        $mylink = new PDO("mysql:host={$this->host};dbname={$this->dbname};charset=utf8", $this->username, $this->password, $this->options);
        $query = ("select * from allfixturesandclubinfo " .
                "where " .
                // temporary allowing -3 days to include fixtures while working on the code over weekend.
                //"KickOffTime between (select DateFrom from gameweekmap where DateFrom > (SELECT date_sub(CURRENT_TIMESTAMP, INTERVAL 3 DAY)) limit 1) " .
                "KickOffTime between (select DateFrom from gameweekmap where DateFrom > (select CURRENT_TIMESTAMP) limit 1) " .
                "and " .
                "(select DateTo from gameweekmap where DateTo > (select CURRENT_TIMESTAMP) limit 1)");
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        $results=$stmt->fetchAll(PDO::FETCH_ASSOC);
        return $results;
    }
    
    public function getUserSelectionForThisWeek($UserName){
        $mylink = new PDO("mysql:host={$this->host};dbname={$this->dbname};charset=utf8", $this->username, $this->password, $this->options);
        $query = ("call showUserCurrentSelection (:userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $UserName);
        $stmt->execute();
        $check = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $check;
    }
    
    
    public function getUserData($UserName){
        $mylink = new PDO("mysql:host={$this->host};dbname={$this->dbname};charset=utf8", $this->username, $this->password, $this->options);
        $query = ("select username,CompStatus,PaymentStatus from Users where UserName = (:userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $UserName);
        $stmt->execute();
        $UserInfo = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $UserInfo[0];
    }

    function disconnect() {
        $this->database_link = NULL;
    }

}

?>
