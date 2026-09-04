import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AISummaryCard extends StatelessWidget {
  const AISummaryCard({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.onOpenChat,
    required this.onRefresh,
  });

  final String? summary;
  final bool isLoading;
  final VoidCallback onOpenChat;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: AppTheme.primaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI CFO Executive Brief',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: Colors.white70,
                ),
                tooltip: 'Refresh Summary',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: isLoading ? null : onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Body Summary Text
          if (isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryLight,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Synthesizing financial performance...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            )
          else
            Text(
              summary ??
                  'Your financial workspace is configured. Tap below to chat with your AI CFO for actionable analysis.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFF1F5F9),
                height: 1.45,
              ),
            ),
          const SizedBox(height: 14),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onOpenChat,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryLight.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ask Finora AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppTheme.primaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
