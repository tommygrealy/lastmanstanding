<?php
// First we execute our common code to connection to the database and start the session 
require("common.php");

// At the top of the page we check to see whether the user is logged in or not 
if (empty($_SESSION['user'])) {
    // If they are not, we redirect them to the login page. 
    header("Location: login.php");

    // Remember that this die statement is absolutely critical.  Without it, 
    // people can view your members-only content without logging in. 
    die("Redirecting to login.php");
}

$lms_username = $_SESSION['user']['username'];
$lms_privlevel = $_SESSION['user']['PrivLevel'];

if ($lms_privlevel<3){
    header("Location: login.php");
    die ("Admin access only.. redirecting");
}

// Everything below this point in the file is secured by the login system 
// We can display the user's username to them by reading it from the session array.  Remember that because 
// a username is user submitted content we must use htmlentities on it before displaying it to the user. 
?> 
<html>
    <head>
        <!--<link rel="stylesheet" href="styles/themes/actionshots_mobile.min.css" />
        <link rel="stylesheet" href="styles/themes/jquery.mobile.icons.min.css" />-->
        <link rel="stylesheet" href="http://code.jquery.com/mobile/1.4.3/jquery.mobile-1.4.3.min.css">
        <link rel="stylesheet" href="styles/themes/bluyel.min.css">
        <link rel="stylesheet" href="styles/style.css">
        <title>Last Man Standing - Home</title>
        <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
        <script src="http://code.jquery.com/mobile/1.4.3/jquery.mobile-1.4.3.min.js"></script>
        <script src="scripts/adminFunctions.js"></script>
        <meta name="viewport" content="initial-scale=1, maximum-scale=1">
        <script>
            $(document).ready(function() {
                loadResultsPending();
            });
        </script>
    </head>
    <body>
        <div data-role="page" id="homescreen">
            <div data-role="header" data-position="fixed">
                
                <?php
                include 'includes/header.php';
                #echo 'PrivLevel=' . $lms_privlevel;
                ?>
            </div>



            <div data-role="content">
                You are logged in as: <?php echo htmlentities($lms_username, ENT_QUOTES, 'UTF-8'); ?> <br><br /> 
                <span id="scoreInputNeeded"><span id="numPending"></span> fixtures require score updates. Please enter the scores below.</span>
                <span id="noScoreInputNeeded">All match scores are up to date - no input required</span>

                


                <span id="messageInformSelect"> </span>
                <ul id="updatePendingList" data-role="listview" data-inset="true" data-divider-theme="a">

                </ul>

            </div>


            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>
            </div>  
        </div>

        <!-- payment page -->
        <div data-role="page" id="paymentPage">
            <div data-role="header" data-position="fixed">
                <?php
                include 'includes/header.php';
                ?>
            </div>


            <div data-role="content"><p>

                <div data-role="fieldcontain">
				Payment can be made in cash to Tommy Grealy (IR5-2-B4) or to James O'Neill or online using the payment form below<br> 
				Note that this will take you to paypal in order to complete the payment. You do not need to have a Paypal account 
				to complete payment, just click the "Don't have a Paypal Account" or "Pay with Card" link.
                    <form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
                        <input type="hidden" name="cmd" value="_xclick">
                        <input type="hidden" name="business" value="payments@actionshots.ie">
                        <input type="hidden" name="lc" value="IE">
                        <input type="hidden" name="item_name" value="<?php echo $lms_username . '|:| LMS entry fee '; ?>">
                        <input type="hidden" name="item_number" value="LMS01">
                        <input type="hidden" name="button_subtype" value="services">
                        <input type="hidden" name="no_note" value="0">
                        <input type="hidden" name="bn" value="PP-BuyNowBF:btn_buynowCC_LG.gif:NonHostedGuest">
                        <table>
                            <tr><td><input type="hidden" name="on0" value="Payment Options">Payment Options</td></tr><tr><td><select name="os0">
                                        <option value="Entry Fee">Entry Fee €10.00 EUR</option>
                                       
                                    </select> </td></tr>
                            <tr><td><input type="hidden" name="on1" value="Comment (Optional)">Comment (Optional)</td></tr>
                            <tr><td><input type="text" name="os1" maxlength="200"></td></tr>
                        </table>
                        <input type="hidden" name="currency_code" value="EUR">
                        <input type="hidden" name="option_select0" value="Entry Fee">
                        <input type="hidden" name="option_amount0" value="10.00">
                        <!--input type="hidden" name="option_select1" value="Entry + 10 Euro Donation">
                        <input type="hidden" name="option_amount1" value="15.00">
                        <input type="hidden" name="option_select2" value="Entry + 15 Euro Donation">
                        <input type="hidden" name="option_amount2" value="20.00">
                        <input type="hidden" name="option_index" value="0"-->
                        <input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_buynowCC_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
                        <img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
                    </form>
                </div> 

            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>
            </div>
        </div>

        <!-- rules page -->
        <div data-role="page" id="rules">
            <div data-role="header" data-position="fixed">
                <?php
                include 'includes/header.php';
                ?>
            </div>
            <div data-role="content">
                <?php
                include 'includes/rules.php';
                ?>

            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>
            </div>


        </div>

        <!-- charity description page -->
        <div data-role="page" id="charity">
            <div data-role="header" data-position="fixed">
                <?php
                include 'includes/header.php';
                ?>
            </div>
            <div data-role="content">
            
            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>
            </div>
        </div>
        
        <!-- standings page -->
        <div data-role="page" id="standings">
            <div data-role="header" data-position="fixed">
                <?php
                include 'includes/header.php';
                ?>
            </div>
            <div data-role="content">
                <h3>Current Player Standings</h3>
                <h5>Search Players
                    <form class="ui-filterable">
                        <input id="myFilter" data-type="search">
                    </form></h5>
                <ul data-role="listview" id="playerStandingsList" data-filter="true" data-input="#myFilter" data-inset="true">

                    <!-- this list is dynamically updated on page init -->
                </ul>


            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>
            </div>
        </div>
        
        
        
                
        <!-- payment confirmed page -->
        <div data-role="page" id="paymentConfirmed">
            <div data-role="header" data-position="fixed">
                <?php
                include 'includes/header.php';
                ?>
            </div>
            <div data-role="content">
                <h3>Payment confirmed, Thank You!</h3>
                Thank you for your payment. Your transaction has been completed, 
                and a receipt for your purchase has been emailed to you. You may 
                now continue to play in the competition by <a href="#homescreen">clicking here</a>

            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>
            </div>
        </div>



        <!-- user prediction history page -->
        <div data-role="page" id="userHistory">
            <div data-role="header" data-position="fixed">
                <?php
                include 'includes/header.php';
                ?>
            </div>
            <div data-role="content">
                <h3>History for <span id="histForUser"></span> </h3>
                <ul data-role="listview" id="userHistoryList" data-inset="true">

                </ul>


            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>
            </div>
        </div>





    </div>


</body>

</html>



