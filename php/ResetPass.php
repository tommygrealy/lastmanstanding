<?php
// First we execute our common code to connection to the database and start the session 
require("common.php");
require('dal.php');

$token=$_GET['token'];

// This if statement checks to determine whether the registration form has been submitted 
// If it has, then the registration code is run, otherwise the form is displayed 
/*if (!empty($_POST)) {
    // Ensure that the user has entered a non-empty username 
    if ((empty($_POST['username'])) && (empty($_POST['email']))) {
        die("You need to supply either a username or a valid email address to complete this process");
    }

    $myDal = new dal();
    $token = dechex(mt_rand(0, 2147483647)) . dechex(mt_rand(0, 2147483647));
    
    if (empty($_POST['username'])){
        $identifierName="email";
        $identifierValue=$_POST['email'];
    }
    else{
        $identifierName="username";
        $identifierValue=$_POST['username'];
    }
    
    
    $success=$myDal->insertResetToken($token, $identifierName, $identifierValue);
    
    if(!(empty($success))){
        //email the password reset link
        //notify user that the mail has been sent to the email address associated with this account - whether or not it has been!
        echo $success;
    }
    die;
}*/
?> 

<html>
    <head>
        <link rel="stylesheet" href="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.css">
        <link rel="stylesheet" href="styles/themes/bluyel.min.css">
        <title>Last Man Standing</title>
        <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
        <script src="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.js"></script>
        <script src="scripts/lastmanstanding.js"></script>
         <meta name="viewport" content="initial-scale=1, maximum-scale=1">
    </head>
    <body>
        <div data-role="page">
            <div data-role="header">
                <?php include 'includes/header_nologin.php';?>
            </div>
            <div data-role="content">      
                <form id="resetSubmitForm" data-ajax="false" action="ForgotPass.php" method="post"> 
                    Enter New Password:<br /> 
                    <input type="password" name="password" id="txtPwd" value="" />                    
                    Confirm New Password<br /> 
                    <input type="password" name="passwordConfirm" id="txtPwdConfirm" value="" /> 
                    <br /><br /> 
                    <input type="hidden" name="token" value="<?php echo $_GET['token']?>" />
                    <input type="button" onclick="doPassReset($('#resetSubmitForm').serialize());"  value="Submit" /> 
                </form>
            </div>
            
            <div data-role="footer" data-position="fixed" data-theme="b">
                <?php
                include 'includes/footer.php';
                ?>
            </div>

        </div>
        <div data-role="page" id="rules">
            <div data-role="header" data-position="fixed">
                <?php
                include 'includes/header_nologin.php';
                ?>
            </div>
            <div data-role="content">
                <?php 
                include 'includes/rules.php';
                ?>

            </div>
            <div data-role="footer" data-theme="b" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>;  
            </div>

    </body>

</html>
