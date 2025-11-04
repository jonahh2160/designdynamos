import 'package:flutter/material.dart';

class TaskIconOption {
  const TaskIconOption({
    required this.name,
    required this.icon,
    required this.label,
  });

  final String name;
  final IconData icon;
  final String label;
}

class TaskIconRegistry {
  static const List<TaskIconOption> options = [
    TaskIconOption(name: 'task_alt', icon: Icons.task_alt, label: 'Task'),
    TaskIconOption(name: 'bed', icon: Icons.bed, label: 'Sleep'),
    TaskIconOption(
      name: 'local_drink',
      icon: Icons.local_drink,
      label: 'Hydrate',
    ),
    TaskIconOption(name: 'restaurant', icon: Icons.restaurant, label: 'Meals'),
    TaskIconOption(
      name: 'fitness_center',
      icon: Icons.fitness_center,
      label: 'Workout',
    ),
    TaskIconOption(
      name: 'emoji_events',
      icon: Icons.emoji_events,
      label: 'Achievements',
    ),
    TaskIconOption(name: 'school', icon: Icons.school, label: 'Study'),
    TaskIconOption(name: 'work', icon: Icons.work_outline, label: 'Work'),
    TaskIconOption(name: 'pets', icon: Icons.pets, label: 'Pets'),
    TaskIconOption(
      name: 'self_care',
      icon: Icons.self_improvement,
      label: 'Self care',
    ),
    TaskIconOption(
      name: 'shopping',
      icon: Icons.shopping_bag,
      label: 'Errands',
    ),
  ];

  static final Map<String, TaskIconOption> _byName = {
    for (final option in options) option.name: option,
  };

  static TaskIconOption get defaultOption => options.first;

  static TaskIconOption optionByName(String? name) {
    if (name == null) return defaultOption;
    return _byName[name] ?? defaultOption;
  }

  static IconData iconFor(String? name) => optionByName(name).icon;
}
