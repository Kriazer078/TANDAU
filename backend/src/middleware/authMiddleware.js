/**
 * Authentication Middleware
 * Verifies the Firebase ID Token passed in the Authorization header.
 * Attaches the decoded user to req.user.
 */
const { auth } = require('../config/firebase');

const verifyToken = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized', message: 'No token provided' });
    }

    const token = authHeader.split('Bearer ')[1];

    try {
        const decodedToken = await auth.verifyIdToken(token);
        req.user = decodedToken;
        next();
    } catch (error) {
        console.error('Error verifying token:', error);
        return res.status(403).json({ error: 'Forbidden', message: 'Invalid or expired token' });
    }
};

module.exports = verifyToken;
