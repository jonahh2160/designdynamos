import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/widgets/icon_container.dart';
import 'package:designdynamos/features/daily_tasks/widgets/status_pip.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onToggle});
  final TaskItem task;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final bool completed = task.is_done;
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
      child: GestureDetector(
        onTap: () {
          //Open task details panel
        },
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
              GestureDetector(
                onTap: onToggle, // Toggle completion
                behavior: HitTestBehavior.translucent,
                child: StatusPip(isCompleted: completed),
              ),
              const SizedBox(width: 14),
              IconContainer(icon: Icons.task_alt, isCompleted: completed),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: titleStyle),
                    // Progress and metadata are omitted since TaskItem
                    // from the database does not include these fields.
                  ],
                ),
              ),
              if (!completed && task.points > 0)
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
                    '${task.points}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
