import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/core/models/nav_item_data.dart';
import 'sidebar_button.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.title,
    required this.primaryItems,
    required this.secondaryItems,
  });

  final String title;
  final List<NavItemData> primaryItems;
  final List<NavItemData> secondaryItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...primaryItems.map((item) => SidebarButton(item: item)),
          const Spacer(),
          ...secondaryItems.map(
            (item) => SidebarButton(item: item, isSecondary: true),
          ),
        ],
      ),
    );
  }
}
