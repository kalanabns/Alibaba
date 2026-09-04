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
      padding: const EdgeInsets.all(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.navyPrimary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: AppTheme.navyPrimary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(deltaIcon, size: 11, color: badgeText),
                    const SizedBox(width: 2),
                    Text(
                      formatDelta(deltaValue),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BASELINE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatVal(baselineValue),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppTheme.navyPrimary,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PROJECTED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatVal(projectedValue),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navyDeep,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
