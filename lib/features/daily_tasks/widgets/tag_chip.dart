import 'package:flutter/material.dart';
import 'package:designdynamos/core/theme/app_colors.dart';

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.onDeleted});

  final String label;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final text = label.trim().isEmpty ? label : label.trim();
    return Container(
      decoration: BoxDecoration(
        //Match the greenish meta chip background used for dates
        color: AppColors.sidebarActive.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDeleted,
              behavior: HitTestBehavior.opaque,
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
