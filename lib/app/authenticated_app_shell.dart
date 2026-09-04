import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/businesses/application/business_controller.dart';
import '../features/financial_health/application/financial_health_controller.dart';
import '../features/financial_health/presentation/dashboard_screen.dart';
import '../features/transactions/application/transaction_controller.dart';
import '../features/transactions/presentation/transactions_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _healthController = FinancialHealthController();
    _transactionController = TransactionController(
      onTransactionsChanged: () {
        final business = widget.businessController.currentBusiness;
        if (business != null) {
          _healthController.recalculate(
            businessId: business.id,
            allTransactions: _transactionController.transactions,
            silent: true,
          );
        }
      },
    );

    final business = widget.businessController.currentBusiness;
    if (business != null) {
      _transactionController.loadTransactions(businessId: business.id);
    }
  }

  @override
  void dispose() {
    _transactionController.dispose();
    _healthController.dispose();
    super.dispose();
  }

  void _handleSignOut() {
    widget.businessController.reset();
    widget.authController.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.businessController.currentBusiness;

    if (business == null) {
      return const Scaffold(body: Center(child: Text('No business selected.')));
    }

    final pages = [
      DashboardScreen(
        healthController: _healthController,
        transactionController: _transactionController,
        business: business,
        onNavigateToTransactions: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      TransactionsScreen(
        controller: _transactionController,
        businessId: business.id,
        currency: business.currency,
      ),
      _buildPlaceholderTab(
        title: 'AI CFO Advisory',
        icon: Icons.psychology_outlined,
        badgeText: 'Coming in Stage 6',
        description:
            'Qoder Cloud Agents will provide executive analysis, scenario planning, and financial recommendations.',
      ),
      _buildPlaceholderTab(
        title: 'Alerts & Risk Engine',
        icon: Icons.notifications_none_outlined,
        badgeText: 'Coming in Stage 5',
        description:
            'Anomaly detection, distress warnings, and growth opportunities based on transaction momentum.',
      ),
      _buildSettingsTab(context),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppTheme.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${business.currency} • ${business.industry ?? "General"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            tooltip: 'Log Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'AI CFO',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab({
    required String title,
    required IconData icon,
    required String badgeText,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Icon(icon, size: 32, color: AppTheme.primaryLight),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
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
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.person_outline,
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
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _handleSignOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
            side: const BorderSide(color: AppTheme.errorColor),
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Log Out of Finora'),
        ),
      ],
    );
  }
}
