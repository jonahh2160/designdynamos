import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AddTaskCard extends StatelessWidget {
  const AddTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.taskCard,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.sidebarActive,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Add task',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textPrimary,
            size: 22,
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.flag_outlined,
            color: AppColors.textPrimary,
            size: 22,
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.local_offer_outlined,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ],
      ),
    );
  }
}