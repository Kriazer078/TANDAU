from flask import Flask, jsonify
from flask_cors import CORS
from src.utils.errors import AppError
from src.controllers.user_controller import user_bp

def create_app():
    app = Flask(__name__)
    
    # Enable CORS for all routes (restrict origins in production)
    CORS(app)
    
    # Register Blueprints with versioning
    app.register_blueprint(user_bp, url_prefix='/v1/users')
    
    # Global Error Handler
    @app.errorhandler(AppError)
    def handle_app_error(error):
        response = jsonify(error.to_dict())
        response.status_code = error.status_code
        return response

    @app.errorhandler(404)
    def handle_404(error):
        return jsonify({"status": "error", "message": "Endpoint not found"}), 404

    @app.errorhandler(500)
    def handle_500(error):
        return jsonify({"status": "error", "message": "Internal Server Error"}), 500
        
    @app.route('/health')
    def health_check():
        return jsonify({"status": "ok", "version": "1.0.0"}), 200

    return app
