import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';

typedef OverdueTaskAction = Future<void> Function(TaskItem task);

class OverdueTaskAlert extends StatelessWidget {
  final TaskItem task;
  final OverdueTaskAction onDelete;
  final OverdueTaskAction onComplete;
  final OverdueTaskAction onMoveDate;
  final TtsProvider tts;
  const OverdueTaskAlert({
    super.key,
    required this.tts,
    required this.task,
    required this.onDelete,
    required this.onComplete,
    required this.onMoveDate,
  });

  @override
  Widget build(BuildContext context) {
    final dueLocal = task.dueAt?.toLocal();
    final dueDate = dueLocal != null
        ? DateFormat('MMM d, h:mm a').format(dueLocal)
        : 'unknown date';

    return Semantics(
      container: true,
      label: 'Overdue Task Alert for ${task.title}',
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.detailCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: MergeSemantics(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: MouseRegion(
                  onEnter: (_) {
                    final label = 'Overdue: ${task.title}';
                    if (tts.isEnabled) tts.speak(label);
                  },
                  child: Semantics(
                    header: true,
                    label: 'Overdue: ${task.title}',
                    child: Text(
                      'Overdue: "${task.title}"',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This task was due on $dueDate and is still open.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _OverdueButton(
                label: 'Mark Complete',
                semanticLabel: 'Mark task ${task.title} as complete',
                onPressed: () async {
                  await onComplete(task);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task marked complete')),
                    );
                  }
                },
              ),
              _OverdueButton(
                label: 'Move Task Date',
                semanticLabel: 'Move task ${task.title} to a new date',
                onPressed: () => onMoveDate(task),
                secondary: true,
              ),
              _OverdueButton(
                label: 'Delete Task',
                semanticLabel: 'Delete task ${task.title}',
                onPressed: () async {
                  await onDelete(task);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task deleted')),
                    );
                  }
                },
                danger: true,
              ),
            ],
          ),
        ],
      ),
    ),
    ),
    );
  }
}

class _OverdueButton extends StatelessWidget {
  const _OverdueButton({
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
    this.secondary = false,
    this.danger = false,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool secondary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsProvider>();
    final bg = danger
        ? Colors.redAccent.withOpacity(0.18)
        : secondary
            ? AppColors.surface
            : AppColors.taskCardHighlight;
    final fg = danger
        ? Colors.redAccent
        : secondary
            ? AppColors.textPrimary
            : Colors.black;

    return MouseRegion(
      onEnter: (_) {
        if (tts.isEnabled) tts.speak(semanticLabel);
      },
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
          ),
        ),
      ),
    );
  }
}
