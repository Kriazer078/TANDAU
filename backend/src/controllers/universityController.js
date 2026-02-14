const { db } = require('../config/firebase');
const University = require('../models/universityModel');

const getAllUniversities = async (req, res) => {
    try {
        const snapshot = await db.collection('universities').get();
        const universities = [];
        snapshot.forEach(doc => {
            universities.push({ id: doc.id, ...doc.data() });
        });
        res.json({ universities });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

const createUniversity = async (req, res) => {
    try {
        const { name, city, description, ranking } = req.body;
        // Validation could be added here or in middleware

        const newUni = {
            name,
            city,
            description,
            ranking: parseInt(ranking)
        };

        const docRef = await db.collection('universities').add(newUni);
        res.status(201).json({ id: docRef.id, message: 'University created' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = { getAllUniversities, createUniversity };
