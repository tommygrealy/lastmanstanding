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
            $result = $stmt->fetchAll(PDO::FETCH_ASSOC);            
            return "success|" . $result[0]['PredictionID'];
        } else {
            $myErrorArray = array($stmt->errorInfo());
            return $myErrorArray[0][2];
        }
    }
    
    public function submitMatchResult($fixtureId, $homeScore, $awayScore, $result){
        $mylink = $this->connect();
        $query = ("call updateMatchScore (:fixtureId, :homeScore, :awayScore, :result)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':fixtureId', $fixtureId);
        $stmt->bindParam(':homeScore', $homeScore);
        $stmt->bindParam(':awayScore', $awayScore);
        $stmt->bindParam(':result', $result);
        if ($stmt->execute()){
            return true;
        }
        else{
            return false;
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
        $query = ("select * from thisWeeksFixtures;");
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
    
    public function getAllSelectionsForThisWeek() {
        $mylink = $this->connect();
        $query = ("call showCurrentSelections");
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        $check = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $check;
    }
    
    public function getSelectionsPostDeadline() {
        $mylink = $this->connect();
        $query = ("call showSelectionsPostDeadline");
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        $check = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $check;
    }

    // Get all past fixtures for which no result has yet been entered
    public function getFixturesWithNullResult() {
        $mylink = $this->connect();
        $query = ("call showNullResultFixtures");
        $stmt = $mylink->prepare($query);
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
        $query = ("select * from users where UserName = (:userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $UserName);
        $stmt->execute();
        $UserInfo = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $UserInfo[0];
    }

    public function getPredictionDetails($predictionId){
        $mylink = $this->connect();
        $query = ("SELECT * FROM detailedpredictions where PredictionID = (:PredictionID)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':PredictionID', $predictionId);
        $stmt->execute();
        $PredictionDetilResult = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $PredictionDetilResult[0];
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
    
    
     public function updateCompStatus($username, $status) {
        $mylink = $this->connect();
        $query = "call updateCompStatus (:userName, :status);";
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $username);
        $stmt->bindParam(':status', $status);
        if ($stmt->execute()) {
            return TRUE;
        } else {
            return FALSE;
        }
    }
    
    
    public function cancelPrediction ($username, $predictionId){
        $mylink = $this->connect();
        $query = ("call cancelPrediction (:PredictionID, :userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':PredictionID', $predictionId);
        $stmt->bindParam(':userName', $username);
        $stmt->execute();
        $PredictionCancelledResult = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $PredictionCancelledResult[0];
    }
    
    public function selectRandTeamForUser($username){
        $mylink = $this->connect();
        $query = ("call selectRandomTeam (:userName)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $username);
        $stmt->execute();
        $randomTeam = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $randomTeam[0];
    }
    
    //users who have not predicted yet
    public function getLazyUsers(){ 
         $mylink = $this->connect();
         $query = ("select * from usersnotsubmitted");
         $stmt = $mylink->prepare($query);
         $stmt->execute();
         $usersNotSubmitted = $stmt->fetchAll(PDO::FETCH_ASSOC);
         return $usersNotSubmitted;
    }
    
    public function getNextFixtureForTeam($teamName){
        $mylink = $this->connect();
        $query = ("call getNextFixtureForTeam (:team)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':team', $teamName);
        $stmt->execute();
        $fixture = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $fixture[0];
    }
    
    public function insertResetToken($token, $idType, $idValue){
        $mylink = $this->connect();
        $query="";
        if ($idType="email"){
            $query = ("call generateResetForEmail (:email, :token)");
            $stmt = $mylink->prepare($query);
            $stmt->bindParam(':email', $idValue);
        }
        if ($idType="username"){
            $query = ("call generateResetForUsername (:username, :token)");
            $stmt = $mylink->prepare($query);
            $stmt->bindParam(':username', $idValue);        
        }
        $stmt->bindParam(':token', $token);
        if ($stmt->execute()){
            return TRUE;
        }
        else{
            return FALSE;
        }
    }

    public function getPlayingUsersNotPaid(){
        $mylink = $this->connect();
        $query = ("SELECT * FROM playingnotpaid");
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        $usersNotPaid = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $usersNotPaid;
    }

    public function getUsernameByToken($token){
        $mylink = $this->connect();
        $query = ("call getUserDetailsFromToken (:token)");
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':token', $token);
        $stmt->execute();
        $retval = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $retval[0]['username'];
    }

    public function passwordReset($user, $pass_enc, $salt){
        $mylink=$this->connect();
        $query="call passwordReset (:username, :password, :salt)";
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':username',$user);
        $stmt->bindParam(':password',$pass_enc);
        $stmt->bindParam(':salt',$salt);
        $stmt->execute();
        if($stmt->rowCount()>0){
            return TRUE;
        }
        else{
            return FALSE;
        }
    }
            
    function disconnect() {
        $this->database_link = NULL;
    }

}

?>
