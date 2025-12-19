from flask import Flask

def create_app():
    app = Flask(__name__)

    app.config.from_object("app.config.Config")

    from app.blueprints.health.routes import health_bp
    app.register_blueprint(health_bp)

    return app
