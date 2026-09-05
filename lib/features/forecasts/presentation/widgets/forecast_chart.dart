import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/money_formatter.dart';
import '../../../financial_health/domain/financial_engine.dart';
import '../../domain/forecast.dart';

class ForecastChart extends StatelessWidget {
  const ForecastChart({
    super.key,
    required this.historicalBuckets,
    required this.forecasts,
    required this.currency,
    required this.forecastType,
    required this.title,
    required this.accentColor,
  });

  final List<MonthlyFinancialBucket> historicalBuckets;
  final List<Forecast> forecasts;
  final String currency;
  final ForecastType forecastType;
  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final typeForecasts = forecasts
        .where((f) => f.forecastType == forecastType)
        .toList();

    if (historicalBuckets.isEmpty && typeForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Combine historical values + forecasts
    final historicalPoints = historicalBuckets.map((b) {
      double val = 0.0;
      switch (forecastType) {
        case ForecastType.revenue:
          val = b.revenue;
          break;
        case ForecastType.expenses:
          val = b.expenses;
          break;
        case ForecastType.cashFlow:
          val = b.netCashFlow;
          break;
        case ForecastType.cashBalance:
          val = b.netCashFlow;
          break;
      }
      return _ChartPoint(
        label: b.label.split(' ').first,
        value: val,
        isForecast: false,
      );
    }).toList();

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final forecastPoints = typeForecasts.map((f) {
      final label = monthNames[f.forecastDate.month - 1];
      return _ChartPoint(
        label: label,
        value: f.predictedValue,
        isForecast: true,
        lowerBound: f.lowerBound,
        upperBound: f.upperBound,
      );
    }).toList();

    final allPoints = [...historicalPoints, ...forecastPoints];

    double maxVal = 100.0;
    for (final p in allPoints) {
      maxVal = math.max(maxVal, p.value.abs());
      if (p.upperBound != null) {
        maxVal = math.max(maxVal, p.upperBound!.abs());
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem('Actual', accentColor, isDashed: false),
                  const SizedBox(width: 10),
                  _buildLegendItem(
                    'Forecast',
                    accentColor.withValues(alpha: 0.6),
                    isDashed: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: allPoints.map((point) {
                final ratio = (point.value / maxVal).clamp(0.0, 1.0);
                final isForecast = point.isForecast;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tooltip or Value label
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              MoneyFormatter.format(
                                point.value,
                                currency: currency,
                                compact: true,
                              ),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isForecast
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isForecast
                                    ? AppTheme.primaryNavy
                                    : AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Bar with distinction
                        Container(
                          width: 14,
                          height: math.max(4.0, 95.0 * ratio),
                          decoration: BoxDecoration(
                            color: isForecast
                                ? accentColor.withValues(alpha: 0.45)
                                : accentColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            border: isForecast
                                ? Border.all(color: accentColor, width: 1.2)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Month Label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              point.label,
                              style: TextStyle(
                                color: isForecast
                                    ? AppTheme.primaryNavy
                                    : AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: isForecast
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (isForecast)
                              const Text(
                                '*',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: isDashed
                ? Border.all(color: AppTheme.primaryNavy, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _ChartPoint {
  const _ChartPoint({
    required this.label,
    required this.value,
    required this.isForecast,
    this.lowerBound,
    this.upperBound,
  });

  final String label;
  final double value;
  final bool isForecast;
  final double? lowerBound;
  final double? upperBound;
}
