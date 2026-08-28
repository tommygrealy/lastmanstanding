<?php
// First we execute our common code to connection to the database and start the session 
require("common.php");

// This if statement checks to determine whether the registration form has been submitted 
// If it has, then the registration code is run, otherwise the form is displayed 
if (!empty($_POST)) {
    // Ensure that the user has entered a non-empty username 
    if (empty($_POST['username'])) {
        // Note that die() is generally a terrible way of handling user errors 
        // like this.  It is much better to display the error with the form 
        // and allow the user to correct their mistake.  However, that is an 
        // exercise for you to implement yourself. 
        die("Please enter a username.");
    }

    // Ensure that the user has entered a non-empty password 
    if (empty($_POST['password'])) {
        die("Please enter a password.");
    }

    if (empty($_POST['league_id'])) {
        die("No league specified, Please register using an invite link only");
    }

    // Make sure the user entered a valid E-Mail address 
    // filter_var is a useful PHP function for validating form input, see: 
    // http://us.php.net/manual/en/function.filter-var.php 
    // http://us.php.net/manual/en/filter.filters.php 
    if (!filter_var($_POST['email'], FILTER_VALIDATE_EMAIL)) {
        die("Invalid E-Mail Address");
    }

    // We will use this SQL query to see whether the username entered by the 
    // user is already in use.  A SELECT query is used to retrieve data from the database. 
    // :username is a special token, we will substitute a real value in its place when 
    // we execute the query. 
    $query = " 
            SELECT 
                1 
            FROM users 
            WHERE 
                username = :username 
        ";

    // This contains the definitions for any special tokens that we place in 
    // our SQL query.  In this case, we are defining a value for the token 
    // :username.  It is possible to insert $_POST['username'] directly into 
    // your $query string; however doing so is very insecure and opens your 
    // code up to SQL injection exploits.  Using tokens prevents this. 
    // For more information on SQL injections, see Wikipedia: 
    // http://en.wikipedia.org/wiki/SQL_Injection 
    $query_params = array(
        ':username' => $_POST['username']
    );

    try {
        // These two statements run the query against your database table. 
        $stmt = $db->prepare($query);
        $result = $stmt->execute($query_params);
    } catch (PDOException $ex) {
        // Note: On a production website, you should not output $ex->getMessage(). 
        // It may provide an attacker with helpful information about your code.  
        die("Failed to run query: " . $ex->getMessage());
    }

    // The fetch() method returns an array representing the "next" row from 
    // the selected results, or false if there are no more rows to fetch. 
    $row = $stmt->fetch();

    // If a row was returned, then we know a matching username was found in 
    // the database already and we should not allow the user to continue. 
    if ($row) {
        die("This username is already in use");
    }

    // Now we perform the same type of check for the email address, in order 
    // to ensure that it is unique. 
    $query = " 
            SELECT 
                1 
            FROM users 
            WHERE 
                email = :email 
        ";

    $query_params = array(
        ':email' => $_POST['email']
    );

    try {
        $stmt = $db->prepare($query);
        $result = $stmt->execute($query_params);
    } catch (PDOException $ex) {
        die("Failed to run query: " . $ex->getMessage());
    }

    $row = $stmt->fetch();

    if ($row) {
        die("This email address is already registered");
    }

    // An INSERT query is used to add new rows to a database table. 
    // Again, we are using special tokens (technically called parameters) to 
    // protect against SQL injection attacks. 
    $query = " 
            INSERT INTO users ( 
                username, 
                password,
                FullName,
                salt, 
                email,
                CompStatus,
                PaymentStatus
            ) VALUES ( 
                :username, 
                :password,
                :fullname,
                :salt, 
                :email,
                'Playing',
                'Pending'
            );
        ";
    $query .= "
            INSERT INTO league_memberships (
                user_id,
                league_id
            ) VALUES (
                LAST_INSERT_ID(),
                :league_id
            );
        ";


    // Hash the password using bcrypt via PHP's password_hash().
    // The salt column is left empty to signal this is a modern hash.
    $password = password_hash($_POST['password'], PASSWORD_DEFAULT);

    // Here we prepare our tokens for insertion into the SQL query.  We do not 
    // store the original password; only the hashed version of it. 
    $query_params = array(
        ':username' => $_POST['username'],
        ':password' => $password,
        'fullname' => $_POST['fullname'],
        ':salt' => '',
        ':email' => $_POST['email'],
        ':league_id' => $_POST['league_id']
    );

    try {
        // Execute the query to create the user 
        $stmt = $db->prepare($query);
        $result = $stmt->execute($query_params);
        echo json_encode($result);
    } catch (PDOException $ex) {
        // Note: On a production website, you should not output $ex->getMessage(). 
        // It may provide an attacker with helpful information about your code.  
        die("Failed to run query: " . $ex->getMessage());
    }

    // This redirects the user back to the login page after they register 
    header("Location: login.php");

    // Calling die or exit after performing a redirect using the header function 
    // is critical.  The rest of your PHP script will continue to execute and 
    // will be sent to the user if you do not die or exit. 
    die("Redirecting to login.php");
}
?> 

<html>
    <head>
        <link rel="stylesheet" href="<?php echo $myServerConfig->http_protocol?>://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.css">

        <title>Last Man Standing</title>
        <script src="<?php echo $myServerConfig->http_protocol?>://code.jquery.com/jquery-1.10.2.min.js"></script>
        <script src="<?php echo $myServerConfig->http_protocol?>://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.js"></script>
         <meta name="viewport" content="initial-scale=1, maximum-scale=1">
         <script>
             $(document).ready(function(){
                //fvar params = new window.URLSearchParams(window.location.search);
                //var league_id_from_qs = params.get('league_id')
                //if (league_id_from_qs != null){
                //    $('#league_id').val(params.get('league_id'))
                //    $('#league_id').prop( "disabled", true );
                //}
             })
             

         </script>
    </head>
    <body>
        <div data-role="page">
            <div data-role="header">
                <?php include 'includes/header_nologin.php';?>
            </div>
            <div data-role="content">      
                <form data-ajax="false" action="register.php" method="post"> 
                    Username:<br /> 
                    <input type="text" name="username" value="" /> 
                    <br /><br />
                    Full Name:<br /> 
                    <input type="text" name="fullname" value="" /> 
                    <br /><br /> 
                    E-Mail:<br /> 
                    <input type="text" name="email" value="" /> 
                    <br /><br /> 
                    Password:<br /> 
                    <input type="password" name="password" value="" /> 
                    <br /><br /> 
                    League/Invite ID:</br >
                    <input type="text" id="fm_league_id" name="league_id" value="<?php echo($_GET['lid']);?>" /> 
                    <br /><br />

                    <input type="submit" value="Register" /> 

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
