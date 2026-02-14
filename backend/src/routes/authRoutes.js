const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const verifyToken = require('../middleware/authMiddleware');

// Public route to register new users
router.post('/signup', authController.signup);

// Protected route to get current user profile
router.get('/profile', verifyToken, authController.getProfile);

module.exports = router;
