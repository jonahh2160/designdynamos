import  'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/core/models/task_item.dart';

class TaskService {
  final SupabaseClient _sb;
  TaskService(this._sb);


  Future<List<TaskItem>> getTodayTasks() async {
    final today = DateTime.now();
    final from  = DateTime(today.year, today.month, today.day);
    final to = from.add(const Duration(days : 1));

    final List<Map<String, dynamic>> res  = await _sb
      .from('tasks')
      .select('*')
      .gte('due_date', from.toIso8601String())
      .lt('due_date', to.toIso8601String())
      .order('is_done', ascending: true)
      .order('order_hint', ascending: true);
    

    return res.map(TaskItem.fromMap).toList(growable: false);
  }

  Future<String> createTask(TaskItem t, {List<String> labelIds = const [], List<String> subtasks = const []}) async {
    final data = await _sb.rpc('create_task_with_children', params: {
      'p_title': t.title,
      'p_notes': t.notes,
      'p_start_date': t.start_date?.toIso8601String(),
      'p_due_date': t.due_date?.toIso8601String(),
      'p_points': t.points,
      'p_priority': t.priority,
      'p_labels': labelIds,
      'p_subtasks': subtasks,
    }) as String;

    return data;
  }

  Future<void> toggleDone(String taskId, bool done) async {
    await _sb.rpc('toggle_task_done', params: {
      'p_task_id': taskId,
      'p_done': done,
      });
  }

  Future<void> reorder(String taskId, int newHint) async {
    await _sb.from('tasks').update({'order_hint': newHint}).eq('id', taskId);
  }



}
