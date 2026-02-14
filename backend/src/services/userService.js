const { db, auth } = require('../config/firebase');
const User = require('../models/userModel');

/**
 * Create a new user in Firestore after they sign up via Firebase Auth.
 * @param {Object} userData - Data from the request
 * @returns {Promise<Object>} Created user data
 */
const createUser = async (userData) => {
    const { uid, email, displayName, photoURL, role } = userData;

    // Create user instance
    const newUser = new User(uid, email, displayName, role, photoURL);

    // Save to Firestore 'users' collection
    await db.collection('users').doc(uid).set(newUser.toFirestore());

    // Set Custom User Claims for Role (Important for Role-Based Access)
    // This allows verifyToken to see the role immediately.
    await auth.setCustomUserClaims(uid, { role: newUser.role });

    return newUser.toFirestore();
};

/**
 * Get user profile by UID
 * @param {string} uid 
 * @returns {Promise<Object|null>}
 */
const getUserProfile = async (uid) => {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;
    return userDoc.data();
};

/**
 * Get all users (Admin only)
 * @returns {Promise<Array>}
 */
const getAllUsers = async () => {
    const snapshot = await db.collection('users').get();
    const users = [];
    snapshot.forEach(doc => {
        users.push(doc.data());
    });
    return users;
}

module.exports = {
    createUser,
    getUserProfile,
    getAllUsers
};
