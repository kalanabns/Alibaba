import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/money_formatter.dart';

class KpiMetricCard extends StatelessWidget {
  const KpiMetricCard({
    super.key,
    required this.title,
    required this.amount,
    required this.currency,
    this.growth,
    this.subtitle,
    required this.icon,
    this.accentColor,
    this.isExpenseType = false,
  });

  final String title;
  final double amount;
  final String currency;
  final double? growth;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final bool isExpenseType;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.textPrimary;
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
        growthIcon = Icons.remove;
        growthText = '0.0%';
      } else if (isExpenseType) {
        // For expenses: growth is warning/danger, reduction is positive emerald!
        growthColor = isPositive ? AppTheme.errorColor : AppTheme.accentColor;
        growthIcon = isPositive ? Icons.trending_up : Icons.trending_down;
        growthText = '${isPositive ? '+' : ''}${growth!.toStringAsFixed(1)}%';
      } else {
        // For revenue/profit/cash: growth is positive emerald, drop is coral red!
        growthColor = isPositive ? AppTheme.accentColor : AppTheme.errorColor;
        growthIcon = isPositive ? Icons.trending_up : Icons.trending_down;
        growthText = '${isPositive ? '+' : ''}${growth!.toStringAsFixed(1)}%';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Icon + Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
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
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
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
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: growthColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(growthIcon, size: 11, color: growthColor),
                      const SizedBox(width: 2),
                      Text(
                        growthText,
                        style: TextStyle(
                          color: growthColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    'vs prev',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                const Flexible(
                  child: Text(
                    'Current period',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
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
