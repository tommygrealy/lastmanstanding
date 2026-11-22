import sqlite3
import unittest
from datetime import datetime
from unittest.mock import patch

import app
import dal


NOW = datetime(2026, 11, 22, 18)

sqlite3.register_adapter(datetime, lambda value: value.isoformat(" "))
sqlite3.register_converter("TIMESTAMP", lambda value: datetime.fromisoformat(value.decode()))


class Clock(datetime):
    @classmethod
    def now(cls, tz=None):
        return NOW


class Cursor:
    def __init__(self, connection):
        self.cursor = connection.cursor()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.cursor.close()

    def execute(self, sql, params=()):
        self.cursor.execute(sql.replace("%s", "?"), params)

    def fetchone(self):
        row = self.cursor.fetchone()
        return dict(row) if row else None

    def fetchall(self):
        return [dict(row) for row in self.cursor.fetchall()]

    @property
    def lastrowid(self):
        return self.cursor.lastrowid


class Connection:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        return self

    def __exit__(self, *args):
        pass

    def cursor(self):
        return Cursor(self.connection)

    def commit(self):
        self.connection.commit()


class AutoPickTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:", detect_types=sqlite3.PARSE_DECLTYPES)
        self.db.row_factory = sqlite3.Row
        self.db.create_function("NOW", 0, lambda: str(NOW))
        self.db.create_function("RAND", 0, lambda: 0.5)
        self.db.executescript("""
            CREATE TABLE gameweekmap (GameWeek INTEGER, DateFrom TIMESTAMP, DateTo TIMESTAMP);
            CREATE TABLE clubs (ClubId INTEGER, LongName TEXT, MedName TEXT, ShortName TEXT);
            CREATE TABLE fixtureresults (FixtureId INTEGER, KickOffTime TIMESTAMP,
                                         HomeTeam TEXT, AwayTeam TEXT);
            CREATE TABLE users (username TEXT, FullName TEXT, email TEXT,
                                PaymentStatus TEXT, CompStatus TEXT);
            CREATE TABLE predictions (PredictionID INTEGER PRIMARY KEY, DateTimeEntered TIMESTAMP,
                                      EntryType TEXT, FixtureID INTEGER, GameWeek INTEGER,
                                      UserName TEXT, TeamName TEXT, PredictionStatus TEXT,
                                      PredictedResult INTEGER, UNIQUE (GameWeek, UserName));
            INSERT INTO gameweekmap VALUES
                (1, '2026-11-22 12:00:00', '2026-11-23 00:00:00'),
                (2, '2026-11-24 12:00:00', '2026-11-25 00:00:00');
            INSERT INTO clubs VALUES
                (1, 'Used Team', 'Used', 'U'), (2, 'Eligible Team', 'Eligible', 'E'),
                (3, 'Next Week Team', 'Next Week', 'N');
            INSERT INTO fixtureresults VALUES
                (10, '2026-11-22 14:00:00', 'Used Team', ' Eligible Team '),
                (20, '2026-11-24 14:00:00', 'Next Week Team', 'Other');
            INSERT INTO users VALUES
                ('player', 'Player', 'player@example.test', 'Paid', 'Playing'),
                ('unpaid', 'Unpaid', 'unpaid@example.test', 'Pending', 'Playing');
            INSERT INTO predictions (EntryType, FixtureID, GameWeek, UserName, TeamName,
                                     PredictionStatus, PredictedResult)
                VALUES ('MANUAL', 5, 0, 'player', 'Used', 'A', 1);
        """)
        self.db_patcher = patch.object(dal, "get_connection", side_effect=lambda: Connection(self.db))
        self.clock_patcher = patch.object(dal, "datetime", Clock)
        self.db_patcher.start()
        self.clock_patcher.start()
        self.addCleanup(self.db_patcher.stop)
        self.addCleanup(self.clock_patcher.stop)
        self.addCleanup(self.db.close)
        self.app = app.create_app()
        self.app.config["TESTING"] = True
        self.client = self.app.test_client()

    def login(self, privilege):
        user = {"id": 1, "username": "admin", "email": "admin@example.test",
                "PrivLevel": privilege}
        patcher = patch.object(dal, "get_user_by_id", return_value=user)
        patcher.start()
        self.addCleanup(patcher.stop)
        with self.client.session_transaction() as session:
            session["_user_id"] = "1"
            session["_fresh"] = True

    def test_admin_can_pick_past_fixture_after_deadline_in_active_week(self):
        self.login(3)
        response = self.client.post("/api/run-auto-picks").get_json()
        self.assertEqual(response["status"], 1)
        prediction = self.db.execute(
            "SELECT EntryType, FixtureID, GameWeek, UserName, TeamName, PredictedResult "
            "FROM predictions WHERE GameWeek = 1"
        ).fetchone()
        self.assertEqual(tuple(prediction), ("AUTO", 10, 1, "player", " Eligible Team ", 3))
        self.assertEqual(dal.get_lazy_users(), [])
        self.assertEqual(self.client.post("/api/run-auto-picks").get_json()["status"], 0)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM predictions").fetchone()[0], 2)

    def test_manual_prediction_still_blocked_after_deadline(self):
        result = dal.submit_user_prediction(10, "player", 3, "MANUAL")
        self.assertEqual(result, {"ok": False, "error": "deadline passed"})

    def test_manual_prediction_still_allowed_before_deadline(self):
        self.db.execute("UPDATE gameweekmap SET DateFrom = '2026-11-22 19:00:00' WHERE GameWeek = 1")
        result = dal.submit_user_prediction(10, "player", 3, "MANUAL")
        self.assertTrue(result["ok"])

    def test_non_admin_cannot_run_auto_picks(self):
        self.login(1)
        self.assertEqual(self.client.post("/api/run-auto-picks").status_code, 403)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM predictions").fetchone()[0], 1)

    def test_no_eligible_fixture_reports_failure_without_using_next_week(self):
        self.db.execute("DELETE FROM fixtureresults WHERE FixtureId = 10")
        self.login(3)
        response = self.client.post("/api/run-auto-picks").get_json()
        self.assertEqual(response["status"], 0)
        self.assertIn("player: no available team", response["reason"])
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM predictions").fetchone()[0], 1)

    def test_auto_pick_rejects_fixture_outside_active_week(self):
        result = dal.submit_user_prediction(20, "player", 1, "AUTO", allow_after_deadline=True)
        self.assertEqual(result, {"ok": False, "error": "Fixture is not in the active game week"})

    def test_submission_failures_are_reported(self):
        self.login(3)
        with patch.object(dal, "submit_user_prediction",
                          return_value={"ok": False, "error": "database rejected pick"}):
            response = self.client.post("/api/run-auto-picks").get_json()
        self.assertEqual(response["status"], 0)
        self.assertIn("player: database rejected pick", response["reason"])

    def test_partial_failures_report_successes_and_failed_users(self):
        self.db.execute(
            "INSERT INTO users VALUES ('other', 'Other', 'other@example.test', 'Paid', 'Playing')"
        )
        self.login(3)
        submit = dal.submit_user_prediction

        def submit_with_failure(fixture_id, username, *args, **kwargs):
            if username == "other":
                return {"ok": False, "error": "database rejected pick"}
            return submit(fixture_id, username, *args, **kwargs)

        with patch.object(dal, "submit_user_prediction", side_effect=submit_with_failure):
            response = self.client.post("/api/run-auto-picks").get_json()
        self.assertEqual(response["status"], 0)
        self.assertEqual(len(response["completed"]), 1)
        self.assertIn("other: database rejected pick", response["reason"])

    def test_no_active_gameweek_is_reported(self):
        self.db.execute("DELETE FROM gameweekmap")
        self.login(3)
        response = self.client.post("/api/run-auto-picks").get_json()
        self.assertEqual(response["reason"], "No active game week found")
        self.assertEqual(dal.get_lazy_users(), [])


if __name__ == "__main__":
    unittest.main()
