class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.iconName,
    required this.points,
    required this.isDone,
    this.notes,
    this.startDate,
    this.dueDate,
    this.priority = 5,
    this.orderHint = 1000,
    this.completedAt,
  });

  final String id;
  final String title;
  final String iconName;
  final int points;
  final bool isDone;
  final String? notes;
  final DateTime? startDate;
  final DateTime? dueDate;
  final int priority;
  final int orderHint;
  final DateTime? completedAt;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      //handling common timestamp variants returned by PostgREST
      String s = value.trim();
      //normalizing space separator to 'T'
      if (s.contains(' ') && !s.contains('T')) {
        s = s.replaceFirst(' ', 'T');
      }
      //ensuring timezone offset has colon, e.g. +00 -> +00:00, +0000 -> +00:00
      final tzNoColon = RegExp(r"[+-]\d{2}(?!:)\d{2}$");
      final tzShort = RegExp(r"[+-]\d{2}$");
      if (tzNoColon.hasMatch(s)) {
        s = s.replaceFirst(RegExp(r"([+-]\d{2})(\d{2})$"), r"$1:$2");
      } else if (tzShort.hasMatch(s)) {
        s = "$s:00";
      }
      //parse normalized string
      return DateTime.tryParse(s) ?? DateTime.tryParse(value);
    }
    return null;
  }

  static String? _dateOnlyString(DateTime? value) {
    if (value == null) return null;
    final local = value; //treating as local date selection from UI
    final y = local.year.toString();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  //factory construtor is a special type of constructor that can return an instance of the class(existing, chached, new, or even subclass)
  //dynamic type is a special type that allows a variable to hold values of any type, and type can change durring runtime
  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as String,
      title: map['title'] as String,
      iconName: (map['icon_name'] ?? 'task_alt') as String,
      points: (map['points'] ?? 10) as int,
      isDone: (map['is_done'] ?? false) as bool,
      notes: map['notes'] as String?,
      startDate: _parseDateTime(map['start_date']),
      dueDate: _parseDateTime(map['due_date']),
      priority: _parseInt(map['priority'], 5),
      orderHint: (map['order_hint'] ?? 1000) as int,
      completedAt: _parseDateTime(map['completed_at']),
    );
  }

  Map<String, dynamic> toInsertRow(String userId) => {
    'user_id': userId,
    'title': title,
    'icon_name': iconName,
    'notes': notes,
    //DB columns are DATE; store YYYY-MM-DD only
    'start_date': _dateOnlyString(startDate),
    'due_date': _dateOnlyString(dueDate),
    'points': points,
    'priority': priority,
    'order_hint': orderHint,
    'is_done': isDone,
    if (completedAt != null)
      'completed_at': completedAt!.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toUpdateRow({
    bool clearDueDate = false,
    DateTime? overrideCompletedAt,
  }) {
    final data = <String, dynamic>{
      'title': title,
      'icon_name': iconName,
      'notes': notes,
      //DB columns are DATE; store YYYY-MM-DD only
      'start_date': _dateOnlyString(startDate),
      'due_date': clearDueDate ? null : _dateOnlyString(dueDate),
      'points': points,
      'priority': priority,
      'order_hint': orderHint,
      'is_done': isDone,
    };

    final completed = overrideCompletedAt ?? completedAt;
    data['completed_at'] = completed?.toUtc().toIso8601String();

    data.removeWhere((_, value) => value == null);
    return data;
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? iconName,
    int? points,
    bool? isDone,
    String? notes,
    DateTime? startDate,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? priority,
    int? orderHint,
    DateTime? completedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      iconName: iconName ?? this.iconName,
      points: points ?? this.points,
      isDone: isDone ?? this.isDone,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      orderHint: orderHint ?? this.orderHint,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
