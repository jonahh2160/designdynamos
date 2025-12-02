import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:designdynamos/core/models/goal_step_task.dart';

class GoalStepTaskService {
  GoalStepTaskService(this._client);

  final SupabaseClient _client;

  Future<Map<String, GoalStepTask>> fetchForTaskIds(
    List<String> taskIds,
  ) async {
    if (taskIds.isEmpty) return <String, GoalStepTask>{};
    final response = await _client
        .from('goal_step_tasks')
        .select('id, goal_step_id, task_id, goal_steps(goal_id)')
        .inFilter('task_id', taskIds);
    final List<Map<String, dynamic>> rows = (response as List)
        .cast<Map<String, dynamic>>();
    return {
      for (final row in rows)
        row['task_id'] as String: GoalStepTask.fromMap(row),
    };
  }

  Future<GoalStepTask> assign(String goalStepId, String taskId) async {
    await _client.rpc(
      'assign_task_to_step',
      params: {'p_goal_step_id': goalStepId, 'p_task_id': taskId},
    );
    final Map<String, dynamic> row = await _client
        .from('goal_step_tasks')
        .select('id, goal_step_id, task_id, goal_steps(goal_id)')
        .eq('task_id', taskId)
        .single();
    return GoalStepTask.fromMap(row);
  }

  Future<void> removeByTask(String taskId) async {
    await _client.rpc('remove_task_from_step', params: {'p_task_id': taskId});
  }

  Future<void> remove(String goalStepId, String taskId) async {
    await _client.rpc('remove_task_from_step', params: {'p_task_id': taskId});
  }
}
