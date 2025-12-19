import os

class Config:
    ENV = os.getenv("FLASK_ENV", "production")
    DEBUG = ENV == "development"

    SECRET_KEY = os.getenv("SECRET_KEY", "dev-only-change-me")

    DATABASE_URL = os.getenv("DATABASE_URL")
    SERVICE_NAME = os.getenv("SERVICE_NAME", "admin")
