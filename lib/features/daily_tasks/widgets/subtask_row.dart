import 'package:designdynamos/core/models/subtask_item.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SubtaskRow extends StatelessWidget {
  const SubtaskRow({super.key, required this.subtask});

  final SubtaskItem subtask;

  @override
  Widget build(BuildContext context) {
    final bool completed = subtask.completed;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.subtaskBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle
                : Icons.radio_button_unchecked_outlined,
            color: completed ? AppColors.accent : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtask.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: completed
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                decoration: completed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}