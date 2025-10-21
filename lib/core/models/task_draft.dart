import 'task_item.dart';

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.iconName,
    this.dueDate,
    this.priority = 5,
    this.notes,
    this.points = 10,
    this.subtasks = const <String>[],
    this.labels = const <String>{},
  });

  final String title;
  final String iconName;
  final DateTime? dueDate;
  final int priority;
  final String? notes;
  final int points;
  final List<String> subtasks;
  final Set<String> labels;

  TaskItem toTask({
    required String id,
    required int orderHint,
    DateTime? startDate,
  }) {
    return TaskItem(
      id: id,
      title: title,
      iconName: iconName,
      points: points,
      isDone: false,
      notes: notes,
      startDate: startDate,
      dueDate: dueDate,
      priority: priority,
      orderHint: orderHint,
    );
  }
}
