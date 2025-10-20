import 'package:flutter/material.dart';

import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/utils/task_icon_registry.dart';
import 'package:designdynamos/features/daily_tasks/widgets/icon_container.dart';
import 'package:designdynamos/features/daily_tasks/widgets/status_pip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_icon_picker.dart';

class TaskDetailPanel extends StatelessWidget {
  const TaskDetailPanel({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onDueDateChange,
    required this.onClearDueDate,
    required this.onPriorityChange,
    required this.onIconChange,
  });

  final TaskItem? task;
  final Future<void> Function(bool done) onToggleComplete;
  final Future<void> Function(DateTime date) onDueDateChange;
  final Future<void> Function() onClearDueDate;
  final Future<void> Function(int priority) onPriorityChange;
  final Future<void> Function(String iconName) onIconChange;

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.detailCard,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Text(
          'Select a task to view its details.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final iconData = TaskIconRegistry.iconFor(task!.iconName);
    final dueDateLabel = task!.dueDate != null
        ? _formatLongDate(task!.dueDate!)
        : 'Add due date';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => onToggleComplete(!task!.isDone),
                      child: StatusPip(isCompleted: task!.isDone),
                    ),
                    const SizedBox(width: 12),
                    IconContainer(icon: iconData, isCompleted: task!.isDone),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task!.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task!.isDone ? 'Completed' : 'In progress',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: task!.isDone
                          ? 'Mark incomplete'
                          : 'Mark complete',
                      onPressed: () => onToggleComplete(!task!.isDone),
                      icon: Icon(
                        task!.isDone
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _DetailTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Due date',
                  value: dueDateLabel,
                  trailing: task!.dueDate != null
                      ? IconButton(
                          tooltip: 'Clear due date',
                          onPressed: onClearDueDate,
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = task!.dueDate ?? now;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                      helpText: 'Select due date',
                    );
                    if (picked != null) {
                      await onDueDateChange(
                        DateTime(picked.year, picked.month, picked.day),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _PriorityTile(
                  priority: task!.priority,
                  onPriorityChange: onPriorityChange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose icon',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TaskIconPicker(
                  selectedName: task!.iconName,
                  onChanged: onIconChange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({required this.priority, required this.onPriorityChange});

  final int priority;
  final Future<void> Function(int priority) onPriorityChange;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Priority',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DropdownButton<int>(
              value: priority,
              underline: const SizedBox.shrink(),
              dropdownColor: AppColors.detailCard,
              onChanged: (value) {
                if (value != null) {
                  onPriorityChange(value);
                }
              },
              items: [
                for (var value = 1; value <= 10; value++)
                  DropdownMenuItem(value: value, child: Text('Level $value')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatLongDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final month = months[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}
