import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/businesses/application/business_controller.dart';

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

  void _handleSignOut() {
    widget.businessController.reset();
    widget.authController.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.businessController.currentBusiness;

    final pages = [
      _buildHomeTab(context, business),
      _buildPlaceholderTab(
        title: 'Transactions',
        icon: Icons.receipt_long_outlined,
        description: 'CSV and manual transaction management will be implemented in Stage 3.',
      ),
      _buildPlaceholderTab(
        title: 'AI CFO',
        icon: Icons.psychology_outlined,
        description: 'Qoder Cloud Agents AI financial advisor will be connected in Stage 6.',
      ),
      _buildPlaceholderTab(
        title: 'Alerts & Risks',
        icon: Icons.notifications_none_outlined,
        description: 'Risk and opportunity detection engine will be added in Stage 5.',
      ),
      _buildSettingsTab(context),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(business?.name ?? 'Finora AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
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

  Widget _buildHomeTab(BuildContext context, dynamic business) {
    final currency = business?.currency ?? 'USD';
    final startingCash = business?.startingCash ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good morning',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            business?.name ?? 'Your Business',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Starting Cash Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currency,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$currency ${startingCash.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Industry: ${business?.industry ?? "N/A"}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.public, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        business?.country ?? 'N/A',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Financial health metrics, forecasts, and AI insights will appear here after transaction data is imported in later stages.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab({
    required String title,
    required IconData icon,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
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
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('User Email'),
          subtitle: Text(user?.email ?? 'N/A'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.store_outlined),
          title: const Text('Business Name'),
          subtitle: Text(business?.name ?? 'N/A'),
        ),
        ListTile(
          leading: const Icon(Icons.monetization_on_outlined),
          title: const Text('Reporting Currency'),
          subtitle: Text(business?.currency ?? 'USD'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Fiscal Year Start Month'),
          subtitle: Text('Month ${business?.fiscalYearStartMonth ?? 1}'),
        ),
        const Divider(),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _handleSignOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Log Out'),
        ),
      ],
    );
  }
}
