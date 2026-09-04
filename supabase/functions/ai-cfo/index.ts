// Supabase Edge Function: ai-cfo
// Proxies AI CFO requests securely to Qoder Cloud Agents API / AI engine.
// Never exposes Qoder tokens to Flutter clients.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface AICFORequestBody {
  business_id: string;
  session_id: string;
  message: string;
  alert_context?: {
    title: string;
    description: string;
    recommendation?: string;
    severity?: string;
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? supabaseAnonKey;
    const qoderApiKey = Deno.env.get("QODER_ACCESS_TOKEN") ?? Deno.env.get("QODER_API_KEY") ?? "";
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY") ?? Deno.env.get("GOOGLE_API_KEY") ?? "";

    // 1. Authenticate user from JWT
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized user" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body: AICFORequestBody = await req.json();
    const { business_id, session_id, message, alert_context } = body;

    if (!business_id || !session_id || !message) {
      return new Response(JSON.stringify({ error: "Missing required parameters" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Verify business ownership
    const { data: business, error: bizError } = await supabase
      .from("businesses")
      .select("id, name, industry, country, currency, starting_cash")
      .eq("id", business_id)
      .eq("owner_id", user.id)
      .single();

    if (bizError || !business) {
      return new Response(JSON.stringify({ error: "Business not found or access denied" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Fetch latest metrics and active signals
    const { data: metrics } = await supabase
      .from("financial_metrics")
      .select("*")
      .eq("business_id", business_id)
      .order("period_end", { ascending: false })
      .limit(2);

    const currentMetric = metrics && metrics.length > 0 ? metrics[0] : null;

    const { data: activeAlerts } = await supabase
      .from("alerts")
      .select("title, alert_type, severity, description, recommendation")
      .eq("business_id", business_id)
      .eq("is_read", false)
      .limit(6);

    const { data: recentTransactions } = await supabase
      .from("transactions")
      .select("transaction_date, transaction_type, category, amount, payment_status, description")
      .eq("business_id", business_id)
      .order("transaction_date", { ascending: false })
      .limit(10);

    // 4. Assemble compact Financial Context Object
    const financialContext = {
      business: {
        name: business.name,
        industry: business.industry ?? "General",
        currency: business.currency ?? "USD",
        country: business.country ?? "US",
      },
      metrics: currentMetric
        ? {
            revenue: currentMetric.revenue,
            expenses: currentMetric.expenses,
            profit: currentMetric.profit,
            profit_margin: `${(currentMetric.profit_margin ?? 0).toFixed(1)}%`,
            cash_inflow: currentMetric.cash_inflow,
            cash_outflow: currentMetric.cash_outflow,
            net_cash_flow: currentMetric.net_cash_flow,
            receivables: currentMetric.receivables,
            payables: currentMetric.payables,
            revenue_growth: `${(currentMetric.revenue_growth ?? 0).toFixed(1)}%`,
            expense_growth: `${(currentMetric.expense_growth ?? 0).toFixed(1)}%`,
            health_score: currentMetric.health_score,
          }
        : "No periodic metrics calculated yet.",
      active_signals: activeAlerts ?? [],
      recent_transactions_sample: recentTransactions ?? [],
      focused_alert: alert_context ?? null,
    };

    // 5. System Instructions for Finora AI CFO
    const systemInstruction = `You are Finora AI CFO, a pragmatic, executive financial advisor for small and medium-sized business owners.
You help business owners understand their financial position, mitigate cash flow risks, capture opportunities, and make profitable decisions.

CRITICAL OPERATING RULES:
1. TRUTH IN METRICS: The provided deterministic metrics and transactions are your authoritative single source of truth. NEVER invent revenue, profit, costs, or transactions.
2. NO ARITHMETIC RECALCULATION: Explain the provided numbers accurately. Do not invent contradictory calculations.
3. STRUCTURED ADVICE: Whenever providing a recommendation or explaining a risk/performance change, structure your response as:
- **What Happened**: Clear, factual summary of the metric or trend.
- **Why It Matters**: Business impact (cash runway, margin pressure, working capital).
- **What I Recommend**: 2-3 specific, actionable steps the owner can take today.
- **Priority**: Critical / High / Medium / Low.
4. SIMPLE LANGUAGE: Speak clearly without unnecessary accounting jargon. Be encouraging, precise, and strategic.
5. DISCLAIMER: You are an AI financial advisor, not a CPA, auditor, or legal counsel.`;

    // 6. Call Live AI Engine (Gemini / Qoder)
    let assistantReply = "";

    if (geminiApiKey) {
      try {
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=${geminiApiKey}`;
        const geminiRes = await fetch(geminiUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            system_instruction: { parts: [{ text: systemInstruction }] },
            contents: [
              {
                role: "user",
                parts: [
                  {
                    text: `Financial Context:\n${JSON.stringify(financialContext, null, 2)}\n\nUser Question:\n${message}`,
                  },
                ],
              },
            ],
          }),
        });

        if (geminiRes.ok) {
          const geminiData = await geminiRes.json();
          assistantReply = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
        }
      } catch (_e) {
        // Fall through
      }
    }

    if (!assistantReply && qoderApiKey) {
      try {
        const qoderEndpoint = Deno.env.get("QODER_API_URL") || "https://api.qoder.ai/v1/agents/chat";
        const qoderRes = await fetch(qoderEndpoint, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${qoderApiKey}`,
          },
          body: JSON.stringify({
            model: "qoder-cfo-v1",
            system_instruction: systemInstruction,
            context: financialContext,
            messages: [{ role: "user", content: message }],
          }),
        });

        if (qoderRes.ok) {
          const qoderData = await qoderRes.json();
          assistantReply = qoderData.choices?.[0]?.message?.content || qoderData.response || qoderData.message;
        }
      } catch (_e) {
        // Fall through
      }
    }

    // Server-side deterministic fallback generator if external Qoder endpoint is unavailable
    if (!assistantReply) {
      assistantReply = generateGroundedAdvisoryResponse(message, financialContext, alert_context);
    }

    // 7. Persist turn in ai_conversations table
    const serviceClient = createClient(supabaseUrl, supabaseServiceKey);

    await serviceClient.from("ai_conversations").insert([
      {
        business_id,
        user_id: user.id,
        session_id,
        role: "user",
        message,
      },
      {
        business_id,
        user_id: user.id,
        session_id,
        role: "assistant",
        message: assistantReply,
      },
    ]);

    return new Response(
      JSON.stringify({
        session_id,
        reply: assistantReply,
        context_summary: {
          business_name: business.name,
          currency: business.currency,
          health_score: currentMetric?.health_score ?? 0,
        },
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({
        error: "AI CFO is temporarily unavailable. Your financial dashboard and alerts are still available.",
        details: String(err),
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

function generateGroundedAdvisoryResponse(message: string, context: any, alertContext: any): string {
  const m = context.metrics;
  const b = context.business;
  const lowerMsg = message.toLowerCase();

  if (alertContext) {
    return `### What Happened
${alertContext.description}

### Why It Matters
This signal directly impacts your operating liquidity and profit stability for ${b.name}. When ${alertContext.title.toLowerCase()} persists, it restricts your flexibility to reinvest or manage unexpected expenses.

### What I Recommend
1. ${alertContext.recommendation || "Review your high-expenditure categories and renegotiate vendor terms."}
2. Prioritize collecting outstanding customer invoices before committing to new capital outlays.
3. Review your weekly cash outflow schedule to align with customer payment cycles.

**Priority**: ${alertContext.severity ? alertContext.severity.toUpperCase() : "HIGH"}`;
  }

  if (lowerMsg.includes("risk") || lowerMsg.includes("danger") || lowerMsg.includes("concern")) {
    if (m && typeof m === "object") {
      const isLoss = m.profit < 0;
      const isNegativeCash = m.net_cash_flow < 0;
      return `### What Happened
Your business is operating with a Health Score of **${m.health_score}/100**. ${isLoss ? `Current net loss is -$${Math.abs(m.profit).toFixed(2)}.` : `Net profit is $${m.profit.toFixed(2)}.`} ${isNegativeCash ? `Net cash burn is -$${Math.abs(m.net_cash_flow).toFixed(2)}.` : `Positive cash flow is $${m.net_cash_flow.toFixed(2)}.`}

### Why It Matters
${isNegativeCash ? "Cash outflow is outpacing cash inflow, which will deplete your starting reserves if unaddressed." : "Top-line margins need continued defense against rising vendor costs."}

### What I Recommend
1. Accelerate recovery of the **$${m.receivables?.toFixed(2) || "0.00"}** in outstanding customer receivables.
2. Conduct an immediate audit of your recurring software subscriptions and discretionary services.
3. Delay non-critical disbursements until net operating cash flow turns solidly positive.

**Priority**: ${isLoss || isNegativeCash ? "HIGH" : "MEDIUM"}`;
    }
  }

  if (lowerMsg.includes("reduce") || lowerMsg.includes("expense") || lowerMsg.includes("cost")) {
    return `### What Happened
Total operating expenses for this period are **$${m?.expenses?.toFixed(2) || "0.00"}**, representing an expense growth rate of **${m?.expense_growth || "0.0%"}**.

### Why It Matters
Controlling overhead is the fastest lever to boost your profit margin without needing immediate revenue expansion.

### What I Recommend
1. Review your top 3 largest expense categories to identify contract renegotiation opportunities.
2. Audit recurring SaaS licenses, subscriptions, and retainers to eliminate unused seats.
3. Establish a pre-approval threshold for discretionary expenses above $250.

**Priority**: MEDIUM`;
  }

  if (lowerMsg.includes("opportunity") || lowerMsg.includes("grow") || lowerMsg.includes("increase")) {
    return `### What Happened
${b.name} generated **$${m?.revenue?.toFixed(2) || "0.00"}** in revenue with a profit margin of **${m?.profit_margin || "0.0%"}**.

### Why It Matters
Expanding high-performing revenue lines while accelerating invoice collection velocity compounds your cash flow flywheel.

### What I Recommend
1. Re-engage past high-margin clients with tailored upsell proposals.
2. Offer 2% discount terms for clients settling invoices within 7 days to accelerate cash collections.
3. Double down marketing investments on your highest-margin product or service categories.

**Priority**: MEDIUM`;
  }

  // General Business Performance Overview
  return `### What Happened
${b.name} recorded **$${m?.revenue?.toFixed(2) || "0.00"}** in revenue and **$${m?.expenses?.toFixed(2) || "0.00"}** in expenses, resulting in a net profit of **$${m?.profit?.toFixed(2) || "0.00"}** (Margin: **${m?.profit_margin || "0.0%"}**). Your composite Financial Health Score is **${m?.health_score || "0.0"}/100**.

### Why It Matters
${(m?.profit || 0) >= 0 ? "Your core operations are profitable, giving you stability to scale." : "Operating expenses exceed current revenue, creating pressure on working capital."}

### What I Recommend
1. ${m?.receivables > 0 ? `Focus on collecting the $${m.receivables.toFixed(2)} in pending customer payments.` : "Maintain tight oversight on recurring monthly operating overhead."}
2. Keep a 3-month cash buffer in reserve for unexpected market shifts.
3. Review your active alerts in the Signals tab to tackle top bottlenecks.

**Priority**: ${(m?.health_score || 100) < 60 ? "HIGH" : "MEDIUM"}`;
}
