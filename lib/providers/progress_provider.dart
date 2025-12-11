import 'package:designdynamos/core/models/progress_snapshot.dart';
import 'package:designdynamos/data/services/progress_service.dart';
import 'package:flutter/foundation.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._service)
      : _snapshot = ProgressSnapshot.empty(
          range: ProgressRange.last30,
        );

  final ProgressService _service;

  ProgressSnapshot _snapshot;
  ProgressSnapshot? _lastGood;
  bool _loading = false;
  String? _error;

  ProgressSnapshot get snapshot => _snapshot;
  bool get isLoading => _loading;
  String? get error => _error;
  ProgressRange get range => _snapshot.range;
  String? get categoryFilter => _snapshot.categoryFilter;

  Future<void> refresh({
    ProgressRange? range,
    String? category,
    bool resetCategory = false,
  }) async {
    if (_loading) return;
    final nextRange = range ?? _snapshot.range;
    final nextCategory = resetCategory ? null : category ?? _snapshot.categoryFilter;
    _snapshot = _snapshot.copyWith(
      range: nextRange,
      categoryFilter: nextCategory,
    );

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.fetch(
        range: nextRange,
        categoryFilter: nextCategory,
      );
      _snapshot = result;
      _lastGood = result;
    } catch (error) {
      _error = error.toString();
      if (_lastGood != null) {
        _snapshot = _lastGood!.copyWith(fromCache: true);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
