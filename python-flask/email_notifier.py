"""Email notification helpers for Last Man Standing."""

import os

import requests


def _send(to_name: str, to_email: str, subject: str, html_body: str) -> bool:
    api_key = os.environ.get("MAILGUN_API_KEY", "")
    domain = os.environ.get("MAILGUN_DOMAIN", "")
    from_addr = os.environ.get("LMS_MAIL_FROM", "lms@actionshots.ie")
    from_name = os.environ.get("LMS_MAIL_FROM_NAME", "Last Man Standing")

    try:
        response = requests.post(
            f"https://api.eu.mailgun.net/v3/{domain}/messages",
            auth=("api", api_key),
            data={
                "from": f"{from_name} <{from_addr}>",
                "to": f"{to_name} <{to_email}>",
                "subject": subject,
                "html": html_body,
            },
            timeout=10,
        )
        response.raise_for_status()
        return True
    except Exception as exc:
        print(f"[email] Failed to send to {to_email}: {exc}")
        return False


def send_prediction_confirmation(pred_details: dict) -> bool:
    subject = "Last Man Standing - Prediction Confirmation"
    body = (
        f"<html><body>Your prediction has been submitted<br><br>"
        f"<table style='border:1px solid'>"
        f"<tr><td>Prediction ID</td><td>{pred_details['PredictionID']}</td></tr>"
        f"<tr><td>Game</td><td>{pred_details['FixtureDetail']} "
        f"- Kick-off: {pred_details['KickOffTime']}</td></tr>"
        f"<tr><td>You selected</td><td>{pred_details['User Selected']}</td></tr>"
        f"</table></body></html>"
    )
    return _send(pred_details["FullName"], pred_details["email"], subject, body)


def send_submit_reminder(users: list[dict]) -> bool:
    base_url = os.environ.get("LMS_BASE_URL", "http://localhost:5000")
    all_ok = True
    for user in users:
        subject = "Last Man Standing - Reminder"
        body = (
            f"<html><strong>Reminder</strong> to submit your team for LMS. "
            f"Log in <a href='{base_url}'>here</a></html>"
        )
        ok = _send(user["FullName"], user["Email"], subject, body)
        all_ok = all_ok and ok
    return all_ok


def send_password_reset(email: str, token: str) -> bool:
    base_url = os.environ.get("LMS_BASE_URL", "http://localhost:5000")
    reset_url = f"{base_url}/reset-password?token={token}"
    subject = "Last Man Standing - Password Reset Instructions"
    body = (
        f"<html><body>A request to change your password was submitted.<br><br>"
        f"<a href='{reset_url}'>Click here</a> to reset your password.<br><br>"
        f"This link expires in 10 minutes.</body></html>"
    )
    return _send("User", email, subject, body)
