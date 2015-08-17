<?php
// First we execute our common code to connection to the database and start the session 
require("common.php");

// This variable will be used to re-display the user's username to them in the 
// login form if they fail to enter the correct password.  It is initialized here 
// to an empty value, which will be shown if the user has not submitted the form. 
$submitted_username = '';

// This if statement checks to determine whether the login form has been submitted 
// If it has, then the login code is run, otherwise the form is displayed 
if (!empty($_POST)) {
    // This query retreives the user's information from the database using 
    // their username. 
    $query = " 
            SELECT 
                id, 
                username, 
                password, 
                salt, 
                email 
            FROM users 
            WHERE 
                username = :username 
        ";

    // The parameter values 
    $query_params = array(
        ':username' => $_POST['username']
    );

    try {
        // Execute the query against the database 
        $stmt = $db->prepare($query);
        $result = $stmt->execute($query_params);
    } catch (PDOException $ex) {
        // Note: On a production website, you should not output $ex->getMessage(). 
        // It may provide an attacker with helpful information about your code.  
        die("Failed to run query: " . $ex->getMessage());
    }

    // This variable tells us whether the user has successfully logged in or not. 
    // We initialize it to false, assuming they have not. 
    // If we determine that they have entered the right details, then we switch it to true. 
    $login_ok = false;

    // Retrieve the user data from the database.  If $row is false, then the username 
    // they entered is not registered. 
    $row = $stmt->fetch();
    if ($row) {
        // Using the password submitted by the user and the salt stored in the database, 
        // we now check to see whether the passwords match by hashing the submitted password 
        // and comparing it to the hashed version already stored in the database. 
        $check_password = hash('sha256', $_POST['password'] . $row['salt']);
        for ($round = 0; $round < 65536; $round++) {
            $check_password = hash('sha256', $check_password . $row['salt']);
        }

        if ($check_password === $row['password']) {
            // If they do, then we flip this to true 
            $login_ok = true;
        }
    }

    // If the user logged in successfully, then we send them to the private members-only page 
    // Otherwise, we display a login failed message and show the login form again 
    if ($login_ok) {
        // Here I am preparing to store the $row array into the $_SESSION by 
        // removing the salt and password values from it.  Although $_SESSION is 
        // stored on the server-side, there is no reason to store sensitive values 
        // in it unless you have to.  Thus, it is best practice to remove these 
        // sensitive values first. 
        unset($row['salt']);
        unset($row['password']);

        // This stores the user's data into the session at the index 'user'. 
        // We will check this index on the private members-only page to determine whether 
        // or not the user is logged in.  We can also use it to retrieve 
        // the user's details. 
        $_SESSION['user'] = $row;

        // Redirect the user to the private members-only page. 
        header("Location: home.php");
        die("Redirecting to: home.php");
    } else {
        // Tell the user they failed 
        //print("Login Failed.");
        echo ('<script type="text/javascript">alert("login failed")</script>');

        // Show them their username again so all they have to do is enter a new 
        // password.  The use of htmlentities prevents XSS attacks.  You should 
        // always use htmlentities on user submitted values before displaying them 
        // to any users (including the user that submitted them).  For more information: 
        // http://en.wikipedia.org/wiki/XSS_attack 
        $submitted_username = htmlentities($_POST['username'], ENT_QUOTES, 'UTF-8');
    }
}
?> 
<html>
    <head>
        <link rel="stylesheet" href="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.css">
        <link rel="stylesheet" href="styles/themes/bluyel.min.css">
        <title>Last Man Standing - Login</title>
        <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
        <script src="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.js"></script>
        <script src="scripts/forgotpass.js"></script>
        <meta name="viewport" content="initial-scale=1, maximum-scale=1">
    </head>
    <body>
        <div data-role="content">
            <div data-role="page">
                <div data-role="header">
                    <?php
                    include 'includes/header_nologin.php';
                    ?>
                </div>
                <div data-role="content">
                    <p>New user? <a href="register.php">Click here to register</a></p>

                    <form data-ajax="false" action="login.php" method="post"> 
                        <h5>Existing Users, login here:</h5>
                        Username:<br /> 
                        <input type="text" name="username" value="<?php echo $submitted_username; ?>" /> 
                        <br /><br /> 
                        Password:<br /> 
                        <input type="password" name="password" value="" /> 
                        <a href="ForgotPass.php">Forgot Password?</a>
                        <br /><br /> 
                        <input type="submit" value="Login" /> 
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
                <div data-role="footer" data-theme="d" data-position="fixed">
                    <?php
                    include 'includes/footer.php';
                    ?>
                </div>


            </div>
            <!-- charity description page -->
            <div data-role="page" id="charity">
                <div data-role="header" data-position="fixed">
                    <?php
                    include 'includes/header_nologin.php';
                    ?>
                </div>
                <div data-role="content">
                    <h3>Funding for Hannah & Patrick McCarthy’s Medical Treatment in the USA</h3>
                    The Parents of Hannah aged 7 years and Patrick aged 5 year’s respectfully seek funding support for Autism treatment for their Children in the USA.
                    Hannah & Patrick are both diagnosed with ASD, Autism and live with their Parents, Caroline and Neil in Castleknock, Dublin.  According to Mainstream Medicine there is no known cure for ASD and treatment is not covered by the HSE or private medical insurance.
                    As Parents it is very difficult to accept this fate and for years we have tirelessly researched ASD and appropriate treatments. Both Children are non-verbal, very poor cognition and fully dependant on us for their care. Hannah has a serious food disorder and is fed through a gastrostomy tube since 2010. 
                    Through exhaustive research we uncovered the Advanced Medical Centre in North Carolina, USA. They specialise in the advanced treatment of ASD for Children. The treatment is carried out over a four week period. The treatment schedule is repeated at least 4 times inside 12 months. We personally know one little boy who is now fully cured and attending main stream school in Dublin 15 after completing Chelation treatment.
                    The cost for the 12 month schedule for both our Children will be in excess of €140,000 of which we need to raise privately with the generous support and help of family and friends.
                    We would be extremely grateful for your kindness and consideration to support Hannah & Patrick’s treatment in the USA, as we plan to make the first treatment visit in late October 2014.


                </div>
                <div data-role="footer" data-theme="b" data-position="fixed">
                    <?php
                    include 'includes/footer.php';
                    ?>
                </div>
            </div>
        </div>


    </body>

</html>

