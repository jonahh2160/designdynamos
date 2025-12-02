import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:designdynamos/core/models/goal.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/models/goal_draft.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/goals/widgets/goal_detail_panel.dart';
import 'package:designdynamos/features/goals/widgets/goal_summary_card.dart';
import 'package:designdynamos/providers/goal_provider.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String? _deletingGoalId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final selectedGoal = goalProvider.selectedGoal;
    final goals = goalProvider.goals;
    final tasksById = {for (final task in taskProvider.today) task.id: task};

    final Widget body;
    if (goalProvider.isLoading && goals.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (goals.isEmpty) {
      body = _EmptyState(
        onRefresh: () => goalProvider.refresh(),
        onCreateGoal: () => _openCreateGoalSheet(context),
      );
    } else {
      body = _GoalLayout(
        goals: goals,
        selectedGoalId: selectedGoal?.id,
        onSelectGoal: (id) => goalProvider.selectGoal(id),
        detailPanel: GoalDetailPanel(
          goal: selectedGoal,
          tasksById: tasksById,
          onToggleTask: (task, done) async {
            await taskProvider.toggleDone(task.id, done);
            await goalProvider.refresh();
          },
          onAddTask: () => _openAttachSheet(
            context,
            selectedGoal,
            goals,
            taskProvider.unassignedTasks,
          ),
          onClose: () => goalProvider.selectGoal(null),
          onUpdateMeta:
              ({DateTime? startAt, DateTime? dueAt, int? priority}) async {
                final current = goalProvider.selectedGoal;
                if (current == null) return;
                await goalProvider.updateGoalMeta(
                  current,
                  startAt: startAt,
                  dueAt: dueAt,
                  priority: priority,
                );
              },
          onDelete: selectedGoal == null
              ? null
              : () => _confirmDeleteGoal(context, selectedGoal),
          isDeleting: _deletingGoalId == selectedGoal?.id,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Goals',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _openCreateGoalSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Goal'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachSheet(
    BuildContext context,
    Goal? selectedGoal,
    List<Goal> goals,
    List<TaskItem> unassigned,
  ) async {
    if (selectedGoal == null) return;
    if (unassigned.isEmpty || selectedGoal.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unassigned.isEmpty
                ? 'No available tasks to attach'
                : 'Goal has no steps yet',
          ),
        ),
      );
      return;
    }
    final taskProvider = context.read<TaskProvider>();
    final goalProvider = context.read<GoalProvider>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.detailCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AttachTaskSheet(
        goal: selectedGoal,
        tasks: unassigned,
        onSubmit: (stepId, taskId) async {
          final step = selectedGoal.steps.firstWhere((s) => s.id == stepId);
          final task = unassigned.firstWhere((t) => t.id == taskId);
          final navigator = Navigator.of(context);
          await goalProvider.assignTaskToStep(selectedGoal, step, task.id);
          await taskProvider.assignTaskToStep(task.id, step.id);
          if (!mounted) return;
          navigator.pop();
        },
      ),
    );
  }

  Future<void> _openCreateGoalSheet(BuildContext context) async {
    final provider = context.read<GoalProvider>();
    final draft = await showModalBottomSheet<GoalDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.detailCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _CreateGoalSheet(),
    );
    if (draft == null) return;
    await provider.createGoal(draft);
    await provider.refresh();
  }

  Future<void> _confirmDeleteGoal(BuildContext context, Goal goal) async {
    final goalProvider = context.read<GoalProvider>();
    final taskProvider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?'),
        content: const Text(
          'This will remove the goal, its steps, and unlink any attached tasks. '
          'Tasks will stay in your task list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _deletingGoalId = goal.id);
    try {
      await goalProvider.deleteGoal(goal);
      await taskProvider.refreshToday();
      await goalProvider.refresh();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Goal "${goal.title}" deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete goal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingGoalId = null);
      }
    }
  }
}

class _GoalLayout extends StatelessWidget {
  const _GoalLayout({
    required this.goals,
    required this.selectedGoalId,
    required this.onSelectGoal,
    required this.detailPanel,
  });

  final List<Goal> goals;
  final String? selectedGoalId;
  final void Function(String goalId) onSelectGoal;
  final Widget detailPanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;
        final goalList = _GoalList(
          goals: goals,
          selectedGoalId: selectedGoalId,
          onSelectGoal: onSelectGoal,
        );

        if (!isWide) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [goalList, const SizedBox(height: 24), detailPanel],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: SingleChildScrollView(child: goalList)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: detailPanel),
          ],
        );
      },
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({
    required this.goals,
    required this.selectedGoalId,
    required this.onSelectGoal,
  });

  final List<Goal> goals;
  final String? selectedGoalId;
  final void Function(String goalId) onSelectGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final goal in goals)
          GoalSummaryCard(
            goal: goal,
            selected: goal.id == selectedGoalId,
            onTap: () => onSelectGoal(goal.id),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh, required this.onCreateGoal});

  final Future<void> Function() onRefresh;
  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No goals yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreateGoal,
            icon: const Icon(Icons.add),
            label: const Text('Create your first goal'),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _AttachTaskSheet extends StatefulWidget {
  const _AttachTaskSheet({
    required this.goal,
    required this.tasks,
    required this.onSubmit,
  });

  final Goal goal;
  final List<TaskItem> tasks;
  final Future<void> Function(String stepId, String taskId) onSubmit;

  @override
  State<_AttachTaskSheet> createState() => _AttachTaskSheetState();
}

class _AttachTaskSheetState extends State<_AttachTaskSheet> {
  String? _selectedStepId;
  String? _selectedTaskId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal.steps.isNotEmpty) {
      _selectedStepId = widget.goal.steps.first.id;
    }
    if (widget.tasks.isNotEmpty) {
      _selectedTaskId = widget.tasks.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add task to ${widget.goal.title}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStepId,
            decoration: const InputDecoration(labelText: 'Goal step'),
            items: widget.goal.steps
                .map(
                  (step) =>
                      DropdownMenuItem(value: step.id, child: Text(step.title)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedStepId = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTaskId,
            decoration: const InputDecoration(labelText: 'Task'),
            items: widget.tasks
                .map(
                  (task) =>
                      DropdownMenuItem(value: task.id, child: Text(task.title)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedTaskId = value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _saving || _selectedStepId == null || _selectedTaskId == null
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await widget.onSubmit(
                          _selectedStepId!,
                          _selectedTaskId!,
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Adding...' : 'Add task'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGoalSheet extends StatefulWidget {
  const _CreateGoalSheet();

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _stepControllers = [
    TextEditingController(),
  ];
  DateTime? _startAt;
  DateTime? _dueAt;
  int _priority = 5;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Goal',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Start date',
                    value: _startAt,
                    onSelected: (date) => setState(() => _startAt = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: 'Due date',
                    value: _dueAt,
                    onSelected: (date) => setState(() => _dueAt = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: [
                for (var value = 1; value <= 10; value++)
                  DropdownMenuItem(value: value, child: Text('Level $value')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Steps',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _stepControllers.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stepControllers[i],
                      decoration: InputDecoration(labelText: 'Step ${i + 1}'),
                    ),
                  ),
                  IconButton(
                    onPressed: _stepControllers.length == 1
                        ? null
                        : () {
                            setState(() {
                              final controller = _stepControllers.removeAt(i);
                              controller.dispose();
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
                setState(() {
                  _stepControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add step'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Creating...' : 'Create goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Please enter a goal title');
      return;
    }
    if (_startAt == null || _dueAt == null) {
      setState(() => _errorText = 'Start and due dates are required');
      return;
    }
    if (_dueAt!.isBefore(_startAt!)) {
      setState(() => _errorText = 'Due date must be after start date');
      return;
    }
    setState(() {
      _errorText = null;
      _submitting = true;
    });
    final steps = _stepControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final draft = GoalDraft(
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      startAt: _startAt!,
      dueAt: _dueAt!,
      steps: steps,
    );
    if (!mounted) return;
    Navigator.of(context).pop(draft);
  }

}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select date'
        : DateFormat.yMMMMd().format(value!);
    return OutlinedButton(
      onPressed: () async {
        final now = DateTime.now();
        final initial = value ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) {
          onSelected(DateTime(picked.year, picked.month, picked.day));
        }
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
