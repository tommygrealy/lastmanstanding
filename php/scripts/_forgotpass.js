/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


function requestPassReset(data){
    console.log(data);
    $.post("restServices/requestPasswordReset.php", data, function(responseData){
        console.log(JSON.stringify(responseData));
        if (responseData["status"]=="success"){
        	alert('An email has been sent to the registered email account with reset instructions')
        }
        else{
        	alert('User does not exist')
        }
    })
    
}


function doPassReset(data){
    console.log(data);
   $.post("restServices/doPasswordReset.php", data, function(responseData){
        console.log(JSON.stringify(responseData));
        if (responseData["status"]=="success"){
            alert("Password has been succesfully reset for " + responseData["reason"] + ", please log in using your new password");
            window.location="login.php";
        }
        else
        {
            alert ("Password could not be reset: " + responseData["reason"]);
        }
    }) 
    
}




