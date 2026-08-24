import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

// Groq API configuration - read from environment variable
// Set via .env file or Firebase environment config
const GROQ_API_KEY = process.env.GROQ_API_KEY || "";

interface FinancialSummary {
  monthlyIncome: number;
  monthlyExpense: number;
  profit: number;
  lastMonthIncome?: number;
  lastMonthExpense?: number;
  incomeChange?: number;
  expenseChange?: number;
  topExpenses?: Record<string, number>;
}

async function getFinancialSummary(businessId: string): Promise<FinancialSummary> {
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
  const topExpenses: Record<string, number> = {};

  currentMonthSnap.docs.forEach((doc) => {
    const data = doc.data();
    const amount = data.amount || 0;
    if (data.type === "income") {
      monthlyIncome += amount;
    } else {
      monthlyExpense += amount;
      topExpenses[data.category] = (topExpenses[data.category] || 0) + amount;
    }
  });

  lastMonthSnap.docs.forEach((doc) => {
    const data = doc.data();
    const amount = data.amount || 0;
    if (data.type === "income") {
      lastMonthIncome += amount;
    } else {
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

async function callGroqApi(prompt: string): Promise<string> {
  if (!GROQ_API_KEY) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "AI service is not configured. Please contact support."
    );
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
    throw new functions.https.HttpsError(
      "internal",
      "AI service temporarily unavailable. Please try again later."
    );
  }

  const data = await response.json() as any;
  return data.choices?.[0]?.message?.content || "No response generated.";
}

function buildAnalysisPrompt(type: string, summary: FinancialSummary, query?: string): string {
  const summaryText = `
Financial Summary:
- Monthly Income: ৳${summary.monthlyIncome}
- Monthly Expense: ৳${summary.monthlyExpense}
- Net Profit: ৳${summary.profit}
- Last Month Income: ৳${summary.lastMonthIncome || 0}
- Last Month Expense: ৳${summary.lastMonthExpense || 0}
- Income Change: ${summary.incomeChange?.toFixed(1) || 0}%
- Expense Change: ${summary.expenseChange?.toFixed(1) || 0}%
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

export const aiAnalyze = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be authenticated to use AI features."
    );
  }

  const { businessId, type, query } = request.data;

  if (!businessId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Business ID is required."
    );
  }

  try {
    const summary = await getFinancialSummary(businessId);
    const prompt = buildAnalysisPrompt(type, summary, query);
    const response = await callGroqApi(prompt);

    return { response };
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error("AI analysis error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "AI analysis failed. Please try again later."
    );
  }
});
