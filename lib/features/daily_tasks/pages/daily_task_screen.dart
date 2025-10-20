import 'package:designdynamos/core/models/tag_info.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/core/widgets/action_chip_button.dart';
import 'package:designdynamos/core/widgets/status_pip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/add_task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/finished_section_header.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_detail_panel.dart';
import 'package:designdynamos/features/dashboard/utils/dashboard_constants.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';




class DailyTaskScreen extends StatefulWidget {
  const DailyTaskScreen({super.key});
  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TaskProvider>().refreshToday());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    if (p.isLoading) return const Center(child: CircularProgressIndicator());

    final open = p.today.where((t) => !t.isDone).toList();
    final finished = p.today.where((t) => t.isDone).toList();

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
                      streakLabel: '${finished.length}/${p.today.length} tasks completed',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'October 4',
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
                                onToggle: () => context.read<TaskProvider>().toggle(task.id, !task.isDone),
                              ),
                            const SizedBox(height: 16),
                            FinishedSectionHeader(title: 'Finished - ${finished.length}'),
                            const SizedBox(height: 12),
                            for (final task in finished)
                              TaskCard(
                                task: task,
                                onToggle: () => context.read<TaskProvider>().toggle(task.id, !task.isDone),
                              ),
                            const SizedBox(height: 16),
                            AddTaskCard(), // wire onTap => show dialog to addQuickTask
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              const SizedBox(
                width: 300,
                child: TaskDetailPanel(
                  title: 'Make Bed',
                  score: 9,
                  subtasks: DashboardConstants.makeBedSubtasks,
                  tags: [
                    TagInfo(label: 'Due Oct. 4', icon: Icons.event_available),
                    TagInfo(label: 'Goals', icon: Icons.flag_outlined),
                    TagInfo(
                      label: 'Self Care',
                      icon: Icons.local_florist_outlined,
                    ),
                    TagInfo(
                      label: 'Priority 9',
                      icon: Icons.priority_high_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}