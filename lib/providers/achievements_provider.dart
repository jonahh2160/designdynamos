import 'package:designdynamos/data/services/achievements_service.dart';
import 'package:flutter/foundation.dart';

class AchievementsProvider extends ChangeNotifier {
  AchievementsProvider(this._service);

  final AchievementsService _service;

  bool _loading = false;
  String? _error;
  AchievementsSnapshot? _snapshot;

  bool get isLoading => _loading;
  String? get error => _error;
  AchievementsSnapshot? get snapshot => _snapshot;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _snapshot = await _service.fetch();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
