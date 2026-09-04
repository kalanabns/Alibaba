import 'package:flutter/foundation.dart';
import '../../alerts/domain/alert.dart';
import '../../alerts/domain/priority_ranking_engine.dart';
import '../../financial_health/domain/financial_goal.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../data/cfo_action_plan_repository.dart';
import '../domain/cfo_action_item.dart';

class CfoActionPlanController extends ChangeNotifier {
  CfoActionPlanController({CfoActionPlanRepository? repository})
      : _repository = repository ?? CfoActionPlanRepository();

  final CfoActionPlanRepository _repository;

  List<CfoActionItem> _actionItems = [];
  MonthlyStrategicRoadmap? _roadmap;
  bool _isLoading = false;
  String? _errorMessage;

  List<CfoActionItem> get actionItems => _actionItems;
  MonthlyStrategicRoadmap? get roadmap => _roadmap;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _actionItems.where((i) => i.isActive).length;
  int get completedCount => _actionItems.where((i) => i.isCompleted).length;

  void loadInMemoryActionItems(List<CfoActionItem> items, {MonthlyStrategicRoadmap? roadmap}) {
    _actionItems = List.from(items);
    _roadmap = roadmap;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadActionItems(String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _actionItems = await _repository.getActionItems(businessId);
    } catch (_) {
      _errorMessage = 'Failed to load action items.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateActionStatus(String id, CfoActionStatus newStatus) async {
    final index = _actionItems.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final updated = _actionItems[index].copyWith(
        status: newStatus,
        completedAt: newStatus == CfoActionStatus.completed ? DateTime.now() : null,
      );
      _actionItems[index] = updated;
      notifyListeners();

      await _repository.saveActionItem(updated);
    }
  }

  void generateRoadmap({
    required String businessId,
    required FinancialMetric? metric,
    required List<Alert> alerts,
    required List<FinancialGoal> goals,
  }) {
    _roadmap = MonthlyStrategicRoadmap.generateFromContext(
      businessId: businessId,
      metric: metric,
      alerts: alerts,
      goals: goals,
    );
    notifyListeners();
  }

  /// Syncs action items from deterministic prioritized issues so the owner always has actionable tasks
  void syncWithPrioritizedIssues({
    required String businessId,
    required List<PrioritizedFinancialIssue> prioritizedIssues,
    required FinancialMetric? metric,
    required List<Alert> activeAlerts,
    required List<FinancialGoal> goals,
  }) {
    _roadmap = MonthlyStrategicRoadmap.generate(
      metric: metric,
      activeAlerts: activeAlerts,
      goals: goals,
      businessId: businessId,
    );

    // Merge issues into action items if not already existing
    for (final issue in prioritizedIssues) {
      final existingIndex = _actionItems.indexWhere((item) => item.id == issue.id);
      if (existingIndex < 0) {
        final newItem = CfoActionItem(
          id: issue.id,
          businessId: businessId,
          title: issue.title,
          reason: issue.whyItMatters,
          priority: issue.priorityLevel,
          urgency: issue.urgency,
          relatedMetric: issue.sourceMetric,
          recommendedNextStep: issue.recommendedAction,
          actionType: issue.actionType,
          status: CfoActionStatus.todo,
          createdAt: DateTime.now(),
        );
        _actionItems.add(newItem);
      }
    }

    notifyListeners();
  }
}
