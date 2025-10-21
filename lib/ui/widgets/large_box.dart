import 'package:flutter/material.dart';
import 'package:designdynamos/core/theme/app_colors.dart';

class LargeBox extends StatelessWidget {
  final String label;       //Title text (can be a date or anything)
  final Widget? child;      //Optional child content

  const LargeBox({
    super.key,
    required this.label,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.subtaskBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.textMuted,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white70, thickness: 1),
          const SizedBox(height: 20),
          if (child != null) child!,
        ],
      ),
    );
  }
}
