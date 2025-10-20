import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AddTaskCard extends StatelessWidget {
  const AddTaskCard({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isLoading ? null : onPressed,
        child: Container(
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: isLoading
                    ? SizedBox(
                        key: const ValueKey('add-task-loading'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.textPrimary,
                          ),
                          backgroundColor:
                              AppColors.sidebarActive.withOpacity(0.4),
                        ),
                      )
                    : Row(
                        key: const ValueKey('add-task-icons'),
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.flag_outlined,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.local_offer_outlined,
                            color: AppColors.textPrimary,
                            size: 22,
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
