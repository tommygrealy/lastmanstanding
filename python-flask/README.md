# Last Man Standing — Python Flask

Python Flask rewrite of the PHP web application.

## Structure

```
python-flask/
├── app.py              — Flask application (all routes)
├── dal.py              — Data Access Layer (MySQL queries)
├── email_notifier.py   — Email sending helpers
├── config.py           — Configuration class (env-var driven)
├── requirements.txt    — Python dependencies
├── static/
│   ├── scripts/
│   │   ├── lastmanstanding.js   — Main frontend JS (API URLs updated)
│   │   └── adminFunctions.js    — Admin panel JS
│   └── styles/
│       └── style.css
└── templates/           — Jinja2 HTML templates
    ├── base.html
    ├── base_nologin.html
    ├── login.html
    ├── register.html
    ├── home.html
    ├── admin.html
    ├── forgot_password.html
    ├── reset_password.html
    ├── edit_account.html
    └── includes/
        ├── header.html
        ├── header_admin.html
        ├── header_nologin.html
        ├── footer.html
        └── rules.html
```

## Setup

### 1. Install dependencies

```bash
cd python-flask
pip install -r requirements.txt
```

### 2. Configure environment variables

```bash
export LMS_DB_HOST=localhost
export LMS_DB_USER=lms
export LMS_DB_PASSWORD=your_db_password
export LMS_DB_NAME=lastmanstanding
export LMS_SECRET_KEY=a-long-random-secret-key
export LMS_BASE_URL=https://yourdomain.com
export LMS_SMTP_HOST=localhost
export LMS_SMTP_PORT=25
export LMS_MAIL_FROM=lms@yourdomain.com
```

Or use a `.env` file and load it with `python-dotenv`.

### 3. Run the app

Development:
```bash
flask --app app run --debug
```

Production (with gunicorn):
```bash
gunicorn -w 4 -b 0.0.0.0:8000 app:app
```

## Key improvements over the PHP version

### Fragile team-name joins — fixed

The original PHP app relied on MySQL `allfixturesandclubinfo` and related views
that joined `fixtureresults.HomeTeam` (free-text varchar) to `clubs.LongName`
using **exact string equality**. A single trailing space or inconsistent
capitalisation would silently break the join.

The Python DAL rewrites all such queries to use:

```sql
LEFT JOIN clubs hc ON LOWER(TRIM(f.HomeTeam)) = LOWER(TRIM(hc.LongName))
```

- `LOWER()` makes comparisons case-insensitive.
- `TRIM()` removes leading/trailing whitespace.
- `LEFT JOIN` (instead of `INNER JOIN`) means a fixture still appears even
  if its team name has no exact match in `clubs`; you get `NULL` for club
  metadata rather than a missing row.

The "available teams" exclusion query is also improved: instead of checking
`LongName NOT IN (select TeamName from predictions)` and
`MedName NOT IN (select TeamName from predictions)` as two separate conditions
(which can miss teams stored under one variant but not the other), the Python
version uses a **ClubId-based sub-query**:

```sql
WHERE c.ClubId NOT IN (
    SELECT DISTINCT c2.ClubId FROM predictions p
    JOIN clubs c2
      ON LOWER(TRIM(p.TeamName)) = LOWER(TRIM(c2.LongName))
      OR LOWER(TRIM(p.TeamName)) = LOWER(TRIM(c2.MedName))
    WHERE p.UserName = %s
)
```

This ensures that a prediction stored under any name variant of a club
correctly excludes that entire club.

### Password hashing — backward-compatible

Existing passwords use the PHP SHA-256 + 65 536-round KDF and are supported
for login. New passwords set via the Flask app use the same algorithm to
remain fully compatible with the existing database.

### Session management

Uses `flask-login` for clean, secure session handling instead of raw PHP
`$_SESSION` arrays.

### API endpoint mapping

| Original PHP path | Flask route |
|---|---|
| `restServices/showUserSelectionOptions.php` | `GET /api/user-selection-options` |
| `restServices/submitPredictionSvc.php` | `POST /api/submit-prediction` |
| `restServices/cancelPredictionSvc.php` | `POST /api/cancel-prediction` |
| `restServices/userStandings.php` | `GET /api/user-standings` |
| `restServices/getUserPredictionHistory.php` | `GET /api/user-prediction-history` |
| `restServices/getAllSelections.php` | `GET /api/all-selections` |
| `restServices/getSelectionsPostDeadline.php` | `GET /api/selections-post-deadline` |
| `restServices/showMatchResultsPending.php` | `GET /api/match-results-pending` |
| `restServices/submitMatchScore.php` | `POST /api/submit-match-score` |
| `restServices/getUsersNotPaid.php` | `GET /api/users-not-paid` |
| `restServices/getUsersNotSubmitted.php` | `GET /api/users-not-submitted` |
| `restServices/updateUser.php` | `POST /api/update-user` |
| `restServices/sendMailReminder.php` | `POST /api/send-mail-reminder` |
| `restServices/runAutoPicks.php` | `POST /api/run-auto-picks` |
| `restServices/showUserDynamiteOptions.php` | `GET /api/dynamite-options` |
| `restServices/submitDynamiteDrop.php` | `POST /api/drop-dynamite` |
| `restServices/getDynamiteDropHistory.php` | `GET /api/dynamite-history` |
| `restServices/requestPasswordReset.php` | `POST /api/request-password-reset` |
| `restServices/doPasswordReset.php` | `POST /api/do-password-reset` |
