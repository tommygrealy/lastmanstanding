<?php
// First we execute our common code to connection to the database and start the session 
require("../common.php");
require("../dal.php");

// At the top of the page we check to see whether the user is logged in or not 
if (empty($_SESSION['user'])) {
    // If they are not, we redirect them to the login page. 
    header("Location: login.php");

    // Remember that this die statement is absolutely critical.  Without it, 
    // people can view your members-only content without logging in. 
    die("Redirecting to login.php");
}

// Everything below this point in the file is secured by the login system 
// We can display the user's username to them by reading it from the session array.  Remember that because 
// a username is user submitted content we must use htmlentities on it before displaying it to the user. 
?> 
<html>
    <head>
        <link rel="stylesheet" href="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.css">
        <title>Last Man Standing - Prediction Submitted</title>
        <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
        <script src="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.js"></script>
        <meta name="viewport" content="initial-scale=1, maximum-scale=1">
    </head>
    <body>
        <div data-role="page">
            <div data-role="header">
                <strong>Prediction Submitted</strong>
            </div>
            <div data-role="content">
                Prediction submitted by <?php 
                echo $_SESSION['user']['username'] . "<br>"; 
              
                echo "FixtureID: " . $_POST['fixtureId'] . ", Prediction: " . $_POST['prediction'];
                
                ini_set('display_errors', '1');
                $dal = new dal();
                //$dal->connect();
                $result = $dal->submitUserPrediction($_POST['fixtureId'], $_SESSION['user']['username'], $_POST['prediction']);
                //echo $_SESSION['user'];
                echo $result;
                ?>

            </div>

            <div data-role="footer">
                Page design by Tommy
            </div>
        </div>

    </body>

</html>



