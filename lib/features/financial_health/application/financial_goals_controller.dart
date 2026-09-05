import 'package:flutter/foundation.dart';
import '../../../core/utilities/uuid_generator.dart';
import '../data/financial_goals_repository.dart';
import '../domain/financial_goal.dart';
import '../domain/financial_metric.dart';

class FinancialGoalsController extends ChangeNotifier {
  FinancialGoalsController({FinancialGoalsRepository? repository})
      : _repository = repository ?? FinancialGoalsRepository();

  final FinancialGoalsRepository _repository;

  List<FinancialGoal> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FinancialGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadInMemoryGoals(List<FinancialGoal> demoGoals) {
    _goals = List.from(demoGoals);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadGoals(String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _repository.getGoals(businessId);
    } catch (e) {
      _errorMessage = 'Failed to load financial goals.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveGoal({
    required String businessId,
    String? id,
    required String title,
    required GoalType goalType,
    required double targetValue,
    required double currentValue,
    required String unit,
    DateTime? targetDate,
  }) async {
    final goalId = id ?? UuidUtils.generate();
    final status = FinancialGoal.evaluateStatus(goalType, targetValue, currentValue);
    final now = DateTime.now();

    final goal = FinancialGoal(
      id: goalId,
      businessId: businessId,
      title: title,
      goalType: goalType,
      targetValue: targetValue,
      currentValue: currentValue,
      unit: unit,
      targetDate: targetDate,
      status: status,
      createdAt: now,
      updatedAt: now,
    );

    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index >= 0) {
      _goals[index] = goal;
    } else {
      _goals.insert(0, goal);
    }
    notifyListeners();

    await _repository.saveGoal(goal);
  }

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
    await _repository.deleteGoal(id);
  }

  /// Syncs goals with current financial metric to recalculate current values and statuses deterministically
  void syncGoalsWithMetrics(FinancialMetric metric, {double? startingCash}) {
    bool hasChanged = false;
    final updatedList = <FinancialGoal>[];

    for (final goal in _goals) {
      double newCurrent = goal.currentValue;
      switch (goal.goalType) {
        case GoalType.targetRevenue:
          newCurrent = metric.revenue;
          break;
        case GoalType.targetProfitMargin:
          newCurrent = metric.profitMargin;
          break;
        case GoalType.targetCashReserve:
          newCurrent = (startingCash ?? 0.0) + metric.netCashFlow;
          break;
        case GoalType.expenseLimit:
          newCurrent = metric.expenses;
          break;
        case GoalType.debtReduction:
          newCurrent = metric.debt;
          break;
      }

      final newStatus = FinancialGoal.evaluateStatus(goal.goalType, goal.targetValue, newCurrent);
      if (newCurrent != goal.currentValue || newStatus != goal.status) {
        hasChanged = true;
        updatedList.add(goal.copyWith(
          currentValue: newCurrent,
          status: newStatus,
          updatedAt: DateTime.now(),
        ));
      } else {
        updatedList.add(goal);
      }
    }

    if (hasChanged) {
      _goals = updatedList;
      notifyListeners();
    }
  }

  void syncWithMetrics(FinancialMetric metric, {double? startingCash}) {
    syncGoalsWithMetrics(metric, startingCash: startingCash);
  }
}
