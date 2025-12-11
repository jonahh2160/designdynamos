import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/data/services/break_day_service.dart';

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.subtitle,
    this.iconUrl,
    this.earned = false,
    this.awardedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? iconUrl;
  final bool earned;
  final DateTime? awardedAt;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.coins,
    this.isCurrentUser = false,
  });

  final String name;
  final int coins;
  final bool isCurrentUser;
}

class DayStreakStatus {
  const DayStreakStatus({
    required this.label,
    required this.completed,
    this.isBreakDay = false,
  });

  final String label;
  final bool completed;
  final bool isBreakDay;
}

class AchievementsSnapshot {
  const AchievementsSnapshot({
    required this.badges,
    required this.leaderboard,
    required this.currentStreak,
    required this.recentDays,
    required this.totalTasksCompleted,
  });

  final List<AchievementBadge> badges;
  final List<LeaderboardEntry> leaderboard;
  final int currentStreak;
  final List<DayStreakStatus> recentDays;
  final int totalTasksCompleted;
}

class AchievementsService {
  AchievementsService(
    SupabaseClient client, {
    BreakDayService? breakDays,
  })  : _client = client,
        _breakDays = breakDays ?? BreakDayService(client);

  final SupabaseClient _client;
  final BreakDayService _breakDays;

  Future<AchievementsSnapshot> fetch() async {
    final userId = _client.auth.currentUser?.id;

    final badges = await _fetchBadges(userId);
    final leaderboard = await _fetchLeaderboard(userId);
    final dailyStats = await _fetchDailyStats();
    final now = DateTime.now();
    final breakDayKeys = await _fetchBreakDays(
      now.subtract(const Duration(days: 90)),
      now.add(const Duration(days: 14)),
    );
    final totalTasks = await _fetchTotalTasks();

    final streak = _computeStreak(dailyStats, breakDayKeys);
    final computedBadges = _computeLocalBadges(
      streak: streak,
      totalTasksCompleted: totalTasks,
      existing: badges,
    );

    final recentDays = _buildRecentDayStatuses(
      dailyStats,
      breakDayKeys,
    );

    return AchievementsSnapshot(
      badges: computedBadges,
      leaderboard: leaderboard,
      currentStreak: streak,
      recentDays: recentDays,
      totalTasksCompleted: totalTasks,
    );
  }

  Future<List<AchievementBadge>> _fetchBadges(String? userId) async {
    if (userId == null) return const [];

    try {
      final response = await _client
          .from('user_badges')
          .select(
            'badge_id, awarded_at, badges(id, slug, name, description, icon_url)',
          )
          .eq('user_id', userId);

      final List<dynamic> rows = response;
      return rows.map((raw) {
        final badge = raw['badges'] as Map<String, dynamic>?;
        final title = badge?['name'] as String? ?? 'Achievement';
        final subtitle =
            badge?['description'] as String? ?? 'Unlocked achievement';
        return AchievementBadge(
          id: badge?['slug'] as String? ??
              badge?['id'] as String? ??
              raw['badge_id'] as String? ??
              title,
          title: title,
          subtitle: subtitle,
          iconUrl: badge?['icon_url'] as String?,
          earned: true,
          awardedAt:
              raw['awarded_at'] != null ? DateTime.tryParse(raw['awarded_at']) : null,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<LeaderboardEntry>> _fetchLeaderboard(String? userId) async {
    try {
      final response = await _client.rpc('get_leaderboard');
      final List<dynamic> rows = response is List ? response : [];
      if (rows.isEmpty) return _fallbackLeaderboard();

      return rows.map((row) {
        final name = (row['display_name'] as String?)?.trim();
        return LeaderboardEntry(
          name: (name == null || name.isEmpty) ? 'User' : name,
          coins: row['coins'] as int? ?? 0,
          isCurrentUser: userId != null && row['id'] == userId,
        );
      }).toList();
    } catch (_) {
      return _fallbackLeaderboard();
    }
  }

  List<LeaderboardEntry> _fallbackLeaderboard() {
    return const [
      LeaderboardEntry(name: 'User1', coins: 12000),
      LeaderboardEntry(name: 'User99', coins: 11000),
      LeaderboardEntry(name: 'User21', coins: 10999),
      LeaderboardEntry(name: 'User11', coins: 10200),
      LeaderboardEntry(name: 'User999', coins: 5000),
    ];
  }

  Future<Set<String>> _fetchBreakDays(DateTime start, DateTime end) async {
    try {
      return await _breakDays.fetchRange(start, end);
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDailyStats() async {
    try {
      final response = await _client
          .from('user_daily_stats')
          .select('day, tasks_completed')
          .order('day', ascending: false)
          .limit(60);

      final List<dynamic> rows = response;
      return rows
          .whereType<Map<String, dynamic>>()
          .where((row) => row['day'] != null)
          .map((row) {
            final raw = row['day'] as String;
            //Treat stored DATE as UTC midnight, then shift to local day to match user view.
            final asUtc = DateTime.utc(
              int.parse(raw.substring(0, 4)),
              int.parse(raw.substring(5, 7)),
              int.parse(raw.substring(8, 10)),
            );
            final local = asUtc.toLocal();
            final key = DateTime(local.year, local.month, local.day)
                .toIso8601String()
                .split('T')
                .first;
            return {
              'day': key,
              'tasks_completed': row['tasks_completed'],
            };
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> _fetchTotalTasks() async {
    try {
      final response =
          await _client.from('tasks').select('id').eq('is_done', true);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  int _computeStreak(
    List<Map<String, dynamic>> stats,
    Set<String> breakDays,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Set<String> completedDays = {
      for (final row in stats)
      if ((row['tasks_completed'] as int? ?? 0) > 0)
        row['day'] as String,
    };

    //Find most recent completed day (not in the future).
    DateTime? lastCompleted;
    for (final key in completedDays) {
      final parsed = DateTime.tryParse(key);
      if (parsed == null) continue;
      final dayOnly = DateTime(parsed.year, parsed.month, parsed.day);
      if (dayOnly.isAfter(today)) continue;
      if (lastCompleted == null || dayOnly.isAfter(lastCompleted)) {
        lastCompleted = dayOnly;
      }
    }
    if (lastCompleted == null) return 0;

    //If there's a missed working day between the last completion and today (excluding today),
    //the streak is already broken.
    var forwardCursor = lastCompleted.add(const Duration(days: 1));
    while (forwardCursor.isBefore(today)) {
      final key = _dayKey(forwardCursor);
      if (!breakDays.contains(key) && !completedDays.contains(key)) {
        return 0;
      }
      forwardCursor = forwardCursor.add(const Duration(days: 1));
    }

    int streak = 0;
    DateTime cursor = lastCompleted;
    int guard = 0;
    while (true) {
      if (guard > 365) break; //safety net
      final key = _dayKey(cursor);
      if (breakDays.contains(key)) {
        cursor = cursor.subtract(const Duration(days: 1));
        guard += 1;
        continue;
      }
      if (completedDays.contains(key)) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
        guard += 1;
      } else {
        break;
      }
    }

    return streak;
  }

  List<DayStreakStatus> _buildRecentDayStatuses(
    List<Map<String, dynamic>> stats,
    Set<String> breakDays,
  ) {
    final Map<String, int> byDay = {
      for (final row in stats)
        row['day'] as String: (row['tasks_completed'] as int? ?? 0),
    };

    final now = DateTime.now();
    //Build the current week (Mon–Sun) in order, so all days are shown.
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final List<DayStreakStatus> days = [];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final key = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')
          .first;
      final label = _weekdayLabel(date.weekday);
      final completed = (byDay[key] ?? 0) > 0;
      final isBreakDay = breakDays.contains(key);
      days.add(
        DayStreakStatus(
          label: label,
          completed: completed || isBreakDay,
          isBreakDay: isBreakDay,
        ),
      );
    }
    return days;
  }

  List<AchievementBadge> _computeLocalBadges({
    required int streak,
    required int totalTasksCompleted,
    required List<AchievementBadge> existing,
  }) {
    final Map<String, AchievementBadge> byId = {
      for (final b in existing) b.id: b,
    };

    AchievementBadge buildBadge({
      required String id,
      required String title,
      required String subtitle,
      required bool earned,
    }) {
      final existingBadge = byId[id];
      if (existingBadge != null) {
        return existingBadge;
      }
      return AchievementBadge(
        id: id,
        title: title,
        subtitle: subtitle,
        earned: earned,
      );
    }

    final badges = <AchievementBadge>[
      buildBadge(
        id: 'streak_3',
        title: '3-day streak',
        subtitle: 'Complete tasks 3 days in a row',
        earned: streak >= 3,
      ),
      buildBadge(
        id: 'streak_7',
        title: '7-day streak',
        subtitle: 'Keep momentum for a week',
        earned: streak >= 7,
      ),
      buildBadge(
        id: 'streak_30',
        title: '30-day streak',
        subtitle: 'A month of consistency',
        earned: streak >= 30,
      ),
      buildBadge(
        id: 'tasks_2',
        title: '2 tasks completed',
        subtitle: 'Nice warm-up!',
        earned: totalTasksCompleted >= 2,
      ),
      buildBadge(
        id: 'tasks_10',
        title: '10 tasks completed',
        subtitle: 'Nice warm-up!',
        earned: totalTasksCompleted >= 10,
      ),
  
      buildBadge(
        id: 'tasks_100',
        title: '100 tasks completed',
        subtitle: 'Triple digits club',
        earned: totalTasksCompleted >= 100,
      ),
    ];

    //Keep any extra badges from the backend.
    final extra = existing.where((b) => !byId.containsKey(b.id)).toList();
    return [
      ...{for (final b in badges) b.id: b}.values,
      ...extra,
    ];
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'Th';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'Sa';
      case DateTime.sunday:
        return 'Su';
      default:
        return '';
    }
  }

  String _dayKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T').first;
  }
}
