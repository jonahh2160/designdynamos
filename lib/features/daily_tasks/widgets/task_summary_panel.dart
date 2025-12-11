import 'package:designdynamos/core/models/subtask_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/widgets/icon_container.dart';
import 'package:designdynamos/features/daily_tasks/widgets/status_pip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/subtask_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';

class TaskSummaryCard extends StatelessWidget {
  const TaskSummaryCard({
    super.key,
    required this.title,
    required this.score,
    required this.subtasks,
  });

  final String title;
  final int score;
  final List<SubtaskItem> subtasks;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsProvider>();
    final summaryLabel = 'Task Summary Card for $title with priority $score and ${subtasks.length} subtasks';

    return MouseRegion(
      onEnter: (_) {
        if (tts.isEnabled) tts.speak(summaryLabel);
      },
      child: Semantics(
        container: true,
        label: summaryLabel,
        child: Container(
        decoration: BoxDecoration(
          color: AppColors.detailCard,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Row(
                children: [
                  const StatusPip(isCompleted: false),
                  MouseRegion(
                    onEnter: (_) {
                      if (tts.isEnabled) tts.speak('Task status: incomplete');
                    },
                    child: Semantics(
                      label: 'Task status: incomplete',
                      child: const StatusPip(isCompleted: false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconContainer(icon: Icons.bed, isCompleted: false),
                  MouseRegion(
                    onEnter: (_) {
                      if (tts.isEnabled) tts.speak('Task category icon');
                    },
                    child: Semantics(
                      label: 'Task category icon',
                      child: IconContainer(icon: Icons.bed, isCompleted: false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MouseRegion(
                        onEnter: (_) {
                          if (tts.isEnabled) tts.speak(title);
                        },
                        child: Semantics(
                          header: true,
                          label: title,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      MouseRegion(
                        onEnter: (_) {
                          if (tts.isEnabled) tts.speak('Priority $score');
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Semantics(
                              label: 'Priority $score',
                              child: Text(
                                'Priority $score',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  onEnter: (_) {
                    if (tts.isEnabled) tts.speak('Delete task');
                  },
                  child: Semantics(
                    label: 'Delete task',
                    button: true,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
            const SizedBox(height: 16),
            for (final subtask in subtasks) ...[
              MouseRegion(
                onEnter: (_) {
                  if (tts.isEnabled) tts.speak('${subtask.title}${subtask.completed ? ', completed' : ', not completed'}');
                },
                child: Semantics(
                  label: '${subtask.title}${subtask.completed ? ', completed' : ', not completed'}',
                  child: SubtaskRow(subtask: subtask),
                ),
              ),
              const SizedBox(height: 12),
            ],
            MouseRegion(
              onEnter: (_) {
                if (tts.isEnabled) tts.speak('Add subtask');
              },
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.add,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                label: Semantics(
                  label: 'Add subtask',
                  child: Text(
                    'Add subtask',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
