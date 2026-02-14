const express = require('express');
const router = express.Router();
const userService = require('../services/userService');
const verifyToken = require('../middleware/authMiddleware');
const checkRole = require('../middleware/roleMiddleware');

// Get all users - Admin only
router.get('/', verifyToken, checkRole(['admin']), async (req, res) => {
    try {
        const users = await userService.getAllUsers();
        res.json({ users });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get specific user - Admin or the user themselves
router.get('/:uid', verifyToken, async (req, res) => {
    try {
        const { uid } = req.params;

        // Check permissions: Admin or same user
        if (req.user.role !== 'admin' && req.user.uid !== uid) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        const user = await userService.getUserProfile(uid);
        if (!user) return res.status(404).json({ error: 'User not found' });

        res.json({ user });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
