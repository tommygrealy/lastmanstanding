/*
 * Last Man Standing — Admin frontend JavaScript.
 * All REST endpoint paths updated for the Python Flask backend.
 */

$(document).on("pageinit", "#homescreen", function () {
    loadResultsPending();
    displayUsersNotSubmitted();
    displayPlayingUsersNotPaid();
    displayUserSelections();
    $('#btnExecuteAutoPic').click(function () { runAutoPicks(); });
});

function loadResultsPending() {
    $.ajax({
        url: '/api/match-results-pending',
        dataType: 'json',
        success: function (json) {
            if (json.length > 0) {
                $('#numPending').text(json.length);
                $('#noScoreInputNeeded').hide();
            } else {
                $('#scoreInputNeeded').hide();
            }
            $.each(json, function (key, value) {
                $('#updatePendingList').append(
                    '<li data-role="list-divider"><table><tr><td><span class="kickoffTime">'
                    + value["KickOffTime"].substring(0, value["KickOffTime"].length - 3)
                    + '</span></td></tr></table></li>'
                    + '<li><input type="text" id="homeScore_' + value["FixtureId"] + '" style="width:2em;" /> ' + value["HomeTeam"] + '</li>'
                    + '<li><input type="text" id="awayScore_' + value["FixtureId"] + '" style="width:2em;" /> ' + value["AwayTeam"] + '</li>'
                    + '<li><button onclick="updateScore(' + value["FixtureId"] + ')">submit</button></li>'
                );
            });
            $('#updatePendingList').listview("refresh");
        }
    });
}

function displayPlayingUsersNotPaid() {
    $.ajax({
        url: '/api/users-not-paid',
        dataType: 'json',
        success: function (json) {
            $.each(json, function (key, value) {
                $('#usersNotPaid').append(
                    '<div data-role="collapsible">' +
                    '<h3>' + value["FullName"] + '</h3>' +
                    '<p><a data-role="button" href="#" onclick="updateUserField(\'' + value["username"] + '\',\'PaymentStatus\',\'Paid\')" id="paidLinkPlaceHolder">Update to "Paid"</a>' +
                    '<a data-role="button" href="#" id="paidLink">Update to "Not Playing"</a>' +
                    '</p></div>'
                );
            });
            $('#usersNotPaid').enhanceWithin();
        }
    });
}

function updateScore(fixtureId) {
    var homeScore = parseInt($('#homeScore_' + fixtureId).val());
    var awayScore = parseInt($('#awayScore_' + fixtureId).val());
    var result;
    if (homeScore > awayScore) result = 1;
    else if (homeScore < awayScore) result = 3;
    else result = 2;

    var matchResult = {"FixtureId": fixtureId, "homeScore": homeScore, "awayScore": awayScore, "result": result};
    var posting = $.post("/api/submit-match-score", matchResult);
    $.mobile.loading('show', {text: 'Loading', textVisible: false, theme: 'z', html: ""});
    posting.done(function (data) {
        $.mobile.loading('hide');
        if (data.status == 1) {
            $('#updatePendingList').empty();
            loadResultsPending();
        }
    });
}

function displayUsersNotSubmitted() {
    $.ajax({
        url: '/api/users-not-submitted',
        dataType: 'json',
        success: function (json) {
            $.each(json, function (key, value) {
                $('#usersNotSubmittedList').append('<li>' + value["FullName"] + '</li>');
            });
            $('#usersNotSubmittedList').listview("refresh");
        }
    });
}

function displayUserSelections() {
    $.ajax({
        url: '/api/all-selections',
        dataType: 'json',
        success: function (json) {
            $.each(json, function (key, value) {
                $('#currentSelectionsList').append(
                    '<li data-role="list-divider">Username: ' + value["username"] + '</li>' +
                    '<li>' + value["HomeTeam"] + ' vs ' + value["AwayTeam"] + '</li>' +
                    '<li>Selected: <strong>' + value["PredictedTeam"] + '</strong></li>'
                );
            });
            $('#currentSelectionsList').listview("refresh");
        }
    });
}

function updateUserField(username, field, newValue) {
    var userUpdateInfo = {"userToUpdate": username, "fieldToUpdate": field, "newValue": newValue};
    var posting = $.post("/api/update-user", userUpdateInfo);
    $.mobile.loading('show', {text: 'Loading', textVisible: false, theme: 'z', html: ""});
    posting.done(function (data) {
        $.mobile.loading('hide');
        if (data.status == 1) {
            $('#usersNotPaid').empty();
            displayPlayingUsersNotPaid();
        }
    });
}

function sendReminder() {
    $.post("/api/send-mail-reminder", {}, function (data) {
        alert(data.reason || (data.status == 1 ? "Reminders sent!" : "Send failed"));
    });
}

function runAutoPicks() {
    if (confirm("Warning!\nIf you continue, users who have not made selections for this week will have teams automatically assigned.\nYou should only click \"ok\" below if the deadline has passed!")) {
        $.ajax({
            url: '/api/run-auto-picks',
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                alert(JSON.stringify(json));
            }
        });
    }
}
