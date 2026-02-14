from flask import jsonify

class AppError(Exception):
    def __init__(self, message, status_code=400, payload=None):
        super().__init__()
        self.message = message
        self.status_code = status_code
        self.payload = payload

    def to_dict(self):
        rv = dict(self.payload or ())
        rv['message'] = self.message
        rv['status'] = 'error'
        rv['code'] = self.status_code
        return rv

class UnauthorizedError(AppError):
    def __init__(self, message="Unauthorized"):
        super().__init__(message, 401)

class ForbiddenError(AppError):
    def __init__(self, message="Forbidden"):
        super().__init__(message, 403)

class NotFoundError(AppError):
    def __init__(self, message="Resource not found"):
        super().__init__(message, 404)

class ValidationError(AppError):
    def __init__(self, message="Validation failed", payload=None):
        super().__init__(message, 400, payload)
