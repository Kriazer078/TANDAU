from functools import wraps
from flask import request, g
from firebase_admin import auth
from src.utils.errors import UnauthorizedError, ForbiddenError
from src.utils.logger import Logger

def verify_token(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            Logger.warning("Missing or invalid Authorization header")
            raise UnauthorizedError("Missing or invalid Authorization header")

        id_token = auth_header.split('Bearer ')[1]
        try:
            decoded_token = auth.verify_id_token(id_token)
            g.user = decoded_token  # verification successful
            g.uid = decoded_token['uid']
            # Store role for convenience, defaulting to user if not set
            g.role = decoded_token.get('role', 'user') 
        except Exception as e:
            Logger.error(f"Token verification failed: {e}")
            raise UnauthorizedError("Invalid token")
        
        return f(*args, **kwargs)
    return decorated_function

def require_role(required_role):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not hasattr(g, 'role'):
                # Should be checked after verify_token
                raise UnauthorizedError("User role not verified")
            
            # Simple check: if required is 'admin', user must be 'admin'
            # If required is 'user', 'admin' can also access (hierarchy)
            if required_role == 'admin' and g.role != 'admin':
                Logger.warning(f"Access denied for user {g.uid} with role {g.role} (required: {required_role})")
                raise ForbiddenError("Insufficient permissions")
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator
