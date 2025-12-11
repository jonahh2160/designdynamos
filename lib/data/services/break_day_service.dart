import 'package:supabase_flutter/supabase_flutter.dart';

class BreakDayService {
  BreakDayService(this._client);

  final SupabaseClient _client;
  static const String _breakTitle = '__break_day__';

  ///Returns a set of local day keys (yyyy-MM-dd) that are marked as breaks.
  Future<Set<String>> fetchRange(DateTime start, DateTime end) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    //Normalize to day boundaries in UTC to avoid TZ drift.
    final startUtc = DateTime.utc(start.year, start.month, start.day);
    final endUtc = DateTime.utc(end.year, end.month, end.day)
        .add(const Duration(days: 1));

    final response = await _client
        .from('events')
        .select('start_at')
        .eq('user_id', userId)
        .eq('all_day', true)
        .eq('title', _breakTitle)
        .gte('start_at', startUtc.toIso8601String())
        .lt('start_at', endUtc.toIso8601String());

    if (response is! List) return {};

    final Set<String> result = {};
    for (final row in response.whereType<Map<String, dynamic>>()) {
      final raw = row['start_at'];
      if (raw is! String) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;
      //Stored as UTC day boundary that already represents the user's local day.
      //Do NOT shift to local again or the day will slip backward in negative offsets.
      final utcDay = DateTime.utc(parsed.year, parsed.month, parsed.day);
      result.add(_dayKey(utcDay));
    }
    return result;
  }

  ///Mark or unmark a specific day as a break.
  Future<void> setBreakDay(DateTime day, bool isBreak) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot update break days without an authenticated user.');
    }

    final localDay = DateTime(day.year, day.month, day.day);
    final startUtc = DateTime.utc(
      localDay.year,
      localDay.month,
      localDay.day,
    );
    final endUtc = startUtc.add(const Duration(days: 1));

    final table = _client.from('events');
    final existing = await table
        .select('id')
        .eq('user_id', userId)
        .eq('all_day', true)
        .eq('title', _breakTitle)
        .gte('start_at', startUtc.toIso8601String())
        .lt('start_at', endUtc.toIso8601String())
        .maybeSingle();

    if (isBreak) {
      if (existing == null) {
        await table.insert({
          'user_id': userId,
          'title': _breakTitle,
          'notes': 'break-day',
          'start_at': startUtc.toIso8601String(),
          'end_at': endUtc.toIso8601String(),
          'all_day': true,
        });
      }
    } else {
      if (existing != null) {
        await table.delete().eq('id', existing['id']);
      }
    }
  }

  static String _dayKey(DateTime dt) {
    final local = DateTime(dt.year, dt.month, dt.day);
    return local.toIso8601String().split('T').first;
  }
}
