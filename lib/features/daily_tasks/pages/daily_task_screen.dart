import 'package:designdynamos/core/models/task_draft.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/core/widgets/action_chip_button.dart';
import 'package:designdynamos/features/daily_tasks/widgets/add_task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/add_task_dialog.dart';
import 'package:designdynamos/features/daily_tasks/widgets/finished_section_header.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_detail_panel.dart';
import 'package:designdynamos/features/dashboard/widgets/progress_overview.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DailyTaskScreen extends StatefulWidget {
  const DailyTaskScreen({super.key});
  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TaskProvider>().refreshToday(),
    );
  }

  Future<void> _handleAddTask() async {
    if (_isAdding) return;

    final draft = await showDialog<TaskDraft>(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );

    if (draft == null) return;
    if (!mounted) return;

    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isAdding = true);
    try {
      await provider.createTask(draft);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Task added')));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to add task: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    if (p.isLoading) return const Center(child: CircularProgressIndicator());

    final open = p.today.where((t) => !t.isDone).toList();
    final finished = p.today.where((t) => t.isDone).toList();
    final selectedTaskId = p.selectedTask?.id;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressOverview(
                      completed: finished.length,
                      total: p.today.length,
                      coins: 600, //TODO: read from profile provider
                      streakLabel:
                          '${finished.length}/${p.today.length} tasks completed',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateTime.now()
                                .toIso8601String(), //TODO: Convert to fromat October 20
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        const ActionChipButton(
                          icon: Icons.auto_awesome,
                          label: 'Suggestions',
                        ),
                        const SizedBox(width: 12),
                        const ActionChipButton(
                          icon: Icons.filter_list,
                          label: 'Filter',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final task in open)
                              TaskCard(
                                task: task,
                                isSelected: task.id == selectedTaskId,
                                onTap: () => p.selectTask(task.id),
                                onToggle: () => context
                                    .read<TaskProvider>()
                                    .toggleDone(task.id, !task.isDone),
                              ),
                            const SizedBox(height: 16),
                            FinishedSectionHeader(
                              title: 'Finished - ${finished.length}',
                            ),
                            const SizedBox(height: 12),
                            for (final task in finished)
                              TaskCard(
                                task: task,
                                isSelected: task.id == selectedTaskId,
                                onTap: () => p.selectTask(task.id),
                                onToggle: () => context
                                    .read<TaskProvider>()
                                    .toggleDone(task.id, !task.isDone),
                              ),
                            const SizedBox(height: 16),
                            AddTaskCard(
                              onPressed: _handleAddTask,
                              isLoading: _isAdding || p.isCreating,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 320,
                child: TaskDetailPanel(
                  task: p.selectedTask,
                  onToggleComplete: (done) async {
                    final task = p.selectedTask;
                    if (task == null) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await p.toggleDone(task.id, done);
                    } catch (error) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update task: $error'),
                        ),
                      );
                    }
                  },
                  onDueDateChange: (date) async {
                    final task = p.selectedTask;
                    if (task == null) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await p.updateTask(task.id, dueDate: date);
                    } catch (error) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update due date: $error'),
                        ),
                      );
                    }
                  },
                  onClearDueDate: () async {
                    final task = p.selectedTask;
                    if (task == null) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await p.updateTask(task.id, clearDueDate: true);
                    } catch (error) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to clear due date: $error'),
                        ),
                      );
                    }
                  },
                  onPriorityChange: (priority) async {
                    final task = p.selectedTask;
                    if (task == null) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await p.updateTask(task.id, priority: priority);
                    } catch (error) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update priority: $error'),
                        ),
                      );
                    }
                  },
                  onIconChange: (iconName) async {
                    final task = p.selectedTask;
                    if (task == null) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await p.updateTask(task.id, iconName: iconName);
                    } catch (error) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update icon: $error'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
