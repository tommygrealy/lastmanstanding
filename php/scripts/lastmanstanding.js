/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

var noFixToDisplayMsg = "There are currently no fixtures available for selection, \n\
    fixtures for the next round will be avilable for selection at the concusion of the current round of matches";

var userToView = "";

$(document).on("pageinit", "#standings", function () {
    displayPlayerStandings();
});

$(document).on("pageshow", "#userHistory", function () {
    showPlayerHist(userToView);
});





function loadUserOpts() {
    $.ajax({
        'url': 'restServices/showUserSelectionOptions.php',
        dataType: 'json',
        success: function (json) {
            if (json.userstatus) {
                if (json.userstatus.CompStatus == "Eliminated") {
                    console.log("Elim");
                    $("#elminiatedNotifyPopup").popup();
                    $("#elminiatedNotifyPopup").popup("open");
                    //return;
                }

                if (json.userstatus.PaymentStatus == "Pending") {
                    $("#paymentNotifyPopup").popup();
                    $("#paymentNotifyPopup").popup("open");
                    console.log("PayPend");
                    //return;
                }
            }

            if (json.fixtures) {
                $('#messageInformSelect').html("Please select one match winner from the list of fixtures below: <br>")
                var AllowedTeams = json.availableTeams;
                console.log(JSON.stringify(AllowedTeams));
                $("#upComingFixtureList").empty();
                $.each(json.fixtures, function (key, value) {
                    var HomeTeamAvilableMarkup = '<span class="availableHomeTeam">',
                            AwayTeamAvailableMarkup = '<span class="availableAwayTeam">';

                    if (AllowedTeams.indexOf(value.ShortNameHome) == -1) {
                        HomeTeamAvilableMarkup = '<span class="unavilableHomeTeam">'
                    }
                    if (AllowedTeams.indexOf(value.ShortNameAway) == -1) {
                        AwayTeamAvailableMarkup = '<span class="unavilableAwayTeam">'
                    }


                    $("#upComingFixtureList").append(
                            '<li data-role="list-divider"><table><tr><td><span class="kickoffTime">'
                            + value.KickOffTime.substring(0, value.KickOffTime.length - 3) + '</span></td><td><image src="' + value.HomeCrestImg + '" width=30 height=30 /></td><td><span class="vsSeparator">vs</span> </td><td><image src="' + value.AwayCrestImg + '" width=30 height=30 /></td></tr></table>' +
                            '</li>' +
                            '<li><a href="#" onclick="updateSelection(' + value.FixtureId + ',\'' + value.HomeTeam + '\', \'' + value.AwayTeam + '\',' + 1 + ')" >' + HomeTeamAvilableMarkup + value.HomeTeam + '</a></li>' +
                            '<li><a href="#" onclick="updateSelection(' + value.FixtureId + ',\'' + value.HomeTeam + '\', \'' + value.AwayTeam + '\',' + 3 + ')" >' + AwayTeamAvailableMarkup + value.AwayTeam + '</a></li>'

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


function updateSelection(fixid, homeTeam, awayTeam, selected) {
    //TODO: update the currentSelection div
    $("#submitNow").unbind("click");
    switch (selected) {
        case 1:
            $('#csTeamWin').text(homeTeam + "(home) to beat " + awayTeam);
            break;
        case 3:
            $('#csTeamWin').text(awayTeam + "(away) to beat " + homeTeam);
            break;
    }

    $('#currentSelection').slideDown();


    //TODO: Fix bug - this gets called multiple times if user changes their selection mutliple times before hitting submit.
    $('#submitNow').click(function () {
        makeSubmission(fixid, selected)
    })
}

function cancelPrediction(predictionId) {
    if (confirm('Are you sure you want to cancel this prediction?')) {
        var predictionToCancel = {"predictionId": predictionId};
        var posting = $.post("restServices/cancelPredictionSvc.php", predictionToCancel);
        $.mobile.loading('show', {
            text: 'Loading',
            textVisible: false,
            theme: 'z',
            html: ""
        });
        posting.done(function (data) {
            console.log(JSON.stringify(data));
            if (data.ROWS_AFFECTED == 1) {
                $.mobile.loading('hide');
                $('#alreadyPredictedDetails').empty();
                $('#submitNow').show();
                $('#submitCancel').text('Cancel');
                loadUserOpts();
            }
            else {
                $.mobile.loading('hide');
            }
        })
    }
}

function makeSubmission(fixid, select)
{

    var selection = {"FixtureId": fixid, "prediction": select};
    //if (confirm('Are you sure you want to submit this prediction? \nOnce a prediction has been submitted it cannot be changed!')) {
    var posting = $.post("restServices/submitPredictionSvc.php", selection);
    $.mobile.loading('show', {
        text: 'Loading',
        textVisible: false,
        theme: 'z',
        html: ""
    });
    posting.done(function (data) {
        $.mobile.loading('hide');
        console.log(JSON.stringify(data));
        if (data.status == 1) {
            $('#csTeamWin').text("Your prediction for this week has been submitted. Good Luck!")
            $('#submitNow').hide();
            $('#submitCancel').empty();
            $('#submitCancel').text('Close');
            $('#upComingFixtureList').empty();
            $('#messageInformSelect').empty();
            loadUserOpts();
        }
        else {

            console.log(data.reason.substring(data.reason.length - 13, data.reason.length));
            //TODO: Select/case for every possible reason type
            var UsrMsg = ""
            //TODO: Below should be a switch/case to handle more error types
            if (data.reason.substring(data.reason.length - 13, data.reason.length) == "ey 'UserTeam'") {
                UsrMsg = "You have already selected this team in a previous "
                        + " round of the competition <a href=\"myhistory\">Click here for more details</a>";
            }

            if (data.reason.substring(data.reason.length - 13, data.reason.length) == "UserGameWeek'") {
                UsrMsg = "You have already submitted a prediction for this game week"
            }
            if (data.reason == "Payment Pending") {
                // redirect to payment page.
                UsrMsg = "Entry fee not yet paid";
                $('#submitNow').css("display: none;");
                $('#submitCancel').css("display: none;");
                $('#goPayment').show();
            }

            if (data.reason == "eliminated from comp") {
                // redirect to payment page.
                UsrMsg = " because you have been eliminated from this competition";
                $('#submitNow').css("display: none;");
                $('#submitCancel').css("display: none;");
                $('goMyHistory').show();
            }

            //$('#currentSelection').empty();
            $('#csTeamWin').html("Could not submit prediction <br> \n" + UsrMsg);


        }
    });
    //}
}

function showAlreadyPlayed(selectionData) {
    //$("#alreadyPredictedDetails").empty();
    //console.log("already played funciton hit")
    console.log(JSON.stringify(selectionData));
    console.log("Prediction to cancel=" + selectionData[0].PredictionID);
    chgPredLinkHtml = '<button onclick="cancelPrediction(' + selectionData[0].PredictionID + ')">Click Here to Cancel This Prediction</button>';
    $("#alreadyPredictedDetails").html("<h3> Your prediction for this round has been submitted </h3>" +
            "<p>Fixture: " + selectionData[0].HomeTeam + " v " +
            selectionData[0].AwayTeam + "<br/>You selected:  " + selectionData[0].PredictedTeam + "<br>" +
            "<br>" + chgPredLinkHtml + "<br>" +
            "<br>Best of Luck!</p>");
    $('#alreadyPredictedDetails').collapsible("refresh");

    $('#messageInformSelect').fadeOut('slow');
    $('#upComingFixtureList').fadeOut('slow');

}


function displayPlayerStandings() {
    $.ajax({
        'url':
                'restServices/userStandings.php',
        dataType: 'json',
        success: function (json) {


            $.each(json, function (key, value) {
                var markUp = "";
                console.log("value = " + value["username"]);
                if (value["CompStatus"] == "Playing") {
                    markUp = '<span class="activePlayerName">';
                }
                else if (value["CompStatus"] == "Eliminated") {
                    markUp = '<span class="elimPlayerName">';
                }
                $('#playerStandingsList').append(
                        '<li><a href="#userHistory" onclick="userToView=\'' + value["username"] + '\'" >' + markUp + value["FullName"] + '</span></a></li>'
                        )

            });
            $('#playerStandingsList').listview("refresh");

        }
    });
}


function displaySelectionsPostDeadline() {
    $.ajax({
        'url': 'restServices/getSelectionsPostDeadline.php',
        dataType: 'json',
        success: function (json) {
            if (json[0].TIME_PUBLIC) {
               $('#publicSelectionsListLabel').html("This week's predictions will appear here after the deadline");
            }
            else {
                $('#publicSelectionsListLabel').html("This week's predictions:");
                $('#messageInformSelect').html("Submission deadline for the current game week has passed")
                $.each(json, function (key, value) {
                    console.log(JSON.stringify(json));

                    $('#publicSelectionsList').append(
                            '<li data-role="list-divider">Player: ' + value["FullName"] + '</li><li>' + value["HomeTeam"] + ' vs ' + value["AwayTeam"] + '</li><li>Selected: <strong>' + value["PredictedTeam"] + '</strong></li>'
                            )
                });
                $('#publicSelectionsList').listview("refresh");
            }
        }
    });
}

function showPlayerHist(inUser) {
    $('#userHistoryList').empty();
    //console.log("Getting history for: " + inUser);
    $.ajax({
        'url': 'restServices/getUserPredictionHistory.php?player=' + inUser,
        dataType: 'json',
        success: function (json) {
            $('#histForUser').html(inUser)
            $.each(json, function (key, value) {
                var markUp = "";
                console.log(JSON.stringify(value));
                if (value["PredictedResult"] == 1) {
                    markUp = '<td style="background-color:green;"> win </td>';
                }
                else if (value["PredictedResult"] == 0) {
                    markUp = '<td style="background-color:red"> lose </td>';
                }
                else {
                    markUp = '<td style="background-color:orange"> pending </td>';
                }

                $('#userHistoryList').append(
                        '<li><table class="predictTable"> \n <tr><td class="predictTableLabel">Fixture Date/Time: </td><td>' + value["KickOffTime"] + '</td></tr>' +
                        '<tr><td class="predictTableLabel">Home Team: </td><td>' + value["HomeTeam"] +
                        '</td></tr><tr><td class="predictTableLabel">Away Team: </td><td>' + value["AwayTeam"] +
                        '</td></tr><tr><td class="predictTableLabel">Selected: </td><td>' + value["PredictedWinner"] + '</td></tr>' +
                        '<tr><td class="predictTableLabel">Result: </td>' + markUp + '</tr></table></li>'
                        )

            });
            $('#userHistoryList').listview("refresh");

        }
    });
}


function requestPassReset(data) {
    console.log(data);
    $.mobile.loading('show', {
        text: 'Loading',
        textVisible: true,
        theme: 'z',
        html: ""
    });
    var posting = $.post("restServices/requestPasswordReset.php", data);
    posting.done(function (responseData) {
        $.mobile.loading('hide');
        console.log(JSON.stringify(responseData));
        if (responseData["status"] == "success") {
            alert('An email has been sent to the registered email account with reset instructions')
        }
        else {
            alert('User does not exist')
        }
    })

}


function doPassReset(data) {
    console.log(data);
    $.mobile.loading('show', {
        text: 'Loading',
        textVisible: true,
        theme: 'z',
        html: ""
    });
    $.post("restServices/doPasswordReset.php", data, function (responseData) {
        $.mobile.loading('hide');
        console.log(JSON.stringify(responseData));
        if (responseData["status"] == "success") {
            alert("Password has been succesfully reset for " + responseData["reason"] + ", please log in using your new password");
            window.location = "login.php";
        }
        else
        {
            alert("Password could not be reset: " + responseData["reason"]);
        }
    })

}