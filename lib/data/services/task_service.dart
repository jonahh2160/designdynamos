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
  }) async {
    //ensuring we only fetch tasks for the current authenticated user
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      //no user session; return empty to avoid RLS errors
      return <TaskItem>[];
    }

    final query = _sb
        .from('tasks')
        .select(
          '''
            id,
            user_id,
            title,
            notes,
            priority,
            is_done,
            points,
            order_hint,
            created_at,
            updated_at,
            completed_at,
            icon_name,
            start_at,
            due_at,
            target_at,
            estimated_minutes,
            goal_step_tasks(
              id,
              goal_step_id,
              goal_steps(goal_id)
            )
          ''',
        )
        .eq('user_id', userId)
        .order('is_done', ascending: true)
        .order('priority', ascending: false)
        .order('target_at', ascending: true)
        .order('due_at', ascending: true)
        .order('order_hint', ascending: true);

    final response = await query;

    final List<Map<String, dynamic>> res =
        response.cast<Map<String, dynamic>>();
    final all = res.map(TaskItem.fromMap).toList();

    final localStart = DateTime(day.year, day.month, day.day);
    final dayStart = localStart.toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));

    final filtered = all.where((task) {
      final start = task.startDate?.toUtc();
      final due = task.dueAt?.toUtc();

      final dueWithinDay =
          due != null && !due.isBefore(dayStart) && due.isBefore(dayEnd);

      final spanning = includeSpanning &&
          start != null &&
          due != null &&
          !start.isAfter(dayEnd) &&
          !due.isBefore(dayStart);

      final overdue = includeOverdue && due != null && due.isBefore(dayStart);

      return dueWithinDay || spanning || overdue;
    }).toList();

    filtered.sort((a, b) {
      final dueA = a.dueAt;
      final dueB = b.dueAt;
      if (dueA != null && dueB != null) {
        final cmp = dueA.compareTo(dueB);
        if (cmp != 0) return cmp;
      } else if (dueA == null && dueB != null) {
        return 1;
      } else if (dueA != null && dueB == null) {
        return -1;
      }
      return a.orderHint.compareTo(b.orderHint);
    });

    return filtered;
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

  Future<void> reorderTasks (String taskId, int newOrderHint) async {
  await _sb
      .from('tasks')
      .update({'order_hint': newOrderHint})
      .eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot delete task without an authenticated user.');
    }

    await _sb.from('tasks').delete().eq('id', taskId).eq('user_id', userId);
    await _goalStepTasks.removeByTask(taskId);
  }
  /// Fetch all tasks without filtering by user
  Future<List<TaskItem>> getAllTasks() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      // No user session; return empty to avoid RLS errors
      return const [];
    }

    final response = await _sb
      .from('tasks')
      .select()
      .eq('user_id', userId) // only fetch tasks for this user
      .order('due_at', ascending: true)   // order by due date first
      .order('order_hint', ascending: true); // then by order hint

    final List<Map<String, dynamic>> res = (response as List).cast<Map<String, dynamic>>();
    return res.map(TaskItem.fromMap).toList();
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
