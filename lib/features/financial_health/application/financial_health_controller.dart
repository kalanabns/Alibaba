import 'package:flutter/foundation.dart';
import '../../transactions/domain/transaction.dart';
import '../data/financial_metrics_repository.dart';
import '../domain/financial_engine.dart';
import '../domain/financial_metric.dart';
import '../domain/health_score_breakdown.dart';

enum FinancialPeriodRange {
  oneMonth('1M', 'This Month'),
  threeMonths('3M', 'Last 3 Months'),
  sixMonths('6M', 'Last 6 Months'),
  twelveMonths('12M', 'Last 12 Months');

  const FinancialPeriodRange(this.shortLabel, this.fullLabel);
  final String shortLabel;
  final String fullLabel;
}

class FinancialHealthController extends ChangeNotifier {
  FinancialHealthController({FinancialMetricsRepository? repository})
    : _repository = repository ?? FinancialMetricsRepository();

  final FinancialMetricsRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  FinancialPeriodRange _selectedPeriod = FinancialPeriodRange.oneMonth;

  FinancialMetric? _currentMetric;
  FinancialMetric? _previousMetric;
  HealthScoreBreakdown? _healthBreakdown;
  List<MonthlyFinancialBucket> _monthlyBuckets = [];
  bool _hasTransactions = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FinancialPeriodRange get selectedPeriod => _selectedPeriod;
  FinancialMetric? get currentMetric => _currentMetric;
  FinancialMetric? get previousMetric => _previousMetric;
  HealthScoreBreakdown? get healthBreakdown => _healthBreakdown;
  List<MonthlyFinancialBucket> get monthlyBuckets => _monthlyBuckets;
  bool get hasTransactions => _hasTransactions;

  void setPeriod(
    FinancialPeriodRange period, {
    required String businessId,
    required List<Transaction> allTransactions,
  }) {
    _selectedPeriod = period;
    recalculate(businessId: businessId, allTransactions: allTransactions);
  }

  Future<void> recalculate({
    required String businessId,
    required List<Transaction> allTransactions,
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _hasTransactions = allTransactions.isNotEmpty;

      final now = DateTime.now().toUtc();
      DateTime periodStart;
      DateTime periodEnd;
      DateTime prevStart;
      DateTime prevEnd;

      switch (_selectedPeriod) {
        case FinancialPeriodRange.oneMonth:
          periodStart = DateTime.utc(now.year, now.month, 1);
          periodEnd = DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59);

          final prevMonthYear = now.month == 1 ? now.year - 1 : now.year;
          final prevMonthVal = now.month == 1 ? 12 : now.month - 1;
          prevStart = DateTime.utc(prevMonthYear, prevMonthVal, 1);
          prevEnd = DateTime.utc(
            prevMonthYear,
            prevMonthVal + 1,
            0,
            23,
            59,
            59,
          );
          break;

        case FinancialPeriodRange.threeMonths:
          periodStart = DateTime.utc(now.year, now.month - 2, 1);
          periodEnd = DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59);

          prevStart = DateTime.utc(now.year, now.month - 5, 1);
          prevEnd = DateTime.utc(now.year, now.month - 2, 0, 23, 59, 59);
          break;

        case FinancialPeriodRange.sixMonths:
          periodStart = DateTime.utc(now.year, now.month - 5, 1);
          periodEnd = DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59);

          prevStart = DateTime.utc(now.year, now.month - 11, 1);
          prevEnd = DateTime.utc(now.year, now.month - 5, 0, 23, 59, 59);
          break;

        case FinancialPeriodRange.twelveMonths:
          periodStart = DateTime.utc(now.year - 1, now.month, 1);
          periodEnd = DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59);

          prevStart = DateTime.utc(now.year - 2, now.month, 1);
          prevEnd = DateTime.utc(now.year - 1, now.month, 0, 23, 59, 59);
          break;
      }

      final currentTransactions = FinancialEngine.filterTransactionsForPeriod(
        allTransactions,
        periodStart,
        periodEnd,
      );

      final prevTransactions = FinancialEngine.filterTransactionsForPeriod(
        allTransactions,
        prevStart,
        prevEnd,
      );

      final computedMetric = FinancialEngine.calculatePeriodMetrics(
        businessId: businessId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        currentTransactions: currentTransactions,
        previousTransactions: prevTransactions,
      );

      _healthBreakdown = FinancialEngine.calculateHealthScore(
        revenue: computedMetric.revenue,
        expenses: computedMetric.expenses,
        profit: computedMetric.profit,
        profitMargin: computedMetric.profitMargin,
        cashInflow: computedMetric.cashInflow,
        cashOutflow: computedMetric.cashOutflow,
        netCashFlow: computedMetric.netCashFlow,
        receivables: computedMetric.receivables,
        payables: computedMetric.payables,
        revenueGrowth: computedMetric.revenueGrowth,
        expenseGrowth: computedMetric.expenseGrowth,
        hasPreviousPeriod: prevTransactions.isNotEmpty,
      );

      if (prevTransactions.isNotEmpty) {
        _previousMetric = FinancialEngine.calculatePeriodMetrics(
          businessId: businessId,
          periodStart: prevStart,
          periodEnd: prevEnd,
          currentTransactions: prevTransactions,
        );
      } else {
        _previousMetric = null;
      }

      _currentMetric = computedMetric;

      // Build 6-month historical bucket trajectory for charts
      _monthlyBuckets = FinancialEngine.buildMonthlyBuckets(
        allTransactions,
        monthCount: _selectedPeriod == FinancialPeriodRange.twelveMonths
            ? 12
            : 6,
      );

      _isLoading = false;
      notifyListeners();

      // Persist to Supabase in background (fail gracefully if offline or mock)
      try {
        await _repository.upsertFinancialMetric(computedMetric);
      } catch (_) {
        // Non-blocking for local state
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
}
