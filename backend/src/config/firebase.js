const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

// Check if Firebase credentials are provided in env, else try default Google credentials
if (process.env.FIREBASE_PRIVATE_KEY) {
    admin.initializeApp({
        credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            // Handle newline characters in private key
            privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
    });
} else {
    // Fallback for local development if GOOGLE_APPLICATION_CREDENTIALS is set
    // or if running in a Google Cloud environment
    admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };
