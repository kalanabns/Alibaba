import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/financial_engine.dart';

class RevenueExpensesChart extends StatelessWidget {
  const RevenueExpensesChart({
    super.key,
    required this.buckets,
    required this.currency,
  });

  final List<MonthlyFinancialBucket> buckets;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxVal = 100.0;
    for (final b in buckets) {
      maxVal = math.max(maxVal, math.max(b.revenue, b.expenses));
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
          // Header & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue vs Expenses',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('Revenue', AppTheme.accentColor),
                  const SizedBox(width: 12),
                  _buildLegendItem('Expenses', AppTheme.errorColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chart Canvas
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.map((bucket) {
                final revRatio = (bucket.revenue / maxVal).clamp(0.0, 1.0);
                final expRatio = (bucket.expenses / maxVal).clamp(0.0, 1.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bars Row
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Revenue Bar
                              Flexible(
                                child: Container(
                                  width: 14,
                                  height: math.max(4.0, 120.0 * revRatio),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              // Expense Bar
                              Flexible(
                                child: Container(
                                  width: 14,
                                  height: math.max(4.0, 120.0 * expRatio),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Month Label
                        Text(
                          bucket.label.split(' ').first,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
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

class CashFlowTrendChart extends StatelessWidget {
  const CashFlowTrendChart({
    super.key,
    required this.buckets,
    required this.currency,
  });

  final List<MonthlyFinancialBucket> buckets;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxNet = 100.0;
    for (final b in buckets) {
      maxNet = math.max(maxNet, b.netCashFlow.abs());
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Cash Flow Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Monthly Net Movement',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: buckets.map((bucket) {
                final isPositive = bucket.netCashFlow >= 0;
                final ratio = (bucket.netCashFlow.abs() / maxNet).clamp(
                  0.0,
                  1.0,
                );
                final color = isPositive
                    ? AppTheme.primaryLight
                    : AppTheme.errorColor;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top space / positive bar
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: isPositive
                                ? Container(
                                    width: 16,
                                    height: math.max(4.0, 50.0 * ratio),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        // Zero Baseline
                        Container(height: 1, color: AppTheme.borderColor),
                        // Bottom space / negative bar
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: !isPositive
                                ? Container(
                                    width: 16,
                                    height: math.max(4.0, 50.0 * ratio),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(4),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Month Label
                        Text(
                          bucket.label.split(' ').first,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
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
}
