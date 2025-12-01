import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:designdynamos/core/models/goal.dart';
import 'package:designdynamos/core/models/goal_step.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';

class GoalDetailPanel extends StatelessWidget {
  const GoalDetailPanel({
    super.key,
    required this.goal,
    required this.tasksById,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onClose,
    required this.onUpdateMeta,
    this.onDelete,
    this.isDeleting = false,
  });

  final Goal? goal;
  final Map<String, TaskItem> tasksById;
  final Future<void> Function(TaskItem task, bool done) onToggleTask;
  final VoidCallback onAddTask;
  final VoidCallback onClose;
  final Future<void> Function({
    DateTime? startAt,
    DateTime? dueAt,
    int? priority,
  })
  onUpdateMeta;
  final Future<void> Function()? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    if (goal == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.detailCard,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Text(
          'Select a goal to view details',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final sortedSteps = [...goal!.steps]
      ..sort((a, b) => a.orderHint.compareTo(b.orderHint));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        goal!.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    if (onDelete != null) ...[
                      IconButton(
                        tooltip: isDeleting ? 'Deleting…' : 'Delete goal',
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        onPressed: isDeleting ? null : onDelete,
                        icon: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.delete_outline,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ],
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${(goal!.progress * 100).toStringAsFixed(0)}% complete',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: goal!.progress.clamp(0, 1),
                          backgroundColor: AppColors.progressTrack,
                          minHeight: 10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoGrid(
                  startDate: goal!.startAt,
                  dueDate: goal!.dueAt,
                  priority: goal!.priority,
                  onStartTap: () => _pickDate(
                    context,
                    initial: goal!.startAt,
                    onSubmit: (date) => onUpdateMeta(startAt: date),
                  ),
                  onDueTap: () => _pickDate(
                    context,
                    initial: goal!.dueAt,
                    onSubmit: (date) => onUpdateMeta(dueAt: date),
                  ),
                  onPriorityChanged: (value) => onUpdateMeta(priority: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                for (final step in sortedSteps) ...[
                  _GoalStepTile(
                    step: step,
                    tasks: _tasksForStep(step),
                    onToggleTask: onToggleTask,
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Add task to Goal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TaskItem> _tasksForStep(GoalStep step) {
    final filtered = tasksById.values
        .where((task) => task.goalStepId == step.id)
        .toList();
    filtered.sort(
      (a, b) => (a.dueAt ?? a.targetAt ?? DateTime.now()).compareTo(
        b.dueAt ?? b.targetAt ?? DateTime.now(),
      ),
    );
    return filtered;
  }
}

class _GoalStepTile extends StatelessWidget {
  const _GoalStepTile({
    required this.step,
    required this.tasks,
    required this.onToggleTask,
  });

  final GoalStep step;
  final List<TaskItem> tasks;
  final Future<void> Function(TaskItem task, bool done) onToggleTask;

  @override
  Widget build(BuildContext context) {
    final completedTasks = tasks.where((task) => task.isDone).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.subtaskBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                step.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${completedTasks}/${tasks.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Text(
              'No tasks assigned yet.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            )
          else
            Column(
              children: [
                for (final task in tasks) ...[
                  _GoalTaskRow(
                    task: task,
                    onToggle: (done) => onToggleTask(task, done),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _GoalTaskRow extends StatelessWidget {
  const _GoalTaskRow({required this.task, required this.onToggle});

  final TaskItem task;
  final Future<void> Function(bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: task.isDone,
          onChanged: (value) {
            if (value == null) return;
            onToggle(value);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  decoration: task.isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: task.isDone ? 1 : 0,
                backgroundColor: AppColors.progressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.isDone ? AppColors.accent : AppColors.textMuted,
                ),
                minHeight: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.drag_handle_rounded, color: AppColors.textSecondary),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.startDate,
    required this.dueDate,
    required this.priority,
    required this.onStartTap,
    required this.onDueTap,
    required this.onPriorityChanged,
  });

  final DateTime startDate;
  final DateTime dueDate;
  final int priority;
  final VoidCallback onStartTap;
  final VoidCallback onDueTap;
  final ValueChanged<int> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final infoStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.event_available_outlined,
            label: 'Started',
            value: DateFormat.yMMMMd().format(startDate),
            labelStyle: labelStyle,
            valueStyle: infoStyle,
            onTap: onStartTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            icon: Icons.calendar_month_outlined,
            label: 'Due',
            value: DateFormat.yMMMMd().format(dueDate),
            labelStyle: labelStyle,
            valueStyle: infoStyle,
            onTap: onDueTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PriorityTile(
            icon: Icons.flag_outlined,
            label: 'Priority',
            value: priority,
            labelStyle: labelStyle,
            valueStyle: infoStyle,
            onChanged: onPriorityChanged,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: labelStyle),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: valueStyle),
      ],
    );
    return Material(
      color: AppColors.subtaskBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(16), child: content),
      ),
    );
  }
}

Future<void> _pickDate(
  BuildContext context, {
  required DateTime initial,
  required ValueChanged<DateTime> onSubmit,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(initial.year - 5),
    lastDate: DateTime(initial.year + 5),
  );
  if (picked != null) {
    onSubmit(
      DateTime(
        picked.year,
        picked.month,
        picked.day,
        initial.hour,
        initial.minute,
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.subtaskBackground,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(label, style: labelStyle),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                dropdownColor: AppColors.detailCard,
                iconEnabledColor: AppColors.textPrimary,
                onChanged: (val) {
                  if (val == null) return;
                  onChanged(val);
                },
                items: [
                  for (var i = 1; i <= 10; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text('Level $i', style: valueStyle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
