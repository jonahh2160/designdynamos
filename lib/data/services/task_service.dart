import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/core/models/task_item.dart';

class TaskService {
  final SupabaseClient _sb;
  TaskService(this._sb);

  Future<List<TaskItem>> getTodayTasks() async {
    final today = DateTime.now();
    final from = DateTime(today.year, today.month, today.day);
    final to = from.add(const Duration(days: 1));

    final response = await _sb
        .from('tasks')
        .select(
          'id, title, icon_name, notes, start_date, due_date, points, priority, order_hint, is_done, completed_at',
        )
        .gte('due_date', from.toIso8601String())
        .lt('due_date', to.toIso8601String())
        .order('is_done', ascending: true)
        .order('order_hint', ascending: true);

    final List<Map<String, dynamic>> res = (response as List)
        .cast<Map<String, dynamic>>();
    return res.map(TaskItem.fromMap).toList(growable: false);
  }

  Future<TaskItem> createTask(TaskItem task) async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot create task without an authenticated user.');
    }

    final Map<String, dynamic> inserted = await _sb
        .from('tasks')
        .insert(task.toInsertRow(userId))
        .select()
        .single();

    return TaskItem.fromMap(inserted);
  }

  Future<void> updateTask(
    String taskId, {
    DateTime? dueDate,
    bool clearDueDate = false,
    int? priority,
    String? iconName,
    bool? isDone,
    DateTime? completedAt,
  }) async {
    final payload = <String, dynamic>{};

    if (clearDueDate) {
      payload['due_date'] = null;
    } else if (dueDate != null) {
      payload['due_date'] = dueDate.toIso8601String();
    }

    if (priority != null) payload['priority'] = priority;
    if (iconName != null) payload['icon_name'] = iconName;
    if (isDone != null) {
      payload['is_done'] = isDone;
      payload['completed_at'] = isDone
          ? (completedAt ?? DateTime.now()).toIso8601String()
          : null;
    }

    if (payload.isEmpty) return;

    await _sb.from('tasks').update(payload).eq('id', taskId);
  }

  Future<void> toggleDone(String taskId, bool done) =>
      updateTask(taskId, isDone: done);

  Future<void> reorder(String taskId, int newHint) async {
    await _sb.from('tasks').update({'order_hint': newHint}).eq('id', taskId);
  }
}
