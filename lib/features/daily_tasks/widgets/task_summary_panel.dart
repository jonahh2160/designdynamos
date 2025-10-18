import 'package:designdynamos/core/models/subtask_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/widgets/icon_container.dart';
import 'package:designdynamos/features/daily_tasks/widgets/status_pip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/subtask_row.dart';
import 'package:flutter/material.dart';

class TaskSummaryCard extends StatelessWidget {
  const TaskSummaryCard({
    super.key,
    required this.title,
    required this.score,
    required this.subtasks,
  });

  final String title;
  final int score;
  final List<SubtaskItem> subtasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.detailCard,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusPip(isCompleted: false),
              const SizedBox(width: 16),
              IconContainer(icon: Icons.bed, isCompleted: false),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Priority $score',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final subtask in subtasks) ...[
            SubtaskRow(subtask: subtask),
            const SizedBox(height: 12),
          ],
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.add,
              color: AppColors.textSecondary,
              size: 18,
            ),
            label: Text(
              'Add subtask',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}