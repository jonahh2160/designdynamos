class GoalDraft {
  const GoalDraft({
    required this.title,
    required this.startAt,
    required this.dueAt,
    this.description,
    this.priority = 5,
    this.steps = const <String>[],
  });

  final String title;
  final DateTime startAt;
  final DateTime dueAt;
  final String? description;
  final int priority;
  final List<String> steps;
}
