from firebase_functions import https_fn, firestore_fn
from firebase_admin import initialize_app, firestore, messaging
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

# Listen for new notifications in Firestore and send Push Notification
@firestore_fn.on_document_created(document="users/{userId}/notifications/{notificationId}")
def send_push_notification(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    # Get the verification data
    snapshot = event.data
    if not snapshot:
        return

    notification_data = snapshot.to_dict()
    if not notification_data:
        return

    user_id = event.params["userId"]
    
    # Get the user's FCM token from their profile
    db = firestore.client()
    user_ref = db.collection("users").document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        print(f"User {user_id} not found")
        return

    user_data = user_doc.to_dict()
    fcm_token = user_data.get("fcmToken")

    if not fcm_token:
        print(f"No FCM token for user {user_id}")
        return

    # Construct the message
    title = notification_data.get("title", "Новое уведомление")
    body = notification_data.get("message", "")
    
    # Extract optional data payload
    data_payload = notification_data.get("data", {})
    # Ensure all data values are strings for FCM
    string_data = {k: str(v) for k, v in data_payload.items()}
    
    # Add screen navigation info if available
    if "type" in notification_data:
         string_data["type"] = str(notification_data["type"])

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=string_data,
        token=fcm_token,
    )

    # Send the message
    try:
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
    except Exception as e:
# Removed Cloud Functions triggers to avoid Cloud Build dependency.
# Stats are now handled via manual API calls to Render backend.