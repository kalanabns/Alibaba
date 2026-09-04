import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../businesses/domain/business.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../../transactions/application/transaction_controller.dart';
import '../application/simulation_controller.dart';
import '../domain/simulation_engine.dart';
import 'widgets/simulation_delta_card.dart';

class SimulationsScreen extends StatefulWidget {
  const SimulationsScreen({
    super.key,
    required this.business,
    required this.transactionsController,
    required this.currentMetric,
    this.initialScenarioType,
    this.initialPercentageDelta,
    this.initialTargetCategory,
    this.initialFixedAmountDelta,
    this.initialScenarioName,
  });

  final Business business;
  final TransactionController transactionsController;
  final FinancialMetric? currentMetric;
  final ScenarioType? initialScenarioType;
  final double? initialPercentageDelta;
  final String? initialTargetCategory;
  final double? initialFixedAmountDelta;
  final String? initialScenarioName;

  @override
  State<SimulationsScreen> createState() => _SimulationsScreenState();
}

class _SimulationsScreenState extends State<SimulationsScreen> {
  late final SimulationController _controller;

  final List<String> _categories = [
    'Marketing',
    'Software',
    'Payroll',
    'Rent',
    'Contractors',
    'Inventory',
    'Utilities',
    'Travel',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _controller = SimulationController();
    _controller.addListener(_onControllerUpdate);

    if (widget.initialScenarioType != null) {
      _controller.setScenarioType(widget.initialScenarioType!);
    }
    if (widget.initialPercentageDelta != null) {
      _controller.setPercentageDelta(widget.initialPercentageDelta!);
    }
    if (widget.initialTargetCategory != null) {
      _controller.setTargetCategory(widget.initialTargetCategory!);
    }
    if (widget.initialFixedAmountDelta != null) {
      _controller.setFixedAmountDelta(widget.initialFixedAmountDelta!);
    }
    if (widget.initialScenarioName != null) {
      _controller.setScenarioName(widget.initialScenarioName!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runCurrentSimulation();
      _controller.loadSavedSimulations(businessId: widget.business.id);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _runCurrentSimulation() {
    final now = DateTime.now();
    final metric =
        widget.currentMetric ??
        FinancialMetric(
          id: 'placeholder',
          businessId: 'placeholder',
          periodStart: now.subtract(const Duration(days: 30)),
          periodEnd: now,
          revenue: 10000.0,
          expenses: 7000.0,
          profit: 3000.0,
          profitMargin: 30.0,
          cashInflow: 10000.0,
          cashOutflow: 7000.0,
          netCashFlow: 3000.0,
          receivables: 0.0,
          payables: 0.0,
          healthScore: 65.0,
          createdAt: now,
          updatedAt: now,
        );

    _controller.runSimulation(
      baselineMetric: metric,
      transactions: widget.transactionsController.transactions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _controller.currentResult;
    final business = widget.business;

    return Scaffold(
      backgroundColor: AppTheme.canvasWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.navyDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'What-If Scenario Simulator',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Saved Simulations',
            onPressed: () => _showSavedSimulationsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save Current Scenario',
            onPressed: () => _saveCurrentScenario(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scenario Presets Bar
            _buildPresetSelector(),
            const SizedBox(height: 16),

            // Interactive Controls Card
            _buildScenarioControlsCard(),
            const SizedBox(height: 20),

            // Projected Deltas Grid
            if (result != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROJECTED IMPACT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppTheme.navyPrimary,
                    ),
                  ),
                  Text(
                    'Based on ${business.name} Financials',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDeltasGrid(result),
              const SizedBox(height: 20),

              // Executive Trade-offs & Summary Card
              _buildTradeOffsCard(result),
              const SizedBox(height: 20),

              // AI CFO Advisory Card
              _buildAiAdvisoryCard(
                business.name,
                business.industry ?? 'Business',
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector() {
    final presets = [
      {'title': 'Rev +10%', 'type': ScenarioType.revenueDelta, 'val': 10.0},
      {'title': 'Rev -15%', 'type': ScenarioType.revenueDelta, 'val': -15.0},
      {
        'title': 'Cut Exp -10%',
        'type': ScenarioType.expenseDelta,
        'val': -10.0,
      },
      {
        'title': 'Cut Mktg -20%',
        'type': ScenarioType.categoryExpenseDelta,
        'val': -20.0,
      },
      {
        'title': 'Price +5%',
        'type': ScenarioType.pricingAdjustment,
        'val': 5.0,
      },
      {
        'title': 'Hire Staff',
        'type': ScenarioType.headcountAddition,
        'val': 3500.0,
      },
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = presets[index];
          final type = item['type'] as ScenarioType;
          final isSelected = _controller.selectedType == type;

          return ChoiceChip(
            label: Text(
              item['title'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.navyDeep,
              ),
            ),
            selected: isSelected,
            selectedColor: AppTheme.navyPrimary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppTheme.navyPrimary : AppTheme.cardBorder,
            ),
            onSelected: (selected) {
              if (selected) {
                _controller.setScenarioType(type);
                if (type == ScenarioType.headcountAddition) {
                  _controller.setFixedAmountDelta(item['val'] as double);
                } else {
                  _controller.setPercentageDelta(item['val'] as double);
                }
                _runCurrentSimulation();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildScenarioControlsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _controller.scenarioName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navyDeep,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.navyPrimary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _controller.selectedType == ScenarioType.headcountAddition
                      ? '\$${_controller.fixedAmountDelta.toStringAsFixed(0)} / mo'
                      : '${_controller.percentageDelta >= 0 ? '+' : ''}${_controller.percentageDelta.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navyPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Conditional Controls
          if (_controller.selectedType ==
              ScenarioType.categoryExpenseDelta) ...[
            DropdownButtonFormField<String>(
              initialValue: _controller.targetCategory ?? 'Marketing',
              decoration: InputDecoration(
                labelText: 'Target Expense Category',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  _controller.setTargetCategory(val);
                  _runCurrentSimulation();
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          if (_controller.selectedType == ScenarioType.headcountAddition) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Salary + Burden',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                Text(
                  '\$${_controller.fixedAmountDelta.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Slider(
              value: _controller.fixedAmountDelta,
              min: 1000.0,
              max: 20000.0,
              divisions: 38,
              activeColor: AppTheme.navyPrimary,
              inactiveColor: Colors.grey.shade200,
              label: '\$${_controller.fixedAmountDelta.toStringAsFixed(0)}',
              onChanged: (val) {
                _controller.setFixedAmountDelta(val);
                _runCurrentSimulation();
              },
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Percentage Change',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                Text(
                  '${_controller.percentageDelta >= 0 ? '+' : ''}${_controller.percentageDelta.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Slider(
              value: _controller.percentageDelta,
              min: -50.0,
              max: 50.0,
              divisions: 100,
              activeColor: AppTheme.navyPrimary,
              inactiveColor: Colors.grey.shade200,
              label: '${_controller.percentageDelta.toStringAsFixed(1)}%',
              onChanged: (val) {
                _controller.setPercentageDelta(val);
                _runCurrentSimulation();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeltasGrid(SimulationResult result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 550;
        return GridView.count(
          crossAxisCount: isWide ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            SimulationDeltaCard(
              title: 'Revenue',
              baselineValue: result.baselineRevenue,
              projectedValue: result.projectedRevenue,
              deltaValue: result.revenueDelta,
              isCurrency: true,
              higherIsBetter: true,
              icon: Icons.trending_up_rounded,
            ),
            SimulationDeltaCard(
              title: 'Expenses',
              baselineValue: result.baselineExpenses,
              projectedValue: result.projectedExpenses,
              deltaValue: result.expensesDelta,
              isCurrency: true,
              higherIsBetter: false,
              icon: Icons.trending_down_rounded,
            ),
            SimulationDeltaCard(
              title: 'Net Profit',
              baselineValue: result.baselineProfit,
              projectedValue: result.projectedProfit,
              deltaValue: result.profitDelta,
              isCurrency: true,
              higherIsBetter: true,
              icon: Icons.account_balance_wallet_rounded,
            ),
            SimulationDeltaCard(
              title: 'Profit Margin',
              baselineValue: result.baselineMargin,
              projectedValue: result.projectedMargin,
              deltaValue: result.marginDelta,
              isCurrency: false,
              isPercentage: true,
              higherIsBetter: true,
              icon: Icons.pie_chart_outline_rounded,
            ),
            SimulationDeltaCard(
              title: 'Cash Flow',
              baselineValue: result.baselineCashFlow,
              projectedValue: result.projectedCashFlow,
              deltaValue: result.cashFlowDelta,
              isCurrency: true,
              higherIsBetter: true,
              icon: Icons.swap_horiz_rounded,
            ),
            SimulationDeltaCard(
              title: 'Health Score',
              baselineValue: result.baselineHealthScore,
              projectedValue: result.projectedHealthScore,
              deltaValue: result.healthScoreDelta,
              isCurrency: false,
              higherIsBetter: true,
              icon: Icons.favorite_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTradeOffsCard(SimulationResult result) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppTheme.amberWarning,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Deterministic Model Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.navyDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.executiveSummary,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          if (result.tradeOffs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Key Strategic Trade-offs:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...result.tradeOffs.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navyPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiAdvisoryCard(String businessName, String industry) {
    final hasAiFeedback =
        _controller.aiFeedback != null && _controller.aiFeedback!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [AppTheme.navyDeep, AppTheme.navyPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F2B48),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.tealAccent.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.tealAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AI CFO Trade-off Advisor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (!hasAiFeedback && !_controller.isAiAnalyzing)
                ElevatedButton.icon(
                  icon: const Icon(Icons.psychology_rounded, size: 16),
                  label: const Text('Consult AI CFO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealAccent,
                    foregroundColor: AppTheme.navyDeep,
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    _controller.requestAiAnalysis(
                      businessId: widget.business.id,
                      businessName: businessName,
                      industry: industry,
                    );
                  },
                ),
            ],
          ),
          if (_controller.isAiAnalyzing) ...[
            const SizedBox(height: 16),
            Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.tealAccent,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Evaluating scenario trade-offs against industry benchmarks...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ] else if (hasAiFeedback) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _controller.aiFeedback!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: AppTheme.tealAccent,
                ),
                label: const Text(
                  'Re-evaluate with AI',
                  style: TextStyle(color: AppTheme.tealAccent, fontSize: 12),
                ),
                onPressed: () {
                  _controller.requestAiAnalysis(
                    businessId: widget.business.id,
                    businessName: businessName,
                    industry: industry,
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Click "Consult AI CFO" to have Finora AI evaluate cash flow sensitivity, risk boundaries, and strategic execution steps for this scenario.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _saveCurrentScenario(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await _controller.saveCurrentSimulation(
      businessId: widget.business.id,
      userId: widget.business.ownerId,
    );

    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Saved scenario: "${_controller.scenarioName}"'),
          backgroundColor: AppTheme.tealAccent,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Failed to save scenario.'),
          backgroundColor: AppTheme.coralRisk,
        ),
      );
    }
  }

  void _showSavedSimulationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final list = _controller.savedSimulations;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saved Simulations',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navyDeep,
                    ),
                  ),
                  Text(
                    '${list.length} saved',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'No saved simulations yet.\nCreate and bookmark a scenario above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = list[idx];
                      final proj = item.projectedMetrics;
                      final profitDelta =
                          (proj['profit_delta'] as num?)?.toDouble() ?? 0.0;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.navyPrimary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: AppTheme.navyPrimary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Profit Delta: ${profitDelta >= 0 ? '+' : ''}\$${profitDelta.toStringAsFixed(0)} • ${item.createdAt.month}/${item.createdAt.day}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
