const { db } = require('../config/firebase');

const getAllGrants = async (req, res) => {
    try {
        const snapshot = await db.collection('grants').get();
        const grants = [];
        snapshot.forEach(doc => {
            grants.push({ id: doc.id, ...doc.data() });
        });
        res.json({ grants });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

const createGrant = async (req, res) => {
    try {
        const { title, description, amount, deadline, universityId } = req.body;

        const newGrant = {
            title,
            description,
            amount,
            deadline,
            universityId, // Link to university if applicable
            createdAt: new Date().toISOString()
        };

        const docRef = await db.collection('grants').add(newGrant);
        res.status(201).json({ id: docRef.id, message: 'Grant created' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = { getAllGrants, createGrant };
