import 'package:designdynamos/features/daily_tasks/widgets/meta_chip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:designdynamos/core/models/db_subtask.dart';

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
    required this.subtasks,
    required this.onAddSubtask,
    required this.onToggleSubtask,
    required this.onDeleteSubtask,
    required this.onDeleteTask,
    required this.labels,
    required this.onToggleLabel,
    required this.note,
    required this.onSaveNote,
  });

  final TaskItem? task;
  final Future<void> Function(bool done) onToggleComplete;
  final Future<void> Function(DateTime date) onDueDateChange;
  final Future<void> Function() onClearDueDate;
  final Future<void> Function(int priority) onPriorityChange;
  final Future<void> Function(String iconName) onIconChange;
  final List<DbSubtask> subtasks;
  final Future<void> Function(String title) onAddSubtask;
  final Future<void> Function(String subtaskId, bool done) onToggleSubtask;
  final Future<void> Function(String subtaskId) onDeleteSubtask;
  final Future<void> Function() onDeleteTask;
  final Set<String> labels;
  final Future<void> Function(String name, bool enabled) onToggleLabel;
  final String? note;
  final Future<void> Function(String? content) onSaveNote;

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
          //Header + actions
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
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
                    IconButton(
                      tooltip: 'Delete task',
                      onPressed: () async {
                        final ok =
                            await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete task?'),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (ok) await onDeleteTask();
                      },
                      icon: const Icon(
                        Icons.delete_outline,
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
          //Labels and quick chips
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: _LabelsEditor(
              labels: labels,
              dueToday:
                  task!.dueDate != null &&
                  DateUtils.isSameDay(task!.dueDate, DateTime.now()),
              onAdd: (name) => onToggleLabel(name, true),
              onRemove: (name) => onToggleLabel(name, false),
              priority: task!.priority,
            ),
          ),
          const SizedBox(height: 16),
          //Subtasks list
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subtasks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                for (final s in subtasks) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.subtaskBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => onToggleSubtask(s.id, !s.isDone),
                          icon: Icon(
                            s.isDone
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked_outlined,
                            color: s.isDone
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            s.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  decoration: s.isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onDeleteSubtask(s.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final title = await showDialog<String>(
                      context: context,
                      builder: (ctx) {
                        final c = TextEditingController();
                        return AlertDialog(
                          title: const Text('Add subtask'),
                          content: TextField(
                            controller: c,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Subtask title',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, c.text.trim()),
                              child: const Text('Add'),
                            ),
                          ],
                        );
                      },
                    );
                    if (title != null && title.isNotEmpty)
                      await onAddSubtask(title);
                  },
                  icon: const Icon(Icons.add, color: AppColors.textSecondary),
                  label: const Text('Add subtask'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          //Notes editor
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: _NotesEditor(initial: note, onSave: onSaveNote),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.detailCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
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

class _NotesEditor extends StatefulWidget {
  const _NotesEditor({required this.initial, required this.onSave});
  final String? initial;
  final Future<void> Function(String? content) onSave;

  @override
  State<_NotesEditor> createState() => _NotesEditorState();
}

class _NotesEditorState extends State<_NotesEditor> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void didUpdateWidget(covariant _NotesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && !_saving) {
      _controller.text = widget.initial ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Add notes'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await widget.onSave(
                        _controller.text.trim().isEmpty
                            ? null
                            : _controller.text.trim(),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ),
      ],
    );
  }
}

class _LabelsEditor extends StatefulWidget {
  const _LabelsEditor({
    required this.labels,
    required this.dueToday,
    required this.onAdd,
    required this.onRemove,
    required this.priority,
  });

  final Set<String> labels;
  final bool dueToday;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(String name) onRemove;
  final int priority;

  @override
  State<_LabelsEditor> createState() => _LabelsEditorState();
}

class _LabelsEditorState extends State<_LabelsEditor> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.onAdd(name);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.dueToday)
              const MetaChip(
                icon: Icons.calendar_today_outlined,
                label: 'Due Today',
              ),
            MetaChip(
              icon: Icons.flag_outlined,
              label: 'Priority ${widget.priority}',
            ),
            for (final name in widget.labels)
              TagChip(
                label: name,
                onDeleted: () {
                  widget.onRemove(name);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Add label'),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _busy ? null : _add,
              child: Text(_busy ? 'Adding...' : 'Add'),
            ),
          ],
        ),
      ],
    );
  }
}
