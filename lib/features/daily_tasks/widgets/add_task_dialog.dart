import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:designdynamos/core/models/task_draft.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/utils/task_icon_registry.dart';
import 'package:designdynamos/features/daily_tasks/widgets/tag_chip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_icon_picker.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _dueAt = _defaultDueAt(DateTime.now());
  int _priority = 5;
  String _selectedIcon = TaskIconRegistry.defaultOption.name;
  String? _errorText;
  final List<TextEditingController> _subtaskControllers = [];
  final TextEditingController _labelInputController = TextEditingController();
  final Set<String> _labels = <String>{};

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (final c in _subtaskControllers) {
      c.dispose();
    }
    _labelInputController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = (_dueAt ?? _defaultDueAt(now)).toLocal();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select due date',
    );

    if (picked != null) {
      setState(() {
        final current = _dueAt ?? _defaultDueAt(now);
        _dueAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          current.hour,
          current.minute,
        );
      });
    }
  }

  Future<void> _pickDueTime() async {
    final now = DateTime.now();
    final base = (_dueAt ?? _defaultDueAt(now)).toLocal();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      helpText: 'Select due time',
    );
    if (picked != null) {
      setState(() {
        final currentDate = _dueAt ?? _defaultDueAt(now);
        _dueAt = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _clearDueAt() {
    setState(() {
      _dueAt = null;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorText = 'Please enter a task title';
      });
      return;
    }

    final subtasks = _subtaskControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final labels = Set<String>.from(_labels);

    Navigator.of(context).pop(
      TaskDraft(
        title: title,
        iconName: _selectedIcon,
        dueAt: _dueAt ?? _defaultDueAt(DateTime.now()),
        priority: _priority,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        subtasks: subtasks,
        labels: labels,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'Add task',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Task title',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _dueAt != null ? _formattedDate(_dueAt!) : 'Add due date',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDueTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _dueAt != null ? _formattedTime(_dueAt!) : 'Add due time',
                    ),
                  ),
                ),
                if (_dueAt != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Clear due date',
                    onPressed: _clearDueAt,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Notes (optional)'),
            ),
            const SizedBox(height: 16),
            Text(
              'Labels',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _labels)
                  TagChip(
                    label: name,
                    onDeleted: () => setState(() => _labels.remove(name)),
                  ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _labelInputController,
                    decoration: const InputDecoration(
                      hintText: 'Add label and press Enter',
                    ),
                    onSubmitted: (value) {
                      final name = value.trim();
                      if (name.isEmpty) return;
                      setState(() {
                        _labels.add(name);
                        _labelInputController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _priority,
                  dropdownColor: AppColors.surface,
                  items: [
                    for (var value = 1; value <= 10; value++)
                      DropdownMenuItem(
                        value: value,
                        child: Text('Level $value'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _priority = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Icon',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TaskIconPicker(
              selectedName: _selectedIcon,
              onChanged: (value) {
                setState(() {
                  _selectedIcon = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Subtasks',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _subtaskControllers.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskControllers[i],
                      decoration: InputDecoration(hintText: 'Subtask ${i + 1}'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () {
                      setState(() {
                        final c = _subtaskControllers.removeAt(i);
                        c.dispose();
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: () {
                setState(
                  () => _subtaskControllers.add(TextEditingController()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add subtask'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

DateTime _defaultDueAt(DateTime reference) {
  final local = reference.toLocal();
  final truncated = DateTime(local.year, local.month, local.day, local.hour);
  return truncated.add(const Duration(hours: 1));
}

String _formattedDate(DateTime date) =>
    DateFormat.yMMMMd().format(date.toLocal());

String _formattedTime(DateTime date) => DateFormat.jm().format(date.toLocal());
