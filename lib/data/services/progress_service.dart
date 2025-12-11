import 'dart:math';

import 'package:designdynamos/core/models/progress_snapshot.dart';
import 'package:designdynamos/data/services/break_day_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  ProgressService(
    this._client, {
    BreakDayService? breakDays,
  }) : _breakDays = breakDays ?? BreakDayService(_client);

  final SupabaseClient _client;
  final BreakDayService _breakDays;

  Future<ProgressSnapshot> fetch({
    ProgressRange range = ProgressRange.last30,
    String? categoryFilter,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return ProgressSnapshot.empty(
        range: range,
        categoryFilter: categoryFilter,
        fromCache: true,
      );
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: range.days - 1));
    final cutoffDate = DateTime.utc(start.year, start.month, start.day);
    final cutoffDateStr = cutoffDate.toIso8601String().split('T').first;
    final cutoffIso = cutoffDate.toIso8601String();

    //Pull daily stats for overall activity.
    final dailyRows = await _client
        .from('user_daily_stats')
        .select('day, tasks_completed, coins_earned')
        .gte('day', cutoffDateStr)
        .order('day');

    final dailySeries = _buildDailySeries(dailyRows, start, now);
    Set<String> breakDayKeys = {};
    try {
      breakDayKeys = await _breakDays.fetchRange(start, now);
    } catch (_) {
      breakDayKeys = {};
    }

    //Pull tasks that were due or completed in the range (superset, filtered locally).
    final rawTasks = await _client
        .from('tasks')
        .select(
          'id, is_done, due_at, completed_at, task_labels(labels(name))',
        )
        .eq('user_id', userId)
        .or('completed_at.gte.$cutoffIso,due_at.gte.$cutoffIso');

    final allTasks = _mapTasks(rawTasks);
    final availableCategories = _collectCategories(allTasks);

    bool matchesCategory(Set<String> labels) {
      if (categoryFilter == null || categoryFilter.isEmpty) return true;
      return labels.contains(categoryFilter);
    }

    final filteredTasks = allTasks.where((task) {
      if (!matchesCategory(task.labels)) return false;
      final due = task.dueAt;
      final completed = task.completedAt;
      final withinDueWindow =
          due != null && !due.isBefore(start) && !due.isAfter(now);
      final withinCompletedWindow = completed != null &&
          !completed.isBefore(start) &&
          !completed.isAfter(now);
      return withinDueWindow || withinCompletedWindow;
    }).toList();

    final completionRate =
        filteredTasks.isEmpty ? 0.0 : filteredTasks.where((t) {
          final completed = t.completedAt;
          final completedInRange = completed != null &&
              !completed.isBefore(start) &&
              !completed.isAfter(now);
          return t.isDone && completedInRange;
        }).length /
            filteredTasks.length;

    //If filtering by category, rebuild the day series from the filtered tasks
    //so the chart reflects the selection.
    final List<DailyStatPoint> series = (categoryFilter == null || categoryFilter.isEmpty)
        ? dailySeries
        : _buildSeriesFromTasks(filteredTasks, start, now);

    final workingDayCount = max(1, range.days - breakDayKeys.length);
    final consistency = series.isEmpty
        ? 0.0
        : series.where((p) => p.completed > 0).length /
            workingDayCount;

    final bestDayCount = series.isEmpty
        ? 0
        : series.map((p) => p.completed).reduce(max);

    final currentStreak = _computeStreak(series, breakDayKeys);

    final totalCompleted = filteredTasks.where((t) {
      final completed = t.completedAt;
      return t.isDone &&
          completed != null &&
          !completed.isBefore(start) &&
          !completed.isAfter(now);
    }).length;

    final categories = _buildCategorySummaries(filteredTasks);

    return ProgressSnapshot(
      range: range,
      categoryFilter: categoryFilter,
      daily: series,
      completionRate: completionRate,
      consistency: consistency,
      bestDayCount: bestDayCount,
      currentStreak: currentStreak,
      totalCompleted: totalCompleted,
      totalTasks: filteredTasks.length,
      categories: categories,
      availableCategories: availableCategories,
      generatedAt: DateTime.now(),
    );
  }

  List<DailyStatPoint> _buildDailySeries(
    dynamic rows,
    DateTime start,
    DateTime end,
  ) {
    final Map<String, DailyStatPoint> byDay = {};
    if (rows is List) {
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final dayRaw = row['day'] as String?;
        if (dayRaw == null) continue;
        final parsed = DateTime.tryParse(dayRaw);
        if (parsed == null) continue;
        //Treat stored DATE as UTC midnight.
        final local = DateTime.utc(parsed.year, parsed.month, parsed.day).toLocal();
        final keyDate = DateTime(local.year, local.month, local.day);
        final key = keyDate.toIso8601String().split('T').first;
        byDay[key] = DailyStatPoint(
          day: keyDate,
          completed: (row['tasks_completed'] as int?) ?? 0,
          coins: (row['coins_earned'] as int?) ?? 0,
        );
      }
    }

    final List<DailyStatPoint> series = [];
    DateTime cursor = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(endDay)) {
      final key = cursor.toIso8601String().split('T').first;
      series.add(
        byDay[key] ??
            DailyStatPoint(day: cursor, completed: 0, coins: 0),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return series;
  }

  List<DailyStatPoint> _buildSeriesFromTasks(
    List<_TaskLite> tasks,
    DateTime start,
    DateTime end,
  ) {
    final Map<String, int> byDay = {};
    for (final task in tasks) {
      if (!task.isDone) continue;
      final completed = task.completedAt;
      if (completed == null) continue;
      if (completed.isBefore(start) || completed.isAfter(end)) continue;
      final keyDate =
          DateTime(completed.year, completed.month, completed.day);
      final key = keyDate.toIso8601String().split('T').first;
      byDay.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    final List<DailyStatPoint> series = [];
    DateTime cursor = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(endDay)) {
      final key = cursor.toIso8601String().split('T').first;
      series.add(
        DailyStatPoint(
          day: cursor,
          completed: byDay[key] ?? 0,
          coins: 0,
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return series;
  }

  int _computeStreak(
    List<DailyStatPoint> series,
    Set<String> breakDays,
  ) {
    if (series.isEmpty) return 0;
    final Set<String> activeDays = {
      for (final p in series)
        if (p.completed > 0) p.day.toIso8601String().split('T').first,
    };
    DateTime cursor = DateTime.now();
    int streak = 0;
    int guard = 0;
    while (true) {
      if (guard > 365) break; //safety
      final key = DateTime(cursor.year, cursor.month, cursor.day)
          .toIso8601String()
          .split('T')
          .first;
      if (breakDays.contains(key)) {
        cursor = cursor.subtract(const Duration(days: 1));
        guard += 1;
        continue;
      }
      if (activeDays.contains(key)) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
        guard += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  List<CategorySummary> _buildCategorySummaries(List<_TaskLite> tasks) {
    const unlabeled = 'Unlabeled';
    final Map<String, _CategoryAgg> byCategory = {};

    for (final task in tasks) {
      final labels = task.labels.isEmpty ? {unlabeled} : task.labels;
      final completedInRange =
          task.isDone && task.completedAt != null;

      for (final label in labels) {
        final current = byCategory[label] ?? _CategoryAgg();
        current.completed += completedInRange ? 1 : 0;
        current.total += 1;
        byCategory[label] = current;
      }
    }

    return byCategory.entries
        .map(
          (entry) => CategorySummary(
            name: entry.key,
            completed: entry.value.completed,
            total: entry.value.total,
          ),
        )
        .toList()
      ..sort(
        (a, b) => b.completionRate.compareTo(a.completionRate),
      );
  }

  List<String> _collectCategories(List<_TaskLite> tasks) {
    const unlabeled = 'Unlabeled';
    final Set<String> result = {unlabeled};
    for (final task in tasks) {
      result.addAll(task.labels);
    }
    return result.toList()..sort();
  }

  List<_TaskLite> _mapTasks(dynamic rows) {
    if (rows is! List) return const [];
    return rows.whereType<Map<String, dynamic>>().map((row) {
      final labels = <String>{};
      final labelRows = row['task_labels'];
      if (labelRows is List) {
        for (final labelRow in labelRows.whereType<Map<String, dynamic>>()) {
          final nested = labelRow['labels'] as Map<String, dynamic>?;
          final name = nested?['name'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            labels.add(name.trim());
          }
        }
      }
      return _TaskLite(
        isDone: (row['is_done'] as bool?) ?? false,
        dueAt: _parseDateTime(row['due_at']),
        completedAt: _parseDateTime(row['completed_at']),
        labels: labels,
      );
    }).toList();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String && value.isNotEmpty) {
      String s = value.trim();
      if (s.contains(' ') && !s.contains('T')) {
        s = s.replaceFirst(' ', 'T');
      }
      final tzNoColon = RegExp(r"[+-]\d{2}(?!:)\d{2}$");
      final tzShort = RegExp(r"[+-]\d{2}$");
      if (tzNoColon.hasMatch(s)) {
        s = s.replaceFirst(RegExp(r"([+-]\\d{2})(\\d{2})$"), r"$1:$2");
      } else if (tzShort.hasMatch(s)) {
        s = "$s:00";
      }
      return DateTime.tryParse(s)?.toLocal();
    }
    return null;
  }
}

class _TaskLite {
  _TaskLite({
    required this.isDone,
    required this.dueAt,
    required this.completedAt,
    required this.labels,
  });

  final bool isDone;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final Set<String> labels;
}

class _CategoryAgg {
  _CategoryAgg() : completed = 0, total = 0;
  int completed;
  int total;
}
