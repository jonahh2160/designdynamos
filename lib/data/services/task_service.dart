import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/data/services/goal_step_task_service.dart';

//start_date =
//dude_date = deadline(overdue after this date)
class TaskService {
  final SupabaseClient _sb;
  TaskService(this._sb, {GoalStepTaskService? goalStepTasks})
    : _goalStepTasks = goalStepTasks ?? GoalStepTaskService(_sb);
  final GoalStepTaskService _goalStepTasks;
  SupabaseClient get client => _sb;

  //Flexible daily-task fetch with optional inclusions.
  Future<List<TaskItem>> getDailyTasks(
    DateTime day, {
    bool includeOverdue = true,
    bool includeSpanning = true,
    bool includeUndated = false,
  }) async {
    //ensuring we only fetch tasks for the current authenticated user
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      //no user session; return empty to avoid RLS errors
      return <TaskItem>[];
    }

    try {
      final response = await _sb.rpc(
        'get_daily_tasks_rpc',
        params: {
          'day': day.toUtc().toIso8601String(),
          'include_overdue': includeOverdue,
          'include_spanning': includeSpanning,
          'include_backlog': includeUndated,
        },
      );

      if (response is List) {
        final List<Map<String, dynamic>> res =
            response.cast<Map<String, dynamic>>();
        return res.map(TaskItem.fromMap).toList();
      }

      // Unexpected shape (e.g., null/Map) – log and return empty
      debugPrint('get_daily_tasks_rpc returned unexpected shape: $response');
      return <TaskItem>[];
    } catch (error, stack) {
      debugPrint('get_daily_tasks_rpc failed: $error');
      debugPrint('$stack');
      return <TaskItem>[];
    }
  }

  //Convenience wrapper for "today"
  Future<List<TaskItem>> getTodayTasks() => getDailyTasks(DateTime.now());

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

    var created = TaskItem.fromMap(inserted);
    if (task.goalStepId != null) {
      await _goalStepTasks.assign(task.goalStepId!, created.id);
      created = created.copyWith(
        goalStepId: task.goalStepId,
        goalId: task.goalId,
      );
    }
    return created;
  }

  Future<void> updateTask(
    String taskId, {
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? targetAt,
    bool clearTargetAt = false,
    String? goalStepId,
    bool clearGoalStep = false,
    int? priority,
    String? iconName,
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
    bool? isDone,
    DateTime? completedAt,
  }) async {
    final payload = <String, dynamic>{};

    if (clearDueAt) {
      payload['due_at'] = null;
    } else if (dueAt != null) {
      payload['due_at'] = dueAt.toUtc().toIso8601String();
    }

    if (clearTargetAt) {
      payload['target_at'] = null;
    } else if (targetAt != null) {
      payload['target_at'] = targetAt.toUtc().toIso8601String();
    }

    if (priority != null) payload['priority'] = priority;
    if (iconName != null) payload['icon_name'] = iconName;
    if (clearEstimatedMinutes) {
      payload['estimated_minutes'] = null;
    } else if (estimatedMinutes != null) {
      payload['estimated_minutes'] = estimatedMinutes;
    }
    if (isDone != null) {
      payload['is_done'] = isDone;
      payload['completed_at'] = isDone
          ? (completedAt ?? DateTime.now()).toUtc().toIso8601String()
          : null;
    }

    if (payload.isNotEmpty) {
      await _sb.from('tasks').update(payload).eq('id', taskId);
    }

    if (clearGoalStep) {
      await _goalStepTasks.removeByTask(taskId);
    } else if (goalStepId != null) {
      await _goalStepTasks.assign(goalStepId, taskId);
    }
  }

  Future<void> toggleDone(String taskId, bool done) =>
      updateTask(taskId, isDone: done);

  Future<void> reorder(String taskId, int newHint) async {
    await _sb.from('tasks').update({'order_hint': newHint}).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot delete task without an authenticated user.');
    }

    await _sb.from('tasks').delete().eq('id', taskId).eq('user_id', userId);
    await _goalStepTasks.removeByTask(taskId);
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
    final trimmed = content?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _sb.from('task_notes').delete().eq('task_id', taskId);
      return;
    }

    await _sb.from('task_notes').upsert({
      'task_id': taskId,
      'content': trimmed,
    }, onConflict: 'task_id');
  }

  Future<void> setGoalStep(String taskId, {String? goalStepId}) async {
    if (goalStepId == null) {
      await _goalStepTasks.removeByTask(taskId);
    } else {
      await _goalStepTasks.assign(goalStepId, taskId);
    }
  }
}
