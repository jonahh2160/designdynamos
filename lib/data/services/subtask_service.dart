import 'package:designdynamos/core/models/db_subtask.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubtaskService {
  final SupabaseClient _sb;
  SubtaskService(this._sb);

  Future<List<DbSubtask>> fetchForTask(String taskId) async {
    final response = await _sb
        .from('subtasks')
        .select('id, task_id, title, is_done, order_hint')
        .eq('task_id', taskId)
        .order('order_hint', ascending: true);
    final List<Map<String, dynamic>> res = (response as List)
        .cast<Map<String, dynamic>>();
    return res.map(DbSubtask.fromMap).toList(growable: false);
  }

  Future<DbSubtask> create(
    String taskId,
    String title, {
    int orderHint = 1000,
  }) async {
    final row = DbSubtask(
      id: 'tmp',
      taskId: taskId,
      title: title,
      isDone: false,
      orderHint: orderHint,
    ).toInsertRow(taskId);
    final inserted = await _sb.from('subtasks').insert(row).select().single();
    return DbSubtask.fromMap(inserted);
  }

  Future<void> toggleDone(String subtaskId, bool done) async {
    await _sb.from('subtasks').update({'is_done': done}).eq('id', subtaskId);
  }

  Future<void> delete(String subtaskId) async {
    await _sb.from('subtasks').delete().eq('id', subtaskId);
  }
}
