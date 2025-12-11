import 'package:flutter/material.dart';
import 'package:designdynamos/core/theme/app_colors.dart';

class MetaChip extends StatelessWidget {
  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
  });

  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.textPrimary;
    final bg = backgroundColor ?? AppColors.sidebarActive.withOpacity(0.5);
    final border = borderColor;
    final borderW = borderWidth ?? 1.1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: border != null ? Border.all(color: border, width: borderW) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Color priorityLevelColor(int priority) {
  const low = Color(0xFF63F7BB); //brighter green for low priority
  const high = Color(0xFFFF4D4F); //vivid red for high priority
  final clamped = priority.clamp(1, 10);
  final t = ((clamped as num) - 1) / 9;
  return Color.lerp(low, high, t.toDouble()) ?? high;
}

class PriorityChipColors {
  const PriorityChipColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

PriorityChipColors buildPriorityChipColors(int priority) {
  final tone = priorityLevelColor(priority);
  final background = Color.lerp(tone, Colors.black, 0.45) ?? tone;
  final foreground =
      background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  final border = tone.withOpacity(0.95);
  return PriorityChipColors(
    background: background,
    foreground: foreground,
    border: border,
  );
}
