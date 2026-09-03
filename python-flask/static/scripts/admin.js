(function () {
    const state = {
        allLeagueIds: []
    };

    function postForm(url, payload) {
        return fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: new URLSearchParams(payload),
            credentials: 'same-origin'
        }).then(function (response) {
            return response.json();
        });
    }

    function getJson(url) {
        return fetch(url, { credentials: 'same-origin' }).then(function (response) {
            return response.json();
        });
    }

    function setStatus(elementId, message, tone) {
        const el = document.getElementById(elementId);
        if (!el) return;
        el.textContent = message || '';
        el.className = 'status-text' + (tone ? ' ' + tone : '');
    }

    function clearElement(element) {
        while (element.firstChild) {
            element.removeChild(element.firstChild);
        }
    }

    function createMetaRow(label, value) {
        const row = document.createElement('p');
        row.className = 'admin-meta';

        const strong = document.createElement('strong');
        strong.textContent = label + ': ';
        row.appendChild(strong);
        row.appendChild(document.createTextNode(value || '—'));
        return row;
    }

    function buildSelect(name, currentValue, options) {
        const select = document.createElement('select');
        select.name = name;

        const values = Array.from(new Set([currentValue].concat(options).filter(Boolean)));
        values.forEach(function (value) {
            const option = document.createElement('option');
            option.value = value;
            option.textContent = value;
            if (String(value) === String(currentValue)) option.selected = true;
            select.appendChild(option);
        });

        return select;
    }

    function buildField(label, control, id) {
        const wrapper = document.createElement('label');
        wrapper.className = 'form-field';
        if (id) control.id = id;

        const text = document.createElement('span');
        text.textContent = label;
        wrapper.appendChild(text);
        wrapper.appendChild(control);
        return wrapper;
    }

    function getUserFilters() {
        return {
            league_id: document.getElementById('leagueFilter').value,
            compStatus: document.getElementById('compStatusFilter').value,
            paymentStatus: document.getElementById('paymentStatusFilter').value
        };
    }

    function buildAdminUsersUrl() {
        const params = new URLSearchParams();
        const filters = getUserFilters();
        Object.keys(filters).forEach(function (key) {
            if (filters[key]) params.set(key, filters[key]);
        });
        const query = params.toString();
        return '/api/admin-users' + (query ? '?' + query : '');
    }

    function populateLeagueFilter() {
        const select = document.getElementById('leagueFilter');
        if (!select) return;

        const currentValue = select.value;
        select.innerHTML = '<option value="">All leagues</option>';
        state.allLeagueIds.forEach(function (leagueId) {
            const option = document.createElement('option');
            option.value = String(leagueId);
            option.textContent = 'League ' + leagueId;
            select.appendChild(option);
        });
        select.value = currentValue;
    }

    function renderUsers(users) {
        const host = document.getElementById('adminUsersList');
        if (!host) return;

        clearElement(host);

        if (!users.length) {
            const empty = document.createElement('div');
            empty.className = 'list-row';
            empty.textContent = 'No users match the current filters.';
            host.appendChild(empty);
            return;
        }

        users.forEach(function (user) {
            const form = document.createElement('form');
            form.className = 'admin-user-card';
            form.dataset.userId = user.id;

            const heading = document.createElement('h3');
            heading.textContent = user.FullName || user.username;
            form.appendChild(heading);
            form.appendChild(createMetaRow('Username', user.username));
            form.appendChild(createMetaRow('Email', user.email));

            const fields = document.createElement('div');
            fields.className = 'form-grid';

            const privLevelInput = document.createElement('input');
            privLevelInput.type = 'number';
            privLevelInput.name = 'PrivLevel';
            privLevelInput.min = '1';
            privLevelInput.value = user.PrivLevel ?? 1;

            const leagueInput = document.createElement('input');
            leagueInput.type = 'number';
            leagueInput.name = 'league_id';
            leagueInput.min = '1';
            leagueInput.value = user.league_id ?? '';

            fields.appendChild(buildField('PrivLevel', privLevelInput));
            fields.appendChild(buildField('CompStatus', buildSelect('CompStatus', user.CompStatus, ['Playing', 'Eliminated'])));
            fields.appendChild(buildField('PaymentStatus', buildSelect('PaymentStatus', user.PaymentStatus, ['Paid', 'Pending'])));
            fields.appendChild(buildField('league_id', leagueInput));
            form.appendChild(fields);

            const actions = document.createElement('div');
            actions.className = 'admin-actions';

            const submit = document.createElement('button');
            submit.type = 'submit';
            submit.className = 'lms-btn';
            submit.textContent = 'Save user';
            actions.appendChild(submit);
            form.appendChild(actions);

            form.addEventListener('submit', function (event) {
                event.preventDefault();
                saveUser(form);
            });

            host.appendChild(form);
        });
    }

    function collectLeagueIds(users) {
        state.allLeagueIds = users
            .map(function (user) { return user.league_id; })
            .filter(function (leagueId) { return leagueId !== null && leagueId !== undefined && leagueId !== ''; })
            .sort(function (a, b) { return Number(a) - Number(b); })
            .filter(function (leagueId, index, values) { return index === 0 || String(leagueId) !== String(values[index - 1]); });
        populateLeagueFilter();
    }

    function loadUsers(isInitialLoad) {
        return getJson(buildAdminUsersUrl()).then(function (users) {
            if (isInitialLoad) collectLeagueIds(users);
            renderUsers(users);
            setStatus('usersStatus', users.length + ' user' + (users.length === 1 ? '' : 's') + ' shown.');
        }).catch(function () {
            setStatus('usersStatus', 'Unable to load users.', 'error');
        });
    }

    function saveUser(form) {
        const privLevel = form.querySelector('[name="PrivLevel"]').value.trim();
        const compStatus = form.querySelector('[name="CompStatus"]').value;
        const paymentStatus = form.querySelector('[name="PaymentStatus"]').value;
        const leagueId = form.querySelector('[name="league_id"]').value.trim();

        return postForm('/api/update-user', {
            userId: form.dataset.userId,
            PrivLevel: privLevel,
            CompStatus: compStatus,
            PaymentStatus: paymentStatus,
            league_id: leagueId
        }).then(function (data) {
            if (data.status !== 1) {
                setStatus('usersStatus', data.reason || 'User update failed.', 'error');
                return;
            }

            const filters = getUserFilters();
            const shouldRefreshOptions = !filters.league_id && !filters.compStatus && !filters.paymentStatus;
            return loadUsers(shouldRefreshOptions).then(function () {
                setStatus('usersStatus', 'User updated successfully.', 'success');
            });
        }).catch(function () {
            setStatus('usersStatus', 'User update failed.', 'error');
        });
    }

    function loadPendingResults() {
        const host = document.getElementById('updatePendingList');
        if (!host) return Promise.resolve();

        return getJson('/api/match-results-pending').then(function (fixtures) {
            clearElement(host);

            if (!fixtures.length) {
                setStatus('matchResultsStatus', 'All match scores are up to date.');
                return;
            }

            setStatus('matchResultsStatus', fixtures.length + ' fixture' + (fixtures.length === 1 ? '' : 's') + ' require score updates.');

            fixtures.forEach(function (fixture) {
                const card = document.createElement('form');
                card.className = 'prediction-card';
                card.dataset.fixtureId = fixture.FixtureId;

                const title = document.createElement('h3');
                title.textContent = (fixture.KickOffTime || '').slice(0, 16).replace('T', ' ');
                card.appendChild(title);
                card.appendChild(createMetaRow('Fixture', fixture.HomeTeam + ' vs ' + fixture.AwayTeam));

                const fields = document.createElement('div');
                fields.className = 'form-grid';

                const homeInput = document.createElement('input');
                homeInput.type = 'number';
                homeInput.name = 'homeScore';
                homeInput.min = '0';
                homeInput.required = true;

                const awayInput = document.createElement('input');
                awayInput.type = 'number';
                awayInput.name = 'awayScore';
                awayInput.min = '0';
                awayInput.required = true;

                fields.appendChild(buildField(fixture.HomeTeam + ' score', homeInput));
                fields.appendChild(buildField(fixture.AwayTeam + ' score', awayInput));
                card.appendChild(fields);

                const actions = document.createElement('div');
                actions.className = 'admin-actions';
                const submit = document.createElement('button');
                submit.type = 'submit';
                submit.className = 'lms-btn';
                submit.textContent = 'Save score';
                actions.appendChild(submit);
                card.appendChild(actions);

                card.addEventListener('submit', function (event) {
                    event.preventDefault();
                    updateScore(card);
                });

                host.appendChild(card);
            });
        }).catch(function () {
            setStatus('matchResultsStatus', 'Unable to load pending match results.', 'error');
        });
    }

    function updateScore(form) {
        const homeScore = Number(form.querySelector('[name="homeScore"]').value);
        const awayScore = Number(form.querySelector('[name="awayScore"]').value);

        if (!Number.isInteger(homeScore) || !Number.isInteger(awayScore) || homeScore < 0 || awayScore < 0) {
            setStatus('matchResultsStatus', 'Enter valid home and away scores.', 'error');
            return Promise.resolve();
        }

        let result = 2;
        if (homeScore > awayScore) result = 1;
        if (awayScore > homeScore) result = 3;

        return postForm('/api/submit-match-score', {
            FixtureId: form.dataset.fixtureId,
            homeScore: homeScore,
            awayScore: awayScore,
            result: result
        }).then(function (data) {
            if (data.status !== 1) {
                setStatus('matchResultsStatus', data.reason || 'Score update failed.', 'error');
                return;
            }

            return loadPendingResults().then(function () {
                setStatus('matchResultsStatus', 'Score updated successfully.', 'success');
            });
        }).catch(function () {
            setStatus('matchResultsStatus', 'Score update failed.', 'error');
        });
    }

    function loadNextGameweek() {
        return getJson('/api/next-gameweek').then(function (gameweek) {
            if (!gameweek || !gameweek.GameWeek) {
                setStatus('gameweekStatus', 'No upcoming gameweek found.', 'warning');
                return;
            }

            document.getElementById('gameweekNumber').value = gameweek.GameWeek;
            document.getElementById('gameweekDisplay').value = gameweek.GameWeek;
            document.getElementById('gameweekDateFrom').value = gameweek.DateFrom || '';
            document.getElementById('gameweekDateTo').value = gameweek.DateTo || '';
            setStatus('gameweekStatus', 'Update the next round timings below.');
        }).catch(function () {
            setStatus('gameweekStatus', 'Unable to load the next gameweek.', 'error');
        });
    }

    function saveGameweek(event) {
        event.preventDefault();

        return postForm('/api/update_gameweek', {
            GameWeek: document.getElementById('gameweekNumber').value,
            DateFrom: document.getElementById('gameweekDateFrom').value,
            DateTo: document.getElementById('gameweekDateTo').value
        }).then(function (data) {
            if (data.status !== 1) {
                setStatus('gameweekStatus', data.reason || 'Gameweek update failed.', 'error');
                return;
            }

            return loadNextGameweek().then(function () {
                setStatus('gameweekStatus', 'Next match window updated successfully.', 'success');
            });
        }).catch(function () {
            setStatus('gameweekStatus', 'Gameweek update failed.', 'error');
        });
    }

    function loadUsersNotSubmitted() {
        const host = document.getElementById('usersNotSubmittedList');
        if (!host) return Promise.resolve();

        return getJson('/api/users-not-submitted').then(function (users) {
            clearElement(host);

            if (!users.length) {
                setStatus('usersNotSubmittedStatus', 'All eligible users have submitted.');
                return;
            }

            setStatus('usersNotSubmittedStatus', users.length + ' user' + (users.length === 1 ? '' : 's') + ' still need to submit.');

            users.forEach(function (user) {
                const row = document.createElement('div');
                row.className = 'list-row';
                row.textContent = user.FullName + ' (' + user.username + ')';
                host.appendChild(row);
            });
        }).catch(function () {
            setStatus('usersNotSubmittedStatus', 'Unable to load users not submitted.', 'error');
        });
    }

    function sendReminder() {
        return postForm('/api/send-mail-reminder', {}).then(function (data) {
            setStatus(
                'usersNotSubmittedStatus',
                data.reason || (data.status === 1 ? 'Reminders sent.' : 'Reminder send failed.'),
                data.status === 1 ? 'success' : 'error'
            );
        }).catch(function () {
            setStatus('usersNotSubmittedStatus', 'Reminder send failed.', 'error');
        });
    }

    function runAutoPicks() {
        if (!window.confirm('Run auto-picks for users who have not submitted for the current game week?')) {
            return;
        }

        return postForm('/api/run-auto-picks', {}).then(function (data) {
            setStatus(
                'matchResultsStatus',
                data.reason || (data.status === 1 ? 'Auto-picks completed.' : 'Auto-picks failed.'),
                data.status === 1 ? 'success' : 'error'
            );
            return loadUsersNotSubmitted();
        }).catch(function () {
            setStatus('matchResultsStatus', 'Auto-picks failed.', 'error');
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        loadPendingResults();
        loadUsers(true);
        loadNextGameweek();
        loadUsersNotSubmitted();

        document.getElementById('leagueFilter').addEventListener('change', function () { loadUsers(false); });
        document.getElementById('compStatusFilter').addEventListener('change', function () { loadUsers(false); });
        document.getElementById('paymentStatusFilter').addEventListener('change', function () { loadUsers(false); });

        document.getElementById('resetUserFilters').addEventListener('click', function () {
            document.getElementById('leagueFilter').value = '';
            document.getElementById('compStatusFilter').value = '';
            document.getElementById('paymentStatusFilter').value = '';
            loadUsers(false);
        });

        document.getElementById('gameweekForm').addEventListener('submit', saveGameweek);
        document.getElementById('sendReminderButton').addEventListener('click', sendReminder);
        document.getElementById('btnExecuteAutoPick').addEventListener('click', runAutoPicks);
    });
}());
