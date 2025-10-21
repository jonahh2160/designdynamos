import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class StatusPip extends StatelessWidget {
  const StatusPip({super.key, required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? AppColors.accent : Colors.transparent,
        border: Border.all(
          color: isCompleted
              ? AppColors.accent
              : AppColors.textPrimary.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 14, color: Colors.black)
          : null,
    );
  }
}
