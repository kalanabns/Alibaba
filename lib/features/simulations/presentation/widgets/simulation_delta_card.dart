import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SimulationDeltaCard extends StatelessWidget {
  const SimulationDeltaCard({
    super.key,
    required this.title,
    required this.baselineValue,
    required this.projectedValue,
    required this.deltaValue,
    required this.isCurrency,
    this.isPercentage = false,
    this.higherIsBetter = true,
    required this.icon,
  });

  final String title;
  final double baselineValue;
  final double projectedValue;
  final double deltaValue;
  final bool isCurrency;
  final bool isPercentage;
  final bool higherIsBetter;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isPositive = deltaValue > 0.001;
    final isNegative = deltaValue < -0.001;
    final isNeutral = !isPositive && !isNegative;

    Color badgeBg;
    Color badgeText;
    IconData deltaIcon;

    if (isNeutral) {
      badgeBg = Colors.grey.shade100;
      badgeText = AppTheme.textSecondary;
      deltaIcon = Icons.remove_rounded;
    } else if ((isPositive && higherIsBetter) ||
        (!isPositive && !higherIsBetter)) {
      badgeBg = const Color(0xFFE8F8F5);
      badgeText = AppTheme.tealAccent;
      deltaIcon = isPositive
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
    } else {
      badgeBg = const Color(0xFFFDEDEC);
      badgeText = AppTheme.coralRisk;
      deltaIcon = isPositive
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
    }

    String formatVal(double val) {
      if (isPercentage) {
        return '${val.toStringAsFixed(1)}%';
      } else if (isCurrency) {
        return '\$${val.abs().toStringAsFixed(0)}';
      }
      return val.toStringAsFixed(0);
    }

    String formatDelta(double val) {
      final sign = val > 0 ? '+' : (val < 0 ? '-' : '');
      if (isPercentage) {
        return '$sign${val.abs().toStringAsFixed(1)}%';
      } else if (isCurrency) {
        return '$sign\$${val.abs().toStringAsFixed(0)}';
      }
      return '$sign${val.abs().toStringAsFixed(0)} pts';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(icon, size: 14, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(deltaIcon, size: 9, color: badgeText),
                    const SizedBox(width: 2),
                    Text(
                      formatDelta(deltaValue),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BASE',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatVal(baselineValue),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'PROJ',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatVal(projectedValue),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
