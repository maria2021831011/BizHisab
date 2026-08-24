"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.aiAnalyze = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
// Groq API configuration - read from environment variable
// Set via .env file or Firebase environment config
const GROQ_API_KEY = process.env.GROQ_API_KEY || "";
async function getFinancialSummary(businessId) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);
    const currentMonthSnap = await db
        .collection(`businesses/${businessId}/transactions`)
        .where("date", ">=", admin.firestore.Timestamp.fromDate(startOfMonth))
        .get();
    const lastMonthSnap = await db
        .collection(`businesses/${businessId}/transactions`)
        .where("date", ">=", admin.firestore.Timestamp.fromDate(startOfLastMonth))
        .where("date", "<=", admin.firestore.Timestamp.fromDate(endOfLastMonth))
        .get();
    let monthlyIncome = 0;
    let monthlyExpense = 0;
    let lastMonthIncome = 0;
    let lastMonthExpense = 0;
    const topExpenses = {};
    currentMonthSnap.docs.forEach((doc) => {
        const data = doc.data();
        const amount = data.amount || 0;
        if (data.type === "income") {
            monthlyIncome += amount;
        }
        else {
            monthlyExpense += amount;
            topExpenses[data.category] = (topExpenses[data.category] || 0) + amount;
        }
    });
    lastMonthSnap.docs.forEach((doc) => {
        const data = doc.data();
        const amount = data.amount || 0;
        if (data.type === "income") {
            lastMonthIncome += amount;
        }
        else {
            lastMonthExpense += amount;
        }
    });
    return {
        monthlyIncome,
        monthlyExpense,
        profit: monthlyIncome - monthlyExpense,
        lastMonthIncome,
        lastMonthExpense,
        incomeChange: lastMonthIncome > 0
            ? ((monthlyIncome - lastMonthIncome) / lastMonthIncome) * 100
            : 0,
        expenseChange: lastMonthExpense > 0
            ? ((monthlyExpense - lastMonthExpense) / lastMonthExpense) * 100
            : 0,
        topExpenses,
    };
}
async function callGroqApi(prompt) {
    var _a, _b, _c;
    if (!GROQ_API_KEY) {
        throw new functions.https.HttpsError("failed-precondition", "AI service is not configured. Please contact support.");
    }
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${GROQ_API_KEY}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            model: "llama-3.3-70b-versatile",
            messages: [
                {
                    role: "system",
                    content: `You are BizHisab AI, a smart business finance assistant for Bangladeshi small businesses.
Analyze the financial data provided and give clear, actionable insights.
Support Bangla, Banglish, and English queries.
Always base your analysis on the actual numbers provided. Never invent numbers.
Format your response with clear sections: Observation, Reason, Recommendation.
Keep responses concise and practical.`,
                },
                {
                    role: "user",
                    content: prompt,
                },
            ],
            temperature: 0.7,
            max_tokens: 1024,
        }),
    });
    if (!response.ok) {
        const error = await response.text();
        console.error("Groq API error:", error);
        throw new functions.https.HttpsError("internal", "AI service temporarily unavailable. Please try again later.");
    }
    const data = await response.json();
    return ((_c = (_b = (_a = data.choices) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.message) === null || _c === void 0 ? void 0 : _c.content) || "No response generated.";
}
function buildAnalysisPrompt(type, summary, query) {
    var _a, _b;
    const summaryText = `
Financial Summary:
- Monthly Income: ৳${summary.monthlyIncome}
- Monthly Expense: ৳${summary.monthlyExpense}
- Net Profit: ৳${summary.profit}
- Last Month Income: ৳${summary.lastMonthIncome || 0}
- Last Month Expense: ৳${summary.lastMonthExpense || 0}
- Income Change: ${((_a = summary.incomeChange) === null || _a === void 0 ? void 0 : _a.toFixed(1)) || 0}%
- Expense Change: ${((_b = summary.expenseChange) === null || _b === void 0 ? void 0 : _b.toFixed(1)) || 0}%
- Top Expenses: ${JSON.stringify(summary.topExpenses || {})}
`;
    switch (type) {
        case "daily":
            return `${summaryText}\n\nProvide a brief daily financial insight. Focus on today's performance.`;
        case "weekly":
            return `${summaryText}\n\nProvide a weekly financial summary with key observations and actionable recommendations.`;
        case "monthly":
            return `${summaryText}\n\nProvide a comprehensive monthly financial analysis with observations, reasons for changes, and specific recommendations.`;
        case "expenseAnalysis":
            return `${summaryText}\n\nAnalyze the expense patterns. Identify the top spending categories, compare with last month, and provide recommendations to optimize spending.`;
        case "profitAnalysis":
            return `${summaryText}\n\nAnalyze the profit trends. Compare with last month, identify factors affecting profit, and suggest ways to improve.`;
        case "revenueTrend":
            return `${summaryText}\n\nAnalyze revenue trends. Compare current month with last month, identify growth or decline patterns, and provide insights.`;
        case "recommendation":
            return `${summaryText}\n\nBased on the financial data, provide 3-5 specific, actionable business recommendations for the Bangladeshi small business owner.`;
        case "chatbot":
            return `${summaryText}\n\nUser Question: ${query || "Analyze my business finances"}\n\nAnswer the user's question based on the financial data above. Be specific with numbers. Respond in the same language as the question (Bangla, Banglish, or English).`;
        default:
            return `${summaryText}\n\nProvide a general financial analysis.`;
    }
}
exports.aiAnalyze = functions.https.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "You must be authenticated to use AI features.");
    }
    const { businessId, type, query } = request.data;
    if (!businessId) {
        throw new functions.https.HttpsError("invalid-argument", "Business ID is required.");
    }
    try {
        const summary = await getFinancialSummary(businessId);
        const prompt = buildAnalysisPrompt(type, summary, query);
        const response = await callGroqApi(prompt);
        return { response };
    }
    catch (error) {
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        console.error("AI analysis error:", error);
        throw new functions.https.HttpsError("internal", "AI analysis failed. Please try again later.");
    }
});
//# sourceMappingURL=index.js.map