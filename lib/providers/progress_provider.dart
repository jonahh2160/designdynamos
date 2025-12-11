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
  }) async {
    if (_loading) return;
    if (range != null || category != null) {
      _snapshot = _snapshot.copyWith(
        range: range ?? _snapshot.range,
        categoryFilter: category ?? _snapshot.categoryFilter,
      );
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.fetch(
        range: _snapshot.range,
        categoryFilter: _snapshot.categoryFilter,
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
