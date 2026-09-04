import 'dart:math' as math;
import '../../alerts/domain/alert.dart';
import '../../financial_health/domain/financial_engine.dart';
import 'forecast.dart';

class ForecastEvaluation {
  const ForecastEvaluation({
    required this.isSufficient,
    required this.message,
    required this.forecasts,
    this.forecastRisks = const [],
    this.confidenceScore = 0.0,
    this.revenueForecastNextMonth,
    this.expensesForecastNextMonth,
    this.cashFlowForecastNextMonth,
    this.estimatedCashBalanceNextMonth,
    this.trendExplanation,
  });

  factory ForecastEvaluation.insufficient({
    String message =
        'Not enough historical data for a reliable forecast. At least 2 monthly periods required.',
  }) {
    return ForecastEvaluation(
      isSufficient: false,
      message: message,
      forecasts: const [],
      forecastRisks: const [],
      confidenceScore: 0.0,
      trendExplanation: message,
    );
  }

  final bool isSufficient;
  final String message;
  final List<Forecast> forecasts;
  final List<Alert> forecastRisks;
  final double confidenceScore;
  final double? revenueForecastNextMonth;
  final double? expensesForecastNextMonth;
  final double? cashFlowForecastNextMonth;
  final double? estimatedCashBalanceNextMonth;
  final String? trendExplanation;
}

class ForecastEngine {
  const ForecastEngine._();

  /// Deterministically generates forward-looking forecasts for Revenue, Expenses,
  /// Net Cash Flow, and Estimated Cash Balance based on historical monthly buckets.
  static ForecastEvaluation generateForecasts({
    required String businessId,
    required List<MonthlyFinancialBucket> historicalBuckets,
    double startingCash = 0.0,
    int forecastHorizonMonths = 3,
  }) {
    // 1. Data Sufficiency Check
    // Filter out buckets with zero activity if leading
    final activeBuckets = historicalBuckets
        .where((b) => b.revenue > 0 || b.expenses > 0)
        .toList();

    if (activeBuckets.length < 2) {
      return ForecastEvaluation.insufficient();
    }

    final n = activeBuckets.length;
    final now = DateTime.now().toUtc();

    // 2. Extract series
    final revenueSeries = activeBuckets.map((b) => b.revenue).toList();
    final expenseSeries = activeBuckets.map((b) => b.expenses).toList();
    final cashFlowSeries = activeBuckets.map((b) => b.netCashFlow).toList();

    // 3. Compute Deterministic Statistical Projections for each metric
    final revProj = _projectMetricSeries(revenueSeries, forecastHorizonMonths);
    final expProj = _projectMetricSeries(expenseSeries, forecastHorizonMonths);

    // Confidence Calculation based on sample size and variance
    final double confidence;
    if (n == 2) {
      confidence = 0.45;
    } else if (n == 3) {
      confidence = 0.60;
    } else {
      final meanRev = revenueSeries.reduce((a, b) => a + b) / n;
      final varianceRatio = meanRev > 0
          ? (revProj.standardError / meanRev)
          : 0.5;
      final rawConf = 0.70 + (0.04 * n) - (varianceRatio * 0.2);
      confidence = rawConf.clamp(0.50, 0.90);
    }

    // 4. Build Forecast records
    final forecasts = <Forecast>[];
    double runningCashBalance = startingCash;

    // Calculate current running cash balance up through historical periods
    for (final b in activeBuckets) {
      runningCashBalance += b.netCashFlow;
    }

    final lastBucket = activeBuckets.last;
    final forecastRisks = <Alert>[];

    for (int step = 1; step <= forecastHorizonMonths; step++) {
      int targetMonth = lastBucket.month + step;
      int targetYear = lastBucket.year;
      while (targetMonth > 12) {
        targetMonth -= 12;
        targetYear += 1;
      }
      final forecastDate = DateTime.utc(targetYear, targetMonth, 1);

      final predRevenue = math.max(0.0, revProj.predictions[step - 1]);
      final predExpenses = math.max(0.0, expProj.predictions[step - 1]);
      final predCashFlow = predRevenue - predExpenses;
      runningCashBalance += predCashFlow;

      // Revenue Forecast
      forecasts.add(
        Forecast(
          id: 'fc_rev_${businessId}_$step',
          businessId: businessId,
          forecastType: ForecastType.revenue,
          forecastDate: forecastDate,
          predictedValue: predRevenue,
          lowerBound: math.max(
            0.0,
            predRevenue -
                (1.28 * revProj.standardError * math.sqrt(1 + step * 0.2)),
          ),
          upperBound:
              predRevenue +
              (1.28 * revProj.standardError * math.sqrt(1 + step * 0.2)),
          confidence: confidence,
          modelVersion: '1.0.0-deterministic',
          createdAt: now,
        ),
      );

      // Expenses Forecast
      forecasts.add(
        Forecast(
          id: 'fc_exp_${businessId}_$step',
          businessId: businessId,
          forecastType: ForecastType.expenses,
          forecastDate: forecastDate,
          predictedValue: predExpenses,
          lowerBound: math.max(
            0.0,
            predExpenses -
                (1.28 * expProj.standardError * math.sqrt(1 + step * 0.2)),
          ),
          upperBound:
              predExpenses +
              (1.28 * expProj.standardError * math.sqrt(1 + step * 0.2)),
          confidence: confidence,
          modelVersion: '1.0.0-deterministic',
          createdAt: now,
        ),
      );

      // Net Cash Flow Forecast
      forecasts.add(
        Forecast(
          id: 'fc_cf_${businessId}_$step',
          businessId: businessId,
          forecastType: ForecastType.cashFlow,
          forecastDate: forecastDate,
          predictedValue: predCashFlow,
          lowerBound: predCashFlow - (1.28 * revProj.standardError),
          upperBound: predCashFlow + (1.28 * revProj.standardError),
          confidence: confidence,
          modelVersion: '1.0.0-deterministic',
          createdAt: now,
        ),
      );

      // Estimated Cash Balance Forecast
      forecasts.add(
        Forecast(
          id: 'fc_bal_${businessId}_$step',
          businessId: businessId,
          forecastType: ForecastType.cashBalance,
          forecastDate: forecastDate,
          predictedValue: runningCashBalance,
          lowerBound:
              runningCashBalance - (1.28 * revProj.standardError * step),
          upperBound:
              runningCashBalance + (1.28 * revProj.standardError * step),
          confidence: confidence,
          modelVersion: '1.0.0-deterministic',
          createdAt: now,
        ),
      );
    }

    // 5. Detect Forward-Looking Forecast Risk Signals
    final nextMonthRevenue = revProj.predictions.first;
    final nextMonthExpenses = expProj.predictions.first;
    final nextMonthCashFlow = nextMonthRevenue - nextMonthExpenses;
    final estimatedCashBalanceNextMonth =
        startingCash +
        cashFlowSeries.fold<double>(0.0, (a, b) => a + b) +
        nextMonthCashFlow;

    if (nextMonthCashFlow < 0) {
      forecastRisks.add(
        Alert(
          id: 'risk_forecast_cash_burn_$businessId',
          businessId: businessId,
          alertType: AlertType.risk,
          severity: estimatedCashBalanceNextMonth <= 0
              ? AlertSeverity.critical
              : AlertSeverity.high,
          title: 'Projected Operating Cash Deficit',
          description:
              'Forward-looking trend models project net cash flow of -\$${(-nextMonthCashFlow).toStringAsFixed(2)} next month (projected outflow \$${nextMonthExpenses.toStringAsFixed(2)} vs revenue \$${nextMonthRevenue.toStringAsFixed(2)}).',
          recommendation:
              'Build up liquid cash reserves and review scheduled recurring vendor commitments ahead of the upcoming cycle.',
          metricName: 'forecast_cash_flow',
          metricValue: nextMonthCashFlow,
          thresholdValue: 0.0,
          createdAt: now,
        ),
      );
    }

    if (revProj.slope < -0.10 && revenueSeries.last > 0) {
      forecastRisks.add(
        Alert(
          id: 'risk_forecast_revenue_decline_$businessId',
          businessId: businessId,
          alertType: AlertType.risk,
          severity: AlertSeverity.medium,
          title: 'Projected Revenue Contraction',
          description:
              'Based on recent trajectory, top-line revenue is projected to contract to ~\$${nextMonthRevenue.toStringAsFixed(2)} next month.',
          recommendation:
              'Implement customer retention incentives and initiate new pipeline outreach to stabilize sales volume.',
          metricName: 'forecast_revenue',
          metricValue: nextMonthRevenue,
          thresholdValue: revenueSeries.last,
          createdAt: now,
        ),
      );
    }

    // 6. Trend Narrative Explanation
    final trendExplanation = _generateTrendExplanation(
      activeBuckets: activeBuckets,
      revSlope: revProj.slope,
      expSlope: expProj.slope,
      nextMonthRev: nextMonthRevenue,
      confidence: confidence,
    );

    return ForecastEvaluation(
      isSufficient: true,
      message:
          'Generated forward-looking outlook with ${(confidence * 100).toStringAsFixed(0)}% confidence.',
      forecasts: forecasts,
      forecastRisks: forecastRisks,
      confidenceScore: confidence,
      revenueForecastNextMonth: nextMonthRevenue,
      expensesForecastNextMonth: nextMonthExpenses,
      cashFlowForecastNextMonth: nextMonthCashFlow,
      estimatedCashBalanceNextMonth: estimatedCashBalanceNextMonth,
      trendExplanation: trendExplanation,
    );
  }

  static _MetricProjection _projectMetricSeries(
    List<double> series,
    int horizon,
  ) {
    final n = series.length;
    if (n == 0) {
      return _MetricProjection(
        predictions: List.filled(horizon, 0.0),
        slope: 0.0,
        standardError: 0.0,
      );
    }

    if (n == 1) {
      return _MetricProjection(
        predictions: List.filled(horizon, series.first),
        slope: 0.0,
        standardError: series.first * 0.15,
      );
    }

    // Linear regression on time index (1..n)
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;

    for (int i = 0; i < n; i++) {
      final x = (i + 1).toDouble();
      final y = series[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Exponential Weighted Moving Average for recent baseline
    double ewma = series.first;
    const alpha = 0.6;
    for (int i = 1; i < n; i++) {
      ewma = alpha * series[i] + (1 - alpha) * ewma;
    }

    // Compute standard error / residual volatility
    double sumSquaredResiduals = 0;
    for (int i = 0; i < n; i++) {
      final x = (i + 1).toDouble();
      final fit = intercept + slope * x;
      final res = series[i] - fit;
      sumSquaredResiduals += res * res;
    }
    final standardError = math.sqrt(sumSquaredResiduals / math.max(1, n - 1));

    final predictions = <double>[];
    for (int step = 1; step <= horizon; step++) {
      final x = (n + step).toDouble();
      final linearVal = intercept + slope * x;
      // Blend linear trend with EWMA
      final blended = (linearVal * 0.55) + (ewma * 0.45) + (slope * step * 0.2);
      predictions.add(math.max(0.0, blended));
    }

    return _MetricProjection(
      predictions: predictions,
      slope: slope,
      standardError: math.max(50.0, standardError),
    );
  }

  static String _generateTrendExplanation({
    required List<MonthlyFinancialBucket> activeBuckets,
    required double revSlope,
    required double expSlope,
    required double nextMonthRev,
    required double confidence,
  }) {
    final n = activeBuckets.length;
    final confLabel = confidence >= 0.75
        ? 'High'
        : (confidence >= 0.55 ? 'Moderate' : 'Directional');

    if (revSlope > 100) {
      return 'Revenue has trended upward over the last $n reporting periods. The deterministic model projects continued positive trajectory into next month (~${(confidence * 100).toStringAsFixed(0)}% $confLabel confidence).';
    } else if (revSlope < -100) {
      return 'Revenue has experienced downward pressure across recent months. Forecast models anticipate top-line contraction unless sales velocity is reinforced.';
    } else {
      return 'Revenue and expense trajectories have remained relatively stable over the last $n months, indicating steady baseline operations heading into next month.';
    }
  }
}

class _MetricProjection {
  const _MetricProjection({
    required this.predictions,
    required this.slope,
    required this.standardError,
  });

  final List<double> predictions;
  final double slope;
  final double standardError;
}
