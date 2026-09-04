import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/money_formatter.dart';
import '../../domain/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    this.onTap,
    this.onDelete,
  });

  final Transaction transaction;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final isTransfer = transaction.isTransfer;

    final Color badgeColor;
    final Color iconColor;
    final IconData iconData;
    final String amountPrefix;

    if (isIncome) {
      badgeColor = AppTheme.accentColor.withValues(alpha: 0.15);
      iconColor = AppTheme.accentColor;
      iconData = Icons.arrow_downward_rounded;
      amountPrefix = '+';
    } else if (isTransfer) {
      badgeColor = AppTheme.infoColor.withValues(alpha: 0.15);
      iconColor = AppTheme.infoColor;
      iconData = Icons.swap_horiz_rounded;
      amountPrefix = '';
    } else {
      badgeColor = AppTheme.errorColor.withValues(alpha: 0.15);
      iconColor = AppTheme.errorColor;
      iconData = Icons.arrow_upward_rounded;
      amountPrefix = '-';
    }

    final dateStr =
        '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}-${transaction.transactionDate.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Direction Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Title and Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.displayTitle,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppTheme.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              transaction.category,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (transaction.paymentStatus ==
                                  PaymentStatus.pending ||
                              transaction.paymentStatus ==
                                  PaymentStatus.overdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    transaction.paymentStatus ==
                                        PaymentStatus.overdue
                                    ? AppTheme.errorColor.withValues(alpha: 0.2)
                                    : AppTheme.warningColor.withValues(
                                        alpha: 0.2,
                                      ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                transaction.paymentStatus.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      transaction.paymentStatus ==
                                          PaymentStatus.overdue
                                      ? AppTheme.errorColor
                                      : AppTheme.warningColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix${MoneyFormatter.format(transaction.amount, currency: currency)}',
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (transaction.source == TransactionSource.csv) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'CSV Import',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
