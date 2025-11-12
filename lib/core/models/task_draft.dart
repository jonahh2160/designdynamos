import 'task_item.dart';

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.iconName,
    this.startAt,
    this.dueAt,
    this.targetAt,
    this.priority = 5,
    this.notes,
    this.points = 10,
    this.subtasks = const <String>[],
    this.labels = const <String>{},
  });

  final String title;
  final String iconName;
  final DateTime? startAt;
  final DateTime? dueAt;
  final DateTime? targetAt;
  final int priority;
  final String? notes;
  final int points;
  final List<String> subtasks;
  final Set<String> labels;

  DateTime? get dueDateOnly {
    final value = dueAt;
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  Duration? get dueTimeOfDay {
    final value = dueAt;
    if (value == null) return null;
    return Duration(hours: value.hour, minutes: value.minute);
  }

  DateTime? get targetDateOnly {
    final value = targetAt;
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  Duration? get targetTimeOfDay {
    final value = targetAt;
    if (value == null) return null;
    return Duration(hours: value.hour, minutes: value.minute);
  }

  TaskItem toTask({
    required String id,
    required int orderHint,
    DateTime? fallbackStartAt,
    DateTime? fallbackDueAt,
    DateTime? fallbackTargetAt,
  }) {
    final resolvedStart = startAt ?? fallbackStartAt;
    final resolvedDue = dueAt ?? fallbackDueAt ?? resolvedStart;
    final resolvedTarget = targetAt ?? fallbackTargetAt;

    return TaskItem(
      id: id,
      title: title,
      iconName: iconName,
      points: points,
      isDone: false,
      notes: notes,
      startDate: resolvedStart,
      dueAt: resolvedDue,
      targetAt: resolvedTarget,
      priority: priority,
      orderHint: orderHint,
    );
  }
}
