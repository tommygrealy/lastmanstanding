/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

$(document).on("pageinit", "#userActivity", function() {
    displayUsersNotSubmitted();
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
                console.log("value = " + value["FullName"]);
               
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
        'url':
                'restServices/getAllSelections.php',
        dataType: 'json',
        success: function(json) {
            $.each(json, function(key, value) {
                console.log(JSON.stringify(json));
               
                $('#currentSelectionsList').append(
                        '<li>Username:'+ value["username"] + '<br>' + value["HomeTeam"] + ' vs ' + value["AwayTeam"] + '<br>Selected:' + value["PredictedTeam"] + '</li>'
                        )
            });
            $('#currentSelectionsList').listview("refresh");
        }
    });
}