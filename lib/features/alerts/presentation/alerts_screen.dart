import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/finora_empty_state.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_loading_indicator.dart';
import '../../businesses/domain/business.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../application/alerts_controller.dart';
import '../domain/alert.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.controller,
    required this.businessId,
    this.business,
    this.currentMetrics,
    this.onAskAiAboutAlert,
  });

  final AlertsController controller;
  final String businessId;
  final Business? business;
  final FinancialMetric? currentMetrics;
  final void Function(Alert alert)? onAskAiAboutAlert;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isLoading = controller.isLoading;
        final error = controller.errorMessage;
        final alerts = controller.filteredAlerts;
        final checkIn = business != null
            ? controller.generateDailyCheckIn(
                business: business!,
                metric: currentMetrics,
              )
            : null;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              // 40% Navy Accent Header / Filter Toolbar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Action Center',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Proactive risk mitigation & strategic growth actions.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (controller.unreadCount > 0)
                          TextButton.icon(
                            onPressed: () =>
                                controller.markAllAsRead(businessId),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text(
                              'Mark all read',
                              style: TextStyle(fontSize: 12),
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
                          _buildFilterChip(
                            label: 'All (${controller.allAlerts.length})',
                            filter: AlertsFilter.all,
                          ),
                          if (controller.criticalCount > 0) ...[
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'Critical (${controller.criticalCount})',
                              filter: AlertsFilter.critical,
                              badgeColor: AppTheme.errorColor,
                            ),
                          ],
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Risks (${controller.activeRisksCount})',
                            filter: AlertsFilter.risks,
                            badgeColor: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label:
                                'Opportunities (${controller.activeOpportunitiesCount})',
                            filter: AlertsFilter.opportunities,
                            badgeColor: AppTheme.primaryLight,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Unread (${controller.unreadCount})',
                            filter: AlertsFilter.unread,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content List (60% White/Light Canvas)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Proactive "Finora Financial Check-in" Card
                    if (checkIn != null) ...[
                      _buildDailyCheckInCard(checkIn),
                      const SizedBox(height: 16),
                    ],

                    // Section Heading
                    Row(
                      children: [
                        const Text(
                          'Action Items & Signals',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Text(
                            '${alerts.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (isLoading && alerts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: FinoraLoadingIndicator(
                          message: 'Analyzing financial signals...',
                        ),
                      )
                    else if (error != null && alerts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: FinoraErrorView(message: error),
                      )
                    else if (alerts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: FinoraEmptyState(
                          icon: Icons.verified_user_outlined,
                          title: 'All Clear — No Active Signals',
                          message:
                              'Your financial metrics are operating safely within targets. New alerts will automatically appear here when risks or opportunities emerge.',
                        ),
                      )
                    else
                      ...alerts.map((alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildAlertCard(context, alert),
                          )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyCheckInCard(FinancialCheckIn checkIn) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppTheme.primaryLight,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Finora Financial Check-in',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'DAILY BRIEF',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Priority Item
          _buildCheckInRow(
            icon: Icons.priority_high_rounded,
            label: "TODAY'S PRIORITY",
            text: checkIn.priority,
            color: const Color(0xFFF87171),
          ),
          const SizedBox(height: 8),

          // Watch Item
          _buildCheckInRow(
            icon: Icons.visibility_outlined,
            label: 'WATCH',
            text: checkIn.watch,
            color: const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 8),

          // Opportunity Item
          _buildCheckInRow(
            icon: Icons.trending_up_rounded,
            label: 'OPPORTUNITY',
            text: checkIn.opportunity,
            color: AppTheme.primaryLight,
          ),
          const SizedBox(height: 8),

          // Action Item
          _buildCheckInRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'ACTION',
            text: checkIn.action,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInRow({
    required IconData icon,
    required String label,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, height: 1.35),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(color: Color(0xFFE2E8F0)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required AlertsFilter filter,
    Color? badgeColor,
  }) {
    final isSelected = controller.selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setFilter(filter),
      selectedColor: AppTheme.primaryNavy,
      backgroundColor: AppTheme.surfaceElevated,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryNavy : AppTheme.borderColor,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildAlertCard(BuildContext context, Alert alert) {
    final isRisk = alert.isRisk;
    final accentColor = alert.severityColor;

    return Container(
      decoration: BoxDecoration(
        color: alert.isRead ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.isRead
              ? AppTheme.borderColor
              : accentColor.withValues(alpha: 0.4),
          width: alert.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: alert.isRead
                ? Colors.black.withValues(alpha: 0.02)
                : accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Severity Badge + Time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRisk
                            ? Icons.warning_amber_rounded
                            : Icons.lightbulb_outline_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.severityLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!alert.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(alert.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              alert.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: alert.isRead
                    ? AppTheme.textPrimary
                    : AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              alert.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Recommendation Box
            if (alert.recommendation != null &&
                alert.recommendation!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.recommendation!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Action Buttons (60/40 design: distinct Navy/Emerald AI button)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!alert.isRead)
                  TextButton(
                    onPressed: () => controller.markAsRead(alert.id),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (!alert.isRead) {
                      controller.markAsRead(alert.id);
                    }
                    if (onAskAiAboutAlert != null) {
                      onAskAiAboutAlert!(alert);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRisk
                        ? AppTheme.primaryNavy
                        : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.psychology_outlined, size: 16),
                  label: const Text(
                    'Explain with AI CFO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dt.month}/${dt.day}';
    }
  }
}
