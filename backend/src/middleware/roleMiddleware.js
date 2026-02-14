/**
 * Role-Based Access Control Middleware
 * Checks if the authenticated user has the required role.
 * Assumes req.user is already populated by verifyToken middleware.
 */
const { auth } = require('../config/firebase');

// Cache roles temporarily if needed, but for now we trust the custom claims
// or we fetch from Firestore if custom claims aren't used.
// Here we assume roles are set in Custom Claims or Firestore 'users' collection.

const checkRole = (requiredRoles) => {
    return async (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const { uid } = req.user;

        // Option 1: Check Custom Claims (Best performance)
        // const userRecord = await auth.getUser(uid);
        // const userRole = userRecord.customClaims?.role || 'user';

        // Option 2: Check token claims (req.user has payload)
        // Note: Custom claims are inside the token, so we can use req.user.role directly if set.
        // If you haven't set custom claims yet, we might need to check Firestore.

        // For this implementation, we will check the 'role' custom claim.
        // Ensure you implement a mechanism to Set these claims (e.g. in a signup trigger or admin endpoint).
        const userRole = req.user.role || 'user'; // Default to user

        if (requiredRoles.includes(userRole)) {
            return next();
        }

        return res.status(403).json({
            error: 'Forbidden',
            message: `Access denied. Requires one of the following roles: ${requiredRoles.join(', ')}`
        });
    };
};

module.exports = checkRole;
