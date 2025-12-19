import os

class Config:
    ENV = os.getenv("FLASK_ENV", "production")
    DEBUG = ENV == "development"

    # Placeholder config values
    DATABASE_URL = os.getenv("DATABASE_URL")
    SERVICE_NAME = os.getenv("SERVICE_NAME", "api")
