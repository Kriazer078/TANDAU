from flask import Blueprint, jsonify, request
from src.services.ai_service import AIService
import traceback

ai_bp = Blueprint('ai', __name__)
ai_service = AIService()

@ai_bp.route('/getAIStrategy', methods=['POST'])
def get_ai_strategy():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"status": "error", "message": "No JSON data provided"}), 400

        user_unt_score = data.get('user_unt_score')
        specialty_id = data.get('specialty_id')
        university_id = data.get('university_id')
        user_subjects_scores = data.get('user_subjects_scores', {})

        if user_unt_score is None or specialty_id is None or university_id is None:
            return jsonify({"status": "error", "message": "Missing required fields"}), 400

        result = ai_service.generate_strategy(
            user_unt_score, 
            specialty_id, 
            university_id, 
            user_subjects_scores
        )
        return jsonify(result), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500
