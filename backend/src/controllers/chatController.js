const { GoogleGenerativeAI } = require("@google/generative-ai");

// Get the API key from environment variables
const API_KEY = process.env.GEMINI_API_KEY;

// Initialize the Google Generative AI client
const genAI = new GoogleGenerativeAI(API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-pro" });

/**
 * Handle chat request
 * Expects: { question: string }
 * Returns: { answer: string }
 */
const chat = async (req, res) => {
    try {
        const { question } = req.body;

        if (!question) {
            return res.status(400).json({ error: "Question is required" });
        }

        if (!API_KEY) {
            console.error("GEMINI_API_KEY is not set");
            return res.status(500).json({ error: "Server configuration error (API Key missing)" });
        }

        // Generate content
        const result = await model.generateContent(question);
        const response = await result.response;
        const text = response.text();

        res.json({ answer: text });
    } catch (error) {
        console.error("Error generating content:", error);
        res.status(500).json({ error: "Failed to generate response from AI" });
    }
};

module.exports = {
    chat
};
