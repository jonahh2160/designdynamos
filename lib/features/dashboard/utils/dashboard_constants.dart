import 'package:flutter/material.dart';

import 'package:designdynamos/core/models/nav_item_data.dart';
import 'package:designdynamos/core/models/subtask_item.dart';
import 'package:designdynamos/core/models/tag_info.dart';
import 'package:designdynamos/core/models/task_item.dart';

class DashboardConstants {
  static const List<NavItemData> mainDestinations = [
    NavItemData(Icons.home, 'Daily Tasks', badge: '3', isActive: true),
    NavItemData(Icons.event_note, 'Calendar'),
    NavItemData(Icons.vrpano, 'Outlook'),
    NavItemData(Icons.view_list, 'All Tasks'),
    NavItemData(Icons.flag, 'Goals'),
    NavItemData(Icons.emoji_events, 'Achievements'),
    NavItemData(Icons.sports_esports, 'Games'),
  ];

  static const List<NavItemData> secondaryDestinations = [
    NavItemData(Icons.open_in_new, 'Pop out'),
    NavItemData(Icons.settings, 'Settings'),
    NavItemData(Icons.logout, 'Sign Out'),
  ];

  //need to pull from database
  static const List<TaskItem> todayTasks = [
    TaskItem(
      title: 'Make Bed',
      icon: Icons.bed,
      score: 9,
      progress: 0.5,
      progressLabel: '1/2',
      metadata: [
        TagInfo(label: 'Due Today', icon: Icons.calendar_today_outlined),
        TagInfo(label: 'Self Care', icon: Icons.self_improvement_outlined),
      ],
    ),
    TaskItem(
      title: 'Drink Water',
      icon: Icons.local_drink,
      score: 6,
      metadata: [TagInfo(label: 'Self Care', icon: Icons.water_drop_outlined)],
    ),
    TaskItem(
      title: 'Eat Breakfast',
      icon: Icons.restaurant,
      score: 7,
      metadata: [TagInfo(label: 'Health', icon: Icons.favorite_outline)],
    ),
  ];

  static const List<TaskItem> completedTasks = [
    TaskItem(title: 'Do something', icon: Icons.check, completed: true),
    TaskItem(title: 'Do something', icon: Icons.check, completed: true),
    TaskItem(title: 'Do something', icon: Icons.check, completed: true),
  ];

  static const List<SubtaskItem> makeBedSubtasks = [
    SubtaskItem(title: 'Wash bedding', completed: true),
    SubtaskItem(title: 'Dry bedding'),
  ];
}