import os
from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__)

@health_bp.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "ok",
        "service": "executor"
    })

@health_bp.route("/health/version", methods=["GET"])
def version():
    return jsonify({
        "service": "executor",
        "version": os.getenv("APP_VERSION", "unknown"),
        "git_sha": os.getenv("APP_GIT_SHA", "unknown"),
        "build_date": os.getenv("APP_BUILD_DATE", "unknown")
    })
