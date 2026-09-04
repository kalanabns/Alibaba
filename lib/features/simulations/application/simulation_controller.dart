import 'package:flutter/foundation.dart';
import '../../ai_cfo/data/ai_cfo_repository.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../../transactions/domain/transaction.dart';
import '../data/simulation_repository.dart';
import '../domain/simulation.dart';
import '../domain/simulation_engine.dart';

class SimulationController extends ChangeNotifier {
  SimulationController({
    SimulationRepository? repository,
    AICFORepository? aiRepository,
  }) : _repository = repository ?? SimulationRepository(),
       _aiRepository = aiRepository ?? AICFORepository();

  final SimulationRepository _repository;
  final AICFORepository _aiRepository;

  bool _isLoading = false;
  bool _isAiAnalyzing = false;
  String? _errorMessage;
  String? _aiFeedback;

  List<Simulation> _savedSimulations = [];
  SimulationResult? _currentResult;

  // Active scenario input state
  ScenarioType _selectedType = ScenarioType.revenueDelta;
  double _percentageDelta = 10.0;
  String? _targetCategory = 'Marketing';
  double _fixedAmountDelta = 3500.0;
  String _scenarioName = 'Revenue Expansion (+10%)';

  bool get isLoading => _isLoading;
  bool get isAiAnalyzing => _isAiAnalyzing;
  String? get errorMessage => _errorMessage;
  String? get aiFeedback => _aiFeedback;
  List<Simulation> get savedSimulations => _savedSimulations;
  SimulationResult? get currentResult => _currentResult;

  ScenarioType get selectedType => _selectedType;
  double get percentageDelta => _percentageDelta;
  String? get targetCategory => _targetCategory;
  double get fixedAmountDelta => _fixedAmountDelta;
  String get scenarioName => _scenarioName;

  void setScenarioType(ScenarioType type) {
    _selectedType = type;
    switch (type) {
      case ScenarioType.revenueDelta:
        _percentageDelta = 10.0;
        _scenarioName = 'Revenue Expansion (+10%)';
        break;
      case ScenarioType.expenseDelta:
        _percentageDelta = -10.0;
        _scenarioName = 'Expense Reduction (-10%)';
        break;
      case ScenarioType.categoryExpenseDelta:
        _percentageDelta = -20.0;
        _targetCategory = 'Marketing';
        _scenarioName = 'Reduce Marketing Spend (-20%)';
        break;
      case ScenarioType.pricingAdjustment:
        _percentageDelta = 5.0;
        _scenarioName = 'Pricing Increase (+5%)';
        break;
      case ScenarioType.headcountAddition:
        _fixedAmountDelta = 3500.0;
        _scenarioName = 'Hire New Full-Time Staff';
        break;
    }
    _aiFeedback = null;
    notifyListeners();
  }

  void setPercentageDelta(double val) {
    _percentageDelta = val;
    _aiFeedback = null;
    notifyListeners();
  }

  void setTargetCategory(String category) {
    _targetCategory = category;
    _aiFeedback = null;
    notifyListeners();
  }

  void setFixedAmountDelta(double amount) {
    _fixedAmountDelta = amount;
    _aiFeedback = null;
    notifyListeners();
  }

  void setScenarioName(String name) {
    _scenarioName = name;
    notifyListeners();
  }

  /// Evaluates simulation deterministically against baseline metrics.
  void runSimulation({
    required FinancialMetric baselineMetric,
    List<Transaction> transactions = const [],
  }) {
    final assumption = ScenarioAssumption(
      type: _selectedType,
      name: _scenarioName,
      description: _buildDescription(),
      percentageDelta: _percentageDelta,
      targetCategory: _targetCategory,
      fixedAmountDelta: _fixedAmountDelta,
    );

    _currentResult = SimulationEngine.simulate(
      baselineMetric: baselineMetric,
      assumption: assumption,
      transactions: transactions,
    );
    notifyListeners();
  }

  String _buildDescription() {
    switch (_selectedType) {
      case ScenarioType.revenueDelta:
        return 'Adjust total revenue by ${_percentageDelta >= 0 ? '+' : ''}${_percentageDelta.toStringAsFixed(1)}%';
      case ScenarioType.expenseDelta:
        return 'Adjust operating expenses by ${_percentageDelta >= 0 ? '+' : ''}${_percentageDelta.toStringAsFixed(1)}%';
      case ScenarioType.categoryExpenseDelta:
        return 'Adjust ${_targetCategory ?? 'Category'} spending by ${_percentageDelta >= 0 ? '+' : ''}${_percentageDelta.toStringAsFixed(1)}%';
      case ScenarioType.pricingAdjustment:
        return 'Adjust product/service pricing by ${_percentageDelta >= 0 ? '+' : ''}${_percentageDelta.toStringAsFixed(1)}%';
      case ScenarioType.headcountAddition:
        return 'Add new staff costing \$${_fixedAmountDelta.toStringAsFixed(0)}/month';
    }
  }

  /// Fetches saved simulations for the business.
  Future<void> loadSavedSimulations({required String businessId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _savedSimulations = await _repository.getSimulations(
        businessId: businessId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load saved simulations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists current simulation to Supabase.
  Future<bool> saveCurrentSimulation({
    required String businessId,
    required String userId,
  }) async {
    if (_currentResult == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final saved = await _repository.saveSimulation(
        businessId: businessId,
        userId: userId,
        name: _scenarioName,
        assumptions: _currentResult!.assumption.toJson(),
        baselineMetrics: _currentResult!.baselineToJson(),
        projectedMetrics: _currentResult!.projectedToJson(),
        aiAnalysis: _aiFeedback,
      );

      _savedSimulations.insert(0, saved);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save simulation: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Asks AI CFO to provide expert strategic trade-off analysis on current simulation.
  Future<void> requestAiAnalysis({
    required String businessId,
    required String businessName,
    required String industry,
  }) async {
    if (_currentResult == null) return;

    _isAiAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prompt =
          'Evaluate this What-If financial simulation for $businessName ($industry):\n'
          'Scenario: ${_currentResult!.assumption.name} (${_currentResult!.assumption.description})\n'
          'Baseline Revenue: \$${_currentResult!.baselineRevenue.toStringAsFixed(0)}, Baseline Profit: \$${_currentResult!.baselineProfit.toStringAsFixed(0)}, Margin: ${_currentResult!.baselineMargin.toStringAsFixed(1)}%, Health Score: ${_currentResult!.baselineHealthScore.toStringAsFixed(0)}\n'
          'Projected Revenue: \$${_currentResult!.projectedRevenue.toStringAsFixed(0)}, Projected Profit: \$${_currentResult!.projectedProfit.toStringAsFixed(0)}, Projected Margin: ${_currentResult!.projectedMargin.toStringAsFixed(1)}%, Projected Health Score: ${_currentResult!.projectedHealthScore.toStringAsFixed(0)}\n'
          'Profit Delta: \$${_currentResult!.profitDelta >= 0 ? '+' : ''}${_currentResult!.profitDelta.toStringAsFixed(0)}, Margin Delta: ${_currentResult!.marginDelta >= 0 ? '+' : ''}${_currentResult!.marginDelta.toStringAsFixed(1)}%\n'
          'Trade-offs: ${_currentResult!.tradeOffs.join('; ')}\n'
          'Please provide 2-3 concise, actionable strategic trade-offs and recommendations for the business owner.';

      final response = await _aiRepository.sendMessage(
        businessId: businessId,
        sessionId: 'sim-$businessId',
        message: prompt,
      );

      _aiFeedback = response;
    } catch (e) {
      _errorMessage = 'AI Trade-off analysis unavailable: $e';
    } finally {
      _isAiAnalyzing = false;
      notifyListeners();
    }
  }
}
