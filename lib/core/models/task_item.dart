import 'package:flutter/material.dart';
import 'tag_info.dart';

class TaskItem {
  const TaskItem({
    required this.title,
    required this.icon,
    this.score,
    this.progress,
    this.progressLabel,
    this.metadata = const [],
    this.completed = false,
  });

  final String title;
  final IconData icon;
  final int? score;
  final double? progress;
  final String? progressLabel;
  final List<TagInfo> metadata;
  final bool completed;
}