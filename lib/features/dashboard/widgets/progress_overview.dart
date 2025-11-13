import 'package:flutter/material.dart';
import 'package:designdynamos/core/theme/app_colors.dart';

class ProgressOverview extends StatelessWidget {
  const ProgressOverview({
    super.key,
    required this.completed,
    required this.total,
    required this.coins,
    required this.streakLabel,
  });

  final int completed;
  final int total;
  final int coins;
  final String streakLabel;

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : completed / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 18,
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.progressTrack,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0, 1),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.taskCard,
                                  AppColors.taskCardHighlight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  streakLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.sidebarActive,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  coins.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
