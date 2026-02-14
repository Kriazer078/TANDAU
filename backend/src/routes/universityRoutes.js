const express = require('express');
const router = express.Router();
const uniController = require('../controllers/universityController');
const verifyToken = require('../middleware/authMiddleware');
const checkRole = require('../middleware/roleMiddleware');

// Public or Protected - List Universities
router.get('/', uniController.getAllUniversities);

// Admin Only - Create University
router.post('/', verifyToken, checkRole(['admin']), uniController.createUniversity);

module.exports = router;
