class DbSubtask {
  const DbSubtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    this.orderHint = 1000,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final int orderHint;

  factory DbSubtask.fromMap(Map<String, dynamic> map) {
    return DbSubtask(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      title: map['title'] as String,
      isDone: (map['is_done'] ?? false) as bool,
      orderHint: (map['order_hint'] ?? 1000) as int,
    );
  }

  Map<String, dynamic> toInsertRow(String taskId) => {
    'task_id': taskId,
    'title': title,
    'is_done': isDone,
    'order_hint': orderHint,
  };

  DbSubtask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isDone,
    int? orderHint,
  }) {
    return DbSubtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      orderHint: orderHint ?? this.orderHint,
    );
  }
}
