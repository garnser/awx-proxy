from flask import Blueprint, request, jsonify

jobs_bp = Blueprint("jobs", __name__)

@jobs_bp.route("/internal/jobs/notify", methods=["POST"])
def notify():
    payload = request.get_json(silent=True) or {}

    job_id = payload.get("job_id")

    if not job_id:
        return jsonify({"error": "job_id missing"}), 400

    # For now: just acknowledge
    return jsonify({
        "status": "accepted",
        "job_id": job_id
    }), 202
