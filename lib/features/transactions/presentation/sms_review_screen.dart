import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/money_formatter.dart';
import '../../../shared/widgets/finora_empty_state.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_loading_indicator.dart';
import '../../businesses/domain/business.dart';
import '../application/sms_ingestion_controller.dart';
import '../domain/sms_candidate.dart';
import '../domain/transaction.dart';

class SmsReviewScreen extends StatefulWidget {
  const SmsReviewScreen({
    super.key,
    required this.controller,
    required this.business,
    required this.existingTransactions,
  });

  final SmsIngestionController controller;
  final Business business;
  final List<Transaction> existingTransactions;

  @override
  State<SmsReviewScreen> createState() => _SmsReviewScreenState();
}

class _SmsReviewScreenState extends State<SmsReviewScreen> {
  String _selectedFilter = 'Pending';

  @override
  void initState() {
    super.initState();
    // Auto-scan on opening if empty
    if (widget.controller.candidates.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.scanInbox(
          businessId: widget.business.id,
          existingTransactions: widget.existingTransactions,
        );
      });
    }
  }

  List<SmsTransactionCandidate> _getFilteredCandidates() {
    final all = widget.controller.candidates;
    switch (_selectedFilter) {
      case 'Pending':
        return all.where((c) => c.isPending && !c.isDuplicate).toList();
      case 'High Confidence':
        return all.where((c) => c.isPending && c.isHighConfidence && !c.isDuplicate).toList();
      case 'Approved':
        return all.where((c) => c.isApproved).toList();
      case 'Duplicates':
        return all.where((c) => c.isDuplicate).toList();
      case 'Ignored':
        return all.where((c) => c.isIgnored).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isLoading = widget.controller.isLoading;
        final error = widget.controller.errorMessage;
        final filtered = _getFilteredCandidates();
        final pendingCount = widget.controller.pendingCandidates.length;
        final highConfCount = widget.controller.highConfidencePending.length;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMS Transactions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Android automated bank statement detection',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync_rounded, size: 20),
                tooltip: 'Scan SMS Inbox',
                onPressed: isLoading
                    ? null
                    : () => widget.controller.scanInbox(
                          businessId: widget.business.id,
                          existingTransactions: widget.existingTransactions,
                        ),
              ),
            ],
          ),
          body: Column(
            children: [
              // 40% Navy Accent Stats & Quick Actions Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStatPill('Pending', pendingCount, AppTheme.warningColor),
                        const SizedBox(width: 8),
                        _buildStatPill('High Confidence', highConfCount, AppTheme.primaryLight),
                        const SizedBox(width: 8),
                        _buildStatPill('Imported', widget.controller.approvedCandidates.length, AppTheme.primaryColor),
                        const Spacer(),
                        if (highConfCount > 0)
                          ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final count = await widget.controller.approveAllHighConfidence(
                                      businessId: widget.business.id,
                                      currency: widget.business.currency,
                                    );
                                    if (context.mounted && count > 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Imported $count SMS transactions successfully!'),
                                          backgroundColor: AppTheme.primaryColor,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.done_all_rounded, size: 14),
                            label: Text(
                              'Approve All ($highConfCount)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Pending',
                          'High Confidence',
                          'All (${widget.controller.candidates.length})',
                          'Approved',
                          'Duplicates (${widget.controller.duplicateCandidates.length})',
                          'Ignored',
                        ].map((filterName) {
                          final cleanName = filterName.split(' (').first;
                          final isSelected = _selectedFilter == cleanName;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(filterName),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedFilter = cleanName),
                              selectedColor: AppTheme.primaryNavy,
                              backgroundColor: AppTheme.surfaceElevated,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryNavy : AppTheme.borderColor,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // 60% White/Light Canvas Content Area
              Expanded(
                child: isLoading && widget.controller.candidates.isEmpty
                    ? const FinoraLoadingIndicator(
                        message: 'Scanning SMS inbox for bank transactions...',
                      )
                    : error != null && widget.controller.candidates.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: FinoraErrorView(
                          message: error,
                          onRetry: () => widget.controller.scanInbox(
                            businessId: widget.business.id,
                            existingTransactions: widget.existingTransactions,
                          ),
                        ),
                      )
                    : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: FinoraEmptyState(
                            icon: Icons.sms_outlined,
                            title: 'No SMS Transactions Found',
                            message: _selectedFilter == 'Pending'
                                ? 'No pending SMS transactions waiting for review. Tap the scan button to refresh your inbox.'
                                : 'No transactions in this category.',
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filtered.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            return _buildPrivacyCard();
                          }
                          final item = filtered[index];
                          return _buildCandidateCard(context, item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, SmsTransactionCandidate candidate) {
    final isIncome = candidate.transactionType == TransactionType.income;
    final isDuplicate = candidate.isDuplicate;
    final isApproved = candidate.isApproved;

    return Container(
      decoration: BoxDecoration(
        color: isApproved ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDuplicate
              ? AppTheme.warningColor.withValues(alpha: 0.5)
              : isApproved
                  ? AppTheme.borderColor
                  : candidate.isHighConfidence
                      ? AppTheme.primaryColor.withValues(alpha: 0.4)
                      : AppTheme.borderColor,
          width: candidate.isHighConfidence && candidate.isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type, Confidence Badge & Amount
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppTheme.primaryLight.withValues(alpha: 0.15)
                      : AppTheme.errorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isIncome ? AppTheme.primaryLight : AppTheme.errorColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.merchantName ?? candidate.senderAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${candidate.category} • ${candidate.accountMask ?? "SMS Direct"}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? "+" : "-"}${MoneyFormatter.format(candidate.amount, currency: widget.business.currency)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppTheme.primaryColor : AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDuplicate
                          ? AppTheme.warningColor.withValues(alpha: 0.15)
                          : isApproved
                              ? AppTheme.primaryLight.withValues(alpha: 0.15)
                              : candidate.isHighConfidence
                                  ? AppTheme.primaryLight.withValues(alpha: 0.15)
                                  : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isDuplicate
                          ? 'DUPLICATE'
                          : isApproved
                              ? 'IMPORTED'
                              : '${(candidate.confidence * 100).toInt()}% CONFIDENCE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDuplicate
                            ? AppTheme.warningColor
                            : isApproved
                                ? AppTheme.primaryLight
                                : candidate.isHighConfidence
                                    ? AppTheme.primaryLight
                                    : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Raw SMS snippet preview
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    candidate.rawBody,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Actions
          if (candidate.isPending && !candidate.isDuplicate)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => widget.controller.ignoreCandidate(candidate.id),
                  child: const Text(
                    'Ignore',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await widget.controller.approveCandidate(
                      businessId: widget.business.id,
                      currency: widget.business.currency,
                      candidate: candidate,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction imported successfully!'),
                          backgroundColor: AppTheme.primaryColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text('Approve & Import', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppTheme.primaryColor),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy & On-Device Processing',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Non-financial personal messages are discarded in memory and never stored or uploaded. Only transactions you approve are synced to your Finora workspace.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
