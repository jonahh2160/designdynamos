import 'package:designdynamos/features/daily_tasks/widgets/meta_chip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:designdynamos/core/models/db_subtask.dart';
import 'package:provider/provider.dart';

import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/utils/task_icon_registry.dart';
import 'package:designdynamos/features/daily_tasks/widgets/icon_container.dart';
import 'package:designdynamos/features/daily_tasks/widgets/status_pip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_icon_picker.dart';
import 'package:designdynamos/features/daily_tasks/utils/estimate_formatter.dart';
import 'package:designdynamos/providers/tts_provider.dart';

class TaskDetailPanel extends StatelessWidget {
  const TaskDetailPanel({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onTargetAtChange,
    required this.onTargetTimeChange,
    required this.onClearTargetAt,
    required this.onDueAtChange,
    required this.onDueTimeChange,
    required this.onEstimateChange,
    required this.onClearEstimate,
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
    required this.onClose,
  });

  final TaskItem? task;
  final Future<void> Function(bool done) onToggleComplete;
  final Future<void> Function(DateTime date) onTargetAtChange;
  final Future<void> Function(Duration timeOfDay) onTargetTimeChange;
  final Future<void> Function() onClearTargetAt;
  final Future<void> Function(DateTime date) onDueAtChange;
  final Future<void> Function(Duration timeOfDay) onDueTimeChange;
  final Future<void> Function(int? minutes) onEstimateChange;
  final Future<void> Function() onClearEstimate;
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
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsProvider>();

    if (task == null) {
      return Semantics(
        label: 'No task selected. Select a task to view its details.',
        child: Container(
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
        ),
      );
    }

    final iconData = TaskIconRegistry.iconFor(task!.iconName);
    final targetDateLabel = task!.targetAt != null
        ? _formatLongDate(task!.targetAt!)
        : 'Add target date';
    final targetTimeLabel = task!.targetAt != null
        ? DateFormat.jm().format(task!.targetAt!.toLocal())
        : 'Add target time';
    final dueDateLabel = task!.dueAt != null
        ? _formatLongDate(task!.dueAt!)
        : 'Add due date';
    final dueTimeLabel = task!.dueAt != null
        ? DateFormat.jm().format(task!.dueAt!.toLocal())
        : 'Add due time';
    final estimateLabel = task!.estimatedMinutes != null
        ? formatEstimateLabel(task!.estimatedMinutes!)
        : 'Add estimate';
    final panelIntro =
        'Task details. All fields are editable. Select a tile to edit dates, times, estimate, priority, labels, subtasks, or notes.';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Header + actions
          MouseRegion(
            onEnter: (_) {
              if (tts.isEnabled) tts.speak(panelIntro);
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.detailCard,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Semantics(
                label: 'Task details for ${task!.title}. Status: ${task!.isDone ? 'Completed' : 'In progress'}. $panelIntro',
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
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
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            IconButton(
                              tooltip: task!.isDone
                                  ? 'Mark incomplete'
                                  : 'Mark complete',
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(6),
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
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(6),
                              onPressed: () async {
                                final ok =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete task?'),
                                        content: const Text(
                                          'This cannot be undone.',
                                        ),
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
                            IconButton(
                              tooltip: 'Hide details',
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(6),
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                _DetailTile(
                  icon: Icons.flag_outlined,
                  title: 'Target date',
                  value: targetDateLabel,
                  semanticsLabel: 'Target date: $targetDateLabel',
                  trailing: task!.targetAt != null
                      ? IconButton(
                          tooltip: 'Clear target date',
                          onPressed: onClearTargetAt,
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = task!.targetAt ?? task!.dueAt ?? now;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                      helpText: 'Select target date',
                    );
                    if (picked != null) {
                      await onTargetAtChange(
                        DateTime(picked.year, picked.month, picked.day),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DetailTile(
                  icon: Icons.access_alarm_outlined,
                  title: 'Target time',
                  value: targetTimeLabel,
                  semanticsLabel: 'Target time: $targetTimeLabel',
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = task!.targetAt ?? task!.dueAt ?? now;
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(initial.toLocal()),
                      helpText: 'Select target time',
                    );
                    if (picked != null) {
                      await onTargetTimeChange(
                        Duration(hours: picked.hour, minutes: picked.minute),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DetailTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Due date',
                  value: dueDateLabel,
                  semanticsLabel: 'Due date: $dueDateLabel',
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = task!.dueAt ?? now;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                      helpText: 'Select due date',
                    );
                    if (picked != null) {
                      await onDueAtChange(
                        DateTime(picked.year, picked.month, picked.day),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DetailTile(
                  icon: Icons.access_time,
                  title: 'Due time',
                  value: dueTimeLabel,
                  semanticsLabel: 'Due time: $dueTimeLabel',
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = task!.dueAt ?? now;
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(initial.toLocal()),
                      helpText: 'Select due time',
                    );
                    if (picked != null) {
                      await onDueTimeChange(
                        Duration(hours: picked.hour, minutes: picked.minute),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DetailTile(
                  icon: Icons.timelapse,
                  title: 'Estimate',
                  value: estimateLabel,
                  trailing: task!.estimatedMinutes != null
                      ? IconButton(
                          tooltip: 'Clear estimate',
                          onPressed: onClearEstimate,
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  onTap: () async {
                    final controller = TextEditingController(
                      text: formatEstimateInput(task!.estimatedMinutes),
                    );
                    final newValue = await showDialog<String>(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text('Set estimate'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            keyboardType: TextInputType.datetime,
                            decoration: const InputDecoration(
                              hintText: 'Minutes or H:MM (e.g., 45 or 1:30)',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, controller.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );

                    if (newValue == null) return;
                    if (newValue.isEmpty) {
                      await onClearEstimate();
                      return;
                    }

                    final parsed = parseEstimateMinutes(newValue);
                    if (parsed == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Enter minutes or H:MM (e.g., 45 or 1:30)'),
                        ),
                      );
                      return;
                    }
                    await onEstimateChange(parsed);
                  },
                ),
                const SizedBox(height: 12),
                MouseRegion(
                  onEnter: (_) {
                    if (tts.isEnabled) tts.speak('Priority level ${task!.priority}');
                  },
                  child: Semantics(
                    label: 'Priority level ${task!.priority}',
                    child: _PriorityTile(
                      priority: task!.priority,
                      onPriorityChange: onPriorityChange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
          ),
          const SizedBox(height: 16),
          //Labels and quick chips
          MouseRegion(
            onEnter: (_) {
              if (tts.isEnabled) tts.speak('Labels section with ${labels.length} labels');
            },
            child: Semantics(
              label: 'Labels section',
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.detailCard,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: _LabelsEditor(
                  labels: labels,
                  dueToday:
                      task!.dueAt != null &&
                      DateUtils.isSameDay(task!.dueAt, DateTime.now()),
                  onAdd: (name) => onToggleLabel(name, true),
                  onRemove: (name) => onToggleLabel(name, false),
                  priority: task!.priority,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          //Subtasks list
          MouseRegion(
            onEnter: (_) {
              if (tts.isEnabled) tts.speak('Subtasks section with ${subtasks.length} subtasks');
            },
            child: Semantics(
              label: 'Subtasks section',
              child: Container(
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
                      MouseRegion(
                        onEnter: (_) {
                          if (tts.isEnabled) tts.speak('${s.title}${s.isDone ? ', completed' : ', not completed'}');
                        },
                        child: Semantics(
                          label: '${s.title}${s.isDone ? ', completed' : ', not completed'}',
                          checked: s.isDone,
                          child: Container(
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
                        if (title != null && title.isNotEmpty) {
                          await onAddSubtask(title);
                        }
                      },
                      icon: const Icon(Icons.add, color: AppColors.textSecondary),
                      label: const Text('Add subtask'),
                    ),
                  ],
                ),
              ),
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
            child: Builder(
              builder: (context) {
                final tts = context.read<TtsProvider>();
                final notesLabel = note?.isNotEmpty == true
                    ? 'Notes: ${note!.replaceAll('\n', ' ')}'
                    : 'No notes yet. Add notes';

                return MouseRegion(
                  onEnter: (_) {
                    if (tts.isEnabled) tts.speak(notesLabel);
                  },
                  child: Semantics(
                    label: notesLabel,
                    child: _NotesEditor(initial: note, onSave: onSaveNote),
                  ),
                );
              },
            ),
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
    this.semanticsLabel,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsProvider>();
    final label = semanticsLabel ?? '$title: $value';

    return MouseRegion(
      onEnter: (_) {
        if (tts.isEnabled) tts.speak(label);
      },
      child: Semantics(
        label: label,
        button: onTap != null,
        child: Material(
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
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
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

String _formatLongDate(DateTime date) =>
    DateFormat.yMMMMd().add_jm().format(date.toLocal());


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
