<html>
    <head>
        <link rel="stylesheet" href="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.css">
        <link rel="stylesheet" href="styles/themes/bluyel.min.css">
        <title>Last Man Standing</title>      
        <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
        <script src="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.js"></script>
        <script src="scripts/forgotpass.js"></script>
         <meta name="viewport" content="initial-scale=1, maximum-scale=1">
    </head>
    <body>
        <div data-role="page">
            <div data-role="header">
                <?php include 'includes/header_nologin.php';?>
            </div>
            <div data-role="content">      
                <form data-ajax="false" id="resetRequestForm"> 
                    Please enter your username:<br /> 
                    <input type="text" name="username" value="" /> 
                    <br />Don't know or cannot remember your username?<br />
                    Enter the email address used when you registered with LMS:<br /> 
                    <input type="text" name="email" value="" /> 
                    <br /><br /> 
                    
                    <input type="button"  onclick="requestPassReset($('#resetRequestForm').serialize());" value="Continue" /> 
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
