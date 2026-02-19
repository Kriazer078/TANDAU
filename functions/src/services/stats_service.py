from firebase_admin import firestore
from datetime import datetime
import pytz

class StatsService:
    def __init__(self):
        self.db = firestore.client()
        self.collection = self.db.collection('statistics')

    def track_new_user(self):
        """Increments new_users counter for the current day."""
        today = datetime.now(pytz.utc).strftime("%Y-%m-%d")
        doc_ref = self.collection.document(today)
        
        try:
            doc_ref.set({
                "new_users": firestore.Increment(1),
                "date": datetime.now(pytz.utc)
            }, merge=True)
            return {"status": "success", "message": f"Tracked new user for {today}"}
        except Exception as e:
            print(f"Error tracking user: {e}")
            raise e

    def track_new_review(self):
        """Increments new_reviews counter for the current day."""
        today = datetime.now(pytz.utc).strftime("%Y-%m-%d")
        doc_ref = self.collection.document(today)
        
        try:
            doc_ref.set({
                "new_reviews": firestore.Increment(1),
                "date": datetime.now(pytz.utc)
            }, merge=True)
            return {"status": "success", "message": f"Tracked new review for {today}"}
        except Exception as e:
            print(f"Error tracking review: {e}")
            raise e
