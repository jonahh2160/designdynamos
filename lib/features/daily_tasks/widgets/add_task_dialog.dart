import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:designdynamos/core/models/task_draft.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/utils/estimate_formatter.dart';
import 'package:designdynamos/features/daily_tasks/utils/task_icon_registry.dart';
import 'package:designdynamos/features/daily_tasks/widgets/tag_chip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_icon_picker.dart';
import 'package:designdynamos/providers/break_day_provider.dart';
import 'package:provider/provider.dart';

import 'package:designdynamos/providers/tts_provider.dart';


class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _estimateController = TextEditingController();
  DateTime? _dueAt;
  DateTime? _targetAt;
  int _priority = 5;
  String _selectedIcon = TaskIconRegistry.defaultOption.name;
  String? _errorText;
  String? _estimateErrorText;
  final List<TextEditingController> _subtaskControllers = [];
  final TextEditingController _labelInputController = TextEditingController();
  final Set<String> _labels = <String>{};

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _estimateController.dispose();
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
      helpText: 'Select task due date',
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
      helpText: 'Select task due time',
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

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorText = 'Please enter a task title';
      });
      return;
    }

    final rawEstimate = _estimateController.text.trim();
    final parsedEstimate = parseEstimateMinutes(rawEstimate);
    if (rawEstimate.isNotEmpty && parsedEstimate == null) {
      setState(() {
        _estimateErrorText = 'Use minutes or H:MM (e.g., 45 or 1:30)';
      });
      return;
    } else {
      _estimateErrorText = null;
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
        targetAt: _targetAt,
        priority: _priority,
        estimatedMinutes: parsedEstimate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        subtasks: subtasks,
        labels: labels,
      ),
    );
  }

  DateTime _defaultDueAt(DateTime reference) {
    final local = reference.toLocal();
    final truncated = DateTime(local.year, local.month, local.day, local.hour)
        .add(const Duration(hours: 1));
    BreakDayProvider? breakProvider;
    try {
      breakProvider = context.read<BreakDayProvider>();
    } catch (_) {
      breakProvider = null;
    }
    if (breakProvider == null) return truncated;
    final nextWorkingDay = breakProvider.nextWorkingDay(truncated);
    return DateTime(
      nextWorkingDay.year,
      nextWorkingDay.month,
      nextWorkingDay.day,
      truncated.hour,
      truncated.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsProvider>();
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
            MouseRegion(
              onEnter: (_) {
                if (tts.isEnabled) tts.speak('Task title input');
              },
              child: Semantics(
                label: 'Task title input',
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    errorText: _errorText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) {
                      final label = _dueAt != null
                          ? 'Due date ${_formattedDate(_dueAt!)}'
                          : 'Add due date';
                      if (tts.isEnabled) tts.speak(label);
                    },
                    child: Semantics(
                      label: _dueAt != null
                          ? 'Due date ${_formattedDate(_dueAt!)}'
                          : 'Add due date',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: _pickDueDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _dueAt != null ? _formattedDate(_dueAt!) : 'Add due date',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) {
                      final label = _dueAt != null
                          ? 'Due time ${_formattedTime(_dueAt!)}'
                          : 'Add due time';
                      if (tts.isEnabled) tts.speak(label);
                    },
                    child: Semantics(
                      label: _dueAt != null
                          ? 'Due time ${_formattedTime(_dueAt!)}'
                          : 'Add due time',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: _pickDueTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          _dueAt != null ? _formattedTime(_dueAt!) : 'Add due time',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) {
                      final label = _targetAt != null
                          ? 'Target date ${_formattedDate(_targetAt!)}'
                          : 'Add target date';
                      if (tts.isEnabled) tts.speak(label);
                    },
                    child: Semantics(
                      label: _targetAt != null
                          ? 'Target date ${_formattedDate(_targetAt!)}'
                          : 'Add target date',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final initial = (_targetAt ?? _dueAt ?? now).toLocal();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                            helpText: 'Select target date',
                          );
                          if (picked != null) {
                            setState(() {
                              final current = _targetAt ?? _dueAt ?? now;
                              _targetAt = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                current.hour,
                                current.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(
                          _targetAt != null
                              ? _formattedDate(_targetAt!)
                              : 'Add target date',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) {
                      final label = _targetAt != null
                          ? 'Target time ${_formattedTime(_targetAt!)}'
                          : 'Add target time';
                      if (tts.isEnabled) tts.speak(label);
                    },
                    child: Semantics(
                      label: _targetAt != null
                          ? 'Target time ${_formattedTime(_targetAt!)}'
                          : 'Add target time',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final base = (_targetAt ?? _dueAt ?? now).toLocal();
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: base.hour,
                              minute: base.minute,
                            ),
                            helpText: 'Select target time',
                          );
                          if (picked != null) {
                            setState(() {
                              final currentDate = _targetAt ?? _dueAt ?? now;
                              _targetAt = DateTime(
                                currentDate.year,
                                currentDate.month,
                                currentDate.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.access_alarm_outlined),
                        label: Text(
                          _targetAt != null
                              ? _formattedTime(_targetAt!)
                              : 'Add target time',
                        ),
                      ),
                    ),
                  ),
                ),
                if (_targetAt != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Clear target date',
                    onPressed: () => setState(() => _targetAt = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            MouseRegion(
              onEnter: (_) {
                const label = 'Estimate input. Format in minutes or H colon MM like zero colon thirty';
                if (tts.isEnabled) tts.speak(label);
              },
              child: Semantics(
                label:
                    'Estimate input. Format in minutes or H colon MM like zero colon thirty',
                child: TextField(
                  controller: _estimateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Estimate (minutes or H:MM)',
                    errorText: _estimateErrorText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            MouseRegion(
              onEnter: (_) {
                const label = 'Notes input optional';
                if (tts.isEnabled) tts.speak(label);
              },
              child: Semantics(
                label: 'Notes input optional',
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Notes (optional)'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tags(Important, Time Sensitive, etc)',
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
                  MouseRegion(
                    onEnter: (_) {
                      final label = 'Tag $name. Remove button';
                      if (tts.isEnabled) tts.speak(label);
                    },
                    child: Semantics(
                      label: 'Tag $name. Remove button',
                      button: true,
                      child: TagChip(
                        label: name,
                        onDeleted: () => setState(() => _labels.remove(name)),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 220,
                  child: MouseRegion(
                    onEnter: (_) {
                      const label = 'Add tag input. Type a label and press enter';
                      if (tts.isEnabled) tts.speak(label);
                    },
                    child: Semantics(
                      label: 'Add tag input. Type a label and press enter',
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
                MouseRegion(
                  onEnter: (_) {
                    final label = 'Priority level $_priority dropdown';
                    if (tts.isEnabled) tts.speak(label);
                  },
                  child: Semantics(
                    label: 'Priority level $_priority dropdown',
                    button: true,
                    child: DropdownButton<int>(
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
                  ),
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
                    child: MouseRegion(
                      onEnter: (_) {
                        final label = 'Subtask ${i + 1} input';
                        if (tts.isEnabled) tts.speak(label);
                      },
                      child: Semantics(
                        label: 'Subtask ${i + 1} input',
                        child: TextField(
                          controller: _subtaskControllers[i],
                          decoration:
                              InputDecoration(hintText: 'Subtask ${i + 1}'),
                        ),
                      ),
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
            MouseRegion(
              onEnter: (_) {
                const label = 'Add subtask button';
                if (tts.isEnabled) tts.speak(label);
              },
              child: Semantics(
                label: 'Add subtask button',
                button: true,
                child: TextButton.icon(
                  onPressed: () {
                    setState(
                      () => _subtaskControllers.add(TextEditingController()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add subtask'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        MouseRegion(
          onEnter: (_) {
            const label = 'Cancel button';
            if (tts.isEnabled) tts.speak(label);
          },
          child: Semantics(
            label: 'Cancel button',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) {
            const label = 'Add task button';
            if (tts.isEnabled) tts.speak(label);
          },
          child: Semantics(
            label: 'Add task button',
            button: true,
            child: ElevatedButton(onPressed: _submit, child: const Text('Add')),
          ),
        ),
      ],
    );
  }
}

String _formattedDate(DateTime date) =>
    DateFormat.yMMMMd().format(date.toLocal());

String _formattedTime(DateTime date) => DateFormat.jm().format(date.toLocal());
