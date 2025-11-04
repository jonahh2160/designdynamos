import 'package:supabase_flutter/supabase_flutter.dart';

class LabelService {
  final SupabaseClient _sb;
  LabelService(this._sb);

  Future<Map<String, String>> ensureLabels(Iterable<String> names) async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return {};

    //Fetch existing
    final existingRes = await _sb
        .from('labels')
        .select('id, name')
        .eq('user_id', userId)
        .inFilter('name', names.toList());
    final Map<String, String> result = {};
    for (final row in (existingRes as List)) {
      result[(row as Map<String, dynamic>)['name'] as String] =
          row['id'] as String;
    }

    //Insert missing
    final missing = names.where((n) => !result.containsKey(n)).toList();
    if (missing.isNotEmpty) {
      final inserts = missing
          .map((n) => {'user_id': userId, 'name': n})
          .toList();
      final inserted = await _sb
          .from('labels')
          .insert(inserts)
          .select('id, name');
      for (final row in (inserted as List)) {
        final map = row as Map<String, dynamic>;
        result[map['name'] as String] = map['id'] as String;
      }
    }
    return result; //name -> id
  }

  Future<Set<String>> getTaskLabelNames(String taskId) async {
    final rows = await _sb
        .from('task_labels')
        .select('label_id, labels(name)')
        .eq('task_id', taskId);
    final Set<String> names = {};
    for (final r in (rows as List)) {
      final map = r as Map<String, dynamic>;
      final nested = map['labels'] as Map<String, dynamic>?;
      final name = nested != null ? nested['name'] as String? : null;
      if (name != null) names.add(name);
    }
    return names;
  }

  Future<void> setTaskLabels(String taskId, Set<String> names) async {
    //Clear and recreate for simplicity
    await _sb.from('task_labels').delete().eq('task_id', taskId);
    if (names.isEmpty) return;
    final map = await ensureLabels(names);
    final rows = map.values
        .map((labelId) => {'task_id': taskId, 'label_id': labelId})
        .toList();
    await _sb.from('task_labels').insert(rows);
  }

  Future<void> toggleTaskLabel(String taskId, String name, bool enabled) async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return;
    final ids = await ensureLabels([name]);
    final labelId = ids[name];
    if (labelId == null) return;
    if (enabled) {
      await _sb.from('task_labels').upsert({
        'task_id': taskId,
        'label_id': labelId,
      });
    } else {
      await _sb.from('task_labels').delete().match({
        'task_id': taskId,
        'label_id': labelId,
      });
    }
  }
}
