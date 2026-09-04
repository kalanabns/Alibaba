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

    if (!business_id || !message) {
      return new Response(JSON.stringify({ error: "Missing required parameters" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const activeSessionId = (session_id && uuidRegex.test(session_id))
      ? session_id
      : crypto.randomUUID();

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
        session_id: activeSessionId,
        role: "user",
        message,
      },
      {
        business_id,
        user_id: user.id,
        session_id: activeSessionId,
        role: "assistant",
        message: assistantReply,
      },
    ]);

    return new Response(
      JSON.stringify({
        session_id: activeSessionId,
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
  const currency = b?.currency || "USD";
  const lowerMsg = message.toLowerCase();

  // 0. Insufficient Data Check
  if (!m || typeof m !== "object" || (m.revenue === 0 && m.expenses === 0)) {
    return `### What Happened
${b.name} workspace has insufficient financial records to compute reliable trends or projections.

### Why It Matters
Actionable decision support requires transaction baseline data to evaluate operating margins and cash burn velocity.

### What I Recommend
1. Import your recent bank statements via the **Transactions** tab.
2. Record at least 30 to 60 days of business inflows and disbursements.
3. Verify your baseline cash reserve in Business Settings.

**Priority**: HIGH`;
  }

  // 1. Alert Context Explanation
  if (alertContext) {
    return `### What Happened
${alertContext.description}

### Why It Matters
This signal directly impacts operating liquidity and profit stability for ${b.name}. When ${alertContext.title.toLowerCase()} persists, working capital becomes constrained.

### Top Risks
- Cash runway compression if collections lag behind disbursements.
- Unplanned debt reliance or emergency liquidity borrowing.

### Recommended Actions
1. ${alertContext.recommendation || "Review your high-expenditure categories and renegotiate vendor terms."}
2. Prioritize collecting overdue receivables before committing to new capital outlays.
3. Review your weekly cash outflow schedule against expected customer payments.

### Expected Impact & Urgency
- **Expected Impact**: Stabilizes monthly operating cash flow by reducing immediate burn.
- **Priority / Urgency**: ${alertContext.severity ? alertContext.severity.toUpperCase() : "HIGH"}`;
  }

  // 2. Hiring & Headcount Affordability
  if (lowerMsg.includes("hire") || lowerMsg.includes("staff") || lowerMsg.includes("employee") || lowerMsg.includes("payroll")) {
    const monthlyProfit = m.profit || 0;
    const monthlyCash = m.net_cash_flow || 0;
    const canAfford = monthlyProfit > 3000 && monthlyCash > 2000;

    return `### What Happened
${b.name} currently generates **$${currency} ${monthlyProfit.toFixed(2)}** in monthly profit and **$${currency} ${monthlyCash.toFixed(2)}** in net cash flow, with a composite Health Score of **${m.health_score || 0}/100**.

### Why It Matters
Adding new fixed payroll increases your monthly break-even threshold regardless of revenue volatility. A safe hiring decision requires at least 3-6 months of payroll reserve plus consistent positive operating cash flow.

### Top Risks
- New staff fixed expense could flip monthly cash flow into a deficit if sales fluctuate.
- Slower onboarding velocity delaying revenue contribution.

### Recommended Actions
1. ${canAfford ? "Your current cash flow supports a cautious hire. Set a strict total compensation ceiling (salary + taxes + benefits)." : "Delay full-time hiring until operating profit and cash collections consistently exceed $3,000/mo."}
2. Run a scenario in the **What-If Simulator** (+Hire Staff) to model the exact margin impact.
3. Consider contract or milestone-based talent first to protect baseline cash flow.

### Expected Impact & Urgency
- **Expected Impact**: Preserves liquidity while verifying revenue payback period.
- **Priority**: ${canAfford ? "MEDIUM" : "HIGH"}`;
  }

  // 3. Forward Cash & Forecast Questions
  if (lowerMsg.includes("next month") || lowerMsg.includes("forecast") || lowerMsg.includes("runway") || lowerMsg.includes("future cash") || lowerMsg.includes("how much cash")) {
    const cashFlow = m.net_cash_flow || 0;
    const isPositive = cashFlow >= 0;

    return `### What Happened
Historical net operating cash flow is running at **${isPositive ? "+" : ""}$${currency} ${cashFlow.toFixed(2)}** per month. Total receivables waiting to be collected stand at **$${currency} ${(m.receivables || 0).toFixed(2)}**.

### Why It Matters
Forward cash stability depends on maintaining positive operating cash flow and accelerating the velocity of invoice collections.

### Top Risks
- Delayed customer payments postponing expected cash receipts into subsequent periods.
- Lump-sum annual software or insurance renewals creating short-term liquidity dips.

### Recommended Actions
1. Review your 3-Month Projection in the **Forecasts** tab to examine best/worst-case cash trajectory.
2. Follow up on the **$${currency} ${(m.receivables || 0).toFixed(2)}** in pending invoices to secure immediate cash inflows.
3. Establish a rolling 13-week cash flow calendar to monitor weekly disbursement timing.

### Expected Impact & Urgency
- **Expected Impact**: Protects operating buffer and prevents unexpected working capital shortfalls.
- **Priority**: ${isPositive ? "MEDIUM" : "HIGH"}`;
  }

  // 4. Price Increase / What-If Scenario Questions
  if (lowerMsg.includes("increase price") || lowerMsg.includes("pricing") || lowerMsg.includes("what if") || lowerMsg.includes("price increase") || lowerMsg.includes("5%") || lowerMsg.includes("10%")) {
    const rev = m.revenue || 0;
    const fivePercentGain = rev * 0.05;

    return `### What Happened
${b.name} recorded **$${currency} ${rev.toFixed(2)}** in baseline revenue with a profit margin of **${m.profit_margin || "0.0%"}**. A 5% price adjustment would generate approximately **+$${currency} ${fivePercentGain.toFixed(2)}** in direct gross profit.

### Why It Matters
Because fixed operating costs remain constant, pricing power flows directly to bottom-line net profit and cash flow expansion.

### Top Risks
- Potential client churn if price increases are not paired with clear value communication.
- Competitor undercutting on standard service tiers.

### Recommended Actions
1. Model this scenario in the **What-If Simulator** to project exact margin expansion.
2. Roll out price revisions selectively to new client proposals before adjusting existing contracts.
3. Grandfather top long-term accounts on 12-month retainers to lock in predictable baseline revenue.

### Expected Impact & Urgency
- **Expected Impact**: Expands net profit margin with zero additional overhead.
- **Priority**: MEDIUM`;
  }

  // 5. Risks & Vulnerabilities
  if (lowerMsg.includes("risk") || lowerMsg.includes("danger") || lowerMsg.includes("concern") || lowerMsg.includes("threat")) {
    const isLoss = (m.profit || 0) < 0;
    const isNegativeCash = (m.net_cash_flow || 0) < 0;

    return `### What Happened
Your business is operating with a Health Score of **${m.health_score || 0}/100**. ${isLoss ? `Current net loss is -$${currency} ${Math.abs(m.profit).toFixed(2)}.` : `Net profit is $${currency} ${(m.profit || 0).toFixed(2)}.`} ${isNegativeCash ? `Net cash burn is -$${currency} ${Math.abs(m.net_cash_flow).toFixed(2)}.` : `Positive cash flow is $${currency} ${(m.net_cash_flow || 0).toFixed(2)}.`}

### Why It Matters
${isNegativeCash ? "Cash disbursements are outpacing collections, which will erode your liquid cash buffer if unchecked." : "Operating margins require active defense against compounding overhead and delayed receivables."}

### Top Risks
- Cash runway contraction if revenue contracts while fixed costs remain elevated.
- Overdue customer invoices turning into bad debt write-offs.

### Recommended Actions
1. Accelerate recovery of the **$${currency} ${(m.receivables || 0).toFixed(2)}** in pending customer receivables.
2. Conduct an immediate audit of recurring vendor subscriptions and overhead retainers.
3. Delay capital-intensive disbursements until monthly cash flow is solidly positive.

### Expected Impact & Urgency
- **Expected Impact**: Halts cash drainage and rebuilds working capital reserves.
- **Priority**: ${isLoss || isNegativeCash ? "CRITICAL" : "HIGH"}`;
  }

  // 6. Expense Optimization & Spending
  if (lowerMsg.includes("reduce") || lowerMsg.includes("expense") || lowerMsg.includes("cost") || lowerMsg.includes("spend") || lowerMsg.includes("overhead")) {
    return `### What Happened
Total operating expenses for this period are **$${currency} ${(m.expenses || 0).toFixed(2)}**, representing an expense growth rate of **${m.expense_growth || "0.0%"}**.

### Why It Matters
Controlling overhead is the fastest lever to boost your profit margin without needing immediate revenue expansion.

### Top Risks
- Creeping subscription overhead compounding unnoticed month-over-month.
- Vendor price escalations going unreviewed.

### Recommended Actions
1. Review your top 3 largest expense categories in the **Transactions** tab to identify renegotiation opportunities.
2. Audit recurring SaaS licenses, subscriptions, and retainers to eliminate unused seats.
3. Establish a pre-approval threshold for discretionary expenses above $250.

### Expected Impact & Urgency
- **Expected Impact**: Trims monthly operating overhead by 5-15%, directly boosting cash reserves.
- **Priority**: HIGH`;
  }

  // 7. Revenue Opportunities & Growth
  if (lowerMsg.includes("opportunity") || lowerMsg.includes("grow") || lowerMsg.includes("increase")) {
    return `### What Happened
${b.name} generated **$${currency} ${(m.revenue || 0).toFixed(2)}** in revenue with a profit margin of **${m.profit_margin || "0.0%"}**.

### Why It Matters
Expanding high-performing revenue lines while accelerating invoice collection velocity compounds your cash flow flywheel.

### Top Risks
- Over-allocating time and resources to low-margin or slow-paying customer accounts.

### Recommended Actions
1. Re-engage past high-margin clients with tailored upsell proposals.
2. Offer 2% discount terms for clients settling invoices within 7 days to accelerate cash collections.
3. Double down marketing investments on your highest-margin product or service categories.

### Expected Impact & Urgency
- **Expected Impact**: Accelerates cash inflow timing and elevates composite health score.
- **Priority**: MEDIUM`;
  }

  // 8. General Business Performance Overview
  return `### What Happened
${b.name} recorded **$${currency} ${(m.revenue || 0).toFixed(2)}** in revenue and **$${currency} ${(m.expenses || 0).toFixed(2)}** in expenses, resulting in a net profit of **$${currency} ${(m.profit || 0).toFixed(2)}** (Margin: **${m.profit_margin || "0.0%"}**). Your composite Financial Health Score is **${m.health_score || 0}/100**.

### Why It Matters
${(m.profit || 0) >= 0 ? "Your core operations are profitable, giving you stability to scale." : "Operating expenses exceed current revenue, creating pressure on working capital."}

### Top Risks
- ${(m.receivables || 0) > 0 ? `Uncollected receivables ($${currency} ${m.receivables.toFixed(2)}) delaying working capital availability.` : "Managing monthly fixed overhead against seasonal revenue fluctuations."}

### Recommended Actions
1. ${(m.receivables || 0) > 0 ? `Focus on collecting the $${currency} ${m.receivables.toFixed(2)} in pending customer payments.` : "Maintain tight oversight on recurring monthly operating overhead."}
2. Keep a 3-month cash buffer in reserve for unexpected market shifts.
3. Review your active alerts in the **Action Center** to tackle top bottlenecks.

### Expected Impact & Urgency
- **Expected Impact**: Protects core profitability and strengthens overall business financial resilience.
- **Priority**: ${(m.health_score || 100) < 60 ? "HIGH" : "MEDIUM"}`;
}
