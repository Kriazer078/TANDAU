from flask import Blueprint, jsonify, g
from src.middleware.auth import verify_token, require_role
from src.middleware.validation import validate_schema
from src.middleware.rate_limit import rate_limit
from src.models.user import UserCreate, UserUpdate
from src.services.user_service import UserService

user_bp = Blueprint('user', __name__, url_prefix='/users')
user_service = UserService()

@user_bp.route('/me', methods=['GET'])
@verify_token
@rate_limit(limit=20, window=60)
def get_my_profile():
    """Get current logged in user profile"""
    profile = user_service.get_user_profile(g.uid)
    return jsonify({"status": "success", "data": profile}), 200

@user_bp.route('/', methods=['POST'])
@rate_limit(limit=5, window=60) # stricter limit for creation
@validate_schema(UserCreate)
# @verify_token # Open endpoint for registration or protected? 
# Usually registration is verified on client via auth then user doc created,
# OR admin creates user. Let's assume generic registration for now.
# If admin-only creation is needed, uncomment verify_token and use require_role('admin')
def create_user(validated_data):
    """Create a new user"""
    try:
        new_user = user_service.create_user(validated_data)
        return jsonify({"status": "success", "data": new_user}), 201
    except Exception as e:
        # Service handles logging, just bubble up or catch
        raise e

@user_bp.route('/<uid>/role', methods=['PUT'])
@verify_token
@require_role('admin')
@validate_schema(UserUpdate)
def update_role(uid, validated_data):
    """Admin only: Update a user's role"""
    if not validated_data.role:
        return jsonify({"status": "error", "message": "Role is required"}), 400
    
    result = user_service.update_user_role(uid, validated_data.role)
    return jsonify({"status": "success", "data": result}), 200
