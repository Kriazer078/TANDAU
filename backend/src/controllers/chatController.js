const { GoogleGenerativeAI } = require("@google/generative-ai");
const { db } = require('../config/firebase'); // For RAG

// Get the API key from environment variables
const API_KEY = process.env.GEMINI_API_KEY;

// Initialize the Google Generative AI client
const genAI = new GoogleGenerativeAI(API_KEY);

// Cache for university data to avoid fetching on every chat
let cachedUniversitiesContext = "";
let lastCacheUpdate = 0;

async function getUniversitiesContext() {
    const now = Date.now();
    // Update cache every 1 hour
    if (now - lastCacheUpdate < 3600000 && cachedUniversitiesContext) {
        return cachedUniversitiesContext;
    }

    try {
        const snapshot = await db.collection('universities').get();
        const unis = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            unis.push(`- ${data.name || 'Без названия'} (${data.city || 'Город неизвестен'}). Описание: ${data.description || 'Нет'}`);
        });
        cachedUniversitiesContext = "Список университетов в нашей базе данных:\n" + unis.join("\n");
        lastCacheUpdate = now;
        return cachedUniversitiesContext;
    } catch (error) {
        console.error("Failed to load universities for RAG:", error);
        return "Не удалось загрузить базу университетов.";
    }
}

/**
 * Handle chat request with SSE Streaming
 * Expects: { question: string, language?: string, userContext?: string, history?: array }
 */
const chat = async (req, res) => {
    try {
        const { question, language, userContext, history, uid } = req.body;

        if (!question) {
            return res.status(400).json({ error: "Question is required" });
        }

        if (!API_KEY) {
            console.error("GEMINI_API_KEY is not set");
            return res.status(500).json({ error: "Server configuration error (API Key missing)" });
        }

        // Detect if request wants streaming
        const wantsEventStream = req.headers['accept'] === 'text/event-stream' || String(req.originalUrl).includes('stream');
        // Actually, the app reads the Content-Type response. So we ALWAYS stream.
        res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
        res.setHeader('Cache-Control', 'no-cache');
        res.setHeader('Connection', 'keep-alive');

        // Build System Instruction
        const uniContext = await getUniversitiesContext();
        let systemPrompt = `Ты профессиональный AI-консультант по поступлению в вузы Казахстана "Tandau".
Отвечай вежливо, коротко и точно. Язык ответа: ${language === 'kk' ? 'Казахский' : 'Русский'}.

ПРАВИЛА И СТРОГИЕ ОГРАНИЧЕНИЯ (ВО ИЗБЕЖАНИЕ ГАЛЛЮЦИНАЦИЙ):
1. Никогда не выдумывай цены, проходные баллы или названия вузов.
2. Используй только данные, предоставленные ниже, или актуальные данные из Google Поиска.
3. Если пользователь спрашивает про вуз, которого нет в списке ниже, скажи "В моей базе нет этого вуза, но я могу поискать информацию в интернете" и используй поиск.

ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ (Учитывай ее при советах):
${userContext || 'Нет данных профиля.'}

ДАННЫЕ ИЗ БАЗЫ УНИВЕРСИТЕТОВ TANDAU:
${uniContext}
`;

        let tools = [];
        try {
           tools = [{ googleSearch: {} }]; // Enable Web Search Tool
        } catch (e) {
           console.log("googleSearch tool ignored, perhaps old SDK version.");
        }

        // Initialize Gemini with System Instruction and Tools
        const model = genAI.getGenerativeModel({
            model: "gemini-1.5-pro",
            systemInstruction: systemPrompt,
            tools: tools
        });

        // Format history for Gemini
        let formattedHistory = [];
        if (history && Array.isArray(history)) {
            formattedHistory = history.map(msg => ({
                // API expects role to be "user" or "model"
                role: msg.isUser ? "user" : "model",
                parts: [{ text: msg.text || "" }]
            }));
        }
        
        const chatSession = model.startChat({ history: formattedHistory });

        // Call the streaming API
        const resultStream = await chatSession.sendMessageStream(question);

        for await (const chunk of resultStream.stream) {
            const chunkText = chunk.text();
            if (chunkText) {
                // Send SSE formatted chunk
                res.write(`data: ${JSON.stringify({ answer: chunkText })}\n\n`);
            }
        }
        
        // Signal end of stream
        res.write(`data: [DONE]\n\n`);
        res.end();

    } catch (error) {
        console.error("Error generating content:", error);
        
        // If headers haven't been sent, send a JSON error
        if (!res.headersSent) {
            res.status(500).json({ error: "Failed to generate response from AI", details: error.message });
        } else {
            // If streaming has started, append error block and end
            res.write(`data: ${JSON.stringify({ answer: "\n[Ошибка связи с AI. Попробуйте еще раз]" })}\n\n`);
            res.write(`data: [DONE]\n\n`);
            res.end();
        }
    }
};

module.exports = {
    chat
};
