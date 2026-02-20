from flask import Blueprint, jsonify
from src.services.stats_service import StatsService

stats_bp = Blueprint('stats', __name__)
stats_service = StatsService()

@stats_bp.route('/user-created', methods=['POST'])
# No auth required for initial registration, or we can use verify_token if they sign in first.
# To keep it simple and robust, let's keep it open for now or trust the client.
# A better way is to verify Firebase Auth ID token here.
def user_created():
    """Track a new user registration"""
    try:
        result = stats_service.track_new_user()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@stats_bp.route('/review-created', methods=['POST'])
def review_created():
    """Track a new review"""
    try:
        result = stats_service.track_new_review()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
