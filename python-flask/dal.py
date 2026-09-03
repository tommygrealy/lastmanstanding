"""
Data Access Layer for Last Man Standing.

Key improvements over the PHP version:
- All team-name joins use LOWER(TRIM(...)) to be case- and whitespace-insensitive,
  eliminating the fragile exact-string-match joins in the original SQL views.
- Uses parameterised queries throughout to prevent SQL injection.
- Available-teams exclusion is done via a ClubId sub-query so that a prediction
  recorded under either the LongName or the MedName correctly blocks the team.
- Passwords for new accounts use Werkzeug's PBKDF2-SHA256 algorithm (via
  werkzeug.security).  Existing accounts still use the legacy SHA-256 + 65 536-
  round KDF stored in the ``password`` / ``salt`` columns; they are upgraded
  transparently on next login (upgrade-on-login pattern).
"""

import hashlib
import os
import secrets
from datetime import datetime

import pymysql
import pymysql.cursors
from werkzeug.security import check_password_hash as wz_check
from werkzeug.security import generate_password_hash as wz_generate


def _get_db_config():
    return {
        "host": os.environ.get("LMS_DB_HOST", "localhost"),
        "user": os.environ.get("LMS_DB_USER", "lms"),
        "password": os.environ.get("LMS_DB_PASSWORD", ""),
        "database": os.environ.get("LMS_DB_NAME", "lastmanstanding"),
        "cursorclass": pymysql.cursors.DictCursor,
        "charset": "utf8mb4",
        "autocommit": False,
    }


def get_connection():
    """Return a new PyMySQL connection."""
    return pymysql.connect(**_get_db_config())


def get_active_gameweek() -> dict | None:
    sql = """
        SELECT GameWeek, DateFrom, DateTo
        FROM gameweekmap
        WHERE DateTo > NOW()
        ORDER BY DateTo ASC
        LIMIT 1
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchone()


# ---------------------------------------------------------------------------
# Password helpers
# ---------------------------------------------------------------------------

# NOTE — legacy SHA-256 KDF
# The existing database stores passwords hashed with SHA-256 + a custom
# 65 536-round KDF (as implemented by the original PHP code).  This is weaker
# than a modern algorithm such as bcrypt / Argon2.  New passwords are hashed
# with Werkzeug's PBKDF2-SHA256 (stored with no legacy salt column value).
# Existing users are upgraded transparently on their next successful login.

def _is_legacy_hash(stored_hash: str) -> bool:
    """Return True for old SHA-256 hex hashes (64 lower-hex chars)."""
    return len(stored_hash) == 64 and all(c in "0123456789abcdef" for c in stored_hash)


def hash_password_legacy(password: str, salt: str) -> str:
    """Reproduce the PHP SHA-256 + 65536-round KDF used for existing passwords.

    NOTE: This intentionally uses SHA-256 only to *verify* passwords already
    stored in the database.  New passwords are never hashed this way — see
    hash_password_modern().  The lgtm suppression below acknowledges this.
    """
    # lgtm[py/weak-sensitive-data-hashing]
    h = hashlib.sha256((password + salt).encode()).hexdigest()
    for _ in range(65536):
        h = hashlib.sha256((h + salt).encode()).hexdigest()  # lgtm[py/weak-sensitive-data-hashing]
    return h


def generate_salt() -> str:
    """Return a 16-character hex salt (matches PHP dechex output length)."""
    return secrets.token_hex(8)  # 16 hex chars


def hash_password_modern(password: str) -> str:
    """Hash a password with Werkzeug PBKDF2-SHA256."""
    return wz_generate(password)


def verify_password(password: str, stored_hash: str, salt: str) -> bool:
    """
    Verify a password against either a legacy SHA-256 hash or a modern
    Werkzeug hash.  Returns True on match, False otherwise.
    """
    if _is_legacy_hash(stored_hash):
        return hash_password_legacy(password, salt) == stored_hash
    return wz_check(stored_hash, password)


# ---------------------------------------------------------------------------
# User operations
# ---------------------------------------------------------------------------

def get_user_by_username(username: str) -> dict | None:
    """Return user row joined with league_id, or None."""
    sql = """
        SELECT u.id, u.username, u.FullName, u.password, u.salt,
               u.PrivLevel, u.email, u.CompStatus, u.PaymentStatus,
               u.lives, l.league_id
        FROM users u
        LEFT JOIN league_memberships l ON u.id = l.user_id
        WHERE u.username = %s
        LIMIT 1
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (username,))
            return cur.fetchone()


def get_user_by_id(user_id: int) -> dict | None:
    sql = """
        SELECT u.id, u.username, u.FullName, u.password, u.salt,
               u.PrivLevel, u.email, u.CompStatus, u.PaymentStatus,
               u.lives, l.league_id
        FROM users u
        LEFT JOIN league_memberships l ON u.id = l.user_id
        WHERE u.id = %s
        LIMIT 1
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (user_id,))
            return cur.fetchone()


def username_exists(username: str) -> bool:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM users WHERE username = %s LIMIT 1", (username,))
            return cur.fetchone() is not None


def email_exists(email: str) -> bool:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM users WHERE email = %s LIMIT 1", (email,))
            return cur.fetchone() is not None


def create_user(username: str, full_name: str, email: str,
                password: str, league_id: int) -> int:
    """Insert a new user and league membership; return the new user id."""
    # New users get the modern Werkzeug hash; salt column left blank.
    hashed = hash_password_modern(password)
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """INSERT INTO users (username, FullName, email, password, salt,
                                     PrivLevel, lives, CompStatus, PaymentStatus)
                   VALUES (%s, %s, %s, %s, '', 1, 3, 'Playing', 'Pending')""",
                (username, full_name, email, hashed),
            )
            user_id = cur.lastrowid
            cur.execute(
                "INSERT INTO league_memberships (user_id, league_id) VALUES (%s, %s)",
                (user_id, league_id),
            )
        conn.commit()
    return user_id


def update_user_email(user_id: int, new_email: str) -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE users SET email = %s WHERE id = %s", (new_email, user_id))
        conn.commit()


def update_user_password(user_id: int, new_password: str) -> None:
    hashed = hash_password_modern(new_password)
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE users SET password = %s, salt = '' WHERE id = %s",
                (hashed, user_id),
            )
        conn.commit()


def upgrade_password_to_modern(user_id: int, new_password: str) -> None:
    """Upgrade a legacy SHA-256 password to a modern Werkzeug hash in-place."""
    update_user_password(user_id, new_password)


def update_payment_status(username: str, status: str) -> bool:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE users SET PaymentStatus = %s WHERE username = %s",
                (status, username),
            )
        conn.commit()
        return True


def update_comp_status(username: str, status: str) -> bool:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE users SET CompStatus = %s WHERE username = %s",
                (status, username),
            )
        conn.commit()
        return True


def get_current_standings(league_id: int) -> list[dict]:
    sql = """
        SELECT u.username, u.FullName, u.lives, u.CompStatus
        FROM users u
        JOIN league_memberships lm ON u.id = lm.user_id
        WHERE u.PaymentStatus = 'Paid'
          AND lm.league_id = %s
        ORDER BY u.lives DESC, u.FullName
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (league_id,))
            return cur.fetchall()


def get_playing_users_not_paid() -> list[dict]:
    """Users whose CompStatus is Playing but have not paid."""
    sql = """
        SELECT u.username, u.FullName, u.email
        FROM users u
        WHERE u.PaymentStatus != 'Paid'
          AND u.CompStatus = 'Playing'
        ORDER BY u.FullName
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchall()


def get_lazy_users() -> list[dict]:
    """Users who have not yet submitted a prediction for the current game week."""
    sql = """
        SELECT u.email AS Email, u.FullName, u.username
        FROM users u
        WHERE u.PaymentStatus = 'Paid'
          AND u.CompStatus = 'Playing'
          AND u.username NOT IN (
              SELECT p.UserName
              FROM predictions p
              WHERE p.GameWeek = (
                  SELECT gw.GameWeek FROM gameweekmap gw
                  WHERE gw.DateTo > NOW()
                  ORDER BY gw.DateTo ASC
                  LIMIT 1
              )
              AND p.PredictionStatus = 'A'
          )
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchall()


# ---------------------------------------------------------------------------
# Fixture operations
# ---------------------------------------------------------------------------

def _fixture_with_club_info_cols() -> str:
    """
    Common SELECT fragment that joins fixtureresults with clubs using
    LOWER(TRIM()) comparisons — fixing the fragile exact-match joins
    in the original allfixturesandclubinfo view.
    """
    return """
        f.FixtureId, f.KickOffTime, f.HomeTeam, f.AwayTeam,
        f.HomeTeamScore, f.AwayTeamScore, f.KillerTeam, f.Result,
        hc.ShortName  AS ShortNameHome,
        hc.MedName    AS MedNameHome,
        hc.CrestURLSmall AS HomeCrestImg,
        ac.ShortName  AS ShortNameAway,
        ac.MedName    AS MedNameAway,
        ac.CrestURLSmall AS AwayCrestImg
    """


def _fixture_club_joins() -> str:
    """
    LEFT JOIN to clubs using case-insensitive, trimmed name matching so that
    minor variations in spacing or capitalisation do not break the lookup.
    """
    return """
        LEFT JOIN clubs hc ON LOWER(TRIM(f.HomeTeam)) = LOWER(TRIM(hc.LongName))
        LEFT JOIN clubs ac ON LOWER(TRIM(f.AwayTeam)) = LOWER(TRIM(ac.LongName))
    """


def get_this_weeks_fixtures() -> list[dict]:
    sql = f"""
        SELECT {_fixture_with_club_info_cols()}
        FROM fixtureresults f
        {_fixture_club_joins()}
        WHERE f.KickOffTime BETWEEN
            (SELECT gw.DateFrom FROM gameweekmap gw WHERE gw.DateTo > NOW() ORDER BY gw.DateTo ASC LIMIT 1)
            AND
            (SELECT gw.DateTo FROM gameweekmap gw WHERE gw.DateTo > NOW() ORDER BY gw.DateTo ASC LIMIT 1)
        ORDER BY f.KickOffTime
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchall()


def get_results_history(lookback: int = 50) -> list[dict]:
    sql = """
        SELECT * FROM (
            SELECT FixtureId, KickOffTime, HomeTeam, AwayTeam,
                   HomeTeamScore, AwayTeamScore, Result
            FROM fixtureresults
            WHERE HomeTeamScore IS NOT NULL
            ORDER BY KickOffTime DESC
            LIMIT %s
        ) AS recent
        ORDER BY KickOffTime ASC
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (lookback,))
            return cur.fetchall()


def get_fixtures_with_null_result() -> list[dict]:
    """All past fixtures that have no result entered yet."""
    sql = """
        SELECT FixtureId, KickOffTime, HomeTeam, AwayTeam
        FROM fixtureresults
        WHERE Result IS NULL AND KickOffTime < NOW()
        ORDER BY KickOffTime DESC
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchall()


def submit_match_result(fixture_id: int, home_score: int,
                        away_score: int, result: int) -> bool:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """UPDATE fixtureresults
                   SET HomeTeamScore = %s, AwayTeamScore = %s, Result = %s
                   WHERE FixtureId = %s""",
                (home_score, away_score, result, fixture_id),
            )
        conn.commit()
        return True


def get_next_fixture_for_team(team_long_name: str) -> dict | None:
    """
    Return the next upcoming fixture involving the given team.
    Uses LOWER(TRIM()) on both sides for robust matching.
    """
    sql = """
        SELECT FixtureId, KickOffTime, HomeTeam, AwayTeam
        FROM fixtureresults
        WHERE KickOffTime > NOW()
          AND (LOWER(TRIM(HomeTeam)) = LOWER(TRIM(%s))
               OR LOWER(TRIM(AwayTeam)) = LOWER(TRIM(%s)))
        ORDER BY KickOffTime ASC
        LIMIT 1
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (team_long_name, team_long_name))
            return cur.fetchone()


# ---------------------------------------------------------------------------
# Team / prediction selection
# ---------------------------------------------------------------------------

def get_teams_available_to_user(username: str) -> list[dict]:
    """
    Return clubs not yet used by this user in any previous or current prediction.

    Improvement over PHP: uses a ClubId-based sub-query so that a team recorded
    under LongName or MedName in predictions is correctly excluded, and uses
    LOWER(TRIM()) normalisation to handle name variations.
    """
    sql = """
        SELECT c.ClubId, c.LongName, c.MedName, c.ShortName, c.CrestURLSmall
        FROM clubs c
        WHERE c.ClubId NOT IN (
            SELECT DISTINCT c2.ClubId
            FROM predictions p
            JOIN clubs c2
              ON LOWER(TRIM(p.TeamName)) = LOWER(TRIM(c2.LongName))
              OR LOWER(TRIM(p.TeamName)) = LOWER(TRIM(c2.MedName))
            WHERE p.UserName = %s
        )
        ORDER BY c.LongName
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (username,))
            return cur.fetchall()


def get_user_selection_for_this_week(username: str) -> list[dict]:
    active_gameweek = get_active_gameweek()
    if not active_gameweek or datetime.now() >= active_gameweek["DateFrom"]:
        return []

    sql = f"""
        SELECT {_fixture_with_club_info_cols()},
               p.PredictionID, p.UserName AS username, p.TeamName AS PredictedTeam
        FROM predictions p
        JOIN fixtureresults f ON f.FixtureId = p.FixtureID
        {_fixture_club_joins()}
        WHERE p.UserName = %s
          AND p.GameWeek = %s
          AND p.PredictionStatus = 'A'
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (username, active_gameweek["GameWeek"]))
            return cur.fetchall()

def get_fixture_details(fixture_id: int) -> dict | None:
    sql = f"""
        SELECT {_fixture_with_club_info_cols()}
        FROM fixtureresults f
        {_fixture_club_joins()}
        WHERE f.FixtureId = %s
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (fixture_id,))
            return cur.fetchone()


def get_previously_selected_teams(username: str) -> list[str]:
    """
    Return all team names previously selected by the user.
    """
    sql = "SELECT TeamName FROM predictions WHERE UserName = %s"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (username,))
            return [row["TeamName"] for row in cur.fetchall()]


def submit_user_prediction(fixture_id: int, username: str,
                           predicted_result: int, entry_type: str) -> dict:
    """
    Insert a prediction row. Returns {'ok': True, 'prediction_id': int} on success
    or {'ok': False, 'error': str} on failure.
    """
    get_team_sql = """
        SELECT HomeTeam, AwayTeam FROM fixtureresults WHERE FixtureId = %s
    """
    try:
        active_gameweek = get_active_gameweek()
        if not active_gameweek:
            return {"ok": False, "error": "No active game week found"}
        if datetime.now() >= active_gameweek["DateFrom"]:
            return {"ok": False, "error": "deadline passed"}

        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(get_team_sql, (fixture_id,))
                fixture = cur.fetchone()
                if not fixture:
                    return {"ok": False, "error": "Fixture not found"}

                team_name = fixture["HomeTeam"] if predicted_result == 1 else fixture["AwayTeam"]

                cur.execute(
                    """INSERT INTO predictions
                       (DateTimeEntered, EntryType, FixtureID, GameWeek,
                        UserName, TeamName, PredictionStatus, PredictedResult)
                       VALUES (NOW(), %s, %s, %s, %s, %s, 'A', %s)""",
                    (entry_type, fixture_id, active_gameweek["GameWeek"], username, team_name, predicted_result),
                )
                pred_id = cur.lastrowid
            conn.commit()
        return {"ok": True, "prediction_id": pred_id}
    except pymysql.err.IntegrityError as exc:
        return {"ok": False, "error": str(exc.args[1])}


def cancel_prediction(username: str, prediction_id: int) -> dict:
    """
    Cancel a prediction if before the deadline, moving it to predictionstrash.
    Returns {'ROWS_AFFECTED': 1} on success or {'ROWS_AFFECTED': 0} on failure.
    """
    active_gameweek = get_active_gameweek()
    if not active_gameweek or datetime.now() >= active_gameweek["DateFrom"]:
        return {"ROWS_AFFECTED": 0, "reason": "too late"}

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """INSERT INTO predictionstrash
                   SELECT * FROM predictions
                   WHERE PredictionID = %s AND UserName = %s""",
                (prediction_id, username),
            )
            rows = cur.rowcount
            if rows:
                cur.execute(
                    "DELETE FROM predictions WHERE PredictionID = %s AND UserName = %s",
                    (prediction_id, username),
                )
        conn.commit()
    return {"ROWS_AFFECTED": rows}


def get_user_prediction_history(username: str) -> list[dict]:
    sql = """
        SELECT f.KickOffTime, f.FixtureId, f.HomeTeam, f.AwayTeam,
               f.Result,
               p.PredictionID,
               p.TeamName  AS PredictedWinner,
               p.PredictedResult,
               p.PredictionCorrect
        FROM predictions p
        JOIN fixtureresults f ON f.FixtureId = p.FixtureID
        WHERE p.UserName = %s
          AND f.KickOffTime < NOW()
        ORDER BY f.KickOffTime DESC
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (username,))
            return cur.fetchall()


def get_all_selections_for_this_week() -> list[dict]:
    active_gameweek = get_active_gameweek()
    if not active_gameweek:
        return []

    sql = """
        SELECT f.KickOffTime, f.FixtureId, f.HomeTeam, f.AwayTeam,
               f.Result, p.PredictionID, p.DateTimeEntered,
               p.UserName AS username, p.TeamName AS PredictedTeam
        FROM predictions p
        JOIN fixtureresults f ON f.FixtureId = p.FixtureID
        WHERE p.GameWeek = %s
        ORDER BY p.DateTimeEntered DESC
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (active_gameweek["GameWeek"],))
            return cur.fetchall()


def get_selections_for_gameweek(game_week: int) -> list[dict]:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """SELECT f.KickOffTime, f.FixtureId, f.HomeTeam, f.AwayTeam,
                          f.Result, f.KillerTeam,
                          p.PredictionID, p.UserName AS username,
                          p.TeamName AS PredictedTeam, p.EntryType,
                          u.FullName
                   FROM predictions p
                   JOIN fixtureresults f ON f.FixtureId = p.FixtureID
                   JOIN users u ON p.UserName = u.username
                   WHERE p.GameWeek = %s
                     AND p.PredictionStatus = 'A'
                   ORDER BY p.DateTimeEntered DESC""",
                (game_week,),
            )
            return cur.fetchall()


def get_selections_post_deadline() -> list[dict]:
    """
    Returns selections with full detail once the deadline has passed,
    or a single row with TIME_PUBLIC set to the deadline if still before it.
    """
    active_gameweek = get_active_gameweek()
    if not active_gameweek:
        return []

    if datetime.now() < active_gameweek["DateFrom"]:
        return [{"TIME_PUBLIC": active_gameweek["DateFrom"]}]

    return get_selections_for_gameweek(active_gameweek["GameWeek"])


def get_prediction_details(prediction_id: int) -> dict | None:
    sql = """
        SELECT u.FullName, u.email,
               f.KickOffTime,
               CONCAT(f.HomeTeam, ' vs ', f.AwayTeam) AS FixtureDetail,
               p.TeamName AS `User Selected`,
               p.DateTimeEntered,
               p.PredictionID
        FROM predictions p
        JOIN fixtureresults f ON f.FixtureId = p.FixtureID
        JOIN users u ON p.UserName = u.username
        WHERE p.PredictionID = %s
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (prediction_id,))
            return cur.fetchone()


# ---------------------------------------------------------------------------
# Random team / auto-picks
# ---------------------------------------------------------------------------

def select_random_team_for_user(username: str) -> dict | None:
    """
    Select a random club that the user has not yet used, using ClubId
    matching for robustness (same improvement as get_teams_available_to_user).
    """
    sql = """
        SELECT c.ClubId, c.LongName, c.MedName, c.ShortName
        FROM clubs c
        WHERE c.ClubId NOT IN (
            SELECT DISTINCT c2.ClubId
            FROM predictions p
            JOIN clubs c2
              ON LOWER(TRIM(p.TeamName)) = LOWER(TRIM(c2.LongName))
              OR LOWER(TRIM(p.TeamName)) = LOWER(TRIM(c2.MedName))
            WHERE p.UserName = %s
        )
        ORDER BY RAND()
        LIMIT 1
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (username,))
            return cur.fetchone()


# ---------------------------------------------------------------------------
# Dynamite operations
# ---------------------------------------------------------------------------

def get_dynamite_for_user(user_id: int) -> list[dict]:
    sql = """
        SELECT dynamite_id, granted_to_user_fk, target_user_fk,
               won_in_fixture_id, status, updated_at
        FROM dynamite
        WHERE granted_to_user_fk = %s AND status = 1
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (user_id,))
            return cur.fetchall()


def get_dynamite_last_updated() -> str | None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT updated_at FROM dynamite ORDER BY updated_at DESC LIMIT 1"
            )
            row = cur.fetchone()
            return str(row["updated_at"]) if row else None


def drop_dynamite_on_user(dynamite_id: int, target_username: str) -> int | None:
    """
    Decrement lives for target_username, mark dynamite as used.
    Returns new lives count, or None on failure.
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE users SET lives = lives - 1 WHERE username = %s",
                (target_username,),
            )
            if cur.rowcount == 0:
                return None
            cur.execute("SELECT lives FROM users WHERE username = %s", (target_username,))
            lives = cur.fetchone()["lives"]

            cur.execute(
                """UPDATE dynamite
                   SET target_user_fk = (SELECT id FROM users WHERE username = %s),
                       status = 0
                   WHERE dynamite_id = %s""",
                (target_username, dynamite_id),
            )
        conn.commit()
    return lives


def get_dynamite_drop_history(league_id: int) -> list[dict]:
    sql = """
        SELECT d.updated_at,
               su.FullName AS SourceFullName,
               tu.FullName AS TargetFullName
        FROM dynamite d
        JOIN users su ON d.granted_to_user_fk = su.id
        JOIN users tu ON d.target_user_fk    = tu.id
        WHERE EXISTS (
            SELECT 1
            FROM league_memberships lm
            WHERE lm.user_id = d.granted_to_user_fk
              AND lm.league_id = %s
        )
        AND EXISTS (
            SELECT 1
            FROM league_memberships lm
            WHERE lm.user_id = d.target_user_fk
              AND lm.league_id = %s
        )
        ORDER BY d.updated_at DESC
    """

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (league_id, league_id))
            return cur.fetchall()


# ---------------------------------------------------------------------------
# Password reset tokens
# ---------------------------------------------------------------------------

def create_password_reset_token(username: str, token: str) -> bool:
    sql = """
        INSERT INTO passwordresettokens (username, token, expiry)
        VALUES (%s, %s, DATE_ADD(NOW(), INTERVAL 10 MINUTE))
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (username, token))
        conn.commit()
    return True


def get_username_by_reset_token(token: str) -> str | None:
    sql = """
        SELECT username FROM passwordresettokens
        WHERE token = %s AND expiry > NOW()
        LIMIT 1
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, (token,))
            row = cur.fetchone()
            return row["username"] if row else None


def reset_password_by_token(token: str, new_password: str) -> bool:
    username = get_username_by_reset_token(token)
    if not username:
        return False
    update_user_password_by_username(username, new_password)
    # Invalidate token
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM passwordresettokens WHERE token = %s", (token,))
        conn.commit()
    return True


def update_user_password_by_username(username: str, new_password: str) -> None:
    hashed = hash_password_modern(new_password)
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE users SET password = %s, salt = '' WHERE username = %s",
                (hashed, username),
            )
        conn.commit()
