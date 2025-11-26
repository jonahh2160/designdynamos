import 'dart:math' as math;

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
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/providers/coin_provider.dart';

import 'package:intl/intl.dart';
import 'package:designdynamos/core/models/task_item.dart';

class DailyTaskScreen extends StatefulWidget {
  const DailyTaskScreen({super.key});
  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  bool _isAdding = false;
  StreamSubscription<AuthState>? _authSub;

  Future<void> _openFilterSheet() async {
    final p = context.read<TaskProvider>();
    DateTime day = p.day;
    bool includeOverdue = p.includeOverdue;
    bool includeSpanning = p.includeSpanning;
    bool includeUndated = p.includeUndated;
    bool sortByEstimate = p.sortByEstimate;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Daily Filters',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            day = DateTime.now();
                            includeOverdue = true;
                            includeSpanning = true;
                            includeUndated = false;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Day'),
                    subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(day)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: day,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => day = picked);
                      }
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include overdue'),
                    value: includeOverdue,
                    onChanged: (v) => setState(() => includeOverdue = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include spanning window'),
                    subtitle: const Text(
                      'Show tasks where day falls within start → due',
                    ),
                    value: includeSpanning,
                    onChanged: (v) => setState(() => includeSpanning = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include undated backlog'),
                    value: includeUndated,
                    onChanged: (v) => setState(() => includeUndated = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sort by longest estimate first'),
                    value: sortByEstimate,
                    onChanged: (v) => setState(() => sortByEstimate = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await context.read<TaskProvider>().refreshDaily(
                            day: day,
                            includeOverdue: includeOverdue,
                            includeSpanning: includeSpanning,
                            includeUndated: includeUndated,
                          );
                          context
                              .read<TaskProvider>()
                              .setSortByEstimate(sortByEstimate);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    //initial fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        context.read<TaskProvider>().refreshToday();
        context.read<CoinProvider>().refresh();
      }
    });

    //ensuring we refresh once auth session is available (e.g., after app start) and refetch when auth state changes
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      if (event.session != null) {
        context.read<TaskProvider>().refreshToday();
        context.read<CoinProvider>().refresh();
      } else {
        context.read<CoinProvider>().reset();
      }
    });
  }

  Future<void> _toggleTaskCompletion(
    TaskProvider provider,
    CoinProvider coinProvider,
    TaskItem task,
    bool done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.toggleDone(task.id, done);
      await coinProvider.refresh();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update task: $error')),
      );
    }
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
    final coins = context.watch<CoinProvider>();
    if (p.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final open = p.today.where((t) => !t.isDone).toList();
    final finished = p.today.where((t) => t.isDone).toList();
    final selectedTaskId = p.selectedTask?.id;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;
              final detailTask = p.selectedTask;
              final detailPanel = detailTask == null
                  ? null
                  : TaskDetailPanel(
                      task: detailTask,
                      subtasks: p.subtasksOf(detailTask.id),
                      labels: p.labelsOf(detailTask.id),
                      note: p.noteOf(detailTask.id),
                      onToggleComplete: (done) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        await _toggleTaskCompletion(
                          p,
                          context.read<CoinProvider>(),
                          task,
                          done,
                        );
                      },
                      onTargetAtChange: (date) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await p.updateTask(task.id, targetDatePart: date);
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update target date: $error',
                              ),
                            ),
                          );
                        }
                      },
                      onTargetTimeChange: (timeOfDay) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await p.updateTask(task.id, targetTime: timeOfDay);
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update target time: $error',
                              ),
                            ),
                          );
                        }
                      },
                      onClearTargetAt: () async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await p.updateTask(task.id, clearTargetAt: true);
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to clear target date: $error',
                              ),
                            ),
                          );
                        }
                      },
                      onDueAtChange: (date) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await p.updateTask(task.id, dueDatePart: date);
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update due date: $error',
                              ),
                            ),
                          );
                        }
                      },
                      onDueTimeChange: (timeOfDay) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await p.updateTask(task.id, dueTime: timeOfDay);
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update due time: $error',
                              ),
                            ),
                          );
                        }
                      },
                      onEstimateChange: (minutes) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await p.updateTask(
                            task.id,
                            estimatedMinutes: minutes,
                            clearEstimatedMinutes: minutes == null,
                          );
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update estimate: $error',
                              ),
                            ),
                          );
                        }
                      },
                      onClearEstimate: () async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await p.updateTask(
                            task.id,
                            clearEstimatedMinutes: true,
                          );
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to clear estimate: $error',
                              ),
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
                              content: Text(
                                'Failed to update priority: $error',
                              ),
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
                      onAddSubtask: (title) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        await p.addSubtask(task.id, title);
                      },
                      onToggleSubtask: (sid, done) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        await p.toggleSubtask(task.id, sid, done);
                      },
                      onDeleteSubtask: (sid) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        await p.deleteSubtask(task.id, sid);
                      },
                      onDeleteTask: () async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        await p.deleteTask(task.id);
                      },
                      onToggleLabel: (name, enabled) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        await p.toggleLabel(task.id, name, enabled);
                      },
                      onSaveNote: (content) async {
                        final task = p.selectedTask;
                        if (task == null) return;
                        await p.setNote(task.id, content);
                      },
                      onClose: () => p.selectTask(null),
                    );

              final availableWidth = constraints.maxWidth;
              final panelWidth = math.max(
                280.0,
                math.min(availableWidth * 0.34, 380.0),
              );
              final availableHeight = MediaQuery.of(context).size.height;
              final compactPanelHeight = math.min(availableHeight * 0.6, 560.0);

              final taskColumn = Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressOverview(
                      completed: finished.length,
                      total: p.today.length,
                      coins: coins.totalCoins,
                      streakLabel:
                          '${finished.length}/${p.today.length} tasks completed',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('MMMM d').format(p.day),
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
                        ActionChipButton(
                          icon: Icons.filter_list,
                          label: 'Filter',
                          onTap: _openFilterSheet,
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
                                onToggle: () {
                                  _toggleTaskCompletion(
                                    p,
                                    context.read<CoinProvider>(),
                                    task,
                                    !task.isDone,
                                  );
                                },
                                subtaskDone: p.subtaskProgress(task.id).$1,
                                subtaskTotal: p.subtaskProgress(task.id).$2,
                                labels: p.labelsOf(task.id),
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
                                onToggle: () {
                                  _toggleTaskCompletion(
                                    p,
                                    context.read<CoinProvider>(),
                                    task,
                                    !task.isDone,
                                  );
                                },
                                subtaskDone: p.subtaskProgress(task.id).$1,
                                subtaskTotal: p.subtaskProgress(task.id).$2,
                                labels: p.labelsOf(task.id),
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
              );

              final children = <Widget>[taskColumn];

              if (detailPanel != null) {
                children.add(
                  isCompact
                      ? const SizedBox(height: 24)
                      : const SizedBox(width: 24),
                );
                final boundedPanel = isCompact
                    ? SizedBox(height: compactPanelHeight, child: detailPanel)
                    : SizedBox(width: panelWidth, child: detailPanel);
                if (isCompact) {
                  children.add(
                    Flexible(flex: 0, fit: FlexFit.loose, child: boundedPanel),
                  );
                } else {
                  children.add(boundedPanel);
                }
              }

              return Flex(
                direction: isCompact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
