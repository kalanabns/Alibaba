import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../alerts/domain/alert.dart';
import '../../businesses/domain/business.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../../transactions/domain/transaction.dart';
import '../data/ai_cfo_repository.dart';
import '../domain/ai_conversation.dart';

class AICFOController extends ChangeNotifier {
  AICFOController({AICFORepository? repository})
    : _repository = repository ?? AICFORepository(),
      _sessionId = _generateUniqueId();

  final AICFORepository _repository;

  String _sessionId;
  List<AIConversation> _messages = [];
  bool _isLoading = false;
  bool _isGeneratingSummary = false;
  String? _errorMessage;
  String? _cachedDashboardSummary;

  String get sessionId => _sessionId;
  List<AIConversation> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isGeneratingSummary => _isGeneratingSummary;
  String? get errorMessage => _errorMessage;
  String? get cachedDashboardSummary => _cachedDashboardSummary;

  static String _generateUniqueId() {
    final rand = Random().nextInt(999999);
    return 'sess_${DateTime.now().millisecondsSinceEpoch}_$rand';
  }

  /// Loads message history for the current or specified session.
  Future<void> loadHistory({
    required String businessId,
    String? sessionId,
  }) async {
    if (sessionId != null) {
      _sessionId = sessionId;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _repository.getConversationHistory(
        businessId: businessId,
        sessionId: _sessionId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load conversation history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a user question or alert explanation prompt to the AI CFO.
  Future<void> sendMessage({
    required String message,
    required String businessId,
    Alert? alertContext,
    FinancialMetric? currentMetrics,
    Business? business,
    List<Alert>? activeAlerts,
    List<Transaction>? recentTransactions,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final userMessage = AIConversation(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      userId: '',
      sessionId: _sessionId,
      role: AIRole.user,
      message: trimmed,
      createdAt: DateTime.now(),
    );

    _messages = [..._messages, userMessage];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final replyText = await _repository.sendMessage(
        businessId: businessId,
        sessionId: _sessionId,
        message: trimmed,
        alertContext: alertContext,
        currentMetrics: currentMetrics,
        business: business,
        activeAlerts: activeAlerts,
        recentTransactions: recentTransactions,
      );

      final assistantMessage = AIConversation(
        id: 'msg_asst_${DateTime.now().millisecondsSinceEpoch}',
        businessId: businessId,
        userId: '',
        sessionId: _sessionId,
        role: AIRole.assistant,
        message: replyText,
        createdAt: DateTime.now(),
      );

      _messages = [..._messages, assistantMessage];
    } catch (e) {
      _errorMessage = 'AI CFO is currently unavailable: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates or returns the cached executive summary for the dashboard.
  Future<void> generateDashboardSummary({
    required String businessId,
    FinancialMetric? currentMetrics,
    Business? business,
    List<Alert>? activeAlerts,
    bool force = false,
  }) async {
    if (!force && _cachedDashboardSummary != null) return;

    _isGeneratingSummary = true;
    notifyListeners();

    try {
      final bName = business?.name ?? 'Your business';
      final health = currentMetrics?.healthScore?.toStringAsFixed(0) ?? '0';
      final profit = currentMetrics?.profit ?? 0.0;
      final margin = currentMetrics?.profitMargin.toStringAsFixed(1) ?? '0.0';
      final cashFlow = currentMetrics?.netCashFlow ?? 0.0;

      if (currentMetrics == null ||
          (currentMetrics.revenue == 0 && currentMetrics.expenses == 0)) {
        _cachedDashboardSummary =
            '$bName has initialized its workspace. Import transaction CSVs or add records to unlock automated AI CFO analysis.';
      } else if (profit >= 0 && cashFlow >= 0) {
        _cachedDashboardSummary =
            '$bName is in a healthy position with a Health Score of $health/100 and positive profit margin of $margin%. Operating cash flow is positive (\$${cashFlow.toStringAsFixed(2)}). Continue disciplined invoice collection to protect liquidity.';
      } else if (profit >= 0 && cashFlow < 0) {
        _cachedDashboardSummary =
            '$bName is profitable with a $margin% margin, but operating cash flow is tightening (-\$${(-cashFlow).toStringAsFixed(2)}). Focus on collecting outstanding receivables to rebuild cash buffer.';
      } else {
        _cachedDashboardSummary =
            '$bName experienced a net operating deficit this period (-\$${(-profit).toStringAsFixed(2)}). High priority should be placed on auditing overhead costs and accelerating invoice recovery.';
      }
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }

  /// Resets the conversation session.
  void resetSession(String businessId) {
    _sessionId = _generateUniqueId();
    _messages = [];
    _errorMessage = null;
    notifyListeners();
  }
}
