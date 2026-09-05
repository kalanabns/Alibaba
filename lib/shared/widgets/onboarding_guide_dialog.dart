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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: AppTheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(26.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Brand Icon
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryLight.withValues(alpha: 0.35),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Finora AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
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
                  title: '1. Deterministic Health Radar (0–100)',
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
                  color: AppTheme.cyberIndigo,
                  title: '4. Grounded AI CFO Decision Support',
                  description:
                      'Your AI CFO explains underlying financial trends, surfaces early risks, and drafts structured 1-2-3 action plans.',
                ),
                const SizedBox(height: 26),

                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
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
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
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
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
