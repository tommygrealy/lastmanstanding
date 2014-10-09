/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

//setInterval(function(){loadinfo(5)},5000)

// When running on WIFI network @ home
var socketServer = 'localhost'

// When running on Razri phone hotspot
//var socketServer = '192.168.43.44'

//TODO: Listen to socket on http://localhost:12345 (nodeJS socket emmiter)

function loadfixtures() {
    $.ajax({
        'url':
                'restServices/showUserSelectionOptions.php',
        dataType: 'json',
        success: function(json) {
            if (json.fixtures) {
                $('#messageInformSelect').html("Please select one match winner from the list of fixtures below: <br>")
                var AllowedTeams = json.availableTeams;
                console.log(JSON.stringify(AllowedTeams))
                $("#upComingFixtureList").empty();
                $.each(json.fixtures, function(key, value) {
                    var HomeTeamAvilableMarkup = '<TD class="availableHomeTeam">', AwayTeamAvailableMarkup = '<TD class="tdAvailableAwayTeam">';
                    if (AllowedTeams.indexOf(value.ShortNameHome) == -1) {
                        HomeTeamAvilableMarkup = '<TD class="tdUnavilableHomeTeam">'
                    }
                    if (AllowedTeams.indexOf(value.ShortNameAway) == -1) {
                        AwayTeamAvailableMarkup = '<TD class="tdUnavilableAwayTeam">'
                    }
                    $("#upComingFixtureList").append(
                            '<li data-role="list-divider"><table><tr><td><span class="kickoffTime">'
                            + value.KickOffTime.substring(0, value.KickOffTime.length - 3) + '</span></td><td><image src="' + value.HomeCrestImg + '" width=30 height=30 /></td><td><span class="vsSeparator">vs</span> </td><td><image src="' + value.AwayCrestImg + '" width=30 height=30 /></td></tr></table>' +
                            '</li>' +
                            '<li><a href="#" onclick="makeSubmission(' + value.FixtureId + ', ' + 1 + ')" >' + value.HomeTeam + '</a></li>' +
                            '<li><a href="#" onclick="makeSubmission(' + value.FixtureId + ', ' + 3 + ')" >' + value.AwayTeam + '</a></li>'

                            )
                });
                $('#upComingFixtureList').listview("refresh");
            }
            else {
                showAlreadyPlayed(json);
            }

        }
    });


}


function makeSubmission(fixid, select)
{
    var selection = {"FixtureId": fixid, "prediction": select};
    if (confirm('Are you sure you want to submit this prediction? \nOnce a prediction has been submitted it cannot be changed!')) {
        var posting = $.post("restServices/submitPredictionSvc.php", selection);
        $.mobile.loading('show', {
            text: 'Loading',
            textVisible: false,
            theme: 'z',
            html: ""
        });
        posting.done(function(data) {
            $.mobile.loading('hide');
            console.log(JSON.stringify(data));
            if (data.status == 1) {
               //alert("Prediction has been submitted");
                loadfixtures();
            }
            else {
                
                console.log(data.reason.substring(data.reason.length-13, data.reason.length));
                //TODO: Select/case for every possible reason type
                var UserMsg = ""
                //TODO: Below should be a switch/case to handle more error types
                if (data.reason.substring(data.reason.length-13, data.reason.length)=="UserGameWeek'"){
                    UsrMsg="You have already submitted a prediction for this game week"                                                
                }
                if (data.reason=="Payment Pending"){
                    // redirect to payment page.
                    UsrMsg="Entry fee not yet paid";
                }
                alert("Could not submit prediction \n" + UsrMsg);
            }
        });
    }
}

function showAlreadyPlayed(selectionData) {
    //$("#alreadyPredictedDetails").empty();
    $("#alreadyPredictedDetails").html("<h3> Your prediction for this round has been submitted </h3>" +
            "<p>Fixture: " + selectionData[0].HomeTeam + " v " + 
            selectionData[0].AwayTeam + "You selected: " + selectionData[0].PredictedTeam + "</p>");
    $('#alreadyPredictedDetails').collapsible("refresh"); 
    
    $('#messageInformSelect').fadeOut('slow');
    $('#upComingFixtureList').fadeOut('slow');
   
}