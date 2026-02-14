from firebase_admin import auth, firestore
from src.utils.logger import Logger
from src.utils.errors import AppError, NotFoundError

class UserService:
    def __init__(self):
        self.db = firestore.client()
        self.collection = self.db.collection('users')

    def get_user_profile(self, uid):
        # Fetch detailed profile from Firestore
        # Assuming we store extra user data in 'users' collection
        doc = self.collection.document(uid).get()
        if not doc.exists:
            # Fallback to auth user record if firestore doc doesn't exist yet
            try:
                user_record = auth.get_user(uid)
                return {
                    "uid": user_record.uid,
                    "email": user_record.email,
                    "displayName": user_record.display_name,
                    "photoURL": user_record.photo_url,
                    "role": user_record.custom_claims.get('role', 'user') if user_record.custom_claims else 'user'
                }
            except Exception as e:
                Logger.error(f"Error fetching auth user: {e}")
                raise NotFoundError("User not found")
        
        return doc.to_dict()

    def update_user_role(self, uid, new_role):
        try:
            # Set custom claims for role-based access
            auth.set_custom_user_claims(uid, {'role': new_role})
            
            # Also update firestore
            self.collection.document(uid).set({'role': new_role}, merge=True)
            
            Logger.info(f"Updated role for {uid} to {new_role}")
            return {"uid": uid, "role": new_role}
        except Exception as e:
            Logger.error(f"Failed to update role: {e}")
            raise AppError("Failed to update user role")

    def create_user(self, data):
        # Logic to create user in Auth and Firestore
        try:
            user = auth.create_user(
                email=data.email,
                password=data.password,
                display_name=data.display_name
            )
            
            # Set initial role
            role = data.role or 'user'
            auth.set_custom_user_claims(user.uid, {'role': role})
            
            # Create firestore doc
            user_doc = {
                'uid': user.uid,
                'email': data.email,
                'displayName': data.display_name,
                'role': role,
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            self.collection.document(user.uid).set(user_doc)
            
            return user_doc
        except Exception as e:
            Logger.error(f"Create user failed: {e}")
            raise AppError(f"Could not create user: {str(e)}")
