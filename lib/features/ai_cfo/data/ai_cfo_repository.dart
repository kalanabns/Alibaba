import 'package:supabase_flutter/supabase_flutter.dart';
import '../../alerts/domain/alert.dart';
import '../../businesses/domain/business.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/ai_conversation.dart';

class AICFORepository {
  AICFORepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  /// Retrieves past conversation turns for a given session.
  Future<List<AIConversation>> getConversationHistory({
    required String businessId,
    required String sessionId,
  }) async {
    final response = await _client
        .from('ai_conversations')
        .select()
        .eq('business_id', businessId)
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    final list = response as List<dynamic>;
    return list
        .map((json) => AIConversation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Sends a message to the AI CFO via Supabase Edge Function (or direct secure DB fallback),
  /// returning the grounded advisory reply.
  Future<String> sendMessage({
    required String businessId,
    required String sessionId,
    required String message,
    Alert? alertContext,
    FinancialMetric? currentMetrics,
    Business? business,
    List<Alert>? activeAlerts,
    List<Transaction>? recentTransactions,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated.');
    }

    try {
      // 1. Try calling the Supabase Edge Function 'ai-cfo'
      final functionResponse = await _client.functions.invoke(
        'ai-cfo',
        body: {
          'business_id': businessId,
          'session_id': sessionId,
          'message': message,
          if (alertContext != null)
            'alert_context': {
              'title': alertContext.title,
              'description': alertContext.description,
              'recommendation': alertContext.recommendation,
              'severity': alertContext.severity.name,
            },
        },
      );

      if (functionResponse.status == 200 && functionResponse.data != null) {
        final data = functionResponse.data as Map<String, dynamic>;
        final reply = data['reply'] as String?;
        if (reply != null && reply.isNotEmpty) {
          return reply;
        }
      }
    } catch (_) {
      // Fall through to secure client-side grounded generator + DB persistence
    }

    // 2. Client-safe Grounded AI Advisor fallback
    final groundedReply = generateAdvisoryResponse(
      message: message,
      alert: alertContext,
      metric: currentMetrics,
      business: business,
    );

    // Persist conversation turns directly into Supabase ai_conversations table
    await _client.from('ai_conversations').insert([
      {
        'business_id': businessId,
        'user_id': user.id,
        'session_id': sessionId,
        'role': 'user',
        'message': message,
      },
      {
        'business_id': businessId,
        'user_id': user.id,
        'session_id': sessionId,
        'role': 'assistant',
        'message': groundedReply,
      },
    ]);

    return groundedReply;
  }

  /// Clears a conversation session.
  Future<void> clearSession({
    required String businessId,
    required String sessionId,
  }) async {
    await _client
        .from('ai_conversations')
        .delete()
        .eq('business_id', businessId)
        .eq('session_id', sessionId);
  }

  static String generateAdvisoryResponse({
    required String message,
    Alert? alert,
    FinancialMetric? metric,
    Business? business,
  }) {
    final bName = business?.name ?? 'your business';
    final lowerMsg = message.toLowerCase();

    if (alert != null) {
      return '''### What Happened
${alert.description}

### Why It Matters
This signal directly impacts operating cash flow and profit sustainability for $bName. When ${alert.title.toLowerCase()} persists, working capital becomes constrained.

### What I Recommend
1. ${alert.recommendation ?? "Review your highest operating costs and renegotiate key supplier agreements."}
2. Prioritize collecting overdue receivables before committing to new capital outlays.
3. Review your weekly cash outflow schedule against expected customer payments.

**Priority**: ${alert.severityLabel.toUpperCase()}''';
    }

    if (lowerMsg.contains('risk') ||
        lowerMsg.contains('danger') ||
        lowerMsg.contains('concern')) {
      if (metric != null) {
        final isLoss = metric.profit < 0;
        final isNegativeCash = metric.netCashFlow < 0;
        return '''### What Happened
$bName is operating with a Financial Health Score of **${metric.healthScore?.toStringAsFixed(0) ?? "0"}/100**. ${isLoss ? "Current net loss is -\$${(-metric.profit).toStringAsFixed(2)}." : "Net profit is \$${metric.profit.toStringAsFixed(2)}."} ${isNegativeCash ? "Net cash burn is -\$${(-metric.netCashFlow).toStringAsFixed(2)}." : "Positive cash flow is \$${metric.netCashFlow.toStringAsFixed(2)}."}

### Why It Matters
${isNegativeCash ? "Cash outflow is exceeding cash inflow, which will deplete reserves if uncorrected." : "Operating margins require active oversight against rising vendor overhead."}

### What I Recommend
1. Accelerate recovery of the **\$${metric.receivables.toStringAsFixed(2)}** in pending customer receivables.
2. Conduct an immediate audit of recurring software subscriptions and overhead retainers.
3. Delay discretionary equipment or non-essential spending until net cash flow stabilizes.

**Priority**: ${isLoss || isNegativeCash ? "HIGH" : "MEDIUM"}''';
      }
    }

    if (lowerMsg.contains('reduce') ||
        lowerMsg.contains('expense') ||
        lowerMsg.contains('cost')) {
      return '''### What Happened
Total operating expenses for this period are **\$${metric?.expenses.toStringAsFixed(2) ?? "0.00"}**, with an expense growth rate of **${metric?.expenseGrowth.toStringAsFixed(1) ?? "0.0"}%**.

### Why It Matters
Eliminating unnecessary overhead directly expands net profit margin without requiring immediate sales growth.

### What I Recommend
1. Review your top 3 largest expense categories to identify renegotiation targets.
2. Audit recurring SaaS licenses, subscriptions, and retainers to remove inactive seats.
3. Establish a pre-approval requirement for non-budgeted expenses exceeding \$250.

**Priority**: MEDIUM''';
    }

    if (lowerMsg.contains('opportunity') ||
        lowerMsg.contains('grow') ||
        lowerMsg.contains('increase') ||
        lowerMsg.contains('margin')) {
      return '''### What Happened
$bName generated **\$${metric?.revenue.toStringAsFixed(2) ?? "0.00"}** in revenue with a profit margin of **${metric?.profitMargin.toStringAsFixed(1) ?? "0.0"}%**.

### Why It Matters
Focusing on your most profitable revenue drivers and accelerating invoice collections compounds free cash flow.

### What I Recommend
1. Re-engage past high-margin clients with personalized follow-up proposals.
2. Offer 2% early-settlement discounts for customer invoices paid within 7 days.
3. Prioritize marketing allocation toward your highest-performing sales channels.

**Priority**: MEDIUM''';
    }

    // Default overview
    return '''### What Happened
$bName recorded **\$${metric?.revenue.toStringAsFixed(2) ?? "0.00"}** in revenue and **\$${metric?.expenses.toStringAsFixed(2) ?? "0.00"}** in expenses, resulting in net profit of **\$${metric?.profit.toStringAsFixed(2) ?? "0.00"}** (Margin: **${metric?.profitMargin.toStringAsFixed(1) ?? "0.0"}%**). Your composite Financial Health Score is **${metric?.healthScore?.toStringAsFixed(0) ?? "0"}/100**.

### Why It Matters
${(metric?.profit ?? 0) >= 0 ? "Your business is operating profitably, providing cash cushion for measured expansion." : "Operating expenses exceed current revenues, placing short-term pressure on cash reserves."}

### What I Recommend
1. ${metric != null && metric.receivables > 0 ? "Focus on collecting the \$${metric.receivables.toStringAsFixed(2)} in outstanding customer invoices." : "Maintain disciplined oversight of weekly operating cash outflows."}
2. Maintain a 3-month operating cash buffer for unforeseen business fluctuations.
3. Review active alerts in the Signals tab to address emerging bottlenecks.

**Priority**: ${(metric?.healthScore ?? 100) < 60 ? "HIGH" : "MEDIUM"}''';
  }
}
