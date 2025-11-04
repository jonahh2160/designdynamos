import 'package:flutter/material.dart';

import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/daily_tasks/utils/task_icon_registry.dart';

class TaskIconPicker extends StatelessWidget {
  const TaskIconPicker({
    super.key,
    required this.selectedName,
    required this.onChanged,
  });

  final String selectedName;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in TaskIconRegistry.options)
          _IconChoice(
            option: option,
            selected: option.name == selectedName,
            onTap: () => onChanged(option.name),
          ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TaskIconOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.sidebarActive.withOpacity(0.8)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                color: selected ? AppColors.accent : AppColors.textPrimary,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                option.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
