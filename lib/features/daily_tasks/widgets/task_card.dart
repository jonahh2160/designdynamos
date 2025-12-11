import 'package:designdynamos/features/daily_tasks/widgets/meta_chip.dart';
import 'package:designdynamos/features/daily_tasks/widgets/tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/utils/estimate_formatter.dart';
import 'package:designdynamos/features/daily_tasks/utils/task_icon_registry.dart';
import 'package:designdynamos/features/daily_tasks/widgets/icon_container.dart';
import 'package:designdynamos/features/daily_tasks/widgets/status_pip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onToggle,
    this.onTap,
    this.isSelected = false,
    this.subtaskDone = 0,
    this.subtaskTotal = 0,
    this.labels = const {},
  });

  final TaskItem task;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final bool isSelected;
  final int subtaskDone;
  final int subtaskTotal;
  final Set<String> labels;

  @override
  Widget build(BuildContext context) {
    final bool completed = task.isDone;
    final Color baseColor = completed
        ? AppColors.completedCard
        : AppColors.taskCard;
    final Color textColor = completed
        ? AppColors.textPrimary.withOpacity(0.7)
        : AppColors.textPrimary;
    final TextStyle titleStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
          decoration: completed
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          decorationColor: textColor.withOpacity(0.8),
        ) ??
        TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          decoration: completed
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        );

    final borderColor = isSelected
        ? AppColors.accent
        : completed
        ? AppColors.completedBorder
        : Colors.transparent;
    final borderWidth = isSelected ? 2.0 : (completed ? 1.4 : 0.0);

    final iconData = TaskIconRegistry.iconFor(task.iconName);

    // Semantics label
    final List<String> semanticsParts = [
      task.title,
      if (completed) "Completed",
      if (subtaskTotal > 0) "Subtasks: $subtaskDone of $subtaskTotal completed",
      if (task.targetAt != null) _formatTargetLabel(task.targetAt!),
      if (task.dueAt != null) _formatDueLabel(task.dueAt!),
      "Priority ${task.priority}",
      if (task.points > 0) "${task.points} points",
    ];
    final String semanticsLabel = semanticsParts.join(', ');
    final ttsProvider = context.read<TtsProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MouseRegion(
        onEnter: (_) {
          if (ttsProvider.isEnabled) {
            ttsProvider.speak(semanticsLabel);
          }
        },
        child: Semantics(
          label: semanticsLabel,
          button: true,
          child: Material(
            color: baseColor,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (onToggle != null)
                      GestureDetector(
                        onTap: onToggle,
                        behavior: HitTestBehavior.translucent,
                        child: StatusPip(isCompleted: completed),
                      ),
                    const SizedBox(width: 14),
                    IconContainer(icon: iconData, isCompleted: completed),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: titleStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                          const SizedBox(height: 6),
                          _MetadataRow(
                            task: task,
                            done: subtaskDone,
                            total: subtaskTotal,
                            labels: labels,
                          ),
                        ],
                      ),
                    ),
                    if (task.points > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.scoreBadge.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${task.points}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.task,
    required this.done,
    required this.total,
    required this.labels,
  });

  final TaskItem task;
  final int done;
  final int total;
  final Set<String> labels;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    //Subtask progress
    if (total > 0) {
      chips.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              child: LinearProgressIndicator(
                value: (done / total).clamp(0, 1).toDouble(),
                backgroundColor: AppColors.textPrimary.withOpacity(0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$done/$total',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (task.targetAt != null) {
      chips.add(
        MetaChip(
          icon: Icons.flag_outlined,
          label: _formatTargetLabel(task.targetAt!),
        ),
      );
    }
    if (task.dueAt != null) {
      chips.add(
        MetaChip(
          icon: Icons.calendar_today_outlined,
          label: _formatDueLabel(task.dueAt!),
        ),
      );
    }
    if (task.estimatedMinutes != null) {
      chips.add(
        MetaChip(
          icon: Icons.timelapse,
          label: formatEstimateLabel(task.estimatedMinutes!),
        ),
      );
    }
    //Label chips
    for (final name in labels) {
      chips.add(TagChip(label: name));
    }
    chips.add(
      MetaChip(icon: Icons.flag_outlined, label: 'Priority ${task.priority}'),
    );
    if (task.isDone) {
      chips.add(MetaChip(icon: Icons.check_circle_outline, label: 'Done'));
    }

    return Wrap(
      spacing: 8, 
      runSpacing: 8, 
      children: chips.map((widget) {
        if (widget is MetaChip || widget is TagChip) {
          return Semantics(
            label: (widget as dynamic).label,
            child: widget,
          );
        }
        return widget;
      }).toList(),
    );
  }
}

String _formatTargetLabel(DateTime dateTime) =>
    'Target ${_formatRelativeDate(dateTime)}';

String _formatDueLabel(DateTime dateTime) =>
    'Due ${_formatRelativeDate(dateTime)}';

String _formatRelativeDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final today = DateUtils.dateOnly(DateTime.now());
  final target = DateUtils.dateOnly(local);
  final diff = target.difference(today).inDays;
  final timeLabel = DateFormat.jm().format(local);

  if (diff == 0) return 'Today • $timeLabel';
  if (diff == 1) return 'Tomorrow • $timeLabel';
  if (diff == -1) return 'Yesterday • $timeLabel';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[target.month - 1];
  return '$month ${target.day} • $timeLabel';
}
