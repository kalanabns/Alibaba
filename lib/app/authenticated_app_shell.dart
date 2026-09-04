import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/ai_cfo/application/ai_cfo_controller.dart';
import '../features/ai_cfo/presentation/ai_cfo_screen.dart';
import '../features/alerts/application/alerts_controller.dart';
import '../features/alerts/domain/alert.dart';
import '../features/alerts/presentation/alerts_screen.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/businesses/application/business_controller.dart';
import '../features/businesses/data/demo_business_service.dart';
import '../features/financial_health/application/financial_health_controller.dart';
import '../features/financial_health/presentation/dashboard_screen.dart';
import '../features/forecasts/application/forecast_controller.dart';
import '../features/forecasts/presentation/forecast_screen.dart';
import '../features/simulations/presentation/simulations_screen.dart';
import '../features/transactions/application/sms_ingestion_controller.dart';
import '../features/transactions/application/transaction_controller.dart';
import '../features/transactions/presentation/sms_review_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../shared/widgets/onboarding_guide_dialog.dart';

class AuthenticatedAppShell extends StatefulWidget {
  const AuthenticatedAppShell({
    super.key,
    required this.authController,
    required this.businessController,
  });

  final AuthController authController;
  final BusinessController businessController;

  @override
  State<AuthenticatedAppShell> createState() => _AuthenticatedAppShellState();
}

class _AuthenticatedAppShellState extends State<AuthenticatedAppShell> {
  int _selectedIndex = 0;
  late final TransactionController _transactionController;
  late final FinancialHealthController _healthController;
  late final AlertsController _alertsController;
  late final AICFOController _aiCfoController;
  late final ForecastController _forecastController;
  late final SmsIngestionController _smsController;

  Alert? _alertToExplainInAi;

  @override
  void initState() {
    super.initState();
    _healthController = FinancialHealthController();
    _alertsController = AlertsController();
    _aiCfoController = AICFOController();
    _forecastController = ForecastController();

    _transactionController = TransactionController(
      onTransactionsChanged: () {
        _syncAllEngines(silent: true);
      },
    );

    _smsController = SmsIngestionController(
      onTransactionsChanged: () {
        final business = widget.businessController.currentBusiness;
        if (business != null) {
          _transactionController.loadTransactions(businessId: business.id).then((_) {
            _syncAllEngines(silent: true);
          });
        }
      },
    );

    final business = widget.businessController.currentBusiness;
    if (business != null) {
      if (widget.businessController.isDemoMode) {
        _loadDemoState();
      } else {
        _transactionController.loadTransactions(businessId: business.id).then((
          _,
        ) {
          _syncAllEngines(silent: false);
        });
        _aiCfoController.loadHistory(businessId: business.id);
      }
    }
  }

  void _loadDemoState() {
    final demo = DemoBusinessService.getDemoData();
    _transactionController.loadInMemoryTransactions(demo.transactions);
    _alertsController.loadInMemoryAlerts(demo.alerts);
    _healthController.recalculate(
      businessId: demo.business.id,
      allTransactions: demo.transactions,
      silent: true,
    );
    _forecastController.generateAndSyncForecasts(
      businessId: demo.business.id,
      buckets: demo.buckets,
      startingCash: demo.business.startingCash,
      silent: true,
    );
  }

  void _syncAllEngines({bool silent = false}) {
    final business = widget.businessController.currentBusiness;
    if (business == null) return;

    _healthController.recalculate(
      businessId: business.id,
      allTransactions: _transactionController.transactions,
      silent: silent,
    );

    final metric = _healthController.currentMetric;
    if (metric != null) {
      _alertsController.evaluateAndSync(
        businessId: business.id,
        currentMetrics: metric,
        currentTransactions: _transactionController.transactions,
        startingCash: business.startingCash,
      );

      _aiCfoController.generateDashboardSummary(
        businessId: business.id,
        currentMetrics: metric,
        business: business,
        activeAlerts: _alertsController.allAlerts,
      );

      _forecastController.generateAndSyncForecasts(
        businessId: business.id,
        buckets: _healthController.monthlyBuckets,
        startingCash: business.startingCash,
        silent: silent,
      );
    }
  }

  @override
  void dispose() {
    _transactionController.dispose();
    _healthController.dispose();
    _alertsController.dispose();
    _aiCfoController.dispose();
    _forecastController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  void _handleSignOut() {
    widget.businessController.reset();
    widget.authController.signOut();
  }

  void _openForecastsScreen(BuildContext context) {
    final business = widget.businessController.currentBusiness;
    if (business == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForecastScreen(
          controller: _forecastController,
          business: business,
          historicalBuckets: _healthController.monthlyBuckets,
          onAskAiAboutForecast: (query) {
            _selectedIndex = 2;
            setState(() {});
            _aiCfoController.sendMessage(
              message: query,
              businessId: business.id,
              currentMetrics: _healthController.currentMetric,
              business: business,
              activeAlerts: _alertsController.allAlerts,
              recentTransactions: _transactionController.transactions,
            );
          },
        ),
      ),
    );
  }

  void _openSimulationsScreen(BuildContext context) {
    final business = widget.businessController.currentBusiness;
    if (business == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimulationsScreen(
          business: business,
          transactionsController: _transactionController,
          currentMetric: _healthController.currentMetric,
        ),
      ),
    );
  }

  void _openSmsReviewScreen(BuildContext context) {
    final business = widget.businessController.currentBusiness;
    if (business == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmsReviewScreen(
          controller: _smsController,
          business: business,
          existingTransactions: _transactionController.transactions,
        ),
      ),
    );
  }

  void _navigateToAiCfoWithAlert(Alert alert) {
    setState(() {
      _alertToExplainInAi = alert;
      _selectedIndex = 2; // AI CFO tab index
    });

    _aiCfoController.sendMessage(
      message:
          'Explain this signal: "${alert.title}" and provide practical next steps.',
      businessId: widget.businessController.currentBusiness!.id,
      alertContext: alert,
      currentMetrics: _healthController.currentMetric,
      business: widget.businessController.currentBusiness,
      activeAlerts: _alertsController.allAlerts,
      recentTransactions: _transactionController.transactions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.businessController.currentBusiness;

    if (business == null) {
      return const Scaffold(body: Center(child: Text('No business selected.')));
    }

    return ListenableBuilder(
      listenable: _alertsController,
      builder: (context, _) {
        final unreadAlerts = _alertsController.unreadCount;

        final pages = [
          DashboardScreen(
            healthController: _healthController,
            transactionController: _transactionController,
            alertsController: _alertsController,
            aiCfoController: _aiCfoController,
            forecastController: _forecastController,
            business: business,
            onNavigateToTransactions: () {
              setState(() => _selectedIndex = 1);
            },
            onNavigateToAlerts: () {
              setState(() => _selectedIndex = 3);
            },
            onNavigateToAiCfo: () {
              setState(() => _selectedIndex = 2);
            },
            onNavigateToForecasts: () => _openForecastsScreen(context),
            onNavigateToSimulations: () => _openSimulationsScreen(context),
            onExplainAlert: _navigateToAiCfoWithAlert,
          ),
          TransactionsScreen(
            controller: _transactionController,
            businessId: business.id,
            currency: business.currency,
            business: business,
            smsController: _smsController,
          ),
          AICFOScreen(
            controller: _aiCfoController,
            business: business,
            currentMetrics: _healthController.currentMetric,
            activeAlerts: _alertsController.allAlerts,
            recentTransactions: _transactionController.transactions,
            initialAlertToExplain: _alertToExplainInAi,
          ),
          AlertsScreen(
            controller: _alertsController,
            businessId: business.id,
            business: business,
            currentMetrics: _healthController.currentMetric,
            onAskAiAboutAlert: _navigateToAiCfoWithAlert,
          ),
          _buildSettingsTab(context),
        ];

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              business.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.businessController.isDemoMode) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade800,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DEMO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${business.currency} • ${business.industry ?? "General"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: 'Product Guide',
                onPressed: () => OnboardingGuideDialog.show(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: 'Forecasts',
                onPressed: () => _openForecastsScreen(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: 'What-If Simulator',
                onPressed: () => _openSimulationsScreen(context),
              ),
              IconButton(
                icon: Icon(
                  widget.businessController.isDemoMode ? Icons.exit_to_app_rounded : Icons.logout_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: widget.businessController.isDemoMode ? 'Exit Demo' : 'Log Out',
                onPressed: widget.businessController.isDemoMode
                    ? () {
                        widget.businessController.exitDemoMode();
                      }
                    : _handleSignOut,
              ),
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            backgroundColor: AppTheme.primaryNavy,
            indicatorColor: AppTheme.primaryLight.withValues(alpha: 0.2),
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Transactions',
              ),
              const NavigationDestination(
                icon: Icon(Icons.psychology_outlined),
                selectedIcon: Icon(Icons.psychology_rounded),
                label: 'AI CFO',
              ),
              NavigationDestination(
                icon: unreadAlerts > 0
                    ? Badge(
                        label: Text('$unreadAlerts'),
                        backgroundColor: AppTheme.errorColor,
                        child: const Icon(Icons.notifications_none_rounded),
                      )
                    : const Icon(Icons.notifications_none_rounded),
                selectedIcon: const Icon(Icons.notifications_rounded),
                label: 'Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    final user = widget.authController.currentUser;
    final business = widget.businessController.currentBusiness;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text(
          'Account & Workspace',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.textSecondary,
                ),
                title: const Text(
                  'User Email',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                subtitle: Text(
                  user?.email ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.store_outlined,
                  color: AppTheme.textSecondary,
                ),
                title: const Text(
                  'Business Name',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                subtitle: Text(
                  business?.name ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.monetization_on_outlined,
                  color: AppTheme.textSecondary,
                ),
                title: const Text(
                  'Base Currency',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                subtitle: Text(
                  business?.currency ?? 'USD',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppTheme.textSecondary,
                ),
                title: const Text(
                  'Fiscal Year Start Month',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                subtitle: Text(
                  'Month ${business?.fiscalYearStartMonth ?? 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Automations & Ingestion Section
        const Text(
          'Automations & Ingestion',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.sms_outlined,
                  color: AppTheme.primaryLight,
                ),
                title: const Text(
                  'Android SMS Ingestion',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Detect incoming bank & wallet SMS transactions',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                trailing: Switch(
                  value: _smsController.isIngestionEnabled,
                  activeThumbColor: AppTheme.primaryLight,
                  onChanged: (val) {
                    setState(() {
                      _smsController.toggleIngestion(val);
                    });
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.fact_check_outlined,
                  color: AppTheme.textSecondary,
                ),
                title: const Text(
                  'Review SMS Candidates',
                  style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
                subtitle: Text(
                  '${_smsController.pendingCandidates.length} pending approval',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                onTap: () => _openSmsReviewScreen(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Product Guide & Presentation Tools
        const Text(
          'Product Guide & Presentation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.menu_book_outlined,
                  color: AppTheme.primaryLight,
                ),
                title: const Text(
                  '4-Pillar Architecture Guide',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Review deterministic engine, What-If simulator, and AI CFO concepts',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () => OnboardingGuideDialog.show(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.science_outlined,
                  color: AppTheme.warningColor,
                ),
                title: Text(
                  widget.businessController.isDemoMode ? 'Exit Demo Mode' : 'Load Hackathon Demo Dataset',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  widget.businessController.isDemoMode
                      ? 'Currently running isolated sample SMB scenario'
                      : 'Test Pacific Coast Roasters scenario (revenue growth with expense surge)',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () {
                  if (widget.businessController.isDemoMode) {
                    widget.businessController.exitDemoMode();
                  } else {
                    final demo = DemoBusinessService.getDemoData();
                    widget.businessController.loadDemoMode(demo.business);
                    _loadDemoState();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: widget.businessController.isDemoMode ? widget.businessController.exitDemoMode : _handleSignOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
            side: const BorderSide(color: AppTheme.errorColor),
          ),
          icon: Icon(widget.businessController.isDemoMode ? Icons.exit_to_app_rounded : Icons.logout_rounded, size: 18),
          label: Text(widget.businessController.isDemoMode ? 'Exit Demo Mode' : 'Log Out of Finora'),
        ),
      ],
    );
  }
}
