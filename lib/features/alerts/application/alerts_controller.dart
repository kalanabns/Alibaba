import 'package:flutter/foundation.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../../transactions/domain/transaction.dart';
import '../data/alert_repository.dart';
import '../domain/alert.dart';
import '../domain/opportunity_engine.dart';
import '../domain/risk_engine.dart';

enum AlertsFilter { all, risks, opportunities, unread }

class AlertsController extends ChangeNotifier {
  AlertsController({AlertRepository? repository})
    : _repository = repository ?? AlertRepository();

  final AlertRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Alert> _alerts = [];
  AlertsFilter _selectedFilter = AlertsFilter.all;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Alert> get allAlerts => _alerts;
  AlertsFilter get selectedFilter => _selectedFilter;

  List<Alert> get filteredAlerts {
    switch (_selectedFilter) {
      case AlertsFilter.all:
        return _alerts;
      case AlertsFilter.risks:
        return _alerts.where((a) => a.isRisk).toList();
      case AlertsFilter.opportunities:
        return _alerts.where((a) => a.isOpportunity).toList();
      case AlertsFilter.unread:
        return _alerts.where((a) => !a.isRead).toList();
    }
  }

  List<Alert> get topRisks =>
      _alerts.where((a) => a.isRisk && !a.isRead).take(3).toList();

  List<Alert> get topOpportunities =>
      _alerts.where((a) => a.isOpportunity && !a.isRead).take(3).toList();

  int get unreadCount => _alerts.where((a) => !a.isRead).length;
  int get activeRisksCount =>
      _alerts.where((a) => a.isRisk && !a.isRead).length;
  int get activeOpportunitiesCount =>
      _alerts.where((a) => a.isOpportunity && !a.isRead).length;

  void setFilter(AlertsFilter filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  /// Evaluates Risk & Opportunity engines against current metrics and transactions,
  /// then synchronizes with Supabase.
  Future<void> evaluateAndSync({
    required String businessId,
    required FinancialMetric currentMetrics,
    FinancialMetric? previousMetrics,
    required List<Transaction> currentTransactions,
    double startingCash = 0.0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Run deterministic Risk Engine
      final evaluatedRisks = RiskEngine.evaluateRisks(
        businessId: businessId,
        currentMetrics: currentMetrics,
        previousMetrics: previousMetrics,
        currentTransactions: currentTransactions,
        startingCash: startingCash,
      );

      // 2. Run deterministic Opportunity Engine
      final evaluatedOpportunities = OpportunityEngine.evaluateOpportunities(
        businessId: businessId,
        currentMetrics: currentMetrics,
        previousMetrics: previousMetrics,
        currentTransactions: currentTransactions,
      );

      final combined = [...evaluatedRisks, ...evaluatedOpportunities];

      // 3. Persist and deduplicate in database
      _alerts = await _repository.syncAlerts(
        businessId: businessId,
        evaluatedAlerts: combined,
      );
    } catch (e) {
      _errorMessage = 'Failed to evaluate financial signals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a specific alert as read and updates local state.
  Future<void> markAsRead(String alertId) async {
    try {
      await _repository.markAsRead(alertId);
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to mark alert as read: $e';
      notifyListeners();
    }
  }

  /// Marks all alerts for this business as read.
  Future<void> markAllAsRead(String businessId) async {
    try {
      await _repository.markAllAsRead(businessId);
      _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to mark all alerts as read: $e';
      notifyListeners();
    }
  }
}
