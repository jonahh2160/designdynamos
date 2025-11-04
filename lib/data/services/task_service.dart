import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/core/models/task_item.dart';

class TaskService {
  final SupabaseClient _sb;
  TaskService(this._sb);
  SupabaseClient get client => _sb;

  Future<List<TaskItem>> getTodayTasks() async {
    //ensuring we only fetch tasks for the current authenticated user
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      //no user session; return empty to avoid RLS errors
      return const [];
    }

    final day = _formatDateOnly(DateTime.now());

    final response = await _sb
        .from('tasks')
        .select(
          'id, title, icon_name, notes, start_date, due_date, points, priority, order_hint, is_done, completed_at',
        )
        .eq('user_id', userId)
        .or('due_date.eq.$day,start_date.eq.$day')
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
      payload['due_date'] = _formatDateOnly(dueDate);
    }

    if (priority != null) payload['priority'] = priority;
    if (iconName != null) payload['icon_name'] = iconName;
    if (isDone != null) {
      payload['is_done'] = isDone;
      payload['completed_at'] = isDone
          ? (completedAt ?? DateTime.now()).toUtc().toIso8601String()
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

  Future<void> deleteTask(String taskId) async {
    await _sb.from('tasks').delete().eq('id', taskId);
  }

  //Notes CRUD
  Future<String?> fetchNote(String taskId) async {
    final response = await _sb
        .from('task_notes')
        .select('id, content')
        .eq('task_id', taskId)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return response['content'] as String?;
  }

  Future<void> upsertNote(String taskId, String? content) async {
    final existing = await _sb
        .from('task_notes')
        .select('id')
        .eq('task_id', taskId)
        .limit(1)
        .maybeSingle();
    if (content == null || content.trim().isEmpty) {
      if (existing != null) {
        await _sb.from('task_notes').delete().eq('id', existing['id']);
      }
      return;
    }
    if (existing == null) {
      await _sb.from('task_notes').insert({
        'task_id': taskId,
        'content': content,
      });
    } else {
      await _sb
          .from('task_notes')
          .update({'content': content})
          .eq('id', existing['id']);
    }
  }
}

String _formatDateOnly(DateTime date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
