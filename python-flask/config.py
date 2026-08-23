import os


class Config:
    SECRET_KEY = os.environ.get("LMS_SECRET_KEY", "change-me-in-production")
    DB_HOST = os.environ.get("LMS_DB_HOST", "localhost")
    DB_USER = os.environ.get("LMS_DB_USER", "lms")
    DB_PASSWORD = os.environ.get("LMS_DB_PASSWORD", "")
    DB_NAME = os.environ.get("LMS_DB_NAME", "lastmanstanding")
    MAIL_FROM_ADDRESS = os.environ.get("LMS_MAIL_FROM", "lms@actionshots.ie")
    MAIL_FROM_NAME = os.environ.get("LMS_MAIL_FROM_NAME", "Last Man Standing")
    BASE_URL = os.environ.get("LMS_BASE_URL", "http://localhost:5000")
    SMTP_HOST = os.environ.get("LMS_SMTP_HOST", "localhost")
    SMTP_PORT = int(os.environ.get("LMS_SMTP_PORT", "25"))
