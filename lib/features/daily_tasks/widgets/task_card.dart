import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/widgets/icon_container.dart';
import 'package:designdynamos/features/daily_tasks/widgets/status_pip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/tag_chip.dart';
import 'package:flutter/material.dart';


class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final bool completed = task.completed;
    final Color backgroundColor = completed
        ? AppColors.completedCard
        : AppColors.taskCard;
    final Color textColor = completed
        ? AppColors.textPrimary.withOpacity(0.7)
        : AppColors.textPrimary;
    final TextStyle titleStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
          decoration: completed
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          decorationColor: textColor.withOpacity(0.8),
        ) ??
        TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          decoration: completed
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: completed
              ? Border.all(color: AppColors.completedBorder, width: 1.4)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StatusPip(isCompleted: completed),
            const SizedBox(width: 14),
            IconContainer(icon: task.icon, isCompleted: completed),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: titleStyle),
                  if (!completed &&
                      (task.progress != null || task.metadata.isNotEmpty))
                    const SizedBox(height: 10),
                  if (!completed && task.progress != null)
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: task.progress!.clamp(0, 1),
                              backgroundColor: AppColors.progressTrack
                                  .withOpacity(0.6),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.taskCardHighlight,
                              ),
                            ),
                          ),
                        ),
                        if (task.progressLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            task.progressLabel!,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  if (!completed && task.metadata.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: task.metadata
                          .map((tag) => TagChip(tag: tag))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (!completed && task.score != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scoreBadge.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${task.score}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
