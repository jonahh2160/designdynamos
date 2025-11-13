import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:designdynamos/core/models/goal.dart';
import 'package:designdynamos/core/models/goal_draft.dart';

class GoalService {
  GoalService(this._client);

  final SupabaseClient _client;

  Future<List<Goal>> fetchGoals() async {
    final response = await _client
        .from('goals')
        .select(_goalSelect)
        .order('due_at');
    final List<Map<String, dynamic>> rows = (response as List)
        .cast<Map<String, dynamic>>();
    return rows.map(Goal.fromMap).toList();
  }

  Future<Goal> createGoal(GoalDraft draft) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot create goal without an authenticated user.');
    }

    final inserted = await _client
        .from('goals')
        .insert({
          'user_id': userId,
          'title': draft.title,
          'description': draft.description,
          'priority': draft.priority,
          'start_at': draft.startAt.toUtc().toIso8601String(),
          'due_at': draft.dueAt.toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    final goalId = inserted['id'] as String;

    final stepRows = <Map<String, dynamic>>[];
    int hint = 0;
    for (final title in draft.steps) {
      final trimmed = title.trim();
      if (trimmed.isEmpty) continue;
      hint += 1000;
      stepRows.add({
        'goal_id': goalId,
        'title': trimmed,
        'order_hint': hint,
        'user_id': userId,
      });
    }

    if (stepRows.isNotEmpty) {
      await _client.from('goal_steps').insert(stepRows);
    }

    final Map<String, dynamic> fetched = await _client
        .from('goals')
        .select(_goalSelect)
        .eq('id', goalId)
        .single();
    return Goal.fromMap(fetched);
  }

  static const String _goalSelect = '''
    id,
    user_id,
    title,
    description,
    priority,
    completed,
    start_at,
    due_at,
    goal_steps(
      id,
      goal_id,
      title,
      is_done,
      order_hint,
      user_id,
      goal_step_tasks(
        id,
        goal_step_id,
        task_id,
        goal_steps(goal_id)
      )
    )
  ''';

  Future<Goal> updateGoal(
    String goalId, {
    DateTime? startAt,
    DateTime? dueAt,
    int? priority,
  }) async {
    final payload = <String, dynamic>{};
    if (startAt != null) {
      payload['start_at'] = startAt.toUtc().toIso8601String();
    }
    if (dueAt != null) {
      payload['due_at'] = dueAt.toUtc().toIso8601String();
    }
    if (priority != null) {
      payload['priority'] = priority;
    }
    if (payload.isNotEmpty) {
      await _client.from('goals').update(payload).eq('id', goalId);
    }
    final Map<String, dynamic> row = await _client
        .from('goals')
        .select(_goalSelect)
        .eq('id', goalId)
        .single();
    return Goal.fromMap(row);
  }
}
