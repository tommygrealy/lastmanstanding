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

    public function submitUserPrediction($fixtureId, $UserName, $prediction, $entryType) {
        //$mylink=$this->connect();
        $mylink = $this->connect();

        $query = ("call insertPrediction (:fixtureId, :userName, :TeamSelected, :EntryType)");
        //echo $query;
        $stmt = $mylink->prepare($query);

        $stmt->bindParam(':fixtureId', $fixtureId);
        $stmt->bindParam(':userName', $UserName);
        $stmt->bindParam(':TeamSelected', $prediction);
        $stmt->bindParam(':EntryType', $entryType);


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

    
    public function getStandings($league_id){
        $mylink = $this->connect();
        $query = "call showCurrentStandingsByLeague($league_id)";
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
        $query = ("select * from thisweeksfixtures;");
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $results;
    }

    public function getResultsHistory($lookback_matches){
        $mylink = $this->connect();
        $query = "
            SELECT * 
            FROM (
                SELECT * 
                FROM fixtureresults 
                WHERE HomeTeamScore IS NOT NULL 
                ORDER BY KickOffTime DESC 
                LIMIT $lookback_matches
            ) AS last_five
            ORDER BY KickOffTime ASC;
        ";
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
        $query = ("select * from users_join_leagues where UserName = (:userName)");
        //$query = ("select * from users where UserName = (:userName)");
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
        $query = "update users set CompStatus = :status where username = :userName;";
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':userName', $username);
        $stmt->bindParam(':status', $status);
        if ($stmt->execute()) {
            return TRUE;
        } else {
            return FALSE;
        }
    }

    public function updateDynamite($dynamite_id, $used_on){
        $mylink = $this->connect();
        $query = "UPDATE dynamite SET target_user_fk = ";
        $query .= "(select id from users where username = :target_user), ";
        $query .= "status = 0 WHERE dynamite_id = :dynamite_id;";
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':target_user', $used_on);
        $stmt->bindParam(':dynamite_id', $dynamite_id);
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

    public function getUserDetailsFromApiToken($token){
        $mylink=$this->connect();
        $query = "select * from users where id =  ";
        $query .= "(select fk_user_id from api_tokens ";
        $query .= "where token = :token;";
        $stmt->bindParam(':token',$token);
        $stmt->execute();
        $userdetails = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $userdetails[0];
    }

    public function getDynamiteDataForUser($user_id){
        $mylink=$this->connect();
        $query = "SELECT";
        $query .= " dynamite_id, granted_to_user_fk, target_user_fk, won_in_fixture_id, status,";
        $query .= " (select updated_at from dynamite order by updated_at desc limit 1) as 'updated_at'";
        $query .= " FROM  dynamite where dynamite.granted_to_user_fk = :user_id and status = 1;";
        $stmt = $mylink->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        $dyn_details = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $dyn_details;
    }

    public function getDynamiteDropHistory(){
        $mylink=$this->connect();
        $query = " 
            SELECT 
                dynamite.updated_at,
                source_user.FullName AS SourceFullName,
                target_user.FullName AS TargetFullName
            FROM 
                dynamite
            JOIN 
                users AS source_user ON dynamite.granted_to_user_fk = source_user.id
            JOIN 
                users AS target_user ON dynamite.target_user_fk = target_user.id
            ORDER by dynamite.updated_at desc;
        ";
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getDynamiteLastUpdatedTimeStamp(){
        $mylink=$this->connect();
        $query =  "SELECT updated_at FROM  dynamite order by updated_at desc limit 1;";
        $stmt = $mylink->prepare($query);
        $stmt->execute();
        $result =  $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $result[0]['updated_at'];
    }

    public function grantDynamiteToUser($user_id, $fixture_id){

    }

    public function dropDynamiteOnUser($dynamite_id, $target_user_id){
        $mylink=$this->connect();

        try {
            // Prepare the UPDATE query to decrement lives
            $sql_update = "UPDATE users SET lives = lives - 1 WHERE username = :target_user";
            $stmt_update = $mylink->prepare($sql_update);
            $stmt_update->bindParam(":target_user", $target_user_id);
            $stmt_update->execute();

            if ($stmt_update->rowCount() > 0){
                $sql_select = "SELECT lives FROM users WHERE username = :target_user";
                $stmt_select = $mylink->prepare($sql_select);
                $stmt_select->bindParam(":target_user", $target_user_id);
                $stmt_select->execute();
                $result = $stmt_select->fetch();
                return $result[0];
            }
            else {
                return "Failed";
            }

        
            /*// Prepare the SELECT query to retrieve the new lives value
            $sql_select = "SELECT lives FROM users WHERE username = :target_user";
            $stmt_select = $mylink->prepare($sql_select);
            $stmt_select->bindParam(":target_user", $target_user_id);
            $stmt_select->execute();
        
            // Fetch the result
            $result = $stmt_select->fetch();
        
            // Commit transaction
            $mylink->commit();

            return $result;*/
        
        } catch (Exception $e) {
            // Rollback transaction in case of an error
            $mylink->rollback();
            echo "Failed to update $e :-(";
            return "update failed";
        }
        
        
    }
            
    function disconnect() {
        $this->database_link = NULL;
    }

}

?>
