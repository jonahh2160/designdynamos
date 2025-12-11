import 'dart:math';

enum ProgressRange { last7, last30, last90 }

extension ProgressRangeDays on ProgressRange {
  int get days {
    switch (this) {
      case ProgressRange.last7:
        return 7;
      case ProgressRange.last30:
        return 30;
      case ProgressRange.last90:
        return 90;
    }
  }

  String get label {
    switch (this) {
      case ProgressRange.last7:
        return '7d';
      case ProgressRange.last30:
        return '30d';
      case ProgressRange.last90:
        return '90d';
    }
  }
}

class DailyStatPoint {
  const DailyStatPoint({
    required this.day,
    required this.completed,
    required this.coins,
  });

  final DateTime day;
  final int completed;
  final int coins;
}

class CategorySummary {
  const CategorySummary({
    required this.name,
    required this.completed,
    required this.total,
  });

  final String name;
  final int completed;
  final int total;

  double get completionRate => total == 0 ? 0 : completed / total;
}

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.range,
    required this.categoryFilter,
    required this.daily,
    required this.completionRate,
    required this.consistency,
    required this.bestDayCount,
    required this.currentStreak,
    required this.totalCompleted,
    required this.totalTasks,
    required this.categories,
    required this.availableCategories,
    required this.generatedAt,
    this.fromCache = false,
  });

  final ProgressRange range;
  final String? categoryFilter;
  final List<DailyStatPoint> daily;
  final double completionRate;
  final double consistency;
  final int bestDayCount;
  final int currentStreak;
  final int totalCompleted;
  final int totalTasks;
  final List<CategorySummary> categories;
  final List<String> availableCategories;
  final DateTime generatedAt;
  final bool fromCache;

  bool get hasActivity =>
      totalTasks > 0 || daily.any((point) => point.completed > 0);

  ProgressSnapshot copyWith({
    ProgressRange? range,
    String? categoryFilter,
    List<DailyStatPoint>? daily,
    double? completionRate,
    double? consistency,
    int? bestDayCount,
    int? currentStreak,
    int? totalCompleted,
    int? totalTasks,
    List<CategorySummary>? categories,
    List<String>? availableCategories,
    DateTime? generatedAt,
    bool? fromCache,
  }) {
    return ProgressSnapshot(
      range: range ?? this.range,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      daily: daily ?? this.daily,
      completionRate: completionRate ?? this.completionRate,
      consistency: consistency ?? this.consistency,
      bestDayCount: bestDayCount ?? this.bestDayCount,
      currentStreak: currentStreak ?? this.currentStreak,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      totalTasks: totalTasks ?? this.totalTasks,
      categories: categories ?? this.categories,
      availableCategories: availableCategories ?? this.availableCategories,
      generatedAt: generatedAt ?? this.generatedAt,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  static ProgressSnapshot empty({
    ProgressRange range = ProgressRange.last30,
    String? categoryFilter,
    List<String> availableCategories = const [],
    bool fromCache = false,
  }) {
    return ProgressSnapshot(
      range: range,
      categoryFilter: categoryFilter,
      daily: const [],
      completionRate: 0,
      consistency: 0,
      bestDayCount: 0,
      currentStreak: 0,
      totalCompleted: 0,
      totalTasks: 0,
      categories: const [],
      availableCategories: availableCategories,
      generatedAt: DateTime.now(),
      fromCache: fromCache,
    );
  }
}

int clampPercent(double value) {
  return value.isNaN
      ? 0
      : max(0, min(100, (value * 100).round()));
}
