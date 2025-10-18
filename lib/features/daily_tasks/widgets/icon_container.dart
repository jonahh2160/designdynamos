import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class IconContainer extends StatelessWidget {
  const IconContainer({
    super.key,
    required this.icon,
    required this.isCompleted,
  });

  final IconData icon;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.sidebarActive.withOpacity(0.6)
            : AppColors.sidebarActive,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.textPrimary),
    );
  }
}