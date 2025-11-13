import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:designdynamos/core/models/goal.dart';
import 'package:designdynamos/core/theme/app_colors.dart';

class GoalSummaryCard extends StatelessWidget {
  const GoalSummaryCard({
    super.key,
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final Goal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseline = _timelineProgress(goal);
    final status = _statusLabel(goal.progress, baseline);
    final daysRemaining = goal.dueAt.difference(DateTime.now()).inDays;
    final daysLabel = daysRemaining >= 0
        ? '$daysRemaining days remain'
        : 'Past due';
    final formatter = DateFormat.MMMd();
    final dueRange =
        '${formatter.format(goal.startAt)} — ${formatter.format(goal.dueAt)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: selected ? AppColors.taskCardHighlight : AppColors.taskCard,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${goal.completedSteps}/${goal.totalSteps} steps completed',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              daysLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Priority ${goal.priority}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProgressBar(
                  value: goal.progress,
                  label:
                      '${(goal.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                ),
                const SizedBox(height: 12),
                _ProgressBar(
                  value: baseline,
                  background: AppColors.progressTrack,
                  color: Colors.pinkAccent.withOpacity(0.8),
                  label: dueRange,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.check, color: AppColors.textPrimary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _timelineProgress(Goal goal) {
    final total = goal.dueAt.difference(goal.startAt).inSeconds;
    if (total <= 0) return 1;
    final elapsed = DateTime.now().difference(goal.startAt).inSeconds;
    return (elapsed / total).clamp(0, 1);
  }

  String _statusLabel(double progress, double baseline) {
    if (progress >= baseline + 0.1) return 'Ahead';
    if (progress + 0.1 < baseline) return 'Behind';
    return 'On track';
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.label,
    this.color = AppColors.accent,
    this.background = AppColors.detailCard,
  });

  final double value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            backgroundColor: background,
            minHeight: 10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
