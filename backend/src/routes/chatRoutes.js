const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

// POST /api/v1/chat
router.post('/', chatController.chat);

module.exports = router;
