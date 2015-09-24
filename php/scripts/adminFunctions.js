/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

$(document).on("pageinit", "#homescreen", function() {
    loadResultsPending();
    displayUsersNotSubmitted();
    displayPlayingUsersNotPaid();
    displayUserSelections();
});

function loadResultsPending(){
    $.ajax({
        'url':
                'restServices/showMatchResultsPending.php',
        dataType: 'json',
        success: function(json) {
            if(json.length>0){
                $('#numPending').text(json.length);
                $('#noScoreInputNeeded').hide()
            }
            else{
                $('#scoreInputNeeded').hide();
            }
            $.each(json, function(key,value) {
                $('#updatePendingList').append(
                         '<li data-role="list-divider"><table><tr><td><span class="kickoffTime">'
                            + value["KickOffTime"].substring(0, value["KickOffTime"].length - 3) + '</span></td></tr></table>' +
                            '</li>' +
                            '<li><input type=text id="homeScore_' + value["FixtureId"] + '" style="width:2em;" /> '+value["HomeTeam"]+'</li>' +
                            '<li><input type=text id="awayScore_' + value["FixtureId"] + '" style="width:2em;" /> '+value["AwayTeam"]+'</li>' + 
                            '<li><button onclick="updateScore(' + value["FixtureId"] +  ')">submit</button></li>'

                        )

            });
            $('#updatePendingList').listview("refresh");

        }
    });
}

function displayPlayingUsersNotPaid(){
    $.ajax({
        'url':
                'restServices/getUsersNotPaid.php',
        dataType: 'json',
        success: function(json) {
            $.each(json, function(key, value) {
                var markUp = "";
                console.log("value = " + value["FullName"]);
               
                $('#usersNotPaid').append(
                        '<div data-role="collapsible">'+
                        '<h3>'+ value["FullName"] +'</h3>'+
                        '<p><a data-role="button" href="#" onclick="updateUserField(\''+ value["username"]+'\',\'PaymentStatus\',\'Paid\')" id="paidLinkPlaceHolder">Update to \"Paid\"</a>'+
                        '<a data-role="button" href="#" id="paidLink">Update to \"Not Playing\"</a>'+
                        '</p>'+
                        '</div>'
                        )
            });
            $('#usersNotPaid').enhanceWithin();
        }
    });
}


function updateScore(fixtureId){
    var homeScoreElId = '#homeScore_' + fixtureId;
    var awayScoreElid = '#awayScore_' + fixtureId;
    homeScore = $(homeScoreElId).val() 
    awayScore = $(awayScoreElid).val();
    
    var result;
    if (homeScore>awayScore){
        result=1;
    }
    else if (homeScore<awayScore){
        result=3;
    }
    else{
        result=2;
    }

    var matchResult = {"FixtureId": fixtureId, "homeScore": homeScore, "awayScore":awayScore, "result":result};
    
    console.log("Posting: " + JSON.stringify(matchResult));
    
    var posting = $.post("restServices/submitMatchScore.php", matchResult);
    $.mobile.loading('show', {
        text: 'Loading',
        textVisible: false,
        theme: 'z',
        html: ""
    });
    posting.done(function(data) {
        console.log(JSON.stringify(data));
        if (data.status==1){
            $.mobile.loading('hide');
            $('#updatePendingList').empty();
            loadResultsPending();
        }
        else{
            $.mobile.loading('hide');
        }
    })
}


function displayUsersNotSubmitted() {
    $.ajax({
        'url':
                'restServices/getUsersNotSubmitted.php',
        dataType: 'json',
        success: function(json) {
            $.each(json, function(key, value) {
                var markUp = "";
                //console.log("value = " + value["FullName"]);
               
                $('#usersNotSubmittedList').append(
                        '<li>' + value["FullName"] + '</li>'
                        )
            });
            $('#usersNotSubmittedList').listview("refresh");
        }
    });
}

   
   
function displayUserSelections() {
    $.ajax({
        'url':'restServices/getAllSelections.php',
        dataType: 'json',
        success: function(json) {
            $.each(json, function(key, value) {
                console.log(JSON.stringify(json));
               
                $('#currentSelectionsList').append(
                        '<li data-role="list-divider">Username:'+ value["username"] + '</li><li>' + value["HomeTeam"] + ' vs ' + value["AwayTeam"] + '</li><li>Selected: <strong>' + value["PredictedTeam"] + '</strong></li>'
                        )
            });
            $('#currentSelectionsList').listview("refresh");
        }
    });
}


function updateUserField(username,field,newValue){
   // alert (username + "," + field + "," + newValue)
    
    var userUpdateInfo = {"userToUpdate": username, "fieldToUpdate": field, "newValue": newValue};
    var posting = $.post("restServices/updateUser.php", userUpdateInfo);
    $.mobile.loading('show', {
        text: 'Loading',
        textVisible: false,
        theme: 'z',
        html: ""
    });
    
    //TODO: Fix below
    posting.done(function(data) {
        console.log(JSON.stringify(data));
        if (data.status==1){
            $.mobile.loading('hide');
            $('#usersNotPaid').empty();
            displayPlayingUsersNotPaid();
        }
        else{
            $.mobile.loading('hide');
        }
    })
    
}