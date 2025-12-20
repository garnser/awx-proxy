import os

class Config:
    ENV = os.getenv("FLASK_ENV", "production")
    DEBUG = False

    SERVICE_NAME = "executor"
