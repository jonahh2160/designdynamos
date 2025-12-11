import 'package:flutter/foundation.dart';
import 'package:designdynamos/data/services/break_day_service.dart';

class BreakDayProvider extends ChangeNotifier {
  BreakDayProvider(this._service);

  final BreakDayService _service;

  final Set<String> _breakDays = {};
  DateTime? _cachedStart;
  DateTime? _cachedEnd;
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;

  bool isBreakDay(DateTime day) {
    final key = _dayKey(day);
    return _breakDays.contains(key);
  }

  ///Fetch break days around the provided anchor to keep the cache warm.
  Future<void> warmCache({DateTime? anchor}) async {
    final now = anchor ?? DateTime.now();
    final start = now.subtract(const Duration(days: 120));
    final end = now.add(const Duration(days: 120));
    await _refreshRange(start, end);
  }

  ///Ensure a specific day is covered by the cache; will refetch if needed.
  Future<void> ensureCovers(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    if (_cachedStart != null &&
        _cachedEnd != null &&
        !dayOnly.isBefore(_cachedStart!) &&
        !dayOnly.isAfter(_cachedEnd!)) {
      return Future.value();
    }
    final start = dayOnly.subtract(const Duration(days: 120));
    final end = dayOnly.add(const Duration(days: 120));
    return _refreshRange(start, end);
  }

  Future<void> setBreakDay(DateTime day, bool enabled) async {
    final key = _dayKey(day);
    _error = null;
    try {
      await _service.setBreakDay(day, enabled);
      if (enabled) {
        _breakDays.add(key);
      } else {
        _breakDays.remove(key);
      }
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  DateTime nextWorkingDay(DateTime from) {
    var cursor = DateTime(from.year, from.month, from.day);
    int guard = 0;
    while (_breakDays.contains(_dayKey(cursor)) && guard < 366) {
      cursor = cursor.add(const Duration(days: 1));
      guard += 1;
    }
    return cursor;
  }

  Future<void> _refreshRange(DateTime start, DateTime end) async {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day);
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _service.fetchRange(rangeStart, rangeEnd);
      _breakDays
        ..removeWhere((key) {
          final parsed = DateTime.tryParse(key);
          if (parsed == null) return false;
          final date = DateTime(parsed.year, parsed.month, parsed.day);
          return date.isBefore(rangeStart) || date.isAfter(rangeEnd);
        })
        ..addAll(fetched);
      _cachedStart = rangeStart;
      _cachedEnd = rangeEnd;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _dayKey(DateTime day) {
    final local = DateTime(day.year, day.month, day.day);
    return local.toIso8601String().split('T').first;
  }
}
