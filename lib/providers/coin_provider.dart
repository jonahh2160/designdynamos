import 'package:flutter/foundation.dart';
import 'package:designdynamos/data/services/coin_service.dart';

class CoinProvider extends ChangeNotifier {
  CoinProvider(this._service);

  final CoinService _service;

  bool _loading = false;
  int _totalCoins = 0;
  int _todayCoins = 0;
  String? _error;

  bool get isLoading => _loading;
  int get totalCoins => _totalCoins;
  int get todayCoins => _todayCoins;
  String? get error => _error;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final balance = await _service.fetchBalance();
      _totalCoins = balance.totalCoins;
      _todayCoins = balance.todayCoins;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void reset() {
    _totalCoins = 0;
    _todayCoins = 0;
    _error = null;
    notifyListeners();
  }
}
