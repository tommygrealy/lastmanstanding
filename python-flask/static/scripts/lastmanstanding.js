/*
 * Last Man Standing — main frontend JavaScript.
 * All REST endpoint paths updated for the Python Flask backend.
 * API endpoints are now at /api/* instead of restServices/*.php
 */

var noFixToDisplayMsg = "There are currently no fixtures available for selection, \
    fixtures for the next round will be available for selection at the conclusion of the current round of matches";

var userToView = "";
var currentUsername = "";
var user_dynamite_id = null;
var dynamiteTargetUser = "";
var dynamiteTargetFullName = "";

$(document).on("pageinit", "#standings", function () {
    displayPlayerStandings();
});

$(document).on("pageshow", "#userHistory", function () {
    showPlayerHist(userToView);
});

$(document).on("pageinit", "#dynamite_page", function () {
    $.ajax({
        url: '/api/dynamite-options',
        type: 'GET',
        dataType: 'json',
        success: function (response) {
            if (response.length > 0 && response[0].status === 1) {
                localStorage.setItem('updatedAt', response[0].updated_at);
                user_dynamite_id = response[0].dynamite_id;
                displayPlayersForDynamite();
                $('#no-dynamite-msg').hide();
                $('#dynamite-drop-options').show();
            }
        },
        error: function (xhr, status, error) {
            console.log('Error: unexpected response from dynamite-options, ' + error);
        }
    });
    showDynamiteHist();
});

var params = new window.URLSearchParams(window.location.search);

function formatDateTime(dateTimeString) {
    const date = new Date(dateTimeString.replace(' ', 'T'));
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const dayName = days[date.getDay()];
    let hours = date.getHours();
    const period = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const formattedTime = minutes === '00' ? `${hours}${period}` : `${hours}:${minutes}${period}`;
    return `${dayName} at ${formattedTime}`;
}

function loadUserOpts() {
    $.ajax({
        url: '/api/user-selection-options',
        dataType: 'json',
        success: function (json) {
            if (json.userstatus) {
                currentUsername = json.userstatus.username;
                if (json.userstatus.CompStatus == "Eliminated") {
                    $("#elminiatedNotifyPopup").popup();
                    $("#elminiatedNotifyPopup").popup("open");
                }
                if (json.userstatus.PaymentStatus == "Pending") {
                    $("#paymentNotifyPopup").popup();
                    $("#paymentNotifyPopup").popup("open");
                }
            }

            if (json.fixtures) {
                $('#messageInformSelect').html("Please select one match winner from the list of fixtures below<br>");
                var AllowedTeams = json.availableTeams;
                $("#upComingFixtureList").empty();
                $.each(json.fixtures, function (key, value) {
                    var HomeTeamAvilableMarkup = '<span class="availableHomeTeam">',
                        AwayTeamAvailableMarkup = '<span class="availableAwayTeam">';

                    if (AllowedTeams.indexOf(value.ShortNameHome) == -1) {
                        HomeTeamAvilableMarkup = '<span class="unavilableHomeTeam">';
                    }
                    if (AllowedTeams.indexOf(value.ShortNameAway) == -1) {
                        AwayTeamAvailableMarkup = '<span class="unavilableAwayTeam">';
                    }

                    var HomeTeamFormHtml = "";
                    var AwayTeamFormHtml = "";
                    if (json.formguide) {
                        if (json.formguide[value.HomeTeam]) {
                            HomeTeamFormHtml = json.formguide[value.HomeTeam].replaceAll("WIN,", " &#128994;").replaceAll("LOS,", " &#128308;").replaceAll("DRW,", " &#128993;");
                        }
                        if (json.formguide[value.AwayTeam]) {
                            AwayTeamFormHtml = json.formguide[value.AwayTeam].replaceAll("WIN,", " &#128994;").replaceAll("LOS,", " &#128308;").replaceAll("DRW,", " &#128993;");
                        }
                    }

                    var KillerHomeTeamMarkup = "";
                    var KillerAwayTeamMarkup = "";
                    var killerSelected = 0;
                    if (value.KillerTeam == 1) {
                        killerSelected = 1;
                        KillerHomeTeamMarkup += " &#x1f9e8;";
                    }
                    if (value.KillerTeam == 3) {
                        killerSelected = 3;
                        KillerAwayTeamMarkup += " &#x1f9e8;";
                    }

                    $("#upComingFixtureList").append(
                        '<li data-role="list-divider"><table><tr><td><span class="kickoffTime">'
                        + value.KickOffTime.substring(0, value.KickOffTime.length - 3)
                        + '</span></td><td><img src="' + (value.HomeCrestImg || '') + '" width=30 height=30 /></td>'
                        + '<td><span class="vsSeparator">vs</span></td>'
                        + '<td><img src="' + (value.AwayCrestImg || '') + '" width=30 height=30 /></td></tr></table></li>'
                        + '<li><a href="#" onclick="updateSelection(' + value.FixtureId + ',\'' + value.HomeTeam + '\', \'' + value.AwayTeam + '\',' + 1 + "," + killerSelected + ')" >'
                        + KillerHomeTeamMarkup + ' ' + HomeTeamAvilableMarkup + value.HomeTeam + HomeTeamFormHtml + '</span></a></li>'
                        + '<li><a href="#" onclick="updateSelection(' + value.FixtureId + ',\'' + value.HomeTeam + '\', \'' + value.AwayTeam + '\',' + 3 + "," + killerSelected + ')" >'
                        + KillerAwayTeamMarkup + ' ' + AwayTeamAvailableMarkup + value.AwayTeam + AwayTeamFormHtml + '</span></a></li>'
                    );
                });
                $('#upComingFixtureList').listview("refresh");
                updateCountdown();
            } else {
                showAlreadyPlayed(json);
            }
        }
    });
}


function updateSelection(fixid, homeTeam, awayTeam, selected, killer) {
    killer = killer || false;
    var killerTeamMsg = "<br><br>Select {teamname} this week and if they win, you get to REMOVE a life from another player of your choice";
    $("#submitNow").unbind("click");
    switch (selected) {
        case 1:
            $('#csTeamWin').text(homeTeam + " (home) to beat " + awayTeam);
            if (killer == 1) {
                $('#csTeamWin').append(killerTeamMsg.replace("{teamname}", homeTeam));
            }
            break;
        case 3:
            $('#csTeamWin').text(awayTeam + " (away) to beat " + homeTeam);
            if (killer == 3) {
                $('#csTeamWin').append(killerTeamMsg.replace("{teamname}", awayTeam));
            }
            break;
    }
    $('#currentSelection').slideDown();
    $('#submitNow').click(function () {
        makeSubmission(fixid, selected);
    });
}

function cancelPrediction(predictionId) {
    if (confirm('Are you sure you want to cancel this prediction?')) {
        var posting = $.post("/api/cancel-prediction", {"predictionId": predictionId});
        $.mobile.loading('show', {text: 'Loading', textVisible: false, theme: 'z', html: ""});
        posting.done(function (data) {
            $.mobile.loading('hide');
            if (data.ROWS_AFFECTED == 1) {
                $('#alreadyPredictedDetails').empty();
                $('#submitNow').show();
                $('#submitCancel').text('Cancel');
                loadUserOpts();
            }
        });
    }
}

function makeSubmission(fixid, select) {
    var selection = {"FixtureId": fixid, "prediction": select};
    var posting = $.post("/api/submit-prediction", selection);
    $.mobile.loading('show', {text: 'Loading', textVisible: false, theme: 'z', html: ""});
    posting.done(function (data) {
        $.mobile.loading('hide');
        if (data.status == 1) {
            $('#csTeamWin').text("Your prediction for this week has been submitted. Good Luck!");
            $('#submitNow').hide();
            $('#submitCancel').empty();
            $('#submitCancel').text('Close');
            $('#upComingFixtureList').empty();
            $('#messageInformSelect').empty();
            loadUserOpts();
        } else {
            var UsrMsg = "";
            if (data.reason && data.reason[0]) {
                if (data.reason[0].substring(data.reason[0].length - 13) == "ey 'UserTeam'") {
                    UsrMsg = "You have already selected this team in a previous round of the competition";
                }
                if (data.reason[0].substring(data.reason[0].length - 13) == "UserGameWeek'") {
                    UsrMsg = "You have already submitted a prediction for this game week";
                }
            }
            if (data.reason == "Payment Pending") {
                UsrMsg = "Pay Tommy First - revolut €10 to @tommy5kit";
            }
            if (data.reason == "eliminated from comp") {
                UsrMsg = "You have been eliminated from the competition";
            }
            $('#csTeamWin').html("Cannot submit this prediction<br>\n" + UsrMsg);
        }
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.log("Error: " + JSON.stringify(jqXHR));
    });
}

function dropDynamite() {
    let check_timestamp = localStorage.getItem('updatedAt');
    var selection = {"user_last_update": check_timestamp, "drop_on_user": dynamiteTargetUser, "dynamite_id": user_dynamite_id};
    var posting = $.post("/api/drop-dynamite", selection);
    $.mobile.loading('show', {text: 'Loading', textVisible: false, theme: 'z', html: ""});
    posting.done(function (data) {
        $.mobile.loading('hide');
        var post_throw_msg = "";
        if (data['reason'] == "stale data") {
            post_throw_msg = "Cannot drop now as another user has recently dropped a dynamite, please click continue to refresh this page and see the latest info";
            $("#submitDynamiteCancel").remove();
            $("#submitDynamiteNow").text("Continue");
            $("#submitDynamiteNow").click(function () { location.reload(); });
        } else if (data['reason']['lives_remaining'] < 1) {
            post_throw_msg = data['reason']['player_hit'] + " is out.. good job!";
            $("#dynamite").fadeOut();
            $("#submitDynamiteNow").text("Continue");
            $("#submitDynamiteNow").click(function () { location.href = '/home#standings'; });
        } else {
            post_throw_msg = "You took a life from " + dynamiteTargetFullName + ", they now have " + data['reason']['lives_remaining'] + " lives";
            $("#dynamite").fadeOut();
            $("#submitDynamiteNow").text("Continue");
            $("#submitDynamiteNow").click(function () { location.href = '/home#standings'; });
        }
        $("#dynamite-drop-h3").text(post_throw_msg);
        $("#submitDynamiteCancel").remove();
        $("#submitDynamiteNow").text("Continue");
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.log("Request failed: " + textStatus);
    });
}

function showAlreadyPlayed(selectionData) {
    console.log(JSON.stringify(selectionData));
    var chgPredLinkHtml = '<button onclick="cancelPrediction(' + selectionData[0].PredictionID + ')">Click Here to Cancel This Prediction</button>';
    $("#alreadyPredictedDetails").html(
        "<h3> Your prediction for this round has been submitted </h3>" +
        "<p>Fixture: " + selectionData[0].HomeTeam + " v " + selectionData[0].AwayTeam +
        "<br/>You selected: " + selectionData[0].PredictedTeam + "<br>" +
        "<br>" + chgPredLinkHtml + "<br><br>Best of Luck!</p>"
    );
    $('#messageInformSelect').fadeOut('slow');
    $('#upComingFixtureList').fadeOut('slow');
}


function displayPlayerStandings() {
    $.ajax({
        url: '/api/user-standings',
        dataType: 'json',
        success: function (json) {
            $.each(json, function (key, value) {
                var lives_lost = 3 - value["lives"];
                var ballshtml = "&#9917;&nbsp;".repeat(value["lives"]);
                ballshtml += "&#10060;&nbsp;".repeat(lives_lost);
                var markUp = "";
                if (value["CompStatus"] == "Playing") {
                    markUp = '<span class="activePlayerName">' + ballshtml;
                } else if (value["CompStatus"] == "Eliminated") {
                    markUp = '<span class="elimPlayerName">';
                }
                $('#playerStandingsList').append(
                    '<li><a href="#userHistory" onclick="userToView=\'' + value["username"] + '\'">' + markUp + value["FullName"] + '</span></a></li>'
                );
            });
            $('#playerStandingsList').listview("refresh");
        }
    });
}


function displayPlayersForDynamite() {
    $.ajax({
        url: '/api/user-standings',
        dataType: 'json',
        success: function (json) {
            $.each(json, function (key, value) {
                var lives_lost = 3 - value["lives"];
                var ballshtml = "&#9917;&nbsp;".repeat(value["lives"]);
                ballshtml += "&#10060;&nbsp;".repeat(lives_lost);
                var player_tile_class = (value["CompStatus"] == "Playing") ? 'drop-target' : 'gone-target';
                $('#player-tile-targets').append(
                    '<div class="' + player_tile_class + '" id="' + value["FullName"] + '" user_attr="' + value["username"] + '">' +
                    value["FullName"] + '<br>' + ballshtml + '</div>'
                );
            });
            $("#dynamite").draggable();
            $(".drop-target").droppable({
                accept: "#dynamite",
                hoverClass: "active",
                drop: function (event, ui) {
                    $('#dynamiteSelection').slideDown();
                    dynamiteTargetFullName = $(this).attr('id');
                    dynamiteTargetUser = $(this).attr('user_attr');
                    $("#dynamite-drop-h3").text("Drop 🧨 on " + dynamiteTargetFullName + "?");
                }
            });
            $('#no-dynamite-msg').hide();
            $('#dynamite-drop-options').show();
        }
    });
}


function displaySelectionsPostDeadline() {
    $.ajax({
        url: '/api/selections-post-deadline',
        dataType: 'json',
        success: function (json) {
            if (!json || json.length === 0) return;
            if (json[0].TIME_PUBLIC) {
                $('#publicSelectionsListLabel').html("This week's predictions will appear here after the deadline");
            } else {
                $('#publicSelectionsListLabel').html("This week's predictions:");
                $('#messageInformSelect').html("Submission deadline for the current game week has passed");
                $.each(json, function (key, value) {
                    var selectionMethodText = (value["EntryType"] == "AUTO") ? "Auto-Pick*: " : "Selected: ";
                    var dynamite = "";
                    if (value["KillerTeam"] != null) {
                        if (value["PredictedTeam"] == value["HomeTeam"] && value["KillerTeam"] == 1) dynamite = " &#x1f9e8;";
                        if (value["PredictedTeam"] == value["AwayTeam"] && value["KillerTeam"] == 3) dynamite = " &#x1f9e8;";
                    }
                    $('#publicSelectionsList').append(
                        '<li data-role="list-divider">Player: ' + value["FullName"] + '</li>' +
                        '<li>' + value["HomeTeam"] + ' vs ' + value["AwayTeam"] + " - " + formatDateTime(value["KickOffTime"]) + '</li>' +
                        '<li>' + selectionMethodText + '<strong>' + value["PredictedTeam"] + dynamite + '</strong></li>'
                    );
                });
                $('#publicSelectionsList').listview("refresh");
            }
        }
    });
}

function showDynamiteHist() {
    $('#dynamiteActionsList').empty();
    $.ajax({
        url: '/api/dynamite-history',
        success: function (data) {
            $.each(data, function (key, value) {
                $('#dynamiteActionsList').append(
                    "<li>On " + value["updated_at"] + ", " + value["SourceFullName"] + " threw 🧨 at " + value["TargetFullName"] + "</li>"
                );
            });
        }
    });
}

function showPlayerHist(inUser) {
    $('#userHistoryList').empty();
    $.ajax({
        url: '/api/user-prediction-history?player=' + encodeURIComponent(inUser),
        dataType: 'json',
        success: function (json) {
            $('#histForUser').html(inUser);
            $.each(json, function (key, value) {
                var resultHtml;
                if (value["PredictedResult"] == 1) {
                    resultHtml = '<span style="color:green; font-weight:bold;">Win</span>';
                } else if (value["PredictedResult"] == 0) {
                    resultHtml = '<span style="color:red; font-weight:bold;">Lose</span>';
                } else {
                    resultHtml = '<span style="color:orange; font-weight:bold;">Pending</span>';
                }
                $('#userHistoryList').append(
                    '<div class="prediction-card" style="border:1px solid #ccc; border-radius:10px; margin:10px 0; padding:15px; box-shadow:2px 2px 8px rgba(0,0,0,0.1);">' +
                    '<div class="prediction-header" style="font-weight:bold; font-size:16px; margin-bottom:8px;">' +
                    new Date(value["KickOffTime"]).toISOString().split('T')[0] + ' — ' + value["HomeTeam"] + ' vs ' + value["AwayTeam"] +
                    '</div>' +
                    '<div class="prediction-body" style="font-size:14px;">' +
                    inUser + ' predicted ' + value["PredictedWinner"] + ' to win.<br>' + resultHtml +
                    '</div></div>'
                );
            });
        }
    });
}


function requestPassReset(data) {
    $.mobile.loading('show', {text: 'Loading', textVisible: true, theme: 'z', html: ""});
    var posting = $.post("/api/request-password-reset", data);
    posting.done(function (responseData) {
        $.mobile.loading('hide');
        if (responseData["status"] == "success") {
            alert('An email has been sent to the registered email account with reset instructions');
        } else {
            alert('User does not exist');
        }
    });
}

function doPassReset(data) {
    $.mobile.loading('show', {text: 'Loading', textVisible: true, theme: 'z', html: ""});
    $.post("/api/do-password-reset", data, function (responseData) {
        $.mobile.loading('hide');
        if (responseData["status"] == "success") {
            alert("Password has been successfully reset for " + responseData["reason"] + ", please log in using your new password");
            window.location = "/login";
        } else {
            alert("Password could not be reset: " + responseData["reason"]);
        }
    });
}

function findEarliestKickoff() {
    const elements = document.querySelectorAll("#upComingFixtureList .kickoffTime");
    let earliestTime = null;
    elements.forEach(el => {
        const dateTime = new Date(el.textContent.trim().replace(" ", "T"));
        if (!earliestTime || dateTime < earliestTime) {
            earliestTime = dateTime;
        }
    });
    return earliestTime;
}

function updateCountdown() {
    const countdownSpan = document.getElementById("countdown_days_hours_min");
    if (!countdownSpan) return;
    const earliestTime = findEarliestKickoff();
    if (!earliestTime) {
        countdownSpan.textContent = "No info on next match kickoff time is available";
        return;
    }
    function tick() {
        const now = new Date();
        const diff = earliestTime - now;
        if (diff <= 0) {
            countdownSpan.textContent = "Deadline passed";
            clearInterval(interval);
            return;
        }
        const days = Math.floor(diff / (1000 * 60 * 60 * 24));
        const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((diff % (1000 * 60)) / 1000);
        countdownSpan.textContent = `Deadline in ${days} Days, ${hours} Hours, ${minutes} Minutes ${seconds} seconds`;
    }
    tick();
    const interval = setInterval(tick, 1000);
}
