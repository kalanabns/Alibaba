import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../alerts/domain/priority_ranking_engine.dart';
import '../../businesses/domain/business.dart';
import '../application/cfo_action_plan_controller.dart';
import '../domain/cfo_action_item.dart';

class CfoActionPlanScreen extends StatefulWidget {
  const CfoActionPlanScreen({
    super.key,
    required this.controller,
    required this.business,
    this.onExecuteAction,
  });

  final CfoActionPlanController controller;
  final Business business;
  final void Function(CfoActionItem item)? onExecuteAction;

  @override
  State<CfoActionPlanScreen> createState() => _CfoActionPlanScreenState();
}

class _CfoActionPlanScreenState extends State<CfoActionPlanScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            border: const Border(bottom: BorderSide(color: Color(0x3538BDF8), width: 1.2)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
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
                        child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CFO Action Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Prioritized Execution & Roadmap',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppTheme.primaryLight,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: [
                    Tab(text: 'Active (${widget.controller.pendingCount})'),
                    Tab(text: 'Completed (${widget.controller.completedCount})'),
                    const Tab(text: 'Dismissed'),
                    const Tab(text: 'Strategic Roadmap'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final items = widget.controller.actionItems;
          final activeItems = items.where((i) => i.isActive).toList();
          final completedItems = items.where((i) => i.isCompleted).toList();
          final dismissedItems = items.where((i) => i.isDismissed).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActionList(activeItems, 'No active action items. Your business operates with optimal signals.'),
              _buildActionList(completedItems, 'No completed action items yet.'),
              _buildActionList(dismissedItems, 'No dismissed items.'),
              _buildRoadmapView(widget.controller.roadmap),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionList(List<CfoActionItem> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.done_all_rounded, color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildActionCard(item);
      },
    );
  }

  Widget _buildActionCard(CfoActionItem item) {
    Color priorityColor;
    switch (item.priority) {
      case PriorityLevel.critical:
        priorityColor = AppTheme.errorColor;
        break;
      case PriorityLevel.high:
        priorityColor = const Color(0xFFEA580C);
        break;
      case PriorityLevel.medium:
        priorityColor = AppTheme.warningColor;
        break;
      case PriorityLevel.low:
      case PriorityLevel.informational:
        priorityColor = AppTheme.primaryLight;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: priorityColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              item.priority.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: priorityColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildStatusSelector(item),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.reason,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right_alt_rounded, color: AppTheme.primaryColor, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Next Step: ${item.recommendedNextStep}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onExecuteAction != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => widget.onExecuteAction!(item),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Execute Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSelector(CfoActionItem item) {
    return PopupMenuButton<CfoActionStatus>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.status.name.toUpperCase(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
      onSelected: (newStatus) {
        widget.controller.updateActionStatus(item.id, newStatus);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: CfoActionStatus.todo, child: Text('To Do')),
        const PopupMenuItem(value: CfoActionStatus.inProgress, child: Text('In Progress')),
        const PopupMenuItem(value: CfoActionStatus.completed, child: Text('Completed')),
        const PopupMenuItem(value: CfoActionStatus.dismissed, child: Text('Dismiss')),
      ],
    );
  }

  Widget _buildRoadmapView(MonthlyStrategicRoadmap? roadmap) {
    if (roadmap == null) {
      return const Center(child: Text('Generating strategic roadmap...', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildRoadmapSection('This Month\'s Strategic Priorities', roadmap.thisMonthPriorities, Icons.flag_rounded, AppTheme.primaryColor),
        const SizedBox(height: 20),
        _buildRoadmapSection('Next 30 Days Target Trajectory', roadmap.next30Days, Icons.calendar_today_rounded, AppTheme.accentColor),
        const SizedBox(height: 20),
        _buildRoadmapSection('Next 90 Days Expansion & Solvency', roadmap.next90Days, Icons.rocket_launch_rounded, AppTheme.cyberIndigo),
      ],
    );
  }

  Widget _buildRoadmapSection(String title, List<String> items, IconData icon, Color color) {
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
