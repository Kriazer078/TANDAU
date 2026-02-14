const userService = require('../services/userService');
const { auth } = require('../config/firebase');

/**
 * Handle new user registration (sync with Firestore)
 * Expects the client to have already created the Auth user, 
 * OR this endpoint creates the Auth user. 
 * For better security/flow, usually client creates Auth user, then calls this to sync DB.
 */
const signup = async (req, res) => {
    try {
        // In this flow, we assume the Frontend sends an ID Token of the JUST created user
        // OR keeps it open. Let's assume we are receiving data to CREATE the user here?
        // "Requirements: POST /api/auth/signup"
        // If we create on backend:

        const { email, password, displayName, role } = req.body;

        if (!email || !password || !displayName) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // 1. Create User in Firebase Auth
        const userRecord = await auth.createUser({
            email,
            password,
            displayName,
        });

        // 2. Create User in Firestore
        const userData = {
            uid: userRecord.uid,
            email: userRecord.email,
            displayName: userRecord.displayName,
            role: role || 'user', // Default to user
            photoURL: userRecord.photoURL || ''
        };

        const newUser = await userService.createUser(userData);

        res.status(201).json({
            message: 'User created successfully',
            user: newUser
        });

    } catch (error) {
        console.error('Signup Error:', error);
        res.status(500).json({ error: error.message });
    }
};

const getProfile = async (req, res) => {
    try {
        const uid = req.user.uid;
        const user = await userService.getUserProfile(uid);

        if (!user) {
            return res.status(404).json({ error: 'User profile not found' });
        }

        res.json({ user });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = {
    signup,
    getProfile
};
