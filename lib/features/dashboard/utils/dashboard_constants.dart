import 'package:flutter/material.dart';

import 'package:designdynamos/core/models/nav_item_data.dart';
import 'package:designdynamos/core/models/subtask_item.dart';

class DashboardConstants {
  static const List<NavItemData> mainDestinations = [
    NavItemData(Icons.home, 'Daily Tasks', isActive: true),
    NavItemData(Icons.event_note, 'Calendar'),
    NavItemData(Icons.vrpano, 'Outlook'),
    NavItemData(Icons.view_list, 'All Tasks'),
    NavItemData(Icons.flag, 'Goals'),
    NavItemData(Icons.insights, 'Progress'),
    NavItemData(Icons.emoji_events, 'Achievements'),
    NavItemData(Icons.sports_esports, 'Games'),
  ];

  static const List<NavItemData> secondaryDestinations = [
    NavItemData(Icons.open_in_new, 'Pop out'),
    NavItemData(Icons.settings, 'Settings'),
    NavItemData(Icons.logout, 'Sign Out'),
  ];

  //Task lists now come from the database via TaskProvider.
  //Keep only static demo data unrelated to TaskItem here.

  static const List<SubtaskItem> makeBedSubtasks = [
    SubtaskItem(title: 'Wash bedding', completed: true),
    SubtaskItem(title: 'Dry bedding'),
  ];
}
