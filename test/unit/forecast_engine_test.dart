import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/financial_health/domain/financial_engine.dart';
import 'package:alibaba/features/forecasts/domain/forecast.dart';
import 'package:alibaba/features/forecasts/domain/forecast_engine.dart';

void main() {
  group('ForecastEngine — Deterministic Projections', () {
    test(
      'returns insufficient evaluation when fewer than 2 monthly buckets exist',
      () {
        final buckets = [
          const MonthlyFinancialBucket(
            year: 2026,
            month: 1,
            label: 'Jan 2026',
            revenue: 10000.0,
            expenses: 7000.0,
            profit: 3000.0,
            netCashFlow: 3000.0,
          ),
        ];

        final eval = ForecastEngine.generateForecasts(
          businessId: 'biz-1',
          historicalBuckets: buckets,
          startingCash: 5000.0,
        );

        expect(eval.isSufficient, false);
        expect(eval.forecasts, isEmpty);
        expect(eval.confidenceScore, 0.0);
      },
    );

    test(
      'generates 3-month forecast with linear trend and EWMA weighting on steady growth',
      () {
        final buckets = [
          const MonthlyFinancialBucket(
            year: 2025,
            month: 10,
            label: 'Oct 2025',
            revenue: 10000.0,
            expenses: 6000.0,
            profit: 4000.0,
            netCashFlow: 4000.0,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 11,
            label: 'Nov 2025',
            revenue: 11000.0,
            expenses: 6200.0,
            profit: 4800.0,
            netCashFlow: 4800.0,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 12,
            label: 'Dec 2025',
            revenue: 12000.0,
            expenses: 6500.0,
            profit: 5500.0,
            netCashFlow: 5500.0,
          ),
        ];

        final eval = ForecastEngine.generateForecasts(
          businessId: 'biz-1',
          historicalBuckets: buckets,
          startingCash: 10000.0,
          forecastHorizonMonths: 3,
        );

        expect(eval.isSufficient, true);
        // 3 months x 4 metrics (revenue, expenses, cashFlow, cashBalance) = 12 forecasts
        expect(eval.forecasts.length, 12);
        expect(eval.confidenceScore, greaterThanOrEqualTo(0.60));

        // Check next month single summary properties
        expect(eval.revenueForecastNextMonth, greaterThan(11500.0));
        expect(eval.expensesForecastNextMonth, greaterThan(6000.0));
        expect(eval.cashFlowForecastNextMonth, greaterThan(0.0));

        // Upper bound >= predicted >= lower bound
        for (final f in eval.forecasts) {
          if (f.upperBound != null && f.lowerBound != null) {
            expect(
              f.upperBound!,
              greaterThanOrEqualTo(f.predictedValue - 0.001),
            );
            expect(
              f.predictedValue + 0.001,
              greaterThanOrEqualTo(f.lowerBound!),
            );
          }
        }

        // Cash balance progression
        final cashBalances = eval.forecasts
            .where((f) => f.forecastType == ForecastType.cashBalance)
            .toList();
        expect(cashBalances.length, 3);
        expect(
          cashBalances.last.predictedValue,
          greaterThan(cashBalances.first.predictedValue),
        );
      },
    );

    test(
      'identifies runway depletion and risk alert when business experiences severe cash burn',
      () {
        final buckets = [
          const MonthlyFinancialBucket(
            year: 2025,
            month: 10,
            label: 'Oct 2025',
            revenue: 8000.0,
            expenses: 15000.0,
            profit: -7000.0,
            netCashFlow: -7000.0,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 11,
            label: 'Nov 2025',
            revenue: 7000.0,
            expenses: 16000.0,
            profit: -9000.0,
            netCashFlow: -9000.0,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 12,
            label: 'Dec 2025',
            revenue: 6000.0,
            expenses: 17000.0,
            profit: -11000.0,
            netCashFlow: -11000.0,
          ),
        ];

        final eval = ForecastEngine.generateForecasts(
          businessId: 'biz-2',
          historicalBuckets: buckets,
          startingCash: 15000.0,
          forecastHorizonMonths: 3,
        );

        expect(eval.isSufficient, true);
        expect(eval.forecasts.isNotEmpty, true);
        expect(eval.forecastRisks.isNotEmpty, true);
        expect(
          eval.forecastRisks.any(
            (r) =>
                r.title.toLowerCase().contains('runway') ||
                r.title.toLowerCase().contains('cash'),
          ),
          true,
        );
      },
    );

    test(
      'confidence score scales proportionally with more historical months',
      () {
        final shortHistory = [
          const MonthlyFinancialBucket(
            year: 2025,
            month: 11,
            label: 'Nov 2025',
            revenue: 10000,
            expenses: 5000,
            profit: 5000,
            netCashFlow: 5000,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 12,
            label: 'Dec 2025',
            revenue: 11000,
            expenses: 5200,
            profit: 5800,
            netCashFlow: 5800,
          ),
        ];

        final longHistory = [
          const MonthlyFinancialBucket(
            year: 2025,
            month: 7,
            label: 'Jul 2025',
            revenue: 9000,
            expenses: 4800,
            profit: 4200,
            netCashFlow: 4200,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 8,
            label: 'Aug 2025',
            revenue: 9500,
            expenses: 4900,
            profit: 4600,
            netCashFlow: 4600,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 9,
            label: 'Sep 2025',
            revenue: 10000,
            expenses: 5000,
            profit: 5000,
            netCashFlow: 5000,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 10,
            label: 'Oct 2025',
            revenue: 10500,
            expenses: 5100,
            profit: 5400,
            netCashFlow: 5400,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 11,
            label: 'Nov 2025',
            revenue: 11000,
            expenses: 5200,
            profit: 5800,
            netCashFlow: 5800,
          ),
          const MonthlyFinancialBucket(
            year: 2025,
            month: 12,
            label: 'Dec 2025',
            revenue: 11500,
            expenses: 5300,
            profit: 6200,
            netCashFlow: 6200,
          ),
        ];

        final evalShort = ForecastEngine.generateForecasts(
          businessId: 'biz-s',
          historicalBuckets: shortHistory,
        );

        final evalLong = ForecastEngine.generateForecasts(
          businessId: 'biz-l',
          historicalBuckets: longHistory,
        );

        expect(
          evalLong.confidenceScore,
          greaterThan(evalShort.confidenceScore),
        );
        expect(evalLong.confidenceScore, lessThanOrEqualTo(0.95));
      },
    );
  });
}
