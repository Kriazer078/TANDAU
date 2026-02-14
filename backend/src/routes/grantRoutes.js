const express = require('express');
const router = express.Router();
const grantController = require('../controllers/grantController');
const verifyToken = require('../middleware/authMiddleware');
const checkRole = require('../middleware/roleMiddleware');

// Get all grants - Public
router.get('/', grantController.getAllGrants);

// Create grant - Admin Only
router.post('/', verifyToken, checkRole(['admin']), grantController.createGrant);

module.exports = router;
