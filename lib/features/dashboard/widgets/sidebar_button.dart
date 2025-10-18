import 'package:designdynamos/core/models/nav_item_data.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';


class SidebarButton extends StatelessWidget {
  const SidebarButton({
    super.key,
    required this.item,
    this.isSecondary = false,
  });

  final NavItemData item;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final bool active = item.isActive && !isSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 22,
              color: active
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withOpacity(
                      isSecondary ? 0.6 : 0.8,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withOpacity(
                          isSecondary ? 0.7 : 0.85,
                        ),
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.badge!,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}