import 'goal_step_task.dart';

class GoalStep {
  const GoalStep({
    required this.id,
    required this.goalId,
    required this.title,
    required this.isDone,
    required this.orderHint,
    required this.taskLinks,
    this.userId,
  });

  final String id;
  final String goalId;
  final String title;
  final bool isDone;
  final int orderHint;
  final List<GoalStepTask> taskLinks;
  final String? userId;

  List<String> get taskIds => taskLinks.map((t) => t.taskId).toList();

  GoalStep copyWith({
    String? id,
    String? goalId,
    String? title,
    bool? isDone,
    int? orderHint,
    List<GoalStepTask>? taskLinks,
    String? userId,
  }) {
    return GoalStep(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      orderHint: orderHint ?? this.orderHint,
      taskLinks: taskLinks ?? this.taskLinks,
      userId: userId ?? this.userId,
    );
  }

  factory GoalStep.fromMap(Map<String, dynamic> map) {
    final rawLinks =
        (map['goal_step_tasks'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    return GoalStep(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      title: map['title'] as String,
      isDone: (map['is_done'] ?? false) as bool,
      orderHint: (map['order_hint'] ?? 1000) as int,
      taskLinks: rawLinks.map(GoalStepTask.fromMap).toList(),
      userId: map['user_id'] as String?,
    );
  }
}
