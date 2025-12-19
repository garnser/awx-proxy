from flask import Flask

def create_app():
    app = Flask(__name__)

    # Basic configuration
    app.config.from_object("app.config.Config")

    # Register blueprints
    from app.blueprints.health.routes import health_bp
    app.register_blueprint(health_bp)

    return app
