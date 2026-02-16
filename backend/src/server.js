const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');
const path = require('path');

// Load env vars
dotenv.config();

// Route imports
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const universityRoutes = require('./routes/universityRoutes');
const grantRoutes = require('./routes/grantRoutes');
const chatRoutes = require('./routes/chatRoutes'); // AI Chat

const app = express();

// --- Security & Middleware ---
app.use(helmet()); // Set security headers
app.use(cors()); // Enable CORS
app.use(express.json()); // Parse JSON bodies
app.use(morgan('dev')); // Logger

// Rate Limiter: 100 requests per 15 minutes
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
});
app.use(limiter);

// --- Routes ---
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to TANDAU API', version: '1.0.0', status: 'running' });
});

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Mounted with API Version v1
const apiVersion = '/api/v1';
app.use(`${apiVersion}/auth`, authRoutes);
app.use(`${apiVersion}/users`, userRoutes);
app.use(`${apiVersion}/universities`, universityRoutes);
app.use(`${apiVersion}/grants`, grantRoutes);
app.use(`${apiVersion}/chat`, chatRoutes); // AI Endpoint

// Admin Panel
app.use('/admin', express.static(path.join(__dirname, '../admin')));

// --- Error Handling ---
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong!'
    });
});

// Start Server
const PORT = process.env.PORT || 3000;

if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}

module.exports = app;
