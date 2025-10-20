class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    //required this.icon,
    required this.points,
    required this.is_done,
    this.notes,
    this.start_date,
    this.due_date,
    this.priority = 5,//5 by default cause why not
    this.order_hint = 1000,
  });

  final String id;
  final String title;
  //final IconData icon;
  final int points;
  final bool is_done;
  final String? notes;
  final DateTime? start_date;
  final DateTime? due_date;
  final int priority;
  final int order_hint;

  factory TaskItem.fromMap(Map<String, dynamic> m) => TaskItem( 
      id: m['id'] as String,
      title: m['title'] as String,
      //icon: m['icon'] as IconData,
      points: (m['points'] ?? 10) as int,
      is_done: (m['is_done'] ?? false) as bool,
      notes: m['notes'] as String?,
      start_date: m['start_date'] != null ? DateTime.parse(m['start_date']) : null,
      due_date: m['due_date'] != null ? DateTime.parse(m['due_date']) : null,
      priority: (m['priority'] ?? 5) is int ? m['priority'] : int.tryParse(m['priority'] ?? '5') ?? 5,
      order_hint: (m['order_hint'] ?? 1000) as int,
  );

  Map<String, dynamic> toInsert() => {
    'title': title,
    'notes': notes,
    'start_date': start_date?.toIso8601String(),
    'due_date': due_date?.toIso8601String(),
    'points': points,
    'priority': priority,
    'order_hint': order_hint,
  };

  TaskItem copyWith({bool? isDone}) =>
      TaskItem(
        id: id,
        title: title,
        //icon: icon,
        points: points,
        is_done: is_done ?? this.is_done,
        notes: notes,
        start_date: start_date,
        due_date: due_date,
        priority: priority,
        order_hint: order_hint,
      );
}