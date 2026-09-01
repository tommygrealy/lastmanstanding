(function () {
    const state = {
        selection: null,
        dynamiteTargetUser: '',
        dynamiteTargetFullName: '',
        userDynamiteId: null,
        userDynamiteUpdatedAt: null,
        currentUsername: window.lmsCurrentUser || ''
    };

    function postForm(url, payload) {
        return fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: new URLSearchParams(payload)
        }).then(r => r.json());
    }

    function getJson(url) {
        return fetch(url, { credentials: 'same-origin' }).then(r => r.json());
    }

    function showModal(modalId) {
        const backdrop = document.querySelector('[data-modal-backdrop]');
        const modal = document.getElementById(modalId);
        if (!backdrop || !modal) return;
        backdrop.classList.remove('hidden');
        modal.classList.remove('hidden');
    }

    function closeModal(modalId) {
        const modal = document.getElementById(modalId);
        if (!modal) return;
        modal.classList.add('hidden');
        const backdrop = document.querySelector('[data-modal-backdrop]');
        if (backdrop && [...document.querySelectorAll('.modal')].every(m => m.classList.contains('hidden'))) {
            backdrop.classList.add('hidden');
        }
    }

    function showNotice(title, body, buttonText, onConfirm) {
        const noticeTitle = document.getElementById('noticeTitle');
        const noticeBody = document.getElementById('noticeBody');
        const btn = document.getElementById('noticeConfirm');
        if (!noticeTitle || !noticeBody || !btn) return;
        noticeTitle.textContent = title;
        noticeBody.textContent = body;
        btn.textContent = buttonText || 'OK';
        btn.onclick = function () {
            closeModal('noticeModal');
            if (onConfirm) onConfirm();
        };
        showModal('noticeModal');
    }

    function formatDateTime(dateTimeString) {
        const date = new Date(String(dateTimeString).replace(' ', 'T'));
        if (Number.isNaN(date.getTime())) return dateTimeString;
        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const dayName = days[date.getDay()];
        let hours = date.getHours();
        const period = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12 || 12;
        const minutes = date.getMinutes().toString().padStart(2, '0');
        const formattedTime = minutes === '00' ? `${hours}${period}` : `${hours}:${minutes}${period}`;
        return `${dayName} at ${formattedTime}`;
    }

    function renderFixtureCard(fixture, previouslySelected, formGuide) {
        const wrap = document.createElement('article');
        wrap.className = 'fixture-card';

        const kickoff = document.createElement('div');
        kickoff.className = 'kickoffTime';
        kickoff.textContent = (fixture.KickOffTime || '').slice(0, -3);

        const matchup = document.createElement('div');
        matchup.textContent = `${fixture.HomeTeam} vs ${fixture.AwayTeam}`;

        const actions = document.createElement('div');
        actions.className = 'fixture-actions';

        const createPickButton = (teamName, selected, opponent, killerSelected) => {
            const btn = document.createElement('button');
            const available = !previouslySelected.includes(teamName);
            btn.className = 'lms-btn';
            if (!available) btn.classList.add('unavailable');
            const form = (formGuide[teamName] || '')
                .replaceAll('WIN,', ' 🟢')
                .replaceAll('LOS,', ' 🔴')
                .replaceAll('DRW,', ' 🟡');
            const killerFlag = (selected === 1 && killerSelected === 1) || (selected === 3 && killerSelected === 3) ? ' 🧨' : '';
            btn.textContent = `${killerFlag} ${teamName}${form}`;
            btn.addEventListener('click', function () {
                updateSelection(fixture.FixtureId, fixture.HomeTeam, fixture.AwayTeam, selected, killerSelected);
            });
            return btn;
        };

        const killerSelected = Number(fixture.KillerTeam || 0);
        actions.appendChild(createPickButton(fixture.HomeTeam, 1, fixture.AwayTeam, killerSelected));
        actions.appendChild(createPickButton(fixture.AwayTeam, 3, fixture.HomeTeam, killerSelected));

        wrap.appendChild(kickoff);
        wrap.appendChild(matchup);
        wrap.appendChild(actions);
        return wrap;
    }

    function updateSelection(fixId, homeTeam, awayTeam, selected, killer) {
        const selectedTeamMsg = document.getElementById('csTeamWin');
        const submitNowBtn = document.getElementById('submitNow');
        const submitCancelBtn = document.getElementById('submitCancel');
        if (!selectedTeamMsg || !submitNowBtn || !submitCancelBtn) return;
        state.selection = { fixId, selected };
        const killerTeamMsg = ' Select this team this week and if they win, you can remove a life from another player.';
        let msg = '';

        if (selected === 1) {
            msg = `${homeTeam} (home) to beat ${awayTeam}`;
            if (killer === 1) msg += killerTeamMsg;
        }
        if (selected === 3) {
            msg = `${awayTeam} (away) to beat ${homeTeam}`;
            if (killer === 3) msg += killerTeamMsg;
        }

        selectedTeamMsg.textContent = msg;
        submitNowBtn.classList.remove('hidden');
        submitCancelBtn.textContent = 'Cancel';
        showModal('selectionModal');
    }

    function showAlreadyPlayed(selectionData) {
        if (!selectionData || !selectionData[0]) return;
        const p = selectionData[0];
        const host = document.getElementById('alreadyPredictedDetails');
        const messageInformSelect = document.getElementById('messageInformSelect');
        const upComingFixtureList = document.getElementById('upComingFixtureList');
        if (!host || !messageInformSelect || !upComingFixtureList) return;
        host.innerHTML = '';

        const row = document.createElement('div');
        row.className = 'panel';
        row.innerHTML = `<h3>Your prediction for this round has been submitted</h3>
            <p>Fixture: ${p.HomeTeam} v ${p.AwayTeam}<br>You selected: ${p.PredictedTeam}</p>`;

        const btn = document.createElement('button');
        btn.className = 'lms-btn';
        btn.textContent = 'Cancel this prediction';
        btn.addEventListener('click', function () {
            cancelPrediction(p.PredictionID);
        });

        row.appendChild(btn);
        host.appendChild(row);

        messageInformSelect.textContent = '';
        upComingFixtureList.innerHTML = '';
    }

    function cancelPrediction(predictionId) {
        if (!window.confirm('Are you sure you want to cancel this prediction?')) return;
        postForm('/api/cancel-prediction', { predictionId: predictionId }).then(data => {
            if (data.ROWS_AFFECTED === 1) {
                document.getElementById('alreadyPredictedDetails').innerHTML = '';
                loadUserOpts();
            }
        });
    }

    function makeSubmission() {
        if (!state.selection) return;
        postForm('/api/submit-prediction', {
            FixtureId: state.selection.fixId,
            prediction: state.selection.selected
        }).then(function (data) {
            if (data.status === 1) {
                document.getElementById('csTeamWin').textContent = 'Your prediction for this week has been submitted. Good luck!';
                document.getElementById('submitNow').classList.add('hidden');
                document.getElementById('submitCancel').textContent = 'Close';
                loadUserOpts();
            } else {
                let msg = 'Cannot submit this prediction.';
                if (data.reason === 'Payment Pending') msg = 'Pay Tommy first - Revolut €10 to @tommy5kit';
                if (data.reason === 'eliminated from comp') msg = 'You have been eliminated from the competition';
                if (Array.isArray(data.reason) && data.reason[0] && data.reason[0].endsWith("ey 'UserTeam'")) {
                    msg = 'You have already selected this team in a previous round of the competition';
                }
                if (Array.isArray(data.reason) && data.reason[0] && data.reason[0].endsWith("UserGameWeek'")) {
                    msg = 'You have already submitted a prediction for this game week';
                }
                document.getElementById('csTeamWin').textContent = msg;
            }
        });
    }

    function findEarliestKickoff() {
        const elements = document.querySelectorAll('#upComingFixtureList .kickoffTime');
        let earliest = null;
        elements.forEach(el => {
            const d = new Date(el.textContent.trim().replace(' ', 'T'));
            if (!Number.isNaN(d.getTime()) && (!earliest || d < earliest)) earliest = d;
        });
        return earliest;
    }

    function updateCountdown() {
        const countdownSpan = document.getElementById('countdown_days_hours_min');
        if (!countdownSpan) return;
        const earliestTime = findEarliestKickoff();
        if (!earliestTime) {
            countdownSpan.textContent = 'No info on next match kickoff time is available';
            return;
        }

        function tick() {
            const diff = earliestTime - new Date();
            if (diff <= 0) {
                countdownSpan.textContent = 'Deadline passed';
                return;
            }
            const days = Math.floor(diff / (1000 * 60 * 60 * 24));
            const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
            const seconds = Math.floor((diff % (1000 * 60)) / 1000);
            countdownSpan.textContent = `Deadline in ${days} Days, ${hours} Hours, ${minutes} Minutes ${seconds} seconds`;
        }

        tick();
        setInterval(tick, 1000);
    }

    function loadUserOpts() {
        getJson('/api/user-selection-options').then(function (json) {
            if (json.userstatus) {
                state.currentUsername = json.userstatus.username || state.currentUsername;
                if (json.userstatus.CompStatus === 'Eliminated') {
                    showNotice('Player Eliminated', 'You have been eliminated.', 'My Predictions', function () {
                        showPlayerHist(state.currentUsername);
                    });
                }
                if (json.userstatus.PaymentStatus === 'Pending') {
                    showNotice('Payment Due', 'Entry fee needs to be paid before playing', 'Go to Payment', function () {
                        location.assign('/home2/payment');
                    });
                }
            }

            const fixtureHost = document.getElementById('upComingFixtureList');
            const alreadyPredictedDetails = document.getElementById('alreadyPredictedDetails');
            const messageInformSelect = document.getElementById('messageInformSelect');
            if (!fixtureHost || !alreadyPredictedDetails || !messageInformSelect) return;
            fixtureHost.innerHTML = '';
            alreadyPredictedDetails.innerHTML = '';

            if (json.fixtures) {
                messageInformSelect.innerHTML = 'Please select one match winner from the list of fixtures below';
                const previouslySelected = json.previouslySelected || [];
                const formGuide = json.formguide || {};
                json.fixtures.forEach(f => fixtureHost.appendChild(renderFixtureCard(f, previouslySelected, formGuide)));
                updateCountdown();
            } else {
                showAlreadyPlayed(json);
            }
        });
    }

    function displaySelectionsPostDeadline() {
        const label = document.getElementById('publicSelectionsListLabel');
        const host = document.getElementById('publicSelectionsList');
        const messageInformSelect = document.getElementById('messageInformSelect');
        if (!label || !host || !messageInformSelect) return;
        getJson('/api/selections-post-deadline').then(function (json) {
            if (!json || json.length === 0) return;
            host.innerHTML = '';

            if (json[0].TIME_PUBLIC) {
                label.textContent = "This week's predictions will appear here after the deadline";
                return;
            }

            label.textContent = "This week's predictions:";
            messageInformSelect.textContent = 'Submission deadline for the current game week has passed';

            json.forEach(function (value) {
                const row = document.createElement('div');
                row.className = 'list-row';
                const methodText = value.EntryType === 'AUTO' ? 'Auto-Pick*: ' : 'Selected: ';
                let dynamite = '';
                if (value.KillerTeam !== null) {
                    if (value.PredictedTeam === value.HomeTeam && value.KillerTeam === 1) dynamite = ' 🧨';
                    if (value.PredictedTeam === value.AwayTeam && value.KillerTeam === 3) dynamite = ' 🧨';
                }
                row.innerHTML = `<strong>Player:</strong> ${value.FullName}<br>${value.HomeTeam} vs ${value.AwayTeam} - ${formatDateTime(value.KickOffTime)}<br>${methodText}<strong>${value.PredictedTeam}${dynamite}</strong>`;
                host.appendChild(row);
            });
        });
    }

    function displayPlayerStandings() {
        const host = document.getElementById('playerStandingsList');
        if (!host) return;
        getJson('/api/user-standings').then(function (rows) {
            host.innerHTML = '';
            rows.forEach(function (value) {
                const livesLost = 3 - value.lives;
                const balls = '⚽ '.repeat(value.lives) + '❌ '.repeat(livesLost);
                const btn = document.createElement('button');
                btn.className = 'clickable-row';
                const cls = value.CompStatus === 'Playing' ? 'active-player' : 'elim-player';
                btn.innerHTML = `<span class="${cls}">${balls}${value.FullName}</span>`;
                btn.addEventListener('click', function () { showPlayerHist(value.username); });
                host.appendChild(btn);
            });
        });
    }

    function showPlayerHist(username) {
        const host = document.getElementById('userHistoryList');
        const historyTitle = document.getElementById('historyTitle');
        if (!host || !historyTitle) return;
        getJson('/api/user-prediction-history?player=' + encodeURIComponent(username)).then(function (rows) {
            host.innerHTML = '';
            historyTitle.textContent = `History for ${username}`;

            rows.forEach(function (value) {
                const card = document.createElement('div');
                card.className = 'prediction-card';
                let result = '<span style="color:orange;font-weight:bold;">Pending</span>';
                if (value.PredictionCorrect === 1) result = '<span style="color:#87f89f;font-weight:bold;">Win</span>';
                if (value.PredictionCorrect === 0) result = '<span style="color:#ffc4c4;font-weight:bold;">Lose</span>';
                const date = new Date(value.KickOffTime).toISOString().split('T')[0];
                card.innerHTML = `<strong>${date} — ${value.HomeTeam} vs ${value.AwayTeam}</strong><br>${username} predicted ${value.PredictedWinner} to win.<br>${result}`;
                host.appendChild(card);
            });

            showModal('historyModal');
        });
    }

    function showDynamiteHist() {
        const host = document.getElementById('dynamiteActionsList');
        if (!host) return;
        getJson('/api/dynamite-history').then(function (rows) {
            host.innerHTML = '';
            rows.forEach(function (value) {
                const row = document.createElement('div');
                row.className = 'list-row';
                row.textContent = `On ${value.updated_at}, ${value.SourceFullName} threw 🧨 at ${value.TargetFullName}`;
                host.appendChild(row);
            });
        });
    }

    function displayPlayersForDynamite() {
        const host = document.getElementById('player-tile-targets');
        const dynamiteAction = document.getElementById('dynamiteAction');
        if (!host || !dynamiteAction) return;
        getJson('/api/user-standings').then(function (rows) {
            host.innerHTML = '';
            rows.forEach(function (value) {
                const livesLost = 3 - value.lives;
                const balls = '⚽ '.repeat(value.lives) + '❌ '.repeat(livesLost);
                const btn = document.createElement('button');
                btn.className = value.CompStatus === 'Playing' ? 'drop-target clickable-row' : 'gone-target clickable-row';
                btn.disabled = value.CompStatus !== 'Playing';
                btn.innerHTML = `${value.FullName}<br>${balls}`;
                btn.addEventListener('click', function () {
                    state.dynamiteTargetFullName = value.FullName;
                    state.dynamiteTargetUser = value.username;
                    dynamiteAction.textContent = `Drop 🧨 on ${state.dynamiteTargetFullName}?`;
                    showModal('dynamiteModal');
                });
                host.appendChild(btn);
            });
        });
    }

    function dropDynamite() {
        if (!state.userDynamiteId || !state.dynamiteTargetUser) return;
        postForm('/api/drop-dynamite', {
            user_last_update: state.userDynamiteUpdatedAt,
            drop_on_user: state.dynamiteTargetUser,
            dynamite_id: state.userDynamiteId
        }).then(function (data) {
            let msg = '';
            let btnText = 'Continue';
            let onConfirm = function () {
                closeModal('dynamiteModal');
                location.assign('/home2/standings');
            };

            if (data.reason === 'stale data') {
                msg = 'Cannot drop now as another user has recently dropped dynamite; continue to refresh page.';
                onConfirm = function () { location.reload(); };
            } else if (data.reason && data.reason.lives_remaining < 1) {
                msg = `${data.reason.player_hit} is out.. good job!`;
            } else if (data.reason && typeof data.reason === 'object') {
                msg = `You took a life from ${state.dynamiteTargetFullName}, they now have ${data.reason.lives_remaining} lives`;
            }

            closeModal('dynamiteModal');
            showNotice('Dynamite', msg, btnText, onConfirm);
        });
    }

    function loadDynamiteOptions() {
        const noDynamiteMsg = document.getElementById('no-dynamite-msg');
        const dynamiteDropOptions = document.getElementById('dynamite-drop-options');
        if (!noDynamiteMsg || !dynamiteDropOptions) return;
        getJson('/api/dynamite-options').then(function (rows) {
            if (rows.length > 0 && rows[0].status === 1) {
                state.userDynamiteUpdatedAt = rows[0].updated_at;
                state.userDynamiteId = rows[0].dynamite_id;
                noDynamiteMsg.classList.add('hidden');
                dynamiteDropOptions.classList.remove('hidden');
                displayPlayersForDynamite();
            }
        });
    }

    function setupStandingsFilter() {
        const filter = document.getElementById('standingsFilter');
        if (!filter) return;
        filter.addEventListener('input', function () {
            const term = filter.value.toLowerCase();
            document.querySelectorAll('#playerStandingsList .clickable-row').forEach(function (row) {
                row.classList.toggle('hidden', !row.textContent.toLowerCase().includes(term));
            });
        });
    }

    function wireEvents() {
        const submitNow = document.getElementById('submitNow');
        const submitCancel = document.getElementById('submitCancel');
        const historyClose = document.getElementById('historyClose');
        const submitDynamiteNow = document.getElementById('submitDynamiteNow');
        const submitDynamiteCancel = document.getElementById('submitDynamiteCancel');
        const backdrop = document.querySelector('[data-modal-backdrop]');

        if (submitNow) submitNow.addEventListener('click', makeSubmission);
        if (submitCancel) submitCancel.addEventListener('click', function () { closeModal('selectionModal'); });
        if (historyClose) historyClose.addEventListener('click', function () { closeModal('historyModal'); });
        if (submitDynamiteNow) submitDynamiteNow.addEventListener('click', dropDynamite);
        if (submitDynamiteCancel) submitDynamiteCancel.addEventListener('click', function () { closeModal('dynamiteModal'); });
        if (backdrop) backdrop.addEventListener('click', function () {
            ['selectionModal', 'noticeModal', 'historyModal', 'dynamiteModal'].forEach(closeModal);
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        wireEvents();
        setupStandingsFilter();
        loadUserOpts();
        displaySelectionsPostDeadline();
        displayPlayerStandings();
        loadDynamiteOptions();
        showDynamiteHist();
    });
})();
