import 'package:designdynamos/core/models/tag_info.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.tags});

  final List<TagInfo> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.detailCard,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final tag in tags) ...[
            Row(
              children: [
                Icon(
                  tag.icon ?? Icons.tag_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  tag.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (tag != tags.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
