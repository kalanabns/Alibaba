import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/money_formatter.dart';

class KpiMetricCard extends StatelessWidget {
  const KpiMetricCard({
    super.key,
    required this.title,
    required this.amount,
    required this.currency,
    this.previousAmount,
    this.growth,
    this.subtitle,
    required this.icon,
    this.accentColor,
    this.isExpenseType = false,
  });

  final String title;
  final double amount;
  final String currency;
  final double? previousAmount;
  final double? growth;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final bool isExpenseType;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryColor;
    final formattedAmount = MoneyFormatter.format(
      amount,
      currency: currency,
      compact: amount.abs() >= 100000,
    );

    Color? growthColor;
    IconData? growthIcon;
    String? growthText;

    if (growth != null && !growth!.isNaN && !growth!.isInfinite) {
      final isPositive = growth! > 0;
      final isZero = growth! == 0;

      if (isZero) {
        growthColor = AppTheme.textSecondary;
        growthIcon = Icons.remove_rounded;
        growthText = '0.0%';
      } else if (isExpenseType) {
        // For expenses: growth is warning/danger, reduction is positive emerald!
        growthColor = isPositive ? AppTheme.errorColor : AppTheme.accentColor;
        growthIcon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
        growthText = '${isPositive ? '+' : ''}${growth!.toStringAsFixed(1)}%';
      } else {
        // For revenue/profit/cash: growth is positive emerald, drop is coral red!
        growthColor = isPositive ? AppTheme.accentColor : AppTheme.errorColor;
        growthIcon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
        growthText = '${isPositive ? '+' : ''}${growth!.toStringAsFixed(1)}%';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Title + Glowing Icon Container
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Amount
          Text(
            formattedAmount,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Growth Badge or Subtitle
          Row(
            children: [
              if (growthText != null &&
                  growthColor != null &&
                  growthIcon != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: growthColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(growthIcon, size: 12, color: growthColor),
                      const SizedBox(width: 3),
                      Text(
                        growthText,
                        style: TextStyle(
                          color: growthColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Flexible(
                  child: Text(
                    'vs prior',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else if (subtitle != null) ...[
                Flexible(
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                const Flexible(
                  child: Text(
                    'Current cycle',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
