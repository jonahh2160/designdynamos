import 'package:designdynamos/core/models/tag_info.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/core/widgets/action_chip_button.dart';
import 'package:designdynamos/core/widgets/status_pip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/add_task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/finished_section_header.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_detail_panel.dart';
import 'package:designdynamos/features/dashboard/utils/dashboard_constants.dart';
import 'package:flutter/material.dart';


class DailyTaskScreen extends StatelessWidget {
  const DailyTaskScreen({super.key});
  @override
  Widget build(BuildContext context) {
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
                    const ProgressOverview(
                      completed: 8,
                      total: 11,
                      coins: 600,
                      streakLabel: '8/11 tasks completed',
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
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final task in DashboardConstants.todayTasks)
                              TaskCard(task: task),
                            const SizedBox(height: 16),
                            const FinishedSectionHeader(title: 'Finished - 8'),
                            const SizedBox(height: 12),
                            for (final task in DashboardConstants.completedTasks)
                              TaskCard(task: task),
                            const SizedBox(height: 16),
                            const AddTaskCard(),
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