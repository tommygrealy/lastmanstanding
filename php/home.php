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
        <script src="scripts/lastmanstanding.js"></script>
        <meta name="viewport" content="initial-scale=1, maximum-scale=1">
        <script>
            $(document).ready(function() {
                loadfixtures();
            });
        </script>
    </head>
    <body>
        <div data-role="page" id="homescreen">
            <div data-role="header" data-position="fixed">
                <?php
                include 'includes/header.php';
                ?>
            </div>



            <div data-role="content">
                You are logged in as: <?php echo htmlentities($lms_username, ENT_QUOTES, 'UTF-8'); ?> <br><br /> 
                <div id="currentSelection">
                    <h3>Your Selection</h3>
                    <span id="csTeamWin"></span><br>
                    <a href="#" id="submitNow" data-role="button">Submit</a>
                    <a href="#" id="submitCancel" data-role="button" onclick="$('#currentSelection').fadeOut();">Cancel</a>
                </div>

                <div id="alreadyPredictedDetails"></div>



                <span id="messageInformSelect"> </span>
                <ul id="upComingFixtureList" data-role="listview" data-inset="true" data-divider-theme="a">

                </ul>
             
            </div>


            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>;  
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
                    In order to join the competition, you must complete the online entry fee payment before playing. 
                    Please note that you will be directed to PayPal to complete this transaction. </p>
                <div data-role="fieldcontain">
                    <form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
                        <input type="hidden" name="cmd" value="_xclick">
                        <input type="hidden" name="business" value="payments@actionshots.ie">
                        <input type="hidden" name="lc" value="IE">
                        <input type="hidden" name="item_name" value="<?php echo $lms_username . ' LMS entry fee '; ?>">
                        <input type="hidden" name="item_number" value="LMS01">
                        <input type="hidden" name="button_subtype" value="services">
                        <input type="hidden" name="no_note" value="0">
                        <input type="hidden" name="bn" value="PP-BuyNowBF:btn_buynowCC_LG.gif:NonHostedGuest">
                        <table>
                            <tr><td><input type="hidden" name="on0" value="Payment Options">Payment Options</td></tr><tr><td><select name="os0">
                                        <option value="Entry Fee">Entry Fee €5.00 EUR</option>
                                        <option value="Entry + 10 Euro Donation">Entry + 10 Euro Donation €15.00 EUR</option>
                                        <option value="Entry + 15 Euro Donation">Entry + 15 Euro Donation €20.00 EUR</option>
                                    </select> </td></tr>
                            <tr><td><input type="hidden" name="on1" value="Comment (Optional)">Comment (Optional)</td></tr>
                            <tr><td><input type="text" name="os1" maxlength="200"></td></tr>
                        </table>
                        <input type="hidden" name="currency_code" value="EUR">
                        <input type="hidden" name="option_select0" value="Entry Fee">
                        <input type="hidden" name="option_amount0" value="5.00">
                        <input type="hidden" name="option_select1" value="Entry + 10 Euro Donation">
                        <input type="hidden" name="option_amount1" value="15.00">
                        <input type="hidden" name="option_select2" value="Entry + 15 Euro Donation">
                        <input type="hidden" name="option_amount2" value="20.00">
                        <input type="hidden" name="option_index" value="0">
                        <input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_buynowCC_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
                        <img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
                    </form>
                </div>
            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>;  
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
                <h3>Competition Rules</h3>
                <A href="#paymentPage">Pay</A> your entry fee at week 1 — no need to pay again. 50% of the fee 
                goes to support our chosen <a href="#charity">charity</a> and the 
                rest goes into the pot to be won.
                Each week, simply pick a team playing a match that week – 
                if your team wins, you go through, lose or draw and you’re out.
                You can only pick a team to win once in a competition, 
                so be tactical about who you pick and when.
                All selections must be in 1 hour before kick off of the first match 
                — once you submit a team, you can <u>NOT</u> change your selection.
                If you forget to pick a team, we’ll randomly pick one for you for that round.
                Last Man continues until only one person remains and wins the pot. 
                If two participants remain at the end, the pot is equally distributed; 
                however, if more than two remain everyone goes through to the next round. 
                If all remaining players lose in the last round, they all go through to the next round.

            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>;  
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
                <h3>Funding for Hannah & Patrick McCarthy’s Medical Treatment in the USA</h3>
                The Parents of Hannah aged 7 years and Patrick aged 5 year’s respectfully seek funding support for Autism treatment for their Children in the USA.
                Hannah & Patrick are both diagnosed with ASD, Autism and live with their Parents, Caroline and Neil in Castleknock, Dublin.  According to Mainstream Medicine there is no known cure for ASD and treatment is not covered by the HSE or private medical insurance.
                As Parents it is very difficult to accept this fate and for years we have tirelessly researched ASD and appropriate treatments. Both Children are non-verbal, very poor cognition and fully dependant on us for their care. Hannah has a serious food disorder and is fed through a gastrostomy tube since 2010. 
                Through exhaustive research we uncovered the Advanced Medical Centre in North Carolina, USA. They specialise in the advanced treatment of ASD for Children. The treatment is carried out over a four week period. The treatment schedule is repeated at least 4 times inside 12 months. We personally know one little boy who is now fully cured and attending main stream school in Dublin 15 after completing Chelation treatment.
                The cost for the 12 month schedule for both our Children will be in excess of €140,000 of which we need to raise privately with the generous support and help of family and friends.
                We would be extremely grateful for your kindness and consideration to support Hannah & Patrick’s treatment in the USA, as we plan to make the first treatment visit in late October 2014.


            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>;  
            </div>
        </div>
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
                ?>;  
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
                <h3>History for </h3>
                <ul data-role="listview" id="userHistoryList" data-inset="true">

                </ul>


            </div>
            <div data-role="footer" data-position="fixed">
                <?php
                include 'includes/footer.php';
                ?>;  
            </div>
        </div>





    </div>


</body>

</html>



