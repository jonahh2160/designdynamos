import 'goal_step.dart';

class Goal {
  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.priority,
    required this.completed,
    required this.startAt,
    required this.dueAt,
    required this.steps,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final int priority;
  final bool completed;
  final DateTime startAt;
  final DateTime dueAt;
  final List<GoalStep> steps;

  int get totalSteps => steps.length;
  int get completedSteps => steps.where((step) => step.isDone).length;
  double get progress => totalSteps == 0 ? 0 : completedSteps / totalSteps;
  Duration get remainingDuration => dueAt.difference(DateTime.now());

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? priority,
    bool? completed,
    DateTime? startAt,
    DateTime? dueAt,
    List<GoalStep>? steps,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      startAt: startAt ?? this.startAt,
      dueAt: dueAt ?? this.dueAt,
      steps: steps ?? this.steps,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }

  static int _parsePriority(dynamic value){
    if(value is int) return value;
    if(value is String) return int.tryParse(value) ?? 5;
    return 5;
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    final stepMaps =
        (map['goal_steps'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return Goal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: _parsePriority(map['priority']),
      completed: (map['completed'] ?? false) as bool,
      startAt: _parseDate(map['start_at']),
      dueAt: _parseDate(map['due_at']),
      steps: stepMaps.map(GoalStep.fromMap).toList(),
    );
  }
}
