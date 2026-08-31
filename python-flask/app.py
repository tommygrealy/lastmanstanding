"""
Last Man Standing — Python Flask application.

Replaces the PHP web application. All REST endpoints keep parity with the
original PHP restServices/ paths so that the existing JavaScript frontend
can be adapted with minimal changes.
"""

import os
import secrets

from flask import (
    Flask,
    abort,
    jsonify,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from flask_login import (
    LoginManager,
    UserMixin,
    current_user,
    login_required,
    login_user,
    logout_user,
)

import dal
import email_notifier


# ---------------------------------------------------------------------------
# Application factory
# ---------------------------------------------------------------------------

def create_app() -> Flask:
    app = Flask(__name__)
    app.config["SECRET_KEY"] = os.environ.get("LMS_SECRET_KEY", "change-me-in-production")

    # ----- Flask-Login setup -----
    login_manager = LoginManager(app)
    login_manager.login_view = "login"

    class User(UserMixin):
        def __init__(self, row: dict):
            self.id = row["id"]
            self.username = row["username"]
            self.full_name = row.get("FullName", "")
            self.email = row["email"]
            self.priv_level = row.get("PrivLevel", 1)
            self.comp_status = row.get("CompStatus", "Playing")
            self.payment_status = row.get("PaymentStatus", "Pending")
            self.lives = row.get("lives", 3)
            self.league_id = row.get("league_id")

        def to_dict(self) -> dict:
            return {
                "id": self.id,
                "username": self.username,
                "FullName": self.full_name,
                "email": self.email,
                "PrivLevel": self.priv_level,
                "CompStatus": self.comp_status,
                "PaymentStatus": self.payment_status,
                "lives": self.lives,
                "league_id": self.league_id,
            }

    @login_manager.user_loader
    def load_user(user_id):
        row = dal.get_user_by_id(int(user_id))
        return User(row) if row else None

    # -------------------------------------------------------------------------
    # Page routes
    # -------------------------------------------------------------------------

    @app.route("/")
    def index():
        if current_user.is_authenticated:
            return redirect(url_for("home"))
        return redirect(url_for("login"))

    @app.route("/login", methods=["GET", "POST"])
    def login():
        if current_user.is_authenticated:
            return redirect(url_for("home"))
        error = None
        submitted_username = ""
        if request.method == "POST":
            submitted_username = request.form.get("username", "")
            password = request.form.get("password", "")
            row = dal.get_user_by_username(submitted_username)
            if row and dal.verify_password(password, row["password"], row["salt"]):
                # Upgrade legacy SHA-256 passwords to Werkzeug PBKDF2 on login
                if dal._is_legacy_hash(row["password"]):
                    dal.upgrade_password_to_modern(row["id"], password)
                    row = dal.get_user_by_id(row["id"])
                login_user(User(row))
                return redirect(url_for("home"))
            error = "Invalid username or password."
        return render_template("login.html",
                               error=error,
                               submitted_username=submitted_username)

    @app.route("/logout")
    @login_required
    def logout():
        logout_user()
        return redirect(url_for("login"))

    @app.route("/register", methods=["GET", "POST"])
    def register():
        error = None
        league_id = request.args.get("league_id") or request.form.get("league_id", "")
        if request.method == "POST":
            username = request.form.get("username", "").strip()
            full_name = request.form.get("full_name", "").strip()
            email = request.form.get("email", "").strip()
            password = request.form.get("password", "")
            confirm = request.form.get("password_confirm", "")
            lid = request.form.get("league_id", "").strip()

            if not username:
                error = "Please enter a username."
            elif not password:
                error = "Please enter a password."
            elif password != confirm:
                error = "Passwords do not match."
            elif not lid:
                error = "No league specified. Please register using an invite link."
            elif not email or "@" not in email:
                error = "Please enter a valid e-mail address."
            elif dal.username_exists(username):
                error = "That username is already taken."
            elif dal.email_exists(email):
                error = "That e-mail address is already registered."
            else:
                try:
                    user_id = dal.create_user(username, full_name, email, password, int(lid))
                    row = dal.get_user_by_id(user_id)
                    login_user(User(row))
                    return redirect(url_for("home"))
                except Exception as exc:
                    error = f"Registration failed: {exc}"

        return render_template("register.html", error=error, league_id=league_id)

    @app.route("/home")
    @login_required
    def home():
        return render_template("home.html",
                               username=current_user.username,
                               priv_level=current_user.priv_level)

    @app.route("/admin")
    @login_required
    def admin():
        if current_user.priv_level < 3:
            return redirect(url_for("home"))
        return render_template("admin.html", username=current_user.username)

    @app.route("/edit-account", methods=["GET", "POST"])
    @login_required
    def edit_account():
        error = None
        success = None
        if request.method == "POST":
            new_email = request.form.get("email", "").strip()
            new_password = request.form.get("password", "")
            confirm = request.form.get("password_confirm", "")

            if not new_email or "@" not in new_email:
                error = "Please enter a valid e-mail address."
            elif new_email != current_user.email and dal.email_exists(new_email):
                error = "That e-mail address is already in use."
            elif new_password and new_password != confirm:
                error = "Passwords do not match."
            else:
                dal.update_user_email(current_user.id, new_email)
                if new_password:
                    dal.update_user_password(current_user.id, new_password)
                success = "Account updated successfully."

        return render_template("edit_account.html",
                               error=error,
                               success=success,
                               user=current_user)

    @app.route("/forgot-password", methods=["GET", "POST"])
    def forgot_password():
        message = None
        if request.method == "POST":
            username = request.form.get("username", "").strip()
            if username:
                row = dal.get_user_by_username(username)
                if row:
                    token = secrets.token_hex(16)
                    dal.create_password_reset_token(username, token)
                    email_notifier.send_password_reset(row["email"], token)
                # Always show success to avoid user enumeration
                message = ("An e-mail has been sent to the address registered "
                           "to that account (if it exists).")
            else:
                message = "Please enter your username."
        return render_template("forgot_password.html", message=message)

    @app.route("/reset-password", methods=["GET", "POST"])
    def reset_password():
        token = request.args.get("token") or request.form.get("token", "")
        error = None
        success = None
        if request.method == "POST":
            password = request.form.get("password", "")
            confirm = request.form.get("password_confirm", "")
            if not password:
                error = "Please enter a new password."
            elif password != confirm:
                error = "Passwords do not match."
            else:
                ok = dal.reset_password_by_token(token, password)
                if ok:
                    success = "Password reset successfully. You may now log in."
                else:
                    error = "Invalid or expired reset link."
        return render_template("reset_password.html",
                               token=token, error=error, success=success)

    @app.route("/memberlist")
    @login_required
    def memberlist():
        return render_template("memberlist.html")

    # -------------------------------------------------------------------------
    # REST / AJAX endpoints  (mirror original restServices/ paths)
    # -------------------------------------------------------------------------

    @app.route("/api/user-selection-options")
    @login_required
    def api_user_selection_options():
        """
        Returns fixture list, available teams, current user status, and form guide.
        Replaces: restServices/showUserSelectionOptions.php
        """
        username = current_user.username

        existing = dal.get_user_selection_for_this_week(username)
        if existing:
            return jsonify(existing)

        user_status = current_user.to_dict()
        available_teams = dal.get_teams_available_to_user(username)
        fixtures = dal.get_this_weeks_fixtures()
        history = dal.get_results_history(50)

        # Build form guide: team -> comma-separated WIN/DRW/LOS string
        formguide: dict[str, str] = {}
        for row in history:
            r = row.get("Result")
            ht, at = row["HomeTeam"], row["AwayTeam"]
            if r == 1:
                formguide[ht] = formguide.get(ht, "") + "WIN,"
                formguide[at] = formguide.get(at, "") + "LOS,"
            elif r == 2:
                formguide[ht] = formguide.get(ht, "") + "DRW,"
                formguide[at] = formguide.get(at, "") + "DRW,"
            elif r == 3:
                formguide[ht] = formguide.get(ht, "") + "LOS,"
                formguide[at] = formguide.get(at, "") + "WIN,"

        # Serialise datetime objects for JSON
        for f in fixtures:
            if hasattr(f.get("KickOffTime"), "isoformat"):
                f["KickOffTime"] = f["KickOffTime"].strftime("%Y-%m-%d %H:%M:%S")

        short_names_avail = [t["ShortName"] for t in available_teams]

        return jsonify({
            "availableTeams": short_names_avail,
            "fixtures": fixtures,
            "userstatus": user_status,
            "formguide": formguide,
        })

    @app.route("/api/submit-prediction", methods=["POST"])
    @login_required
    def api_submit_prediction():
        """Replaces: restServices/submitPredictionSvc.php"""
        if current_user.payment_status != "Paid":
            return jsonify({"status": 0, "reason": "Payment Pending"})
        if current_user.comp_status == "Eliminated":
            return jsonify({"status": 0, "reason": "eliminated from comp"})

        fixture_id = int(request.form.get("FixtureId", 0))
        prediction = int(request.form.get("prediction", 0))

        result = dal.submit_user_prediction(fixture_id, current_user.username,
                                            prediction, "MANUAL")
        if result["ok"]:
            return jsonify({"status": 1, "reason": result["prediction_id"]})
        return jsonify({"status": 0, "reason": result["error"]})

    @app.route("/api/cancel-prediction", methods=["POST"])
    @login_required
    def api_cancel_prediction():
        """Replaces: restServices/cancelPredictionSvc.php"""
        if current_user.payment_status == "Pending":
            return jsonify({"status": 0, "reason": "Payment Pending"})
        if current_user.comp_status == "Eliminated":
            return jsonify({"status": 0, "reason": "eliminated from comp"})

        pred_id = int(request.form.get("predictionId", 0))
        result = dal.cancel_prediction(current_user.username, pred_id)
        return jsonify(result)

    @app.route("/api/user-standings")
    @login_required
    def api_user_standings():
        """Replaces: restServices/userStandings.php"""
        standings = dal.get_current_standings(current_user.league_id)
        return jsonify(standings)

    @app.route("/api/user-prediction-history")
    @login_required
    def api_user_prediction_history():
        """Replaces: restServices/getUserPredictionHistory.php"""
        player = request.args.get("player", current_user.username)
        history = dal.get_user_prediction_history(player)
        for row in history:
            if hasattr(row.get("KickOffTime"), "isoformat"):
                row["KickOffTime"] = row["KickOffTime"].strftime("%Y-%m-%d %H:%M:%S")
        return jsonify(history)

    @app.route("/api/all-selections")
    @login_required
    def api_all_selections():
        """Replaces: restServices/getAllSelections.php  (admin only)"""
        if current_user.priv_level < 3:
            return jsonify({"status": 0, "reason": "Insufficient privilege"}), 403
        selections = dal.get_all_selections_for_this_week()
        for row in selections:
            if hasattr(row.get("KickOffTime"), "isoformat"):
                row["KickOffTime"] = row["KickOffTime"].strftime("%Y-%m-%d %H:%M:%S")
            if hasattr(row.get("DateTimeEntered"), "isoformat"):
                row["DateTimeEntered"] = row["DateTimeEntered"].strftime("%Y-%m-%d %H:%M:%S")
        return jsonify(selections)

    @app.route("/api/selections-post-deadline")
    @login_required
    def api_selections_post_deadline():
        """Replaces: restServices/getSelectionsPostDeadline.php"""
        selections = dal.get_selections_post_deadline()
        for row in selections:
            for key in ("KickOffTime", "DateTimeEntered", "TIME_PUBLIC"):
                if key in row and hasattr(row[key], "isoformat"):
                    row[key] = row[key].strftime("%Y-%m-%d %H:%M:%S")
        return jsonify(selections)

    @app.route("/api/match-results-pending")
    @login_required
    def api_match_results_pending():
        """Replaces: restServices/showMatchResultsPending.php"""
        pending = dal.get_fixtures_with_null_result()
        for row in pending:
            if hasattr(row.get("KickOffTime"), "isoformat"):
                row["KickOffTime"] = row["KickOffTime"].strftime("%Y-%m-%d %H:%M:%S")
        return jsonify(pending)

    @app.route("/api/submit-match-score", methods=["POST"])
    @login_required
    def api_submit_match_score():
        """Replaces: restServices/submitMatchScore.php  (admin only)"""
        if current_user.priv_level < 3:
            return jsonify({"status": 0, "reason": "Insufficient privilege"}), 403

        fixture_id = int(request.form.get("FixtureId", 0))
        home_score = int(request.form.get("homeScore", 0))
        away_score = int(request.form.get("awayScore", 0))
        result = int(request.form.get("result", 0))

        ok = dal.submit_match_result(fixture_id, home_score, away_score, result)
        if ok:
            return jsonify({"status": 1, "reason": "Update successful"})
        return jsonify({"status": 0, "reason": "DB update failed"})

    @app.route("/api/users-not-paid")
    @login_required
    def api_users_not_paid():
        """Replaces: restServices/getUsersNotPaid.php  (admin only)"""
        if current_user.priv_level < 3:
            return jsonify({"status": 0, "reason": "Insufficient privilege"}), 403
        return jsonify(dal.get_playing_users_not_paid())

    @app.route("/api/users-not-submitted")
    @login_required
    def api_users_not_submitted():
        """Replaces: restServices/getUsersNotSubmitted.php  (admin only)"""
        if current_user.priv_level < 3:
            return jsonify({"status": 0, "reason": "Insufficient privilege"}), 403
        return jsonify(dal.get_lazy_users())

    @app.route("/api/update-user", methods=["POST"])
    @login_required
    def api_update_user():
        """Replaces: restServices/updateUser.php  (admin only)"""
        if current_user.priv_level < 3:
            return jsonify({"status": 0, "reason": "Insufficient privilege"}), 403

        user = request.form.get("userToUpdate", "")
        field = request.form.get("fieldToUpdate", "")
        new_value = request.form.get("newValue", "")

        if field == "PaymentStatus":
            dal.update_payment_status(user, "Paid")
            return jsonify({"status": 1, "reason": "Update successful"})
        elif field == "CompStatus":
            dal.update_comp_status(user, new_value)
            return jsonify({"status": 1, "reason": "Update successful"})

        return jsonify({"status": 0, "reason": "Unknown field"})

    @app.route("/api/send-mail-reminder", methods=["POST"])
    @login_required
    def api_send_mail_reminder():
        """Replaces: restServices/sendMailReminder.php  (admin only)"""
        if current_user.priv_level < 3:
            return jsonify({"status": 0, "reason": "Admin access only"}), 403

        lazy_users = dal.get_lazy_users()
        ok = email_notifier.send_submit_reminder(lazy_users)
        return jsonify({"status": 1 if ok else 0,
                        "reason": "mail sent" if ok else "some mails failed"})

    @app.route("/api/run-auto-picks", methods=["POST"])
    @login_required
    def api_run_auto_picks():
        """
        Auto-assign a random available team to every user who has not yet
        submitted a prediction for the current game week.
        Replaces: restServices/runAutoPicks.php  (admin only)
        """
        if current_user.priv_level < 3:
            return jsonify({"status": 0, "reason": "Admin access only"}), 403

        lazy_users = dal.get_lazy_users()
        completed = []
        for user in lazy_users:
            username = user["username"]
            team = dal.select_random_team_for_user(username)
            if not team:
                continue
            fixture = dal.get_next_fixture_for_team(team["LongName"])
            if not fixture:
                continue
            predicted_result = (
                1 if fixture["HomeTeam"].strip().lower() == team["LongName"].strip().lower()
                else 3
            )
            result = dal.submit_user_prediction(
                fixture["FixtureId"], username, predicted_result, "AUTO"
            )
            if result["ok"]:
                completed.append({
                    "UserName": username,
                    "FixtureID": fixture["FixtureId"],
                    "PredictedResult": predicted_result,
                    "EntryType": "AUTO",
                })

        if completed:
            return jsonify({"status": 1, "reason": completed})
        return jsonify({"status": 0, "reason": "No auto predictions were made"})

    @app.route("/api/dynamite-options")
    @login_required
    def api_dynamite_options():
        """Replaces: restServices/showUserDynamiteOptions.php"""
        options = dal.get_dynamite_for_user(current_user.id)
        if options:
            for row in options:
                if hasattr(row.get("updated_at"), "isoformat"):
                    row["updated_at"] = row["updated_at"].strftime("%Y-%m-%d %H:%M:%S")
            return jsonify(options)
        return jsonify({"status": 0, "reason": "No dynamite"})

    @app.route("/api/drop-dynamite", methods=["POST"])
    @login_required
    def api_drop_dynamite():
        """Replaces: restServices/submitDynamiteDrop.php"""
        user_last_update = request.form.get("user_last_update", "")
        drop_on_user = request.form.get("drop_on_user", "")
        dynamite_id = int(request.form.get("dynamite_id", 0))

        if not drop_on_user or not dynamite_id:
            return jsonify({"status": 0, "message": "Invalid request"})

        db_last_update = dal.get_dynamite_last_updated()
        if db_last_update and str(db_last_update) != user_last_update:
            return jsonify({"status": 1, "reason": "stale data"})

        new_lives = dal.drop_dynamite_on_user(dynamite_id, drop_on_user)
        if new_lives is None:
            return jsonify({"status": 0, "message": "Drop failed"})

        if new_lives == 0:
            dal.update_comp_status(drop_on_user, "Eliminated")

        return jsonify({
            "status": 1,
            "reason": {
                "player_hit": drop_on_user,
                "lives_remaining": new_lives,
            },
        })

    @app.route("/api/dynamite-history")
    @login_required
    def api_dynamite_history():
        """Replaces: restServices/getDynamiteDropHistory.php"""
        history = dal.get_dynamite_drop_history()
        for row in history:
            if hasattr(row.get("updated_at"), "isoformat"):
                row["updated_at"] = row["updated_at"].strftime("%Y-%m-%d %H:%M:%S")
        return jsonify(history)

    @app.route("/api/request-password-reset", methods=["POST"])
    def api_request_password_reset():
        """Replaces: restServices/requestPasswordReset.php"""
        username = request.form.get("username", "").strip()
        if not username:
            return jsonify({"status": "fail", "reason": "username required"})

        row = dal.get_user_by_username(username)
        if row:
            token = secrets.token_hex(16)
            dal.create_password_reset_token(username, token)
            email_notifier.send_password_reset(row["email"], token)
        # Always return success to avoid user enumeration
        return jsonify({"status": "success", "reason": ""})

    @app.route("/api/do-password-reset", methods=["POST"])
    def api_do_password_reset():
        """Replaces: restServices/doPasswordReset.php"""
        token = request.form.get("token", "")
        password = request.form.get("password", "")
        confirm = request.form.get("passwordConfirm", "")

        if password != confirm:
            return jsonify({
                "status": "fail",
                "reason": "Password and confirmation do not match",
            })

        username = dal.get_username_by_reset_token(token)
        if not username:
            return jsonify({
                "status": "fail",
                "reason": "Invalid or expired token",
            })

        ok = dal.reset_password_by_token(token, password)
        if ok:
            return jsonify({"status": "success", "reason": username})
        return jsonify({"status": "fail", "reason": "Password reset failed"})

    return app


app = create_app()

if __name__ == "__main__":
    debug = os.environ.get("FLASK_DEBUG", "0") == "1"
    app.run(debug=debug)
