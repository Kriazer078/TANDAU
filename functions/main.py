from firebase_functions import https_fn
from firebase_admin import initialize_app
from src.app import create_app

# Initialize Firebase Admin SDK once
initialize_app()

# Create Flask app
app = create_app()

# Expose Flask app as a single Cloud Function
# This captures all requests to /api/**
@https_fn.on_request(max_instances=10)
def api(req: https_fn.Request) -> https_fn.Response:
    with app.request_context(req.environ):
        return app.full_dispatch_request()