from functools import wraps
from flask import request
from pydantic import ValidationError as PydanticValidationError
from src.utils.errors import ValidationError

def validate_schema(schema_class):
    """
    Decorator to validate JSON request body against a Pydantic schema.
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not request.is_json:
                raise ValidationError("Request must be JSON")
            
            try:
                data = schema_class(**request.get_json())
                # Pass validated data as a keyword argument named 'validated_data'
                # or attach to g, but kwargs is cleaner for specific handlers
                kwargs['validated_data'] = data
            except PydanticValidationError as e:
                # Format validation errors
                errors = []
                for error in e.errors():
                    field = ".".join(str(x) for x in error['loc'])
                    msg = error['msg']
                    errors.append(f"{field}: {msg}")
                raise ValidationError("Invalid data provided", payload={'errors': errors})
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator
