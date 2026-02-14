import time
from functools import wraps
from flask import request, g
from src.utils.errors import AppError
from src.utils.logger import Logger

# Simple in-memory store for rate limiting
# Key: IP or User ID, Value: (timestamp, count)
# NOTE: In Cloud Functions, memory is not shared across instances. 
# This is a basic implementation. For production scaling, use Redis.
_request_counts = {}

def rate_limit(limit=10, window=60):
    """
    Rate limit decorator.
    :param limit: Number of requests allowed.
    :param window: Time window in seconds.
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Identify client by User ID (if authed) or IP
            client_id = getattr(g, 'uid', request.remote_addr)
            current_time = time.time()
            
            # Clean up old entries occasionally (naive approach)
            # In a real app, this should be done differently
            
            request_data = _request_counts.get(client_id, [])
            
            # Filter requests within the window
            request_data = [t for t in request_data if current_time - t < window]
            
            if len(request_data) >= limit:
                Logger.warning(f"Rate limit exceeded for {client_id}")
                raise AppError("Too many requests, please try again later", 429)
            
            request_data.append(current_time)
            _request_counts[client_id] = request_data
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator
