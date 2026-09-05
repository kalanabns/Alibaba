import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/money_formatter.dart';
import '../../businesses/domain/business.dart';
import '../application/financial_goals_controller.dart';
import '../domain/financial_goal.dart';
import '../domain/financial_metric.dart';

class FinancialGoalsScreen extends StatefulWidget {
  const FinancialGoalsScreen({
    super.key,
    required this.controller,
    required this.business,
    this.currentMetric,
    this.onAskAiAboutGoal,
    this.onNavigateToSimulations,
  });

  final FinancialGoalsController controller;
  final Business business;
  final FinancialMetric? currentMetric;
  final void Function(FinancialGoal goal)? onAskAiAboutGoal;
  final VoidCallback? onNavigateToSimulations;

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.currentMetric != null) {
      widget.controller.syncWithMetrics(widget.currentMetric!);
    }
  }

  void _showAddEditGoalDialog({FinancialGoal? initialGoal}) {
    final isEditing = initialGoal != null;
    final titleController = TextEditingController(text: initialGoal?.title ?? '');
    final targetController = TextEditingController(
      text: initialGoal != null ? initialGoal.targetValue.toStringAsFixed(0) : '',
    );
    GoalType selectedType = initialGoal?.goalType ?? GoalType.targetRevenue;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                isEditing ? 'Edit Financial Goal' : 'Create Financial Target',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Title',
                        hintText: 'e.g. Expand Gross Margin to 20%',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<GoalType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Goal Type'),
                      items: GoalType.values.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.label, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Value (${selectedType.defaultUnit})',
                        hintText: selectedType.defaultUnit == '%' ? 'e.g. 20' : 'e.g. 85000',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final target = double.tryParse(targetController.text) ?? 0.0;
                    final title = titleController.text.trim();
                    if (title.isEmpty || target <= 0) return;

                    double initialCurrent = 0.0;
                    if (widget.currentMetric != null) {
                      switch (selectedType) {
                        case GoalType.targetRevenue:
                          initialCurrent = widget.currentMetric!.revenue;
                          break;
                        case GoalType.targetProfitMargin:
                          initialCurrent = widget.currentMetric!.profitMargin;
                          break;
                        case GoalType.targetCashReserve:
                          initialCurrent = widget.currentMetric!.netCashFlow;
                          break;
                        case GoalType.expenseLimit:
                          initialCurrent = widget.currentMetric!.expenses;
                          break;
                        case GoalType.debtReduction:
                          initialCurrent = widget.currentMetric!.debt;
                          break;
                      }
                    }

                    widget.controller.saveGoal(
                      businessId: widget.business.id,
                      id: initialGoal?.id,
                      title: title,
                      goalType: selectedType,
                      targetValue: target,
                      currentValue: initialCurrent,
                      unit: selectedType.defaultUnit,
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: Text(isEditing ? 'Update Goal' : 'Save Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.business.currency;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            border: const Border(bottom: BorderSide(color: Color(0x3538BDF8), width: 1.2)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Goals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Target Tracking & AI Advisory',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    tooltip: 'Add Goal',
                    onPressed: () => _showAddEditGoalDialog(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final goals = widget.controller.goals;

          if (goals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_outlined, size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Financial Goals Configured',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set monthly revenue targets, margin thresholds, or expense limits to receive automated tracking and AI guidance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditGoalDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Set First Goal'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildGoalCard(goal, currency);
            },
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(FinancialGoal goal, String currency) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (goal.status) {
      case GoalStatus.achieved:
        statusColor = AppTheme.accentColor;
        statusLabel = 'ACHIEVED';
        statusIcon = Icons.check_circle_rounded;
        break;
      case GoalStatus.onTrack:
        statusColor = AppTheme.primaryLight;
        statusLabel = 'ON TRACK';
        statusIcon = Icons.trending_up_rounded;
        break;
      case GoalStatus.behindTarget:
        statusColor = AppTheme.warningColor;
        statusLabel = 'BEHIND TARGET';
        statusIcon = Icons.warning_amber_rounded;
        break;
    }

    final formattedCurrent = goal.unit == '%'
        ? '${goal.currentValue.toStringAsFixed(1)}%'
        : MoneyFormatter.format(goal.currentValue, currency: currency);

    final formattedTarget = goal.unit == '%'
        ? '${goal.targetValue.toStringAsFixed(1)}%'
        : MoneyFormatter.format(goal.targetValue, currency: currency);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textSecondary),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAddEditGoalDialog(initialGoal: goal);
                  } else if (val == 'delete') {
                    widget.controller.deleteGoal(goal.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Target')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Goal', style: TextStyle(color: AppTheme.errorColor))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goal.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.2),
          ),
          const SizedBox(height: 4),
          Text(
            goal.goalType.label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Actual', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(formattedCurrent, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Target Goal', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(formattedTarget, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (goal.progressRatio).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.borderColor.withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.onAskAiAboutGoal != null)
                TextButton.icon(
                  onPressed: () => widget.onAskAiAboutGoal!(goal),
                  icon: const Icon(Icons.psychology_rounded, size: 16),
                  label: const Text('Ask AI Advisor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              if (widget.onNavigateToSimulations != null)
                OutlinedButton.icon(
                  onPressed: widget.onNavigateToSimulations,
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  label: const Text('Simulate Path', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
