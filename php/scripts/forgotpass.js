/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


function requestPassReset(data){
    console.log(data);
    $.post("restServices/requestPasswordReset.php", data, function(responseData){
        console.log("Response was recieved");
        alert ("Password reset instructions have been sent to the email address for this account, please check your mail.")
        window.location.href = 'ResetPass.php';
        console.log(JSON.stringify(responseData));
    })
    
}



