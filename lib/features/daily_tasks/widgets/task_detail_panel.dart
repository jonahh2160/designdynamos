import 'package:designdynamos/core/models/subtask_item.dart';
import 'package:designdynamos/core/models/tag_info.dart';
import 'package:designdynamos/features/daily_tasks/widgets/info_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/notes_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_summary_panel.dart';
import 'package:flutter/material.dart';

class TaskDetailPanel extends StatelessWidget {
  const TaskDetailPanel({
    super.key,
    required this.title,
    required this.score,
    required this.subtasks,
    required this.tags,
  });

  final String title;
  final int score;
  final List<SubtaskItem> subtasks;
  final List<TagInfo> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskSummaryCard(title: title, score: score, subtasks: subtasks),
        const SizedBox(height: 16),
        InfoCard(tags: tags),
        const SizedBox(height: 16),
        const NotesCard(),
      ],
    );
  }
}