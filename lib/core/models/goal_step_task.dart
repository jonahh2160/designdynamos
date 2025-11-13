class GoalStepTask {
  const GoalStepTask({
    required this.id,
    required this.goalStepId,
    required this.taskId,
    this.goalId,
  });

  final String id;
  final String goalStepId;
  final String taskId;
  final String? goalId;

  GoalStepTask copyWith({
    String? id,
    String? goalStepId,
    String? taskId,
    String? goalId,
  }) {
    return GoalStepTask(
      id: id ?? this.id,
      goalStepId: goalStepId ?? this.goalStepId,
      taskId: taskId ?? this.taskId,
      goalId: goalId ?? this.goalId,
    );
  }

  factory GoalStepTask.fromMap(Map<String, dynamic> map) {
    final nestedGoal = map['goal_steps'] as Map<String, dynamic>?;
    final goalStepId =
        map['goal_step_id'] as String? ??
        (map['goal_step'] as Map<String, dynamic>?)?['id'] as String?;
    if (goalStepId == null) {
      throw ArgumentError('goal_step_id is required for GoalStepTask');
    }
    return GoalStepTask(
      id: map['id'] as String,
      goalStepId: goalStepId,
      taskId: map['task_id'] as String,
      goalId: map['goal_id'] as String? ?? nestedGoal?['goal_id'] as String?,
    );
  }
}
