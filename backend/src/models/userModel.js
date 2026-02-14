const { db } = require('../config/firebase');

/**
 * User Model
 * Represents the structure of a user document in Firestore.
 * This is a helper class, not an ORM model.
 */
class User {
    constructor(uid, email, displayName, role = 'user', photoURL = '') {
        this.uid = uid;
        this.email = email;
        this.displayName = displayName;
        this.role = role;
        this.photoURL = photoURL;
        this.createdAt = new Date().toISOString();
    }

    toFirestore() {
        return {
            uid: this.uid,
            email: this.email,
            displayName: this.displayName,
            role: this.role,
            photoURL: this.photoURL,
            createdAt: this.createdAt
        };
    }
}

module.exports = User;
