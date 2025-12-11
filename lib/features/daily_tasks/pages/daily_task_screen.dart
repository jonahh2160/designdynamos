import 'dart:async';
import 'dart:math' as math;

import 'package:designdynamos/core/models/task_draft.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/core/widgets/action_chip_button.dart';
import 'package:designdynamos/features/daily_tasks/widgets/add_task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/add_task_dialog.dart';
import 'package:designdynamos/features/daily_tasks/widgets/finished_section_header.dart';
import 'package:designdynamos/features/daily_tasks/widgets/overdue_task_alert.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/meta_chip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_detail_panel.dart';
import 'package:designdynamos/features/dashboard/widgets/progress_overview.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/providers/coin_provider.dart';
import 'package:designdynamos/providers/break_day_provider.dart';

class DailyTaskScreen extends StatefulWidget {
  const DailyTaskScreen({super.key});
  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  bool _isAdding = false;
  StreamSubscription<AuthState>? _authSub;

  bool _overdueExpanded = true;
  bool _showSuggestions = false;

  Future<void> _openFilterSheet() async {
    final p = context.read<TaskProvider>();
    final breakProvider = context.read<BreakDayProvider>();
    DateTime day = p.day;
    bool includeOverdue = p.includeOverdue;
    bool includeSpanning = p.includeSpanning;
    bool sortByEstimate = p.sortByEstimate;
    try {
      await breakProvider.ensureCovers(day);
    } catch (error) {
      debugPrint('Failed to refresh break days: $error');
    }
    bool isBreakDay = breakProvider.isBreakDay(day);

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
                        await breakProvider.ensureCovers(picked);
                        setState(() {
                          isBreakDay = breakProvider.isBreakDay(picked);
                        });
                      }
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark this day as a break'),
                    subtitle: const Text(
                      'Breaks pause streak requirements and are skipped by default scheduling.',
                    ),
                    value: isBreakDay,
                    onChanged: (v) => setState(() => isBreakDay = v),
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
                      'Show tasks where the day falls between start and due',
                    ),
                    value: includeSpanning,
                    onChanged: (v) => setState(() => includeSpanning = v),
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
                          final taskProvider = context.read<TaskProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(context).pop();
                          try {
                            await breakProvider.ensureCovers(day);
                            final currentlyBreak = breakProvider.isBreakDay(day);
                            if (isBreakDay != currentlyBreak) {
                              await breakProvider.setBreakDay(day, isBreakDay);
                            }
                            await taskProvider.refreshDaily(
                                  day: day,
                                  includeOverdue: includeOverdue,
                                  includeSpanning: includeSpanning,
                                );
                            taskProvider.setSortByEstimate(sortByEstimate);
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to apply filters: $error',
                                ),
                              ),
                            );
                          }
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        context
            .read<TaskProvider>()
            .refreshToday()
            .catchError((error) => debugPrint('refreshToday failed: $error'));
        context.read<CoinProvider>().refresh();
        context
            .read<BreakDayProvider>()
            .ensureCovers(DateTime.now())
            .catchError((error) => debugPrint('ensureCovers failed: $error'));
      }
    });

    //ensuring we refresh once auth session is available (e.g., after app start) and refetch when auth state changes
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      if (event.session != null) {
        context
            .read<TaskProvider>()
            .refreshToday()
            .catchError((error) => debugPrint('refreshToday failed: $error'));
        context.read<CoinProvider>().refresh();
        context
            .read<BreakDayProvider>()
            .ensureCovers(DateTime.now())
            .catchError((error) => debugPrint('ensureCovers failed: $error'));
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
    final breakProvider = context.watch<BreakDayProvider>();
    if (p.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isBreakDay = breakProvider.isBreakDay(p.day);

    final open = p.today.where((t) {
      //Exclude finished tasks
      if (t.isDone) return false;

      //Exclude overdue from open only if the filter is off
      if (!p.includeOverdue && p.overdueTasks.contains(t)) return false;

      //Otherwise include it
      return true;
    }).toList()
      ..sort((a,b) => a.orderHint.compareTo(b.orderHint)); //Order sorting [MJ]

    final finished = p.today.where((t) => t.isDone)
      .toList()
      ..sort((a, b) => a.orderHint.compareTo(b.orderHint)); //Order sorting [MJ]
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
                    if (isBreakDay)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.sidebarActive.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.taskCardHighlight.withOpacity(0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.beach_access,
                                color: AppColors.taskCardHighlight,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Break day: tasks are optional and your streak is paused.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    await context
                                        .read<BreakDayProvider>()
                                        .setBreakDay(p.day, false);
                                  } catch (error) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to end break: $error'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Resume'),
                              ),
                            ],
                          ),
                        ),
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
                        ActionChipButton(
                          icon: Icons.auto_awesome,
                          label: _showSuggestions ? 'Hide suggestions' : 'Suggestions',
                          onTap: () {
                            setState(() {
                              _showSuggestions = !_showSuggestions;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        ActionChipButton(
                          icon: Icons.add,
                          label: 'Add task',
                          onTap: _handleAddTask,
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
                    const SizedBox(height: 12),
                            ExpansionTile(
                              key: const PageStorageKey('overdueTasks'),
                              initiallyExpanded: _overdueExpanded,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _overdueExpanded = expanded;
                                });
                              },
                              leading: Icon(
                                p.overdueTasks.isNotEmpty ? Icons.warning : Icons.check_circle,
                                color: p.overdueTasks.isNotEmpty ? Colors.red : Colors.green,
                              ),
                              title: Text(
                                p.overdueTasks.isNotEmpty
                                    ? 'Overdue assignments need attention!'
                                    : 'No overdue assignments',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              children: [
                                if (p.overdueTasks.isNotEmpty)
                                  for (final overdue in p.overdueTasks)
                                    OverdueTaskAlert(
                                      task: overdue,
                                      onDelete: (task) async => await p.deleteTask(task.id),
                                      onComplete: (task) async => await p.toggleDone(task.id, true),
                                      onMoveDate: (task) async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null) {
                                          await p.updateTask(task.id, dueDatePart: picked);
                                        }
                                      }
                                    ),
                              ],
                            ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ReorderableListView(
                              physics:
                                  const NeverScrollableScrollPhysics(), //disable inner scroll
                              shrinkWrap: true, //shrink to fit children
                              onReorder: (oldIndex, newIndex) async {
                                if (newIndex > oldIndex) newIndex--;

                                final moved = open.removeAt(oldIndex);
                                open.insert(newIndex, moved);

                                for (int i = 0; i < open.length; i++) {
                                  open[i] = open[i].copyWith(orderHint: i);
                                }

                                for (final t in open) {
                                  await context
                                      .read<TaskProvider>()
                                      .updateTaskOrder(t.id, t.orderHint);
                                }
                              },
                              children: [
                                for (final task in open)
                                  TaskCard(
                                    key: ValueKey(task.id),
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
                                    subtaskTotal:
                                        p.subtaskProgress(task.id).$2,
                                    labels: p.labelsOf(task.id),
                                  ),
                              ],
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

              if (_showSuggestions || detailPanel != null) {
                final suggestionsPanel = _SuggestionsPanel(
                  suggestions: p.suggestedTasks,
                  isLoading: p.isLoading,
                  onRefresh: () => p.refreshToday(),
                  onSelect: (task) => p.selectTask(task.id),
                  onComplete: (task) {
                    _toggleTaskCompletion(
                      p,
                      context.read<CoinProvider>(),
                      task,
                      true,
                    );
                  },
                );

                Widget sidePanel;
                if (_showSuggestions && detailPanel != null) {
                  sidePanel = Column(
                    children: [
                      suggestionsPanel,
                      const SizedBox(height: 16),
                      Expanded(child: detailPanel),
                    ],
                  );
                } else if (_showSuggestions) {
                  sidePanel = suggestionsPanel;
                } else {
                  sidePanel = detailPanel!;
                }

                children.add(
                  isCompact
                      ? const SizedBox(height: 24)
                      : const SizedBox(width: 24),
                );

                final boundedPanel = isCompact
                    ? SizedBox(height: compactPanelHeight, child: sidePanel)
                    : SizedBox(width: panelWidth, child: sidePanel);
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

class _SuggestionsPanel extends StatelessWidget {
  const _SuggestionsPanel({
    required this.suggestions,
    required this.isLoading,
    required this.onRefresh,
    required this.onSelect,
    required this.onComplete,
  });

  final List<SuggestedTask> suggestions;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(TaskItem task) onSelect;
  final void Function(TaskItem task) onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sidebarActive.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Suggested for today',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textMuted),
                tooltip: 'Refresh suggestions',
                onPressed: isLoading ? null : onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Overdue and due-soon tasks are prioritized. Shorter, higher-priority tasks bubble up.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.taskCardHighlight,
              backgroundColor: AppColors.progressTrack,
            ),
          if (!isLoading) ...[
            if (suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No tasks scheduled for today—add or reschedule to see suggestions.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 320,
                child: ListView.separated(
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    final task = suggestion.task;
                    final dueLabel = _dueLabel(task.dueAt);
                    final priorityColors = buildPriorityChipColors(task.priority);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.detailCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.sidebarActive.withOpacity(0.8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                dueLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _pill(
                                icon: Icons.flag,
                                label: 'Priority ${task.priority}',
                                color: priorityColors.background,
                                textColor: priorityColors.foreground,
                                borderColor: priorityColors.border,
                                borderWidth: 1.2,
                              ),
                              if (task.estimatedMinutes != null)
                                _pill(
                                  icon: Icons.timer,
                                  label: '${task.estimatedMinutes} min',
                                ),
                              if (task.goalStepId != null || task.goalId != null)
                                _pill(
                                  icon: Icons.checklist,
                                  label: 'Linked to goal',
                                ),
                              if (suggestion.warnings.isNotEmpty)
                                ...suggestion.warnings.map(
                                  (w) => _pill(
                                    icon: Icons.warning_amber_rounded,
                                    label: w,
                                    color: Colors.orangeAccent.withOpacity(0.2),
                                    textColor: Colors.orangeAccent,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => onSelect(task),
                                child: const Text('View / Edit'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => onComplete(task),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Mark done'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    Color color = const Color(0xFF203743),
    Color textColor = AppColors.textSecondary,
    Color? borderColor,
    double borderWidth = 1.1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor ?? AppColors.sidebarActive.withOpacity(0.8),
          width: borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _dueLabel(DateTime? due) {
    if (due == null) return 'No due date';
    final local = due.toLocal();
    final today = DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final endToday = startToday.add(const Duration(days: 1));

    if (local.isBefore(startToday)) return 'Overdue';
    if (!local.isAfter(endToday)) return 'Due today';
    final diffDays = local.difference(startToday).inDays;
    if (diffDays <= 2) return 'Due in $diffDays day${diffDays == 1 ? '' : 's'}';
    return DateFormat('MMM d').format(local);
  }
}
