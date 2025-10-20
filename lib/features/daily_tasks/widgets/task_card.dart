import 'package:flutter/material.dart';

import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/utils/task_icon_registry.dart';
import 'package:designdynamos/features/daily_tasks/widgets/icon_container.dart';
import 'package:designdynamos/features/daily_tasks/widgets/status_pip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onToggle,
    this.onTap,
    this.isSelected = false,
  });

  final TaskItem task;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final bool completed = task.isDone;
    final Color baseColor = completed
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

    final borderColor = isSelected
        ? AppColors.accent
        : completed
        ? AppColors.completedBorder
        : Colors.transparent;
    final borderWidth = isSelected ? 2.0 : (completed ? 1.4 : 0.0);

    final iconData = TaskIconRegistry.iconFor(task.iconName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: baseColor,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.translucent,
                  child: StatusPip(isCompleted: completed),
                ),
                const SizedBox(width: 14),
                IconContainer(icon: iconData, isCompleted: completed),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: titleStyle),
                      const SizedBox(height: 6),
                      _MetadataRow(task: task),
                    ],
                  ),
                ),
                if (task.points > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (task.dueDate != null) {
      chips.add(
        _MetaChip(
          icon: Icons.calendar_today_outlined,
          label: _formatDueDate(task.dueDate!),
        ),
      );
    }
    chips.add(
      _MetaChip(icon: Icons.flag_outlined, label: 'Priority ${task.priority}'),
    );
    if (task.isDone) {
      chips.add(_MetaChip(icon: Icons.check_circle_outline, label: 'Done'));
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sidebarActive.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDueDate(DateTime date) {
  final today = DateUtils.dateOnly(DateTime.now());
  final target = DateUtils.dateOnly(date);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Due Today';
  if (diff == 1) return 'Due Tomorrow';
  if (diff == -1) return 'Due Yesterday';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[target.month - 1];
  return '$month ${target.day}';
}
