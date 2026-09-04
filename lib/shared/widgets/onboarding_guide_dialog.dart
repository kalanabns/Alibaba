import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OnboardingGuideDialog extends StatelessWidget {
  const OnboardingGuideDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const OnboardingGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Brand Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.primaryLight,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Finora AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your proactive AI CFO for small and medium-sized businesses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const Divider(height: 28),

                // Pillar 1: Deterministic Health Engine
                _buildGuidePillar(
                  icon: Icons.shield_outlined,
                  color: AppTheme.accentColor,
                  title: '1. Deterministic Health Score (0–100)',
                  description:
                      'Finora calculates solvency, margins, cash flow, and runway using verified financial algorithms. Zero arithmetic hallucination.',
                ),
                const SizedBox(height: 14),

                // Pillar 2: Dual Data Ingestion
                _buildGuidePillar(
                  icon: Icons.input_rounded,
                  color: AppTheme.primaryLight,
                  title: '2. Flexible Data Ingestion',
                  description:
                      'Import multi-column bank CSVs with auto-schema detection or enable Android SMS ingestion for real-time transaction detection.',
                ),
                const SizedBox(height: 14),

                // Pillar 3: What-If Simulator
                _buildGuidePillar(
                  icon: Icons.tune_rounded,
                  color: AppTheme.warningColor,
                  title: '3. What-If Scenario Simulator',
                  description:
                      'Stress-test pricing increases (+5%), payroll expansion, or vendor expense cuts before committing company capital.',
                ),
                const SizedBox(height: 14),

                // Pillar 4: AI CFO Advisory
                _buildGuidePillar(
                  icon: Icons.psychology_outlined,
                  color: AppTheme.primaryNavy,
                  title: '4. Grounded AI CFO Decision Support',
                  description:
                      'Your AI CFO explains underlying financial trends, surfaces early risks, and drafts structured 1-2-3 action plans.',
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidePillar({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
